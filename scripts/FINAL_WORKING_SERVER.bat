@echo off
echo 🚀 FINAL WORKING SERVER
echo ======================
echo.

echo 📂 Going to backend directory...
cd backend

echo.
echo 🔧 Starting server...
echo 💡 This will show any errors if they occur
echo.

npx ts-node --transpile-only src/index.ts

echo.
echo ❌ Server stopped or failed to start
echo 💡 Check the error messages above
echo.
pause 