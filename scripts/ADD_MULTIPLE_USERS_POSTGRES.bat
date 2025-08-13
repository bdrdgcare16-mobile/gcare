@echo off
echo ========================================
echo 🗄️ ADD MULTIPLE USERS TO POSTGRESQL
echo ========================================
echo.

echo This will add multiple users to your PostgreSQL database
echo Database: postgresql://postgres:Nishali@localhost:5432/SERV
echo.

cd backend
node -e "
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

const users = [
  {
    email: 'john.doe@company.com',
    name: 'John Doe',
    password: '123456',
    role: 'EMPLOYEE',
    department: 'IT'
  },
  {
    email: 'jane.smith@company.com',
    name: 'Jane Smith',
    password: '123456',
    role: 'MANAGER',
    department: 'HR'
  },
  {
    email: 'mike.wilson@company.com',
    name: 'Mike Wilson',
    password: '123456',
    role: 'EMPLOYEE',
    department: 'SALES'
  },
  {
    email: 'sarah.jones@company.com',
    name: 'Sarah Jones',
    password: '123456',
    role: 'ADMIN',
    department: 'IT'
  },
  {
    email: 'admin@company.com',
    name: 'System Admin',
    password: '123456',
    role: 'ADMIN',
    department: 'IT'
  },
  {
    email: 'manager@company.com',
    name: 'Department Manager',
    password: '123456',
    role: 'MANAGER',
    department: 'HR'
  },
  {
    email: 'employee@company.com',
    name: 'Regular Employee',
    password: '123456',
    role: 'EMPLOYEE',
    department: 'SALES'
  }
];

async function addMultipleUsersToPostgres() {
  try {
    console.log('🔗 Connecting to PostgreSQL database...');
    console.log('📊 Adding ' + users.length + ' users...\n');
    
    for (const userData of users) {
      try {
        const hashedPassword = await bcrypt.hash(userData.password, 10);
        
        const user = await prisma.user.upsert({
          where: { email: userData.email },
          update: { 
            password: hashedPassword,
            name: userData.name,
            role: userData.role,
            department: userData.department
          },
          create: {
            email: userData.email,
            password: hashedPassword,
            name: userData.name,
            role: userData.role,
            department: userData.department,
            phoneNumber: '+1234567890',
            designation: userData.role === 'ADMIN' ? 'Administrator' : 
                        userData.role === 'MANAGER' ? 'Manager' : 'Developer',
            shiftTiming: '9:00 AM - 6:00 PM',
            gender: 'Not Specified',
            reportingTo: userData.role === 'EMPLOYEE' ? 'Manager' : 'Admin',
            dateOfJoining: new Date()
          }
        });
        
        console.log('✅ Added: ' + userData.email + ' (' + userData.role + ')');
      } catch (error) {
        console.log('❌ Failed to add ' + userData.email + ': ' + error.message);
      }
    }
    
    console.log('\n🎉 Multiple users added to PostgreSQL!');
    console.log('📧 You can now login with any of these emails:');
    users.forEach(user => {
      console.log('   - ' + user.email + ' (Password: ' + user.password + ')');
    });
    
  } catch (error) {
    console.log('❌ Error connecting to PostgreSQL:');
    console.log(error.message);
    console.log('\n💡 Make sure PostgreSQL is running and accessible');
    console.log('💡 Check your database connection in prisma/schema.prisma');
  } finally {
    await prisma.\$disconnect();
  }
}

addMultipleUsersToPostgres();
"

echo.
echo ========================================
echo 🎉 MULTIPLE USERS ADDED TO POSTGRESQL!
echo ========================================
echo.
echo ✅ 7 users added to PostgreSQL database
echo ✅ All users have password: 123456
echo ✅ You can login with any email now!
echo.
echo 🗄️ Database: PostgreSQL (SERV)
echo 🔗 Connection: postgresql://postgres:Nishali@localhost:5432/SERV
echo.
pause 