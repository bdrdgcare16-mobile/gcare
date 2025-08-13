@echo off
echo 🔍 CHECKING BACKEND SERVER STATUS
echo =================================
echo.

echo 📊 Testing backend connection...
echo 💡 This will check if your backend server is running
echo.

cd backend
node -e "const http = require('http'); const req = http.request({hostname: 'localhost', port: 3000, path: '/health', method: 'GET'}, (res) => { console.log('✅ Backend server is RUNNING!'); console.log('Status:', res.statusCode); process.exit(0); }); req.on('error', (err) => { console.log('❌ Backend server is NOT RUNNING'); console.log('Error:', err.message); console.log(''); console.log('💡 To start the backend server:'); console.log('1. Open a new terminal'); console.log('2. Run: cd backend'); console.log('3. Run: npm start'); console.log('4. Keep that terminal open'); process.exit(1); }); req.end();"

echo.
echo 🎯 NEXT STEPS:
echo ===============
echo 1. If backend is running: Try logging in now
echo 2. If backend is not running: Start it with npm start
echo 3. Make sure to keep the backend terminal open
echo.
pause 