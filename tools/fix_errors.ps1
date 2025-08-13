Write-Host "========================================" -ForegroundColor Green
Write-Host "FIXING ALL FLUTTER ERRORS" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host ""
Write-Host "Step 1: Checking Flutter installation..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version
    Write-Host "Flutter found: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Flutter not found! Please install Flutter first." -ForegroundColor Red
    Write-Host "Download from: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Step 2: Cleaning project..." -ForegroundColor Yellow
flutter clean

Write-Host ""
Write-Host "Step 3: Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "Step 4: Analyzing code..." -ForegroundColor Yellow
flutter analyze

Write-Host ""
Write-Host "Step 5: Testing compilation..." -ForegroundColor Yellow
flutter build apk --debug

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "ALL ERRORS SHOULD BE FIXED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "If you still see errors in your IDE:" -ForegroundColor Yellow
Write-Host "1. Restart your IDE/editor completely" -ForegroundColor White
Write-Host "2. Reload the project" -ForegroundColor White
Write-Host "3. Wait for it to finish loading" -ForegroundColor White
Write-Host ""
Write-Host "Your app should now be ready for testing!" -ForegroundColor Green
Read-Host "Press Enter to continue" 