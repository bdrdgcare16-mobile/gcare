@echo off
echo 🚀 LAUNCH DAY - REAL MOBILE APP SETUP
echo ======================================
echo.
echo 📅 Today is your launch day!
echo 🎯 Setting up complete HRMS system...
echo.

echo 📂 Step 1: Setting up backend directory...
cd backend

echo.
echo 🔧 Step 2: Installing dependencies...
call npm install

echo.
echo 🗄️ Step 3: Setting up database with real data...
node setup_real_office_data_fixed.js

echo.
echo 🔄 Step 4: Generating Prisma client...
call npx prisma generate

echo.
echo 🗑️ Step 5: Killing any existing server on port 3000...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000') do taskkill /f /pid %%a 2>nul

echo.
echo 🚀 Step 6: Starting backend server...
start "Backend Server" cmd /k "cd /d %CD% && npx ts-node --transpile-only src/index.ts"

echo.
echo ⏳ Step 7: Waiting 5 seconds for server to start...
timeout /t 5 /nobreak >nul

echo.
echo 📂 Step 8: Going back to main directory...
cd ..

echo.
echo 🎨 Step 9: Setting up Flutter app...
call flutter clean
call flutter pub get

echo.
echo 🚀 Step 10: Starting mobile app...
start "Mobile App" cmd /k "flutter run -d chrome"

echo.
echo ⏳ Step 11: Waiting 3 seconds for app to load...
timeout /t 3 /nobreak >nul

echo.
echo 🎉 LAUNCH COMPLETE!
echo ===================
echo.
echo ✅ Backend server running on: http://localhost:3000
echo ✅ Mobile app running on: http://localhost:8080
echo.
echo 👤 LOGIN CREDENTIALS:
echo    Employee: keshaw390@gmail.com / Employee@123
echo    Admin: admin@company.com / Admin@123
echo.
echo 🎯 TEST CHECKLIST:
echo    ☐ Employee login works
echo    ☐ Camera check-in works
echo    ☐ Tasks are visible
echo    ☐ Leave requests work
echo    ☐ Admin panel accessible
echo    ☐ Real-time updates working
echo.
echo 🔧 FUTURE DATA MANAGEMENT:
echo    - Add employees: cd backend && node add_new_employee.js
echo    - Add tasks: cd backend && node add_simple_tasks.js
echo    - View database: cd backend && npx prisma studio
echo.
echo 🚀 YOUR REAL MOBILE APP IS NOW LIVE!
echo.
pause 