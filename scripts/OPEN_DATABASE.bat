@echo off
echo 🗄️ OPENING DATABASE VISUAL INTERFACE
echo ===================================
echo.

echo 📊 Opening Prisma Studio...
echo 🌐 This will open in your browser at: http://localhost:5555
echo.
echo 💡 What you can do:
echo    ✅ View all employees
echo    ✅ Add new employees
echo    ✅ Edit existing employees
echo    ✅ Delete employees
echo    ✅ View all data tables
echo.
echo 🚀 Starting database interface...
cd backend
npx prisma studio

echo.
echo ✅ Database interface opened!
echo.
pause 