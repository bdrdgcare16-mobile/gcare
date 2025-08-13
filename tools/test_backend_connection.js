const axios = require('axios');

const API_BASE = 'http://localhost:3000';

async function testBackendConnection() {
  console.log('🧪 Testing Backend Connection\n');

  try {
    // Test 1: Health check
    console.log('1. Testing health endpoint...');
    const healthResponse = await axios.get(`${API_BASE}/health`);
    console.log('✅ Health check passed:', healthResponse.data);
    console.log('');

    // Test 2: Login with test employee
    console.log('2. Testing login endpoint...');
    const loginResponse = await axios.post(`${API_BASE}/auth/login`, {
      email: 'employee@test.com',
      password: 'password123'
    });
    console.log('✅ Login successful:', loginResponse.data.user.email);
    console.log('');

    // Test 3: Test attendance check-in
    console.log('3. Testing attendance check-in...');
    const token = loginResponse.data.token;
    const checkinResponse = await axios.post(`${API_BASE}/attendance/checkin`, {
      userId: loginResponse.data.user.id,
      timestamp: new Date().toISOString()
    }, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    console.log('✅ Check-in successful:', checkinResponse.data);
    console.log('');

    // Test 4: Test reports endpoint
    console.log('4. Testing reports endpoint...');
    const reportsResponse = await axios.get(`${API_BASE}/reports/dashboard`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    console.log('✅ Reports endpoint working:', reportsResponse.data.summary ? 'Data received' : 'No data');
    console.log('');

    console.log('🎉 All backend tests passed! Your server is working correctly.');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data?.error || error.message);
    
    if (error.code === 'ECONNREFUSED') {
      console.log('\n💡 Backend server is not running. Please start it with:');
      console.log('   cd backend && npm run dev');
    }
  }
}

// Run the test
testBackendConnection(); 