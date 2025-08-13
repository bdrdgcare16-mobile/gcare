@echo off
echo 🚀 WORKING LOGIN FIX
echo ===================
echo.

echo 📂 Going to backend directory...
cd backend

echo.
echo 🔧 Starting server directly...
echo 💡 This will start the backend server
echo 💡 Keep this window open while testing login
echo.

npx ts-node --transpile-only src/index.ts

echo.
echo ❌ Server stopped - you can close this window
pause 