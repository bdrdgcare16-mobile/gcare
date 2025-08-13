const { PrismaClient } = require('@prisma/client');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Database configurations
const SQLITE_DB_PATH = path.join(__dirname, '../prisma/dev.db');
const POSTGRES_URL = process.env.DATABASE_URL || 'postgresql://postgres:Nishali@localhost:5432/SERV';

console.log('🚀 Starting SQLite to PostgreSQL Migration...');
console.log('📊 SQLite DB Path:', SQLITE_DB_PATH);
console.log('🐘 PostgreSQL URL:', POSTGRES_URL);

// Initialize connections
const postgresPrisma = new PrismaClient({
  datasources: {
    db: {
      url: POSTGRES_URL,
    },
  },
});

const sqliteDb = new sqlite3.Database(SQLITE_DB_PATH);

// Helper function to promisify SQLite queries
function query(sqliteDb, sql, params = []) {
  return new Promise((resolve, reject) => {
    sqliteDb.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
}

// Helper function to get single row
function get(sqliteDb, sql, params = []) {
  return new Promise((resolve, reject) => {
    sqliteDb.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
}

// Helper function to safely convert dates
function safeDate(dateValue) {
  if (!dateValue) return null;
  
  // If it's already a Date object, return it
  if (dateValue instanceof Date) return dateValue;
  
  // If it's a string, try to parse it
  if (typeof dateValue === 'string') {
    const parsed = new Date(dateValue);
    // Check if the parsed date is valid
    if (!isNaN(parsed.getTime())) {
      return parsed;
    }
  }
  
  // If it's a number (timestamp), try to convert
  if (typeof dateValue === 'number') {
    const parsed = new Date(dateValue);
    if (!isNaN(parsed.getTime())) {
      return parsed;
    }
  }
  
  // If all else fails, return current date
  console.log(`⚠️  Invalid date value: ${dateValue}, using current date`);
  return new Date();
}

async function migrateData() {
  try {
    console.log('🔌 Connecting to databases...');
    
    // Test PostgreSQL connection
    await postgresPrisma.$connect();
    console.log('✅ Connected to PostgreSQL');
    
    // Test SQLite connection
    await new Promise((resolve, reject) => {
      sqliteDb.get('SELECT 1', (err) => {
        if (err) reject(err);
        else resolve();
      });
    });
    console.log('✅ Connected to SQLite');
    
    // Step 1: Migrate Users
    console.log('\n👥 Migrating Users...');
    const users = await query(sqliteDb, 'SELECT * FROM User ORDER BY id');
    console.log(`Found ${users.length} users to migrate`);
    
    for (const user of users) {
      try {
        await postgresPrisma.user.create({
          data: {
            id: user.id,
            email: user.email,
            password: user.password,
            name: user.name,
            role: user.role,
            phoneNumber: user.phoneNumber,
            designation: user.designation,
            shiftTiming: user.shiftTiming,
            gender: user.gender,
            department: user.department,
            reportingTo: user.reportingTo,
            dateOfJoining: safeDate(user.dateOfJoining),
            createdAt: safeDate(user.createdAt),
            updatedAt: safeDate(user.updatedAt),
          },
        });
        console.log(`✅ Migrated user: ${user.email}`);
      } catch (error) {
        if (error.code === 'P2002') {
          console.log(`⚠️  User ${user.email} already exists, skipping...`);
        } else {
          console.error(`❌ Failed to migrate user ${user.email}:`, error.message);
        }
      }
    }
    
    // Step 2: Migrate LeaveTypes
    console.log('\n📋 Migrating LeaveTypes...');
    const leaveTypes = await query(sqliteDb, 'SELECT * FROM LeaveType ORDER BY id');
    console.log(`Found ${leaveTypes.length} leave types to migrate`);
    
    for (const leaveType of leaveTypes) {
      try {
        await postgresPrisma.leaveType.create({
          data: {
            id: leaveType.id,
            name: leaveType.name,
          },
        });
        console.log(`✅ Migrated leave type: ${leaveType.name}`);
      } catch (error) {
        if (error.code === 'P2002') {
          console.log(`⚠️  Leave type ${leaveType.name} already exists, skipping...`);
        } else {
          console.error(`❌ Failed to migrate leave type ${leaveType.name}:`, error.message);
        }
      }
    }
    
    // Step 3: Migrate Announcements
    console.log('\n📢 Migrating Announcements...');
    const announcements = await query(sqliteDb, 'SELECT * FROM Announcement ORDER BY id');
    console.log(`Found ${announcements.length} announcements to migrate`);
    
    for (const announcement of announcements) {
      try {
        await postgresPrisma.announcement.create({
          data: {
            id: announcement.id,
            title: announcement.title,
            content: announcement.content,
            priority: announcement.priority,
            isPinned: Boolean(announcement.isPinned),
            createdAt: safeDate(announcement.createdAt),
            updatedAt: safeDate(announcement.updatedAt),
          },
        });
        console.log(`✅ Migrated announcement: ${announcement.title}`);
      } catch (error) {
        if (error.code === 'P2002') {
          console.log(`⚠️  Announcement ${announcement.title} already exists, skipping...`);
        } else {
          console.error(`❌ Failed to migrate announcement ${announcement.title}:`, error.message);
        }
      }
    }
    
    // Step 4: Migrate Attendance
    console.log('\n⏰ Migrating Attendance...');
    const attendances = await query(sqliteDb, 'SELECT * FROM Attendance ORDER BY id');
    console.log(`Found ${attendances.length} attendance records to migrate`);
    
    for (const attendance of attendances) {
      try {
        await postgresPrisma.attendance.create({
          data: {
            id: attendance.id,
            userId: attendance.userId,
            date: safeDate(attendance.date),
            checkIn: safeDate(attendance.checkIn),
            checkOut: safeDate(attendance.checkOut),
            status: attendance.status,
            approvedBy: attendance.approvedBy || null,
            approvedAt: safeDate(attendance.approvedAt),
          },
        });
        console.log(`✅ Migrated attendance record ID: ${attendance.id}`);
      } catch (error) {
        if (error.code === 'P2002') {
          console.log(`⚠️  Attendance record ${attendance.id} already exists, skipping...`);
        } else {
          console.error(`❌ Failed to migrate attendance ${attendance.id}:`, error.message);
        }
      }
    }
    
    // Step 5: Migrate Tasks
    console.log('\n📝 Migrating Tasks...');
    const tasks = await query(sqliteDb, 'SELECT * FROM Task ORDER BY id');
    console.log(`Found ${tasks.length} tasks to migrate`);
    
    for (const task of tasks) {
      try {
        await postgresPrisma.task.create({
          data: {
            id: task.id,
            userId: task.userId,
            title: task.title,
            description: task.description,
            status: task.status,
            priority: task.priority,
            dueDate: safeDate(task.dueDate),
            assignedBy: task.assignedBy || null,
            assignedAt: safeDate(task.assignedAt),
            completedAt: safeDate(task.completedAt),
            createdAt: safeDate(task.createdAt),
          },
        });
        console.log(`✅ Migrated task: ${task.title}`);
      } catch (error) {
        if (error.code === 'P2002') {
          console.log(`⚠️  Task ${task.title} already exists, skipping...`);
        } else {
          console.error(`❌ Failed to migrate task ${task.title}:`, error.message);
        }
      }
    }
    
    // Step 6: Migrate LeaveRequests
    console.log('\n🏖️ Migrating LeaveRequests...');
    const leaveRequests = await query(sqliteDb, 'SELECT * FROM LeaveRequest ORDER BY id');
    console.log(`Found ${leaveRequests.length} leave requests to migrate`);
    
    for (const leaveRequest of leaveRequests) {
      try {
        await postgresPrisma.leaveRequest.create({
          data: {
            id: leaveRequest.id,
            userId: leaveRequest.userId,
            leaveTypeId: leaveRequest.leaveTypeId,
            startDate: safeDate(leaveRequest.startDate),
            endDate: safeDate(leaveRequest.endDate),
            status: leaveRequest.status,
            reason: leaveRequest.reason,
            approvedBy: leaveRequest.approvedBy || null,
            approvedAt: safeDate(leaveRequest.approvedAt),
            createdAt: safeDate(leaveRequest.createdAt),
          },
        });
        console.log(`✅ Migrated leave request ID: ${leaveRequest.id}`);
      } catch (error) {
        if (error.code === 'P2002') {
          console.log(`⚠️  Leave request ${leaveRequest.id} already exists, skipping...`);
        } else {
          console.error(`❌ Failed to migrate leave request ${leaveRequest.id}:`, error.message);
        }
      }
    }
    
    // Step 7: Migrate Payrolls
    console.log('\n💰 Migrating Payrolls...');
    const payrolls = await query(sqliteDb, 'SELECT * FROM Payroll ORDER BY id');
    console.log(`Found ${payrolls.length} payroll records to migrate`);
    
    for (const payroll of payrolls) {
      try {
        await postgresPrisma.payroll.create({
          data: {
            id: payroll.id,
            userId: payroll.userId,
            month: payroll.month,
            year: payroll.year,
            amount: payroll.amount,
            details: payroll.details,
            createdAt: safeDate(payroll.createdAt),
          },
        });
        console.log(`✅ Migrated payroll record ID: ${payroll.id}`);
      } catch (error) {
        if (error.code === 'P2002') {
          console.log(`⚠️  Payroll record ${payroll.id} already exists, skipping...`);
        } else {
          console.error(`❌ Failed to migrate payroll ${payroll.id}:`, error.message);
        }
      }
    }
    
    // Step 8: Migrate Overtimes
    console.log('\n⏰ Migrating Overtimes...');
    const overtimes = await query(sqliteDb, 'SELECT * FROM Overtime ORDER BY id');
    console.log(`Found ${overtimes.length} overtime records to migrate`);
    
    for (const overtime of overtimes) {
      try {
        await postgresPrisma.overtime.create({
          data: {
            id: overtime.id,
            userId: overtime.userId,
            date: safeDate(overtime.date),
            hours: overtime.hours,
            reason: overtime.reason,
            status: overtime.status,
            approvedBy: overtime.approvedBy || null,
            approvedAt: safeDate(overtime.approvedAt),
            createdAt: safeDate(overtime.createdAt),
          },
        });
        console.log(`✅ Migrated overtime record ID: ${overtime.id}`);
      } catch (error) {
        if (error.code === 'P2002') {
          console.log(`⚠️  Overtime record ${overtime.id} already exists, skipping...`);
        } else {
          console.error(`❌ Failed to migrate overtime ${overtime.id}:`, error.message);
        }
      }
    }
    
    // Step 9: Migrate Permissions
    console.log('\n🔐 Migrating Permissions...');
    const permissions = await query(sqliteDb, 'SELECT * FROM Permission ORDER BY id');
    console.log(`Found ${permissions.length} permission records to migrate`);
    
    for (const permission of permissions) {
      try {
        await postgresPrisma.permission.create({
          data: {
            id: permission.id,
            userId: permission.userId,
            date: safeDate(permission.date),
            startTime: safeDate(permission.startTime),
            endTime: safeDate(permission.endTime),
            reason: permission.reason,
            status: permission.status,
            approvedBy: permission.approvedBy || null,
            approvedAt: safeDate(permission.approvedAt),
            createdAt: safeDate(permission.createdAt),
          },
        });
        console.log(`✅ Migrated permission record ID: ${permission.id}`);
      } catch (error) {
        if (error.code === 'P2002') {
          console.log(`⚠️  Permission record ${permission.id} already exists, skipping...`);
        } else {
          console.error(`❌ Failed to migrate permission ${permission.id}:`, error.message);
        }
      }
    }
    
    // Step 10: Migrate CheckInRequests
    console.log('\n📍 Migrating CheckInRequests...');
    const checkInRequests = await query(sqliteDb, 'SELECT * FROM CheckInRequest ORDER BY id');
    console.log(`Found ${checkInRequests.length} check-in requests to migrate`);
    
    for (const checkInRequest of checkInRequests) {
      try {
        await postgresPrisma.checkInRequest.create({
          data: {
            id: checkInRequest.id,
            userId: checkInRequest.userId,
            date: safeDate(checkInRequest.date),
            checkInTime: safeDate(checkInRequest.checkInTime),
            reason: checkInRequest.reason,
            status: checkInRequest.status,
            approvedBy: checkInRequest.approvedBy || null,
            approvedAt: safeDate(checkInRequest.approvedAt),
            createdAt: safeDate(checkInRequest.createdAt),
          },
        });
        console.log(`✅ Migrated check-in request ID: ${checkInRequest.id}`);
      } catch (error) {
        if (error.code === 'P2002') {
          console.log(`⚠️  Check-in request ${checkInRequest.id} already exists, skipping...`);
        } else {
          console.error(`❌ Failed to migrate check-in request ${checkInRequest.id}:`, error.message);
        }
      }
    }
    
    // Step 11: Migrate Notifications
    console.log('\n🔔 Migrating Notifications...');
    const notifications = await query(sqliteDb, 'SELECT * FROM Notification ORDER BY id');
    console.log(`Found ${notifications.length} notifications to migrate`);
    
    for (const notification of notifications) {
      try {
        await postgresPrisma.notification.create({
          data: {
            id: notification.id,
            userId: notification.userId,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            read: Boolean(notification.read),
            createdAt: safeDate(notification.createdAt),
          },
        });
        console.log(`✅ Migrated notification ID: ${notification.id}`);
      } catch (error) {
        if (error.code === 'P2002') {
          console.log(`⚠️  Notification ${notification.id} already exists, skipping...`);
        } else {
          console.error(`❌ Failed to migrate notification ${notification.id}:`, error.message);
        }
      }
    }
    
    console.log('\n🎉 Migration completed successfully!');
    console.log('📊 Summary:');
    console.log(`   - Users: ${users.length}`);
    console.log(`   - LeaveTypes: ${leaveTypes.length}`);
    console.log(`   - Announcements: ${announcements.length}`);
    console.log(`   - Attendance: ${attendances.length}`);
    console.log(`   - Tasks: ${tasks.length}`);
    console.log(`   - LeaveRequests: ${leaveRequests.length}`);
    console.log(`   - Payrolls: ${payrolls.length}`);
    console.log(`   - Overtimes: ${overtimes.length}`);
    console.log(`   - Permissions: ${permissions.length}`);
    console.log(`   - CheckInRequests: ${checkInRequests.length}`);
    console.log(`   - Notifications: ${notifications.length}`);
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    // Close connections
    await postgresPrisma.$disconnect();
    sqliteDb.close();
    console.log('🔌 Database connections closed');
  }
}

// Run migration
migrateData()
  .then(() => {
    console.log('✅ Migration script completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Migration script failed:', error);
    process.exit(1);
  }); 