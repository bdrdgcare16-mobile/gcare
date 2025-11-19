"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.api = void 0;
// functions/src/index.ts
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
// ✅ Ensure firebase-admin is initialized exactly once
const admin = __importStar(require("firebase-admin"));
if (!admin.apps.length) {
    admin.initializeApp();
}
// Shared Firebase (single source of truth)
const firebase_1 = require("./config/firebase");
// Routes
const auth_1 = __importDefault(require("./routes/auth"));
const company_1 = __importDefault(require("./routes/company"));
const employees_1 = __importDefault(require("./routes/employees"));
const attendance_1 = __importDefault(require("./routes/attendance"));
const leave_1 = __importDefault(require("./routes/leave"));
const leaveTypes_1 = __importDefault(require("./routes/leaveTypes"));
const officeLocation_1 = __importDefault(require("./routes/officeLocation"));
const upload_1 = __importDefault(require("./routes/upload"));
const report_1 = __importDefault(require("./routes/report"));
const reward_1 = __importDefault(require("./routes/reward"));
const feedbackRoutes_1 = __importDefault(require("./routes/feedbackRoutes"));
const event_1 = __importDefault(require("./routes/event"));
const shift_1 = __importDefault(require("./routes/shift"));
const task_1 = __importDefault(require("./routes/task"));
const tracking_1 = __importDefault(require("./routes/tracking"));
const liveEmployeeDetails_1 = __importDefault(require("./routes/liveEmployeeDetails"));
const authController = __importStar(require("./controllers/authController"));
const reasons_1 = __importDefault(require("./routes/reasons"));
const overtime_1 = __importDefault(require("./routes/overtime"));
const admin_1 = __importDefault(require("./routes/admin"));
// -------------------- App setup --------------------
const app = (0, express_1.default)();
// Params (do NOT call .value() at module load for function options)
const REGION = (0, params_1.defineString)('REGION', { default: 'us-central1' });
const CORS_ORIGIN = (0, params_1.defineString)('CORS_ORIGIN', { default: 'http://localhost:4500' });
// Body parsers
app.use(express_1.default.json({ limit: '10mb' }));
app.use(express_1.default.urlencoded({ extended: true, limit: '10mb' }));
// Tiny logger
app.use((req, _res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl}`);
    next();
});
// --------- Global no-cache (avoid 304 / empty bodies) ----------
app.set('etag', false);
app.use((req, res, next) => {
    res.setHeader('Cache-Control', 'private, no-store, no-cache, must-revalidate, proxy-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
    // auth changes the response shape
    res.setHeader('Vary', 'Authorization');
    next();
});
// CORS — evaluate allowlist at request time
app.use((req, res, next) => {
    const allowList = (CORS_ORIGIN.value() || '*').split(',').map(s => s.trim());
    (0, cors_1.default)({
        origin(origin, cb) {
            if (!origin)
                return cb(null, true); // curl/Postman
            if (allowList.includes('*') || allowList.includes(origin))
                return cb(null, true);
            return cb(null, false);
        },
        credentials: true,
        optionsSuccessStatus: 200,
    })(req, res, next);
});
// Preflight for all
app.options('*', (_req, res) => res.sendStatus(204));
// Health
app.get('/', (_req, res) => res.send('api1 root ok'));
app.get('/api/health', (_req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});
// -------------------- API routes (mounted once) --------------------
app.use('/api/auth', auth_1.default);
app.use('/api/company', company_1.default);
app.use('/api/employees', employees_1.default);
app.use('/api/attendance', attendance_1.default);
app.use('/api/leaves', leave_1.default);
app.use('/api/leave-types', leaveTypes_1.default);
app.use('/api/office', officeLocation_1.default);
app.use('/api/uploads', upload_1.default);
app.use('/api/reports', report_1.default);
app.use('/api/rewards', reward_1.default);
app.use('/api/events', (0, event_1.default)(firebase_1.db));
app.use('/api/feedback', (0, feedbackRoutes_1.default)(firebase_1.db));
app.use('/api/shifts', shift_1.default);
app.use('/api/tasks', task_1.default);
app.use('/api/tracking', tracking_1.default);
app.use('/api/liveEmployeeDetails', liveEmployeeDetails_1.default);
app.get('/api/me', authController.getMe);
app.get('/api/profile', authController.getMe);
app.use('/api/reasons', reasons_1.default);
app.use("/api/overtime", overtime_1.default);
app.use("/api/admin", admin_1.default);
// -------------------- 404 + error handlers --------------------
app.use((req, res) => {
    res.status(404).json({
        status: 'error',
        message: 'Route not found',
        path: req.originalUrl,
        method: req.method,
    });
});
app.use((err, _req, res, _next) => {
    console.error('Error:', err);
    if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(413).json({
            status: 'error',
            message: 'File too large. Maximum file size is 5MB.',
        });
    }
    if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
        return res.status(401).json({
            status: 'error',
            message: 'Invalid or expired token',
        });
    }
    if (err.name === 'ValidationError') {
        return res.status(400).json({
            status: 'error',
            message: err.message,
        });
    }
    return res.status(err.statusCode || 500).json({
        status: 'error',
        message: err.message || 'Internal server error',
    });
});
// -------------------- Export as Firebase Function --------------------
exports.api = (0, https_1.onRequest)({
    region: REGION,
    timeoutSeconds: 120,
    memory: '1GiB',
    minInstances: 0,
    maxInstances: 10,
}, exports.api = (0, https_1.onRequest)(app));
//# sourceMappingURL=index.js.map