# 📝 MANUAL DATA MANAGEMENT GUIDE
## How to Add New Employees and Manage Real Database

---

## 🎯 **Quick Methods to Add New Employees**

### **Method 1: Using the Add Employee Script (Recommended)**
```bash
cd backend
node add_new_employee.js
```

### **Method 2: Direct Database Access**
```bash
cd backend
npx prisma studio
```

### **Method 3: Manual SQL Commands**
```bash
cd backend
npx prisma db seed
```

---

## 🔧 **Step-by-Step Guide for Adding New Employees**

### **Step 1: Prepare Employee Information**
Before adding, collect this information:
- **Full Name** (e.g., "R. Kumar")
- **Email Address** (e.g., "rkumar@district.gov.in")
- **Phone Number** (e.g., "9876543210")
- **Designation** (e.g., "District Program Officer")
- **Gender** (Male/Female)
- **District** (e.g., "Chennai")
- **Date of Joining** (e.g., "2024-01-15")

### **Step 2: Choose Your Method**

---

## 📋 **Method 1: Using Add Employee Script**

### **Step 2.1: Edit the Script**
Open `backend/add_new_employee.js` and add your new employee:

```javascript
// Add this to the employees array
{
  name: 'R. Kumar',
  email: 'rkumar@district.gov.in',
  phoneNumber: '9876543210',
  designation: 'District Program Officer',
  gender: 'Male',
  location: 'Chennai',
  dateOfJoining: new Date('2024-01-15')
}
```

### **Step 2.2: Run the Script**
```bash
cd backend
node add_new_employee.js
```

---

## 🗄️ **Method 2: Using Prisma Studio (Visual Interface)**

### **Step 2.1: Open Prisma Studio**
```bash
cd backend
npx prisma studio
```

### **Step 2.2: Add Employee Manually**
1. Click on "User" table
2. Click "Add record"
3. Fill in the details:
   - **email**: `rkumar@district.gov.in`
   - **password**: `Employee@123` (hashed)
   - **name**: `R. Kumar`
   - **role**: `EMPLOYEE`
   - **phoneNumber**: `9876543210`
   - **designation**: `District Program Officer`
   - **shiftTiming**: `9:00 AM - 6:00 PM`
   - **gender**: `Male`
   - **department**: `District Program Management`
   - **reportingTo**: `HR Manager`
   - **dateOfJoining**: `2024-01-15`

### **Step 2.3: Save the Record**

---

## 💻 **Method 3: Direct Database Commands**

### **Step 3.1: Create a Custom Script**
Create `backend/add_single_employee.js`:

```javascript
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function addSingleEmployee() {
  try {
    // Hash password
    const employeePassword = await bcrypt.hash('Employee@123', 12);
    
    // Add new employee
    const newEmployee = await prisma.user.create({
      data: {
        email: 'rkumar@district.gov.in',
        password: employeePassword,
        name: 'R. Kumar',
        role: 'EMPLOYEE',
        phoneNumber: '9876543210',
        designation: 'District Program Officer',
        shiftTiming: '9:00 AM - 6:00 PM',
        gender: 'Male',
        department: 'District Program Management',
        reportingTo: 'HR Manager',
        dateOfJoining: new Date('2024-01-15')
      }
    });
    
    console.log('✅ New employee added successfully!');
    console.log('Employee ID:', newEmployee.id);
    console.log('Email:', newEmployee.email);
    console.log('Password: Employee@123');
    
  } catch (error) {
    console.error('❌ Error adding employee:', error);
  } finally {
    await prisma.$disconnect();
  }
}

addSingleEmployee();
```

### **Step 3.2: Run the Script**
```bash
cd backend
node add_single_employee.js
```

---

## 🔄 **How to Update Existing Employees**

### **Method 1: Using Prisma Studio**
1. Open Prisma Studio: `npx prisma studio`
2. Find the employee in the User table
3. Click on the record to edit
4. Update the fields
5. Save changes

### **Method 2: Using Update Script**
Create `backend/update_employee.js`:

