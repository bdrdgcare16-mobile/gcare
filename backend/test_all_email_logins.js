const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

// All 23 real users from your database
const allUsers = [
  // ADMIN Users (3)
  { email: 'admin@techcorp.com', password: 'Admin@123', role: 'ADMIN', name: 'Admin User' },
  { email: 'vivek.saxena@company.com', password: 'Admin@123', role: 'ADMIN', name: 'Vivek Saxena' },
  { email: 'shweta.agarwal@company.com', password: 'Admin@123', role: 'ADMIN', name: 'Shweta Agarwal' },
  
  // EMPLOYEE Users (20)
  { email: 'keshaw390@gmail.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Keshav Kumar' },
  { email: 'suryap1209@gmail.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Surya Prakash' },
  { email: 'priya.sharma@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Priya Sharma' },
  { email: 'rahul.singh@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Rahul Singh' },
  { email: 'amit.patel@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Amit Patel' },
  { email: 'neha.gupta@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Neha Gupta' },
  { email: 'rajesh.kumar@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Rajesh Kumar' },
  { email: 'anjali.singh@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Anjali Singh' },
  { email: 'vikram.malhotra@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Vikram Malhotra' },
  { email: 'pooja.sharma@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Pooja Sharma' },
  { email: 'arun.verma@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Arun Verma' },
  { email: 'meera.kapoor@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Meera Kapoor' },
  { email: 'sandeep.reddy@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Sandeep Reddy' },
  { email: 'kavita.joshi@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Kavita Joshi' },
  { email: 'rohit.mehta@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Rohit Mehta' },
  { email: 'sunita.iyer@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Sunita Iyer' },
  { email: 'manoj.tiwari@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Manoj Tiwari' },
  { email: 'deepika.nair@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Deepika Nair' },
  { email: 'aditya.chopra@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Aditya Chopra' },
  { email: 'rashmi.desai@company.com', password: 'Employee@123', role: 'EMPLOYEE', name: 'Rashmi Desai' }
];

async function testLogin(email, password, expectedRole, name) {
  try {
    console.log(`🔐 Testing: ${email} (${name})`);
    
    const response = await axios.post(`${BASE_URL}/auth/login`, {
      email: email,
      password: password
    });

    if (response.data.success) {
      const userRole = response.data.user.role;
      const userName = response.data.user.name;
      
      if (userRole === expectedRole) {
        console.log(`✅ SUCCESS: ${email} - Role: ${userRole} - Name: ${userName}`);
        return { success: true, email, role: userRole, name: userName };
      } else {
        console.log(`❌ ROLE MISMATCH: Expected ${expectedRole}, got ${userRole}`);
        return { success: false, email, error: 'Role mismatch' };
      }
    } else {
      console.log(`❌ LOGIN FAILED: ${email} - ${response.data.message}`);
      return { success: false, email, error: response.data.message };
    }
  } catch (error) {
    console.log(`❌ ERROR: ${email} - ${error.response?.data?.message || error.message}`);
    return { success: false, email, error: error.response?.data?.message || error.message };
  }
}

async function testAllLogins() {
  console.log('🚀 TESTING ALL 23 EMAIL LOGINS');
  console.log('================================');
  console.log('');

  const results = [];
  let successCount = 0;
  let failureCount = 0;

  for (const user of allUsers) {
    const result = await testLogin(user.email, user.password, user.role, user.name);
    results.push(result);
    
    if (result.success) {
      successCount++;
    } else {
      failureCount++;
    }
    
    // Small delay between requests
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  console.log('');
  console.log('📊 TEST RESULTS SUMMARY');
  console.log('========================');
  console.log(`✅ Successful Logins: ${successCount}/23`);
  console.log(`❌ Failed Logins: ${failureCount}/23`);
  console.log(`📈 Success Rate: ${((successCount/23)*100).toFixed(1)}%`);
  console.log('');

  if (failureCount === 0) {
    console.log('🎉 ALL 23 EMAIL LOGINS ARE WORKING PERFECTLY!');
    console.log('🚀 Your app is ready for submission!');
  } else {
    console.log('⚠️  Some logins failed. Check the errors above.');
  }

  console.log('');
  console.log('🔐 LOGIN INSTRUCTIONS FOR DEMO:');
  console.log('================================');
  console.log('📋 Passwords:');
  console.log('   • All Employees: Employee@123');
  console.log('   • All Admins: Admin@123');
  console.log('');
  console.log('💡 Quick Test Examples:');
  console.log('   • suryap1209@gmail.com / Employee@123');
  console.log('   • admin@techcorp.com / Admin@123');
  console.log('   • pooja.sharma@company.com / Employee@123');
}

// Check if server is running first
async function checkServer() {
  try {
    await axios.get(`${BASE_URL}/health`);
    console.log('✅ Backend server is running on port 3000');
    return true;
  } catch (error) {
    console.log('❌ Backend server is not running on port 3000');
    console.log('Please start the server first: npm start');
    return false;
  }
}

async function main() {
  const serverRunning = await checkServer();
  if (!serverRunning) {
    return;
  }
  
  console.log('');
  await testAllLogins();
}

main().catch(console.error); 