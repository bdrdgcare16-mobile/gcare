const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

const realEmployees = [
  {
    name: 'A. Baby Reeta',
    email: 'babyreeta16@gmail.com',
    phoneNumber: '9843194674',
    designation: 'District Program officer',
    gender: 'Female',
    department: 'Program Management',
    shiftTiming: '9:00 AM - 6:00 PM',
    reportingTo: 'Program Director',
    dateOfJoining: '2023-01-15',
    password: 'employee123'
  },
  {
    name: 'A. Mahalakshmi',
    email: 'keshaw390@gmail.com',
    phoneNumber: '9876543210',
    designation: 'Field Coordinator',
    gender: 'Female',
    department: 'Field Operations',
    shiftTiming: '9:00 AM - 6:00 PM',
    reportingTo: 'District Program officer',
    dateOfJoining: '2023-02-01',
    password: 'employee123'
  },
  {
    name: 'M. Anbumozhi',
    email: 'anbu98871@gmail.com',
    phoneNumber: '9876543211',
    designation: 'Social Worker',
    gender: 'Male',
    department: 'Social Work',
    shiftTiming: '9:00 AM - 6:00 PM',
    reportingTo: 'Field Coordinator',
    dateOfJoining: '2023-03-01',
    password: 'employee123'
  },
  {
    name: 'A. Sekar',
    email: 'johnveni2004@hgmail.com',
    phoneNumber: '9876543212',
    designation: 'Community Mobilizer',
    gender: 'Male',
    department: 'Community Development',
    shiftTiming: '9:00 AM - 6:00 PM',
    reportingTo: 'Field Coordinator',
    dateOfJoining: '2023-04-01',
    password: 'employee123'
  },
  {
    name: 'R. Karuppaiah',
    email: 'paiyark123@gmail.com',
    phoneNumber: '9876543213',
    designation: 'Field Worker',
    gender: 'Male',
    department: 'Field Operations',
    shiftTiming: '9:00 AM - 6:00 PM',
    reportingTo: 'Field Coordinator',
    dateOfJoining: '2023-05-01',
    password: 'employee123'
  },
  {
    name: 'M. Pandiyan',
    email: 'anbungo@gmail.com',
    phoneNumber: '9876543214',
    designation: 'Data Entry Operator',
    gender: 'Male',
    department: 'Administration',
    shiftTiming: '9:00 AM - 6:00 PM',
    reportingTo: 'District Program officer',
    dateOfJoining: '2023-06-01',
    password: 'employee123'
  },
  {
    name: 'R. Vijay Bhasker',
    email: 'socialworkervijay@gmail.com',
    phoneNumber: '9876543215',
    designation: 'Social Worker',
    gender: 'Male',
    department: 'Social Work',
    shiftTiming: '9:00 AM - 6:00 PM',
    reportingTo: 'Field Coordinator',
    dateOfJoining: '2023-07-01',
    password: 'employee123'
  },
  {
    name: 'T. Arunagiri',
    email: 'tarunagiri007@gmail.com',
    phoneNumber: '9876543216',
    designation: 'Community Mobilizer',
    gender: 'Male',
    department: 'Community Development',
    shiftTiming: '9:00 AM - 6:00 PM',
    reportingTo: 'Field Coordinator',
    dateOfJoining: '2023-08-01',
    password: 'employee123'
  },
  {
    name: 'S. Ramasubramanian',
    email: 'srs30051957@gmail.com',
    phoneNumber: '9876543217',
    designation: 'Field Worker',
    gender: 'Male',
    department: 'Field Operations',
    shiftTiming: '9:00 AM - 6:00 PM',
    reportingTo: 'Field Coordinator',
    dateOfJoining: '2023-09-01',
    password: 'employee123'
  },
  {
    name: 'Arima Anand',
    email: 'arimaanand196456@gmail.com',
    phoneNumber: '9876543218',
    designation: 'Data Entry Operator',
    gender: 'Female',
    department: 'Administration',
    shiftTiming: '9:00 AM - 6:00 PM',
    reportingTo: 'District Program officer',
    dateOfJoining: '2023-10-01',
    password: 'employee123'
  },
  {
    name: 'R. Franklin',
    email: 'kecttrust@gmail.com',
    phoneNumber: '9876543219',
    designation: 'Field Coordinator',
    gender: 'Male',
    department: 'Field Operations',
    shiftTiming: '9:00 AM - 6:00 PM',
    reportingTo: 'District Program officer',
    dateOfJoining: '2023-11-01',
    password: 'employee123'
  },
  {
    name: 'M. Annamalai',
    email: 'annamalai1966@gmail.com',
    phoneNumber: '9876543220',
    designation: 'Social Worker',
    gender: 'Male',
    department: 'Social Work',
    shiftTiming: '9:00 AM - 6:00 PM',
    reportingTo: 'Field Coordinator',
    dateOfJoining: '2023-12-01',
    password: 'employee123'
  }
];

async function addRealEmployees() {
  try {
    console.log('🚀 Starting to add real employees to database...');
    
    // Clear existing data first
    console.log('🗑️ Clearing existing data...');
    await prisma.attendance.deleteMany();
    await prisma.task.deleteMany();
    await prisma.leaveRequest.deleteMany();
    await prisma.payroll.deleteMany();
    await prisma.overtime.deleteMany();
    await prisma.permission.deleteMany();
    await prisma.user.deleteMany();
    
    console.log('✅ Existing data cleared');
    
    // Add admin user
    console.log('👑 Adding admin user...');
    const adminPassword = await bcrypt.hash('admin123', 10);
    const admin = await prisma.user.create({
      data: {
        name: 'Admin User',
        email: 'admin@nishali.com',
        password: adminPassword,
        role: 'ADMIN',
        phoneNumber: '1234567890',
        designation: 'System Administrator',
        gender: 'Not specified',
        department: 'IT',
        shiftTiming: '9:00 AM - 6:00 PM',
        reportingTo: 'CEO',
        dateOfJoining: new Date('2023-01-01'),
      }
    });
    console.log('✅ Admin user created with ID:', admin.id);
    
    // Add real employees
    console.log('👥 Adding real employees...');
    for (const employee of realEmployees) {
      const hashedPassword = await bcrypt.hash(employee.password, 10);
      const user = await prisma.user.create({
        data: {
          name: employee.name,
          email: employee.email,
          password: hashedPassword,
          role: 'EMPLOYEE',
          phoneNumber: employee.phoneNumber,
          designation: employee.designation,
          gender: employee.gender,
          department: employee.department,
          shiftTiming: employee.shiftTiming,
          reportingTo: employee.reportingTo,
          dateOfJoining: new Date(employee.dateOfJoining),
        }
      });
      console.log(`✅ Employee ${employee.name} created with ID: ${user.id}`);
    }
    
    console.log('🎉 All real employees added successfully!');
    console.log('\n📋 Login Credentials:');
    console.log('👑 Admin: admin@nishali.com / admin123');
    console.log('👥 Employees: Use any email from the list with password: employee123');
    
  } catch (error) {
    console.error('❌ Error adding employees:', error);
  } finally {
    await prisma.$disconnect();
  }
}

addRealEmployees(); 