@echo off
echo ========================================
echo 📁 MOVING FILES TO ORGANIZED FOLDERS
echo ========================================
echo.

echo Moving documentation files...
move "*.md" "docs\"

echo Moving batch files...
move "*.bat" "scripts\"

echo Moving JavaScript files...
move "*.js" "tools\"

echo Moving PowerShell files...
move "*.ps1" "tools\"

echo.
echo ========================================
echo ✅ FILES MOVED SUCCESSFULLY!
echo ========================================
echo.
echo 📁 Files organized into:
echo.
echo 📂 docs/          (All .md files)
echo 📂 scripts/       (All .bat files)
echo 📂 tools/         (All .js and .ps1 files)
echo.
echo ✅ Your project is now organized!
echo.
pause 