@echo off
echo 🚀 Starting PostgreSQL Migration for Nishali HRMS...
echo.

echo 📋 Step 1: Installing PostgreSQL dependencies...
cd backend
call npm install pg @types/pg
if %errorlevel% neq 0 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)
echo ✅ Dependencies installed successfully

echo.
echo 📋 Step 2: Setting up PostgreSQL database...
echo Please ensure PostgreSQL is running with:
echo   - Host: localhost
echo   - Port: 5432
echo   - Database: SERV
echo   - Username: postgres
echo   - Password: Nishali
echo.

echo 📋 Step 3: Running PostgreSQL setup...
call node scripts/setup-postgresql.js
if %errorlevel% neq 0 (
    echo ❌ PostgreSQL setup failed
    pause
    exit /b 1
)

echo.
echo 📋 Step 4: Migrating data from SQLite to PostgreSQL...
call npm run migrate:data
if %errorlevel% neq 0 (
    echo ❌ Data migration failed
    pause
    exit /b 1
)

echo.
echo 📋 Step 5: Testing PostgreSQL connection...
call node scripts/test-postgresql.js
if %errorlevel% neq 0 (
    echo ❌ PostgreSQL test failed
    pause
    exit /b 1
)

echo.
echo 🎉 Migration completed successfully!
echo.
echo 📊 Next steps:
echo   1. Start the server: npm run dev
echo   2. Open Prisma Studio: npm run db:studio
echo   3. Test all application features
echo.
echo 🐘 Your application is now running on PostgreSQL!
pause 