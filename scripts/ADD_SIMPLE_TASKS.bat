@echo off
echo 📝 ADDING SIMPLE TASKS FOR EMPLOYEE
echo ====================================
echo.

echo 📂 Going to backend directory...
cd backend

echo.
echo 🔧 Adding simple tasks to database...
node add_simple_tasks.js

echo.
echo ✅ Simple tasks added!
echo 💡 Employee will now see real task names in dashboard
echo.
pause 