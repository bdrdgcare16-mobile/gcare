@echo off
echo 🚀 WORKING SOLUTION - STEP BY STEP
echo ===================================
echo.

echo 📂 Going to backend directory...
cd backend

echo.
echo 🔧 Step 1: Fixing TypeScript errors...
node fix_all_errors.js

echo.
echo 🗑️ Step 2: Killing any existing server...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000') do taskkill /f /pid %%a 2>nul

echo.
echo 🚀 Step 3: Starting backend server...
echo 💡 Server will start in a new window...
start "Backend Server" cmd /k "cd /d %CD% && npx ts-node --transpile-only src/index.ts"

echo.
echo ⏳ Step 4: Waiting for server to start...
timeout /t 5 /nobreak >nul

echo.
echo 📝 Step 5: Adding real tasks...
node add_simple_tasks.js

echo.
echo 📂 Step 6: Going back to main directory...
cd ..

echo.
echo 🎉 ALL DONE!
echo 💡 Now run: flutter run -d chrome
echo 💡 Login with: keshaw390@gmail.com / Employee@123
echo 💡 You will see real task names in dashboard!
echo.
pause 