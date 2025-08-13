@echo off
echo ========================================
echo 📁 SIMPLE FILE ORGANIZATION
echo ========================================
echo.

echo Creating folders...
mkdir docs 2>nul
mkdir scripts 2>nul
mkdir tools 2>nul
mkdir docs\api 2>nul
mkdir docs\setup 2>nul
mkdir docs\fixes 2>nul
mkdir docs\deployment 2>nul
mkdir docs\guides 2>nul
mkdir scripts\setup 2>nul
mkdir scripts\testing 2>nul
mkdir scripts\database 2>nul
mkdir scripts\fixes 2>nul
mkdir scripts\deployment 2>nul
mkdir tools\database 2>nul
mkdir tools\testing 2>nul
mkdir tools\fixes 2>nul

echo ✅ Created all folders
echo.

echo Moving documentation files...
move "*.md" "docs\" 2>nul
echo ✅ Moved all .md files to docs
echo.

echo Moving batch files...
move "*.bat" "scripts\" 2>nul
echo ✅ Moved all .bat files to scripts
echo.

echo Moving JavaScript files...
move "*.js" "tools\" 2>nul
echo ✅ Moved all .js files to tools
echo.

echo Moving PowerShell files...
move "*.ps1" "tools\" 2>nul
echo ✅ Moved all .ps1 files to tools
echo.

echo Organizing docs subfolders...
move "docs\API_*.md" "docs\api\" 2>nul
move "docs\*SETUP*.md" "docs\setup\" 2>nul
move "docs\*GUIDE*.md" "docs\guides\" 2>nul
move "docs\*FIX*.md" "docs\fixes\" 2>nul
move "docs\*DEPLOY*.md" "docs\deployment\" 2>nul

echo Organizing scripts subfolders...
move "scripts\*SETUP*.bat" "scripts\setup\" 2>nul
move "scripts\*START*.bat" "scripts\setup\" 2>nul
move "scripts\*LAUNCH*.bat" "scripts\setup\" 2>nul
move "scripts\*TEST*.bat" "scripts\testing\" 2>nul
move "scripts\*CHECK*.bat" "scripts\testing\" 2>nul
move "scripts\*ADD_*.bat" "scripts\database\" 2>nul
move "scripts\*USER*.bat" "scripts\database\" 2>nul
move "scripts\*DATABASE*.bat" "scripts\database\" 2>nul
move "scripts\*FIX*.bat" "scripts\fixes\" 2>nul
move "scripts\*DEPLOY*.bat" "scripts\deployment\" 2>nul

echo Organizing tools subfolders...
move "tools\*test*.js" "tools\testing\" 2>nul
move "tools\*check*.js" "tools\testing\" 2>nul
move "tools\*add_*.js" "tools\database\" 2>nul
move "tools\*user*.js" "tools\database\" 2>nul
move "tools\*fix*.js" "tools\fixes\" 2>nul

echo.
echo ========================================
echo 🎉 ORGANIZATION COMPLETE!
echo ========================================
echo.
echo 📁 New structure:
echo.
echo 📂 docs/
echo    ├── 📂 api/          (API docs)
echo    ├── 📂 setup/        (Setup guides)
echo    ├── 📂 fixes/        (Fix docs)
echo    ├── 📂 deployment/   (Deploy guides)
echo    └── 📂 guides/       (General guides)
echo.
echo 📂 scripts/
echo    ├── 📂 setup/        (Setup scripts)
echo    ├── 📂 testing/      (Testing scripts)
echo    ├── 📂 database/     (Database scripts)
echo    ├── 📂 fixes/        (Fix scripts)
echo    └── 📂 deployment/   (Deploy scripts)
echo.
echo 📂 tools/
echo    ├── 📂 database/     (Database tools)
echo    ├── 📂 testing/      (Testing tools)
echo    └── 📂 fixes/        (Fix tools)
echo.
echo ✅ All files organized!
echo ✅ Easy to find and manage!
echo.
pause 