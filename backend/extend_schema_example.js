const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

// Example of how to add new employee details with extended schema
const extendedEmployeeData = [
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
    // NEW EXTENDED FIELDS
    address: '123 Main Street, Chennai, Tamil Nadu',
    emergencyContact: '9876543210',
    emergencyContactName: 'John Doe',
    bloodGroup: 'O+',
    dateOfBirth: '1990-05-15',
    maritalStatus: 'Married',
    nationality: 'Indian',
    education: 'Bachelor of Social Work',
    experience: '5 years',
    salary: 45000,
    bankAccount: '1234567890',
    bankName: 'State Bank of India',
    ifscCode: 'SBIN0001234',
    panNumber: 'ABCDE1234F',
    aadharNumber: '123456789012',
    contractEndDate: '2025-01-15',
    leaveBalance: 15,
    skills: JSON.stringify(['Community Development', 'Social Work', 'Field Coordination']),
    languages: JSON.stringify(['English', 'Tamil', 'Hindi']),
    certifications: JSON.stringify(['Social Work Certification', 'Community Development Training']),
    achievements: JSON.stringify(['Best Field Worker 2023', 'Community Excellence Award 2024']),
    notes: 'Excellent team player with strong community outreach skills',
    password: 'employee123'
  }
];

async function showHowToExtendSchema() {
  console.log('🔧 HOW TO ADD EXTRA EMPLOYEE DETAILS TO DATABASE');
  console.log('================================================');
  console.log('');
  
  console.log('📋 STEP 1: Update Prisma Schema (prisma/schema.prisma)');
  console.log('Add these new fields to the User model:');
  console.log('');
  console.log('model User {');
  console.log('  id           Int       @id @default(autoincrement())');
  console.log('  email        String    @unique');
  console.log('  password     String');
  console.log('  name         String');
  console.log('  role         Role');
  console.log('  phoneNumber  String?');
  console.log('  designation  String?');
  console.log('  shiftTiming  String?');
  console.log('  gender       String?');
  console.log('  department   String?');
  console.log('  reportingTo  String?');
  console.log('  dateOfJoining DateTime?');
  console.log('  // ADD THESE NEW FIELDS:');
  console.log('  address      String?');
  console.log('  emergencyContact String?');
  console.log('  emergencyContactName String?');
  console.log('  bloodGroup   String?');
  console.log('  dateOfBirth  DateTime?');
  console.log('  maritalStatus String?');
  console.log('  nationality  String?');
  console.log('  education    String?');
  console.log('  experience   String?');
  console.log('  salary       Int?');
  console.log('  bankAccount  String?');
  console.log('  bankName     String?');
  console.log('  ifscCode     String?');
  console.log('  panNumber    String?');
  console.log('  aadharNumber String?');
  console.log('  contractEndDate DateTime?');
  console.log('  leaveBalance Int?');
  console.log('  skills       String? // JSON string');
  console.log('  languages    String? // JSON string');
  console.log('  certifications String? // JSON string');
  console.log('  achievements String? // JSON string');
  console.log('  notes        String?');
  console.log('  createdAt    DateTime  @default(now())');
  console.log('  updatedAt    DateTime  @updatedAt');
  console.log('}');
  console.log('');
  
  console.log('📋 STEP 2: Run Database Migration');
  console.log('npx prisma migrate dev --name add_extra_employee_fields');
  console.log('');
  
  console.log('📋 STEP 3: Update Seed Script');
  console.log('Add the new fields to your seed data:');
  console.log('');
  
  console.log('Example extended employee data:');
  extendedEmployeeData.forEach(emp => {
    console.log(`👤 ${emp.name}:`);
    console.log(`   Address: ${emp.address}`);
    console.log(`   Emergency Contact: ${emp.emergencyContact}`);
    console.log(`   Blood Group: ${emp.bloodGroup}`);
    console.log(`   Salary: ₹${emp.salary}`);
    console.log(`   Education: ${emp.education}`);
    console.log(`   Experience: ${emp.experience}`);
    console.log(`   Skills: ${emp.skills}`);
    console.log(`   Languages: ${emp.languages}`);
    console.log(`   Bank Details: ${emp.bankName} - ${emp.bankAccount}`);
    console.log(`   PAN: ${emp.panNumber}`);
    console.log(`   Aadhar: ${emp.aadharNumber}`);
    console.log('');
  });
  
  console.log('📋 STEP 4: Update Flutter App');
  console.log('1. Update profile_screen.dart to show new fields');
  console.log('2. Add new variables for extra details');
  console.log('3. Update _loadUserData() method');
  console.log('4. Add new UI widgets to display extra information');
  console.log('');
  
  console.log('📋 STEP 5: Run Seed Script');
  console.log('npx prisma db seed');
  console.log('');
  
  console.log('🎯 BENEFITS OF EXTENDING SCHEMA:');
  console.log('================================');
  console.log('✅ More detailed employee profiles');
  console.log('✅ Better HR management');
  console.log('✅ Payroll integration');
  console.log('✅ Leave management');
  console.log('✅ Skills and certifications tracking');
  console.log('✅ Emergency contact information');
  console.log('✅ Bank details for salary processing');
  console.log('✅ Performance tracking');
  console.log('');
  
  console.log('💡 TIP: You can add fields gradually as needed!');
  console.log('   Start with essential fields and add more later.');
  console.log('   Each migration is safe and won\'t affect existing data.');
}

// Function to show current database status
async function showCurrentStatus() {
  try {
    console.log('📊 CURRENT DATABASE STATUS:');
    console.log('============================');
    
    const userCount = await prisma.user.count();
    console.log(`Total Users in Database: ${userCount}`);
    
    const adminCount = await prisma.user.count({
      where: { role: 'ADMIN' }
    });
    console.log(`Admin Users: ${adminCount}`);
    
    const employeeCount = await prisma.user.count({
      where: { role: 'EMPLOYEE' }
    });
    console.log(`Employee Users: ${employeeCount}`);
    
    console.log('');
    console.log('✅ Database is working and has real employee data!');
    console.log('🔧 Ready to extend with additional fields when needed.');
    
  } catch (error) {
    console.error('❌ Error checking database:', error);
  } finally {
    await prisma.$disconnect();
  }
}

async function main() {
  await showCurrentStatus();
  console.log('');
  showHowToExtendSchema();
}

main(); 