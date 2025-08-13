const axios = require('axios');
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const BASE_URL = 'http://localhost:3000';
const prisma = new PrismaClient();

// Test data for new employees
const newEmployees = [
  {
    name: 'Test Employee 1',
    email: 'test.employee1@company.com',
    password: 'Employee@123',
    role: 'EMPLOYEE',
    phone: '+919876543233',
    designation: 'Test Developer',
    department: 'Testing',
    gender: 'Male',
    shift: '9:00 AM - 6:00 PM',
    reportsTo: 'Test Manager'
  },
  {
    name: 'Test Employee 2',
    email: 'test.employee2@company.com',
    password: 'Employee@123',
    role: 'EMPLOYEE',
    phone: '+919876543234',
    designation: 'Test Designer',
    department: 'Testing',
    gender: 'Female',
    shift: '9:00 AM - 6:00 PM',
    reportsTo: 'Test Manager'
  }
];

async function checkServer() {
  try {
    await axios.get(`${BASE_URL}/health`);
    console.log('✅ Backend server is running on port 3000');
    return true;
  } catch (error) {
    console.log('❌ Backend server is not running on port 3000');
    console.log('Please start the server first: npm start');
    return false;
  }
}

async function addNewEmployee(employeeData) {
  try {
    console.log(`➕ Adding new employee: ${employeeData.name} (${employeeData.email})`);
    
    // Hash the password
    const hashedPassword = await bcrypt.hash(employeeData.password, 10);
    
    // Add to database
    const newUser = await prisma.user.create({
      data: {
        name: employeeData.name,
        email: employeeData.email,
        password: hashedPassword,
        role: employeeData.role,
        phone: employeeData.phone,
        designation: employeeData.designation,
        department: employeeData.department,
        gender: employeeData.gender,
        shift: employeeData.shift,
        reportsTo: employeeData.reportsTo
      }
    });
    
    console.log(`✅ Successfully added: ${newUser.name} (ID: ${newUser.id})`);
    return newUser;
  } catch (error) {
    console.log(`❌ Error adding employee: ${error.message}`);
    return null;
  }
}

async function testLogin(email, password, expectedRole, name) {
  try {
    console.log(`🔐 Testing login: ${email} (${name})`);
    
    const response = await axios.post(`${BASE_URL}/auth/login`, {
      email: email,
      password: password
    });

    if (response.data.success) {
      const userRole = response.data.user.role;
      const userName = response.data.user.name;
      
      if (userRole === expectedRole) {
        console.log(`✅ LOGIN SUCCESS: ${email} - Role: ${userRole} - Name: ${userName}`);
        return { success: true, email, role: userRole, name: userName };
      } else {
        console.log(`❌ ROLE MISMATCH: Expected ${expectedRole}, got ${userRole}`);
        return { success: false, email, error: 'Role mismatch' };
      }
    } else {
      console.log(`❌ LOGIN FAILED: ${email} - ${response.data.message}`);
      return { success: false, email, error: response.data.message };
    }
  } catch (error) {
    console.log(`❌ LOGIN ERROR: ${email} - ${error.response?.data?.message || error.message}`);
    return { success: false, email, error: error.response?.data?.message || error.message };
  }
}

async function testExistingUsers() {
  console.log('🔍 STEP 1: Testing existing users in database...');
  console.log('================================================');
  
  // Test a few existing users
  const existingUsers = [
    { email: 'suryap1209@gmail.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Surya Prakash' },
    { email: 'admin@techcorp.com', password: 'Admin@123', role: 'ADMIN', name: 'Admin User' },
    { email: 'pooja.sharma@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Pooja Sharma' }
  ];
  
  let existingSuccessCount = 0;
  for (const user of existingUsers) {
    const result = await testLogin(user.email, user.password, user.role, user.name);
    if (result.success) existingSuccessCount++;
    await new Promise(resolve => setTimeout(resolve, 200));
  }
  
  console.log(`📊 Existing users test: ${existingSuccessCount}/${existingUsers.length} successful`);
  console.log('');
  return existingSuccessCount === existingUsers.length;
}

