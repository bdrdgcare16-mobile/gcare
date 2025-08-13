@echo off
echo 🎉 ADDING SAMPLE ANNOUNCEMENTS TO DATABASE
echo ===========================================
echo.

echo 📋 This will add sample announcements that will appear
echo    on both admin and employee dashboards
echo.

cd backend

echo 🔄 Adding sample announcements...
node add_sample_announcements.js

echo.
echo ✅ Sample announcements added successfully!
echo.
echo 🎯 NEXT STEPS:
echo    1. Start your app: flutter run -d chrome
echo    2. Login as admin: admin@techcorp.com / Admin@123
echo    3. Go to Announcements section to see the announcements
echo    4. Login as employee: suryap1209@gmail.com / Employee@123
echo    5. See announcements on employee dashboard
echo.
pause 