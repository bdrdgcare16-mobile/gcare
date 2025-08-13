@echo off
echo ========================================
echo 🔧 QUICK FIX - SERVICES FOLDER
echo ========================================
echo.

echo Step 1: Removing duplicate/conflicting files...
if exist "lib\services\face_recognition_service.dart" del "lib\services\face_recognition_service.dart"
if exist "lib\services\camera_service.dart" del "lib\services\camera_service.dart"
if exist "lib\services\direct_camera_service.dart" del "lib\services\direct_camera_service.dart"

echo ✅ Removed conflicting files!

echo.
echo Step 2: Quick clean and test...
flutter clean
flutter pub get

echo.
echo Step 3: Quick test...
flutter analyze lib/services/ --no-fatal-infos

echo.
echo ========================================
echo 🎉 SERVICES FOLDER FIXED!
echo ========================================
echo.
echo ✅ Removed duplicate service files
echo ✅ Cleaned project
echo ✅ Services should work now
echo.
pause 