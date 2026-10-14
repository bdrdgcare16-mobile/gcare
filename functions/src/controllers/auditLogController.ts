import { Request, Response } from 'express';
import { getDb } from '../config/firebase';
import { COLLECTIONS } from '../constants/collections';

const MAX_SCAN = 500;

const serializeTimestamp = (value: unknown): string | null => {
  if (value && typeof (value as { toDate?: () => Date }).toDate === 'function') {
    return (value as { toDate: () => Date }).toDate().toISOString();
  }
  return value ? String(value) : null;
};

export const getAuditLogs = async (req: Request, res: Response): Promise<Response> => {
  try {
    const companyId = String((req as any).user?.companyId ?? '').trim();
    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const filters = {
      module: String(req.query.module ?? '').trim(),
      resourceType: String(req.query.resourceType ?? '').trim(),
      resourceId: String(req.query.resourceId ?? '').trim(),
      employeeId: String(req.query.employeeId ?? '').trim(),
      action: String(req.query.action ?? '').trim(),
    };
    const limit = Math.min(Math.max(Number(req.query.limit) || 50, 1), 200);

    const snapshot = await getDb()
      .collection(COLLECTIONS.AUDIT_LOGS)
      .where('companyId', '==', companyId)
      .orderBy('timestamp', 'desc')
      .limit(MAX_SCAN)
      .get();

    const logs = snapshot.docs
      .map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          action: data.action ?? null,
          module: data.module ?? null,
          actorId: data.actorId ?? null,
          actorName: data.actorName ?? null,
          actorEmail: data.actorEmail ?? null,
          resourceType: data.resourceType ?? null,
          resourceId: data.resourceId ?? null,
          employeeId: data.employeeId ?? null,
          employeeName: data.employeeName ?? null,
          requestType: data.requestType ?? null,
          companyId: data.companyId ?? null,
          timestamp: serializeTimestamp(data.timestamp),
          before: data.before ?? null,
          after: data.after ?? null,
          metadata: data.metadata ?? null,
        };
      })
      .filter((log) =>
        (!filters.module || log.module === filters.module) &&
        (!filters.resourceType || log.resourceType === filters.resourceType) &&
        (!filters.resourceId || log.resourceId === filters.resourceId) &&
        (!filters.employeeId || log.employeeId === filters.employeeId) &&
        (!filters.action || log.action === filters.action),
      )
      .slice(0, limit);

    return res.status(200).json({ logs, count: logs.length });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: 'Failed to fetch audit logs' });
  }
};
