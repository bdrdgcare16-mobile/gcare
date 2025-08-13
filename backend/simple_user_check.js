const sqlite3 = require('sqlite3').verbose();
const path = require('path');

async function checkUsers() {
  console.log('👥 CHECKING USERS IN DATABASE');
  console.log('=============================');
  console.log('');
  
  const dbPath = path.join(__dirname, 'prisma', 'dev.db');
  
  try {
    const db = new sqlite3.Database(dbPath);
    
    db.all("SELECT id, email, name, role, phoneNumber, designation, department FROM User ORDER BY id", (err, rows) => {
      if (err) {
        console.log('❌ Error reading database:', err.message);
        console.log('');
        console.log('🔧 TROUBLESHOOTING:');
        console.log('   1. Make sure backend server is running');
        console.log('   2. Check if database exists: backend/prisma/dev.db');
        console.log('   3. Try starting the server first: npm start');
        return;
      }
      
      if (rows.length === 0) {
        console.log('❌ No users found in database');
        console.log('');
        console.log('💡 To add users, you can:');
        console.log('   1. Start the server: npm start');
        console.log('   2. Use the app to register new users');
        console.log('   3. Or use the existing scripts');
        return;
      }
      
      console.log(`✅ Found ${rows.length} users in database:`);
      console.log('');
      
      rows.forEach((user, index) => {
        console.log(`${index + 1}. 👤 ${user.name || 'No name'}`);
        console.log(`   📧 Email: ${user.email}`);
        console.log(`   👑 Role: ${user.role || 'Not set'}`);
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
      rows.slice(0, 3).forEach(user => {
        const defaultPassword = user.role === 'ADMIN' ? 'Admin@123' : 'Employee@123';
        console.log(`   • ${user.email} / ${defaultPassword}`);
      });
      console.log('');
      console.log('🎯 QUICK TEST:');
      console.log('   1. Make sure server is running: npm start');
      console.log('   2. Open your app: http://localhost:8080');
      console.log('   3. Try any email from the list above');
      console.log('   4. Use the default password for that role');
      console.log('');
      console.log('⚠️  NOTE: If a user has a custom password, you\'ll need to ask them or reset it.');
      
      db.close();
    });
    
  } catch (error) {
    console.log('❌ Error accessing database:', error.message);
    console.log('');
    console.log('🔧 TROUBLESHOOTING:');
    console.log('   1. Make sure backend server is running');
    console.log('   2. Check if database exists: backend/prisma/dev.db');
    console.log('   3. Try: npm start');
  }
}

checkUsers(); 