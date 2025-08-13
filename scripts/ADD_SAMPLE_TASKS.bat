@echo off
echo 📝 ADDING SAMPLE TASKS FOR EMPLOYEE
echo ===================================
echo.

echo 📂 Going to backend directory...
cd backend

echo.
echo 🔧 Adding sample tasks to database...
node add_sample_tasks.js

echo.
echo ✅ Sample tasks added!
echo 💡 Employee can now see real tasks in dashboard
echo.
pause 