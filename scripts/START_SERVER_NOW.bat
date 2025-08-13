@echo off
echo 🚀 STARTING BACKEND SERVER NOW
echo =============================
echo.

cd backend

echo 🔧 Starting server with transpile-only...
echo 💡 This bypasses all TypeScript errors
echo 💡 Keep this window open!
echo.

npx ts-node --transpile-only src/index.ts

pause 