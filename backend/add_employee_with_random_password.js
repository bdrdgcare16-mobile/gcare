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

// Generate random password
function generateRandomPassword() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
  let password = '';
  
  // Ensure at least one uppercase, one lowercase, one number, one special character
  password += chars.charAt(Math.floor(Math.random() * 26)); // Uppercase
  password += chars.charAt(26 + Math.floor(Math.random() * 26)); // Lowercase
  password += chars.charAt(52 + Math.floor(Math.random() * 10)); // Number
  password += chars.charAt(62 + Math.floor(Math.random() * 8)); // Special char
  
  // Add 4 more random characters
  for (let i = 0; i < 4; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  
  // Shuffle the password
  return password.split('').sort(() => Math.random() - 0.5).join('');
}

async function addEmployeeWithRandomPassword() {
  console.log('👤 ADD EMPLOYEE WITH RANDOM PASSWORD');
  console.log('====================================');
  console.log('');

  try {
    // Get employee details from user
    const email = await askQuestion('📧 Enter email: ');
    const name = await askQuestion('👤 Enter name: ');
    const phone = await askQuestion('📱 Enter phone number: ');
    const designation = await askQuestion('💼 Enter designation: ');
    const department = await askQuestion('🏢 Enter department: ');
    const role = await askQuestion('👑 Enter role (ADMIN/EMPLOYEE): ');

    // Generate random password
    const randomPassword = generateRandomPassword();
    console.log('');
    console.log(`🔐 Generated password: ${randomPassword}`);

    // Hash the password
    const hashedPassword = await bcrypt.hash(randomPassword, 12);

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
    console.log(`   Password: ${randomPassword} (auto-generated)`);
    console.log(`   Name: ${name}`);
    console.log(`   Role: ${role.toUpperCase()}`);
    console.log(`   ID: ${employee.id}`);
    console.log('');
    console.log('🔐 LOGIN CREDENTIALS:');
    console.log(`   Email: ${email}`);
    console.log(`   Password: ${randomPassword}`);
    console.log('');
    console.log('⚠️  IMPORTANT: Save this password! It cannot be recovered.');
    console.log('');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await prisma.$disconnect();
    rl.close();
  }
}

addEmployeeWithRandomPassword(); 