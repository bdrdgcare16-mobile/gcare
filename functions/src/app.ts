import express, { Request, Response, NextFunction } from "express";
import cors from "cors";

// Routes
import authRoutes from "./routes/authRoutes";
import companyRoutes from "./routes/companyRoutes";
import employeeRoutes from "./routes/employeeRoutes";
import employeeDetailsRoutes from './routes/employeeDetailsRoutes';
import attendanceRoutes from "./routes/attendanceRoutes";
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
import leaveRoutes from './routes/leaveRoutes';

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
app.get("/health", (_req: Request, res: Response) => {
  res.status(200).json({ status: "ok", timestamp: new Date().toISOString() });
});

// ---------------- Routes ----------------
app.use("/auth", authRoutes);
app.use("/company", companyRoutes);
app.use("/employees", employeeRoutes);
app.use("/attendance", attendanceRoutes);
app.use("/employee-details", employeeDetailsRoutes);
app.use("/leaves", leaveRoutes);
app.use("/leave-types", leaveTypeRoutes);
app.use("/office", officeLocationRoutes);
app.use("/uploads", uploadRoutes);
app.use("/reports", reportRoutes);
app.use("/rewards", rewardRoutes);
app.use("/events", eventRoutes(db));
app.use("/feedback", feedbackRoutes(db));
app.use("/shifts", shiftRoutes);
app.use("/tasks", taskRoutes);
app.use("/tracking", trackingRoutes);
app.use("/liveEmployeeDetails", liveEmployeeDetailsRouter);
app.use("/reasons", reasonsRouter);
app.use("/overtime", overtimeRoutes);
app.use("/admin", adminRoutes);
app.use('/leaves', leaveRoutes);


app.get("/me", authController.getMe);
app.get("/profile", authController.getMe);

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