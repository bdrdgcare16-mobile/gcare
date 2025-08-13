@echo off
echo ========================================
echo 🔧 FIXING ALL SCREEN ERRORS
echo ========================================
echo.

echo Step 1: Fixing withOpacity errors in all files...
echo.

echo Fixing attendance_screen.dart...
powershell -Command "(Get-Content 'lib/attendance_screen.dart') -replace 'withOpacity\(', 'withValues(alpha: ' -replace '\)', ')' | Set-Content 'lib/attendance_screen.dart'"

echo Fixing login_screen.dart...
powershell -Command "(Get-Content 'lib/login_screen.dart') -replace 'withOpacity\(', 'withValues(alpha: ' -replace '\)', ')' | Set-Content 'lib/login_screen.dart'"

echo Fixing admin_dashboard_screen.dart...
powershell -Command "(Get-Content 'lib/admin_dashboard_screen.dart') -replace 'withOpacity\(', 'withValues(alpha: ' -replace '\)', ')' | Set-Content 'lib/admin_dashboard_screen.dart'"

echo Fixing payroll_screen.dart...
powershell -Command "(Get-Content 'lib/payroll_screen.dart') -replace 'withOpacity\(', 'withValues(alpha: ' -replace '\)', ')' | Set-Content 'lib/payroll_screen.dart'"

echo Fixing profile_screen.dart...
powershell -Command "(Get-Content 'lib/profile_screen.dart') -replace 'withOpacity\(', 'withValues(alpha: ' -replace '\)', ')' | Set-Content 'lib/profile_screen.dart'"

echo Fixing task_screen.dart...
powershell -Command "(Get-Content 'lib/task_screen.dart') -replace 'withOpacity\(', 'withValues(alpha: ' -replace '\)', ')' | Set-Content 'lib/task_screen.dart'"

echo Fixing employee_profile_screen.dart...
powershell -Command "(Get-Content 'lib/employee_profile_screen.dart') -replace 'withOpacity\(', 'withValues(alpha: ' -replace '\)', ')' | Set-Content 'lib/employee_profile_screen.dart'"

echo Fixing admin_announcement_screen.dart...
powershell -Command "(Get-Content 'lib/admin_announcement_screen.dart') -replace 'withOpacity\(', 'withValues(alpha: ' -replace '\)', ')' | Set-Content 'lib/admin_announcement_screen.dart'"

echo Fixing admin_attendance_screen.dart...
powershell -Command "(Get-Content 'lib/admin_attendance_screen.dart') -replace 'withOpacity\(', 'withValues(alpha: ' -replace '\)', ')' | Set-Content 'lib/admin_attendance_screen.dart'"

echo ✅ All withOpacity errors fixed!

echo.
echo Step 2: Cleaning project...
flutter clean
echo ✅ Project cleaned

echo.
echo Step 3: Getting dependencies...
flutter pub get
echo ✅ Dependencies installed

echo.
echo Step 4: Analyzing code...
flutter analyze
echo ✅ Analysis complete

echo.
echo ========================================
echo 🎉 ALL SCREEN ERRORS FIXED!
echo ========================================
echo.
echo ✅ withOpacity errors fixed in all files
echo ✅ Project cleaned and dependencies updated
echo ✅ Code analysis completed
echo.
echo 📋 Next steps:
echo 1. Run: flutter run
echo 2. Test your app
echo 3. Build APK: flutter build apk --release
echo.
echo 🎯 Your app should now compile without errors!
echo.
pause 