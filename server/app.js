
// // // // app.js
// // // const express = require('express');
// // // const cors = require('cors');
// // // const dotenv = require('dotenv');
// // // const cron = require('node-cron');
// // // dotenv.config();

// // // // ─── Firebase DB ───────────────────────────────────────────
// // // const { db } = require('./config/firebase');

// // // // ─── Swagger ───────────────────────────────────────────────
// // // const swaggerUi   = require('swagger-ui-express');
// // // const swaggerSpec = require('./swagger');

// // // // ─── Route Imports ─────────────────────────────────────────
// // // const authRoutes         = require('./routes/auth');
// // // const attendanceRoutes   = require('./routes/attendance');
// // // const leaveRoutes        = require('./routes/leave');
// // // const taskRoutes         = require('./routes/task');
// // // const shiftsRouter       = require('./routes/shifts');
// // // const employeesRouter    = require('./routes/employees');
// // // const reportRoutes       = require('./routes/reports');
// // // const rewardRoutes       = require('./routes/rewards')(db);
// // // const eventRoutes        = require('./routes/events')(db);
// // // const feedbackRoutes     = require('./routes/feedback')(db);
// // // const companyRoutes      = require('./routes/company');
// // // const staticRoutes       = require('./routes/static');
// // // const fileRoutes         = require('./routes/files');
// // // const trackRoutes        = require('./routes/track');
// // // const officeLocationRoutes = require('./routes/officelocation');

// // // // ─── Report Scheduler Setup ─────────────────────────────────
// // // const reportService = require('./services/reportService');
// // // const REPORTS       = 'reports';
// // // async function registerAllJobs() {
// // //   try {
// // //     const snap = await db.collection(REPORTS).get();
// // //     snap.docs.forEach(doc => {
// // //       const cfg = doc.data();
// // //       cron.schedule(cfg.scheduleTime, () => {
// // //         reportService.runReport(cfg);
// // //       });
// // //     });
// // //     console.log('✅ All report‐scheduler jobs registered');
// // //   } catch (err) {
// // //     console.error('❌ Failed to register cron jobs:', err);
// // //   }
// // // }

// // // // ─── App Initialization ────────────────────────────────────
// // // const app = express();
// // // app.use(cors());

// // // // ←――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
// // // // Add this _once_, before any `app.use('/api/…')`:
// // // //  
// // // app.use(express.json());           
// // // app.use(express.urlencoded({ extended: true }));
// // // // ←――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

// // // app.use('/api/auth',          authRoutes);
// // // app.use('/api/attendance',    attendanceRoutes);
// // // app.use('/api/leaves',        leaveRoutes);
// // // app.use('/api/tasks',         taskRoutes);
// // // app.use('/api/shifts',        shiftsRouter);
// // // app.use('/api/employees',     employeesRouter);
// // // app.use('/api/reports',       reportRoutes);
// // // app.use('/api/rewards',       rewardRoutes);
// // // app.use('/api/events',        eventRoutes);
// // // app.use('/api/feedback',      feedbackRoutes);
// // // app.use('/api/company',       companyRoutes);
// // // app.use('/api/static',        staticRoutes);
// // // app.use('/api/files',         fileRoutes);
// // // app.use('/api/track',         trackRoutes);
// // // app.use('/api/officelocation', officeLocationRoutes);
// // // app.use('/uploads', express.static('uploads'));

// // // // ─── Swagger UI ───────────────────────────────────────────
// // // app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// // // // ─── 404 & Error Handlers ─────────────────────────────────
// // // app.use((req, res) => res.status(404).json({ error: 'Not found' }));
// // // app.use((err, req, res, next) => {
// // //   console.error('Unhandled error:', err);
// // //   res.status(500).json({ error: err.message || 'Server error' });
// // // });

// // // // ─── Start Server ─────────────────────────────────────────
// // // const PORT = process.env.PORT || 3000;
// // // app.listen(PORT, () => {
// // //   console.log(`🚀 Server running on port ${PORT}`);
// // //   registerAllJobs();
// // // });
// // // app.js
// // const path = require('path');
// // const express = require('express');
// // const cors = require('cors');
// // const dotenv = require('dotenv');
// // const cron = require('node-cron');
// // const fileUpload = require('express-fileupload'); // ✅ multipart support
// // dotenv.config();

// // // ─── Firebase DB ───────────────────────────────────────────
// // const { db } = require('./config/firebase');

