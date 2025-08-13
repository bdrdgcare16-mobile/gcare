const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

async function addMultipleUsers() {
  console.log('👥 ADDING MULTIPLE USERS TO DATABASE');
  console.log('====================================');
  console.log('');
  
  const prisma = new PrismaClient();
  
  // Sample users to add
  const usersToAdd = [
    {
      name: 'John Doe',
      email: 'john.doe@company.com',
      role: 'EMPLOYEE',
      phoneNumber: '+1234567890',
      designation: 'Software Developer',
      department: 'IT',
      gender: 'Male',
      shiftTiming: '9:00 AM - 6:00 PM',
      reportingTo: 'Tech Lead'
    },
    {
      name: 'Jane Smith',
      email: 'jane.smith@company.com',
      role: 'EMPLOYEE',
      phoneNumber: '+1234567891',
      designation: 'UI/UX Designer',
      department: 'Design',
      gender: 'Female',
      shiftTiming: '9:00 AM - 6:00 PM',
      reportingTo: 'Design Manager'
    },
    {
      name: 'Mike Johnson',
      email: 'mike.johnson@company.com',
      role: 'ADMIN',
      phoneNumber: '+1234567892',
      designation: 'Project Manager',
      department: 'Management',
      gender: 'Male',
      shiftTiming: '8:00 AM - 5:00 PM',
      reportingTo: 'CEO'
    },
    {
      name: 'Sarah Wilson',
      email: 'sarah.wilson@company.com',
      role: 'EMPLOYEE',
      phoneNumber: '+1234567893',
      designation: 'Marketing Specialist',
      department: 'Marketing',
      gender: 'Female',
      shiftTiming: '9:00 AM - 6:00 PM',
      reportingTo: 'Marketing Manager'
    },
    {
      name: 'David Brown',
      email: 'david.brown@company.com',
      role: 'EMPLOYEE',
      phoneNumber: '+1234567894',
      designation: 'Sales Representative',
      department: 'Sales',
      gender: 'Male',
      shiftTiming: '8:30 AM - 5:30 PM',
      reportingTo: 'Sales Manager'
    }
  ];
  
  try {
    let addedCount = 0;
    let skippedCount = 0;
    
    for (const userData of usersToAdd) {
      try {
        // Check if user already exists
        const existingUser = await prisma.user.findUnique({
          where: { email: userData.email }
        });
        
        if (existingUser) {
          console.log(`⏭️  Skipped: ${userData.email} (already exists)`);
          skippedCount++;
          continue;
        }
        
        // Hash password based on role
        const defaultPassword = userData.role === 'ADMIN' ? 'Admin@123' : 'Employee@123';
        const hashedPassword = await bcrypt.hash(defaultPassword, 12);
        
        // Create user
        const user = await prisma.user.create({
          data: {
            ...userData,
            password: hashedPassword,
            dateOfJoining: new Date()
          }
        });
        
        console.log(`✅ Added: ${user.name} (${user.email}) - ${user.role}`);
        console.log(`   📱 Phone: ${user.phoneNumber}`);
        console.log(`   💼 Designation: ${user.designation}`);
        console.log(`   🔐 Password: ${defaultPassword}`);
        console.log('');
        
        addedCount++;
        
      } catch (error) {
        console.log(`❌ Failed to add ${userData.email}: ${error.message}`);
      }
    }
    
    console.log('📊 SUMMARY:');
    console.log(`   ✅ Added: ${addedCount} users`);
    console.log(`   ⏭️  Skipped: ${skippedCount} users (already exist)`);
    console.log('');
    
    if (addedCount > 0) {
      console.log('🎯 NEW LOGIN CREDENTIALS:');
      console.log('========================');
      console.log('');
      console.log('You can now login with any of these new emails:');
      console.log('');
      
      usersToAdd.forEach(user => {
        const password = user.role === 'ADMIN' ? 'Admin@123' : 'Employee@123';
        console.log(`   • ${user.email} / ${password}`);
      });
      
      console.log('');
      console.log('🚀 TEST YOUR APP:');
      console.log('   1. Open: http://localhost:8080');
      console.log('   2. Try any of the new email/password combinations');
      console.log('   3. All users should login successfully!');
    }
    
  } catch (error) {
    console.log('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

addMultipleUsers(); 