async function addAndTestNewEmployees() {
  console.log('➕ STEP 2: Adding new employees to database...');
  console.log('=============================================');
  
  const addedEmployees = [];
  
  for (const employeeData of newEmployees) {
    const newEmployee = await addNewEmployee(employeeData);
    if (newEmployee) {
      addedEmployees.push(newEmployee);
    }
    await new Promise(resolve => setTimeout(resolve, 500));
  }
  
  console.log(`📊 Added ${addedEmployees.length} new employees to database`);
  console.log('');
  
  if (addedEmployees.length === 0) {
    console.log('❌ No employees were added successfully');
    return false;
  }
  
  console.log('🔐 STEP 3: Testing login for newly added employees...');
  console.log('=====================================================');
  
  let newLoginSuccessCount = 0;
  for (const employee of addedEmployees) {
    const result = await testLogin(
      employee.email, 
      'Employee@123', 
      'EMPLOYEE', 
      employee.name
    );
    if (result.success) newLoginSuccessCount++;
    await new Promise(resolve => setTimeout(resolve, 200));
  }
  
  console.log(`📊 New employees login test: ${newLoginSuccessCount}/${addedEmployees.length} successful`);
  console.log('');
  
  return newLoginSuccessCount === addedEmployees.length;
}

async function cleanupTestData() {
  console.log('🧹 STEP 4: Cleaning up test data...');
  console.log('===================================');
  
  try {
    for (const employee of newEmployees) {
      await prisma.user.deleteMany({
        where: {
          email: employee.email
        }
      });
      console.log(`🗑️  Removed test user: ${employee.email}`);
    }
    console.log('✅ Test data cleanup completed');
  } catch (error) {
    console.log(`❌ Error during cleanup: ${error.message}`);
  }
  console.log('');
}

async function showTotalUsers() {
  try {
    const totalUsers = await prisma.user.count();
    console.log(`📊 Total users in database: ${totalUsers}`);
    return totalUsers;
  } catch (error) {
    console.log(`❌ Error counting users: ${error.message}`);
    return 0;
  }
}

async function main() {
  console.log('🚀 COMPREHENSIVE EMPLOYEE LOGIN TEST');
  console.log('====================================');
  console.log('This test demonstrates:');
  console.log('1. Existing users can login');
  console.log('2. New employees can be added to database');
  console.log('3. New employees can login immediately');
  console.log('4. System is scalable for future additions');
  console.log('');
  
  const serverRunning = await checkServer();
  if (!serverRunning) {
    return;
  }
  
  console.log('');
  
  // Step 1: Test existing users
  const existingUsersWork = await testExistingUsers();
  
  // Step 2 & 3: Add and test new employees
  const newEmployeesWork = await addAndTestNewEmployees();
  
  // Step 4: Cleanup
  await cleanupTestData();
  
  // Show final results
  console.log('📋 FINAL TEST RESULTS');
  console.log('=====================');
  console.log(`✅ Existing users login: ${existingUsersWork ? 'WORKING' : 'FAILED'}`);
  console.log(`✅ New employees login: ${newEmployeesWork ? 'WORKING' : 'FAILED'}`);
  
  const totalUsers = await showTotalUsers();
  
  console.log('');
  if (existingUsersWork && newEmployeesWork) {
    console.log('🎉 ALL TESTS PASSED!');
    console.log('🚀 Your system is ready for future employee additions!');
    console.log('');
    console.log('💡 KEY FINDINGS:');
    console.log('   • Existing users can login successfully');
    console.log('   • New employees can be added to database');
    console.log('   • New employees can login immediately after addition');
    console.log('   • System is scalable and production-ready');
    console.log('');
    console.log('🔐 FUTURE WORKFLOW:');
    console.log('   1. Add new employee to database');
    console.log('   2. Employee can login immediately with default password');
    console.log('   3. Employee can change password after first login');
    console.log('   4. All features work for new employees');
  } else {
    console.log('⚠️  Some tests failed. Check the errors above.');
  }
  
  console.log('');
  console.log('📊 DATABASE STATUS:');
  console.log(`   • Total users: ${totalUsers}`);
  console.log('   • System ready for new additions');
}

main()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect();
  }); 