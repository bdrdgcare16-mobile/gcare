const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

// Example of how to add extra employee details
const extraEmployeeDetails = [
  {
    email: 'babyreeta16@gmail.com',
    extraDetails: {
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
      joiningDate: '2023-01-15',
      contractEndDate: '2025-01-15',
      leaveBalance: 15,
      skills: ['Community Development', 'Social Work', 'Field Coordination'],
      languages: ['English', 'Tamil', 'Hindi'],
      certifications: ['Social Work Certification', 'Community Development Training'],
      achievements: ['Best Field Worker 2023', 'Community Excellence Award 2024'],
      notes: 'Excellent team player with strong community outreach skills'
    }
  },
  {
    email: 'keshaw390@gmail.com',
    extraDetails: {
      address: '456 Park Avenue, Madurai, Tamil Nadu',
      emergencyContact: '9876543211',
      emergencyContactName: 'Jane Smith',
      bloodGroup: 'A+',
      dateOfBirth: '1988-08-20',
      maritalStatus: 'Single',
      nationality: 'Indian',
      education: 'Master of Social Work',
      experience: '7 years',
      salary: 52000,
      bankAccount: '1234567891',
      bankName: 'HDFC Bank',
      ifscCode: 'HDFC0001234',
      panNumber: 'BCDEF1234G',
      aadharNumber: '123456789013',
      joiningDate: '2023-02-01',
      contractEndDate: '2025-02-01',
      leaveBalance: 12,
      skills: ['Field Coordination', 'Team Management', 'Project Planning'],
      languages: ['English', 'Tamil', 'Telugu'],
      certifications: ['Project Management Certification', 'Leadership Training'],
      achievements: ['Outstanding Coordinator 2023', 'Team Leadership Award 2024'],
      notes: 'Strong leadership skills with excellent project management capabilities'
    }
  }
];

async function addExtraEmployeeDetails() {
  try {
    console.log('🚀 Adding extra employee details...');
    
    for (const detail of extraEmployeeDetails) {
      // Find the employee by email
      const employee = await prisma.user.findUnique({
        where: { email: detail.email }
      });
      
      if (employee) {
        console.log(`✅ Found employee: ${employee.name}`);
        console.log('📋 Extra details that could be added:');
        console.log('   - Address:', detail.extraDetails.address);
        console.log('   - Emergency Contact:', detail.extraDetails.emergencyContact);
        console.log('   - Blood Group:', detail.extraDetails.bloodGroup);
        console.log('   - Salary:', detail.extraDetails.salary);
        console.log('   - Skills:', detail.extraDetails.skills.join(', '));
        console.log('   - Languages:', detail.extraDetails.languages.join(', '));
        console.log('   - Certifications:', detail.extraDetails.certifications.join(', '));
        console.log('   - Achievements:', detail.extraDetails.achievements.join(', '));
        console.log('');
      }
    }
    
    console.log('💡 To add these extra details, you would need to:');
    console.log('1. Update the Prisma schema (prisma/schema.prisma)');
    console.log('2. Add new fields to the User model');
    console.log('3. Run database migration');
    console.log('4. Update the seed script');
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Function to show current database schema
async function showCurrentSchema() {
  try {
    console.log('📊 Current Database Schema:');
    console.log('============================');
    
    const users = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        phoneNumber: true,
        designation: true,
        gender: true,
        department: true,
        shiftTiming: true,
        reportingTo: true,
        dateOfJoining: true,
        createdAt: true,
        updatedAt: true
      }
    });
    
    console.log(`Total Users: ${users.length}`);
    console.log('');
    
    users.forEach(user => {
      console.log(`👤 ${user.name} (${user.email})`);
      console.log(`   Role: ${user.role}`);
      console.log(`   Designation: ${user.designation}`);
      console.log(`   Department: ${user.department}`);
      console.log(`   Phone: ${user.phoneNumber}`);
      console.log(`   Gender: ${user.gender}`);
      console.log(`   Reporting To: ${user.reportingTo}`);
      console.log(`   Date of Joining: ${user.dateOfJoining}`);
      console.log('');
    });
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Function to show how to extend schema
function showSchemaExtension() {
  console.log('🔧 How to Extend Database Schema:');
  console.log('==================================');
  console.log('');
  console.log('1. Edit prisma/schema.prisma and add new fields:');
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
  console.log('  // NEW FIELDS YOU CAN ADD:');
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
  console.log('2. Run migration: npx prisma migrate dev --name add_extra_fields');
  console.log('3. Update seed script with new data');
  console.log('4. Run: npx prisma db seed');
}

// Run the functions
async function main() {
  console.log('🎯 Employee Database Management');
  console.log('================================');
  console.log('');
  
  await showCurrentSchema();
  console.log('');
  await addExtraEmployeeDetails();
  console.log('');
  showSchemaExtension();
}

main(); 