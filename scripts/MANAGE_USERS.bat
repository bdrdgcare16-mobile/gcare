@echo off
echo.
echo ========================================
echo    USER MANAGEMENT SYSTEM
echo ========================================
echo.
echo Choose an option:
echo.
echo 1. Show all users in database
echo 2. Add multiple test users
echo 3. Add single user with custom password
echo 4. Add single user with random password
echo 5. Open database manager (Prisma Studio)
echo 6. Exit
echo.
set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" (
    echo.
    echo ========================================
    echo    SHOWING ALL USERS
    echo ========================================
    cd backend
    node quick_user_info.js
    cd ..
    pause
    goto :eof
)

if "%choice%"=="2" (
    echo.
    echo ========================================
    echo    ADDING MULTIPLE TEST USERS
    echo ========================================
    cd backend
    node add_multiple_users.js
    cd ..
    pause
    goto :eof
)

if "%choice%"=="3" (
    echo.
    echo ========================================
    echo    ADD USER WITH CUSTOM PASSWORD
    echo ========================================
    cd backend
    node add_employee_with_custom_password.js
    cd ..
    pause
    goto :eof
)

if "%choice%"=="4" (
    echo.
    echo ========================================
    echo    ADD USER WITH RANDOM PASSWORD
    echo ========================================
    cd backend
    node add_employee_with_random_password.js
    cd ..
    pause
    goto :eof
)

if "%choice%"=="5" (
    echo.
    echo ========================================
    echo    OPENING DATABASE MANAGER
    echo ========================================
    echo Opening Prisma Studio at http://localhost:5555
    echo Press Ctrl+C to stop the database manager
    echo.
    cd backend
    npx prisma studio
    cd ..
    goto :eof
)

if "%choice%"=="6" (
    echo.
    echo Goodbye!
    goto :eof
)

echo Invalid choice. Please try again.
pause 