const axios = require('axios');

const API_BASE = 'http://localhost:3000';

async function testEmployeeAuth() {
  console.log('🧪 Testing Employee Authentication\n');

  try {
    // Test 1: Login with existing employee
    console.log('1. Testing login with existing employee...');
    const loginResponse = await axios.post(`${API_BASE}/auth/login`, {
      email: 'employee@test.com',
      password: 'password123'
    });
    
    console.log('✅ Login successful!');
    console.log(`   User: ${loginResponse.data.user.name}`);
    console.log(`   Role: ${loginResponse.data.user.role}`);
    console.log(`   Token: ${loginResponse.data.token.substring(0, 20)}...`);
    console.log('');

    // Test 2: Create new employee via API
    console.log('2. Creating new employee via API...');
    const createResponse = await axios.post(`${API_BASE}/users/employees`, {
      name: 'API Test Employee',
      email: 'api.test@company.com',
      password: 'apitest123'
    });
    
    console.log('✅ Employee created via API!');
    console.log(`   Name: ${createResponse.data.employee.name}`);
    console.log(`   Email: ${createResponse.data.employee.email}`);
    console.log(`   Role: ${createResponse.data.employee.role}`);
    console.log('');

    // Test 3: Login with newly created employee
    console.log('3. Testing login with newly created employee...');
    const newLoginResponse = await axios.post(`${API_BASE}/auth/login`, {
      email: 'api.test@company.com',
      password: 'apitest123'
    });
    
    console.log('✅ New employee login successful!');
    console.log(`   User: ${newLoginResponse.data.user.name}`);
    console.log(`   Role: ${newLoginResponse.data.user.role}`);
    console.log('');

    // Test 4: Get all employees
    console.log('4. Fetching all employees...');
    const employeesResponse = await axios.get(`${API_BASE}/users/employees`);
    
    console.log('✅ Employees fetched successfully!');
    console.log(`   Total employees: ${employeesResponse.data.employees.length}`);
    employeesResponse.data.employees.slice(0, 3).forEach((emp, index) => {
      console.log(`   ${index + 1}. ${emp.name} (${emp.email})`);
    });
    console.log('');

    console.log('🎉 All tests passed! Employee authentication system is working correctly.');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data?.error || error.message);
    
    if (error.code === 'ECONNREFUSED') {
      console.log('\n💡 Make sure the backend server is running:');
      console.log('   cd backend && npm start');
    }
  }
}

// Run the test
testEmployeeAuth(); 