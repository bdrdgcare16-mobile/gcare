@echo off
echo 🚀 STARTING REAL APP
echo ====================
echo.

echo 🔧 Starting backend server...
start "Backend Server" cmd /k "cd backend && npm start"

echo.
echo ⏳ Waiting 5 seconds for backend to start...
timeout /t 5 /nobreak >nul

echo.
echo 🌐 Starting Flutter app...
flutter run -d chrome

echo.
echo ✅ Real app is starting!
echo 💡 Backend server is running in separate window
echo 💡 Keep both windows open while using the app
echo.
pause 