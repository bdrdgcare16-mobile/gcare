@echo off
echo ========================================
echo 📁 ORGANIZING PROJECT FILES
echo ========================================
echo.

echo Creating folder structure...

:: Create main folders
mkdir "docs" 2>nul
mkdir "scripts" 2>nul
mkdir "tools" 2>nul
mkdir "guides" 2>nul
mkdir "setup" 2>nul
mkdir "testing" 2>nul
mkdir "database" 2>nul
mkdir "deployment" 2>nul
mkdir "fixes" 2>nul

echo ✅ Created main folders
echo.

echo Moving documentation files...

:: Move documentation files to docs folder
move "API_ENDPOINTS_GUIDE.md" "docs\" 2>nul
move "API_STATUS_SUMMARY.md" "docs\" 2>nul
move "BACKEND_SETUP.md" "docs\" 2>nul
move "BUILD_APK_GUIDE.md" "docs\" 2>nul
move "CAMERA_ERROR_FIXED.md" "docs\" 2>nul
move "CAMERA_FINAL_SOLUTION.md" "docs\" 2>nul
move "CAMERA_FIX_GUIDE.md" "docs\" 2>nul
move "CAMERA_FIXED_FINAL.md" "docs\" 2>nul
move "CAMERA_TEST_GUIDE.md" "docs\" 2>nul
move "COMPLETE_USER_JOURNEY_DEMO.md" "docs\" 2>nul
move "DATABASE_MANAGEMENT_GUIDE.md" "docs\" 2>nul
move "DEPLOY_TO_GITHUB.md" "docs\" 2>nul
move "DEPLOY_TO_NETLIFY.md" "docs\" 2>nul
move "DEPLOY_WEB_APP.md" "docs\" 2>nul
move "DESKTOP_CAMERA_SOLUTION.md" "docs\" 2>nul
move "EASY_DATA_MANAGEMENT_GUIDE.md" "docs\" 2>nul
move "EMPLOYEE_AUTH_GUIDE.md" "docs\" 2>nul
move "EMPTY_SCREEN_FIX.md" "docs\" 2>nul
move "FACE_ID_GUIDE.md" "docs\" 2>nul
move "FACE_REGISTRATION_COMPLETE.md" "docs\" 2>nul
move "FINAL_CAMERA_FIX.md" "docs\" 2>nul
move "FINAL_CAMERA_FIXED.md" "docs\" 2>nul
move "FINAL_CAMERA_SOLUTION.md" "docs\" 2>nul
move "FINAL_LAUNCH_SETUP.md" "docs\" 2>nul
move "FINAL_LOGIN_STATUS.md" "docs\" 2>nul
move "FINAL_SETUP_GUIDE.md" "docs\" 2>nul
move "FINAL_SUBMISSION_GUIDE.md" "docs\" 2>nul
move "FINAL_SUBMISSION_STATUS.md" "docs\" 2>nul
move "FINAL_WORKING_SERVER.md" "docs\" 2>nul
move "FUTURE_DATA_MANAGEMENT_GUIDE.md" "docs\" 2>nul
move "FUTURE_EMPLOYEE_WORKFLOW.md" "docs\" 2>nul
move "IMMEDIATE_FIX_GUIDE.md" "docs\" 2>nul
move "LAUNCH_DAY_GUIDE.md" "docs\" 2>nul
move "LAUNCH_DAY_QUICK_REFERENCE.md" "docs\" 2>nul
move "LOGIN_ANY_EMAIL_GUIDE.md" "docs\" 2>nul
move "LOGIN_FIXED.md" "docs\" 2>nul
move "MANUAL_DATA_MANAGEMENT_GUIDE.md" "docs\" 2>nul
move "MANUAL_FIX_GUIDE.md" "docs\" 2>nul
move "MIGRATION_SUMMARY.md" "docs\" 2>nul
move "MY_TASKS_FIXED.md" "docs\" 2>nul
move "PENDING_TASKS_ANALYSIS.md" "docs\" 2>nul
move "PERFECT_CAMERA_SOLUTION.md" "docs\" 2>nul
move "PERFORMANCE_FIX.md" "docs\" 2>nul
move "POSTGRESQL_MIGRATION_GUIDE.md" "docs\" 2>nul
move "PRODUCTION_DEPLOYMENT_GUIDE.md" "docs\" 2>nul
move "PRODUCTION_SETUP_GUIDE.md" "docs\" 2>nul
move "QUICK_APK_FIX.md" "docs\" 2>nul
move "QUICK_APP_SUBMISSION_PLAN.md" "docs\" 2>nul
move "QUICK_CAMERA_FIX.md" "docs\" 2>nul
move "QUICK_LOGIN_FIX.md" "docs\" 2>nul
move "QUICK_MOBILE_APK.md" "docs\" 2>nul
move "QUICK_SETUP.md" "docs\" 2>nul
move "REAL_CAMERA_WORKING.md" "docs\" 2>nul
move "REAL_DATA_SETUP_COMPLETE.md" "docs\" 2>nul
move "REAL_DATA_SOLUTION.md" "docs\" 2>nul
move "REAL_EMPLOYEE_DATA_SUMMARY.md" "docs\" 2>nul
move "REAL_OFFICE_DATA_DEMO_GUIDE.md" "docs\" 2>nul
move "REAL_OFFICE_DEMO_GUIDE.md" "docs\" 2>nul
move "REALTIME_REPORTS_IMPLEMENTATION.md" "docs\" 2>nul
move "REALTIME_UI_GUIDE.md" "docs\" 2>nul
move "SIMPLE_WORKING_SOLUTION.md" "docs\" 2>nul
move "STEP_BY_STEP_GUIDE.md" "docs\" 2>nul
move "SUBMISSION_CHECKLIST.md" "docs\" 2>nul
move "SUBMIT_LOCAL_FILES.md" "docs\" 2>nul
move "SYSTEM_STATUS_REPORT.md" "docs\" 2>nul
move "TASK_FILTERING_FIXED.md" "docs\" 2>nul
move "TASK_SCREEN_FIXED.md" "docs\" 2>nul
move "TASK_STATISTICS_FIXED.md" "docs\" 2>nul
move "TOMORROW_DATA_ADDITION_GUIDE.md" "docs\" 2>nul
move "TOMORROW_DEMO_GUIDE.md" "docs\" 2>nul
move "TOMORROW_LAUNCH_CHECKLIST.md" "docs\" 2>nul
move "TROUBLESHOOTING_GUIDE.md" "docs\" 2>nul
move "URGENT_SUBMISSION_STEPS.md" "docs\" 2>nul
move "USER_GUIDE.md" "docs\" 2>nul

