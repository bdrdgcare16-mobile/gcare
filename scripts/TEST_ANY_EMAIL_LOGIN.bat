@echo off
echo.
echo ========================================
echo    TEST ANY EMAIL LOGIN
echo ========================================
echo.
echo 🎯 ALL EMAILS IN DATABASE (23 TOTAL):
echo.

echo 👑 ADMIN USERS (3):
echo 1. admin@techcorp.com
echo 2. vivek.saxena@company.com  
echo 3. shweta.agarwal@company.com
echo.

echo 👥 EMPLOYEE USERS (20):
echo 4. keshaw390@gmail.com
echo 5. suryap1209@gmail.com
echo 6. priya.sharma@company.com
echo 7. rahul.singh@company.com
echo 8. amit.patel@company.com
echo 9. neha.gupta@company.com
echo 10. rajesh.kumar@company.com
echo 11. anjali.singh@company.com
echo 12. vikram.malhotra@company.com
echo 13. pooja.sharma@company.com
echo 14. arun.verma@company.com
echo 15. meera.kapoor@company.com
echo 16. sandeep.reddy@company.com
echo 17. kavita.joshi@company.com
echo 18. rohit.mehta@company.com
echo 19. sunita.iyer@company.com
echo 20. manoj.tiwari@company.com
echo 21. deepika.nair@company.com
echo 22. aditya.chopra@company.com
echo 23. rashmi.desai@company.com
echo.

echo ========================================
echo    LOGIN TEST INSTRUCTIONS
echo ========================================
echo.
echo 🔐 PASSWORDS:
echo    • All Employees: Employee@123
echo    • All Admins: Admin@123
echo.
echo 🎯 QUICK TEST:
echo    1. Open: http://localhost:8080
echo    2. Try ANY email from the list above
echo    3. Use correct password for role
echo    4. Login successfully!
echo.
echo 💡 RECOMMENDED TEST:
echo    Email: suryap1209@gmail.com
echo    Password: Employee@123
echo.
echo ========================================
echo    STATUS CHECK
echo ========================================
echo.
echo 🔍 Checking server status...

netstat -an | findstr :3000 > nul
if %errorlevel% equ 0 (
    echo ✅ Backend server is running (port 3000)
) else (
    echo ❌ Backend server is NOT running
    echo    Starting backend server...
    cd backend
    start "Backend" cmd /k "npm start"
    timeout /t 5 /nobreak > nul
)

netstat -an | findstr :8080 > nul
if %errorlevel% equ 0 (
    echo ✅ Flutter app is running (port 8080)
) else (
    echo ❌ Flutter app is NOT running
    echo    Starting Flutter app...
    cd ..
    start "Flutter" cmd /k "flutter run -d chrome"
    timeout /t 5 /nobreak > nul
)

echo.
echo ========================================
echo    READY TO TEST!
echo ========================================
echo.
echo 🎉 You can login with ANY of the 23 emails above!
echo    Just use the correct password for each role.
echo.
pause 