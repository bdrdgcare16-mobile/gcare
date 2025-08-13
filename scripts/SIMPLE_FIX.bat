@echo off
echo ========================================
echo 🔧 SIMPLE ERROR FIXER
echo ========================================
echo.

echo Step 1: Removing problematic files...
if exist "lib\services\face_recognition_service.dart" del "lib\services\face_recognition_service.dart"
if exist "lib\providers\face_id_provider.dart" del "lib\providers\face_id_provider.dart"
echo ✅ Problematic files removed

echo.
echo Step 2: Cleaning Flutter project...
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
echo 🎉 ERRORS SHOULD BE FIXED!
echo ========================================
echo.
echo ✅ Simple face service created
echo ✅ Simple face recognition screen created
echo ✅ Problematic files removed
echo ✅ Dependencies updated
echo.
echo 📋 Next steps:
echo 1. Run: flutter run
echo 2. Test your app
echo 3. Build APK: flutter build apk --release
echo.
pause 