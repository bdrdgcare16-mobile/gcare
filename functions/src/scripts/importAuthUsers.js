const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const serviceAccount = require('../../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();

const usersFilePath = path.join(__dirname, '../../users.json');
const users = JSON.parse(fs.readFileSync(usersFilePath, 'utf8'));

async function importUsers() {
  let created = 0;
  let skipped = 0;
  let failed = 0;

  for (const user of users) {
    const email = user.email?.trim();
    const password = user.password?.trim();

    if (!email || !password) {
      console.log(`Skipped invalid row: ${JSON.stringify(user)}`);
      skipped++;
      continue;
    }

    try {
      await auth.getUserByEmail(email);
      console.log(`Skipped existing user: ${email}`);
      skipped++;
    } catch (err) {
      if (err.code === 'auth/user-not-found') {
        try {
          const createdUser = await auth.createUser({
            email,
            password,
          });
          console.log(`Created user: ${createdUser.email}`);
          created++;
        } catch (createErr) {
          console.log(`Failed to create ${email}: ${createErr.message}`);
          failed++;
        }
      } else {
        console.log(`Failed to check ${email}: ${err.message}`);
        failed++;
      }
    }
  }

  console.log('\nDone');
  console.log(`Created: ${created}`);
  console.log(`Skipped: ${skipped}`);
  console.log(`Failed: ${failed}`);
}

importUsers().catch(console.error);