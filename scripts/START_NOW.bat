@echo off
echo ========================================
echo 🚀 NISHALI HRMS - START NOW!
echo ========================================
echo.

echo 📦 Setting up backend...
cd backend

echo Installing dependencies...
call npm install

echo.
echo 🗄️ Setting up database...
call npx prisma generate
call npx prisma db push
call npx prisma db seed

echo.
echo 🚀 Starting backend server...
echo.
echo ✅ Backend will be running on http://localhost:3000
echo.
echo 🔑 Login Credentials:
echo Admin: admin@nishali.com / admin123
echo Employee: john.doe@nishali.com / employee123
echo.
echo 📱 Now run in a new terminal: flutter run
echo.
echo Press any key to start the server...
pause

npm start 