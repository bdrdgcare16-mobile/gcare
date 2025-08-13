const { PrismaClient, Role } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function addEmployee(name, email, password) {
  try {
    // Check if user already exists
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      console.log(`❌ User with email ${email} already exists`);
      return;
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create employee
    const employee = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        name,
        role: Role.EMPLOYEE,
      },
    });

    console.log(`✅ Employee created successfully:`);
    console.log(`   Name: ${employee.name}`);
    console.log(`   Email: ${employee.email}`);
    console.log(`   Password: ${password}`);
    console.log(`   Role: ${employee.role}`);
    console.log('---');

  } catch (error) {
    console.error('❌ Error creating employee:', error);
  }
}

async function listEmployees() {
  try {
    const employees = await prisma.user.findMany({
      where: { role: Role.EMPLOYEE },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        createdAt: true,
      },
    });

    console.log('📋 Current Employees:');
    employees.forEach((emp, index) => {
      console.log(`${index + 1}. ${emp.name} (${emp.email}) - Created: ${emp.createdAt.toDateString()}`);
    });
    console.log('---');

  } catch (error) {
    console.error('❌ Error listing employees:', error);
  }
}

// Example usage
async function main() {
  console.log('🚀 Employee Management Script\n');

  // List current employees
  await listEmployees();

  // Add some example employees
  await addEmployee('John Doe', 'john.doe@company.com', 'john123');
  await addEmployee('Jane Smith', 'jane.smith@company.com', 'jane123');
  await addEmployee('Mike Johnson', 'mike.johnson@company.com', 'mike123');

  // List employees again
  await listEmployees();

  await prisma.$disconnect();
}

// Run the script
main().catch(console.error); 