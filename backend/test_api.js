const http = require('http');

// Test the health endpoint
const testHealth = () => {
  return new Promise((resolve, reject) => {
    const req = http.request('http://localhost:3000/health', (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        console.log('✅ Health endpoint:', res.statusCode, data);
        resolve();
      });
    });
    req.on('error', reject);
    req.end();
  });
};

// Test login endpoint
const testLogin = () => {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      email: 'admin@test.com',
      password: 'password123'
    });

    const req = http.request('http://localhost:3000/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        console.log('✅ Login endpoint:', res.statusCode, data);
        resolve();
      });
    });
    req.on('error', reject);
    req.write(postData);
    req.end();
  });
};

// Run tests
async function runTests() {
  try {
    console.log('🧪 Testing Backend API...\n');
    await testHealth();
    await testLogin();
    console.log('\n🎉 All tests completed!');
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

runTests(); 