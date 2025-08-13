const axios = require('axios');

const API_BASE_URL = 'http://localhost:3000';

// Test data for new employee registration
const newEmployee = {
  name: 'Test Employee',
  email: 'test.employee@nishali.com',
  password: 'employee123',
  role: 'EMPLOYEE',
  phoneNumber: '9876543210',
  designation: 'Test Developer',
  department: 'IT Department',
  gender: 'Male',
  shiftTiming: '9:00 AM - 6:00 PM',
  reportingTo: 'IT Manager',
  dateOfJoining: new Date().toISOString()
};

async function testRegistration() {
  try {
    console.log('🚀 Testing Automatic User Registration');
    console.log('=====================================');
    console.log('');
    
    console.log('📋 Registering new employee:');
    console.log(`   Name: ${newEmployee.name}`);
    console.log(`   Email: ${newEmployee.email}`);
    console.log(`   Designation: ${newEmployee.designation}`);
    console.log(`   Department: ${newEmployee.department}`);
    console.log(`   Phone: ${newEmployee.phoneNumber}`);
    console.log('');
    
    // Register the new employee
    const response = await axios.post(`${API_BASE_URL}/auth/register`, newEmployee);
    
    console.log('✅ Registration successful!');
    console.log('📊 Response:', response.data);
    console.log('');
    
    console.log('🎯 What happened:');
    console.log('   1. User data sent to backend');
    console.log('   2. Data validated');
    console.log('   3. Password hashed');
    console.log('   4. User saved to database');
    console.log('   5. Response sent back');
    console.log('');
    
    console.log('💡 Now you can:');
    console.log('   - Login with: test.employee@nishali.com / employee123');
    console.log('   - View user in database');
    console.log('   - See complete profile with all details');
    
  } catch (error) {
    console.error('❌ Registration failed:');
    console.error('Error message:', error.message);
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    }
    console.error('Full error:', error);
  }
}

// Function to show how to add more fields in future
function showFutureEnhancements() {
  console.log('');
  console.log('🔧 Future Enhancements:');
  console.log('=======================');
  console.log('');
  console.log('You can easily add more fields:');
  console.log('');
  console.log('1. Update backend schema (prisma/schema.prisma):');
  console.log('   - Add salary field');
  console.log('   - Add address field');
  console.log('   - Add emergency contact');
  console.log('   - Add bank details');
  console.log('');
  console.log('2. Update registration endpoint:');
  console.log('   - Add new fields to req.body');
  console.log('   - Include in user creation');
  console.log('');
  console.log('3. Update Flutter app:');
  console.log('   - Add new form fields');
  console.log('   - Send data to backend');
  console.log('');
  console.log('4. All new registrations will automatically include the new fields!');
}

// Run the test
async function main() {
  await testRegistration();
  showFutureEnhancements();
}

main(); 