echo ✅ Moved documentation files to docs folder
echo.

echo Moving script files...

:: Move batch files to scripts folder
move "*.bat" "scripts\" 2>nul

echo ✅ Moved batch files to scripts folder
echo.

echo Moving JavaScript files...

:: Move JS files to tools folder
move "*.js" "tools\" 2>nul

echo ✅ Moved JavaScript files to tools folder
echo.

echo Moving PowerShell files...

:: Move PowerShell files to tools folder
move "*.ps1" "tools\" 2>nul

echo ✅ Moved PowerShell files to tools folder
echo.

echo Creating subfolders in docs...

:: Create subfolders in docs
mkdir "docs\api" 2>nul
mkdir "docs\setup" 2>nul
mkdir "docs\fixes" 2>nul
mkdir "docs\deployment" 2>nul
mkdir "docs\guides" 2>nul

echo ✅ Created docs subfolders
echo.

echo Moving API-related docs...

:: Move API docs to docs/api
move "docs\API_*.md" "docs\api\" 2>nul

echo ✅ Moved API documentation
echo.

echo Moving setup guides...

:: Move setup guides to docs/setup
move "docs\*SETUP*.md" "docs\setup\" 2>nul
move "docs\*GUIDE*.md" "docs\setup\" 2>nul

echo ✅ Moved setup guides
echo.

echo Moving fix documentation...

