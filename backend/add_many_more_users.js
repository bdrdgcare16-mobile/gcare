const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');
const path = require('path');

function addManyMoreUsers() {
  console.log('🚀 ADDING MANY MORE REAL USERS');
  console.log('================================');
  console.log('');
  
  const dbPath = path.join(__dirname, 'prisma', 'dev.db');
  
  try {
    const db = new sqlite3.Database(dbPath);
    
    // Many more real users
    const users = [
      // Original 5 users (keeping them)
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
      },
      
      // Adding many more users
      {
        name: 'Amit Patel',
        email: 'amit.patel@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543215',
        designation: 'Data Analyst',
        department: 'Analytics',
        gender: 'Male',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Analytics Manager'
      },
      {
        name: 'Neha Gupta',
        email: 'neha.gupta@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543216',
        designation: 'HR Specialist',
        department: 'Human Resources',
        gender: 'Female',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'HR Manager'
      },
      {
        name: 'Rajesh Kumar',
        email: 'rajesh.kumar@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543217',
        designation: 'Network Engineer',
        department: 'IT',
        gender: 'Male',
        shiftTiming: '8:00 AM - 5:00 PM',
        reportingTo: 'IT Manager'
      },
      {
        name: 'Anjali Singh',
        email: 'anjali.singh@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543218',
        designation: 'Content Writer',
        department: 'Marketing',
        gender: 'Female',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Content Manager'
      },
      {
        name: 'Vikram Malhotra',
        email: 'vikram.malhotra@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543219',
        designation: 'Quality Assurance',
        department: 'IT',
        gender: 'Male',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'QA Manager'
      },
      {
        name: 'Pooja Sharma',
        email: 'pooja.sharma@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543220',
        designation: 'Customer Support',
        department: 'Support',
        gender: 'Female',
        shiftTiming: '8:30 AM - 5:30 PM',
        reportingTo: 'Support Manager'
      },
      {
        name: 'Arun Verma',
        email: 'arun.verma@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543221',
        designation: 'Business Analyst',
        department: 'Business',
        gender: 'Male',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Business Manager'
      },
      {
        name: 'Meera Kapoor',
        email: 'meera.kapoor@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543222',
        designation: 'Graphic Designer',
        department: 'Design',
        gender: 'Female',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Design Manager'
      },
      {
        name: 'Sandeep Reddy',
        email: 'sandeep.reddy@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543223',
        designation: 'DevOps Engineer',
        department: 'IT',
        gender: 'Male',
        shiftTiming: '8:00 AM - 5:00 PM',
        reportingTo: 'DevOps Manager'
      },
      {
        name: 'Kavita Joshi',
        email: 'kavita.joshi@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543224',
        designation: 'Financial Analyst',
        department: 'Finance',
        gender: 'Female',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Finance Manager'
      },
      {
        name: 'Rohit Mehta',
        email: 'rohit.mehta@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543225',
        designation: 'Product Manager',
        department: 'Product',
        gender: 'Male',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Product Director'
      },
      {
        name: 'Sunita Iyer',
        email: 'sunita.iyer@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543226',
        designation: 'Legal Advisor',
        department: 'Legal',
        gender: 'Female',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Legal Manager'
      },
      {
        name: 'Manoj Tiwari',
        email: 'manoj.tiwari@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543227',
        designation: 'Security Engineer',
        department: 'IT',
        gender: 'Male',
        shiftTiming: '8:00 AM - 5:00 PM',
        reportingTo: 'Security Manager'
      },
      {
        name: 'Deepika Nair',
        email: 'deepika.nair@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543228',
        designation: 'Research Analyst',
        department: 'Research',
        gender: 'Female',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Research Manager'
      },
      {
        name: 'Aditya Chopra',
        email: 'aditya.chopra@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543229',
        designation: 'Mobile Developer',
        department: 'IT',
        gender: 'Male',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Mobile Team Lead'
      },
      {
        name: 'Rashmi Desai',
        email: 'rashmi.desai@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543230',
        designation: 'Event Coordinator',
        department: 'Marketing',
        gender: 'Female',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Marketing Manager'
      },
      {
        name: 'Vivek Saxena',
        email: 'vivek.saxena@company.com',
        password: 'Admin@123',
        role: 'ADMIN',
        phoneNumber: '+919876543231',
        designation: 'Operations Manager',
        department: 'Operations',
        gender: 'Male',
        shiftTiming: '8:00 AM - 5:00 PM',
        reportingTo: 'CEO'
      },
      {
        name: 'Shweta Agarwal',
        email: 'shweta.agarwal@company.com',
        password: 'Admin@123',
        role: 'ADMIN',
        phoneNumber: '+919876543232',
        designation: 'Project Manager',
        department: 'Project Management',
        gender: 'Female',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Program Director'
      }
    ];
    
    console.log(`📦 Adding ${users.length} users to database...`);
    
    let addedCount = 0;
    let skippedCount = 0;
    
    users.forEach((userData, index) => {
      bcrypt.hash(userData.password, 12).then(hashedPassword => {
        const now = new Date().toISOString();
        
        db.run(`
          INSERT OR IGNORE INTO User (email, password, name, role, phoneNumber, designation, department, gender, shiftTiming, reportingTo, dateOfJoining, createdAt, updatedAt)
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
          } else if (this.changes > 0) {
            console.log(`✅ Added: ${userData.name} (${userData.email}) - ${userData.role}`);
            addedCount++;
          } else {
            console.log(`⏭️  Skipped: ${userData.name} (${userData.email}) - already exists`);
            skippedCount++;
          }
          
          if (addedCount + skippedCount === users.length) {
            console.log('');
            console.log('🎉 USER ADDITION COMPLETE!');
            console.log('==========================');
            console.log(`✅ Added: ${addedCount} new users`);
            console.log(`⏭️  Skipped: ${skippedCount} existing users`);
            console.log(`📊 Total users in database: ${addedCount + skippedCount}`);
            console.log('');
            console.log('🔍 Run "node show_all_real_users.js" to see all users!');
            
            db.close();
          }
        });
      }).catch(error => {
        console.log(`⚠️  Could not hash password for ${userData.email}: ${error.message}`);
      });
    });
    
  } catch (error) {
    console.log('❌ Error during setup:', error.message);
  }
}

addManyMoreUsers(); 