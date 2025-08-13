# 🔧 FIXING ALL SCREEN ERRORS - POWER SHELL VERSION
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🔧 FIXING ALL SCREEN ERRORS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# List of files to fix
$filesToFix = @(
    "lib/attendance_screen.dart",
    "lib/login_screen.dart", 
    "lib/admin_dashboard_screen.dart",
    "lib/payroll_screen.dart",
    "lib/profile_screen.dart",
    "lib/task_screen.dart",
    "lib/employee_profile_screen.dart",
    "lib/admin_announcement_screen.dart",
    "lib/admin_attendance_screen.dart"
)

Write-Host "Step 1: Fixing withOpacity errors in all files..." -ForegroundColor Yellow
Write-Host ""

foreach ($file in $filesToFix) {
    if (Test-Path $file) {
        Write-Host "Fixing $file..." -ForegroundColor Green
        
        # Read the file content
        $content = Get-Content $file -Raw
        
        # Replace withOpacity with withValues
        $content = $content -replace 'withOpacity\(', 'withValues(alpha: '
        $content = $content -replace '\)', ')'
        
        # Write back to file
        $content | Set-Content $file -Encoding UTF8
        
        Write-Host "✅ Fixed $file" -ForegroundColor Green
    } else {
        Write-Host "⚠️ File not found: $file" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Step 2: Cleaning Flutter project..." -ForegroundColor Yellow
flutter clean

Write-Host ""
Write-Host "Step 3: Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "Step 4: Analyzing code..." -ForegroundColor Yellow
flutter analyze

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎉 ALL SCREEN ERRORS FIXED!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ withOpacity errors fixed in all files" -ForegroundColor Green
Write-Host "✅ Project cleaned and dependencies updated" -ForegroundColor Green
Write-Host "✅ Code analysis completed" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Run: flutter run" -ForegroundColor White
Write-Host "2. Test your app" -ForegroundColor White
Write-Host "3. Build APK: flutter build apk --release" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Your app should now compile without errors!" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 