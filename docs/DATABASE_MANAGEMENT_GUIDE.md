# 🗄️ DATABASE MANAGEMENT GUIDE
## How to Open and Manage Your Database in Future

---

## 🚀 **Quick Start - Open Database**

### **Option 1: Double-click the batch file**
- **Double-click**: `OPEN_DATABASE.bat`
- **Opens**: Visual interface at `http://localhost:5555`

### **Option 2: Command line**
```bash
cd backend
npx prisma studio
```

---

## 📊 **What You Can Do in the Visual Interface**

### **1. View All Data**
- **User Table**: See all employees and admins
- **Announcement Table**: View company announcements
- **LeaveType Table**: See leave types
- **All other tables**: Attendance, Tasks, etc.

### **2. Add New Employee**
1. Click on **"User"** table
2. Click **"Add record"** button
3. Fill in the details:
   - **email**: `newemployee@district.gov.in`
   - **password**: `Employee@123` (hashed)
   - **name**: `New Employee Name`
   - **role**: `EMPLOYEE`
   - **phoneNumber**: `9876543210`
   - **designation**: `District Program Officer`
   - **shiftTiming**: `9:00 AM - 6:00 PM`
   - **gender**: `Male` or `Female`
   - **department**: `District Program Management`
   - **reportingTo**: `HR Manager`
   - **dateOfJoining**: `2024-01-15`
4. Click **"Save 1 change"**

### **3. Edit Existing Employee**
1. Click on **"User"** table
2. Find the employee you want to edit
3. Click on their record
4. Make changes
5. Click **"Save 1 change"**

### **4. Delete Employee**
1. Click on **"User"** table
2. Find the employee you want to delete
3. Click the **trash icon** (🗑️)
4. Confirm deletion

---

## 💻 **Command Line Methods**

### **View All Employees**
```bash
cd backend
node view_employees.js
```

### **Add New Employee**
```bash
cd backend
node add_single_employee.js
```
(First edit the file to change employee details)

### **View Database Status**
```bash
cd backend
node view_database.js
```

---

## 🔑 **Current Login Credentials**

### **Admin Users:**
- **System Admin**: `admin@techcorp.com` / `Admin@123`
- **HR Manager**: `hr@techcorp.com` / `Admin@123`

### **Real Employees (19 total):**
- **A.Baby Reeta**: `babyreeta16@gmail.com` / `Employee@123`
- **A.Mahalakshmi**: `keshaw390@gmail.com` / `Employee@123`
- **S.Manikandan**: `Manikandansekar1012@gmail.com` / `Employee@123`
- And 16 more...

---

## 📁 **Database Files Location**

### **Main Database File:**
```
backend/prisma/dev.db
```

### **Backup Database:**
```
backend/prisma/backup.db
```

---

## 🔄 **Backup and Restore**

### **Create Backup**
```bash
cd backend
cp prisma/dev.db prisma/backup_$(date +%Y%m%d_%H%M%S).db
```

### **Restore from Backup**
```bash
cd backend
cp prisma/backup_20241201_143022.db prisma/dev.db
```

---

## ⚠️ **Important Tips**

1. **Always backup** before making major changes
2. **Use unique email addresses** for each employee
3. **Test login** after adding new employees
4. **Default password** for new employees: `Employee@123`
5. **Keep records** of all changes made

---

## 🎯 **Quick Reference Commands**

| Action | Command |
|--------|---------|
| Open visual interface | `npx prisma studio` |
| View all employees | `node view_employees.js` |
| Add new employee | `node add_single_employee.js` |
| View database | `node view_database.js` |
| Reset database | `npx prisma migrate reset --force` |
| Backup database | `cp prisma/dev.db prisma/backup.db` |

---

## 🚀 **Ready to Manage Your Database!**

Now you have all the tools to manage your district program management system's database easily. The visual interface makes it simple to add, edit, and manage employees! 