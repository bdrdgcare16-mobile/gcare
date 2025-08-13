@echo off
echo ========================================
echo FIXING FLUTTER DEPENDENCIES
echo ========================================

echo.
echo 1. Checking Flutter installation...
flutter --version

echo.
echo 2. Cleaning project...
flutter clean

echo.
echo 3. Getting dependencies...
flutter pub get

echo.
echo 4. Checking for errors...
flutter analyze

echo.
echo ========================================
echo DEPENDENCIES FIXED!
echo ========================================
echo.
echo If you still see errors, try:
echo 1. Restart your IDE/editor
echo 2. Run: flutter doctor
echo 3. Check internet connection
echo.
pause 