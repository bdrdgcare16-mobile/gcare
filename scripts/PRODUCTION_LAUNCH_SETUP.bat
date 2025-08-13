@echo off
echo 🚀 PRODUCTION LAUNCH - REAL COMPANY SALE
echo =========================================
echo.
echo 🏢 Setting up TechCorp HRMS for Professional Demo
echo.

echo 📋 Step 1: Setting up Real Company Data...
cd backend
node add_real_company_data.js
timeout /t 3 /nobreak >nul

echo.
echo 🔧 Step 2: Starting Production Backend...
start "Production Backend" cmd /k "node start_production.js"
timeout /t 5 /nobreak >nul

echo.
echo 🌐 Step 3: Starting Flutter Production App...
cd ..
start "Flutter Production" cmd /k "flutter run -d chrome --release"
timeout /t 10 /nobreak >nul

echo.
echo ✅ PRODUCTION ENVIRONMENT READY!
echo.
echo 🏢 TechCorp HRMS - Professional Demo
echo ====================================
echo.
echo 📊 Backend: http://localhost:3000
echo 📱 Flutter: Running in Chrome (Production Mode)
echo.
echo 👥 Professional Team Setup:
echo    CEO: admin@techcorp.com / Admin@2024!
echo    HR: hr@techcorp.com / HR@2024!
echo    IT Manager: it.manager@techcorp.com / Manager@2024!
echo    Employee: alex.martinez@techcorp.com / Employee@2024!
echo.
echo 💼 Departments: Executive, HR, IT, Engineering, Design, Product, Marketing, Analytics
echo.
echo 📈 Features Available:
echo    ✅ Real Employee Profiles
echo    ✅ Professional Attendance Tracking
echo    ✅ Leave Management System
echo    ✅ Payroll Processing
echo    ✅ Task Management
echo    ✅ Company Announcements
echo    ✅ Face Recognition (Mobile)
echo    ✅ Real-time Reports
echo.
echo 🎯 DEMO READY FOR COMPANY SALE!
echo.
pause 