@echo off
echo 🔧 FIXING ALL ERRORS AND STARTING SERVER
echo =========================================
echo.

echo 📂 Going to backend directory...
cd backend

echo.
echo 🔧 Fixing TypeScript errors...
node fix_all_errors.js

echo.
echo 🚀 Starting backend server...
echo 💡 Server will run on http://localhost:3000
echo.
npx ts-node --transpile-only src/index.ts

pause 