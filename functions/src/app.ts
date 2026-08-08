// import express, { Request, Response, NextFunction } from "express";
// import cors from "cors";
// import { generalRateLimit, authRateLimit, attendanceRateLimit, trackingRateLimit, uploadRateLimit } from "./middlewares/rateLimitMiddleware";

// // Routes
// import authRoutes from "./routes/authRoutes";
// import companyRoutes from "./routes/companyRoutes";
// import employeeRoutes from "./routes/employeeRoutes";
// import employeeDetailsRoutes from './routes/employeeDetailsRoutes';
// import attendanceRoutes from "./routes/attendanceRoutes";
// import leaveTypeRoutes from "./routes/leaveTypeRoutes";
// import officeLocationRoutes from "./routes/officeLocationRoutes";
// import uploadRoutes from "./routes/uploadRoutes";
// import reportRoutes from "./routes/reportRoutes";
// import rewardRoutes from "./routes/rewardRoutes";
// import feedbackRoutes from "./routes/feedbackRoutes";
// import eventRoutes from "./routes/eventRoutes";
// import shiftRoutes from "./routes/shiftRoutes";
// import taskRoutes from "./routes/taskRoutes";
// import trackingRoutes from "./routes/trackingRoutes";
// import liveEmployeeDetailsRouter from "./routes/liveEmployeeDetailsRoutes";
// import reasonsRouter from "./routes/reasonMasterRoutes";
// import overtimeRoutes from "./routes/overtimeRoutes";
// import adminRoutes from "./routes/adminRoutes";
// import leaveRoutes from './routes/leaveRoutes';

// import * as authController from "./controllers/authController";
// import { db } from "./config/firebase";
// import router from "./routes/authRoutes";
// import billingRoutes from "./routes/billingRoutes";

// const app = express();

// // Trust proxy for proper IP detection behind Firebase/Cloud Run
// app.set('trust proxy', 1);

// // ---------------- Middleware ----------------
// app.use(express.json({ limit: "10mb" }));
// app.use(express.urlencoded({ extended: true, limit: "10mb" }));
// app.use(cors({
//   origin: (origin, callback) => {
//     // Environment-based CORS logic
//     const isDevelopment = process.env.NODE_ENV === 'development' || process.env.FUNCTIONS_EMULATOR === 'true';

//     const allowedOrigins = isDevelopment ? [
//       "http://localhost:3000",
//       "http://127.0.0.1:3000",
//       "http://localhost:8080",
//       "http://127.0.0.1:8080",
//       "https://servappbackend.web.app",
//       "https://api-zmj7dqloiq-uc.a.run.app"
//     ] : [
//       "https://servappbackend.web.app",
//       "https://api-zmj7dqloiq-uc.a.run.app"
//     ];

//     // Allow requests with no origin (mobile apps, curl, etc.)
//     if (!origin) return callback(null, true);

//     if (allowedOrigins.includes(origin)) {
//       return callback(null, true);
//     } else {
//       return callback(new Error('Not allowed by CORS'));
//     }
//   },
//   methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
//   allowedHeaders: [
//     "Content-Type",
//     "Authorization",
//     "x-auth-token",
//     "x-empid",
//     "companyid",
//     "x-company-id",
//     "Cache-Control",
//     "Pragma",
//     "Expires"
//   ]
// }));

// app.options("*", cors());

// // Logger
// app.use((req, _res, next) => {
//   console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl}`);
//   next();
// });

// // ---------------- Health ----------------
// app.get("/", (_req, res) => res.send("API running"));
// app.get("/health", (_req: Request, res: Response) => {
//   res.status(200).json({ status: "ok", timestamp: new Date().toISOString() });
// });

// // ---------------- Rate Limiting ----------------
// app.use(generalRateLimit);

// // ---------------- Routes ----------------
// app.use("/api/auth", authRateLimit, authRoutes);
// app.use("/api/company", generalRateLimit, companyRoutes);
// app.use("/api/employees", generalRateLimit, employeeRoutes);
// app.use("/api/attendance", attendanceRateLimit, attendanceRoutes);
// app.use("/api/employee-details", generalRateLimit, employeeDetailsRoutes);
// app.use("/api/leaves", generalRateLimit, leaveRoutes);
// app.use("/api/leave-types", generalRateLimit, leaveTypeRoutes);
// app.use("/api/office", generalRateLimit, officeLocationRoutes);
// app.use("/api/uploads", uploadRateLimit, uploadRoutes);
// app.use("/api/reports", generalRateLimit, reportRoutes);
// app.use("/api/rewards", generalRateLimit, rewardRoutes);
// app.use("/api/events", generalRateLimit, eventRoutes(db));
// app.use("/api/feedback", generalRateLimit, feedbackRoutes(db));
// app.use("/api/shifts", generalRateLimit, shiftRoutes);
// app.use("/api/tasks", generalRateLimit, taskRoutes);
// app.use("/api/tracking", trackingRateLimit, trackingRoutes);
// app.use("/api/liveEmployeeDetails", generalRateLimit, liveEmployeeDetailsRouter);
// app.use("/api/reasons", generalRateLimit, reasonsRouter);
// app.use("/api/overtime", generalRateLimit, overtimeRoutes);
// app.use("/api/admin", generalRateLimit, adminRoutes);
// app.get("/api/me", authController.getMe);
// app.get("/api/profile", authController.getMe);
// router.use('/api/billing', billingRoutes);

