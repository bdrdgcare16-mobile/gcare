const { PrismaClient } = require('@prisma/client');

async function testDatabaseConnection() {
  console.log('🔍 Testing database connection...');
  
  const prisma = new PrismaClient();
  
  try {
    const users = await prisma.user.findMany();
    console.log('✅ Database connected successfully!');
    console.log(`📊 Found ${users.length} users in database`);
    
    if (users.length > 0) {
      console.log('👥 Sample users:');
      users.slice(0, 3).forEach(user => {
        console.log(`   - ${user.name} (${user.email}) - ${user.role}`);
      });
    }
    
    console.log('🎉 Database test completed successfully!');
  } catch (error) {
    console.log('❌ Database connection failed:');
    console.log('   Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

testDatabaseConnection(); 