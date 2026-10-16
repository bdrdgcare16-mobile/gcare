import { Request, Response } from "express";
import { db } from "../config/firebase";

/**
 * GET /api/overtime?empid=EMP001&date=2025-10-28
 * Returns overtime hours for an employee on the given date.
 * Authenticated: the leaves query is scoped to the caller's company so an
 * admin cannot read another tenant's overtime records.
 */
export const getOvertimeHours = async (req: Request, res: Response): Promise<void> => {
  try {
    const empid = req.query.empid?.toString().trim();
    const date = req.query.date?.toString().trim();

    if (!empid || !date) {
      res.status(400).json({ ok: false, error: "Missing empid or date" });
      return;
    }

    const user = (req as any).user;
    const callerCompanyId = String(user?.companyId || '').trim();
    const isSuperAdmin = String(user?.role || '').toLowerCase() === 'super_admin';

    let query: FirebaseFirestore.Query = db
      .collection("leaves")
      .where("empid", "==", empid)
      .where("leaveType", "==", "Overtime")
      .where("startDate", "==", date)
      .where("endDate", "==", date);

    // Tenant isolation: non-super-admin callers are restricted to their own
    // company's leave/overtime records.
    if (!isSuperAdmin) {
      if (!callerCompanyId) {
        res.status(403).json({ ok: false, error: "No company context on token" });
        return;
      }
      query = query.where("companyId", "==", callerCompanyId);
    }

    const snapshot = await query.limit(1).get();

    if (snapshot.empty) {
      res.json({ ok: true, overtimeHours: 0 });
      return;
    }

    const data = snapshot.docs[0].data();
    const duration = Number(data.duration ?? 0);

    res.json({ ok: true, overtimeHours: duration });
  } catch (error: any) {
    console.error("Error fetching overtime:", error);
    res.status(500).json({ ok: false, error: error.message || "Internal Server Error" });
  }
};