// // // ─── Swagger ───────────────────────────────────────────────
// // const swaggerUi   = require('swagger-ui-express');
// // const swaggerSpec = require('./swagger');

// // // ─── Route Imports ─────────────────────────────────────────
// // const authRoutes           = require('./routes/auth');
// // const attendanceRoutes     = require('./routes/attendance');
// // const leaveRoutes          = require('./routes/leave');
// // const taskRoutes           = require('./routes/task');
// // const shiftsRouter         = require('./routes/shifts');
// // const employeesRouter      = require('./routes/employees');
// // const reportRoutes         = require('./routes/reports');
// // const rewardRoutes         = require('./routes/rewards')(db);
// // const eventRoutes          = require('./routes/events')(db); // ⬅️ events router (multipart)
// // const feedbackRoutes       = require('./routes/feedback')(db);
// // const companyRoutes        = require('./routes/company');
// // const staticRoutes         = require('./routes/static');
// // const fileRoutes           = require('./routes/files');
// // const trackRoutes          = require('./routes/track');
// // const officeLocationRoutes = require('./routes/officelocation');

// // // ─── Report Scheduler Setup ─────────────────────────────────
// // const reportService = require('./services/reportService');
// // const REPORTS = 'reports';
// // async function registerAllJobs() {
// //   try {
// //     const snap = await db.collection(REPORTS).get();
// //     snap.docs.forEach(doc => {
// //       const cfg = doc.data();
// //       cron.schedule(cfg.scheduleTime, () => {
// //         reportService.runReport(cfg);
// //       });
// //     });
// //     console.log('✅ All report‐scheduler jobs registered');
// //   } catch (err) {
// //     console.error('❌ Failed to register cron jobs:', err);
// //   }
// // }

// // // ─── App Initialization ────────────────────────────────────
// // const app = express();

// // /* 1) CORS first */
// // app.use(cors({ origin: true, credentials: true }));
// // app.options('*', cors());

// // /* 2) ✅ Multipart parser BEFORE other body parsers */
// // app.use(fileUpload({
// //   createParentPath: true,
// //   limits: { fileSize: 20 * 1024 * 1024 }, // 20 MB
// //   abortOnLimit: true,
// // }));

// // /* 3) Static for uploaded files */
// // app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// // /* 4) Other parsers (for JSON routes) */
// // app.use(express.json({ limit: '5mb' }));
// // app.use(express.urlencoded({ extended: true }));

// // // ─── API Routes ────────────────────────────────────────────
// // app.use('/api/auth',            authRoutes);
// // app.use('/api/attendance',      attendanceRoutes);
// // app.use('/api/leaves',          leaveRoutes);
// // app.use('/api/tasks',           taskRoutes);
// // app.use('/api/shifts',          shiftsRouter);
// // app.use('/api/employees',       employeesRouter);
// // app.use('/api/reports',         reportRoutes);
// // app.use('/api/rewards',         rewardRoutes);
// // app.use('/api/events',          eventRoutes);     // ⬅️ now receives req.body + req.files
// // app.use('/api/feedback',        feedbackRoutes);
// // app.use('/api/company',         companyRoutes);
// // app.use('/api/static',          staticRoutes);
// // app.use('/api/files',           fileRoutes);
// // app.use('/api/track',           trackRoutes);
// // app.use('/api/officelocation',  officeLocationRoutes);
// // app.use('/api/leave-types', require('./routes/leaveTypes'));

// // // ─── Swagger UI ───────────────────────────────────────────
// // app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// // // ─── 404 & Error Handlers ─────────────────────────────────
// // app.use((req, res) => res.status(404).json({ error: 'Not found' }));
// // app.use((err, req, res, next) => {
// //   console.error('Unhandled error:', err);
// //   res.status(500).json({ error: err.message || 'Server error' });
// // });

// // // ─── Start Server ─────────────────────────────────────────
// // const PORT = process.env.PORT || 3000;
// // app.listen(PORT, () => {
// //   console.log(`🚀 Server running on port ${PORT}`);
// //   console.log(`📘 Swagger:  http://localhost:${PORT}/api-docs`);
// //   registerAllJobs();
// // });
// // app.js
// const path = require('path');
// const express = require('express');
// const cors = require('cors');
// const dotenv = require('dotenv');
// const cron = require('node-cron');
// const fileUpload = require('express-fileupload'); // multipart/form-data support

