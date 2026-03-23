import express, { Request, Response, NextFunction } from "express";
import cors from "cors";

// Routes
import authRoutes from "./routes/authRoutes";
import companyRoutes from "./routes/companyRoutes";
import employeeRoutes from "./routes/employeeRoutes";
import attendanceRoutes from "./routes/attendanceRoutes";
import leaveRoutes from "./routes/healthRoutes";
import leaveTypeRoutes from "./routes/leaveTypeRoutes";
import officeLocationRoutes from "./routes/officeLocationRoutes";
import uploadRoutes from "./routes/uploadRoutes";
import reportRoutes from "./routes/reportRoutes";
import rewardRoutes from "./routes/rewardRoutes";
import feedbackRoutes from "./routes/feedbackRoutes";
import eventRoutes from "./routes/eventRoutes";
import shiftRoutes from "./routes/shiftRoutes";
import taskRoutes from "./routes/taskRoutes";
import trackingRoutes from "./routes/trackingRoutes";
import liveEmployeeDetailsRouter from "./routes/liveEmployeeDetailsRoutes";
import reasonsRouter from "./routes/reasonMasterRoutes";
import overtimeRoutes from "./routes/overtimeRoutes";
import adminRoutes from "./routes/adminRoutes";

import * as authController from "./controllers/authController";
import { db } from "./config/firebase";

const app = express();

// ---------------- Middleware ----------------
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));
app.use(cors());

// Logger
app.use((req, _res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl}`);
  next();
});

// ---------------- Health ----------------
app.get("/", (_req, res) => res.send("API running"));
app.get("/api/health", (_req: Request, res: Response) => {
  res.status(200).json({ status: "ok", timestamp: new Date().toISOString() });
});

// ---------------- Routes ----------------
app.use("/api/auth", authRoutes);
app.use("/api/company", companyRoutes);
app.use("/api/employees", employeeRoutes);
app.use("/api/attendance", attendanceRoutes);
app.use("/api/leaves", leaveRoutes);
app.use("/api/leave-types", leaveTypeRoutes);
app.use("/api/office", officeLocationRoutes);
app.use("/api/uploads", uploadRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/rewards", rewardRoutes);
app.use("/api/events", eventRoutes(db));
app.use("/api/feedback", feedbackRoutes(db));
app.use("/api/shifts", shiftRoutes);
app.use("/api/tasks", taskRoutes);
app.use("/api/tracking", trackingRoutes);
app.use("/api/liveEmployeeDetails", liveEmployeeDetailsRouter);
app.use("/api/reasons", reasonsRouter);
app.use("/api/overtime", overtimeRoutes);
app.use("/api/admin", adminRoutes);

app.get("/api/me", authController.getMe);
app.get("/api/profile", authController.getMe);

// ---------------- 404 ----------------
app.use((req, res) => {
  res.status(404).json({
    status: "error",
    message: "Route not found",
    path: req.originalUrl,
  });
});

// ---------------- Error Handler ----------------
app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
  console.error("Error:", err);

  return res.status(err.statusCode || 500).json({
    status: "error",
    message: err.message || "Internal server error",
  });
});

export default app;