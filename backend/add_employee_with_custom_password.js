const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const readline = require('readline');

const prisma = new PrismaClient();

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function askQuestion(question) {
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      resolve(answer);
    });
  });
}

async function addEmployeeWithCustomPassword() {
  console.log('👤 ADD EMPLOYEE WITH CUSTOM PASSWORD');
  console.log('====================================');
  console.log('');

  try {
    // Get employee details from user
    const email = await askQuestion('📧 Enter email: ');
    const password = await askQuestion('🔐 Enter password: ');
    const name = await askQuestion('👤 Enter name: ');
    const phone = await askQuestion('📱 Enter phone number: ');
    const designation = await askQuestion('💼 Enter designation: ');
    const department = await askQuestion('🏢 Enter department: ');
    const role = await askQuestion('👑 Enter role (ADMIN/EMPLOYEE): ');

    // Hash the password
    const hashedPassword = await bcrypt.hash(password, 12);

    // Create employee
    const employee = await prisma.user.create({
      data: {
        email: email,
        password: hashedPassword,
        name: name,
        role: role.toUpperCase(),
        phoneNumber: phone,
        designation: designation,
        department: department,
        dateOfJoining: new Date()
      }
    });

    console.log('');
    console.log('✅ Employee added successfully!');
    console.log('');
    console.log('📋 EMPLOYEE DETAILS:');
    console.log(`   Email: ${email}`);
    console.log(`   Password: ${password} (as entered)`);
    console.log(`   Name: ${name}`);
    console.log(`   Role: ${role.toUpperCase()}`);
    console.log(`   ID: ${employee.id}`);
    console.log('');
    console.log('🔐 LOGIN CREDENTIALS:');
    console.log(`   Email: ${email}`);
    console.log(`   Password: ${password}`);
    console.log('');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
    rl.close();
  }
}

addEmployeeWithCustomPassword(); 