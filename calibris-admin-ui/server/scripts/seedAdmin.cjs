const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');

const usersPath = path.join(__dirname, '..', 'data', 'users.json');

// Get password from environment variable or prompt
const password = process.env.ADMIN_PASSWORD || 'CHANGE_THIS_PASSWORD';
if (password === 'CHANGE_THIS_PASSWORD') {
  console.error('⚠️ ERROR: Set ADMIN_PASSWORD environment variable before running this script!');
  console.error('Example: ADMIN_PASSWORD=YourSecurePassword123 node server/scripts/seedAdmin.cjs');
  process.exit(1);
}

const hash = bcrypt.hashSync(password, 10);

const admin = {
  id: "admin-1",
  firstName: "Kaviya",
  lastName: "Madhiraju",
  email: "11kaviya11@gmail.com",
  passwordHash: hash,
  role: "admin",
  createdAt: new Date().toISOString()
};

fs.mkdirSync(path.join(__dirname, '..', 'data'), { recursive: true });
fs.writeFileSync(usersPath, JSON.stringify([admin], null, 2), 'utf8');
console.log('✅ Wrote admin user to', usersPath);
console.log('✅ Admin password has been hashed and stored securely');
