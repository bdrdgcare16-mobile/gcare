const { db } = require('./config/firebase'); // Make sure this path is correct

async function testFirestore() {
  try {
    const docRef = db.collection('users').doc('test-user');
    await docRef.set({
      name: 'Test User',
      email: 'testuser@example.com',
      role: 'employee',
    });

    console.log('Document written successfully');
  } catch (error) {
    console.error('Error writing document: ', error);
  }
}

testFirestore();
