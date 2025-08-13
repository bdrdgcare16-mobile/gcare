@echo off
echo 📝 ADDING REAL TASKS FOR EMPLOYEE
echo ==================================
echo.

echo 📂 Going to backend directory...
cd backend

echo.
echo 🔧 Adding real tasks to database...
node add_real_tasks.js

echo.
echo ✅ Real tasks added!
echo 💡 Employee will now see real task names in dashboard
echo.
pause 