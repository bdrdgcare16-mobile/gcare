@echo off
echo 🔧 RESTARTING SERVER WITH FIXED CORS
echo ====================================
echo.

echo 📂 Going to backend directory...
cd backend

echo.
echo 🔧 Starting server with fixed CORS...
echo 💡 This allows Flutter app to connect
echo 💡 Keep this window open!
echo.

npx ts-node --transpile-only src/index.ts

pause 