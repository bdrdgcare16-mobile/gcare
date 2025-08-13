@echo off
echo 🔧 KILLING OLD SERVER AND STARTING NEW ONE
echo ==========================================
echo.

echo 📂 Going to backend directory...
cd backend

echo.
echo 🔪 Killing any process using port 3000...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :3000') do taskkill /f /pid %%a 2>nul

echo.
echo 🚀 Starting server on port 3000...
echo 💡 Keep this window open!
echo.

npx ts-node --transpile-only src/index.ts

pause 