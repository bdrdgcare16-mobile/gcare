import { Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { db } from '../config/firebase';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { trackUsage } from '../services/usageService';
import { getCurrentMonthRangeIST, canonicalLeaveTypeName } from '../utils/leavePeriod';
import { monthRangeYmd, normalizeToYmd } from '../utils/dateYmd';
import {
  LeaveRuleDoc,
  compareVersionsNewestFirst,
  entitlementForMonth,
  resolveRuleForMonth,
  ruleStartMonth,
} from '../utils/leaveEntitlement';

const COLL = 'leave_types';
const LEAVE_COLL = 'leaves';

/* ============================== Usage Tracking Helper ============================== */

async function trackLeaveTypeUsage(
  req: Request,
  updates: Record<string, number>
) {
  try {
    const user = (req as any).user;
    await trackUsage({
      companyId: user?.companyId || '',
      companyName: user?.companyName || '',
      plan: user?.plan || '',
      updates,
    });
  } catch (trackingError) {
    console.error('Usage tracking failed in leaveType:', trackingError);
  }
}

async function loadActiveVersions(companyId: string): Promise<any[]> {
  const snaps = await db
    .collection(COLL)
    .where('companyId', '==', companyId)
    .where('active', '==', true)
    .get();
  return snaps.docs.map((d) => d.data() as any);
}

/**
 * POST /api/leave-types
 * Body: { type, fromDate, toDate, days }   (days = allowance per calendar month)
 * Admin only
 *
 * A leave type is configured once and renews every month. `fromDate` selects
 * the month the configuration takes effect from (the To date is not used for
 * recurrence). Posting the same type again never creates a duplicate:
 *   - same start month  -> that configuration is updated;
 *   - same allowance already in force for that month -> nothing is written;
 *   - otherwise -> a new version effective from that month (earlier months
 *     keep the allowance they had).
 */
export const createLeaveType = async (req: Request, res: Response): Promise<Response | void> => {
  try {
    const { userId, role, companyId } = ((req as any).user ?? {}) as {
      userId?: string;
      role?: string;
      companyId?: string | null;
    };

    // Admin, or HR with 'leave' approved (hrFeatureGate on the route
    // enforces the feature — this check keeps non-admin roles out).
    if (role !== 'admin' && role !== 'hr') {
      return res.status(403).json({ message: 'Access restricted to administrators' });
    }

    if (!companyId) {
      return res.status(403).json({ message: 'Company ID missing in token' });
    }

    let { type, fromDate, toDate, days } = (req.body ?? {}) as {
      type?: string;
      fromDate?: string;
      toDate?: string;
      days?: number | string;
    };

    type = String(type ?? '').trim();

    if (!type || !fromDate || !toDate || days == null) {
      return res.status(400).json({ message: 'Please fill in all required fields' });
    }

    const s = new Date(fromDate);
    const e = new Date(toDate);
    const allowedDays = Number(days);

    if (Number.isNaN(s.getTime()) || Number.isNaN(e.getTime()) || e < s) {
      return res.status(400).json({ message: 'Please enter valid dates' });
    }

    if (!Number.isFinite(allowedDays) || allowedDays <= 0) {
      return res.status(400).json({ message: 'Number of days must be greater than zero' });
    }

    const canonical = canonicalLeaveTypeName(type);
    const startYm = (normalizeToYmd(fromDate) || normalizeToYmd(s)).slice(0, 7);
    const versions = (await loadActiveVersions(companyId)).filter(
      (v) => canonicalLeaveTypeName(v.type) === canonical,
    );

    // Same start month: update that configuration instead of duplicating it.
    const sameMonth = versions
      .filter((v) => ruleStartMonth(v) === startYm)
      .sort(compareVersionsNewestFirst)[0];

    if (sameMonth) {
      const patch = {
        type,
        allowedDays,
        toDate: Timestamp.fromDate(e),
        updatedAt: FieldValue.serverTimestamp(),
      };
      await db.collection(COLL).doc(sameMonth.id).update(patch);
      await trackLeaveTypeUsage(req, { writeCount: 1, apiCalls: 1 });
      return res.status(201).json({
        status: 'success',
        message: 'Leave type updated successfully',
        data: { ...sameMonth, ...patch },
      });
    }

    // Already in force with the same allowance: nothing to store.
    const inForce = resolveRuleForMonth(versions, canonical, startYm);
    if (inForce && Number(inForce.allowedDays) === allowedDays) {
      return res.status(201).json({
        status: 'success',
        message: 'Leave type is already configured with this allowance',
        data: inForce,
      });
    }

    const id = uuidv4();

    const payload = {
      id,
      companyId,
      type,
      fromDate: Timestamp.fromDate(s),
      toDate: Timestamp.fromDate(e),
      allowedDays,
      active: true,
      createdBy: userId ?? null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    await db.collection(COLL).doc(id).set(payload);

    // Track usage after successful leave type creation
    await trackLeaveTypeUsage(req, {
      writeCount: 1,
      apiCalls: 1,
    });

    return res.status(201).json({
      status: 'success',
      message: 'Leave type created successfully',
      data: payload,
    });
  } catch (err: any) {
    console.error('[leave-types:create] error', err);
    return res.status(500).json({
      message: 'An error occurred while processing your request',
      error: err?.message || 'Unknown error',
    });
  }
};

/**
 * GET /api/leave-types[?month=YYYY-MM]
 * Admin and employee. One entry per leave type for the requested month
 * (default: the current IST month):
 *   - fromDate / toDate  = first / last day of that month
 *   - allowedDays / monthlyAllowance = allowance in force for that month
 *   - used / remaining   = the calling employee's usage in that month
 *                          (employees only; Pending + Approved leaves)
 */
export const listLeaveTypes = async (req: Request, res: Response): Promise<Response | void> => {
  try {
    const { companyId, role, empid } = ((req as any).user ?? {}) as {
      companyId?: string | null;
      role?: string;
      empid?: string;
    };

    if (!companyId) {
      return res.status(403).json({ message: 'Company ID missing in token' });
    }

    const requestedMonth = String(req.query?.month ?? '').trim();
    let ym = getCurrentMonthRangeIST().startYmd.slice(0, 7);
    if (requestedMonth) {
      if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(requestedMonth)) {
        return res.status(400).json({ message: 'month must be in YYYY-MM format' });
      }
      ym = requestedMonth;
    }
    const period = monthRangeYmd(Number(ym.slice(0, 4)), Number(ym.slice(5, 7)));

    const versions = await loadActiveVersions(companyId);
    const isAdminUser = String(role || '').toLowerCase() === 'admin';

    let employeeLeaves: any[] = [];
    if (!isAdminUser && empid && versions.length > 0) {
      const leaveSnaps = await db
        .collection(LEAVE_COLL)
        .where('companyId', '==', companyId)
        .where('empid', '==', empid)
        .get();
      employeeLeaves = leaveSnaps.docs.map((d) => d.data() as any);
    }

    const byType = new Map<string, any[]>();
    for (const v of versions) {
      const key = canonicalLeaveTypeName(v.type);
      byType.set(key, [...(byType.get(key) ?? []), v]);
    }

    const out: any[] = [];
    for (const [canonical, group] of byType) {
      const rule = resolveRuleForMonth(group as LeaveRuleDoc[], canonical, ym);

      if (!rule) {
        // Not effective yet: hidden from employees; admin still sees it as stored.
        if (isAdminUser) out.push([...group].sort(compareVersionsNewestFirst).reverse()[0]);
        continue;
      }

      const entry: any = {
        ...rule,
        fromDate: Timestamp.fromDate(new Date(`${period.start}T00:00:00.000Z`)),
        toDate: Timestamp.fromDate(new Date(`${period.end}T00:00:00.000Z`)),
        allowedDays: Number(rule.allowedDays) || 0,
        monthlyAllowance: Number(rule.allowedDays) || 0,
        recurring: true,
        month: ym,
      };

      if (!isAdminUser && empid) {
        const ent = entitlementForMonth(group as LeaveRuleDoc[], employeeLeaves, canonical, ym);
        if (ent) {
          entry.used = ent.used;
          entry.remaining = ent.remaining;
        }
      }

      out.push(entry);
    }

    out.sort((a, b) => String(a.type).localeCompare(String(b.type)));

    // Track usage after successful leave types read
    await trackLeaveTypeUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({
      status: 'success',
      count: out.length,
      data: out,
    });
  } catch (err: any) {
    console.error('[leave-types:list] error', err);
    return res.status(500).json({
      message: 'Unable to load leave types',
      error: err?.message || 'Unknown error',
    });
  }
};

/**
 * DELETE /api/leave-types/:id
 * Admin only
 * Soft delete within the same company. The leave type is removed as a whole:
 * every active version of it is deactivated. Existing leave requests are
 * never touched.
 */
export const deleteLeaveType = async (req: Request, res: Response): Promise<Response | void> => {
  try {
    const { companyId } = ((req as any).user ?? {}) as {
      companyId?: string | null;
    };

    if (!companyId) {
      return res.status(403).json({ message: 'Company ID missing in token' });
    }

    const { id } = req.params;

    if (!id) {
      return res.status(400).json({ message: 'Leave type ID is required' });
    }

    const ref = db.collection(COLL).doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ message: 'Leave type not found' });
    }

    const data = doc.data() as any;

    if ((data.companyId || null) !== companyId) {
      return res.status(403).json({ message: 'You are not allowed to delete this leave type' });
    }

    const canonical = canonicalLeaveTypeName(data.type);
    const snaps = await db
      .collection(COLL)
      .where('companyId', '==', companyId)
      .where('active', '==', true)
      .get();

    const patch = { active: false, updatedAt: FieldValue.serverTimestamp() };
    const targets = snaps.docs.filter(
      (d) => d.id === id || canonicalLeaveTypeName((d.data() as any).type) === canonical,
    );
    await Promise.all(targets.map((d) => d.ref.update(patch)));
    if (!targets.some((d) => d.id === id)) await ref.update(patch);

    // Track usage after successful leave type deletion
    await trackLeaveTypeUsage(req, {
      deleteCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({
      status: 'success',
      message: 'Leave type deleted successfully',
    });
  } catch (err: any) {
    console.error('[leave-types:delete] error', err);
    return res.status(500).json({
      message: 'Failed to delete leave type',
      error: err?.message || 'Unknown error',
    });
  }
};