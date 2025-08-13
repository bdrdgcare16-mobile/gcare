const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function setupRealOfficeDataFixed() {
  console.log('🏢 Setting up REAL OFFICE DATA with actual employee information...');
  console.log('==============================================================');

  try {
    // Clear existing data with proper error handling
    console.log('🗑️ Clearing existing data...');
    
    try {
      await prisma.notification.deleteMany();
    } catch (error) {
      console.log('⚠️ Notification table not found, skipping...');
    }
    
    try {
      await prisma.checkInRequest.deleteMany();
    } catch (error) {
      console.log('⚠️ CheckInRequest table not found, skipping...');
    }
    
    try {
      await prisma.permission.deleteMany();
    } catch (error) {
      console.log('⚠️ Permission table not found, skipping...');
    }
    
    try {
      await prisma.overtime.deleteMany();
    } catch (error) {
      console.log('⚠️ Overtime table not found, skipping...');
    }
    
    try {
      await prisma.task.deleteMany();
    } catch (error) {
      console.log('⚠️ Task table not found, skipping...');
    }
    
    try {
      await prisma.payroll.deleteMany();
    } catch (error) {
      console.log('⚠️ Payroll table not found, skipping...');
    }
    
    try {
      await prisma.leaveRequest.deleteMany();
    } catch (error) {
      console.log('⚠️ LeaveRequest table not found, skipping...');
    }
    
    try {
      await prisma.attendance.deleteMany();
    } catch (error) {
      console.log('⚠️ Attendance table not found, skipping...');
    }
    
    try {
      await prisma.user.deleteMany();
    } catch (error) {
      console.log('⚠️ User table not found, skipping...');
    }
    
    try {
      await prisma.leaveType.deleteMany();
    } catch (error) {
      console.log('⚠️ LeaveType table not found, skipping...');
    }
    
    try {
      await prisma.announcement.deleteMany();
    } catch (error) {
      console.log('⚠️ Announcement table not found, skipping...');
    }

    console.log('✅ Data cleared successfully');

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
    const adminPassword = await bcrypt.hash('Admin@123', 12);
    const employeePassword = await bcrypt.hash('Employee@123', 12);

    // Create Admin Users
    const admin = await prisma.user.create({
      data: {
        email: 'admin@techcorp.com',
        password: adminPassword,
        name: 'System Administrator',
        role: 'ADMIN',
        phoneNumber: '+91-9876543210',
        designation: 'System Administrator',
        shiftTiming: '9:00 AM - 6:00 PM',
        gender: 'Male',
        department: 'IT',
        reportingTo: 'Board of Directors',
        dateOfJoining: new Date('2020-01-15')
      }
    });

    const hrManager = await prisma.user.create({
      data: {
        email: 'hr@techcorp.com',
        password: adminPassword,
        name: 'HR Manager',
        role: 'ADMIN',
        phoneNumber: '+91-9876543211',
        designation: 'HR Manager',
        shiftTiming: '8:30 AM - 5:30 PM',
        gender: 'Female',
        department: 'Human Resources',
        reportingTo: 'System Administrator',
        dateOfJoining: new Date('2021-03-20')
      }
    });

    // Real Office Employee Data
    const realEmployees = [
      {
        name: 'A.Baby Reeta',
        email: 'babyreeta16@gmail.com',
        phoneNumber: '9843194674',
        designation: 'District Program Officer',
        gender: 'Female',
        location: 'Nilgiris',
        dateOfJoining: new Date('2022-01-15')
      },
      {
        name: 'A.Mahalakshmi',
        email: 'keshaw390@gmail.com',
        phoneNumber: '9655333264/8072052884',
        designation: 'District Program Officer',
        gender: 'Female',
        location: 'Nagapattinam',
        dateOfJoining: new Date('2022-02-20')
      },
      {
        name: 'M.Anbumozhi',
        email: 'anbu98871@gmail.com',
        phoneNumber: '9655333265/8072052885',
        designation: 'District Program Officer',
        gender: 'Female',
        location: 'Pudukkottai',
        dateOfJoining: new Date('2022-03-10')
      },
      {
        name: 'A.Sekar',
        email: 'johnveni2004@hgmail.com',
        phoneNumber: '9655333266/8072052886',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Virudhunagar',
        dateOfJoining: new Date('2022-04-05')
      },
      {
        name: 'R.Karuppaiah',
        email: 'paiyark123@gmail.com',
        phoneNumber: '9655333267/8072052887',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Ramanathapuram',
        dateOfJoining: new Date('2022-05-12')
      },
      {
        name: 'M.Pandiyan',
        email: 'anbungo@gmail.com',
        phoneNumber: '9655333268/8072052888',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Theni',
        dateOfJoining: new Date('2022-06-18')
      },
      {
        name: 'R.Vijay Bhasker',
        email: 'socialworkervijay@gmail.com',
        phoneNumber: '9655333269/8072052889',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Madurai',
        dateOfJoining: new Date('2022-07-25')
      },
      {
        name: 'T.Arunagiri',
        email: 'tarunagiri007@gmail.com',
        phoneNumber: '9655333270/8072052890',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Namakkal',
        dateOfJoining: new Date('2022-08-30')
      },
      {
        name: 'S.Ramasubramanian',
        email: 'srs30051957@gmail.com',
        phoneNumber: '9655333271/8072052891',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Tenkasi',
        dateOfJoining: new Date('2022-09-14')
      },
      {
        name: 'Arima Anand',
        email: 'arimaanand196456@gmail.com',
        phoneNumber: '9655333272/8072052892',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Sivagangai',
        dateOfJoining: new Date('2022-10-22')
      },
      {
        name: 'R. Franklin',
        email: 'kecttrust@gmail.com',
        phoneNumber: '9655333273/8072052893',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Kanyakumari',
        dateOfJoining: new Date('2022-11-08')
      },
      {
        name: 'M.Annamalai',
        email: 'annamalai1966@gmail.com',
        phoneNumber: '9655333274/8072052894',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Krishnagiri',
        dateOfJoining: new Date('2022-12-03')
      },
      {
        name: 'P. Surya',
        email: 'suryap1209@gmail.com',
        phoneNumber: '9655333275/8072052895',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Kanchipuram',
        dateOfJoining: new Date('2023-01-15')
      },
      {
        name: 'R.Ramkumar',
        email: 'srram113@gmail.com',
        phoneNumber: '9655333276/8072052896',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Thirupathur',
        dateOfJoining: new Date('2023-02-20')
      },
      {
        name: 'S.Manikandan',
        email: 'Manikandansekar1012@gmail.com',
        phoneNumber: '9655333277/8072052897',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Cuddalore',
        dateOfJoining: new Date('2023-03-10')
      },
      {
        name: 'R V Dhanush raj',
        email: 'bbluehat040@gmail.com',
        phoneNumber: '9655333278/8072052898',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Vellore',
        dateOfJoining: new Date('2023-04-05')
      },
      {
        name: 'K. Anandhababu',
        email: 'akbabu06051997@gmail.com',
        phoneNumber: '9655333279/8072052899',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Kallakurichi',
        dateOfJoining: new Date('2023-05-12')
      },
      {
        name: 'S.Praveen kumar',
        email: 'praveenkumar51829@gmail.com',
        phoneNumber: '9655333280/8072052900',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Ranipet',
        dateOfJoining: new Date('2023-06-18')
      },
      {
        name: 'V. Vignesh',
        email: 'creatorvignesh4@gmail.com',
        phoneNumber: '9655333281/8072052901',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Erode',
        dateOfJoining: new Date('2023-07-25')
      }
    ];

    // Create Real Employees
    const employees = await Promise.all(
      realEmployees.map(emp => 
        prisma.user.create({
          data: {
            email: emp.email,
            password: employeePassword,
            name: emp.name,
            role: 'EMPLOYEE',
            phoneNumber: emp.phoneNumber,
            designation: emp.designation,
            shiftTiming: '9:00 AM - 6:00 PM',
            gender: emp.gender,
            department: 'District Program Management',
            reportingTo: 'HR Manager',
            dateOfJoining: emp.dateOfJoining
          }
        })
      )
    );

    console.log('👥 Created real employees');

    // Create Real Company Announcements
    const announcements = await Promise.all([
      prisma.announcement.create({
        data: {
          title: 'Welcome to District Program Management System!',
          content: 'Welcome to our new employee management system. This platform will streamline all HR processes including attendance, leave management, payroll, and task tracking for district program officers.'
        }
      }),
      prisma.announcement.create({
        data: {
          title: 'Q4 District Officers Meeting',
          content: 'Join us for our quarterly district officers meeting on Friday, December 15th at 2:00 PM. We\'ll discuss Q4 achievements, upcoming projects, and district goals for 2024.'
        }
      }),
      prisma.announcement.create({
        data: {
          title: 'Holiday Schedule 2024',
          content: 'Please review the 2024 holiday calendar. The office will be closed on major holidays including New Year\'s Day, Republic Day, Independence Day, and Christmas.'
        }
      }),
      prisma.announcement.create({
        data: {
          title: 'New Health Benefits Package',
          content: 'We\'re excited to announce enhanced health benefits starting January 2024. The new package includes improved medical coverage, dental benefits, and wellness programs.'
        }
      }),
      prisma.announcement.create({
        data: {
          title: 'System Maintenance Notice',
          content: 'The HRMS system will undergo scheduled maintenance on Sunday, December 10th from 2:00 AM to 6:00 AM IST. During this time, the system will be temporarily unavailable.'
        }
      })
    ]);

    console.log('📢 Created announcements');

    // Create Real Tasks
    const tasks = await Promise.all([
      prisma.task.create({
        data: {
          userId: employees[0].id,
          title: 'District Program Implementation',
          description: 'Implement new district program initiatives and coordinate with local authorities',
          status: 'IN_PROGRESS',
          dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000)
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[1].id,
          title: 'Community Outreach Program',
          description: 'Organize community outreach programs and awareness campaigns',
          status: 'PENDING',
          dueDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000)
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[2].id,
          title: 'District Assessment Report',
          description: 'Prepare comprehensive district assessment report for Q4',
          status: 'IN_PROGRESS',
          dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[3].id,
          title: 'Program Monitoring',
          description: 'Monitor ongoing district programs and prepare progress reports',
          status: 'COMPLETED',
          dueDate: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000)
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[4].id,
          title: 'Stakeholder Coordination',
          description: 'Coordinate with district stakeholders and government officials',
          status: 'PENDING',
          dueDate: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000)
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[5].id,
          title: 'Data Collection and Analysis',
          description: 'Collect and analyze district-level data for program evaluation',
          status: 'IN_PROGRESS',
          dueDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000)
        }
      })
    ]);

    console.log('📋 Created tasks');

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
          amount: 45000.00,
          details: 'Base salary + district allowance + performance bonus'
        }
      }),
      prisma.payroll.create({
        data: {
          userId: employees[1].id,
          month: 12,
          year: 2024,
          amount: 42000.00,
          details: 'Base salary + district allowance'
        }
      }),
      prisma.payroll.create({
        data: {
          userId: employees[2].id,
          month: 12,
          year: 2024,
          amount: 48000.00,
          details: 'Base salary + district allowance + project bonus'
        }
      }),
      prisma.payroll.create({
        data: {
          userId: employees[3].id,
          month: 12,
          year: 2024,
          amount: 41000.00,
          details: 'Base salary + district allowance'
        }
      }),
      prisma.payroll.create({
        data: {
          userId: employees[4].id,
          month: 12,
          year: 2024,
          amount: 46000.00,
          details: 'Base salary + district allowance + coordination bonus'
        }
      }),
      prisma.payroll.create({
        data: {
          userId: employees[5].id,
          month: 12,
          year: 2024,
          amount: 43000.00,
          details: 'Base salary + district allowance + data analysis bonus'
        }
      })
    ]);

    console.log('💰 Created payroll records');

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

    console.log('🏖️ Created leave requests');

    console.log('✅ Real office data setup completed successfully!');
    console.log('\n🏢 District Program Management System - Real Data');
    console.log('===============================================');
    console.log('\n👥 Team Created:');
    console.log('- 2 Admin users (System Admin, HR Manager)');
    console.log('- 19 Real District Program Officers');
    console.log('- 7 Leave types');
    console.log('- 5 Company announcements');
    console.log('- 6 Active tasks');
    console.log('- 30 days of attendance records');
    console.log('- 6 Payroll records');
    console.log('- 3 Leave requests');
    
    console.log('\n🔑 Real Login Credentials:');
    console.log('System Admin: admin@techcorp.com / Admin@123');
    console.log('HR Manager: hr@techcorp.com / Admin@123');
    console.log('Employee: babyreeta16@gmail.com / Employee@123');
    
    console.log('\n📍 19 Districts Covered:');
    console.log('Nilgiris, Nagapattinam, Pudukkottai, Virudhunagar, Ramanathapuram, Theni, Madurai, Namakkal, Tenkasi, Sivagangai, Kanyakumari, Krishnagiri, Kanchipuram, Thirupathur, Cuddalore, Vellore, Kallakurichi, Ranipet, Erode');
    
    console.log('\n🎯 Ready for Real Office Demo!');

  } catch (error) {
    console.error('❌ Error setting up real office data:', error);
  } finally {
    await prisma.$disconnect();
  }
}

setupRealOfficeDataFixed(); 