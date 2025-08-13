# 🚀 HRMS API ENDPOINTS GUIDE

## 📍 **Base URL:** `http://localhost:3000`

---

## 🔐 **AUTHENTICATION ENDPOINTS**

### **Login**
```http
POST /auth/login
Content-Type: application/json

{
  "email": "john.doe@company.com",
  "password": "123456"
}
```

### **Register**
```http
POST /auth/register
Content-Type: application/json

{
  "email": "newuser@company.com",
  "password": "123456",
  "name": "New User",
  "role": "EMPLOYEE",
  "department": "IT",
  "phoneNumber": "+1234567890",
  "designation": "Developer",
  "gender": "Male",
  "shiftTiming": "9:00 AM - 6:00 PM",
  "reportingTo": "Manager",
  "dateOfJoining": "2024-01-15"
}
```

### **Get User Profile**
```http
GET /auth/profile
Authorization: Bearer YOUR_JWT_TOKEN
```

---

## 👥 **USER ENDPOINTS**

### **Get All Users**
```http
GET /users
Authorization: Bearer YOUR_JWT_TOKEN
```

### **Get User by ID**
```http
GET /users/:id
Authorization: Bearer YOUR_JWT_TOKEN
```

### **Update User**
```http
PUT /users/:id
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "name": "Updated Name",
  "department": "HR",
  "phoneNumber": "+9876543210"
}
```

---

## 📊 **ATTENDANCE ENDPOINTS**

### **Check In**
```http
POST /attendance/checkin
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "date": "2024-01-15",
  "checkInTime": "09:00:00"
}
```

### **Check Out**
```http
POST /attendance/checkout
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "date": "2024-01-15",
  "checkOutTime": "18:00:00"
}
```

### **Get Attendance History**
```http
GET /attendance/history
Authorization: Bearer YOUR_JWT_TOKEN
```

### **Get Attendance by Date**
```http
GET /attendance/date/:date
Authorization: Bearer YOUR_JWT_TOKEN
```

### **Get All Attendance (Admin)**
```http
GET /attendance/all
Authorization: Bearer YOUR_JWT_TOKEN
```

---

## 📋 **TASK ENDPOINTS**

### **Create Task**
```http
POST /tasks
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "title": "Complete Project Report",
  "description": "Finish the quarterly project report",
  "priority": "HIGH",
  "dueDate": "2024-01-20",
  "assignedTo": "user@email.com"
}
```

### **Get All Tasks**
```http
GET /tasks
Authorization: Bearer YOUR_JWT_TOKEN
```

### **Get Task by ID**
```http
GET /tasks/:id
Authorization: Bearer YOUR_JWT_TOKEN
```

### **Update Task**
```http
PUT /tasks/:id
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "status": "IN_PROGRESS",
  "progress": 50
}
```

### **Delete Task**
```http
DELETE /tasks/:id
Authorization: Bearer YOUR_JWT_TOKEN
```

---

## 📢 **ANNOUNCEMENT ENDPOINTS**

### **Create Announcement**
```http
POST /announcements
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "title": "Company Meeting",
  "content": "Monthly team meeting on Friday",
  "priority": "MEDIUM",
  "isPinned": true
}
```

### **Get All Announcements**
```http
GET /announcements
Authorization: Bearer YOUR_JWT_TOKEN
```

### **Get Announcement by ID**
```http
GET /announcements/:id
Authorization: Bearer YOUR_JWT_TOKEN
```

### **Update Announcement**
```http
PUT /announcements/:id
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "title": "Updated Meeting",
  "content": "Updated meeting details"
}
```

### **Delete Announcement**
```http
DELETE /announcements/:id
Authorization: Bearer YOUR_JWT_TOKEN
```

---

## 🏖️ **LEAVE ENDPOINTS**

### **Request Leave**
```http
POST /leave/request
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "leaveTypeId": 1,
  "startDate": "2024-01-20",
  "endDate": "2024-01-22",
  "reason": "Personal vacation"
}
```

