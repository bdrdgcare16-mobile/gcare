@echo off
echo 🚀 ADD NEW DATA TO DATABASE
echo ===========================
echo.
echo 📋 Choose what you want to add:
echo.
echo 1. Add Single Employee
echo 2. Add Multiple Employees
echo 3. Add New Admin
echo 4. Add New Announcements
echo 5. Add New Tasks
echo 6. Add All New Data
echo 7. Exit
echo.
set /p choice="Enter your choice (1-7): "

if "%choice%"=="1" (
    echo.
    echo 👤 Adding Single Employee...
    cd backend
    node add_new_employee.js employee
    cd ..
    echo.
    echo ✅ Employee added successfully!
    pause
    goto :eof
)

if "%choice%"=="2" (
    echo.
    echo 👥 Adding Multiple Employees...
    cd backend
    node add_new_employee.js employees
    cd ..
    echo.
    echo ✅ Multiple employees added successfully!
    pause
    goto :eof
)

if "%choice%"=="3" (
    echo.
    echo 👨‍💼 Adding New Admin...
    cd backend
    node add_new_employee.js admin
    cd ..
    echo.
    echo ✅ Admin added successfully!
    pause
    goto :eof
)

if "%choice%"=="4" (
    echo.
    echo 📢 Adding New Announcements...
    cd backend
    node add_new_employee.js announcements
    cd ..
    echo.
    echo ✅ Announcements added successfully!
    pause
    goto :eof
)

if "%choice%"=="5" (
    echo.
    echo 📋 Adding New Tasks...
    cd backend
    node add_new_employee.js tasks
    cd ..
    echo.
    echo ✅ Tasks added successfully!
    pause
    goto :eof
)

if "%choice%"=="6" (
    echo.
    echo 🚀 Adding All New Data...
    cd backend
    node add_new_employee.js all
    cd ..
    echo.
    echo ✅ All new data added successfully!
    pause
    goto :eof
)

if "%choice%"=="7" (
    echo.
    echo 👋 Exiting...
    goto :eof
)

echo.
echo ❌ Invalid choice! Please enter a number between 1-7.
pause 