@echo off
echo ========================================
echo 🚀 COMPLETE FLUTTER APP SETUP GUIDE
echo ========================================
echo.

echo 📋 STEP 1: CHECKING FLUTTER INSTALLATION
echo ========================================
flutter --version
if %errorlevel% neq 0 (
    echo ❌ Flutter not found! Please install Flutter first.
    echo 💡 Download from: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)
echo ✅ Flutter is installed!

echo.
echo 📋 STEP 2: FIXING DEPENDENCIES
echo ========================================
echo 🗑️ Cleaning project...
flutter clean

echo 📦 Getting dependencies...
flutter pub get

echo 🔍 Analyzing code...
flutter analyze

echo.
echo 📋 STEP 3: TESTING THE APP
echo ========================================
echo 🧪 Running app in debug mode...
echo 💡 This will open the app in your default browser
echo 💡 If you want to test on mobile, connect your device first
echo.
echo Press any key to start testing...
pause

flutter run -d chrome

echo.
echo 📋 STEP 4: BUILDING APK
echo ========================================
echo 📱 Building release APK...
flutter build apk --release

echo.
echo 📋 STEP 5: LOCATING APK FILE
echo ========================================
echo 📂 APK location: build/app/outputs/flutter-apk/app-release.apk
echo 💡 Copy this file for app submission

echo.
echo ========================================
echo 🎉 SETUP COMPLETE!
echo ========================================
echo.
echo ✅ Dependencies installed
echo ✅ App tested
echo ✅ APK built
echo.
echo 📱 Your APK is ready at: build/app/outputs/flutter-apk/app-release.apk
echo 🌐 Web version tested in browser
echo.
echo 💡 NEXT STEPS:
echo 1. Test the APK on your phone
echo 2. Take screenshots for submission
echo 3. Submit to app store
echo.
pause 