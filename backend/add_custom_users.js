const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function addCustomUsers() {
  console.log('👥 ADDING CUSTOM EMPLOYEE AND ADMIN USERS');
  console.log('==========================================');
  console.log('');

  try {
    // Custom users to add
    const customUsers = [
      // Admin Users
      {
        name: 'System Administrator',
        email: 'admin@nishali.com',
        password: 'admin123',
        role: 'ADMIN',
        phoneNumber: '+919876543210',
        designation: 'System Administrator',
        department: 'IT',
        gender: 'Not specified',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'CEO',
        dateOfJoining: '2024-01-01'
      },
      {
        name: 'HR Manager',
        email: 'hr@nishali.com',
        password: 'hr123',
        role: 'ADMIN',
        phoneNumber: '+919876543211',
        designation: 'HR Manager',
        department: 'Human Resources',
        gender: 'Not specified',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'CEO',
        dateOfJoining: '2024-01-15'
      },
      
      // Employee Users
      {
        name: 'John Doe',
        email: 'john.doe@nishali.com',
        password: 'employee123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543212',
        designation: 'Software Developer',
        department: 'Engineering',
        gender: 'Male',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Team Lead',
        dateOfJoining: '2024-02-01'
      },
      {
        name: 'Jane Smith',
        email: 'jane.smith@nishali.com',
        password: 'employee123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543213',
        designation: 'UI/UX Designer',
        department: 'Design',
        gender: 'Female',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Design Lead',
        dateOfJoining: '2024-02-15'
      },
      {
        name: 'Mike Johnson',
        email: 'mike.johnson@nishali.com',
        password: 'employee123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543214',
        designation: 'Marketing Specialist',
        department: 'Marketing',
        gender: 'Male',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Marketing Manager',
        dateOfJoining: '2024-03-01'
      },
      {
        name: 'Sarah Wilson',
        email: 'sarah.wilson@nishali.com',
        password: 'employee123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543215',
        designation: 'Sales Representative',
        department: 'Sales',
        gender: 'Female',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Sales Manager',
        dateOfJoining: '2024-03-15'
      }
    ];

    console.log('📝 Adding custom users...');
    console.log('');

    for (const userData of customUsers) {
      try {
        // Hash password
        const hashedPassword = await bcrypt.hash(userData.password, 10);
        
        // Create or update user
        const user = await prisma.user.upsert({
          where: { email: userData.email },
          update: {
            name: userData.name,
            password: hashedPassword,
            role: userData.role,
            phoneNumber: userData.phoneNumber,
            designation: userData.designation,
            department: userData.department,
            gender: userData.gender,
            shiftTiming: userData.shiftTiming,
            reportingTo: userData.reportingTo,
            dateOfJoining: new Date(userData.dateOfJoining)
          },
          create: {
            email: userData.email,
            password: hashedPassword,
            name: userData.name,
            role: userData.role,
            phoneNumber: userData.phoneNumber,
            designation: userData.designation,
            department: userData.department,
            gender: userData.gender,
            shiftTiming: userData.shiftTiming,
            reportingTo: userData.reportingTo,
            dateOfJoining: new Date(userData.dateOfJoining)
          }
        });

        console.log(`✅ ${userData.role}: ${user.name} (${user.email})`);
        console.log(`   Password: ${userData.password}`);
      } catch (error) {
        console.log(`❌ Failed to add ${userData.email}: ${error.message}`);
      }
    }

    console.log('');
    console.log('🎉 CUSTOM USERS ADDED SUCCESSFULLY!');
    console.log('');
    console.log('🔐 LOGIN CREDENTIALS:');
    console.log('====================');
    console.log('');
    console.log('👑 ADMIN USERS:');
    console.log('   • admin@nishali.com / admin123');
    console.log('   • hr@nishali.com / hr123');
    console.log('');
    console.log('👥 EMPLOYEE USERS:');
    console.log('   • john.doe@nishali.com / employee123');
    console.log('   • jane.smith@nishali.com / employee123');
    console.log('   • mike.johnson@nishali.com / employee123');
    console.log('   • sarah.wilson@nishali.com / employee123');
    console.log('');
    console.log('🚀 READY TO TEST!');
    console.log('   1. Start your backend: npm start');
    console.log('   2. Start your Flutter app: flutter run -d chrome');
    console.log('   3. Login with any of the credentials above');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Run the function
addCustomUsers(); 