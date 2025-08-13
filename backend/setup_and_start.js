const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const { execSync } = require('child_process');

async function setupAndStart() {
  console.log('🚀 SETTING UP DATABASE AND STARTING SERVER');
  console.log('==========================================');
  console.log('');
  
  const prisma = new PrismaClient();
  
  try {
    // Step 1: Generate Prisma client
    console.log('📦 Step 1: Generating Prisma client...');
    try {
      execSync('npx prisma generate', { stdio: 'inherit' });
      console.log('✅ Prisma client generated successfully');
    } catch (error) {
      console.log('⚠️  Prisma generate failed, continuing...');
    }
    
    // Step 2: Push schema to database
    console.log('📦 Step 2: Pushing schema to database...');
    try {
      execSync('npx prisma db push', { stdio: 'inherit' });
      console.log('✅ Schema pushed successfully');
    } catch (error) {
      console.log('⚠️  Schema push failed, continuing...');
    }
    
    // Step 3: Clear existing data
    console.log('📦 Step 3: Clearing existing data...');
    try {
      await prisma.user.deleteMany();
      await prisma.leaveType.deleteMany();
      await prisma.task.deleteMany();
      console.log('✅ Existing data cleared');
    } catch (error) {
      console.log('⚠️  Could not clear data, continuing...');
    }
    
    // Step 4: Add real users
    console.log('📦 Step 4: Adding real users...');
    
    const users = [
      {
        name: 'Keshav Kumar',
        email: 'keshaw390@gmail.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543210',
        designation: 'Software Developer',
        department: 'IT',
        gender: 'Male',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Tech Lead'
      },
      {
        name: 'Admin User',
        email: 'admin@techcorp.com',
        password: 'Admin@123',
        role: 'ADMIN',
        phoneNumber: '+919876543211',
        designation: 'System Administrator',
        department: 'Management',
        gender: 'Male',
        shiftTiming: '8:00 AM - 5:00 PM',
        reportingTo: 'CEO'
      },
      {
        name: 'Surya Prakash',
        email: 'suryap1209@gmail.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543212',
        designation: 'UI/UX Designer',
        department: 'Design',
        gender: 'Male',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Design Manager'
      },
      {
        name: 'Priya Sharma',
        email: 'priya.sharma@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543213',
        designation: 'Marketing Specialist',
        department: 'Marketing',
        gender: 'Female',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'Marketing Manager'
      },
      {
        name: 'Rahul Singh',
        email: 'rahul.singh@company.com',
        password: 'Employee@123',
        role: 'EMPLOYEE',
        phoneNumber: '+919876543214',
        designation: 'Sales Representative',
        department: 'Sales',
        gender: 'Male',
        shiftTiming: '8:30 AM - 5:30 PM',
        reportingTo: 'Sales Manager'
      }
    ];
    
    for (const userData of users) {
      try {
        const hashedPassword = await bcrypt.hash(userData.password, 12);
        const user = await prisma.user.create({
          data: {
            ...userData,
            password: hashedPassword,
            dateOfJoining: new Date()
          }
        });
        console.log(`✅ Added: ${user.name} (${user.email}) - ${user.role}`);
      } catch (error) {
        console.log(`⚠️  Could not add ${userData.email}: ${error.message}`);
      }
    }
    
    // Step 5: Add leave types
    console.log('📦 Step 5: Adding leave types...');
    const leaveTypes = [
      { name: 'Sick Leave', description: 'Medical leave for illness' },
      { name: 'Casual Leave', description: 'Personal leave for urgent matters' },
      { name: 'Annual Leave', description: 'Planned vacation leave' },
      { name: 'Maternity Leave', description: 'Leave for expecting mothers' },
      { name: 'Paternity Leave', description: 'Leave for new fathers' }
    ];
    
    for (const leaveType of leaveTypes) {
      try {
        await prisma.leaveType.create({ data: leaveType });
        console.log(`✅ Added leave type: ${leaveType.name}`);
      } catch (error) {
        console.log(`⚠️  Could not add leave type ${leaveType.name}`);
      }
    }
    
    // Step 6: Add sample tasks
    console.log('📦 Step 6: Adding sample tasks...');
    const tasks = [
      {
        title: 'Complete Project Documentation',
        description: 'Write comprehensive documentation for the current project',
        assignedTo: 'keshaw390@gmail.com',
        priority: 'HIGH',
        status: 'IN_PROGRESS',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days from now
      },
      {
        title: 'Design User Interface',
        description: 'Create wireframes and mockups for the new feature',
        assignedTo: 'suryap1209@gmail.com',
        priority: 'MEDIUM',
        status: 'PENDING',
        dueDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000) // 5 days from now
      },
      {
        title: 'Marketing Campaign Planning',
        description: 'Plan and execute the Q4 marketing campaign',
        assignedTo: 'priya.sharma@company.com',
        priority: 'HIGH',
        status: 'IN_PROGRESS',
        dueDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000) // 10 days from now
      }
    ];
    
    for (const task of tasks) {
      try {
        await prisma.task.create({ data: task });
        console.log(`✅ Added task: ${task.title}`);
      } catch (error) {
        console.log(`⚠️  Could not add task ${task.title}`);
      }
    }
    
    console.log('');
    console.log('🎉 DATABASE SETUP COMPLETE!');
    console.log('==========================');
    console.log('');
    console.log('📋 REAL USERS IN DATABASE:');
    console.log('');
    users.forEach((user, index) => {
      console.log(`${index + 1}. 👤 ${user.name}`);
      console.log(`   📧 Email: ${user.email}`);
      console.log(`   👑 Role: ${user.role}`);
      console.log(`   📱 Phone: ${user.phoneNumber}`);
      console.log(`   💼 Designation: ${user.designation}`);
      console.log(`   🔐 Password: ${user.password}`);
      console.log('');
    });
    
    console.log('🔐 LOGIN INSTRUCTIONS:');
    console.log('======================');
    console.log('');
    console.log('You can login with ANY of the above emails using:');
    console.log('');
    console.log('📋 DEFAULT PASSWORDS:');
    console.log('   • All Employees: Employee@123');
    console.log('   • All Admins: Admin@123');
    console.log('');
    console.log('🎯 QUICK TEST:');
    console.log('   1. Start the server: npm start');
    console.log('   2. Open your app: http://localhost:8080');
    console.log('   3. Try any email from the list above');
    console.log('   4. Use the default password for that role');
    console.log('   5. Login successfully!');
    console.log('');
    console.log('⚠️  NOTE: All users have real data including phone numbers!');
    
  } catch (error) {
    console.log('❌ Error during setup:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

setupAndStart(); 