const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function testLogin() {
  console.log('🔐 TESTING LOGIN CREDENTIALS');
  console.log('============================');
  console.log('');

  try {
    // Test specific employee login
    const testEmail = 'keshaw390@gmail.com';
    const testPassword = 'Employee@123';

    console.log(`Testing login for: ${testEmail}`);
    console.log(`Password: ${testPassword}`);
    console.log('');

    // Find user in database
    const user = await prisma.user.findUnique({
      where: { email: testEmail }
    });

    if (!user) {
      console.log('❌ USER NOT FOUND IN DATABASE');
      console.log('This means the user was not created properly.');
      return;
    }

    console.log('✅ USER FOUND IN DATABASE:');
    console.log(`ID: ${user.id}`);
    console.log(`Name: ${user.name}`);
    console.log(`Email: ${user.email}`);
    console.log(`Role: ${user.role}`);
    console.log(`Department: ${user.department}`);
    console.log('');

    // Test password verification
    const isPasswordValid = await bcrypt.compare(testPassword, user.password);
    
    if (isPasswordValid) {
      console.log('✅ PASSWORD VERIFICATION SUCCESSFUL');
      console.log('The login credentials are correct!');
    } else {
      console.log('❌ PASSWORD VERIFICATION FAILED');
      console.log('The password hash does not match.');
    }

    console.log('');
    console.log('🔍 CHECKING ALL EMPLOYEES:');
    console.log('========================');

    // Check all employees
    const allUsers = await prisma.user.findMany({
      where: { role: 'EMPLOYEE' },
      select: {
        id: true,
        name: true,
        email: true,
        role: true
      }
    });

    console.log(`Total employees in database: ${allUsers.length}`);
    console.log('');

    allUsers.forEach((user, index) => {
      console.log(`${index + 1}. ${user.name} (${user.email})`);
    });

    console.log('');
    console.log('💡 LOGIN INSTRUCTIONS:');
    console.log('======================');
    console.log('1. Make sure your Flutter app is running');
    console.log('2. Make sure your backend server is running');
    console.log('3. Try logging in with the credentials above');
    console.log('4. If it still fails, check the backend server logs');

  } catch (error) {
    console.error('❌ Error testing login:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testLogin(); 