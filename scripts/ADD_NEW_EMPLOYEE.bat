@echo off
echo 🚀 ADDING NEW EMPLOYEE TO DATABASE
echo ===================================
echo.

echo 📋 INSTRUCTIONS:
echo    1. Edit the employee details in backend/add_single_employee.js
echo    2. Run this script to add the employee
echo    3. Test login with the new employee
echo.

cd backend

echo 🔄 Adding new employee...
node add_single_employee.js

echo.
echo ✅ Employee added successfully!
echo.
echo 🎯 NEXT STEPS:
echo    1. Open your app: http://localhost:8080
echo    2. Login with the new employee credentials
echo    3. Verify all features work
echo.

pause 