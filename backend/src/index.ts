import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';
import { createServer } from 'http';

// Load environment variables
dotenv.config();
import authRoutes from './routes/auth';
import userRoutes from './routes/user';
import attendanceRoutes, { setWebSocketManager as setAttendanceWebSocketManager } from './routes/attendance';
import leaveRoutes, { setWebSocketManager as setLeaveWebSocketManager } from './routes/leave';
import payrollRoutes from './routes/payroll';
import announcementRoutes from './routes/announcement';
import taskRoutes, { setWebSocketManager as setTaskWebSocketManager } from './routes/task';
import reportsRoutes from './routes/reports';
import checkinRoutes from './routes/checkin';
import notificationRoutes from './routes/notifications';
import adminRoutes from './routes/admin';
import dashboardRoutes from './routes/dashboard';
import WebSocketManager from './websocket';

const app = express();
const server = createServer(app);

// Initialize Prisma with PostgreSQL configuration
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL || 'postgresql://postgres:Nishali@localhost:5432/SERV',
    },
  },
  log: process.env.NODE_ENV === 'development' ? ['query', 'info', 'warn', 'error'] : ['error'],
});

// Initialize WebSocket
const wsManager = new WebSocketManager(server);

// Enhanced CORS configuration - Allow all localhost ports
app.use(cors({
  origin: true,
  credentials: true,
}));

app.use(express.json());

// Global error handling middleware
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Routes
app.use('/auth', authRoutes);
app.use('/users', userRoutes);
app.use('/attendance', attendanceRoutes);
app.use('/leave', leaveRoutes);
app.use('/payroll', payrollRoutes);
app.use('/announcements', announcementRoutes);
app.use('/tasks', taskRoutes);
app.use('/reports', reportsRoutes);
app.use('/checkin', checkinRoutes);
app.use('/notifications', notificationRoutes);
app.use('/admin', adminRoutes);
app.use('/dashboard', dashboardRoutes);

app.get('/health', async (req, res) => {
  try {
    // Test database connection
    await prisma.$queryRaw`SELECT 1`;
    res.json({ 
      status: 'ok', 
      database: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Database health check failed:', error);
    res.status(503).json({ 
      status: 'error', 
      database: 'disconnected',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

const PORT = process.env.PORT || 8080; // Use port 8080

// Database connection test on startup
async function testDatabaseConnection() {
  try {
    await prisma.$connect();
    console.log('✅ Connected to PostgreSQL database');
    
    // Test basic query
    const userCount = await prisma.user.count();
    console.log(`📊 Database contains ${userCount} users`);
    
  } catch (error) {
    console.error('❌ Failed to connect to PostgreSQL:', error);
    console.log('🔧 Please ensure PostgreSQL is running and accessible');
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down gracefully...');
  await prisma.$disconnect();
  console.log('✅ Database connection closed');
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n🛑 Received SIGTERM, shutting down gracefully...');
  await prisma.$disconnect();
  console.log('✅ Database connection closed');
  process.exit(0);
});

// Start server
async function startServer() {
  try {
    // Test database connection first
    await testDatabaseConnection();
    
    // Wire WebSocket manager to routes that need it
    try {
      setAttendanceWebSocketManager(wsManager);
      setTaskWebSocketManager(wsManager);
      setLeaveWebSocketManager(wsManager);
    } catch (e) {
      console.warn('Could not initialize WebSocket manager for attendance routes:', e);
    }

    // Start HTTP server
    server.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📊 Health check: http://localhost:${PORT}/health`);
      console.log(`🔐 Auth endpoints: http://localhost:${PORT}/auth`);
      console.log(`🔌 WebSocket: ws://localhost:${PORT}`);
      console.log(`🐘 Database: PostgreSQL (SERV)`);
      console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
    });
    
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

startServer(); 