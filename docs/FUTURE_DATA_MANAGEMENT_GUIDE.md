# 🔧 FUTURE DATA MANAGEMENT GUIDE
## Easy Ways to Add/Manage Data Without Cursor Commands

---

## 🎯 QUICK DATA MANAGEMENT OPTIONS

### Option 1: Visual Database Manager (Easiest)
```bash
# Open Prisma Studio - Visual Database Interface
cd backend
npx prisma studio
```
- **Opens at:** http://localhost:5555
- **What you can do:**
  - Add new employees visually
  - Edit existing data
  - Add tasks, leave requests
  - View all data in tables
  - No coding required!

### Option 2: Simple Script Commands
```bash
# Add new employee
cd backend
node add_new_employee.js

# Add new tasks
node add_simple_tasks.js

# View all employees
node view_employees.js

# Check database status
node view_database.js
```

### Option 3: Manual Database Files
- **Database location:** `backend/prisma/dev.db`
- **Use SQLite Browser** to open and edit directly
- **Download:** https://sqlitebrowser.org/

---

## 📝 STEP-BY-STEP DATA ADDITION

### Adding New Employee
1. **Open Prisma Studio:**
   ```bash
   cd backend
   npx prisma studio
   ```

2. **Click on "User" table**

3. **Click "Add record"**

4. **Fill in details:**
   - Email: newemployee@company.com
   - Password: Employee@123
   - Name: John Doe
   - Role: EMPLOYEE
   - Phone: +1234567890
   - Designation: Software Developer
   - Department: Engineering

5. **Click "Save"**

### Adding New Tasks
1. **In Prisma Studio, click "Task" table**

2. **Click "Add record"**

3. **Fill in details:**
   - User ID: (select employee from dropdown)
   - Title: Complete Project Review
   - Description: Review and approve project deliverables
   - Status: PENDING
   - Due Date: (select future date)
   - Assigned By: 1 (admin ID)

4. **Click "Save"**

### Adding Leave Requests
1. **In Prisma Studio, click "LeaveRequest" table**

2. **Click "Add record"**

3. **Fill in details:**
   - User ID: (select employee)
   - Leave Type ID: 1 (Annual Leave)
   - Start Date: (select start date)
   - End Date: (select end date)
   - Reason: Personal vacation
   - Status: PENDING

4. **Click "Save"**

---

## 🔄 COMMON DATA MANAGEMENT TASKS

### View All Employees
```bash
cd backend
node view_employees.js
```

### Add Sample Data
```bash
cd backend
node add_simple_tasks.js
```

### Reset Database
```bash
cd backend
npx prisma migrate reset
node setup_real_office_data_fixed.js
```

### Backup Database
```bash
# Copy the database file
copy backend\prisma\dev.db backend\prisma\backup_$(date).db
```

---

## 📊 DATABASE STRUCTURE

### User Table (Employees)
- **id:** Auto-generated
- **email:** Unique email address
- **password:** Hashed password
- **name:** Full name
- **role:** ADMIN or EMPLOYEE
- **phoneNumber:** Contact number
- **designation:** Job title
- **department:** Work department
- **dateOfJoining:** Hire date

### Task Table
- **id:** Auto-generated
- **userId:** Employee ID
- **title:** Task title
- **description:** Task details
- **status:** PENDING, IN_PROGRESS, COMPLETED
- **dueDate:** Deadline
- **assignedBy:** Admin ID

### LeaveRequest Table
- **id:** Auto-generated
- **userId:** Employee ID
- **leaveTypeId:** Type of leave
- **startDate:** Leave start
- **endDate:** Leave end
- **reason:** Leave reason
- **status:** PENDING, APPROVED, REJECTED

---

## 🚨 TROUBLESHOOTING

### If Prisma Studio Won't Open
```bash
cd backend
npx prisma generate
npx prisma studio
```

### If Database is Corrupted
```bash
cd backend
npx prisma migrate reset
node setup_real_office_data_fixed.js
```

### If Can't Add Data
```bash
cd backend
npx prisma db push
npx prisma generate
```

---

## 💡 PRO TIPS

### 1. Regular Backups
- Copy `dev.db` file weekly
- Keep backup before major changes

### 2. Use Prisma Studio for Everything
- Most user-friendly option
- No command line needed
- Visual interface

### 3. Test Data First
- Add test data in Prisma Studio
- Verify it works in app
- Then add real data

### 4. Keep Credentials Safe
- Store login details securely
- Use strong passwords
- Document admin accounts

---

## 🎯 QUICK REFERENCE

### Essential Commands
```bash
# Start visual database manager
cd backend && npx prisma studio

# Add new employee
cd backend && node add_new_employee.js

# View all data
cd backend && node view_database.js

# Reset everything
cd backend && npx prisma migrate reset && node setup_real_office_data_fixed.js
```

### Database Location
- **File:** `backend/prisma/dev.db`
- **Visual Tool:** http://localhost:5555
- **Backup:** Copy `dev.db` file

### Default Credentials
- **Employee:** keshaw390@gmail.com / Employee@123
- **Admin:** admin@company.com / Admin@123

---

## 🎉 SUCCESS!

You now have multiple easy ways to manage your app's data:
- ✅ Visual database manager (easiest)
- ✅ Simple script commands
- ✅ Manual database editing
- ✅ Regular backup system

**No more cursor commands needed!** 🚀 