```javascript
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function updateEmployee() {
  try {
    const updatedEmployee = await prisma.user.update({
      where: { email: 'babyreeta16@gmail.com' },
      data: {
        phoneNumber: '9843194675', // New phone number
        designation: 'Senior District Program Officer', // Promotion
        department: 'Advanced District Management'
      }
    });
    
    console.log('✅ Employee updated successfully!');
    console.log('Updated:', updatedEmployee.name);
    
  } catch (error) {
    console.error('❌ Error updating employee:', error);
  } finally {
    await prisma.$disconnect();
  }
}

updateEmployee();
```

---

## 🗑️ **How to Remove Employees**

### **Method 1: Using Prisma Studio**
1. Open Prisma Studio: `npx prisma studio`
2. Find the employee in the User table
3. Click the delete button (trash icon)
4. Confirm deletion

### **Method 2: Using Delete Script**
Create `backend/delete_employee.js`:

```javascript
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function deleteEmployee() {
  try {
    const deletedEmployee = await prisma.user.delete({
      where: { email: 'employee@to.delete.com' }
    });
    
    console.log('✅ Employee deleted successfully!');
    console.log('Deleted:', deletedEmployee.name);
    
  } catch (error) {
    console.error('❌ Error deleting employee:', error);
  } finally {
    await prisma.$disconnect();
  }
}

deleteEmployee();
```

---

## 📊 **How to View All Employees**

### **Method 1: Using View Script**
```bash
cd backend
node view_database.js
```

### **Method 2: Using Prisma Studio**
```bash
cd backend
npx prisma studio
```

### **Method 3: Custom Query Script**
Create `backend/view_employees.js`:

```javascript
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function viewEmployees() {
  try {
    const employees = await prisma.user.findMany({
      where: { role: 'EMPLOYEE' },
      select: {
        id: true,
        name: true,
        email: true,
        phoneNumber: true,
        designation: true,
        department: true,
        dateOfJoining: true
      },
      orderBy: { name: 'asc' }
    });
    
    console.log('👥 All Employees:');
    console.log('================');
    
    employees.forEach((emp, index) => {
      console.log(`${index + 1}. ${emp.name}`);
      console.log(`   Email: ${emp.email}`);
      console.log(`   Phone: ${emp.phoneNumber}`);
      console.log(`   Designation: ${emp.designation}`);
      console.log(`   Department: ${emp.department}`);
      console.log(`   Joined: ${emp.dateOfJoining.toDateString()}`);
      console.log('');
    });
    
  } catch (error) {
    console.error('❌ Error viewing employees:', error);
  } finally {
    await prisma.$disconnect();
  }
}

viewEmployees();
```

---

## 🔐 **Password Management**

### **Reset Employee Password**
Create `backend/reset_password.js`:

```javascript
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function resetPassword() {
  try {
    const newPassword = await bcrypt.hash('NewPassword@123', 12);
    
    const updatedUser = await prisma.user.update({
      where: { email: 'babyreeta16@gmail.com' },
      data: { password: newPassword }
    });
    
    console.log('✅ Password reset successfully!');
    console.log('New password: NewPassword@123');
    console.log('User:', updatedUser.name);
    
  } catch (error) {
    console.error('❌ Error resetting password:', error);
  } finally {
    await prisma.$disconnect();
  }
}

resetPassword();
```

---

## 📁 **Backup and Restore**

### **Backup Database**
```bash
cd backend
cp prisma/dev.db prisma/backup_$(date +%Y%m%d_%H%M%S).db
```

### **Restore Database**
```bash
cd backend
cp prisma/backup_20241201_143022.db prisma/dev.db
```

---

## 🎯 **Quick Reference Commands**

| Action | Command |
|--------|---------|
| View all employees | `node view_database.js` |
| Add new employee | `node add_new_employee.js` |
| Open visual editor | `npx prisma studio` |
| Reset database | `npx prisma migrate reset --force` |
| Backup database | `cp prisma/dev.db prisma/backup.db` |

---

## ⚠️ **Important Notes**

1. **Always backup** before making changes
2. **Use unique email addresses** for each employee
3. **Default password** for new employees: `Employee@123`
4. **Test login** after adding new employees
5. **Keep records** of all changes made

---

## 🚀 **Ready to Manage Your Real Data!**

Now you have all the tools to manually manage your district program management system's employee data. Choose the method that works best for you! 