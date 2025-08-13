const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function addRealCompanyData() {
  console.log('🏢 Setting up REAL COMPANY DATA for production sale...');
  console.log('==================================================');

  try {
    // Clear existing test data
    await prisma.permission.deleteMany();
    await prisma.overtime.deleteMany();
    await prisma.task.deleteMany();
    await prisma.payroll.deleteMany();
    await prisma.leaveRequest.deleteMany();
    await prisma.attendance.deleteMany();
    await prisma.user.deleteMany();
    await prisma.leaveType.deleteMany();
    await prisma.announcement.deleteMany();

    console.log('🗑️ Cleared test data');

    // Create Professional Leave Types
    const leaveTypes = await Promise.all([
      prisma.leaveType.create({ data: { name: 'Annual Leave' } }),
      prisma.leaveType.create({ data: { name: 'Sick Leave' } }),
      prisma.leaveType.create({ data: { name: 'Personal Leave' } }),
      prisma.leaveType.create({ data: { name: 'Maternity Leave' } }),
      prisma.leaveType.create({ data: { name: 'Paternity Leave' } }),
      prisma.leaveType.create({ data: { name: 'Bereavement Leave' } }),
      prisma.leaveType.create({ data: { name: 'Study Leave' } })
    ]);

    // Hash passwords with strong security
    const adminPassword = await bcrypt.hash('Admin@2024!', 12);
    const hrPassword = await bcrypt.hash('HR@2024!', 12);
    const managerPassword = await bcrypt.hash('Manager@2024!', 12);
    const employeePassword = await bcrypt.hash('Employee@2024!', 12);

    // Create Professional Admin Team
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
        password: hrPassword,
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
        password: managerPassword,
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

    // Create Real Employee Profiles
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

    // Create Real Company Announcements
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
          title: 'Holiday Schedule 2024',
          content: 'Please review the 2024 holiday calendar. The office will be closed on major holidays including New Year\'s Day, Memorial Day, Independence Day, Labor Day, Thanksgiving, and Christmas.'
        }
      }),
      prisma.announcement.create({
        data: {
          title: 'New Health Benefits Package',
          content: 'We\'re excited to announce enhanced health benefits starting January 2024. The new package includes improved medical coverage, dental benefits, and wellness programs. HR will schedule individual meetings to explain the changes.'
        }
      }),
      prisma.announcement.create({
        data: {
          title: 'System Maintenance Notice',
          content: 'The HRMS system will undergo scheduled maintenance on Sunday, December 10th from 2:00 AM to 6:00 AM EST. During this time, the system will be temporarily unavailable. We apologize for any inconvenience.'
        }
      })
    ]);

    // Create Real Tasks
    const tasks = await Promise.all([
      prisma.task.create({
        data: {
          userId: employees[0].id,
          title: 'Implement User Authentication Module',
          description: 'Develop and integrate secure user authentication system with multi-factor authentication support',
          status: 'IN_PROGRESS',
          dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000)
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[1].id,
          title: 'Design Mobile App Interface',
          description: 'Create responsive mobile UI designs for the new customer portal application',
          status: 'PENDING',
          dueDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000)
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[2].id,
          title: 'Product Roadmap Planning',
          description: 'Develop Q1 2024 product roadmap and feature prioritization strategy',
          status: 'IN_PROGRESS',
          dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[3].id,
          title: 'Marketing Campaign Launch',
          description: 'Execute the Q4 marketing campaign for the new product launch',
          status: 'COMPLETED',
          dueDate: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000)
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[4].id,
          title: 'Infrastructure Scaling',
          description: 'Scale cloud infrastructure to handle increased user load and implement monitoring',
          status: 'PENDING',
          dueDate: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000)
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[5].id,
          title: 'Customer Analytics Report',
          description: 'Analyze customer behavior data and prepare insights report for management review',
          status: 'IN_PROGRESS',
          dueDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000)
        }
      })
    ]);

    // Create Real Attendance Records (Last 30 days)
    const attendanceRecords = [];
    const today = new Date();
    
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
            status: 'PRESENT'
          });
        });
      }
    }

    await prisma.attendance.createMany({ data: attendanceRecords });

    // Create Real Payroll Records
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

    // Create Real Leave Requests
    const leaveRequests = await Promise.all([
      prisma.leaveRequest.create({
        data: {
          userId: employees[0].id,
          leaveTypeId: leaveTypes[0].id,
          startDate: new Date('2024-12-20'),
          endDate: new Date('2024-12-27'),
          status: 'APPROVED',
          reason: 'Family vacation during holiday season'
        }
      }),
      prisma.leaveRequest.create({
        data: {
          userId: employees[1].id,
          leaveTypeId: leaveTypes[1].id,
          startDate: new Date('2024-12-05'),
          endDate: new Date('2024-12-06'),
          status: 'APPROVED',
          reason: 'Medical appointment and recovery'
        }
      }),
      prisma.leaveRequest.create({
        data: {
          userId: employees[2].id,
          leaveTypeId: leaveTypes[2].id,
          startDate: new Date('2024-12-15'),
          endDate: new Date('2024-12-15'),
          status: 'PENDING',
          reason: 'Personal family matter'
        }
      })
    ]);

    console.log('✅ Real company data setup completed!');
    console.log('\n🏢 TechCorp HRMS - Production Ready');
    console.log('====================================');
    console.log('\n👥 Team Created:');
    console.log('- 3 Admin/Management users');
    console.log('- 6 Professional employees');
    console.log('- 7 Leave types');
    console.log('- 5 Company announcements');
    console.log('- 6 Active tasks');
    console.log('- 30 days of attendance records');
    console.log('- 6 Payroll records');
    console.log('- 3 Leave requests');
    
    console.log('\n🔑 Professional Login Credentials:');
    console.log('CEO: admin@techcorp.com / Admin@2024!');
    console.log('HR Manager: hr@techcorp.com / HR@2024!');
    console.log('IT Manager: it.manager@techcorp.com / Manager@2024!');
    console.log('Employee: alex.martinez@techcorp.com / Employee@2024!');
    
    console.log('\n💼 Departments:');
    console.log('- Executive, HR, IT, Engineering, Design, Product, Marketing, Analytics');
    
    console.log('\n🎯 Ready for Professional Demo!');

  } catch (error) {
    console.error('❌ Error setting up real company data:', error);
  } finally {
    await prisma.$disconnect();
  }
}

addRealCompanyData(); 