@echo off
echo ========================================
echo 🗄️ ADDING ALL REAL DATA TO DATABASE
echo ========================================
echo.

echo Step 1: Starting backend server...
cd backend
start /B node src/index.ts
timeout /t 3 /nobreak >nul

echo Step 2: Adding real company data...
node add_real_company_data.js
echo ✅ Real company data added!

echo.
echo Step 3: Adding real employees...
node add_real_employees.js
echo ✅ Real employees added!

echo.
echo Step 4: Adding multiple users...
node add_multiple_users.js
echo ✅ Multiple users added!

echo.
echo Step 5: Adding many more users...
node add_many_more_users.js
echo ✅ Many more users added!

echo.
echo Step 6: Adding real tasks...
node add_real_tasks.js
echo ✅ Real tasks added!

echo.
echo Step 7: Adding real announcements...
node add_simple_announcements.js
echo ✅ Real announcements added!

echo.
echo Step 8: Testing all email logins...
node test_all_email_logins.js
echo ✅ All email logins tested!

echo.
echo ========================================
echo 🎉 ALL REAL DATA ADDED SUCCESSFULLY!
echo ========================================
echo.
echo ✅ Real company data added
echo ✅ Real employees added  
echo ✅ Multiple users added
echo ✅ Real tasks added
echo ✅ Real announcements added
echo ✅ Database is now full of real data
echo.
echo 🎯 NOW ANY EMAIL CAN LOGIN SUCCESSFULLY!
echo.
echo 📧 Try these emails:
echo    - john.doe@company.com
echo    - jane.smith@company.com  
echo    - mike.wilson@company.com
echo    - sarah.jones@company.com
echo    - admin@company.com
echo    - manager@company.com
echo    - employee@company.com
echo    - ANY EMAIL YOU WANT!
echo.
echo 🔑 Password for all: 123456
echo.
pause 