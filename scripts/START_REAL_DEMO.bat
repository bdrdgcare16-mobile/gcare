@echo off
echo 🚀 STARTING REAL DATA DEMO
echo ================================

echo.
echo 📋 Starting Backend Server...
start cmd /k "cd backend && npm start"

echo.
echo ⏳ Waiting for backend to start...
timeout /t 5 /nobreak >nul

echo.
echo 📱 Starting Flutter App...
start cmd /k "flutter run -d chrome"

echo.
echo ✅ DEMO READY!
echo ================================
echo.
echo 🎯 Demo Credentials:
echo    Your Email: nishalimrtech22@gmail.com
echo    Password: Nishali@123
echo.
echo 🔧 For Registration Demo:
echo    Use any new email/password
echo    Registration → Login will work!
echo.
echo 📖 Read REAL_DATA_SOLUTION.md for details
echo.
pause 