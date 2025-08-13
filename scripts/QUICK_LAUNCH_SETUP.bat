@echo off
echo ========================================
echo 🚀 QUICK LAUNCH SETUP FOR TOMORROW
echo ========================================
echo.

echo 📦 Setting up Backend...
cd backend
echo Installing dependencies...
npm install
echo.

echo 🗄️ Setting up Database...
npx prisma generate
npx prisma db push
npx prisma db seed
echo.

echo 🔧 Starting Backend Server...
start "Backend Server" cmd /k "npm start"
echo Backend started on http://localhost:3000
echo.

echo 📱 Setting up Flutter App...
cd ..
echo Installing Flutter dependencies...
flutter pub get
echo.

echo 🚀 Starting Flutter App...
echo Flutter app will start in a new window...
start "Flutter App" cmd /k "flutter run"
echo.

echo ========================================
echo ✅ SETUP COMPLETE!
echo ========================================
echo.
echo 📋 Test Credentials:
echo    Admin: admin@nishali.com / admin123
echo    Employee: john.doe@nishali.com / employee123
echo.
echo 🌐 Backend: http://localhost:3000
echo 📱 Flutter: Running on device/emulator
echo.
echo 🎯 Ready for tomorrow's launch!
pause 