@echo off
echo 🚀 QUICK FIX - STARTING BACKEND SERVER
echo ======================================
echo.

echo 🔧 Fixing TypeScript errors...
cd backend

echo 📝 Updating error handling in route files...
powershell -Command "(Get-Content 'src/routes/leave.ts') -replace 'error\?\.message', 'String(error?.message || \"Internal server error\")' | Set-Content 'src/routes/leave.ts'"
powershell -Command "(Get-Content 'src/routes/checkin.ts') -replace 'error\?\.message', 'String(error?.message || \"Internal server error\")' | Set-Content 'src/routes/checkin.ts'"
powershell -Command "(Get-Content 'src/routes/task.ts') -replace 'error\?\.message', 'String(error?.message || \"Internal server error\")' | Set-Content 'src/routes/task.ts'"
powershell -Command "(Get-Content 'src/routes/notifications.ts') -replace 'error\?\.message', 'String(error?.message || \"Internal server error\")' | Set-Content 'src/routes/notifications.ts'"

echo.
echo 🚀 Starting backend server...
echo 💡 Keep this window open while testing login
echo.

npm start 