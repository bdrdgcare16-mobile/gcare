@echo off
echo 🚀 FINAL LAUNCH SETUP - REAL MOBILE APP
echo =======================================
echo.
echo 📅 LAUNCH DAY: TODAY
echo 🎯 Setting up complete HRMS system with real data...
echo.

echo 📂 Step 1: Setting up backend directory...
cd backend

echo.
echo 🔧 Step 2: Installing all dependencies...
call npm install

echo.
echo 🗄️ Step 3: Setting up database with REAL office data...
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
echo ⏳ Step 7: Waiting 8 seconds for server to start...
timeout /t 8 /nobreak >nul

echo.
echo 📝 Step 8: Adding real tasks for employee...
node add_simple_tasks.js

echo.
echo 📂 Step 9: Going back to main directory...
cd ..

echo.
echo 🎨 Step 10: Setting up Flutter app...
call flutter clean
call flutter pub get

echo.
echo 🚀 Step 11: Starting mobile app...
start "Mobile App" cmd /k "flutter run -d chrome"

echo.
echo ⏳ Step 12: Waiting 5 seconds for app to load...
timeout /t 5 /nobreak >nul

echo.
echo 🎉 LAUNCH COMPLETE!
echo ===================
echo.
echo ✅ Backend server running on: http://localhost:3000
echo ✅ Mobile app running on: http://localhost:8080
echo.
echo 👤 LOGIN CREDENTIALS:
echo    Employee: keshaw390@gmail.com / Employee@123
echo    Admin: admin@techcorp.com / Admin@123
echo.
echo 🎯 COMPLETE TEST CHECKLIST:
echo    ☐ Employee login works
echo    ☐ Camera check-in works
echo    ☐ Tasks are visible and functional
echo    ☐ Leave requests work
echo    ☐ Admin panel accessible
echo    ☐ Real-time updates working
echo    ☐ Attendance tracking works
echo    ☐ Payroll information visible
echo    ☐ Notifications working
echo.
echo 🔧 FUTURE DATA MANAGEMENT:
echo    - Visual Database: cd backend && npx prisma studio
echo    - Add employees: cd backend && node add_new_employee.js
echo    - Add tasks: cd backend && node add_simple_tasks.js
echo    - View data: cd backend && node view_database.js
echo.
echo 🚨 TROUBLESHOOTING:
echo    - If backend issues: cd backend && npx prisma migrate reset
echo    - If app issues: flutter clean && flutter pub get
echo    - Emergency reset: Run this script again
echo.
echo 🎉 YOUR REAL MOBILE APP IS NOW LIVE!
echo 🚀 READY FOR LAUNCH DAY!
echo.
pause 