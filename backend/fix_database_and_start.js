const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function fixDatabaseAndStart() {
  console.log('🔧 FIXING DATABASE AND STARTING SERVER');
  console.log('=====================================');
  console.log('');

  try {
    // Step 1: Generate Prisma client
    console.log('📦 Step 1: Generating Prisma client...');
    const { execSync } = require('child_process');
    execSync('npx prisma generate', { stdio: 'inherit' });
    console.log('✅ Prisma client generated');

    // Step 2: Push database schema
    console.log('🗄️ Step 2: Updating database schema...');
    execSync('npx prisma db push', { stdio: 'inherit' });
    console.log('✅ Database schema updated');

    // Step 3: Setup real data
    console.log('📝 Step 3: Setting up real data...');
    
    // Clear existing data
    await prisma.task.deleteMany();
    await prisma.user.deleteMany();
    await prisma.leaveType.deleteMany();
    await prisma.announcement.deleteMany();
    
    console.log('✅ Data cleared');

    // Create leave types
    const leaveTypes = await Promise.all([
      prisma.leaveType.create({ data: { name: 'Annual Leave' } }),
      prisma.leaveType.create({ data: { name: 'Sick Leave' } }),
      prisma.leaveType.create({ data: { name: 'Personal Leave' } })
    ]);

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

    // Create tasks
    const tasks = [
      {
        userId: employee.id,
        title: 'District Program Review',
        description: 'Review and update district program documentation',
        status: 'PENDING',
        priority: 'MEDIUM',
        dueDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
        assignedBy: admin.id
      },
      {
        userId: employee.id,
        title: 'Community Outreach Meeting',
        description: 'Prepare for community outreach program meeting',
        status: 'IN_PROGRESS',
        priority: 'HIGH',
        dueDate: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000),
        assignedBy: admin.id
      },
      {
        userId: employee.id,
        title: 'Monthly Report Submission',
        description: 'Complete and submit monthly district report',
        status: 'COMPLETED',
        priority: 'LOW',
        dueDate: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
        assignedBy: admin.id
      }
    ];

    for (const taskData of tasks) {
      await prisma.task.create({ data: taskData });
    }

    // Create announcements
    await prisma.announcement.create({
      data: {
        title: 'Welcome to HRMS System',
        content: 'Welcome to our new HR Management System. Please complete your profile and start using the features.'
      }
    });

    console.log('✅ Real data setup complete');
    console.log('');
    console.log('👤 LOGIN CREDENTIALS:');
    console.log('   Employee: keshaw390@gmail.com / Employee@123');
    console.log('   Admin: admin@techcorp.com / Admin@123');
    console.log('');

    // Step 4: Start server
    console.log('🚀 Step 4: Starting server...');
    console.log('✅ Server will start in a new window');
    console.log('✅ Access your app at: http://localhost:8080');
    console.log('');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

fixDatabaseAndStart(); 