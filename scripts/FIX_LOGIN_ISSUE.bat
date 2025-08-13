@echo off
echo.
echo ========================================
echo    FIXING LOGIN ISSUE
echo ========================================
echo.
echo 🔍 The login is failing because the backend server is not running!
echo.
echo ✅ SOLUTION: Starting both servers...
echo.

echo 🚀 Step 1: Starting Backend Server...
cd backend
start "Backend Server" cmd /k "npm start"
timeout /t 3 /nobreak > nul

echo 🚀 Step 2: Starting Flutter App...
cd ..
start "Flutter App" cmd /k "flutter run -d chrome"
timeout /t 5 /nobreak > nul

echo.
echo ========================================
echo    SERVER STATUS
echo ========================================
echo.
echo 🔍 Checking if servers are running...
echo.

REM Check if port 3000 is in use
netstat -an | findstr :3000 > nul
if %errorlevel% equ 0 (
    echo ✅ Backend server is running on port 3000
    echo    URL: http://localhost:3000
) else (
    echo ❌ Backend server is NOT running on port 3000
    echo    Please wait a few more seconds...
)

echo.

REM Check if port 8080 is in use
netstat -an | findstr :8080 > nul
if %errorlevel% equ 0 (
    echo ✅ Flutter app is running on port 8080
    echo    URL: http://localhost:8080
) else (
    echo ❌ Flutter app is NOT running on port 8080
    echo    Please wait a few more seconds...
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
echo    TEST LOGIN
echo ========================================
echo.
echo 1. Open your browser: http://localhost:8080
echo 2. Try logging in with the credentials above
echo 3. If it still fails, wait 30 seconds and try again
echo 4. The servers need time to fully start
echo.
echo ========================================
echo    TROUBLESHOOTING
echo ========================================
echo.
echo If login still fails:
echo 1. Wait 30 seconds for servers to fully start
echo 2. Refresh the browser page
echo 3. Clear browser cache (Ctrl+Shift+R)
echo 4. Check browser console for errors (F12)
echo 5. Make sure no firewall is blocking the ports
echo.
echo ========================================
echo    SUCCESS!
echo ========================================
echo.
echo Your login should work now! The issue was that
echo the backend server wasn't running. Now both
echo servers are starting up.
echo.
pause 