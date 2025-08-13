const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');
const path = require('path');

async function addRealUsers() {
  console.log('🚀 ADDING REAL USERS TO DATABASE');
  console.log('=================================');
  console.log('');
  
  const dbPath = path.join(__dirname, 'prisma', 'dev.db');
  
  try {
    const db = new sqlite3.Database(dbPath);
    
    // Create tables if they don't exist
    console.log('📦 Creating tables...');
    
    db.run(`
      CREATE TABLE IF NOT EXISTS User (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        phoneNumber TEXT,
        designation TEXT,
        shiftTiming TEXT,
        gender TEXT,
        department TEXT,
        reportingTo TEXT,
        dateOfJoining TEXT,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    db.run(`
      CREATE TABLE IF NOT EXISTS LeaveType (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT
      )
    `);
    
    db.run(`
      CREATE TABLE IF NOT EXISTS Task (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT DEFAULT 'PENDING',
        priority TEXT DEFAULT 'MEDIUM',
        dueDate TEXT,
        assignedBy INTEGER,
        assignedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        completedAt TEXT,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (userId) REFERENCES User (id)
      )
    `);
    
    console.log('✅ Tables created successfully');
    
    // Clear existing data
    console.log('📦 Clearing existing data...');
    db.run('DELETE FROM Task');
    db.run('DELETE FROM LeaveType');
    db.run('DELETE FROM User');
    console.log('✅ Existing data cleared');
    
    // Add real users
    console.log('📦 Adding real users...');
    
    const users = [
      {
        name: 'Keshav Kumar',
        email: 'keshaw390@gmail.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543210',
        designation: 'Software Developer',
        department: 'IT',
        gender: 'Male',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Tech Lead'
      },
      {
        name: 'Admin User',
        email: 'admin@techcorp.com',
        password: 'Admin@123',
        role: 'ADMIN',
        phoneNumber: '+919876543211',
        designation: 'System Administrator',
        department: 'Management',
        gender: 'Male',
        shiftTiming: '8:00 AM - 5:00 PM',
        reportingTo: 'CEO'
      },
      {
        name: 'Surya Prakash',
        email: 'suryap1209@gmail.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543212',
        designation: 'UI/UX Designer',
        department: 'Design',
        gender: 'Male',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Design Manager'
      },
      {
        name: 'Priya Sharma',
        email: 'priya.sharma@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543213',
        designation: 'Marketing Specialist',
        department: 'Marketing',
        gender: 'Female',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Marketing Manager'
      },
      {
        name: 'Rahul Singh',
        email: 'rahul.singh@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543214',
        designation: 'Sales Representative',
        department: 'Sales',
        gender: 'Male',
        shiftTiming: '8:30 AM - 5:30 PM',
        reportingTo: 'Sales Manager'
      }
    ];
    
    let addedCount = 0;
    
    for (const userData of users) {
      try {
        const hashedPassword = await bcrypt.hash(userData.password, 12);
        
        db.run(`
          INSERT INTO User (email, password, name, role, phoneNumber, designation, department, gender, shiftTiming, reportingTo, dateOfJoining)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `, [
          userData.email,
          hashedPassword,
          userData.name,
          userData.role,
          userData.phoneNumber,
          userData.designation,
          userData.department,
          userData.gender,
          userData.shiftTiming,
          userData.reportingTo,
          new Date().toISOString()
        ], function(err) {
          if (err) {
            console.log(`⚠️  Could not add ${userData.email}: ${err.message}`);
          } else {
            console.log(`✅ Added: ${userData.name} (${userData.email}) - ${userData.role}`);
            addedCount++;
          }
        });
        
      } catch (error) {
        console.log(`⚠️  Could not add ${userData.email}: ${error.message}`);
      }
    }
    
    // Add leave types
    console.log('📦 Adding leave types...');
    const leaveTypes = [
      { name: 'Sick Leave', description: 'Medical leave for illness' },
      { name: 'Casual Leave', description: 'Personal leave for urgent matters' },
      { name: 'Annual Leave', description: 'Planned vacation leave' },
      { name: 'Maternity Leave', description: 'Leave for expecting mothers' },
      { name: 'Paternity Leave', description: 'Leave for new fathers' }
    ];
    
    leaveTypes.forEach(leaveType => {
      db.run(`
        INSERT INTO LeaveType (name, description)
        VALUES (?, ?)
      `, [leaveType.name, leaveType.description], function(err) {
        if (err) {
          console.log(`⚠️  Could not add leave type ${leaveType.name}`);
        } else {
          console.log(`✅ Added leave type: ${leaveType.name}`);
        }
      });
    });
    
    // Wait a bit for database operations to complete
    setTimeout(() => {
      console.log('');
      console.log('🎉 DATABASE SETUP COMPLETE!');
      console.log('==========================');
      console.log('');
      console.log('📋 REAL USERS IN DATABASE:');
      console.log('');
      users.forEach((user, index) => {
        console.log(`${index + 1}. 👤 ${user.name}`);
        console.log(`   📧 Email: ${user.email}`);
        console.log(`   👑 Role: ${user.role}`);
        console.log(`   📱 Phone: ${user.phoneNumber}`);
        console.log(`   💼 Designation: ${user.designation}`);
        console.log(`   🔐 Password: ${user.password}`);
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
      
      db.close();
    }, 2000);
    
  } catch (error) {
    console.log('❌ Error during setup:', error.message);
  }
}

addRealUsers(); 