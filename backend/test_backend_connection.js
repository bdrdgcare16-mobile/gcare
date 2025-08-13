const axios = require('axios');

const API_BASE_URL = 'http://localhost:3000';

async function testBackendConnection() {
  console.log('🔍 Testing Backend Connection...');
  console.log('=====================================');
  
  try {
    // Test 1: Health Check
    console.log('1️⃣ Testing Health Check...');
    const healthResponse = await axios.get(`${API_BASE_URL}/health`);
    console.log('✅ Health Check: SUCCESS');
    console.log('   Status:', healthResponse.status);
    console.log('   Response:', healthResponse.data);
    
    // Test 2: Login with your email
    console.log('\n2️⃣ Testing Login with your email...');
    const loginData = {
      email: 'nishalimrtech22@gmail.com',
      password: 'Nishali@123'
    };
    
    const loginResponse = await axios.post(`${API_BASE_URL}/auth/login`, loginData);
    console.log('✅ Login Test: SUCCESS');
    console.log('   Status:', loginResponse.status);
    console.log('   User:', loginResponse.data.user.name);
    console.log('   Role:', loginResponse.data.user.role);
    
    // Test 3: Test registration
    console.log('\n3️⃣ Testing Registration...');
    const newUser = {
      name: 'Test User',
      email: 'testuser@example.com',
      password: 'test123',
      role: 'EMPLOYEE',
      phoneNumber: '1234567890',
      designation: 'Test Developer',
      department: 'IT',
      gender: 'Male',
      shiftTiming: '9:00 AM - 6:00 PM',
      reportingTo: 'Test Manager',
      dateOfJoining: new Date().toISOString()
    };
    
    const registerResponse = await axios.post(`${API_BASE_URL}/auth/register`, newUser);
    console.log('✅ Registration Test: SUCCESS');
    console.log('   Status:', registerResponse.status);
    console.log('   Message:', registerResponse.data.message);
    
    // Test 4: Login with newly registered user
    console.log('\n4️⃣ Testing Login with newly registered user...');
    const newLoginData = {
      email: 'testuser@example.com',
      password: 'test123'
    };
    
    const newLoginResponse = await axios.post(`${API_BASE_URL}/auth/login`, newLoginData);
    console.log('✅ New User Login: SUCCESS');
    console.log('   Status:', newLoginResponse.status);
    console.log('   User:', newLoginResponse.data.user.name);
    
    console.log('\n🎉 ALL TESTS PASSED!');
    console.log('✅ Backend is working perfectly!');
    console.log('✅ Real database authentication works!');
    console.log('✅ Registration → Login flow works!');
    
  } catch (error) {
    console.error('❌ Test Failed:', error.message);
    if (error.response) {
      console.error('   Status:', error.response.status);
      console.error('   Data:', error.response.data);
    }
    console.log('\n🔧 Troubleshooting:');
    console.log('   1. Make sure backend is running: npm start');
    console.log('   2. Check if port 3000 is available');
    console.log('   3. Verify database is connected');
  }
}

testBackendConnection(); 