// dotenv.config();

// // ─── Firebase DB ───────────────────────────────────────────
// const { db } = require('./config/firebase');

// // ─── Swagger ───────────────────────────────────────────────
// const swaggerUi = require('swagger-ui-express');
// const swaggerSpec = require('./swagger');

// // ─── Route Imports ─────────────────────────────────────────
// const authRoutes           = require('./routes/auth');
// const attendanceRoutes     = require('./routes/attendance');
// const leaveRoutes          = require('./routes/leave');
// const taskRoutes           = require('./routes/task');      // <- tasks router
// const shiftsRouter         = require('./routes/shifts');
// const employeesRouter      = require('./routes/employees');
// const reportRoutes         = require('./routes/reports');
// const rewardRoutes         = require('./routes/rewards')(db);
// const eventRoutes          = require('./routes/events')(db);
// const feedbackRoutes       = require('./routes/feedback')(db);
// const companyRoutes        = require('./routes/company');
// const staticRoutes         = require('./routes/static');
// const fileRoutes           = require('./routes/files');
// const trackRoutes          = require('./routes/track');
// const officeLocationRoutes = require('./routes/officelocation');
// const leaveTypesRoutes     = require('./routes/leaveTypes');

// // ─── Report Scheduler Setup ─────────────────────────────────
// const reportService = require('./services/reportService');
// const REPORTS = 'reports';

// async function registerAllJobs() {
//   try {
//     const snap = await db.collection(REPORTS).get();
//     snap.docs.forEach((doc) => {
//       const cfg = doc.data();
//       if (cfg?.scheduleTime) {
//         cron.schedule(cfg.scheduleTime, () => reportService.runReport(cfg));
//       }
//     });
//     console.log('✅ All report-scheduler jobs registered');
//   } catch (err) {
//     console.error('❌ Failed to register cron jobs:', err);
//   }
// }

// // ─── App Initialization ────────────────────────────────────
// const app = express();

// // 1) CORS first
// app.use(cors({ origin: true, credentials: true }));
// app.options('*', cors());

// // 2) Multipart parser BEFORE JSON parsers (for file uploads from Postman/web)
// app.use(
//   fileUpload({
//     createParentPath: true,            // auto-create /uploads/... folders
//     limits: { fileSize: 20 * 1024 * 1024 }, // 20 MB
//     abortOnLimit: true,
//     useTempFiles: false,               // keep in memory; routers can move/save
//   })
// );

// // 3) Static for uploaded files (served back to clients)
// app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// // 4) JSON / URL-encoded parsers
// app.use(express.json({ limit: '5mb' }));
// app.use(express.urlencoded({ extended: true }));

// // ─── Health check ──────────────────────────────────────────
// app.get('/health', (_req, res) => res.json({ ok: true }));

// // ─── API Routes ────────────────────────────────────────────
// app.use('/api/auth',            authRoutes);
// app.use('/api/attendance',      attendanceRoutes);
// app.use('/api/leaves',          leaveRoutes);
// app.use('/api/tasks',           taskRoutes);          // <- /api/tasks/*
// app.use('/api/shifts',          shiftsRouter);
// app.use('/api/employees',       employeesRouter);
// app.use('/api/reports',         reportRoutes);
// app.use('/api/rewards',         rewardRoutes);
// app.use('/api/events',          eventRoutes);
// app.use('/api/feedback',        feedbackRoutes);
// app.use('/api/company',         companyRoutes);
// app.use('/api/static',          staticRoutes);
// app.use('/api/files',           fileRoutes);
// app.use('/api/track',           trackRoutes);
// app.use('/api/officelocation',  officeLocationRoutes);
// app.use('/api/leave-types',     leaveTypesRoutes);

// // ─── Swagger UI ───────────────────────────────────────────
// app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// // ─── 404 & Error Handlers ─────────────────────────────────
// app.use((req, res) => res.status(404).json({ error: 'Not found' }));

// // eslint-disable-next-line no-unused-vars
// app.use((err, req, res, next) => {
//   console.error('Unhandled error:', err);
//   const status = err.status || 500;
//   res.status(status).json({ error: err.message || 'Server error' });
// });

// // ─── Start Server ─────────────────────────────────────────
// const PORT = process.env.PORT || 3000;
// app.listen(PORT, () => {
//   console.log(`🚀 Server running on port ${PORT}`);
//   console.log(`📘 Swagger:  http://localhost:${PORT}/api-docs`);
//   registerAllJobs();
// });
// app.js
const path = require('path');
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const cron = require('node-cron');
const fileUpload = require('express-fileupload'); // used only for /api/events

