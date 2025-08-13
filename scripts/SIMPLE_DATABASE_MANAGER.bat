@echo off
echo 🗄️ SIMPLE DATABASE MANAGER
echo =========================
echo.

echo 📊 Choose an option:
echo.
echo 1. View all employees
echo 2. Add new employee
echo 3. View database status
echo 4. Backup database
echo 5. Exit
echo.

set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" goto view_employees
if "%choice%"=="2" goto add_employee
if "%choice%"=="3" goto view_status
if "%choice%"=="4" goto backup_db
if "%choice%"=="5" goto exit

:view_employees
echo.
echo 👥 Loading employee list...
cd backend
node view_employees.js
echo.
pause
goto menu

:add_employee
echo.
echo 👤 Adding new employee...
echo 📋 Please edit backend/add_single_employee.js first
echo 💡 Change the employee details in the file
echo.
cd backend
node add_single_employee.js
echo.
pause
goto menu

:view_status
echo.
echo 📊 Loading database status...
cd backend
node view_database.js
echo.
pause
goto menu

:backup_db
echo.
echo 💾 Creating database backup...
cd backend
copy prisma\dev.db prisma\backup_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.db
echo ✅ Backup created successfully!
echo.
pause
goto menu

:menu
cls
echo 🗄️ SIMPLE DATABASE MANAGER
echo =========================
echo.
echo 📊 Choose an option:
echo.
echo 1. View all employees
echo 2. Add new employee
echo 3. View database status
echo 4. Backup database
echo 5. Exit
echo.

set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" goto view_employees
if "%choice%"=="2" goto add_employee
if "%choice%"=="3" goto view_status
if "%choice%"=="4" goto backup_db
if "%choice%"=="5" goto exit

:exit
echo.
echo 👋 Goodbye!
pause 