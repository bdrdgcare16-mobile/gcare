const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function viewUsers() {
  console.log('👥 ALL USERS IN DATABASE');
  console.log('========================');
  
  try {
    const users = await prisma.user.findMany({
      orderBy: { name: 'asc' }
    });

    if (users.length === 0) {
      console.log('❌ No users found in database');
      return;
    }

    users.forEach((user, index) => {
      console.log(`\n${index + 1}. ${user.name}`);
      console.log(`   📧 Email: ${user.email}`);
      console.log(`   👤 Role: ${user.role}`);
      console.log(`   🏢 Department: ${user.department}`);
      console.log(`   📱 Phone: ${user.phoneNumber}`);
      console.log(`   📍 Location: ${user.location || 'N/A'}`);
      console.log(`   🎯 Designation: ${user.designation}`);
      console.log(`   📅 Joined: ${user.dateOfJoining.toLocaleDateString()}`);
    });

    console.log(`\n📊 Total Users: ${users.length}`);
    const admins = users.filter(u => u.role === 'ADMIN').length;
    const employees = users.filter(u => u.role === 'EMPLOYEE').length;
    console.log(`👨‍💼 Admins: ${admins}`);
    console.log(`👤 Employees: ${employees}`);

  } catch (error) {
    console.error('❌ Error viewing users:', error);
  }
}

async function viewEmployees() {
  console.log('👤 ALL EMPLOYEES IN DATABASE');
  console.log('============================');
  
  try {
    const employees = await prisma.user.findMany({
      where: { role: 'EMPLOYEE' },
      orderBy: { name: 'asc' }
    });

    if (employees.length === 0) {
      console.log('❌ No employees found in database');
      return;
    }

    employees.forEach((employee, index) => {
      console.log(`\n${index + 1}. ${employee.name}`);
      console.log(`   📧 Email: ${employee.email}`);
      console.log(`   📱 Phone: ${employee.phoneNumber}`);
      console.log(`   🎯 Designation: ${employee.designation}`);
      console.log(`   📍 Location: ${employee.location || 'N/A'}`);
      console.log(`   🏢 Department: ${employee.department}`);
      console.log(`   📅 Joined: ${employee.dateOfJoining.toLocaleDateString()}`);
      console.log(`   🔑 Password: Employee@123`);
    });

    console.log(`\n📊 Total Employees: ${employees.length}`);

  } catch (error) {
    console.error('❌ Error viewing employees:', error);
  }
}

async function viewAdmins() {
  console.log('👨‍💼 ALL ADMINS IN DATABASE');
  console.log('==========================');
  
  try {
    const admins = await prisma.user.findMany({
      where: { role: 'ADMIN' },
      orderBy: { name: 'asc' }
    });

    if (admins.length === 0) {
      console.log('❌ No admins found in database');
      return;
    }

    admins.forEach((admin, index) => {
      console.log(`\n${index + 1}. ${admin.name}`);
      console.log(`   📧 Email: ${admin.email}`);
      console.log(`   📱 Phone: ${admin.phoneNumber}`);
      console.log(`   🎯 Designation: ${admin.designation}`);
      console.log(`   🏢 Department: ${admin.department}`);
      console.log(`   📅 Joined: ${admin.dateOfJoining.toLocaleDateString()}`);
      console.log(`   🔑 Password: Admin@123`);
    });

    console.log(`\n📊 Total Admins: ${admins.length}`);

  } catch (error) {
    console.error('❌ Error viewing admins:', error);
  }
}

