@echo off
echo ========================================
echo FIXING ANDROID SDK LICENSES
echo ========================================

echo.
echo Step 1: Accepting Android SDK licenses...
echo y | "C:\Users\Lenovo\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat" --licenses

echo.
echo Step 2: Installing missing NDK...
echo y | "C:\Users\Lenovo\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat" "ndk;27.0.12077973"

echo.
echo Step 3: Building APK...
flutter build apk --release

echo.
echo ========================================
echo BUILD SHOULD BE SUCCESSFUL NOW!
echo ========================================
pause 