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
import notificationRoutes from "./routes/notificationRoutes";
import policyRoutes from "./routes/policyRoutes";
import organizationRegistrationRoutes from "./routes/organizationRegistrationRoutes";
import platformAdminRegistrationRoutes from "./routes/platformAdminRegistrationRoutes";

import * as authController from "./controllers/authController";

const app = express();

// Trust one proxy in production (Firebase/Cloud Run); use the direct
// connection IP in the Functions emulator so req.socket.remoteAddress
// is available and X-Forwarded-For is not blindly trusted.
app.set(
  "trust proxy",
  process.env.FUNCTIONS_EMULATOR === "true" ? false : 1
);

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

    // Allow Flutter web localhost with any random port — DEV emulator only.
    // In production, browser origins must come from the deployed Hosting sites.
    if (
      process.env.FUNCTIONS_EMULATOR === "true" &&
      (origin.startsWith("http://localhost:") ||
        origin.startsWith("http://127.0.0.1:"))
    ) {
      return callback(null, true);
    }

    const allowedOrigins = [
      "https://servappbackend.web.app",
      "https://serv-platform-admin.web.app",
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
    // Applicant resume credential for the public org-registration API.
    "x-registration-resume-token",
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
// In production (Cloud Run), the service root maps to the function root and
// Express sees the full `/api/<resource>/...` path.
// In the Functions emulator the function name `api` is part of the URL and is
// stripped before reaching Express, so `/api/<resource>` would actually need
// to be requested as `/api/api/<resource>`. Use an empty prefix in emulator.
const apiPrefix = process.env.FUNCTIONS_EMULATOR === 'true' ? '' : '/api';

app.use(`${apiPrefix}/auth`, authRateLimit, authRoutes);
app.use(`${apiPrefix}/company`, generalRateLimit, companyRoutes);
app.use(`${apiPrefix}/employees`, generalRateLimit, employeeRoutes);
app.use(`${apiPrefix}/attendance`, attendanceRateLimit, attendanceRoutes);
app.use(`${apiPrefix}/employee-details`, generalRateLimit, employeeDetailsRoutes);
app.use(`${apiPrefix}/leaves`, generalRateLimit, leaveRoutes);
app.use(`${apiPrefix}/leave-types`, generalRateLimit, leaveTypeRoutes);
app.use(`${apiPrefix}/office`, generalRateLimit, officeLocationRoutes);
app.use(`${apiPrefix}/uploads`, uploadRateLimit, uploadRoutes);
app.use(`${apiPrefix}/reports`, generalRateLimit, reportRoutes);
app.use(`${apiPrefix}/rewards`, generalRateLimit, rewardRoutes);
app.use(`${apiPrefix}/events`, generalRateLimit, eventRoutes());
app.use(`${apiPrefix}/feedback`, generalRateLimit, feedbackRoutes());
app.use(`${apiPrefix}/shifts`, generalRateLimit, shiftRoutes);
app.use(`${apiPrefix}/tasks`, generalRateLimit, taskRoutes);
app.use(`${apiPrefix}/tracking`, trackingRateLimit, trackingRoutes);
app.use(
  `${apiPrefix}/liveEmployeeDetails`,
  generalRateLimit,
  liveEmployeeDetailsRouter,
);
app.use(`${apiPrefix}/reasons`, generalRateLimit, reasonsRouter);
app.use(`${apiPrefix}/overtime`, generalRateLimit, overtimeRoutes);
app.use(`${apiPrefix}/admin`, generalRateLimit, adminRoutes);
app.use(`${apiPrefix}/billing`, generalRateLimit, billingRoutes);
app.use(`${apiPrefix}/payroll`, payrollRoutes);
app.use(`${apiPrefix}/onboarding`, onboardingRoutes);
app.use(`${apiPrefix}/notifications`, generalRateLimit, notificationRoutes);
app.use(`${apiPrefix}/organization`, generalRateLimit, policyRoutes);
// Public org-registration draft endpoints — credential-gated, strict limit.
app.use(
  `${apiPrefix}/org-registration`,
  authRateLimit,
  organizationRegistrationRoutes
);
// Platform Admin registration REVIEW endpoints — super_admin JWT required,
// read-only (Milestone 3D-B). No approval/provisioning actions exist here.
app.use(
  `${apiPrefix}/platform-admin/registrations`,
  generalRateLimit,
  platformAdminRegistrationRoutes
);

// Log to confirm payroll routes are registered at startup
// (keeps placement consistent before the final 404 handler)
console.log("[ROUTES] Payroll routes registered");

app.get(`${apiPrefix}/me`, authController.getMe);
app.get(`${apiPrefix}/profile`, authController.getMe);

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
