const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function addNewUser() {
  try {
    console.log('🚀 Adding new user to database...');
    
    // New user data
    const newUser = {
      name: 'Nishali Selvaraj',
      email: 'nishaliselvaraj22@gmail.com',
      password: 'Nisha@123',
      role: 'EMPLOYEE',
      phoneNumber: '9876543210',
      designation: 'Software Developer',
      department: 'IT Department',
      gender: 'Female',
      shiftTiming: '9:00 AM - 6:00 PM',
      reportingTo: 'IT Manager',
      dateOfJoining: new Date('2024-01-01'),
    };

    // Check if user already exists
    const existing = await prisma.user.findUnique({ 
      where: { email: newUser.email } 
    });
    
    if (existing) {
      console.log('⚠️ User already exists!');
      console.log('📧 Email:', existing.email);
      console.log('👤 Name:', existing.name);
      console.log('🔑 Role:', existing.role);
      return;
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(newUser.password, 10);
    
    // Create user
    const user = await prisma.user.create({
      data: {
        name: newUser.name,
        email: newUser.email,
        password: hashedPassword,
        role: newUser.role,
        phoneNumber: newUser.phoneNumber,
        designation: newUser.designation,
        department: newUser.department,
        gender: newUser.gender,
        shiftTiming: newUser.shiftTiming,
        reportingTo: newUser.reportingTo,
        dateOfJoining: newUser.dateOfJoining,
      }
    });

    console.log('✅ New user created successfully!');
    console.log('📧 Email:', user.email);
    console.log('👤 Name:', user.name);
    console.log('🔑 Role:', user.role);
    console.log('🆔 ID:', user.id);
    console.log('');
    console.log('🎉 Now you can login with:');
    console.log('   Email: nishaliselvaraj22@gmail.com');
    console.log('   Password: Nisha@123');

  } catch (error) {
    console.error('❌ Error adding user:', error);
  } finally {
    await prisma.$disconnect();
  }
}

addNewUser(); 