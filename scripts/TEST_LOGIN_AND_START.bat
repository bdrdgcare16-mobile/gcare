@echo off
echo 🔐 TESTING LOGIN AND STARTING BACKEND
echo =====================================
echo.

echo 📊 Step 1: Testing login credentials...
cd backend
node test_login.js

echo.
echo 🚀 Step 2: Starting backend server...
echo 💡 This will start the server on http://localhost:3000
echo 💡 Keep this window open while testing login
echo.

npm start

echo.
echo ✅ Backend server started!
echo 💡 Now try logging in with your real credentials
echo.
pause 