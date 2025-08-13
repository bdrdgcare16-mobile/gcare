Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🚀 QUICK FILE ORGANIZATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Move all .md files to docs folder
Write-Host "Moving documentation files..." -ForegroundColor Yellow
Get-ChildItem -Filter "*.md" | Move-Item -Destination "docs\" -Force
Write-Host "✅ Moved all .md files to docs/" -ForegroundColor Green

# Move all .bat files to scripts folder
Write-Host "Moving batch files..." -ForegroundColor Yellow
Get-ChildItem -Filter "*.bat" | Move-Item -Destination "scripts\" -Force
Write-Host "✅ Moved all .bat files to scripts/" -ForegroundColor Green

# Move all .js files to tools folder
Write-Host "Moving JavaScript files..." -ForegroundColor Yellow
Get-ChildItem -Filter "*.js" | Move-Item -Destination "tools\" -Force
Write-Host "✅ Moved all .js files to tools/" -ForegroundColor Green

# Move all .ps1 files to tools folder
Write-Host "Moving PowerShell files..." -ForegroundColor Yellow
Get-ChildItem -Filter "*.ps1" | Move-Item -Destination "tools\" -Force
Write-Host "✅ Moved all .ps1 files to tools/" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎉 ALL FILES ORGANIZED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 Files organized into:" -ForegroundColor White
Write-Host ""
Write-Host "📂 docs/          (All .md files)" -ForegroundColor Cyan
Write-Host "📂 scripts/       (All .bat files)" -ForegroundColor Cyan
Write-Host "📂 tools/         (All .js and .ps1 files)" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Your project is now organized!" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to continue" 