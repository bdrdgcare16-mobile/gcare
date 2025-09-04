import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import admin from 'firebase-admin';
import { defineString } from 'firebase-functions/params';

// Initialize Firebase Admin
admin.initializeApp();

// Import routes
import authRoutes from './routes/auth';
import companyRoutes from './routes/company';
import employeeRoutes from './routes/employees';
import attendanceRoutes from './routes/attendance';
import leaveRoutes from './routes/leave';
import leaveTypeRoutes from './routes/leaveTypes';
import officeLocationRoutes from './routes/officeLocation';
import uploadRoutes from './routes/upload';

// Create Express app
const app = express();

// Define parameters
const corsOrigin = defineString('CORS_ORIGIN', { default: '*' });

// Enable CORS
const corsOptions: cors.CorsOptions = {
  origin: corsOrigin.value(),
  optionsSuccessStatus: 200,
};

// Middleware
app.use(cors(corsOptions));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check endpoint
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/company', companyRoutes);
app.use('/api/employees', employeeRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/leaves', leaveRoutes);
app.use('/api/leave-types', leaveTypeRoutes);
app.use('/api/office-locations', officeLocationRoutes);
app.use('/api/uploads', uploadRoutes);

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ 
    status: 'error',
    message: 'Route not found',
    path: req.path,
    method: req.method
  });
});

// Custom error interface
interface AppError extends Error {
  statusCode?: number;
  code?: string;
  name: string;
  message: string;
  stack?: string;
}

// Error handler
app.use((err: AppError, req: Request, res: Response, next: NextFunction) => {
  console.error('Error:', err);
  
  // Handle file upload errors
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({
      status: 'error',
      message: 'File too large. Maximum file size is 5MB.',
    });
  }

  // Handle JWT errors
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    return res.status(401).json({
      status: 'error',
      message: 'Invalid or expired token',
    });
  }

  // Handle validation errors
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      status: 'error',
      message: err.message,
    });
  }

  // Default error handler
  res.status(err.statusCode || 500).json({
    status: 'error',
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
  
  return; // Ensure a value is always returned
});

// Import v2 functions
import { onRequest } from 'firebase-functions/v2/https';

// Define parameters
const region = defineString('REGION', { default: 'us-central1' });
const nodeEnv = defineString('NODE_ENV', { default: 'development' });

// Configure environment variables
process.env.NODE_ENV = nodeEnv.value();

// Export the Express app as a Firebase Function
export const api = onRequest(
  {
    region,
    timeoutSeconds: 120, // Increase timeout for file uploads
    memory: '1GiB', // Use GiB for v2 functions
    minInstances: 0, // Allow scaling to zero when not in use
    maxInstances: 10, // Maximum number of instances
  },
  app
);

// Scheduled functions (example)
// Note: Uncomment and update when you need scheduled tasks
/*
import { onSchedule } from 'firebase-functions/v2/scheduler';

export const scheduledTasks = onSchedule(
  {
    schedule: 'every 24 hours',
    timeZone: 'Asia/Kolkata',
    retryCount: 2,
  },
  async (event) => {
    console.log('Running scheduled tasks at', new Date().toISOString());
    // Add your scheduled tasks here
    return null;
  }
);
*/

// Example scheduled function (uncomment and modify as needed)
// export const scheduledFunction = functions.pubsub
//   .schedule('every 24 hours')
//   .onRun(async (context) => {
//     console.log('This will run every 24 hours!');
//     return null;
//   });
