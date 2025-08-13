const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function setupProduction() {
  console.log('🏢 Setting up PRODUCTION DATA for company sale...');
  
  try {
    // Clear existing data
    await prisma.user.deleteMany();
    await prisma.leaveType.deleteMany();
    await prisma.announcement.deleteMany();
    
    // Create leave types
    await prisma.leaveType.createMany({
      data: [
        { name: 'Annual Leave' },
        { name: 'Sick Leave' },
        { name: 'Personal Leave' },
        { name: 'Maternity Leave' }
      ]
    });
    
    // Create admin users
    const adminPassword = await bcrypt.hash('Admin@2024!', 12);
    const hrPassword = await bcrypt.hash('HR@2024!', 12);
    const employeePassword = await bcrypt.hash('Employee@2024!', 12);
    
    await prisma.user.create({
      data: {
        email: 'admin@techcorp.com',
        password: adminPassword,
        name: 'Michael Johnson',
        role: 'ADMIN',
        designation: 'CEO',
        department: 'Executive'
      }
    });
    
    await prisma.user.create({
      data: {
        email: 'hr@techcorp.com',
        password: hrPassword,
        name: 'Sarah Williams',
        role: 'ADMIN',
        designation: 'HR Manager',
        department: 'Human Resources'
      }
    });
    
    await prisma.user.create({
      data: {
        email: 'alex@techcorp.com',
        password: employeePassword,
        name: 'Alex Martinez',
        role: 'EMPLOYEE',
        designation: 'Software Engineer',
        department: 'Engineering'
      }
    });
    
    // Create announcements
    await prisma.announcement.createMany({
      data: [
        {
          title: 'Welcome to TechCorp HRMS!',
          content: 'Professional employee management system for modern companies.'
        },
        {
          title: 'Q4 Meeting Schedule',
          content: 'Quarterly all-hands meeting on December 15th at 2 PM.'
        }
      ]
    });
    
    console.log('✅ Production setup completed!');
    console.log('\n🔑 Login Credentials:');
    console.log('CEO: admin@techcorp.com / Admin@2024!');
    console.log('HR: hr@techcorp.com / HR@2024!');
    console.log('Employee: alex@techcorp.com / Employee@2024!');
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

setupProduction(); 