// // ---------------- 404 ----------------
// app.use((req, res) => {
//   res.status(404).json({
//     status: "error",
//     message: "Route not found",
//     path: req.originalUrl,
//   });
// });

// // ---------------- Error Handler ----------------
// app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
//   console.error("Error:", err);

//   return res.status(err.statusCode || 500).json({
//     status: "error",
//     message: err.message || "Internal server error",
//   });
// });

// export default app;
import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import {
  generalRateLimit,
  authRateLimit,
  attendanceRateLimit,
  trackingRateLimit,
  uploadRateLimit,
} from "./middlewares/rateLimitMiddleware";

// Routes
import authRoutes from "./routes/authRoutes";
import companyRoutes from "./routes/companyRoutes";
import employeeRoutes from "./routes/employeeRoutes";
import employeeDetailsRoutes from "./routes/employeeDetailsRoutes";
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
import leaveRoutes from "./routes/leaveRoutes";
import billingRoutes from "./routes/billingRoutes";
import payrollRoutes from "./routes/payrollRoutes";
import onboardingRoutes from "./routes/onboarding.routes";

import * as authController from "./controllers/authController";
import { db } from "./config/firebase";

const app = express();

// Trust proxy for proper IP detection behind Firebase/Cloud Run
app.set("trust proxy", 1);

// ---------------- CORS Middleware ----------------
// This allows:
// 1. Flutter web localhost with any port
// 2. 127.0.0.1 with any port
// 3. deployed Firebase hosting URL
// 4. deployed Cloud Run API URL
// 5. Postman, mobile app, curl, and server-to-server requests with no origin

const corsOptions: cors.CorsOptions = {
  origin: (origin, callback) => {
    // Allow requests with no origin:
    // mobile apps, Postman, curl, server-to-server calls
    if (!origin) {
      return callback(null, true);
    }

    // Allow Flutter web localhost with any random port
    if (
      origin.startsWith("http://localhost:") ||
      origin.startsWith("http://127.0.0.1:")
    ) {
      return callback(null, true);
    }

    const allowedOrigins = [
      "https://servappbackend.web.app",
      "https://api-zmj7dqloiq-uc.a.run.app",
    ];

    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }

    return callback(new Error(`Not allowed by CORS: ${origin}`));
  },
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: [
    "Content-Type",
    "Authorization",
    "x-auth-token",
    "x-empid",
    "companyid",
    "x-company-id",
    "Cache-Control",
    "Pragma",
    "Expires",
  ],
  credentials: true,
};

// CORS should be before routes
app.use(cors(corsOptions));

// Handle preflight OPTIONS requests
app.options("*", cors(corsOptions));

// ---------------- Body Parser Middleware ----------------
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// ---------------- Logger ----------------
app.use((req, _res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl}`);
  next();
});

// ---------------- Health ----------------
app.get("/", (_req: Request, res: Response) => {
  res.send("API running");
});

app.get("/health", (_req: Request, res: Response) => {
  res.status(200).json({
    status: "ok",
    timestamp: new Date().toISOString(),
  });
});

// ---------------- Rate Limiting ----------------
app.use(generalRateLimit);

// ---------------- Routes ----------------
app.use("/api/auth", authRateLimit, authRoutes);
app.use("/api/company", generalRateLimit, companyRoutes);
app.use("/api/employees", generalRateLimit, employeeRoutes);
app.use("/api/attendance", attendanceRateLimit, attendanceRoutes);
app.use("/api/employee-details", generalRateLimit, employeeDetailsRoutes);
app.use("/api/leaves", generalRateLimit, leaveRoutes);
app.use("/api/leave-types", generalRateLimit, leaveTypeRoutes);
app.use("/api/office", generalRateLimit, officeLocationRoutes);
app.use("/api/uploads", uploadRateLimit, uploadRoutes);
app.use("/api/reports", generalRateLimit, reportRoutes);
app.use("/api/rewards", generalRateLimit, rewardRoutes);
app.use("/api/events", generalRateLimit, eventRoutes(db));
app.use("/api/feedback", generalRateLimit, feedbackRoutes(db));
app.use("/api/shifts", generalRateLimit, shiftRoutes);
app.use("/api/tasks", generalRateLimit, taskRoutes);
app.use("/api/tracking", trackingRateLimit, trackingRoutes);
app.use(
  "/api/liveEmployeeDetails",
  generalRateLimit,
  liveEmployeeDetailsRouter,
);
app.use("/api/reasons", generalRateLimit, reasonsRouter);
app.use("/api/overtime", generalRateLimit, overtimeRoutes);
app.use("/api/admin", generalRateLimit, adminRoutes);
app.use("/api/billing", generalRateLimit, billingRoutes);
app.use("/api/payroll", payrollRoutes);
app.use("/api/onboarding", onboardingRoutes);

// Log to confirm payroll routes are registered at startup
// (keeps placement consistent before the final 404 handler)
console.log("[ROUTES] Payroll routes registered");

app.get("/api/me", authController.getMe);
app.get("/api/profile", authController.getMe);

// ---------------- 404 Handler ----------------
app.use((req: Request, res: Response) => {
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
