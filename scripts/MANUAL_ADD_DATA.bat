@echo off
echo ========================================
echo 📋 MANUAL DATA ADDITION GUIDE
echo ========================================
echo.

echo Step 1: Start Backend Server
echo -----------------------------
echo cd backend
echo npm start
echo.
echo OR double-click: START_BACKEND_ONLY.bat
echo.

echo Step 2: Add Real Data (Choose one)
echo ----------------------------------
echo.
echo Option A: Add ALL data automatically
echo Double-click: ADD_ALL_REAL_DATA.bat
echo.
echo Option B: Add your email only
echo Double-click: ADD_YOUR_EMAIL.bat
echo.
echo Option C: Manual commands
echo cd backend
echo node add_real_company_data.js
echo node add_real_employees.js
echo node add_multiple_users.js
echo node add_real_tasks.js
echo.

echo Step 3: Test Login
echo ------------------
echo Start your Flutter app: flutter run
echo Login with any email + password: 123456
echo.

echo ========================================
echo 🎯 QUICK START RECOMMENDATION:
echo ========================================
echo.
echo 1. Double-click ADD_ALL_REAL_DATA.bat
echo 2. Wait for completion
echo 3. Start app: flutter run
echo 4. Login with ANY email + 123456
echo.
pause 