@echo off
echo 🗄️ VIEW DATABASE CONTENTS
echo =======================
echo.
echo 📋 Choose what you want to view:
echo.
echo 1. View All Users (Employees & Admins)
echo 2. View All Employees Only
echo 3. View All Admins Only
echo 4. View All Tasks
echo 5. View All Leave Requests
echo 6. View All Announcements
echo 7. View All Attendance Records
echo 8. View All Payroll Records
echo 9. View Database Summary
echo 10. Exit
echo.
set /p choice="Enter your choice (1-10): "

if "%choice%"=="1" (
    echo.
    echo 👥 Viewing All Users...
    cd backend
    node view_database.js users
    cd ..
    pause
    goto :eof
)

if "%choice%"=="2" (
    echo.
    echo 👤 Viewing All Employees...
    cd backend
    node view_database.js employees
    cd ..
    pause
    goto :eof
)

if "%choice%"=="3" (
    echo.
    echo 👨‍💼 Viewing All Admins...
    cd backend
    node view_database.js admins
    cd ..
    pause
    goto :eof
)

if "%choice%"=="4" (
    echo.
    echo 📋 Viewing All Tasks...
    cd backend
    node view_database.js tasks
    cd ..
    pause
    goto :eof
)

if "%choice%"=="5" (
    echo.
    echo 🏖️ Viewing All Leave Requests...
    cd backend
    node view_database.js leaves
    cd ..
    pause
    goto :eof
)

if "%choice%"=="6" (
    echo.
    echo 📢 Viewing All Announcements...
    cd backend
    node view_database.js announcements
    cd ..
    pause
    goto :eof
)

if "%choice%"=="7" (
    echo.
    echo ⏰ Viewing All Attendance Records...
    cd backend
    node view_database.js attendance
    cd ..
    pause
    goto :eof
)

if "%choice%"=="8" (
    echo.
    echo 💰 Viewing All Payroll Records...
    cd backend
    node view_database.js payroll
    cd ..
    pause
    goto :eof
)

if "%choice%"=="9" (
    echo.
    echo 📊 Viewing Database Summary...
    cd backend
    node view_database.js summary
    cd ..
    pause
    goto :eof
)

if "%choice%"=="10" (
    echo.
    echo 👋 Exiting...
    goto :eof
)

echo.
echo ❌ Invalid choice! Please enter a number between 1-10.
pause 