dotenv.config();

// ─── Firebase DB ───────────────────────────────────────────
const { db } = require('./config/firebase');

// ─── Swagger ───────────────────────────────────────────────
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./swagger');

// ─── Route Imports ─────────────────────────────────────────
const authRoutes           = require('./routes/auth');
const attendanceRoutes     = require('./routes/attendance');
const leaveRoutes          = require('./routes/leave');
const taskRoutes           = require('./routes/task');      // uses Multer internally
const shiftsRouter         = require('./routes/shifts');
const employeesRouter      = require('./routes/employees');
const reportRoutes         = require('./routes/reports');
const rewardRoutes         = require('./routes/rewards')(db);
const eventRoutes          = require('./routes/events')(db); // needs express-fileupload
const feedbackRoutes       = require('./routes/feedback')(db);
const companyRoutes        = require('./routes/company');
const staticRoutes         = require('./routes/static');
const fileRoutes           = require('./routes/files');
const trackRoutes          = require('./routes/track');
const officeLocationRoutes = require('./routes/officelocation');
const leaveTypesRoutes     = require('./routes/leaveTypes');

// ─── Report Scheduler Setup ─────────────────────────────────
const reportService = require('./services/reportService');
const REPORTS = 'reports';

async function registerAllJobs() {
  try {
    const snap = await db.collection(REPORTS).get();
    snap.docs.forEach((doc) => {
      const cfg = doc.data();
      if (cfg?.scheduleTime) {
        cron.schedule(cfg.scheduleTime, () => reportService.runReport(cfg));
      }
    });
    console.log('✅ All report-scheduler jobs registered');
  } catch (err) {
    console.error('❌ Failed to register cron jobs:', err);
  }
}

// ─── App Initialization ────────────────────────────────────
const app = express();

// 1) CORS
app.use(cors({ origin: true, credentials: true }));
app.options('*', cors());

// 2) Static for uploaded files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// 3) JSON / URL-encoded parsers (keep after CORS)
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true }));

// ─── Health check ──────────────────────────────────────────
app.get('/health', (_req, res) => res.json({ ok: true }));

// ─── API Routes ────────────────────────────────────────────
// NOTE: Do NOT use express-fileupload globally; it conflicts with Multer.
// Tasks router uses Multer inside its own routes:
app.use('/api/tasks',           taskRoutes);

// If your events routes need multipart parsing, attach express-fileupload
// only to this mount:
app.use(
  '/api/events',
  fileUpload({
    createParentPath: true,
    limits: { fileSize: 20 * 1024 * 1024 }, // 20 MB
    abortOnLimit: true,
    useTempFiles: false,
  }),
  eventRoutes
);

// The rest are normal JSON routes
app.use('/api/auth',            authRoutes);
app.use('/api/attendance',      attendanceRoutes);
app.use('/api/leaves',          leaveRoutes);
app.use('/api/shifts',          shiftsRouter);
app.use('/api/employees',       employeesRouter);
app.use('/api/reports',         reportRoutes);
app.use('/api/rewards',         rewardRoutes);
app.use('/api/feedback',        feedbackRoutes);
app.use('/api/company',         companyRoutes);
app.use('/api/static',          staticRoutes);
app.use('/api/files',           fileRoutes);
app.use('/api/track',           trackRoutes);
app.use('/api/officelocation',  officeLocationRoutes);
app.use('/api/leave-types',     leaveTypesRoutes);

// ─── Swagger UI ───────────────────────────────────────────
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// ─── 404 & Error Handlers ─────────────────────────────────
app.use((req, res) => res.status(404).json({ error: 'Not found' }));

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  const status = err.status || 500;
  res.status(status).json({ error: err.message || 'Server error' });
});

// ─── Start Server ─────────────────────────────────────────
const PORT = process.env.PORT || 3000;
// app.listen(PORT, () => {
//   console.log(`🚀 Server running on port ${PORT}`);
//   console.log(`📘 Swagger:  http://localhost:${PORT}/api-docs`);
//   registerAllJobs();
// });
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running at http://192.168.1.42:${PORT}`);
  console.log(`📘 Swagger:  http://192.168.1.42:${PORT}/api-docs`);
  registerAllJobs();
});
