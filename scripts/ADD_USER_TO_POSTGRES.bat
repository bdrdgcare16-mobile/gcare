@echo off
echo ========================================
echo 🗄️ ADD USER TO POSTGRESQL DATABASE
echo ========================================
echo.

set /p useremail="Enter email: "
set /p username="Enter name: "
set /p userpassword="Enter password (or press Enter for '123456'): "
set /p userrole="Enter role (EMPLOYEE/ADMIN/MANAGER, or press Enter for 'EMPLOYEE'): "
set /p userdepartment="Enter department (IT/HR/SALES, or press Enter for 'IT'): "

if "%userpassword%"=="" set userpassword=123456
if "%userrole%"=="" set userrole=EMPLOYEE
if "%userdepartment%"=="" set userdepartment=IT

echo.
echo Adding user to PostgreSQL database...
echo Email: %useremail%
echo Name: %username%
echo Password: %userpassword%
echo Role: %userrole%
echo Department: %userdepartment%
echo.

cd backend
node -e "
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

async function addUserToPostgres() {
  try {
    console.log('🔗 Connecting to PostgreSQL database...');
    
    // Hash the password
    const hashedPassword = await bcrypt.hash('%userpassword%', 10);
    
    // Create user in PostgreSQL
    const user = await prisma.user.upsert({
      where: { email: '%useremail%' },
      update: { 
        password: hashedPassword,
        name: '%username%',
        role: '%userrole%',
        department: '%userdepartment%'
      },
      create: {
        email: '%useremail%',
        password: hashedPassword,
        name: '%username%',
        role: '%userrole%',
        department: '%userdepartment%',
        phoneNumber: '+1234567890',
        designation: 'Developer',
        shiftTiming: '9:00 AM - 6:00 PM',
        gender: 'Not Specified',
        reportingTo: 'Manager',
        dateOfJoining: new Date()
      }
    });
    
    console.log('✅ User added successfully to PostgreSQL!');
    console.log('📧 Email: %useremail%');
    console.log('🔑 Password: %userpassword%');
    console.log('👤 Name: %username%');
    console.log('🎯 Role: %userrole%');
    console.log('🏢 Department: %userdepartment%');
    console.log('🆔 User ID: ' + user.id);
    
  } catch (error) {
    console.log('❌ Error adding user to PostgreSQL:');
    console.log(error.message);
    
    if (error.message.includes('connect')) {
      console.log('💡 Make sure PostgreSQL is running and accessible');
      console.log('💡 Check your database connection in prisma/schema.prisma');
    }
  } finally {
    await prisma.\$disconnect();
  }
}

addUserToPostgres();
"

echo.
echo ========================================
echo 🎉 USER ADDED TO POSTGRESQL!
echo ========================================
echo.
echo ✅ Email: %useremail%
echo ✅ Password: %userpassword%
echo ✅ You can now login with this email!
echo.
echo 🗄️ Database: PostgreSQL (SERV)
echo 🔗 Connection: postgresql://postgres:Nishali@localhost:5432/SERV
echo.
pause 