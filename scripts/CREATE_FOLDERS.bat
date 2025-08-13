@echo off
echo ========================================
echo 📁 CREATING ORGANIZED FOLDERS
echo ========================================
echo.

echo Creating main folders...
mkdir docs
mkdir scripts
mkdir tools

echo Creating docs subfolders...
mkdir docs\api
mkdir docs\setup
mkdir docs\fixes
mkdir docs\deployment
mkdir docs\guides

echo Creating scripts subfolders...
mkdir scripts\setup
mkdir scripts\testing
mkdir scripts\database
mkdir scripts\fixes
mkdir scripts\deployment

echo Creating tools subfolders...
mkdir tools\database
mkdir tools\testing
mkdir tools\fixes

echo.
echo ========================================
echo ✅ FOLDERS CREATED SUCCESSFULLY!
echo ========================================
echo.
echo 📁 New folder structure:
echo.
echo 📂 docs/
echo    ├── 📂 api/
echo    ├── 📂 setup/
echo    ├── 📂 fixes/
echo    ├── 📂 deployment/
echo    └── 📂 guides/
echo.
echo 📂 scripts/
echo    ├── 📂 setup/
echo    ├── 📂 testing/
echo    ├── 📂 database/
echo    ├── 📂 fixes/
echo    └── 📂 deployment/
echo.
echo 📂 tools/
echo    ├── 📂 database/
echo    ├── 📂 testing/
echo    └── 📂 fixes/
echo.
echo ✅ All folders created in: %CD%
echo.
pause 