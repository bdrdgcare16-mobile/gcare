import { Request, Response } from "express";
import { db } from "../config/firebase";

// Helper: today in IST YYYY-MM-DD
function todayYmdIST(): string {
  const now = new Date();
  const ist = new Date(now.getTime() + 5.5 * 60 * 60 * 1000);
  return ist.toISOString().slice(0, 10);
}

interface Employee {
  id?: string;
  name?: string;
  department?: string;
  shift?: string;
  location?: string;
  latitude?: number;
  longitude?: number;
}

interface Attendance {
  empid?: string;
  date?: string;
  checkIn?: string;
  checkOut?: string | null;
  location?: string;
  branchName?: string;
  checkInLatitude?: number;
  checkInLongitude?: number;
  status?: string;
  geofence?: string;
  createdAt?: string;
  updatedAt?: string;
}

// Format into Flutter-ready object
function toUi(emp: Employee = {}, att: Attendance = {}) {
  return {
    id: emp.id || att.empid || "",
    name: emp.name || "" ,
    date: att.date || "",
    checkIn: att.checkIn || "",
    checkOut: att.checkOut || null,
    department: emp.department || "",
    shift: emp.shift || "",
    location: att.location || att.branchName || emp.location || "",
    latitude: att.checkInLatitude ?? emp.latitude ?? null,
    longitude: att.checkInLongitude ?? emp.longitude ?? null,
    status: att.status || "",
    geofence: att.geofence || "-",
  };
}

// GET /api/livedetails?date=YYYY-MM-DD
export async function listLiveDetails(req: Request, res: Response) {
  try {
    const date = (req.query.date as string)?.trim() || todayYmdIST();

    // Employees
    const empSnap = await db.collection("employees").get();
    const employees = empSnap.docs.map((d) => d.data() as Employee);

    // Attendance
    const attSnap = await db
      .collection("attendance")
      .where("date", "==", date)
      .get();

    const attByEmp = new Map<string, Attendance>();
    attSnap.forEach((doc) => {
      const row = doc.data() as Attendance;
      const prev = attByEmp.get(row.empid!);
      if (!prev) {
        attByEmp.set(row.empid!, row);
      } else {
        const pTs = new Date(prev.updatedAt || prev.createdAt || 0).getTime();
        const cTs = new Date(row.updatedAt || row.createdAt || 0).getTime();
        if (cTs >= pTs) attByEmp.set(row.empid!, row);
      }
    });

    const out = employees.map((e) =>
      toUi(e, attByEmp.get(e.id || "") || {})
    );

    return res.json({ status: "ok", data: out });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ status: "error", message: "Failed to fetch livedetails" });
  }
}

// GET /api/livedetails/:empid?date=YYYY-MM-DD
export async function getLiveDetail(req: Request, res: Response) {
  try {
    const empid = req.params.empid;
    const dateQ = (req.query.date as string)?.trim();

    // Employee
    const empQ = await db
      .collection("employees")
      .where("id", "==", empid)
      .limit(1)
      .get();

    if (empQ.empty) {
      return res.status(404).json({ status: "not_found", message: "Employee not found" });
    }
    const employeeDoc = empQ.docs[0].data() as Employee;

    let attendanceDoc: Attendance | null = null;

    if (dateQ) {
      const attQ = await db
        .collection("attendance")
        .where("empid", "==", empid)
        .where("date", "==", dateQ)
        .orderBy("updatedAt", "desc")
        .limit(1)
        .get();
      if (!attQ.empty) attendanceDoc = attQ.docs[0].data() as Attendance;
    } else {
      const today = todayYmdIST();
      let attQ = await db
        .collection("attendance")
        .where("empid", "==", empid)
        .where("date", "==", today)
        .orderBy("updatedAt", "desc")
        .limit(1)
        .get();

      if (!attQ.empty) {
        attendanceDoc = attQ.docs[0].data() as Attendance;
      } else {
        attQ = await db
          .collection("attendance")
          .where("empid", "==", empid)
          .orderBy("updatedAt", "desc")
          .limit(1)
          .get();
        if (!attQ.empty) attendanceDoc = attQ.docs[0].data() as Attendance;
      }
    }

    const out = toUi(employeeDoc, attendanceDoc || {});
    return res.json({ status: "ok", data: out });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ status: "error", message: "Failed to fetch live detail" });
  }
}

