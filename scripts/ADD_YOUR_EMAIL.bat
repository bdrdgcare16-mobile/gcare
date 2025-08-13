@echo off
echo ========================================
echo 📧 ADD YOUR EMAIL TO DATABASE
echo ========================================
echo.

set /p useremail="Enter your email: "
set /p userpassword="Enter your password (or press Enter for default '123456'): "

if "%userpassword%"=="" set userpassword=123456

echo.
echo Adding your email: %useremail%
echo Password: %userpassword%
echo.

cd backend
node -e "
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

async function addUser() {
  try {
    const hashedPassword = await bcrypt.hash('%userpassword%', 10);
    
    const user = await prisma.user.upsert({
      where: { email: '%useremail%' },
      update: { password: hashedPassword },
      create: {
        email: '%useremail%',
        password: hashedPassword,
        name: 'Your Name',
        role: 'EMPLOYEE',
        department: 'IT',
        position: 'Developer',
        salary: 50000,
        hireDate: new Date(),
        isActive: true
      }
    });
    
    console.log('✅ User added successfully!');
    console.log('Email: %useremail%');
    console.log('Password: %userpassword%');
    console.log('Role: EMPLOYEE');
  } catch (error) {
    console.log('❌ Error:', error.message);
  } finally {
    await prisma.\$disconnect();
  }
}

addUser();
"

echo.
echo ========================================
echo 🎉 YOUR EMAIL ADDED SUCCESSFULLY!
echo ========================================
echo.
echo ✅ Email: %useremail%
echo ✅ Password: %userpassword%
echo ✅ You can now login with your email!
echo.
pause 