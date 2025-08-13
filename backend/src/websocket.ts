import { Server as SocketIOServer } from 'socket.io';
import { Server as HTTPServer } from 'http';
import { PrismaClient } from '@prisma/client';
import jwt from 'jsonwebtoken';

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'changeme';

interface AuthenticatedSocket {
  userId: number;
  role: string;
  socket: any;
}

class WebSocketManager {
  private io: SocketIOServer;
  private authenticatedSockets: Map<string, AuthenticatedSocket> = new Map();

  constructor(server: HTTPServer) {
    this.io = new SocketIOServer(server, {
      cors: {
        origin: true,
        methods: ["GET", "POST"],
        credentials: false
      }
    });

    this.setupEventHandlers();
  }

  private setupEventHandlers() {
    this.io.on('connection', (socket) => {
      console.log('🔌 New client connected:', socket.id);

      // Authenticate user
      socket.on('authenticate', async (data: { token: string }) => {
        try {
          const decoded = jwt.verify(data.token, JWT_SECRET) as any;
          const user = await prisma.user.findUnique({
            where: { id: decoded.userId }
          });

          if (user) {
            this.authenticatedSockets.set(socket.id, {
              userId: user.id,
              role: user.role,
              socket: socket
            });

            socket.emit('authenticated', { 
              success: true, 
              user: { id: user.id, name: user.name, role: user.role } 
            });

            // Join role-specific rooms
            socket.join(`role_${user.role}`);
            socket.join(`user_${user.id}`);

            console.log(`✅ User ${user.name} (${user.role}) authenticated`);
          }
        } catch (error) {
          socket.emit('authenticated', { success: false, error: 'Invalid token' });
        }
      });

      // Handle attendance check-in/out
      socket.on('attendance_update', async (data: { 
        userId: number, 
        action: 'checkin' | 'checkout', 
        timestamp: string 
      }) => {
        try {
          const attendance = await prisma.attendance.create({
            data: {
              userId: data.userId,
              date: new Date(),
              checkIn: data.action === 'checkin' ? new Date(data.timestamp) : null,
              checkOut: data.action === 'checkout' ? new Date(data.timestamp) : null,
              status: data.action === 'checkin' ? 'Present' : 'Checked Out'
            }
          });

          // Broadcast to all connected clients
          this.io.emit('attendance_updated', {
            userId: data.userId,
            action: data.action,
            timestamp: data.timestamp,
            attendance: attendance
          });

          // Send notification to admins
          this.io.to('role_ADMIN').emit('notification', {
            type: 'attendance',
            message: `Employee ${data.userId} ${data.action === 'checkin' ? 'checked in' : 'checked out'}`,
            timestamp: new Date().toISOString()
          });

        } catch (error) {
          socket.emit('error', { message: 'Failed to update attendance' });
        }
      });

      // Handle task updates
      socket.on('task_update', async (data: { 
        taskId: number, 
        status: string, 
        userId: number 
      }) => {
        try {
          const task = await prisma.task.update({
            where: { id: data.taskId },
            data: { status: data.status }
          });

          // Broadcast task update
          this.io.emit('task_updated', {
            taskId: data.taskId,
            status: data.status,
            task: task
          });

          // Notify task assignee
          this.io.to(`user_${data.userId}`).emit('notification', {
            type: 'task',
            message: `Task "${task.title}" status updated to ${data.status}`,
            timestamp: new Date().toISOString()
          });

        } catch (error) {
          socket.emit('error', { message: 'Failed to update task' });
        }
      });

      // Handle leave request updates
      socket.on('leave_request_update', async (data: { 
        requestId: number, 
        status: string, 
        userId: number 
      }) => {
        try {
          const leaveRequest = await prisma.leaveRequest.update({
            where: { id: data.requestId },
            data: { status: data.status }
          });

          // Broadcast leave request update
          this.io.emit('leave_request_updated', {
            requestId: data.requestId,
            status: data.status,
            leaveRequest: leaveRequest
          });

          // Notify employee
          this.io.to(`user_${data.userId}`).emit('notification', {
            type: 'leave',
            message: `Your leave request has been ${data.status}`,
            timestamp: new Date().toISOString()
          });

        } catch (error) {
          socket.emit('error', { message: 'Failed to update leave request' });
        }
      });

      // Handle new announcements
      socket.on('new_announcement', async (data: { 
        title: string, 
        content: string, 
        adminId: number 
      }) => {
        try {
          const announcement = await prisma.announcement.create({
            data: {
              title: data.title,
              content: data.content
            }
          });

          // Broadcast to all users
          this.io.emit('announcement_created', {
            announcement: announcement
          });

          // Send notification to all employees
          this.io.to('role_EMPLOYEE').emit('notification', {
            type: 'announcement',
            message: `New announcement: ${data.title}`,
            timestamp: new Date().toISOString()
          });

        } catch (error) {
          socket.emit('error', { message: 'Failed to create announcement' });
        }
      });

      // Handle disconnect
      socket.on('disconnect', () => {
        this.authenticatedSockets.delete(socket.id);
        console.log('🔌 Client disconnected:', socket.id);
      });
    });
  }

  // Method to send notifications to specific users
  public sendNotification(userId: number, notification: any) {
    this.io.to(`user_${userId}`).emit('notification', notification);
  }

  // Method to broadcast to all users
  public broadcast(event: string, data: any) {
    this.io.emit(event, data);
  }

  // Method to send to specific role
  public sendToRole(role: string, event: string, data: any) {
    this.io.to(`role_${role}`).emit(event, data);
  }
}

export default WebSocketManager; 