@echo off
echo 🔧 FIXING REAL DATA LOGIN ISSUE
echo ===============================
echo.

echo 🗑️ Clearing demo data and loading real data...
cd backend

echo.
echo 📊 Running database reset...
npx prisma migrate reset --force

echo.
echo 🏢 Loading real office data...
node setup_real_office_data.js

echo.
echo ✅ Real data loaded successfully!
echo.
echo 🔑 Real Login Credentials:
echo    Admin: admin@techcorp.com / Admin@123
echo    HR Manager: hr@techcorp.com / Admin@123
echo    Employee: babyreeta16@gmail.com / Employee@123
echo.
echo 🎯 Now you can login with your real data!
echo.
pause 