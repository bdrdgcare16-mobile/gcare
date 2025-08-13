const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function viewEmployees() {
  console.log('👥 ALL EMPLOYEES IN DATABASE');
  console.log('============================');
  console.log('');

  try {
    // Get all employees
    const employees = await prisma.user.findMany({
      where: { role: 'EMPLOYEE' },
      select: {
        id: true,
        name: true,
        email: true,
        phoneNumber: true,
        designation: true,
        department: true,
        gender: true,
        dateOfJoining: true
      },
      orderBy: { name: 'asc' }
    });

    // Get all admins
    const admins = await prisma.user.findMany({
      where: { role: 'ADMIN' },
      select: {
        id: true,
        name: true,
        email: true,
        phoneNumber: true,
        designation: true,
        department: true,
        gender: true,
        dateOfJoining: true
      },
      orderBy: { name: 'asc' }
    });
    
    console.log('🔑 ADMIN USERS:');
    console.log('===============');
    admins.forEach((admin, index) => {
      console.log(`${index + 1}. ${admin.name}`);
      console.log(`   Email: ${admin.email}`);
      console.log(`   Phone: ${admin.phoneNumber}`);
      console.log(`   Designation: ${admin.designation}`);
      console.log(`   Department: ${admin.department}`);
      console.log(`   Gender: ${admin.gender}`);
      console.log(`   Joined: ${admin.dateOfJoining.toDateString()}`);
      console.log('');
    });

    console.log('👨‍💼 EMPLOYEES:');
    console.log('==============');
    employees.forEach((emp, index) => {
      console.log(`${index + 1}. ${emp.name}`);
      console.log(`   Email: ${emp.email}`);
      console.log(`   Phone: ${emp.phoneNumber}`);
      console.log(`   Designation: ${emp.designation}`);
      console.log(`   Department: ${emp.department}`);
      console.log(`   Gender: ${emp.gender}`);
      console.log(`   Joined: ${emp.dateOfJoining.toDateString()}`);
      console.log('');
    });

    console.log('📊 SUMMARY:');
    console.log('===========');
    console.log(`Total Admins: ${admins.length}`);
    console.log(`Total Employees: ${employees.length}`);
    console.log(`Total Users: ${admins.length + employees.length}`);
    console.log('');
    console.log('💡 Login Password for all employees: Employee@123');
    console.log('💡 Login Password for all admins: Admin@123');

  } catch (error) {
    console.error('❌ Error viewing employees:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

viewEmployees(); 