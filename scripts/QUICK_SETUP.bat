@echo off
echo ========================================
echo 🚀 NISHALI HRMS - QUICK SETUP
echo ========================================
echo.

echo 📦 Installing backend dependencies...
cd backend
call npm install
if %errorlevel% neq 0 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo 🗄️ Setting up database...
call npx prisma generate
if %errorlevel% neq 0 (
    echo ❌ Failed to generate Prisma client
    pause
    exit /b 1
)

call npx prisma db push
if %errorlevel% neq 0 (
    echo ❌ Failed to push database schema
    pause
    exit /b 1
)

echo.
echo 🌱 Seeding database with real data...
call npm run seed
if %errorlevel% neq 0 (
    echo ❌ Failed to seed database
    pause
    exit /b 1
)

echo.
echo 🚀 Starting backend server...
echo.
echo ✅ Backend is running on http://localhost:3000
echo.
echo 🔑 Login Credentials:
echo Admin: admin@nishali.com / admin123
echo Employee: john.doe@nishali.com / employee123
echo.
echo 📱 Now run: flutter run
echo.
pause 