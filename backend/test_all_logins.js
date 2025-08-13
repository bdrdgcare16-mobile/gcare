const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function testAllLogins() {
  console.log('🔍 Testing all users for login...');
  console.log('=====================================');

  try {
    // Get all users
    const users = await prisma.user.findMany({
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        password: true
      }
    });

    console.log(`📊 Found ${users.length} users in database`);

    // Test each user
    for (const user of users) {
      console.log(`\n👤 Testing: ${user.name} (${user.email})`);
      console.log(`   Role: ${user.role}`);
      
      // Test with common passwords
      const testPasswords = ['Employee@123', 'Admin@123', 'Test@123'];
      
      for (const password of testPasswords) {
        const isValid = await bcrypt.compare(password, user.password);
        if (isValid) {
          console.log(`   ✅ Login works with password: ${password}`);
          break;
        }
      }
    }

    console.log('\n�� Login Test Summary:');
    console.log('=====================');
    console.log('✅ All users with working passwords are ready for login');
    console.log('📧 Use any of the emails above with their working passwords');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testAllLogins(); 