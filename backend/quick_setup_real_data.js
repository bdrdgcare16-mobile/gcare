const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');
const path = require('path');

function quickSetupRealData() {
  console.log('🚀 QUICK SETUP - REAL DATA');
  console.log('==========================');
  console.log('');
  
  const dbPath = path.join(__dirname, 'prisma', 'dev.db');
  
  try {
    const db = new sqlite3.Database(dbPath);
    
    // Drop and recreate tables
    console.log('📦 Setting up database...');
    
    db.serialize(() => {
      // Drop existing tables
      db.run('DROP TABLE IF EXISTS Task');
      db.run('DROP TABLE IF EXISTS LeaveType');
      db.run('DROP TABLE IF EXISTS User');
      
      // Create User table
      db.run(`
        CREATE TABLE User (
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
      
      // Create LeaveType table
      db.run(`
        CREATE TABLE LeaveType (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT
        )
      `);
      
      // Create Task table
      db.run(`
        CREATE TABLE Task (
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
      `, function(err) {
        if (err) {
          console.log('❌ Error creating tables:', err.message);
        } else {
          console.log('✅ Tables created successfully');
          addUsers();
        }
      });
    });
    
    function addUsers() {
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
      
      users.forEach((userData, index) => {
        bcrypt.hash(userData.password, 12).then(hashedPassword => {
          const now = new Date().toISOString();
          
          db.run(`
            INSERT INTO User (email, password, name, role, phoneNumber, designation, department, gender, shiftTiming, reportingTo, dateOfJoining, createdAt, updatedAt)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
            now,
            now,
            now
          ], function(err) {
            if (err) {
              console.log(`⚠️  Could not add ${userData.email}: ${err.message}`);
            } else {
              console.log(`✅ Added: ${userData.name} (${userData.email}) - ${userData.role}`);
              addedCount++;
              
              if (addedCount === users.length) {
                addLeaveTypes();
              }
            }
          });
        }).catch(error => {
          console.log(`⚠️  Could not hash password for ${userData.email}: ${error.message}`);
        });
      });
    }
    
    function addLeaveTypes() {
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
            console.log(`⚠️  Could not add leave type ${leaveType.name}: ${err.message}`);
          } else {
            console.log(`✅ Added leave type: ${leaveType.name}`);
          }
        });
      });
      
      // Show final results
      setTimeout(() => {
        console.log('');
        console.log('🎉 DATABASE SETUP COMPLETE!');
        console.log('==========================');
        console.log('');
        console.log('📋 REAL USERS IN DATABASE:');
        console.log('');
        console.log('1. 👤 Keshav Kumar');
        console.log('   📧 Email: keshaw390@gmail.com');
        console.log('   👑 Role: EMPLOYEE');
        console.log('   📱 Phone: +919876543210');
        console.log('   💼 Designation: Software Developer');
        console.log('   🔐 Password: Employee@123');
        console.log('');
        console.log('2. 👤 Admin User');
        console.log('   📧 Email: admin@techcorp.com');
        console.log('   👑 Role: ADMIN');
        console.log('   📱 Phone: +919876543211');
        console.log('   💼 Designation: System Administrator');
        console.log('   🔐 Password: Admin@123');
        console.log('');
        console.log('3. 👤 Surya Prakash');
        console.log('   📧 Email: suryap1209@gmail.com');
        console.log('   👑 Role: EMPLOYEE');
        console.log('   📱 Phone: +919876543212');
        console.log('   💼 Designation: UI/UX Designer');
        console.log('   🔐 Password: Employee@123');
        console.log('');
        console.log('4. 👤 Priya Sharma');
        console.log('   📧 Email: priya.sharma@company.com');
        console.log('   👑 Role: EMPLOYEE');
        console.log('   📱 Phone: +919876543213');
        console.log('   💼 Designation: Marketing Specialist');
        console.log('   🔐 Password: Employee@123');
        console.log('');
        console.log('5. 👤 Rahul Singh');
        console.log('   📧 Email: rahul.singh@company.com');
        console.log('   👑 Role: EMPLOYEE');
        console.log('   📱 Phone: +919876543214');
        console.log('   💼 Designation: Sales Representative');
        console.log('   🔐 Password: Employee@123');
        console.log('');
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
    }
    
  } catch (error) {
    console.log('❌ Error during setup:', error.message);
  }
}

quickSetupRealData(); 