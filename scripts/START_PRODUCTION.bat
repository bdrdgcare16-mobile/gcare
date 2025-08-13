@echo off
echo 🚀 STARTING PRODUCTION FOR TOMORROW'S SALE
echo ===========================================
echo.

echo 📋 Checking prerequisites...
echo.

echo 🔧 Starting Backend Server...
cd backend
start "Backend Server" cmd /k "node start_production.js"
timeout /t 5 /nobreak >nul

echo.
echo 🌐 Starting Flutter App...
cd ..
start "Flutter App" cmd /k "flutter run -d chrome --release"
timeout /t 10 /nobreak >nul

echo.
echo ✅ Production environment started!
echo.
echo 📊 Backend: http://localhost:3000
echo 📱 Flutter: Running in Chrome
echo.
echo 🎯 Demo Credentials:
echo    Admin: admin@nishali.com / admin123
echo    Employee: nishaliselvaraj22@gmail.com / Nisha@123
echo.
echo 💡 Press any key to open the app...
pause >nul

echo 🌐 Opening Flutter app in browser...
start http://localhost:3000

echo.
echo 🎉 READY FOR DEMO!
echo.
pause 