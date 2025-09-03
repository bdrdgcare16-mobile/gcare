import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Import controllers
import { register, login, getProfile } from './controllers/authController';
import { uploadSingleFile } from './controllers/uploadController';

// Create Express app
const app = express();

// Enable CORS
const corsOptions: cors.CorsOptions = {
  origin: process.env.CORS_ORIGIN || '*',
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

// Auth routes
app.post('/api/auth/register', register);
app.post('/api/auth/login', login);
app.get('/api/auth/profile', getProfile);

// Upload routes
app.post('/api/uploads/single', uploadSingleFile);

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
import { defineString } from 'firebase-functions/params';

// Define environment variables
const region = defineString('REGION', { default: 'us-central1' });

// Export the Express app as a Firebase Function
export const api = onRequest(
  {
    region: region.value(),
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