async function viewTasks() {
  console.log('📋 ALL TASKS IN DATABASE');
  console.log('========================');
  
  try {
    const tasks = await prisma.task.findMany({
      include: {
        user: {
          select: { name: true, email: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    if (tasks.length === 0) {
      console.log('❌ No tasks found in database');
      return;
    }

    tasks.forEach((task, index) => {
      console.log(`\n${index + 1}. ${task.title}`);
      console.log(`   👤 Assigned to: ${task.user.name} (${task.user.email})`);
      console.log(`   📝 Description: ${task.description || 'No description'}`);
      console.log(`   📊 Status: ${task.status}`);
      console.log(`   ⚡ Priority: ${task.priority}`);
      console.log(`   📅 Due Date: ${task.dueDate ? task.dueDate.toLocaleDateString() : 'No due date'}`);
      console.log(`   📅 Created: ${task.createdAt.toLocaleDateString()}`);
    });

    console.log(`\n📊 Total Tasks: ${tasks.length}`);
    const pending = tasks.filter(t => t.status === 'PENDING').length;
    const inProgress = tasks.filter(t => t.status === 'IN_PROGRESS').length;
    const completed = tasks.filter(t => t.status === 'COMPLETED').length;
    console.log(`⏳ Pending: ${pending}`);
    console.log(`🔄 In Progress: ${inProgress}`);
    console.log(`✅ Completed: ${completed}`);

  } catch (error) {
    console.error('❌ Error viewing tasks:', error);
  }
}

async function viewLeaveRequests() {
  console.log('🏖️ ALL LEAVE REQUESTS IN DATABASE');
  console.log('==================================');
  
  try {
    const leaves = await prisma.leaveRequest.findMany({
      include: {
        user: {
          select: { name: true, email: true }
        },
        leaveType: {
          select: { name: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    if (leaves.length === 0) {
      console.log('❌ No leave requests found in database');
      return;
    }

    leaves.forEach((leave, index) => {
      console.log(`\n${index + 1}. ${leave.user.name} - ${leave.leaveType.name}`);
      console.log(`   📧 Employee: ${leave.user.email}`);
      console.log(`   📅 Start Date: ${leave.startDate.toLocaleDateString()}`);
      console.log(`   📅 End Date: ${leave.endDate.toLocaleDateString()}`);
      console.log(`   📊 Status: ${leave.status}`);
      console.log(`   📝 Reason: ${leave.reason || 'No reason provided'}`);
      console.log(`   📅 Requested: ${leave.createdAt.toLocaleDateString()}`);
    });

    console.log(`\n📊 Total Leave Requests: ${leaves.length}`);
    const pending = leaves.filter(l => l.status === 'PENDING').length;
    const approved = leaves.filter(l => l.status === 'APPROVED').length;
    const rejected = leaves.filter(l => l.status === 'REJECTED').length;
    console.log(`⏳ Pending: ${pending}`);
    console.log(`✅ Approved: ${approved}`);
    console.log(`❌ Rejected: ${rejected}`);

  } catch (error) {
    console.error('❌ Error viewing leave requests:', error);
  }
}

async function viewAnnouncements() {
  console.log('📢 ALL ANNOUNCEMENTS IN DATABASE');
  console.log('=================================');
  
  try {
    const announcements = await prisma.announcement.findMany({
      orderBy: { createdAt: 'desc' }
    });

    if (announcements.length === 0) {
      console.log('❌ No announcements found in database');
      return;
    }

    announcements.forEach((announcement, index) => {
      console.log(`\n${index + 1}. ${announcement.title}`);
      console.log(`   📝 Content: ${announcement.content}`);
      console.log(`   📅 Created: ${announcement.createdAt.toLocaleDateString()}`);
    });

    console.log(`\n📊 Total Announcements: ${announcements.length}`);

  } catch (error) {
    console.error('❌ Error viewing announcements:', error);
  }
}

async function viewAttendance() {
  console.log('⏰ RECENT ATTENDANCE RECORDS');
  console.log('============================');
  
  try {
    const attendance = await prisma.attendance.findMany({
      include: {
        user: {
          select: { name: true, email: true }
        }
      },
      orderBy: { date: 'desc' },
      take: 20 // Show last 20 records
    });

    if (attendance.length === 0) {
      console.log('❌ No attendance records found in database');
      return;
    }

    attendance.forEach((record, index) => {
      console.log(`\n${index + 1}. ${record.user.name} - ${record.date.toLocaleDateString()}`);
      console.log(`   📧 Employee: ${record.user.email}`);
      console.log(`   ⏰ Check In: ${record.checkIn ? record.checkIn.toLocaleTimeString() : 'N/A'}`);
      console.log(`   ⏰ Check Out: ${record.checkOut ? record.checkOut.toLocaleTimeString() : 'N/A'}`);
      console.log(`   📊 Status: ${record.status}`);
    });

    console.log(`\n📊 Showing last ${attendance.length} attendance records`);

  } catch (error) {
    console.error('❌ Error viewing attendance:', error);
  }
}

async function viewPayroll() {
  console.log('💰 ALL PAYROLL RECORDS IN DATABASE');
  console.log('===================================');
  
  try {
    const payroll = await prisma.payroll.findMany({
      include: {
        user: {
          select: { name: true, email: true }
        }
      },
      orderBy: { year: 'desc', month: 'desc' }
    });

    if (payroll.length === 0) {
      console.log('❌ No payroll records found in database');
      return;
    }

    payroll.forEach((record, index) => {
      console.log(`\n${index + 1}. ${record.user.name} - ${record.month}/${record.year}`);
      console.log(`   📧 Employee: ${record.user.email}`);
      console.log(`   💰 Amount: ₹${record.amount.toLocaleString()}`);
      console.log(`   📝 Details: ${record.details}`);
    });

    console.log(`\n📊 Total Payroll Records: ${payroll.length}`);
    const totalAmount = payroll.reduce((sum, record) => sum + record.amount, 0);
    console.log(`💰 Total Amount: ₹${totalAmount.toLocaleString()}`);

  } catch (error) {
    console.error('❌ Error viewing payroll:', error);
  }
}

async function viewSummary() {
  console.log('📊 DATABASE SUMMARY');
  console.log('===================');
  
  try {
    const userCount = await prisma.user.count();
    const adminCount = await prisma.user.count({ where: { role: 'ADMIN' } });
    const employeeCount = await prisma.user.count({ where: { role: 'EMPLOYEE' } });
    const taskCount = await prisma.task.count();
    const leaveCount = await prisma.leaveRequest.count();
    const announcementCount = await prisma.announcement.count();
    const attendanceCount = await prisma.attendance.count();
    const payrollCount = await prisma.payroll.count();

    console.log(`\n👥 Users: ${userCount}`);
    console.log(`   👨‍💼 Admins: ${adminCount}`);
    console.log(`   👤 Employees: ${employeeCount}`);
    
    console.log(`\n📋 Tasks: ${taskCount}`);
    console.log(`🏖️ Leave Requests: ${leaveCount}`);
    console.log(`📢 Announcements: ${announcementCount}`);
    console.log(`⏰ Attendance Records: ${attendanceCount}`);
    console.log(`💰 Payroll Records: ${payrollCount}`);

    // Show recent activity
    console.log(`\n🕒 RECENT ACTIVITY:`);
    
    const recentTasks = await prisma.task.findMany({
      take: 3,
      orderBy: { createdAt: 'desc' },
      include: { user: { select: { name: true } } }
    });

    if (recentTasks.length > 0) {
      console.log(`   📋 Recent Tasks:`);
      recentTasks.forEach(task => {
        console.log(`      - ${task.title} (${task.user.name})`);
      });
    }

    const recentLeaves = await prisma.leaveRequest.findMany({
      take: 3,
      orderBy: { createdAt: 'desc' },
      include: { user: { select: { name: true } } }
    });

    if (recentLeaves.length > 0) {
      console.log(`   🏖️ Recent Leave Requests:`);
      recentLeaves.forEach(leave => {
        console.log(`      - ${leave.user.name} (${leave.status})`);
      });
    }

  } catch (error) {
    console.error('❌ Error viewing summary:', error);
  }
}

// Run specific function based on command line argument
const args = process.argv.slice(2);
const command = args[0];

switch (command) {
  case 'users':
    viewUsers();
    break;
  case 'employees':
    viewEmployees();
    break;
  case 'admins':
    viewAdmins();
    break;
  case 'tasks':
    viewTasks();
    break;
  case 'leaves':
    viewLeaveRequests();
    break;
  case 'announcements':
    viewAnnouncements();
    break;
  case 'attendance':
    viewAttendance();
    break;
  case 'payroll':
    viewPayroll();
    break;
  case 'summary':
    viewSummary();
    break;
  default:
    console.log('📋 Usage:');
    console.log('node view_database.js users         - View all users');
    console.log('node view_database.js employees     - View all employees');
    console.log('node view_database.js admins        - View all admins');
    console.log('node view_database.js tasks         - View all tasks');
    console.log('node view_database.js leaves        - View all leave requests');
    console.log('node view_database.js announcements - View all announcements');
    console.log('node view_database.js attendance    - View attendance records');
    console.log('node view_database.js payroll       - View payroll records');
    console.log('node view_database.js summary       - View database summary');
    break;
}

// Disconnect from database
prisma.$disconnect(); 