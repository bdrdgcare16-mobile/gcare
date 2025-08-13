@echo off
echo ========================================
echo 🧪 TESTING ALL HRMS APIs
echo ========================================
echo.

echo Step 1: Starting backend server...
cd backend
start /B npm start
timeout /t 5 /nobreak >nul

echo Step 2: Testing server health...
curl -X GET http://localhost:3000/health
echo.

echo Step 3: Testing authentication APIs...
echo.
echo Testing login API...
curl -X POST http://localhost:3000/auth/login -H "Content-Type: application/json" -d "{\"email\": \"admin@company.com\", \"password\": \"123456\"}"
echo.

echo Step 4: Testing user APIs...
echo.
echo Testing get users API...
curl -X GET http://localhost:3000/users
echo.

echo Step 5: Testing attendance APIs...
echo.
echo Testing attendance history API...
curl -X GET http://localhost:3000/attendance/history
echo.

echo Step 6: Testing task APIs...
echo.
echo Testing get tasks API...
curl -X GET http://localhost:3000/tasks
echo.

echo Step 7: Testing announcement APIs...
echo.
echo Testing get announcements API...
curl -X GET http://localhost:3000/announcements
echo.

echo Step 8: Testing dashboard APIs...
echo.
echo Testing dashboard API...
curl -X GET http://localhost:3000/dashboard
echo.

echo Step 9: Testing reports APIs...
echo.
echo Testing reports API...
curl -X GET http://localhost:3000/reports/attendance
echo.

echo.
echo ========================================
echo 🎉 API TESTING COMPLETE!
echo ========================================
echo.
echo ✅ Health check tested
echo ✅ Authentication APIs tested
echo ✅ User APIs tested
echo ✅ Attendance APIs tested
echo ✅ Task APIs tested
echo ✅ Announcement APIs tested
echo ✅ Dashboard APIs tested
echo ✅ Reports APIs tested
echo.
echo 📊 Check the output above for any errors
echo 🔧 If errors occur, check:
echo    - PostgreSQL is running
echo    - Database has users
echo    - Backend dependencies installed
echo.
pause 