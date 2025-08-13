const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function addSingleEmployee() {
  try {
    console.log('➕ ADDING NEW EMPLOYEE TO DATABASE');
    console.log('==================================');
    
    // Hash the default password
    const hashedPassword = await bcrypt.hash('Employee@123', 10);
    
    // Create new employee (CHANGE THESE DETAILS AS NEEDED)
    const newEmployee = {
      name: 'New Employee Name',           // CHANGE THIS
      email: 'new.employee@company.com',   // CHANGE THIS (must be unique)
      password: hashedPassword,
      role: 'EMPLOYEE',
      phoneNumber: '+919876543236',        // CHANGE THIS
      designation: 'Software Developer',   // CHANGE THIS
      department: 'Engineering',           // CHANGE THIS
      gender: 'Male',                      // CHANGE THIS
      shiftTiming: '9:00 AM - 6:00 PM',   // CHANGE THIS
      reportingTo: 'Engineering Manager'   // CHANGE THIS
    };
    
    // Add to database
    const user = await prisma.user.create({
      data: newEmployee
    });
    
    console.log('✅ EMPLOYEE ADDED SUCCESSFULLY!');
    console.log(`   ID: ${user.id}`);
    console.log(`   Name: ${user.name}`);
    console.log(`   Email: ${user.email}`);
    console.log(`   Role: ${user.role}`);
    console.log('');
    
    console.log('🔐 LOGIN DETAILS:');
    console.log(`   Email: ${user.email}`);
    console.log('   Password: Employee@123');
    console.log('');
    
    console.log('🎯 NEXT STEPS:');
    console.log('   1. Go to your app: http://localhost:8080');
    console.log('   2. Login with the email and password above');
    console.log('   3. Verify all features work for the new employee');
    console.log('');
    
    console.log('✅ SUCCESS! New employee can login immediately!');
    
  } catch (error) {
    console.log('❌ ERROR:', error.message);
    
    if (error.message.includes('unique constraint')) {
      console.log('💡 TIP: Email already exists. Use a different email address.');
    }
  }
}

// Show current database status
async function showStatus() {
  try {
    const totalUsers = await prisma.user.count();
    const employees = await prisma.user.count({
      where: { role: 'EMPLOYEE' }
    });
    const admins = await prisma.user.count({
      where: { role: 'ADMIN' }
    });
    
    console.log('📊 CURRENT DATABASE STATUS:');
    console.log(`   Total Users: ${totalUsers}`);
    console.log(`   Employees: ${employees}`);
    console.log(`   Admins: ${admins}`);
    console.log('');
  } catch (error) {
    console.log('❌ Error getting status:', error.message);
  }
}

async function main() {
  console.log('🚀 ADDING NEW EMPLOYEE');
  console.log('======================');
  console.log('');
  
  await showStatus();
  await addSingleEmployee();
  
  console.log('');
  console.log('📊 UPDATED DATABASE STATUS:');
  await showStatus();
}

main()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect();
  }); 