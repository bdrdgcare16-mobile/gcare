const { PrismaClient } = require('@prisma/client');

async function showAllUsers() {
  console.log('👥 ALL USERS IN DATABASE');
  console.log('========================');
  console.log('');
  
  const prisma = new PrismaClient();
  
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        phoneNumber: true,
        designation: true,
        department: true,
        password: false // Don't show passwords for security
      },
      orderBy: {
        id: 'asc'
      }
    });
    
    if (users.length === 0) {
      console.log('❌ No users found in database');
      console.log('');
      console.log('💡 To add users, you can:');
      console.log('   1. Use Prisma Studio: npx prisma studio');
      console.log('   2. Run: node add_employee_with_custom_password.js');
      console.log('   3. Run: node add_employee_with_random_password.js');
      return;
    }
    
    console.log(`✅ Found ${users.length} users in database:`);
    console.log('');
    
    users.forEach((user, index) => {
      console.log(`${index + 1}. 👤 ${user.name}`);
      console.log(`   📧 Email: ${user.email}`);
      console.log(`   👑 Role: ${user.role}`);
      console.log(`   📱 Phone: ${user.phoneNumber || 'Not set'}`);
      console.log(`   💼 Designation: ${user.designation || 'Not set'}`);
      console.log(`   🏢 Department: ${user.department || 'Not set'}`);
      console.log(`   🔐 Password: [HIDDEN - Use default or contact admin]`);
      console.log('');
    });
    
    console.log('🔐 LOGIN INSTRUCTIONS:');
    console.log('======================');
    console.log('');
    console.log('You can login with ANY of the above emails using:');
    console.log('');
    console.log('📋 DEFAULT PASSWORDS:');
    console.log('   • All Employees: Employee@123');
    console.log('   • All Admins: Admin@123');
    console.log('');
    console.log('💡 EXAMPLE LOGINS:');
    users.slice(0, 3).forEach(user => {
      const defaultPassword = user.role === 'ADMIN' ? 'Admin@123' : 'Employee@123';
      console.log(`   • ${user.email} / ${defaultPassword}`);
    });
    console.log('');
    console.log('🎯 QUICK TEST:');
    console.log('   1. Open your app: http://localhost:8080');
    console.log('   2. Try any email from the list above');
    console.log('   3. Use the default password for that role');
    console.log('');
    console.log('⚠️  NOTE: If a user has a custom password, you\'ll need to ask them or reset it.');
    
  } catch (error) {
    console.log('❌ Error accessing database:', error.message);
    console.log('');
    console.log('🔧 TROUBLESHOOTING:');
    console.log('   1. Make sure backend server is running');
    console.log('   2. Check if database exists: backend/prisma/dev.db');
    console.log('   3. Try: npx prisma studio');
  } finally {
    await prisma.$disconnect();
  }
}

showAllUsers(); 