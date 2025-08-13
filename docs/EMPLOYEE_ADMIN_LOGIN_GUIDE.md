# 🔐 EMPLOYEE & ADMIN LOGIN CREDENTIALS GUIDE

## ✅ **YOUR LOGIN SYSTEM IS READY!**

Your Flutter app has a complete authentication system with both employee and admin login capabilities.

---

## 🎯 **QUICK START - TEST LOGIN NOW**

### **Option 1: Use Existing Real Users (23 Users)**
Your database already has 23 real users with working credentials:

#### 👑 **ADMIN Users (3):**
- **Email:** `admin@techcorp.com` | **Password:** `Admin@123`
- **Email:** `vivek.saxena@company.com` | **Password:** `Admin@123`
- **Email:** `shweta.agarwal@company.com` | **Password:** `Admin@123`

#### 👥 **EMPLOYEE Users (20):**
- **Email:** `keshaw390@gmail.com` | **Password:** `Employee@123`
- **Email:** `suryap1209@gmail.com` | **Password:** `Employee@123`
- **Email:** `priya.sharma@company.com` | **Password:** `Employee@123`
- **Email:** `rahul.singh@company.com` | **Password:** `Employee@123`
- **Email:** `amit.patel@company.com` | **Password:** `Employee@123`
- **Email:** `neha.gupta@company.com` | **Password:** `Employee@123`
- **Email:** `rajesh.kumar@company.com` | **Password:** `Employee@123`
- **Email:** `anjali.singh@company.com` | **Password:** `Employee@123`
- **Email:** `vikram.malhotra@company.com` | **Password:** `Employee@123`
- **Email:** `pooja.sharma@company.com` | **Password:** `Employee@123`
- **Email:** `arun.verma@company.com` | **Password:** `Employee@123`
- **Email:** `meera.kapoor@company.com` | **Password:** `Employee@123`
- **Email:** `sandeep.reddy@company.com` | **Password:** `Employee@123`
- **Email:** `kavita.joshi@company.com` | **Password:** `Employee@123`
- **Email:** `rohit.mehta@company.com` | **Password:** `Employee@123`
- **Email:** `sunita.iyer@company.com` | **Password:** `Employee@123`
- **Email:** `manoj.tiwari@company.com` | **Password:** `Employee@123`
- **Email:** `deepika.nair@company.com` | **Password:** `Employee@123`
- **Email:** `aditya.chopra@company.com` | **Password:** `Employee@123`
- **Email:** `rashmi.desai@company.com` | **Password:** `Employee@123`

### **Option 2: Add Custom Users**
If you want to add your own custom users, run:

```bash
# Double-click this file:
scripts/ADD_CUSTOM_USERS.bat
```

This will add these custom credentials:

#### 👑 **Custom ADMIN Users:**
- **Email:** `admin@nishali.com` | **Password:** `admin123`
- **Email:** `hr@nishali.com` | **Password:** `hr123`

#### 👥 **Custom EMPLOYEE Users:**
- **Email:** `john.doe@nishali.com` | **Password:** `employee123`
- **Email:** `jane.smith@nishali.com` | **Password:** `employee123`
- **Email:** `mike.johnson@nishali.com` | **Password:** `employee123`
- **Email:** `sarah.wilson@nishali.com` | **Password:** `employee123`

---

## 🚀 **HOW TO TEST LOGIN**

### **Step 1: Start Backend Server**
```bash
cd backend
npm start
```

### **Step 2: Start Flutter App**
```bash
flutter run -d chrome
```

### **Step 3: Login**
1. Open your app at `http://localhost:8080`
2. Enter any email from the list above
3. Enter the corresponding password
4. Click "Login as Employee" or "Login as Admin"
5. You'll be redirected to the appropriate dashboard

---

## 📱 **WHAT HAPPENS AFTER LOGIN**

### **For Employees:**
- ✅ **Profile Page:** Shows real name, phone, designation
- ✅ **Attendance:** Can check-in/check-out
- ✅ **Tasks:** View assigned tasks
- ✅ **Leave:** Request and view leave
- ✅ **Payroll:** View salary information

### **For Admins:**
- ✅ **Admin Dashboard:** Full admin panel
- ✅ **Employee Management:** Add/edit employees
- ✅ **Attendance Reports:** View all attendance
- ✅ **Task Management:** Assign and track tasks
- ✅ **Leave Approval:** Approve/reject leave requests
- ✅ **Payroll Management:** Generate and manage payroll

---

## 🔧 **TECHNICAL DETAILS**

### **Authentication Flow:**
1. **User enters credentials** in Flutter app
2. **API call** to `POST /auth/login`
3. **Backend validates** email/password
4. **JWT token** returned for session
5. **User data** stored in app session
6. **Role-based navigation** to appropriate dashboard

### **Security Features:**
- ✅ **Password hashing** with bcrypt
- ✅ **JWT token authentication**
- ✅ **Role-based access control**
- ✅ **Session management**
- ✅ **Input validation**

### **Database Schema:**
```sql
User {
  id: Int (Primary Key)
  email: String (Unique)
  password: String (Hashed)
  name: String
  role: Role (ADMIN | EMPLOYEE)
  phoneNumber: String
  designation: String
  department: String
  gender: String
  shiftTiming: String
  reportingTo: String
  dateOfJoining: DateTime
  createdAt: DateTime
  updatedAt: DateTime
}
```

---

## 🛠️ **CUSTOMIZATION**

### **Add More Users:**
1. Edit `backend/add_custom_users.js`
2. Add your desired users to the `customUsers` array
3. Run `scripts/ADD_CUSTOM_USERS.bat`

### **Change Passwords:**
1. Update the password in the script
2. Run the script again to update existing users

### **Modify User Details:**
1. Edit the user data in the script
2. Run the script to update the database

---

## 🔍 **TROUBLESHOOTING**

### **Issue 1: "Invalid credentials"**
**Solution:**
- Check if email exists in database
- Use correct password (case-sensitive)
- Try the default passwords: `Employee@123` or `Admin@123`

### **Issue 2: "User not found"**
**Solution:**
- Run `scripts/ADD_CUSTOM_USERS.bat` to add users
- Check if backend server is running
- Verify database connection

### **Issue 3: "Backend connection error"**
**Solution:**
- Start backend server: `cd backend && npm start`
- Check if port 3000 is available
- Verify database is running

### **Issue 4: "Flutter app not loading"**
**Solution:**
- Run `flutter run -d chrome`
- Check if port 8080 is available
- Clear browser cache

---

## ✅ **SUCCESS CRITERIA**

Your login system is working when:
- ✅ **Any valid email** from database can login
- ✅ **Correct password** works for each user
- ✅ **Real user data** displays in profile
- ✅ **Role-based features** work correctly
- ✅ **All functionality** works for each user type

---

## 🎉 **READY TO USE!**

Your employee and admin login system is **fully functional** with:
- **23 real users** ready to login
- **Custom user creation** capability
- **Secure authentication** with JWT
- **Role-based access** control
- **Complete user profiles** with real data

**Start testing now with any of the credentials above!** 🚀 