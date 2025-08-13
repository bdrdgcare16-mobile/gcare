import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seeding...');

  // Clear existing data
  await prisma.permission.deleteMany();
  await prisma.overtime.deleteMany();
  await prisma.task.deleteMany();
  await prisma.payroll.deleteMany();
  await prisma.leaveRequest.deleteMany();
  await prisma.attendance.deleteMany();
  await prisma.user.deleteMany();
  await prisma.leaveType.deleteMany();
  await prisma.announcement.deleteMany();

  console.log('🗑️ Cleared existing data');

  // Create Leave Types
  const leaveTypes = await Promise.all([
    prisma.leaveType.create({
      data: { name: 'Annual Leave' }
    }),
    prisma.leaveType.create({
      data: { name: 'Sick Leave' }
    }),
    prisma.leaveType.create({
      data: { name: 'Personal Leave' }
    }),
    prisma.leaveType.create({
      data: { name: 'Maternity Leave' }
    })
  ]);

  console.log('📅 Created leave types');

  // Hash passwords
  const adminPassword = await bcrypt.hash('admin123', 10);
  const employeePassword = await bcrypt.hash('employee123', 10);

  // Create Admin User
  const admin = await prisma.user.create({
    data: {
      email: 'admin@nishali.com',
      password: adminPassword,
      name: 'Admin Manager',
      role: 'ADMIN'
    }
  });

  console.log('👨‍💼 Created admin user');

  // Create Employee Users
  const employees = await Promise.all([
    prisma.user.create({
      data: {
        email: 'john.doe@nishali.com',
        password: employeePassword,
        name: 'John Doe',
        role: 'EMPLOYEE'
      }
    }),
    prisma.user.create({
      data: {
        email: 'jane.smith@nishali.com',
        password: employeePassword,
        name: 'Jane Smith',
        role: 'EMPLOYEE'
      }
    }),
    prisma.user.create({
      data: {
        email: 'mike.wilson@nishali.com',
        password: employeePassword,
        name: 'Mike Wilson',
        role: 'EMPLOYEE'
      }
    }),
    prisma.user.create({
      data: {
        email: 'sarah.jones@nishali.com',
        password: employeePassword,
        name: 'Sarah Jones',
        role: 'EMPLOYEE'
      }
    })
  ]);

  console.log('👥 Created employee users');

  // Create Announcements
  const announcements = await Promise.all([
    prisma.announcement.create({
      data: {
        title: 'Welcome to Nishali HRMS!',
        content: 'Welcome to our new employee management system. Please complete your profile setup.'
      }
    }),
    prisma.announcement.create({
      data: {
        title: 'Monthly Team Meeting',
        content: 'Monthly team meeting scheduled for Friday at 2 PM. All employees must attend.'
      }
    }),
    prisma.announcement.create({
      data: {
        title: 'System Maintenance',
        content: 'System will be under maintenance on Sunday from 2 AM to 6 AM.'
      }
    })
  ]);

  console.log('📢 Created announcements');

  // Create Tasks for Employees
  const tasks = await Promise.all([
    prisma.task.create({
      data: {
        userId: employees[0].id,
        title: 'Complete Project Documentation',
        description: 'Finish the documentation for the new feature implementation',
        status: 'PENDING',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days from now
      }
    }),
    prisma.task.create({
      data: {
        userId: employees[1].id,
        title: 'Code Review',
        description: 'Review the pull requests for the authentication module',
        status: 'IN_PROGRESS',
        dueDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000) // 3 days from now
      }
    }),
    prisma.task.create({
      data: {
        userId: employees[2].id,
        title: 'Database Optimization',
        description: 'Optimize the database queries for better performance',
        status: 'PENDING',
        dueDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000) // 5 days from now
      }
    }),
    prisma.task.create({
      data: {
        userId: employees[3].id,
        title: 'UI/UX Testing',
        description: 'Test the new user interface and provide feedback',
        status: 'COMPLETED',
        dueDate: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000) // 2 days ago
      }
    })
  ]);

  console.log('📋 Created tasks');

  // Create Sample Attendance Records
  const today = new Date();
  const yesterday = new Date(today.getTime() - 24 * 60 * 60 * 1000);
  
  const attendanceRecords = await Promise.all([
    // Today's attendance
    prisma.attendance.create({
      data: {
        userId: employees[0].id,
        date: today,
        checkIn: new Date(today.getTime() - 8 * 60 * 60 * 1000), // 8 AM
        checkOut: new Date(today.getTime() - 1 * 60 * 60 * 1000), // 5 PM
        status: 'PRESENT'
      }
    }),
    prisma.attendance.create({
      data: {
        userId: employees[1].id,
        date: today,
        checkIn: new Date(today.getTime() - 7.5 * 60 * 60 * 1000), // 8:30 AM
        status: 'PRESENT'
      }
    }),
    prisma.attendance.create({
      data: {
        userId: employees[2].id,
        date: today,
        status: 'ABSENT'
      }
    }),
    // Yesterday's attendance
    prisma.attendance.create({
      data: {
        userId: employees[0].id,
        date: yesterday,
        checkIn: new Date(yesterday.getTime() - 8 * 60 * 60 * 1000),
        checkOut: new Date(yesterday.getTime() - 1 * 60 * 60 * 1000),
        status: 'PRESENT'
      }
    }),
    prisma.attendance.create({
      data: {
        userId: employees[1].id,
        date: yesterday,
        checkIn: new Date(yesterday.getTime() - 8 * 60 * 60 * 1000),
        checkOut: new Date(yesterday.getTime() - 1 * 60 * 60 * 1000),
        status: 'PRESENT'
      }
    })
  ]);

  console.log('⏰ Created attendance records');

  // Create Sample Payroll Records
  const payrollRecords = await Promise.all([
    prisma.payroll.create({
      data: {
        userId: employees[0].id,
        month: today.getMonth() + 1,
        year: today.getFullYear(),
        amount: 5000.00,
        details: 'Base salary + performance bonus'
      }
    }),
    prisma.payroll.create({
      data: {
        userId: employees[1].id,
        month: today.getMonth() + 1,
        year: today.getFullYear(),
        amount: 4800.00,
        details: 'Base salary'
      }
    })
  ]);

  console.log('💰 Created payroll records');

  // Create Sample Leave Requests
  const leaveRequests = await Promise.all([
    prisma.leaveRequest.create({
      data: {
        userId: employees[0].id,
        leaveTypeId: leaveTypes[0].id, // Annual Leave
        startDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000), // 2 weeks from now
        endDate: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000), // 3 weeks from now
        status: 'PENDING',
        reason: 'Family vacation'
      }
    }),
    prisma.leaveRequest.create({
      data: {
        userId: employees[1].id,
        leaveTypeId: leaveTypes[1].id, // Sick Leave
        startDate: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), // 2 days ago
        endDate: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000), // 1 day ago
        status: 'APPROVED',
        reason: 'Medical appointment'
      }
    })
  ]);

  console.log('🏖️ Created leave requests');

  console.log('✅ Database seeding completed successfully!');
  console.log('\n📊 Sample Data Created:');
  console.log(`- 1 Admin user (admin@nishali.com / admin123)`);
  console.log(`- 4 Employee users (employee@nishali.com / employee123)`);
  console.log(`- 4 Leave types`);
  console.log(`- 3 Announcements`);
  console.log(`- 4 Tasks`);
  console.log(`- 5 Attendance records`);
  console.log(`- 2 Payroll records`);
  console.log(`- 2 Leave requests`);
  
  console.log('\n🔑 Login Credentials:');
  console.log('Admin: admin@nishali.com / admin123');
  console.log('Employee: john.doe@nishali.com / employee123');
}

main()
  .catch((e) => {
    console.error('❌ Error seeding database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  }); 