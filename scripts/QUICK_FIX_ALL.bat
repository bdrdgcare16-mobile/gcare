@echo off
echo 🚀 QUICK FIX ALL - COMPLETE SOLUTION
echo =====================================
echo.

echo 📂 Going to backend directory...
cd backend

echo.
echo 🔧 Fixing TypeScript errors...
node fix_all_errors.js

echo.
echo 🗑️ Killing any existing server on port 3000...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000') do taskkill /f /pid %%a 2>nul

echo.
echo 🚀 Starting backend server...
start "Backend Server" cmd /k "cd /d %CD% && npx ts-node --transpile-only src/index.ts"

echo.
echo ⏳ Waiting 3 seconds for server to start...
timeout /t 3 /nobreak >nul

echo.
echo 📝 Adding real tasks to database...
node add_simple_tasks.js

echo.
echo 📂 Going back to main directory...
cd ..

echo.
echo 🎉 All fixes applied!
echo 💡 Now run: flutter run -d chrome
echo 💡 Login with: keshaw390@gmail.com / Employee@123
echo.
pause 