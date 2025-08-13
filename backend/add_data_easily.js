const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function addDataEasily() {
  console.log('🔧 EASY DATA MANAGEMENT');
  console.log('======================');
  console.log('');

  try {
    // Check if we have existing data
    const existingUsers = await prisma.user.findMany();
    
    if (existingUsers.length === 0) {
      console.log('📝 No existing data found. Setting up basic data...');
      
      // Hash passwords
      const adminPassword = await bcrypt.hash('Admin@123', 12);
      const employeePassword = await bcrypt.hash('Employee@123', 12);

      // Create admin
      const admin = await prisma.user.create({
        data: {
          email: 'admin@techcorp.com',
          password: adminPassword,
          name: 'Admin User',
          role: 'ADMIN',
          phoneNumber: '+1234567890',
          designation: 'System Administrator',
          department: 'IT',
          dateOfJoining: new Date('2024-01-01')
        }
      });

      // Create employee
      const employee = await prisma.user.create({
        data: {
          email: 'keshaw390@gmail.com',
          password: employeePassword,
          name: 'A.Mahalakshmi',
          role: 'EMPLOYEE',
          phoneNumber: '+9876543210',
          designation: 'District Program Officer',
          department: 'Program Management',
          dateOfJoining: new Date('2024-01-15')
        }
      });

      // Create leave types
      await prisma.leaveType.createMany({
        data: [
          { name: 'Annual Leave' },
          { name: 'Sick Leave' },
          { name: 'Personal Leave' }
        ]
      });

      // Create tasks
      const tasks = [
        {
          userId: employee.id,
          title: 'District Program Review',
          description: 'Review and update district program documentation',
          status: 'PENDING',
          dueDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
          assignedBy: admin.id
        },
        {
          userId: employee.id,
          title: 'Community Outreach Meeting',
          description: 'Prepare for community outreach program meeting',
          status: 'IN_PROGRESS',
          dueDate: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000),
          assignedBy: admin.id
        }
      ];

      for (const taskData of tasks) {
        await prisma.task.create({ data: taskData });
      }

      // Create announcement
      await prisma.announcement.create({
        data: {
          title: 'Welcome to HRMS System',
          content: 'Welcome to our new HR Management System. Please complete your profile and start using the features.'
        }
      });

      console.log('✅ Basic data setup complete!');
    } else {
      console.log('✅ Existing data found. System is ready!');
    }

    console.log('');
    console.log('👤 LOGIN CREDENTIALS:');
    console.log('   Employee: keshaw390@gmail.com / Employee@123');
    console.log('   Admin: admin@techcorp.com / Admin@123');
    console.log('');
    console.log('🔧 EASY DATA MANAGEMENT OPTIONS:');
    console.log('');
    console.log('📊 METHOD 1 - VISUAL DATABASE MANAGER (EASIEST):');
    console.log('   cd backend && npx prisma studio');
    console.log('   Opens at: http://localhost:5555');
    console.log('   - Add/edit employees visually');
    console.log('   - Add tasks, leave requests');
    console.log('   - NO CODING REQUIRED!');
    console.log('');
    console.log('📝 METHOD 2 - SIMPLE COMMANDS:');
    console.log('   cd backend && node add_new_employee.js');
    console.log('   cd backend && node add_simple_tasks.js');
    console.log('   cd backend && node view_database.js');
    console.log('');
    console.log('🎨 METHOD 3 - USE YOUR APP:');
    console.log('   Login as admin: admin@techcorp.com / Admin@123');
    console.log('   Use admin panel to add employees, tasks, etc.');
    console.log('');
    console.log('🗄️ METHOD 4 - MANUAL DATABASE:');
    console.log('   Download SQLite Browser: https://sqlitebrowser.org/');
    console.log('   Open: backend/prisma/dev.db');
    console.log('   Edit directly - no commands needed!');
    console.log('');

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.log('');
    console.log('🔧 TROUBLESHOOTING:');
    console.log('   1. Make sure backend server is running');
    console.log('   2. Try: cd backend && npx prisma db push');
    console.log('   3. Try: cd backend && npx prisma generate');
  } finally {
    await prisma.$disconnect();
  }
}

addDataEasily(); 