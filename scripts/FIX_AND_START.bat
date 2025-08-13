@echo off
echo 🔧 FIXING TYPESCRIPT ERRORS AND STARTING SERVER
echo ===============================================
echo.

echo 📂 Going to backend directory...
cd backend

echo.
echo 🔧 Fixing TypeScript errors...
powershell -Command "(Get-Content 'src/routes/leave.ts') -replace 'error\?\.message \|\| ''Internal server error''', '(error as any)?.message || ''Internal server error''' | Set-Content 'src/routes/leave.ts'"
powershell -Command "(Get-Content 'src/routes/checkin.ts') -replace 'error\?\.message \|\| ''Internal server error''', '(error as any)?.message || ''Internal server error''' | Set-Content 'src/routes/checkin.ts'"
powershell -Command "(Get-Content 'src/routes/task.ts') -replace 'error\?\.message \|\| ''Internal server error''', '(error as any)?.message || ''Internal server error''' | Set-Content 'src/routes/task.ts'"
powershell -Command "(Get-Content 'src/routes/notifications.ts') -replace 'error\?\.message \|\| ''Internal server error''', '(error as any)?.message || ''Internal server error''' | Set-Content 'src/routes/notifications.ts'"

echo.
echo ✅ TypeScript errors fixed!
echo.
echo 🚀 Starting backend server...
echo 💡 Keep this window open while testing login
echo.

npm start 
