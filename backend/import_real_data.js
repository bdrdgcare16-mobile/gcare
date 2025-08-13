const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

// Real employee data from your Excel file
const realEmployees = [
  {
    name: 'A. Baby Reeta',
    email: 'babyreeta16@gmail.com',
    phoneNumber: '9843194674',
    designation: 'District Program officer',
    gender: 'Female',
    password: 'employee123'
  },
  {
    name: 'A. Mahalakshmi',
    email: 'keshaw390@gmail.com',
    phoneNumber: '7868029050',
    designation: 'District Program officer',
    gender: 'Female',
    password: 'employee123'
  },
  {
    name: 'M. Anbumozhi',
    email: 'anbu98871@gmail.com',
    phoneNumber: '9159997873',
    designation: 'District Program officer',
    gender: 'Female',
    password: 'employee123'
  },
  {
    name: 'A. Sekar',
    email: 'johnveni2004@hgmail.com',
    phoneNumber: '9600467436',
    designation: 'District Program officer',
    gender: 'Male',
    password: 'employee123'
  },
  {
    name: 'R. Karuppaiah',
    email: 'paiyark123@gmail.com',
    phoneNumber: '9655333264',
    designation: 'District Program officer',
    gender: 'Male',
    password: 'employee123'
  },
  {
    name: 'M. Pandiyan',
    email: 'anbungo@gmail.com',
    phoneNumber: '8072052884',
    designation: 'District Program officer',
    gender: 'Male',
    password: 'employee123'
  },
  {
    name: 'R. Vijay Bhasker',
    email: 'socialworkervijay@gmail.com',
    phoneNumber: '8778464744',
    designation: 'District Program officer',
    gender: 'Male',
    password: 'employee123'
  },
  {
    name: 'T. Arunagiri',
    email: 'tarunagiri007@gmail.com',
    phoneNumber: '9840254181',
    designation: 'District Program officer',
    gender: 'Male',
    password: 'employee123'
  },
  {
    name: 'S. Ramasubramanian',
    email: 'srs30051957@gmail.com',
    phoneNumber: '7299939900',
    designation: 'District Program officer',
    gender: 'Male',
    password: 'employee123'
  },
  {
    name: 'Arima Anand',
    email: 'arimaanand196456@gmail.com',
    phoneNumber: '8489670414',
    designation: 'District Program officer',
    gender: 'Male',
    password: 'employee123'
  },
  {
    name: 'R. Franklin',
    email: 'kecttrust@gmail.com',
    phoneNumber: '9842164729',
    designation: 'District Program officer',
    gender: 'Male',
    password: 'employee123'
  },
  {
    name: 'M. Annamalai',
    email: 'annamalai1966@gmail.com',
    phoneNumber: '7092884650',
    designation: 'District Program officer',
    gender: 'Male',
    password: 'employee123'
  }
];

async function importRealData() {
  try {
    console.log('🚀 Starting real data import...');
    
    // Clear existing data (except admin)
    await prisma.user.deleteMany({
      where: {
        role: 'EMPLOYEE'
      }
    });
    
    console.log('✅ Cleared existing employee data');
    
    // Import real employees
    for (const employee of realEmployees) {
      const hashedPassword = await bcrypt.hash(employee.password, 10);
      
      await prisma.user.create({
        data: {
          name: employee.name,
          email: employee.email,
          password: hashedPassword,
          role: 'EMPLOYEE',
          phoneNumber: employee.phoneNumber,
          designation: employee.designation,
          gender: employee.gender,
          department: 'District Program',
          shiftTiming: '9:00 AM - 6:00 PM',
          reportingTo: 'Program Manager',
          dateOfJoining: new Date('2024-01-01')
        }
      });
      
      console.log(`✅ Added employee: ${employee.name}`);
    }
    
    console.log('🎉 Real data import completed successfully!');
    console.log(`📊 Total employees imported: ${realEmployees.length}`);
    
  } catch (error) {
    console.error('❌ Error importing real data:', error);
  } finally {
    await prisma.$disconnect();
  }
}

importRealData(); 