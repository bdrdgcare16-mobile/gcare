@echo off
echo 🚀 QUICK START - REAL MOBILE APP
echo ================================
echo.

echo 📂 Step 1: Going to backend directory...
cd backend

echo.
echo 🔧 Step 2: Installing dependencies...
call npm install

echo.
echo 🗑️ Step 3: Killing any existing server on port 3000...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000') do taskkill /f /pid %%a 2>nul

echo.
echo 🚀 Step 4: Starting backend server...
start "Backend Server" cmd /k "cd /d %CD% && npx ts-node --transpile-only src/index.ts"

echo.
echo ⏳ Step 5: Waiting 5 seconds for server to start...
timeout /t 5 /nobreak >nul

echo.
echo 📂 Step 6: Going back to main directory...
cd ..

echo.
echo 🎨 Step 7: Starting mobile app...
start "Mobile App" cmd /k "flutter run -d chrome"

echo.
echo ⏳ Step 8: Waiting 3 seconds for app to load...
timeout /t 3 /nobreak >nul

echo.
echo 🎉 SYSTEM STARTED!
echo ==================
echo.
echo ✅ Backend server running on: http://localhost:3000
echo ✅ Mobile app running on: http://localhost:8080
echo.
echo 👤 LOGIN CREDENTIALS:
echo    Employee: keshaw390@gmail.com / Employee@123
echo    Admin: admin@techcorp.com / Admin@123
echo.
echo 🔧 EASY DATA MANAGEMENT (NO CURSOR COMMANDS NEEDED):
echo.
echo 📊 METHOD 1 - VISUAL DATABASE MANAGER (EASIEST):
echo    cd backend && npx prisma studio
echo    Opens at: http://localhost:5555
echo    - Add/edit employees visually
echo    - Add tasks, leave requests
echo    - NO CODING REQUIRED!
echo.
echo 📝 METHOD 2 - SIMPLE COMMANDS:
echo    cd backend && node add_new_employee.js
echo    cd backend && node add_simple_tasks.js
echo    cd backend && node view_database.js
echo.
echo 🎨 METHOD 3 - USE YOUR APP:
echo    Login as admin: admin@techcorp.com / Admin@123
echo    Use admin panel to add employees, tasks, etc.
echo.
echo 🗄️ METHOD 4 - MANUAL DATABASE:
echo    Download SQLite Browser: https://sqlitebrowser.org/
echo    Open: backend/prisma/dev.db
echo    Edit directly - no commands needed!
echo.
echo 🚀 YOUR REAL MOBILE APP IS NOW LIVE!
echo.
pause 