### **Get Leave Requests**
```http
GET /leave/requests
Authorization: Bearer YOUR_JWT_TOKEN
```

### **Approve/Reject Leave (Admin)**
```http
PUT /leave/:id/approve
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "status": "APPROVED",
  "comments": "Approved"
}
```

---

## 📈 **REPORTS ENDPOINTS**

### **Get Attendance Report**
```http
GET /reports/attendance
Authorization: Bearer YOUR_JWT_TOKEN
```

### **Get Payroll Report**
```http
GET /reports/payroll
Authorization: Bearer YOUR_JWT_TOKEN
```

### **Get Task Report**
```http
GET /reports/tasks
Authorization: Bearer YOUR_JWT_TOKEN
```

---

## 💰 **PAYROLL ENDPOINTS**

### **Get Payroll**
```http
GET /payroll
Authorization: Bearer YOUR_JWT_TOKEN
```

### **Get Payroll by Month**
```http
GET /payroll/month/:month
Authorization: Bearer YOUR_JWT_TOKEN
```

---

## 🔔 **NOTIFICATION ENDPOINTS**

### **Get Notifications**
```http
GET /notifications
Authorization: Bearer YOUR_JWT_TOKEN
```

### **Mark Notification as Read**
```http
PUT /notifications/:id/read
Authorization: Bearer YOUR_JWT_TOKEN
```

---

## 🎛️ **ADMIN ENDPOINTS**

### **Get Dashboard Stats**
```http
GET /admin/dashboard
Authorization: Bearer YOUR_JWT_TOKEN
```

### **Get All Users (Admin)**
```http
GET /admin/users
Authorization: Bearer YOUR_JWT_TOKEN
```

### **Create User (Admin)**
```http
POST /admin/users
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "email": "newemployee@company.com",
  "password": "123456",
  "name": "New Employee",
  "role": "EMPLOYEE",
  "department": "IT"
}
```

---

## 📊 **DASHBOARD ENDPOINTS**

### **Get User Dashboard**
```http
GET /dashboard
Authorization: Bearer YOUR_JWT_TOKEN
```

### **Get Admin Dashboard**
```http
GET /dashboard/admin
Authorization: Bearer YOUR_JWT_TOKEN
```

---

## 🔍 **HEALTH CHECK**

### **Check Server Status**
```http
GET /health
```

---

## 🔑 **AUTHENTICATION**

### **JWT Token Format**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### **Token Response (Login)**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "john.doe@company.com",
    "name": "John Doe",
    "role": "EMPLOYEE",
    "department": "IT"
  }
}
```

---

## 📝 **EXAMPLE USAGE**

### **1. Login and Get Token**
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "john.doe@company.com", "password": "123456"}'
```

### **2. Use Token for API Calls**
```bash
curl -X GET http://localhost:3000/users \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### **3. Check In Attendance**
```bash
curl -X POST http://localhost:3000/attendance/checkin \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"date": "2024-01-15", "checkInTime": "09:00:00"}'
```

---

## 🎯 **QUICK TEST**

### **Test with Postman or curl:**

1. **Login:**
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@company.com", "password": "123456"}'
```

2. **Get Users:**
```bash
curl -X GET http://localhost:3000/users \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

3. **Get Dashboard:**
```bash
curl -X GET http://localhost:3000/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 🚀 **START SERVER**

```bash
cd backend
npm start
```

**Server will run on:** `http://localhost:3000`

---

## 📧 **TEST EMAILS (After adding users)**

- `admin@company.com` / `123456` (ADMIN)
- `manager@company.com` / `123456` (MANAGER)
- `employee@company.com` / `123456` (EMPLOYEE)
- `john.doe@company.com` / `123456` (EMPLOYEE)
- `jane.smith@company.com` / `123456` (MANAGER)

**Any email you add to the database will work!** 🎉 