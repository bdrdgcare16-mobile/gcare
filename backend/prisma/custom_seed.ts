import { PrismaClient, Role } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting custom data seeding...');

  // Clear existing data
  await prisma.permission.deleteMany();
  await prisma.overtime.deleteMany();
  await prisma.task.deleteMany();
  await prisma.announcement.deleteMany();
  await prisma.payroll.deleteMany();
  await prisma.leaveRequest.deleteMany();
  await prisma.leaveType.deleteMany();
  await prisma.attendance.deleteMany();
  await prisma.user.deleteMany();

  console.log('🗑️ Cleared existing data');

  // Create Leave Types
  const leaveTypes = await Promise.all([
    prisma.leaveType.create({ data: { name: 'Sick Leave' } }),
    prisma.leaveType.create({ data: { name: 'Personal Leave' } }),
    prisma.leaveType.create({ data: { name: 'Casual Leave' } }),
    prisma.leaveType.create({ data: { name: 'Planned Leave' } }),
    prisma.leaveType.create({ data: { name: 'Maternity Leave' } }),
  ]);

  console.log('📅 Created leave types');

  // Create Users (Employees and Admin)
  const hashedPassword = await bcrypt.hash('password123', 10);

  const users = await Promise.all([
    // Admin
    prisma.user.create({
      data: {
        email: 'admin@nishali.com',
        password: hashedPassword,
        name: 'Nishali Sharma',
        role: Role.ADMIN,
      },
    }),
    // Employees
    prisma.user.create({
      data: {
        email: 'rahul@nishali.com',
        password: hashedPassword,
        name: 'Rahul Verma',
        role: Role.EMPLOYEE,
      },
    }),
    prisma.user.create({
      data: {
        email: 'priya@nishali.com',
        password: hashedPassword,
        name: 'Priya Singh',
        role: Role.EMPLOYEE,
      },
    }),
    prisma.user.create({
      data: {
        email: 'amit@nishali.com',
        password: hashedPassword,
        name: 'Amit Patel',
        role: Role.EMPLOYEE,
      },
    }),
    prisma.user.create({
      data: {
        email: 'sneha@nishali.com',
        password: hashedPassword,
        name: 'Sneha Reddy',
        role: Role.EMPLOYEE,
      },
    }),
    prisma.user.create({
      data: {
        email: 'vikram@nishali.com',
        password: hashedPassword,
        name: 'Vikram Malhotra',
        role: Role.EMPLOYEE,
      },
    }),
  ]);

  console.log('👥 Created users');

  // Create Payroll Records
  const payrollData = [
    { userId: users[1].id, month: 8, year: 2024, amount: 45000, details: 'Basic: 35000, HRA: 8000, DA: 2000' },
    { userId: users[2].id, month: 8, year: 2024, amount: 52000, details: 'Basic: 40000, HRA: 9000, DA: 3000' },
    { userId: users[3].id, month: 8, year: 2024, amount: 38000, details: 'Basic: 30000, HRA: 6000, DA: 2000' },
    { userId: users[4].id, month: 8, year: 2024, amount: 48000, details: 'Basic: 37000, HRA: 8000, DA: 3000' },
    { userId: users[5].id, month: 8, year: 2024, amount: 55000, details: 'Basic: 42000, HRA: 10000, DA: 3000' },
    // Previous month
    { userId: users[1].id, month: 7, year: 2024, amount: 45000, details: 'Basic: 35000, HRA: 8000, DA: 2000' },
    { userId: users[2].id, month: 7, year: 2024, amount: 52000, details: 'Basic: 40000, HRA: 9000, DA: 3000' },
    { userId: users[3].id, month: 7, year: 2024, amount: 38000, details: 'Basic: 30000, HRA: 6000, DA: 2000' },
  ];

  await Promise.all(
    payrollData.map(data => prisma.payroll.create({ data }))
  );

  console.log('💰 Created payroll records');

  // Create Tasks
  const tasks = [
    {
      userId: users[1].id,
      title: 'Complete Project Alpha Documentation',
      description: 'Finish the technical documentation for Project Alpha including API specs and user guides',
      status: 'In Progress',
      dueDate: new Date('2024-08-25'),
    },
    {
      userId: users[2].id,
      title: 'Design New Landing Page',
      description: 'Create modern and responsive landing page design for the company website',
      status: 'Completed',
      dueDate: new Date('2024-08-20'),
    },
    {
      userId: users[3].id,
      title: 'QA Testing for Mobile App',
      description: 'Perform comprehensive testing of the mobile application across different devices',
      status: 'Pending',
      dueDate: new Date('2024-08-30'),
    },
    {
      userId: users[4].id,
      title: 'Marketing Campaign Planning',
      description: 'Plan and strategize the upcoming marketing campaign for Q4',
      status: 'In Progress',
      dueDate: new Date('2024-09-05'),
    },
    {
      userId: users[5].id,
      title: 'Database Optimization',
      description: 'Optimize database queries and improve performance for better user experience',
      status: 'Pending',
      dueDate: new Date('2024-08-28'),
    },
  ];

  await Promise.all(
    tasks.map(data => prisma.task.create({ data }))
  );

  console.log('📋 Created tasks');

  // Create Announcements
  const announcements = [
    {
      title: 'Company Holiday Notice',
      content: 'The office will be closed on August 15th, 2024 for Independence Day. All employees are requested to plan their work accordingly. Have a great holiday!',
    },
    {
      title: 'New Attendance Policy',
      content: 'A new attendance policy will be effective from September 1st, 2024. Please review the updated guidelines in the employee handbook. Key changes include flexible working hours and remote work options.',
    },
    {
      title: 'Team Building Event',
      content: 'We are organizing a team building event on September 15th, 2024. All employees are encouraged to participate. This will include team activities, lunch, and networking opportunities.',
    },
    {
      title: 'Performance Review Schedule',
      content: 'Annual performance reviews will be conducted from September 1st to September 30th, 2024. Please prepare your self-assessment and goals for the next year.',
    },
  ];

  await Promise.all(
    announcements.map(data => prisma.announcement.create({ data }))
  );

  console.log('📢 Created announcements');

  // Create Attendance Records (Last 30 days)
  const attendanceRecords = [];
  const today = new Date();
  
  for (let i = 0; i < 30; i++) {
    const date = new Date(today);
    date.setDate(date.getDate() - i);
    
    // Skip weekends
    if (date.getDay() === 0 || date.getDay() === 6) continue;
    
    // Create attendance for each employee
    for (let i = 1; i < users.length; i++) {
      const userId = users[i].id;
      const status = Math.random() > 0.1 ? 'Present' : (Math.random() > 0.5 ? 'Late' : 'Absent');
      const checkIn = status === 'Present' ? new Date(date.getTime() + 9 * 60 * 60 * 1000) : null;
      const checkOut = status === 'Present' ? new Date(date.getTime() + 18 * 60 * 60 * 1000) : null;
      
      attendanceRecords.push({
        userId,
        date,
        checkIn,
        checkOut,
        status,
      });
    }
  }

  await Promise.all(
    attendanceRecords.map(data => prisma.attendance.create({ data }))
  );

  console.log('📅 Created attendance records');

  // Create Leave Requests
  const leaveRequests = [
    {
      userId: users[1].id,
      leaveTypeId: leaveTypes[0].id, // Sick Leave
      startDate: new Date('2024-08-10'),
      endDate: new Date('2024-08-12'),
      status: 'Approved',
      reason: 'Not feeling well, need rest',
    },
    {
      userId: users[2].id,
      leaveTypeId: leaveTypes[2].id, // Casual Leave
      startDate: new Date('2024-08-15'),
      endDate: new Date('2024-08-15'),
      status: 'Pending',
      reason: 'Personal work',
    },
    {
      userId: users[3].id,
      leaveTypeId: leaveTypes[3].id, // Planned Leave
      startDate: new Date('2024-08-25'),
      endDate: new Date('2024-08-30'),
      status: 'Approved',
      reason: 'Family vacation',
    },
  ];

  await Promise.all(
    leaveRequests.map(data => prisma.leaveRequest.create({ data }))
  );

  console.log('🏖️ Created leave requests');

  // Create Overtime Records
  const overtimeRecords = [
    { userId: users[1].id, date: new Date('2024-08-05'), hours: 2.5, approved: true },
    { userId: users[2].id, date: new Date('2024-08-07'), hours: 1.5, approved: false },
    { userId: users[3].id, date: new Date('2024-08-10'), hours: 3.0, approved: true },
    { userId: users[4].id, date: new Date('2024-08-12'), hours: 2.0, approved: true },
  ];

  await Promise.all(
    overtimeRecords.map(data => prisma.overtime.create({ data }))
  );

  console.log('⏰ Created overtime records');

  // Create Permission Records
  const permissionRecords = [
    {
      userId: users[1].id,
      type: 'Late Arrival',
      startTime: new Date('2024-08-08T10:00:00'),
      endTime: new Date('2024-08-08T18:00:00'),
      status: 'Approved',
    },
    {
      userId: users[2].id,
      type: 'Early Departure',
      startTime: new Date('2024-08-09T09:00:00'),
      endTime: new Date('2024-08-09T15:00:00'),
      status: 'Pending',
    },
  ];

  await Promise.all(
    permissionRecords.map(data => prisma.permission.create({ data }))
  );

  console.log('🕐 Created permission records');

  console.log('✅ Custom data seeding completed successfully!');
  console.log('\n📊 Data Summary:');
  console.log(`👥 Users: ${users.length} (1 Admin, ${users.length - 1} Employees)`);
  console.log(`💰 Payroll Records: ${payrollData.length}`);
  console.log(`📋 Tasks: ${tasks.length}`);
  console.log(`📢 Announcements: ${announcements.length}`);
  console.log(`📅 Attendance Records: ${attendanceRecords.length}`);
  console.log(`🏖️ Leave Requests: ${leaveRequests.length}`);
  console.log(`⏰ Overtime Records: ${overtimeRecords.length}`);
  console.log(`🕐 Permission Records: ${permissionRecords.length}`);
  
  console.log('\n🔑 Login Credentials:');
  console.log('Admin: admin@nishali.com / password123');
  console.log('Employees: rahul@nishali.com, priya@nishali.com, amit@nishali.com, sneha@nishali.com, vikram@nishali.com / password123');
}

main()
  .catch((e) => {
    console.error('❌ Error seeding data:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  }); 