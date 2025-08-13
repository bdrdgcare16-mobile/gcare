const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const axios = require('axios');

const prisma = new PrismaClient();
const BASE_URL = 'http://localhost:3000';

// Example: How to add a new employee in the future
async function addFutureEmployee(employeeData) {
  try {
    console.log('➕ ADDING NEW EMPLOYEE TO DATABASE');
    console.log('==================================');
    console.log(`Name: ${employeeData.name}`);
    console.log(`Email: ${employeeData.email}`);
    console.log(`Role: ${employeeData.role}`);
    console.log(`Department: ${employeeData.department}`);
    console.log('');
    
    // Hash the password
    const hashedPassword = await bcrypt.hash(employeeData.password, 10);
    
    // Add to database
    const newUser = await prisma.user.create({
      data: {
        name: employeeData.name,
        email: employeeData.email,
        password: hashedPassword,
        role: employeeData.role,
        phoneNumber: employeeData.phone,
        designation: employeeData.designation,
        department: employeeData.department,
        gender: employeeData.gender,
        shiftTiming: employeeData.shift,
        reportingTo: employeeData.reportsTo
      }
    });
    
    console.log(`✅ EMPLOYEE ADDED SUCCESSFULLY!`);
    console.log(`   ID: ${newUser.id}`);
    console.log(`   Name: ${newUser.name}`);
    console.log(`   Email: ${newUser.email}`);
    console.log('');
    
    return newUser;
  } catch (error) {
    console.log(`❌ Error adding employee: ${error.message}`);
    return null;
  }
}

async function testNewEmployeeLogin(email, password, expectedName) {
  try {
    console.log('🔐 TESTING LOGIN FOR NEW EMPLOYEE');
    console.log('==================================');
    console.log(`Email: ${email}`);
    console.log(`Password: ${password}`);
    console.log('');
    
    const response = await axios.post(`${BASE_URL}/auth/login`, {
      email: email,
      password: password
    });

    if (response.data.success) {
      const user = response.data.user;
      console.log(`✅ LOGIN SUCCESSFUL!`);
      console.log(`   Name: ${user.name}`);
      console.log(`   Role: ${user.role}`);
      console.log(`   Department: ${user.department}`);
      console.log(`   Phone: ${user.phone}`);
      console.log('');
      console.log('🎉 NEW EMPLOYEE CAN LOGIN IMMEDIATELY!');
      return true;
    } else {
      console.log(`❌ Login failed: ${response.data.message}`);
      return false;
    }
  } catch (error) {
    console.log(`❌ Login error: ${error.response?.data?.message || error.message}`);
    return false;
  }
}

async function showEmployeeCount() {
  try {
    const totalUsers = await prisma.user.count();
    const employees = await prisma.user.count({
      where: { role: 'EMPLOYEE' }
    });
    const admins = await prisma.user.count({
      where: { role: 'ADMIN' }
    });
    
    console.log('📊 DATABASE STATISTICS');
    console.log('======================');
    console.log(`Total Users: ${totalUsers}`);
    console.log(`Employees: ${employees}`);
    console.log(`Admins: ${admins}`);
    console.log('');
  } catch (error) {
    console.log(`❌ Error getting statistics: ${error.message}`);
  }
}

// Example usage
async function main() {
  console.log('🚀 FUTURE EMPLOYEE ADDITION DEMO');
  console.log('=================================');
  console.log('This demonstrates how to add new employees');
  console.log('and verify they can login immediately.');
  console.log('');
  
  // Check if server is running
  try {
    await axios.get(`${BASE_URL}/health`);
    console.log('✅ Backend server is running');
  } catch (error) {
    console.log('❌ Backend server is not running. Please start it first.');
    return;
  }
  
  console.log('');
  
  // Show current database status
  await showEmployeeCount();
  
  // Example: Add a new employee
  const timestamp = Date.now();
  const newEmployee = {
    name: 'Future Employee Demo',
    email: `future.employee.${timestamp}@company.com`,
    password: 'Employee@123',
    role: 'EMPLOYEE',
    phone: '+919876543235',
    designation: 'Future Developer',
    department: 'Future Tech',
    gender: 'Male',
    shift: '9:00 AM - 6:00 PM',
    reportsTo: 'Future Manager'
  };
  
  // Step 1: Add employee to database
  const addedEmployee = await addFutureEmployee(newEmployee);
  
  if (addedEmployee) {
    // Step 2: Test login immediately
    const loginSuccess = await testNewEmployeeLogin(
      newEmployee.email,
      newEmployee.password,
      newEmployee.name
    );
    
    console.log('📋 WORKFLOW SUMMARY');
    console.log('===================');
    if (loginSuccess) {
      console.log('✅ STEP 1: Employee added to database - SUCCESS');
      console.log('✅ STEP 2: Employee can login immediately - SUCCESS');
      console.log('');
      console.log('🎉 FUTURE WORKFLOW VERIFIED!');
      console.log('   When you add new employees to the database,');
      console.log('   they can login immediately with the default password.');
    } else {
      console.log('❌ STEP 2: Employee login failed');
    }
    
    // Cleanup: Remove the test employee
    console.log('');
    console.log('🧹 Cleaning up test data...');
    try {
      await prisma.user.delete({
        where: { email: newEmployee.email }
      });
      console.log('✅ Test employee removed from database');
    } catch (error) {
      console.log(`❌ Error removing test employee: ${error.message}`);
    }
  }
  
  console.log('');
  console.log('💡 FUTURE INSTRUCTIONS:');
  console.log('=======================');
  console.log('1. Use addFutureEmployee() function to add new employees');
  console.log('2. New employees can login immediately with default password');
  console.log('3. Default passwords: Employee@123 (employees), Admin@123 (admins)');
  console.log('4. Employees can change password after first login');
  console.log('5. All app features work for new employees automatically');
}

main()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect();
  }); 