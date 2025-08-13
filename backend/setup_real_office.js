const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function setupRealOffice() {
  console.log('🏢 Setting up REAL OFFICE DATA with workflows...');
  console.log('===============================================');

  try {
    // Clear existing data
    await prisma.notification.deleteMany();
    await prisma.checkInRequest.deleteMany();
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
      prisma.leaveType.create({ data: { name: 'Annual Leave' } }),
      prisma.leaveType.create({ data: { name: 'Sick Leave' } }),
      prisma.leaveType.create({ data: { name: 'Personal Leave' } }),
      prisma.leaveType.create({ data: { name: 'Maternity Leave' } }),
      prisma.leaveType.create({ data: { name: 'Paternity Leave' } }),
      prisma.leaveType.create({ data: { name: 'Bereavement Leave' } }),
      prisma.leaveType.create({ data: { name: 'Study Leave' } })
    ]);

    // Hash passwords
    const adminPassword = await bcrypt.hash('Admin@2024!', 12);
    const employeePassword = await bcrypt.hash('Employee@2024!', 12);

    // Create Admin Users
    const admin = await prisma.user.create({
      data: {
        email: 'admin@techcorp.com',
        password: adminPassword,
        name: 'Michael Johnson',
        role: 'ADMIN',
        phoneNumber: '+1-555-0101',
        designation: 'Chief Executive Officer',
        shiftTiming: '9:00 AM - 6:00 PM',
        gender: 'Male',
        department: 'Executive',
        reportingTo: 'Board of Directors',
        dateOfJoining: new Date('2020-01-15')
      }
    });

    const hrManager = await prisma.user.create({
      data: {
        email: 'hr@techcorp.com',
        password: adminPassword,
        name: 'Sarah Williams',
        role: 'ADMIN',
        phoneNumber: '+1-555-0102',
        designation: 'HR Manager',
        shiftTiming: '8:30 AM - 5:30 PM',
        gender: 'Female',
        department: 'Human Resources',
        reportingTo: 'Michael Johnson',
        dateOfJoining: new Date('2021-03-20')
      }
    });

    const itManager = await prisma.user.create({
      data: {
        email: 'it.manager@techcorp.com',
        password: adminPassword,
        name: 'David Chen',
        role: 'ADMIN',
        phoneNumber: '+1-555-0103',
        designation: 'IT Manager',
        shiftTiming: '9:00 AM - 6:00 PM',
        gender: 'Male',
        department: 'Information Technology',
        reportingTo: 'Michael Johnson',
        dateOfJoining: new Date('2021-06-10')
      }
    });

    // Create Employee Users
    const employees = await Promise.all([
      prisma.user.create({
        data: {
          email: 'alex.martinez@techcorp.com',
          password: employeePassword,
          name: 'Alex Martinez',
          role: 'EMPLOYEE',
          phoneNumber: '+1-555-0201',
          designation: 'Senior Software Engineer',
          shiftTiming: '9:00 AM - 6:00 PM',
          gender: 'Male',
          department: 'Engineering',
          reportingTo: 'David Chen',
          dateOfJoining: new Date('2022-01-15')
        }
      }),
      prisma.user.create({
        data: {
          email: 'emily.rodriguez@techcorp.com',
          password: employeePassword,
          name: 'Emily Rodriguez',
          role: 'EMPLOYEE',
          phoneNumber: '+1-555-0202',
          designation: 'UX/UI Designer',
          shiftTiming: '9:00 AM - 6:00 PM',
          gender: 'Female',
          department: 'Design',
          reportingTo: 'David Chen',
          dateOfJoining: new Date('2022-03-10')
        }
      }),
      prisma.user.create({
        data: {
          email: 'james.wilson@techcorp.com',
          password: employeePassword,
          name: 'James Wilson',
          role: 'EMPLOYEE',
          phoneNumber: '+1-555-0203',
          designation: 'Product Manager',
          shiftTiming: '8:30 AM - 5:30 PM',
          gender: 'Male',
          department: 'Product',
          reportingTo: 'Michael Johnson',
          dateOfJoining: new Date('2021-09-05')
        }
      }),
      prisma.user.create({
        data: {
          email: 'lisa.thompson@techcorp.com',
          password: employeePassword,
          name: 'Lisa Thompson',
          role: 'EMPLOYEE',
          phoneNumber: '+1-555-0204',
          designation: 'Marketing Specialist',
          shiftTiming: '9:00 AM - 6:00 PM',
          gender: 'Female',
          department: 'Marketing',
          reportingTo: 'Sarah Williams',
          dateOfJoining: new Date('2022-05-20')
        }
      }),
      prisma.user.create({
        data: {
          email: 'robert.garcia@techcorp.com',
          password: employeePassword,
          name: 'Robert Garcia',
          role: 'EMPLOYEE',
          phoneNumber: '+1-555-0205',
          designation: 'DevOps Engineer',
          shiftTiming: '9:00 AM - 6:00 PM',
          gender: 'Male',
          department: 'Engineering',
          reportingTo: 'David Chen',
          dateOfJoining: new Date('2022-07-12')
        }
      }),
      prisma.user.create({
        data: {
          email: 'anna.kim@techcorp.com',
          password: employeePassword,
          name: 'Anna Kim',
          role: 'EMPLOYEE',
          phoneNumber: '+1-555-0206',
          designation: 'Data Analyst',
          shiftTiming: '9:00 AM - 6:00 PM',
          gender: 'Female',
          department: 'Analytics',
          reportingTo: 'James Wilson',
          dateOfJoining: new Date('2022-08-15')
        }
      })
    ]);

    console.log('👥 Created professional team');

    // Create Company Announcements
    const announcements = await Promise.all([
      prisma.announcement.create({
        data: {
          title: 'Welcome to TechCorp HRMS!',
          content: 'Welcome to our new employee management system. This platform will streamline all HR processes including attendance, leave management, payroll, and task tracking. Please complete your profile setup and familiarize yourself with the features.'
        }
      }),
      prisma.announcement.create({
        data: {
          title: 'Q4 All-Hands Meeting',
          content: 'Join us for our quarterly all-hands meeting on Friday, December 15th at 2:00 PM in the main conference room. We\'ll discuss Q4 achievements, upcoming projects, and company goals for 2024.'
        }
      }),
      prisma.announcement.create({
        data: {
          title: 'New Check-in Approval System',
          content: 'Starting today, all late check-ins require manager approval. Please submit check-in requests through the system for any arrival after 9:30 AM.'
        }
      }),
      prisma.announcement.create({
        data: {
          title: 'Task Management Update',
          content: 'All tasks are now assigned through the HRMS system. Managers will assign tasks directly to employees, and you can track progress in real-time.'
        }
      })
    ]);

    // Create Tasks with Admin Assignment
    const tasks = await Promise.all([
      prisma.task.create({
        data: {
          userId: employees[0].id, // Alex Martinez
          title: 'Implement User Authentication Module',
          description: 'Develop and integrate secure user authentication system with multi-factor authentication support',
          status: 'IN_PROGRESS',
          priority: 'HIGH',
          dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
          assignedBy: itManager.id
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[1].id, // Emily Rodriguez
          title: 'Design Mobile App Interface',
          description: 'Create responsive mobile UI designs for the new customer portal application',
          status: 'PENDING',
          priority: 'MEDIUM',
          dueDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
          assignedBy: itManager.id
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[2].id, // James Wilson
          title: 'Product Roadmap Planning',
          description: 'Develop Q1 2024 product roadmap and feature prioritization strategy',
          status: 'IN_PROGRESS',
          priority: 'HIGH',
          dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          assignedBy: admin.id
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[3].id, // Lisa Thompson
          title: 'Marketing Campaign Launch',
          description: 'Execute the Q4 marketing campaign for the new product launch',
          status: 'COMPLETED',
          priority: 'URGENT',
          dueDate: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
          assignedBy: hrManager.id,
          completedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[4].id, // Robert Garcia
          title: 'Infrastructure Scaling',
          description: 'Scale cloud infrastructure to handle increased user load and implement monitoring',
          status: 'PENDING',
          priority: 'HIGH',
          dueDate: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000),
          assignedBy: itManager.id
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[5].id, // Anna Kim
          title: 'Customer Analytics Report',
          description: 'Analyze customer behavior data and prepare insights report for management review',
          status: 'IN_PROGRESS',
          priority: 'MEDIUM',
          dueDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
          assignedBy: admin.id
        }
      })
    ]);

    // Create Check-in Requests (Pending Approval)
    const checkInRequests = await Promise.all([
      prisma.checkInRequest.create({
        data: {
          userId: employees[0].id,
          date: new Date(),
          checkInTime: new Date(new Date().setHours(10, 30, 0, 0)),
          reason: 'Traffic delay due to road construction',
          status: 'PENDING'
        }
      }),
      prisma.checkInRequest.create({
        data: {
          userId: employees[1].id,
          date: new Date(),
          checkInTime: new Date(new Date().setHours(9, 45, 0, 0)),
          reason: 'Medical appointment',
          status: 'APPROVED',
          approvedBy: itManager.id,
          approvedAt: new Date()
        }
      }),
      prisma.checkInRequest.create({
        data: {
          userId: employees[2].id,
          date: new Date(Date.now() - 24 * 60 * 60 * 1000), // Yesterday
          checkInTime: new Date(new Date(Date.now() - 24 * 60 * 60 * 1000).setHours(10, 15, 0, 0)),
          reason: 'Family emergency',
          status: 'APPROVED',
          approvedBy: admin.id,
          approvedAt: new Date(Date.now() - 24 * 60 * 60 * 1000)
        }
      })
    ]);

    // Create Leave Requests (Pending Approval)
    const leaveRequests = await Promise.all([
      prisma.leaveRequest.create({
        data: {
          userId: employees[0].id,
          leaveTypeId: leaveTypes[0].id, // Annual Leave
          startDate: new Date('2024-12-20'),
          endDate: new Date('2024-12-27'),
          status: 'PENDING',
          reason: 'Family vacation during holiday season'
        }
      }),
      prisma.leaveRequest.create({
        data: {
          userId: employees[1].id,
          leaveTypeId: leaveTypes[1].id, // Sick Leave
          startDate: new Date('2024-12-05'),
          endDate: new Date('2024-12-06'),
          status: 'APPROVED',
          reason: 'Medical appointment and recovery',
          approvedBy: itManager.id,
          approvedAt: new Date('2024-12-04')
        }
      }),
      prisma.leaveRequest.create({
        data: {
          userId: employees[2].id,
          leaveTypeId: leaveTypes[2].id, // Personal Leave
          startDate: new Date('2024-12-15'),
          endDate: new Date('2024-12-15'),
          status: 'PENDING',
          reason: 'Personal family matter'
        }
      }),
      prisma.leaveRequest.create({
        data: {
          userId: employees[3].id,
          leaveTypeId: leaveTypes[0].id, // Annual Leave
          startDate: new Date('2024-12-25'),
          endDate: new Date('2024-12-26'),
          status: 'APPROVED',
          reason: 'Christmas holiday',
          approvedBy: hrManager.id,
          approvedAt: new Date('2024-12-20')
        }
      })
    ]);

    // Create Notifications
    const notifications = await Promise.all([
      // Task notifications
      prisma.notification.create({
        data: {
          userId: employees[0].id,
          title: 'New Task Assigned',
          message: 'You have been assigned: Implement User Authentication Module',
          type: 'TASK'
        }
      }),
      prisma.notification.create({
        data: {
          userId: employees[1].id,
          title: 'New Task Assigned',
          message: 'You have been assigned: Design Mobile App Interface',
          type: 'TASK'
        }
      }),
      // Leave request notifications for admin
      prisma.notification.create({
        data: {
          userId: itManager.id,
          title: 'Leave Request Pending',
          message: 'Alex Martinez has requested Annual Leave (Dec 20-27)',
          type: 'LEAVE'
        }
      }),
      prisma.notification.create({
        data: {
          userId: admin.id,
          title: 'Leave Request Pending',
          message: 'James Wilson has requested Personal Leave (Dec 15)',
          type: 'LEAVE'
        }
      }),
      // Check-in request notifications
      prisma.notification.create({
        data: {
          userId: itManager.id,
          title: 'Check-in Request Pending',
          message: 'Alex Martinez has submitted a late check-in request',
          type: 'ATTENDANCE'
        }
      }),
      // Announcement notifications
      ...employees.map(emp => 
        prisma.notification.create({
          data: {
            userId: emp.id,
            title: 'New Announcement',
            message: 'Welcome to TechCorp HRMS! - New system launched',
            type: 'ANNOUNCEMENT'
          }
        })
      )
    ]);

    // Create Attendance Records
    const today = new Date();
    const attendanceRecords = [];
    
    // Create attendance for last 30 days
    for (let i = 0; i < 30; i++) {
      const date = new Date(today.getTime() - i * 24 * 60 * 60 * 1000);
      const isWeekend = date.getDay() === 0 || date.getDay() === 6;
      
      if (!isWeekend) {
        employees.forEach((employee, index) => {
          const checkIn = new Date(date.getTime() + (8 + Math.random() * 2) * 60 * 60 * 1000);
          const checkOut = new Date(date.getTime() + (17 + Math.random() * 2) * 60 * 60 * 1000);
          
          attendanceRecords.push({
            userId: employee.id,
            date: date,
            checkIn: checkIn,
            checkOut: checkOut,
            status: 'PRESENT',
            approvedBy: itManager.id,
            approvedAt: date
          });
        });
      }
    }

    await prisma.attendance.createMany({ data: attendanceRecords });

    // Create Payroll Records
    const payrollRecords = await Promise.all([
      prisma.payroll.create({
        data: {
          userId: employees[0].id,
          month: 12,
          year: 2024,
          amount: 8500.00,
          details: 'Base salary + performance bonus + overtime'
        }
      }),
      prisma.payroll.create({
        data: {
          userId: employees[1].id,
          month: 12,
          year: 2024,
          amount: 7200.00,
          details: 'Base salary + design project bonus'
        }
      }),
      prisma.payroll.create({
        data: {
          userId: employees[2].id,
          month: 12,
          year: 2024,
          amount: 9500.00,
          details: 'Base salary + management bonus'
        }
      }),
      prisma.payroll.create({
        data: {
          userId: employees[3].id,
          month: 12,
          year: 2024,
          amount: 6800.00,
          details: 'Base salary + campaign performance bonus'
        }
      }),
      prisma.payroll.create({
        data: {
          userId: employees[4].id,
          month: 12,
          year: 2024,
          amount: 7800.00,
          details: 'Base salary + infrastructure bonus'
        }
      }),
      prisma.payroll.create({
        data: {
          userId: employees[5].id,
          month: 12,
          year: 2024,
          amount: 6500.00,
          details: 'Base salary + analytics bonus'
        }
      })
    ]);

    console.log('✅ Real office data setup completed!');
    console.log('\n🏢 TechCorp HRMS - Real Office Workflows');
    console.log('=========================================');
    console.log('\n👥 Team Created:');
    console.log('- 3 Admin/Management users');
    console.log('- 6 Professional employees');
    console.log('- 7 Leave types');
    console.log('- 4 Company announcements');
    console.log('- 6 Tasks (assigned by admins)');
    console.log('- 3 Check-in requests (pending approval)');
    console.log('- 4 Leave requests (pending approval)');
    console.log('- 15+ Notifications');
    console.log('- 30 days of attendance records');
    console.log('- 6 Payroll records');
    
    console.log('\n🔑 Login Credentials:');
    console.log('CEO: admin@techcorp.com / Admin@2024!');
    console.log('HR Manager: hr@techcorp.com / Admin@2024!');
    console.log('IT Manager: it.manager@techcorp.com / Admin@2024!');
    console.log('Employee: alex.martinez@techcorp.com / Employee@2024!');
    
    console.log('\n🔄 Workflow Features:');
    console.log('- Employee check-in requests → Admin approval');
    console.log('- Admin task assignment → Employee task list');
    console.log('- Employee leave requests → Admin approval');
    console.log('- Real-time notifications');
    console.log('- Attendance tracking with approval');
    
    console.log('\n💼 Departments:');
    console.log('- Executive, HR, IT, Engineering, Design, Product, Marketing, Analytics');
    
    console.log('\n🎯 Ready for Real Office Demo!');

  } catch (error) {
    console.error('❌ Error setting up real office data:', error);
  } finally {
    await prisma.$disconnect();
  }
}

setupRealOffice(); 