@echo off
echo.
echo ========================================
echo    CHECKING SERVER STATUS
echo ========================================
echo.
echo 🔍 Checking if backend server is running...
echo.

REM Check if port 3000 is in use
netstat -an | findstr :3000 > nul
if %errorlevel% equ 0 (
    echo ✅ Backend server is running on port 3000
    echo    URL: http://localhost:3000
) else (
    echo ❌ Backend server is NOT running on port 3000
    echo.
    echo 🔧 To start the backend server:
    echo    1. Open a new terminal
    echo    2. cd backend
    echo    3. npm start
    echo.
)

echo.
echo 🔍 Checking if Flutter app is running...
echo.

REM Check if port 8080 is in use
netstat -an | findstr :8080 > nul
if %errorlevel% equ 0 (
    echo ✅ Flutter app is running on port 8080
    echo    URL: http://localhost:8080
) else (
    echo ❌ Flutter app is NOT running on port 8080
    echo.
    echo 🔧 To start the Flutter app:
    echo    1. Open a new terminal
    echo    2. flutter run -d chrome
    echo.
)

echo.
echo ========================================
echo    LOGIN CREDENTIALS
echo ========================================
echo.
echo Employee: keshaw390@gmail.com / Employee@123
echo Admin: admin@techcorp.com / Admin@123
echo.
echo ========================================
echo    QUICK FIX
echo ========================================
echo.
echo If login is still failing:
echo 1. Make sure both servers are running
echo 2. Try refreshing the browser
echo 3. Clear browser cache
echo 4. Check browser console for errors
echo.
pause 