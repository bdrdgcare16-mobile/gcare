const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function addNewEmployee() {
  console.log('👤 Adding New Employee to Existing Database...');
  console.log('=============================================');

  try {
    // Hash password for new employee
    const employeePassword = await bcrypt.hash('Employee@123', 12);

    // New Employee Data
    const newEmployee = {
      name: 'New Employee Name',
      email: 'newemployee@company.com',
      phoneNumber: '9876543210',
      designation: 'District Program Officer',
      gender: 'Male',
      location: 'Chennai',
      dateOfJoining: new Date('2024-01-15')
    };

    // Create new employee
    const employee = await prisma.user.create({
      data: {
        email: newEmployee.email,
        password: employeePassword,
        name: newEmployee.name,
        role: 'EMPLOYEE',
        phoneNumber: newEmployee.phoneNumber,
        designation: newEmployee.designation,
        shiftTiming: '9:00 AM - 6:00 PM',
        gender: newEmployee.gender,
        department: 'District Programs',
        reportingTo: 'HR Manager',
        dateOfJoining: newEmployee.dateOfJoining
      }
    });

    console.log('✅ New employee added successfully!');
    console.log(`👤 Employee: ${newEmployee.name}`);
    console.log(`📧 Email: ${newEmployee.email}`);
    console.log(`🔑 Password: Employee@123`);
    console.log(`📍 Location: ${newEmployee.location}`);

  } catch (error) {
    console.error('❌ Error adding new employee:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Function to add multiple employees
async function addMultipleEmployees() {
  console.log('👥 Adding Multiple New Employees...');
  console.log('==================================');

  try {
    const employeePassword = await bcrypt.hash('Employee@123', 12);

    // Multiple new employees
    const newEmployees = [
      {
        name: 'John Doe',
        email: 'john.doe@company.com',
        phoneNumber: '9876543211',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Coimbatore',
        dateOfJoining: new Date('2024-01-20')
      },
      {
        name: 'Jane Smith',
        email: 'jane.smith@company.com',
        phoneNumber: '9876543212',
        designation: 'District Program Officer',
        gender: 'Female',
        location: 'Salem',
        dateOfJoining: new Date('2024-01-25')
      },
      {
        name: 'Mike Johnson',
        email: 'mike.johnson@company.com',
        phoneNumber: '9876543213',
        designation: 'District Program Officer',
        gender: 'Male',
        location: 'Tiruchirappalli',
        dateOfJoining: new Date('2024-02-01')
      }
    ];

    const employees = await Promise.all(
      newEmployees.map(emp => 
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

    console.log('✅ Multiple employees added successfully!');
    employees.forEach(emp => {
      console.log(`👤 ${emp.name} - ${emp.email} - Employee@123`);
    });

  } catch (error) {
    console.error('❌ Error adding multiple employees:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Function to add new admin
async function addNewAdmin() {
  console.log('👨‍💼 Adding New Admin User...');
  console.log('============================');

  try {
    const adminPassword = await bcrypt.hash('Admin@123', 12);

    const newAdmin = {
      name: 'New Admin User',
      email: 'newadmin@company.com',
      phoneNumber: '+91-9876543214',
      designation: 'Project Manager',
      gender: 'Male',
      department: 'Management',
      reportingTo: 'System Administrator',
      dateOfJoining: new Date('2024-01-10')
    };

    const admin = await prisma.user.create({
      data: {
        email: newAdmin.email,
        password: adminPassword,
        name: newAdmin.name,
        role: 'ADMIN',
        phoneNumber: newAdmin.phoneNumber,
        designation: newAdmin.designation,
        shiftTiming: '9:00 AM - 6:00 PM',
        gender: newAdmin.gender,
        department: newAdmin.department,
        reportingTo: newAdmin.reportingTo,
        dateOfJoining: newAdmin.dateOfJoining
      }
    });

    console.log('✅ New admin added successfully!');
    console.log(`👨‍💼 Admin: ${newAdmin.name}`);
    console.log(`📧 Email: ${newAdmin.email}`);
    console.log(`🔑 Password: Admin@123`);
    console.log(`🏢 Department: ${newAdmin.department}`);

  } catch (error) {
    console.error('❌ Error adding new admin:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Function to add new announcements
async function addNewAnnouncements() {
  console.log('📢 Adding New Announcements...');
  console.log('==============================');

  try {
    const announcements = [
      {
        title: 'New Employee Onboarding',
        content: 'Welcome to our new team members! Please complete your profile setup and attend the orientation session.'
      },
      {
        title: 'System Maintenance Notice',
        content: 'The system will be under maintenance on Sunday from 2:00 AM to 6:00 AM. Please plan accordingly.'
      },
      {
        title: 'Performance Review Schedule',
        content: 'Annual performance reviews will begin next month. All employees should prepare their self-assessments.'
      }
    ];

    const newAnnouncements = await Promise.all(
      announcements.map(announcement =>
        prisma.announcement.create({
          data: announcement
        })
      )
    );

    console.log('✅ New announcements added successfully!');
    newAnnouncements.forEach(announcement => {
      console.log(`📢 ${announcement.title}`);
    });

  } catch (error) {
    console.error('❌ Error adding announcements:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Function to add new tasks
async function addNewTasks() {
  console.log('📋 Adding New Tasks...');
  console.log('======================');

  try {
    // Get existing employees and admins
    const employees = await prisma.user.findMany({
      where: { role: 'EMPLOYEE' }
    });

    const admins = await prisma.user.findMany({
      where: { role: 'ADMIN' }
    });

    if (employees.length === 0 || admins.length === 0) {
      console.log('❌ No employees or admins found. Please add users first.');
      return;
    }

    const newTasks = [
      {
        userId: employees[0].id,
        title: 'New Project Implementation',
        description: 'Start implementing the new district program in assigned region',
        status: 'PENDING',
        priority: 'HIGH',
        dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
        assignedBy: admins[0].id
      },
      {
        userId: employees[1]?.id || employees[0].id,
        title: 'Data Collection and Analysis',
        description: 'Collect and analyze district-wise program data',
        status: 'IN_PROGRESS',
        priority: 'MEDIUM',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        assignedBy: admins[0].id
      }
    ];

    const tasks = await Promise.all(
      newTasks.map(task =>
        prisma.task.create({
          data: task
        })
      )
    );

    console.log('✅ New tasks added successfully!');
    tasks.forEach(task => {
      console.log(`📋 ${task.title} - ${task.status}`);
    });

  } catch (error) {
    console.error('❌ Error adding tasks:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Main function to run all additions
async function addAllNewData() {
  console.log('🚀 Adding All New Data to Database...');
  console.log('=====================================');

  await addNewEmployee();
  console.log('');
  
  await addMultipleEmployees();
  console.log('');
  
  await addNewAdmin();
  console.log('');
  
  await addNewAnnouncements();
  console.log('');
  
  await addNewTasks();
  console.log('');
  
  console.log('🎉 All new data added successfully!');
  console.log('📊 Database updated without clearing existing data.');
}

// Export functions for individual use
module.exports = {
  addNewEmployee,
  addMultipleEmployees,
  addNewAdmin,
  addNewAnnouncements,
  addNewTasks,
  addAllNewData
};

// Run specific function based on command line argument
const args = process.argv.slice(2);
const command = args[0];

switch (command) {
  case 'employee':
    addNewEmployee();
    break;
  case 'employees':
    addMultipleEmployees();
    break;
  case 'admin':
    addNewAdmin();
    break;
  case 'announcements':
    addNewAnnouncements();
    break;
  case 'tasks':
    addNewTasks();
    break;
  case 'all':
    addAllNewData();
    break;
  default:
    console.log('📋 Usage:');
    console.log('node add_new_employee.js employee     - Add single employee');
    console.log('node add_new_employee.js employees    - Add multiple employees');
    console.log('node add_new_employee.js admin        - Add new admin');
    console.log('node add_new_employee.js announcements - Add new announcements');
    console.log('node add_new_employee.js tasks        - Add new tasks');
    console.log('node add_new_employee.js all          - Add all new data');
    break;
} 