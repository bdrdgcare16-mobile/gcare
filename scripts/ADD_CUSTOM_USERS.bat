@echo off
echo.
echo ========================================
echo    ADD CUSTOM EMPLOYEE & ADMIN USERS
echo ========================================
echo.
echo This will add custom login credentials for:
echo.
echo 👑 ADMIN USERS:
echo    • admin@nishali.com / admin123
echo    • hr@nishali.com / hr123
echo.
echo 👥 EMPLOYEE USERS:
echo    • john.doe@nishali.com / employee123
echo    • jane.smith@nishali.com / employee123
echo    • mike.johnson@nishali.com / employee123
echo    • sarah.wilson@nishali.com / employee123
echo.
echo ========================================
echo.
pause

cd backend
node add_custom_users.js

echo.
echo ========================================
echo    USERS ADDED SUCCESSFULLY!
echo ========================================
echo.
echo 🚀 READY TO TEST LOGIN:
echo.
echo 1. Start your backend server:
echo    cd backend && npm start
echo.
echo 2. Start your Flutter app:
echo    flutter run -d chrome
echo.
echo 3. Login with any of the credentials above
echo.
echo ========================================
echo.
pause 