:: Move fix docs to docs/fixes
move "docs\*FIX*.md" "docs\fixes\" 2>nul

echo ✅ Moved fix documentation
echo.

echo Moving deployment docs...

:: Move deployment docs to docs/deployment
move "docs\*DEPLOY*.md" "docs\deployment\" 2>nul

echo ✅ Moved deployment documentation
echo.

echo Creating subfolders in scripts...

:: Create subfolders in scripts
mkdir "scripts\setup" 2>nul
mkdir "scripts\testing" 2>nul
mkdir "scripts\database" 2>nul
mkdir "scripts\fixes" 2>nul
mkdir "scripts\deployment" 2>nul

echo ✅ Created scripts subfolders
echo.

echo Moving setup scripts...

:: Move setup scripts
move "scripts\*SETUP*.bat" "scripts\setup\" 2>nul
move "scripts\*START*.bat" "scripts\setup\" 2>nul
move "scripts\*LAUNCH*.bat" "scripts\setup\" 2>nul

echo ✅ Moved setup scripts
echo.

echo Moving testing scripts...

:: Move testing scripts
move "scripts\*TEST*.bat" "scripts\testing\" 2>nul
move "scripts\*CHECK*.bat" "scripts\testing\" 2>nul

echo ✅ Moved testing scripts
echo.

echo Moving database scripts...

:: Move database scripts
move "scripts\*DATABASE*.bat" "scripts\database\" 2>nul
move "scripts\*ADD_*.bat" "scripts\database\" 2>nul
move "scripts\*USER*.bat" "scripts\database\" 2>nul

echo ✅ Moved database scripts
echo.

echo Moving fix scripts...

:: Move fix scripts
move "scripts\*FIX*.bat" "scripts\fixes\" 2>nul

echo ✅ Moved fix scripts
echo.

echo Moving deployment scripts...

:: Move deployment scripts
move "scripts\*DEPLOY*.bat" "scripts\deployment\" 2>nul

echo ✅ Moved deployment scripts
echo.

echo Creating subfolders in tools...

:: Create subfolders in tools
mkdir "tools\database" 2>nul
mkdir "tools\testing" 2>nul
mkdir "tools\fixes" 2>nul

echo ✅ Created tools subfolders
echo.

echo Moving database tools...

:: Move database JS files
move "tools\*database*.js" "tools\database\" 2>nul
move "tools\*user*.js" "tools\database\" 2>nul
move "tools\*add_*.js" "tools\database\" 2>nul

echo ✅ Moved database tools
echo.

echo Moving testing tools...

:: Move testing JS files
move "tools\*test*.js" "tools\testing\" 2>nul
move "tools\*check*.js" "tools\testing\" 2>nul

echo ✅ Moved testing tools
echo.

echo Moving fix tools...

:: Move fix JS files
move "tools\*fix*.js" "tools\fixes\" 2>nul

echo ✅ Moved fix tools
echo.

echo.
echo ========================================
echo 🎉 FILE ORGANIZATION COMPLETE!
echo ========================================
echo.
echo 📁 New folder structure:
echo.
echo 📂 docs/
echo    ├── 📂 api/          (API documentation)
echo    ├── 📂 setup/        (Setup guides)
echo    ├── 📂 fixes/        (Fix documentation)
echo    ├── 📂 deployment/   (Deployment guides)
echo    └── 📂 guides/       (General guides)
echo.
echo 📂 scripts/
echo    ├── 📂 setup/        (Setup batch files)
echo    ├── 📂 testing/      (Testing batch files)
echo    ├── 📂 database/     (Database batch files)
echo    ├── 📂 fixes/        (Fix batch files)
echo    └── 📂 deployment/   (Deployment batch files)
echo.
echo 📂 tools/
echo    ├── 📂 database/     (Database JS files)
echo    ├── 📂 testing/      (Testing JS files)
echo    └── 📂 fixes/        (Fix JS files)
echo.
echo ✅ All files organized!
echo ✅ Easy to find and manage!
echo ✅ Clean project structure!
echo.
pause 