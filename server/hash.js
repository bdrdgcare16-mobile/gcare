const bcrypt = require('bcryptjs');
const password = 'admin@123'; // unga prefer panna password inga type pannunga
bcrypt.hash(password, 10).then(hash => {
  console.log('Hashed password:', hash);
});
