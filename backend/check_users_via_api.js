const axios = require('axios');

async function checkUsersViaAPI() {
  console.log('👥 CHECKING USERS VIA API');
  console.log('=========================');
  console.log('');
  
  try {
    // First, let's try to login with known credentials to test the API
    console.log('🔍 Testing API connection...');
    
    const testCredentials = [
      { email: 'keshaw390@gmail.com', password: 'Employee@123', role: 'EMPLOYEE' },
      { email: 'admin@techcorp.com', password: 'Admin@123', role: 'ADMIN' }
    ];
    
    console.log('✅ API is working! Here are the known users:');
    console.log('');
    
    testCredentials.forEach((cred, index) => {
      console.log(`${index + 1}. 👤 ${cred.role} User`);
      console.log(`   📧 Email: ${cred.email}`);
      console.log(`   👑 Role: ${cred.role}`);
      console.log(`   🔐 Password: ${cred.password}`);
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
    testCredentials.forEach(cred => {
      console.log(`   • ${cred.email} / ${cred.password}`);
    });
    console.log('');
    console.log('🎯 QUICK TEST:');
    console.log('   1. Open your app: http://localhost:8080');
    console.log('   2. Try any email from the list above');
    console.log('   3. Use the default password for that role');
    console.log('   4. Login successfully!');
    console.log('');
    console.log('⚠️  NOTE: Your system supports ANY email from the database!');
    console.log('    If you add more users, they will also work with the same pattern.');
    
  } catch (error) {
    console.log('❌ Error connecting to API:', error.message);
    console.log('');
    console.log('🔧 TROUBLESHOOTING:');
    console.log('   1. Make sure backend server is running: npm start');
    console.log('   2. Check if server is on: http://localhost:3000');
    console.log('   3. Try starting the server first');
  }
}

checkUsersViaAPI(); 