const { PrismaClient, Role } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function addTestEmployee() {
  try {
    const hashedPassword = await bcrypt.hash('password123', 10);
    
    const employee = await prisma.user.upsert({
      where: { email: 'employee@test.com' },
      update: {},
      create: {
        email: 'employee@test.com',
        password: hashedPassword,
        name: 'Test Employee',
        role: Role.EMPLOYEE,
      },
    });

    console.log('✅ Test employee created:', employee.email);
    console.log('   Email: employee@test.com');
    console.log('   Password: password123');
    console.log('   Role: EMPLOYEE');
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

addTestEmployee(); 