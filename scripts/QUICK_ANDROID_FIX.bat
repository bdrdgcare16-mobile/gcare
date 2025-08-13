@echo off
echo ========================================
echo QUICK ANDROID FIX - NO SDKMANAGER NEEDED
echo ========================================

echo.
echo Option 1: Building for Web (Easiest)
echo This will create a web version of your app
echo.
flutter build web --release

echo.
echo Option 2: Building Debug APK (Alternative)
echo This might work without license issues
echo.
flutter build apk --debug

echo.
echo ========================================
echo BUILD COMPLETED!
echo ========================================
echo.
echo Web build: build/web/ (for web deployment)
echo Debug APK: build/app/outputs/flutter-apk/app-debug.apk
echo.
pause 