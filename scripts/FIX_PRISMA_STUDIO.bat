@echo off
echo 🔧 FIXING PRISMA STUDIO ISSUE
echo =============================
echo.

echo 📊 Regenerating Prisma client...
cd backend
npx prisma generate

echo.
echo 🔄 Restarting Prisma Studio...
echo 🌐 This should open at: http://localhost:5555
echo.
echo 💡 If it still doesn't work, use SIMPLE_DATABASE_MANAGER.bat instead
echo.

npx prisma studio

echo.
echo ✅ Prisma Studio should be working now!
echo.
pause 