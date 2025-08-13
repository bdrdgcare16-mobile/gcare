@echo off
echo 🏢 REAL OFFICE LAUNCH - WORKFLOW SYSTEM
echo =======================================
echo.
echo 🚀 Setting up TechCorp HRMS with Real Office Workflows
echo.

echo 📋 Step 1: Database Migration...
cd backend
npx prisma migrate reset --force
timeout /t 3 /nobreak >nul

echo.
echo 🏢 Step 2: Setting up Real Office Data...
node setup_real_office.js
timeout /t 5 /nobreak >nul

echo.
echo 🔧 Step 3: Starting Production Backend...
start "Real Office Backend" cmd /k "node start_production.js"
timeout /t 5 /nobreak >nul

echo.
echo 🌐 Step 4: Starting Flutter Production App...
cd ..
start "Flutter Production" cmd /k "flutter run -d chrome --release"
timeout /t 10 /nobreak >nul

echo.
echo ✅ REAL OFFICE ENVIRONMENT READY!
echo.
echo 🏢 TechCorp HRMS - Real Office Workflows
echo =======================================
echo.
echo 📊 Backend: http://localhost:3000
echo 📱 Flutter: Running in Chrome (Production Mode)
echo.
echo 👥 Professional Team Setup:
echo    CEO: admin@techcorp.com / Admin@2024!
echo    HR Manager: hr@techcorp.com / Admin@2024!
echo    IT Manager: it.manager@techcorp.com / Admin@2024!
echo    Employee: alex.martinez@techcorp.com / Employee@2024!
echo.
echo 🔄 WORKFLOW FEATURES:
echo    ✅ Employee Check-in Requests → Admin Approval
echo    ✅ Admin Task Assignment → Employee Task List
echo    ✅ Employee Leave Requests → Admin Approval
echo    ✅ Real-time Notifications
echo    ✅ Attendance Tracking with Approval
echo    ✅ Professional Company Data
echo.
echo 💼 Departments: Executive, HR, IT, Engineering, Design, Product, Marketing, Analytics
echo.
echo 📈 Real Office Features:
echo    ✅ 3 Admin/Management users
echo    ✅ 6 Professional employees
echo    ✅ 7 Leave types
echo    ✅ 4 Company announcements
echo    ✅ 6 Tasks (assigned by admins)
echo    ✅ 3 Check-in requests (pending approval)
echo    ✅ 4 Leave requests (pending approval)
echo    ✅ 15+ Notifications
echo    ✅ 30 days of attendance records
echo    ✅ 6 Payroll records
echo.
echo 🎯 DEMO WORKFLOW:
echo    1. Employee submits check-in request
echo    2. Admin approves/rejects request
echo    3. Admin assigns task to employee
echo    4. Employee updates task status
echo    5. Employee submits leave request
echo    6. Admin approves/rejects leave
echo    7. Real-time notifications throughout
echo.
echo 🎉 READY FOR REAL OFFICE DEMO!
echo.
pause 