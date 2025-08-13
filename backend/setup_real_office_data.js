const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function setupRealOfficeData() {
  console.log('🏢 Setting up REAL OFFICE DATA with actual employee information...');
  console.log('==============================================================');

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
            department: 'District Programs',
            reportingTo: 'HR Manager',
            dateOfJoining: emp.dateOfJoining
          }
        })
      )
    );

    console.log('👥 Created 19 real employees');

    // Create Company Announcements
    const announcements = await Promise.all([
      prisma.announcement.create({
        data: {
          title: 'Welcome to District Program Management System!',
          content: 'Welcome to our new employee management system for district program officers. This platform will streamline all HR processes including attendance, leave management, payroll, and task tracking. Please complete your profile setup and familiarize yourself with the features.'
        }
      }),
      prisma.announcement.create({
        data: {
          title: 'Monthly District Coordinators Meeting',
          content: 'Monthly district coordinators meeting scheduled for Friday, December 15th at 2:00 PM. All district program officers must attend to discuss program updates and district-wise progress.'
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
          title: 'District Program Updates',
          content: 'Important updates regarding district program implementation. All officers should review the new guidelines and update their progress reports.'
        }
      }),
      prisma.announcement.create({
        data: {
          title: 'Holiday Schedule 2024',
          content: 'Please review the 2024 holiday calendar. The office will be closed on major holidays including New Year\'s Day, Republic Day, Independence Day, and other national holidays.'
        }
      })
    ]);

    // Create Tasks for District Program Officers
    const tasks = await Promise.all([
      prisma.task.create({
        data: {
          userId: employees[0].id, // A.Baby Reeta - Nilgiris
          title: 'District Program Implementation Review',
          description: 'Review and update the implementation status of district programs in Nilgiris region',
          status: 'IN_PROGRESS',
          priority: 'HIGH',
          dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
          assignedBy: admin.id
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[1].id, // A.Mahalakshmi - Nagapattinam
          title: 'Community Outreach Program',
          description: 'Organize community outreach programs in Nagapattinam district',
          status: 'PENDING',
          priority: 'MEDIUM',
          dueDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
          assignedBy: hrManager.id
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[2].id, // M.Anbumozhi - Pudukkottai
          title: 'Program Evaluation Report',
          description: 'Prepare comprehensive evaluation report for Pudukkottai district programs',
          status: 'IN_PROGRESS',
          priority: 'HIGH',
          dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          assignedBy: admin.id
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[3].id, // A.Sekar - Virudhunagar
          title: 'Stakeholder Meeting Coordination',
          description: 'Coordinate with local stakeholders for program implementation in Virudhunagar',
          status: 'COMPLETED',
          priority: 'URGENT',
          dueDate: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
          assignedBy: hrManager.id,
          completedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[4].id, // R.Karuppaiah - Ramanathapuram
          title: 'Field Visit Documentation',
          description: 'Document field visits and program impact assessment in Ramanathapuram',
          status: 'PENDING',
          priority: 'MEDIUM',
          dueDate: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000),
          assignedBy: admin.id
        }
      }),
      prisma.task.create({
        data: {
          userId: employees[5].id, // M.Pandiyan - Theni
          title: 'Program Monitoring and Evaluation',
          description: 'Conduct monitoring and evaluation of ongoing programs in Theni district',
          status: 'IN_PROGRESS',
          priority: 'HIGH',
          dueDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
          assignedBy: hrManager.id
        }
      })
    ]);

    // Create Check-in Requests (Pending Approval)
    const checkInRequests = await Promise.all([
      prisma.checkInRequest.create({
        data: {
          userId: employees[0].id, // A.Baby Reeta
          date: new Date(),
          checkInTime: new Date(new Date().setHours(10, 30, 0, 0)),
          reason: 'Field visit in remote area of Nilgiris',
          status: 'PENDING'
        }
      }),
      prisma.checkInRequest.create({
        data: {
          userId: employees[1].id, // A.Mahalakshmi
          date: new Date(),
          checkInTime: new Date(new Date().setHours(9, 45, 0, 0)),
          reason: 'Community meeting in Nagapattinam',
          status: 'APPROVED',
          approvedBy: admin.id,
          approvedAt: new Date()
        }
      }),
      prisma.checkInRequest.create({
        data: {
          userId: employees[2].id, // M.Anbumozhi
          date: new Date(Date.now() - 24 * 60 * 60 * 1000), // Yesterday
          checkInTime: new Date(new Date(Date.now() - 24 * 60 * 60 * 1000).setHours(10, 15, 0, 0)),
          reason: 'Program coordination meeting in Pudukkottai',
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
          userId: employees[0].id, // A.Baby Reeta
          leaveTypeId: leaveTypes[0].id, // Annual Leave
          startDate: new Date('2024-12-20'),
          endDate: new Date('2024-12-27'),
          status: 'PENDING',
          reason: 'Family vacation during holiday season'
        }
      }),
      prisma.leaveRequest.create({
        data: {
          userId: employees[1].id, // A.Mahalakshmi
          leaveTypeId: leaveTypes[1].id, // Sick Leave
          startDate: new Date('2024-12-05'),
          endDate: new Date('2024-12-06'),
          status: 'APPROVED',
          reason: 'Medical appointment and recovery',
          approvedBy: hrManager.id,
          approvedAt: new Date('2024-12-04')
        }
      }),
      prisma.leaveRequest.create({
        data: {
          userId: employees[2].id, // M.Anbumozhi
          leaveTypeId: leaveTypes[2].id, // Personal Leave
          startDate: new Date('2024-12-15'),
          endDate: new Date('2024-12-15'),
          status: 'PENDING',
          reason: 'Personal family matter'
        }
      }),
      prisma.leaveRequest.create({
        data: {
          userId: employees[3].id, // A.Sekar
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
          message: 'You have been assigned: District Program Implementation Review',
          type: 'TASK'
        }
      }),
      prisma.notification.create({
        data: {
          userId: employees[1].id,
          title: 'New Task Assigned',
          message: 'You have been assigned: Community Outreach Program',
          type: 'TASK'
        }
      }),
      // Leave request notifications for admin
      prisma.notification.create({
        data: {
          userId: admin.id,
          title: 'Leave Request Pending',
          message: 'A.Baby Reeta has requested Annual Leave (Dec 20-27)',
          type: 'LEAVE'
        }
      }),
      prisma.notification.create({
        data: {
          userId: admin.id,
          title: 'Leave Request Pending',
          message: 'M.Anbumozhi has requested Personal Leave (Dec 15)',
          type: 'LEAVE'
        }
      }),
      // Check-in request notifications
      prisma.notification.create({
        data: {
          userId: admin.id,
          title: 'Check-in Request Pending',
          message: 'A.Baby Reeta has submitted a late check-in request',
          type: 'ATTENDANCE'
        }
      }),
      // Announcement notifications
      ...employees.map(emp => 
        prisma.notification.create({
          data: {
            userId: emp.id,
            title: 'New Announcement',
            message: 'Welcome to District Program Management System! - New system launched',
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
            approvedBy: admin.id,
            approvedAt: date
          });
        });
      }
    }

    await prisma.attendance.createMany({ data: attendanceRecords });

    // Create Payroll Records
    const payrollRecords = await Promise.all(
      employees.slice(0, 6).map((employee, index) =>
        prisma.payroll.create({
          data: {
            userId: employee.id,
            month: 12,
            year: 2024,
            amount: 45000.00 + (index * 2000), // Varying salaries
            details: 'Base salary + district allowance + performance bonus'
          }
        })
      )
    );

    console.log('✅ Real office data setup completed!');
    console.log('\n🏢 District Program Management System - Real Data');
    console.log('================================================');
    console.log('\n👥 Team Created:');
    console.log('- 2 Admin users (System Admin, HR Manager)');
    console.log('- 19 Real District Program Officers');
    console.log('- 7 Leave types');
    console.log('- 5 Company announcements');
    console.log('- 6 Tasks (assigned by admins)');
    console.log('- 3 Check-in requests (pending approval)');
    console.log('- 4 Leave requests (pending approval)');
    console.log('- 25+ Notifications');
    console.log('- 30 days of attendance records');
    console.log('- 6 Payroll records');
    
    console.log('\n🔑 Login Credentials:');
    console.log('System Admin: admin@techcorp.com / Admin@123');
    console.log('HR Manager: hr@techcorp.com / Admin@123');
    console.log('Employee: babyreeta16@gmail.com / Employee@123');
    
    console.log('\n📍 Districts Covered:');
    console.log('- Nilgiris, Nagapattinam, Pudukkottai, Virudhunagar');
    console.log('- Ramanathapuram, Theni, Madurai, Namakkal');
    console.log('- Tenkasi, Sivagangai, Kanyakumari, Krishnagiri');
    console.log('- Kanchipuram, Thirupathur, Cuddalore, Vellore');
    console.log('- Kallakurichi, Ranipet, Erode');
    
    console.log('\n🔄 Workflow Features:');
    console.log('- Employee check-in requests → Admin approval');
    console.log('- Admin task assignment → Employee task list');
    console.log('- Employee leave requests → Admin approval');
    console.log('- Real-time notifications');
    console.log('- Attendance tracking with approval');
    
    console.log('\n🎯 Ready for Real Office Demo!');

  } catch (error) {
    console.error('❌ Error setting up real office data:', error);
  } finally {
    await prisma.$disconnect();
  }
}

setupRealOfficeData(); 