@echo off
echo ========================================
echo BUILDING APP FOR SUBMISSION
echo ========================================

echo.
echo 1. Cleaning project...
flutter clean

echo.
echo 2. Getting dependencies...
flutter pub get

echo.
echo 3. Analyzing code...
flutter analyze

echo.
echo 4. Building Android APK...
flutter build apk --release

echo.
echo 5. Building Android App Bundle (for Play Store)...
flutter build appbundle --release

echo.
echo ========================================
echo BUILD COMPLETE!
echo ========================================
echo.
echo APK location: build/app/outputs/flutter-apk/app-release.apk
echo App Bundle location: build/app/outputs/bundle/release/app-release.aab
echo.
echo Ready for submission!
pause 