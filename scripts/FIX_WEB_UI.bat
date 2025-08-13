@echo off
echo ========================================
echo FIXING WEB UI DISPLAY ISSUE
echo ========================================

echo.
echo Starting Flutter web server...
echo Your app will open in browser automatically
echo.
flutter run -d chrome --web-port 8080

echo.
echo If browser doesn't open automatically:
echo 1. Open Chrome
echo 2. Go to: http://localhost:8080
echo.
pause 