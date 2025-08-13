const sqlite3 = require('sqlite3').verbose();
const path = require('path');

function showAllRealUsers() {
  console.log('🔍 SHOWING ALL USERS IN DATABASE');
  console.log('==================================');
  console.log('');
  
  const dbPath = path.join(__dirname, 'prisma', 'dev.db');
  
  try {
    const db = new sqlite3.Database(dbPath);
    
    db.all(`
      SELECT id, email, name, role, phoneNumber, designation, department, gender, shiftTiming, reportingTo, dateOfJoining
      FROM User
      ORDER BY id
    `, [], function(err, rows) {
      if (err) {
        console.log('❌ Error reading users:', err.message);
      } else {
        console.log(`📊 Found ${rows.length} users in database:`);
        console.log('');
        
        if (rows.length === 0) {
          console.log('❌ No users found in database!');
          console.log('');
          console.log('💡 To add users, run:');
          console.log('   node quick_setup_real_data.js');
        } else {
          rows.forEach((user, index) => {
            console.log(`${index + 1}. 👤 ${user.name || 'Unknown'}`);
            console.log(`   📧 Email: ${user.email}`);
            console.log(`   👑 Role: ${user.role}`);
            console.log(`   📱 Phone: ${user.phoneNumber || 'Not set'}`);
            console.log(`   💼 Designation: ${user.designation || 'Not set'}`);
            console.log(`   🏢 Department: ${user.department || 'Not set'}`);
            console.log(`   👥 Gender: ${user.gender || 'Not set'}`);
            console.log(`   ⏰ Shift: ${user.shiftTiming || 'Not set'}`);
            console.log(`   📋 Reports to: ${user.reportingTo || 'Not set'}`);
            console.log(`   📅 Joined: ${user.dateOfJoining || 'Not set'}`);
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
          console.log('🎯 QUICK TEST:');
          console.log('   1. Start the server: npm start');
          console.log('   2. Open your app: http://localhost:8080');
          console.log('   3. Try any email from the list above');
          console.log('   4. Use the default password for that role');
          console.log('   5. Login successfully!');
          console.log('');
          console.log('⚠️  NOTE: All users have real data including phone numbers!');
        }
        
        db.close();
      }
    });
    
  } catch (error) {
    console.log('❌ Error during setup:', error.message);
  }
}

showAllRealUsers(); 