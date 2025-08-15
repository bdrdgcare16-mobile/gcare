# Nishali HRMS API Documentation

## Base URL
```
http://localhost:8080
```

## Authentication
Most APIs require JWT token in Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

---

## 🔐 Authentication APIs (`/auth`)

### 1. Register User
**POST** `/auth/register`

**Request Body:**
```json
{
  "email": "employee@company.com",
  "password": "password123",
  "name": "John Doe",
  "role": "EMPLOYEE",
  "phoneNumber": "+1234567890",
  "designation": "Software Developer",
  "department": "Engineering",
  "gender": "MALE",
  "shiftTiming": "9:00 AM - 6:00 PM",
  "reportingTo": "Manager Name",
  "dateOfJoining": "2024-01-15"
}
```

**Response:**
```json
{
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "email": "employee@company.com",
    "name": "John Doe",
    "role": "EMPLOYEE",
    "phoneNumber": "+1234567890",
    "designation": "Software Developer",
    "department": "Engineering",
    "gender": "MALE",
    "shiftTiming": "9:00 AM - 6:00 PM",
    "reportingTo": "Manager Name",
    "dateOfJoining": "2024-01-15T00:00:00.000Z"
  }
}
```

### 2. Login
**POST** `/auth/login`

**Request Body:**
```json
{
  "email": "employee@company.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "message": "Login successful (demo mode)",
  "token": "demo_token_1",
  "user": {
    "id": 1,
    "email": "employee@company.com",
    "name": "John Doe",
    "role": "EMPLOYEE",
    "phoneNumber": "+1234567890",
    "designation": "Software Developer",
    "department": "Engineering",
    "gender": "MALE",
    "shiftTiming": "9:00 AM - 6:00 PM",
    "reportingTo": "Manager Name",
    "dateOfJoining": "2024-01-15T00:00:00.000Z"
  }
}
```

### 3. Get User Profile
**GET** `/auth/profile`

**Headers:**
```
Authorization: Bearer demo_token_1
```

**Response:**
```json
{
  "user": {
    "id": 1,
    "email": "employee@company.com",
    "name": "John Doe",
    "role": "EMPLOYEE",
    "phoneNumber": "+1234567890",
    "designation": "Software Developer",
    "department": "Engineering",
    "gender": "MALE",
    "shiftTiming": "9:00 AM - 6:00 PM",
    "reportingTo": "Manager Name",
    "dateOfJoining": "2024-01-15T00:00:00.000Z",
    "createdAt": "2024-01-15T10:00:00.000Z",
    "updatedAt": "2024-01-15T10:00:00.000Z"
  }
}
```

### 4. Update User Profile
**PUT** `/auth/profile`

**Headers:**
```
Authorization: Bearer demo_token_1
```

**Request Body:**
```json
{
  "name": "John Smith",
  "phoneNumber": "+1987654321",
  "designation": "Senior Developer",
  "department": "Engineering",
  "gender": "MALE",
  "shiftTiming": "9:00 AM - 6:00 PM",
  "reportingTo": "Senior Manager"
}
```

**Response:**
```json
{
  "message": "Profile updated successfully",
  "user": {
    "id": 1,
    "email": "employee@company.com",
    "name": "John Smith",
    "role": "EMPLOYEE",
    "phoneNumber": "+1987654321",
    "designation": "Senior Developer",
    "department": "Engineering",
    "gender": "MALE",
    "shiftTiming": "9:00 AM - 6:00 PM",
    "reportingTo": "Senior Manager",
    "dateOfJoining": "2024-01-15T00:00:00.000Z",
    "createdAt": "2024-01-15T10:00:00.000Z",
    "updatedAt": "2024-01-15T11:00:00.000Z"
  }
}
```

---

## 👥 User Management APIs (`/users`)

### 1. Create Employee
**POST** `/users/employees`

**Request Body:**
```json
{
  "name": "Jane Smith",
  "email": "jane@company.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "message": "Employee created successfully",
  "employee": {
    "id": 2,
    "name": "Jane Smith",
    "email": "jane@company.com",
    "role": "EMPLOYEE",
    "createdAt": "2024-01-15T12:00:00.000Z"
  }
}
```

### 2. Get All Employees
**GET** `/users/employees`

**Response:**
```json
{
  "employees": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@company.com",
      "role": "EMPLOYEE",
      "createdAt": "2024-01-15T10:00:00.000Z"
    },
    {
      "id": 2,
      "name": "Jane Smith",
      "email": "jane@company.com",
      "role": "EMPLOYEE",
      "createdAt": "2024-01-15T12:00:00.000Z"
    }
  ]
}
```

### 3. Get Employee by ID
**GET** `/users/employees/1`

**Response:**
```json
{
  "employee": {
    "id": 1,
    "name": "John Doe",
    "email": "john@company.com",
    "role": "EMPLOYEE",
    "createdAt": "2024-01-15T10:00:00.000Z"
  }
}
```

---

## 📊 Attendance APIs (`/attendance`)

### 1. Get All Attendance Records
**GET** `/attendance?date=2024-01-15&status=PRESENT`

**Response:**
```json
[
  {
    "id": 1,
    "userId": 1,
    "date": "2024-01-15T00:00:00.000Z",
    "checkIn": "2024-01-15T09:00:00.000Z",
    "checkOut": "2024-01-15T18:00:00.000Z",
    "status": "PRESENT",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@company.com"
    }
  }
]
```

### 2. Get User Attendance
**GET** `/attendance/user/1?startDate=2024-01-01&endDate=2024-01-31`

**Response:**
```json
[
  {
    "id": 1,
    "userId": 1,
    "date": "2024-01-15T00:00:00.000Z",
    "checkIn": "2024-01-15T09:00:00.000Z",
    "checkOut": "2024-01-15T18:00:00.000Z",
    "status": "PRESENT",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@company.com"
    }
  }
]
```

### 3. Get Today's Attendance
**GET** `/attendance/user/1/today`

**Response:**
```json
{
  "id": 1,
  "userId": 1,
  "date": "2024-01-15T00:00:00.000Z",
  "checkIn": "2024-01-15T09:00:00.000Z",
  "checkOut": null,
  "status": "PRESENT",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@company.com"
  }
}
```

### 4. Check In
**POST** `/attendance/checkin`

**Request Body:**
```json
{
  "userId": 1,
  "timestamp": "2024-01-15T09:00:00.000Z",
  "faceVerified": true
}
```

**Response:**
```json
{
  "success": true,
  "message": "Check-in successful",
  "attendance": {
    "id": 1,
    "userId": 1,
    "date": "2024-01-15T00:00:00.000Z",
    "checkIn": "2024-01-15T09:00:00.000Z",
    "checkOut": null,
    "status": "PRESENT",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@company.com"
    }
  }
}
```

### 5. Check Out
**POST** `/attendance/checkout`

**Request Body:**
```json
{
  "userId": 1,
  "timestamp": "2024-01-15T18:00:00.000Z"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Check-out successful",
  "attendance": {
    "id": 1,
    "userId": 1,
    "date": "2024-01-15T00:00:00.000Z",
    "checkIn": "2024-01-15T09:00:00.000Z",
    "checkOut": "2024-01-15T18:00:00.000Z",
    "status": "CHECKED_OUT",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@company.com"
    }
  }
}
```

### 6. Get Attendance Statistics
**GET** `/attendance/stats/overview`

**Response:**
```json
{
  "totalEmployees": 10,
  "presentToday": 8,
  "absentToday": 2,
  "attendanceRate": 80
}
```

---

## 📋 Task Management APIs (`/tasks`)

### 1. Get All Tasks
**GET** `/tasks`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "userId": 1,
      "title": "Complete API Documentation",
      "description": "Create comprehensive API documentation",
      "priority": "HIGH",
      "status": "PENDING",
      "dueDate": "2024-01-20T00:00:00.000Z",
      "assignedBy": 2,
      "createdAt": "2024-01-15T10:00:00.000Z",
      "user": {
        "id": 1,
        "name": "John Doe",
        "email": "john@company.com",
        "department": "Engineering"
      }
    }
  ]
}
```

### 2. Get User Tasks
**GET** `/tasks/user/1`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "userId": 1,
      "title": "Complete API Documentation",
      "description": "Create comprehensive API documentation",
      "priority": "HIGH",
      "status": "PENDING",
      "dueDate": "2024-01-20T00:00:00.000Z",
      "assignedBy": 2,
      "createdAt": "2024-01-15T10:00:00.000Z"
    }
  ]
}
```

### 3. Create Task
**POST** `/tasks`

**Request Body:**
```json
{
  "userId": 1,
  "title": "Complete API Documentation",
  "description": "Create comprehensive API documentation for HRMS",
  "priority": "HIGH",
  "dueDate": "2024-01-20T00:00:00.000Z",
  "assignedBy": 2
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "userId": 1,
    "title": "Complete API Documentation",
    "description": "Create comprehensive API documentation for HRMS",
    "priority": "HIGH",
    "status": "PENDING",
    "dueDate": "2024-01-20T00:00:00.000Z",
    "assignedBy": 2,
    "createdAt": "2024-01-15T10:00:00.000Z"
  }
}
```

### 4. Update Task Status
**PUT** `/tasks/1/status`

**Request Body:**
```json
{
  "status": "IN_PROGRESS"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "userId": 1,
    "title": "Complete API Documentation",
    "description": "Create comprehensive API documentation for HRMS",
    "priority": "HIGH",
    "status": "IN_PROGRESS",
    "dueDate": "2024-01-20T00:00:00.000Z",
    "assignedBy": 2,
    "createdAt": "2024-01-15T10:00:00.000Z"
  }
}
```

### 5. Update Task
**PUT** `/tasks/1`

**Request Body:**
```json
{
  "title": "Updated Task Title",
  "description": "Updated task description",
  "priority": "MEDIUM",
  "dueDate": "2024-01-25T00:00:00.000Z",
  "status": "COMPLETED"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "userId": 1,
    "title": "Updated Task Title",
    "description": "Updated task description",
    "priority": "MEDIUM",
    "status": "COMPLETED",
    "dueDate": "2024-01-25T00:00:00.000Z",
    "assignedBy": 2,
    "completedAt": "2024-01-15T15:00:00.000Z",
    "createdAt": "2024-01-15T10:00:00.000Z"
  }
}
```

### 6. Delete Task
**DELETE** `/tasks/1`

**Response:**
```json
{
  "success": true,
  "message": "Task deleted successfully"
}
```

### 7. Get Task Statistics
**GET** `/tasks/stats/1`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "status": "COMPLETED",
      "_count": {
        "status": 5
      }
    },
    {
      "status": "PENDING",
      "_count": {
        "status": 3
      }
    },
    {
      "status": "IN_PROGRESS",
      "_count": {
        "status": 2
      }
    }
  ]
}
```

---

## 📢 Announcement APIs (`/announcements`)

### 1. Get All Announcements
**GET** `/announcements`

**Response:**
```json
[
  {
    "id": 1,
    "title": "Company Meeting Tomorrow",
    "content": "All employees are invited to attend the monthly company meeting",
    "priority": "HIGH",
    "isPinned": true,
    "createdAt": "2024-01-15T10:00:00.000Z",
    "updatedAt": "2024-01-15T10:00:00.000Z"
  }
]
```

### 2. Get Latest Announcements
**GET** `/announcements/latest`

**Response:**
```json
[
  {
    "id": 1,
    "title": "Company Meeting Tomorrow",
    "content": "All employees are invited to attend the monthly company meeting",
    "priority": "HIGH",
    "isPinned": true,
    "createdAt": "2024-01-15T10:00:00.000Z",
    "updatedAt": "2024-01-15T10:00:00.000Z"
  }
]
```

### 3. Create Announcement
**POST** `/announcements`

**Request Body:**
```json
{
  "title": "New Policy Update",
  "content": "Please review the updated company policies"
}
```

**Response:**
```json
{
  "success": true,
  "announcement": {
    "id": 2,
    "title": "New Policy Update",
    "content": "Please review the updated company policies",
    "priority": "MEDIUM",
    "isPinned": false,
    "createdAt": "2024-01-15T12:00:00.000Z",
    "updatedAt": "2024-01-15T12:00:00.000Z"
  },
  "message": "Announcement created successfully"
}
```

### 4. Update Announcement
**PUT** `/announcements/1`

**Request Body:**
```json
{
  "title": "Updated Meeting Notice",
  "content": "Updated meeting details",
  "priority": "HIGH",
  "isPinned": true
}
```

**Response:**
```json
{
  "success": true,
  "announcement": {
    "id": 1,
    "title": "Updated Meeting Notice",
    "content": "Updated meeting details",
    "priority": "HIGH",
    "isPinned": true,
    "createdAt": "2024-01-15T10:00:00.000Z",
    "updatedAt": "2024-01-15T13:00:00.000Z"
  },
  "message": "Announcement updated successfully"
}
```

### 5. Delete Announcement
**DELETE** `/announcements/1`

**Response:**
```json
{
  "success": true,
  "message": "Announcement deleted successfully"
}
```

### 6. Get Announcement by ID
**GET** `/announcements/1`

**Response:**
```json
{
  "id": 1,
  "title": "Company Meeting Tomorrow",
  "content": "All employees are invited to attend the monthly company meeting",
  "priority": "HIGH",
  "isPinned": true,
  "createdAt": "2024-01-15T10:00:00.000Z",
  "updatedAt": "2024-01-15T10:00:00.000Z"
}
```

---

## 🏖️ Leave Management APIs (`/leave`)

### 1. Get All Leave Requests
**GET** `/leave`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "userId": 1,
      "leaveTypeId": 1,
      "startDate": "2024-01-20T00:00:00.000Z",
      "endDate": "2024-01-22T00:00:00.000Z",
      "reason": "Personal vacation",
      "status": "PENDING",
      "createdAt": "2024-01-15T10:00:00.000Z",
      "user": {
        "id": 1,
        "name": "John Doe",
        "email": "john@company.com",
        "department": "Engineering"
      },
      "leaveType": {
        "id": 1,
        "name": "Annual Leave",
        "days": 20
      }
    }
  ]
}
```

### 2. Get User Leave Requests
**GET** `/leave/user/1`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "userId": 1,
      "leaveTypeId": 1,
      "startDate": "2024-01-20T00:00:00.000Z",
      "endDate": "2024-01-22T00:00:00.000Z",
      "reason": "Personal vacation",
      "status": "PENDING",
      "createdAt": "2024-01-15T10:00:00.000Z",
      "leaveType": {
        "id": 1,
        "name": "Annual Leave",
        "days": 20
      }
    }
  ]
}
```

### 3. Create Leave Request
**POST** `/leave`

**Request Body:**
```json
{
  "userId": 1,
  "leaveTypeId": 1,
  "startDate": "2024-01-20T00:00:00.000Z",
  "endDate": "2024-01-22T00:00:00.000Z",
  "reason": "Personal vacation"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "userId": 1,
    "leaveTypeId": 1,
    "startDate": "2024-01-20T00:00:00.000Z",
    "endDate": "2024-01-22T00:00:00.000Z",
    "reason": "Personal vacation",
    "status": "PENDING",
    "createdAt": "2024-01-15T10:00:00.000Z",
    "leaveType": {
      "id": 1,
      "name": "Annual Leave",
      "days": 20
    },
    "user": {
      "name": "John Doe",
      "email": "john@company.com"
    }
  }
}
```

### 4. Approve/Reject Leave Request
**PUT** `/leave/1/approve`

**Request Body:**
```json
{
  "status": "APPROVED",
  "approvedBy": 2
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "userId": 1,
    "leaveTypeId": 1,
    "startDate": "2024-01-20T00:00:00.000Z",
    "endDate": "2024-01-22T00:00:00.000Z",
    "reason": "Personal vacation",
    "status": "APPROVED",
    "approvedBy": 2,
    "approvedAt": "2024-01-15T14:00:00.000Z",
    "createdAt": "2024-01-15T10:00:00.000Z",
    "leaveType": {
      "id": 1,
      "name": "Annual Leave",
      "days": 20
    },
    "user": {
      "name": "John Doe",
      "email": "john@company.com"
    }
  }
}
```

### 5. Get Leave Types
**GET** `/leave/types`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Annual Leave",
      "days": 20
    },
    {
      "id": 2,
      "name": "Sick Leave",
      "days": 10
    },
    {
      "id": 3,
      "name": "Personal Leave",
      "days": 5
    }
  ]
}
```

### 6. Get Leave Statistics
**GET** `/leave/stats/1`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "status": "APPROVED",
      "_count": {
        "status": 3
      }
    },
    {
      "status": "PENDING",
      "_count": {
        "status": 1
      }
    },
    {
      "status": "REJECTED",
      "_count": {
        "status": 1
      }
    }
  ]
}
```

### 7. Delete Leave Request
**DELETE** `/leave/1`

**Response:**
```json
{
  "success": true,
  "message": "Leave request deleted successfully"
}
```

---

## 💰 Payroll APIs (`/payroll`)

### 1. Get All Payrolls
**GET** `/payroll`

**Response:**
```json
[
  {
    "id": 1,
    "userId": 1,
    "month": 1,
    "year": 2024,
    "amount": 5000.00,
    "details": "Base salary + bonuses",
    "createdAt": "2024-01-15T10:00:00.000Z",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@company.com"
    }
  }
]
```

### 2. Get User Payrolls
**GET** `/payroll/user/1`

**Response:**
```json
[
  {
    "id": 1,
    "userId": 1,
    "month": 1,
    "year": 2024,
    "amount": 5000.00,
    "details": "Base salary + bonuses",
    "createdAt": "2024-01-15T10:00:00.000Z"
  }
]
```

### 3. Create Payroll
**POST** `/payroll`

**Request Body:**
```json
{
  "userId": 1,
  "month": 1,
  "year": 2024,
  "amount": 5000.00,
  "details": "Base salary + bonuses"
}
```

**Response:**
```json
{
  "id": 1,
  "userId": 1,
  "month": 1,
  "year": 2024,
  "amount": 5000.00,
  "details": "Base salary + bonuses",
  "createdAt": "2024-01-15T10:00:00.000Z"
}
```

---

## 📊 Reports APIs (`/reports`)

### 1. Attendance Report
**GET** `/reports/attendance?userId=1&month=1&year=2024&type=monthly`

**Response:**
```json
{
  "attendance": [
    {
      "id": 1,
      "userId": 1,
      "date": "2024-01-15T00:00:00.000Z",
      "checkIn": "2024-01-15T09:00:00.000Z",
      "checkOut": "2024-01-15T18:00:00.000Z",
      "status": "PRESENT",
      "user": {
        "id": 1,
        "name": "John Doe",
        "email": "john@company.com"
      }
    }
  ],
  "statistics": {
    "totalDays": 22,
    "presentDays": 20,
    "absentDays": 1,
    "lateDays": 1,
    "attendanceRate": 90.91
  },
  "period": {
    "startDate": "2024-01-01",
    "endDate": "2024-01-31",
    "type": "monthly"
  }
}
```

### 2. Payroll Report
**GET** `/reports/payroll?userId=1&month=1&year=2024`

**Response:**
```json
{
  "payrolls": [
    {
      "id": 1,
      "userId": 1,
      "month": 1,
      "year": 2024,
      "amount": 5000.00,
      "details": "Base salary + bonuses",
      "user": {
        "id": 1,
        "name": "John Doe",
        "email": "john@company.com"
      }
    }
  ],
  "statistics": {
    "totalEmployees": 10,
    "totalPayroll": 50000.00,
    "averageSalary": 5000.00,
    "highestSalary": 8000.00,
    "lowestSalary": 3000.00
  },
  "period": {
    "month": 1,
    "year": 2024
  }
}
```

### 3. Performance Report
**GET** `/reports/performance?userId=1&month=1&year=2024`

**Response:**
```json
{
  "tasks": [
    {
      "id": 1,
      "userId": 1,
      "title": "Complete API Documentation",
      "status": "COMPLETED",
      "user": {
        "id": 1,
        "name": "John Doe",
        "email": "john@company.com"
      }
    }
  ],
  "attendance": [
    {
      "id": 1,
      "userId": 1,
      "date": "2024-01-15T00:00:00.000Z",
      "status": "PRESENT",
      "user": {
        "id": 1,
        "name": "John Doe",
        "email": "john@company.com"
      }
    }
  ],
  "performance": {
    "taskMetrics": {
      "totalTasks": 10,
      "completedTasks": 8,
      "pendingTasks": 1,
      "inProgressTasks": 1,
      "taskCompletionRate": 80.00
    },
    "attendanceMetrics": {
      "totalDays": 22,
      "presentDays": 20,
      "attendanceRate": 90.91
    },
    "overallScore": 85.46
  },
  "period": {
    "startDate": "2024-01-01",
    "endDate": "2024-01-31"
  }
}
```

### 4. Leave Report
**GET** `/reports/leave?userId=1&month=1&year=2024`

**Response:**
```json
{
  "leaveRequests": [
    {
      "id": 1,
      "userId": 1,
      "startDate": "2024-01-20T00:00:00.000Z",
      "endDate": "2024-01-22T00:00:00.000Z",
      "reason": "Personal vacation",
      "status": "APPROVED",
      "user": {
        "id": 1,
        "name": "John Doe",
        "email": "john@company.com"
      },
      "leaveType": {
        "id": 1,
        "name": "Annual Leave",
        "days": 20
      }
    }
  ],
  "statistics": {
    "totalRequests": 5,
    "approvedRequests": 3,
    "pendingRequests": 1,
    "rejectedRequests": 1,
    "approvalRate": 60.00
  },
  "leaveTypeStats": {
    "Annual Leave": {
      "count": 3,
      "approved": 2,
      "pending": 1,
      "rejected": 0
    },
    "Sick Leave": {
      "count": 2,
      "approved": 1,
      "pending": 0,
      "rejected": 1
    }
  },
  "period": {
    "startDate": "2024-01-01",
    "endDate": "2024-01-31"
  }
}
```

### 5. Dashboard Report
**GET** `/reports/dashboard`

**Response:**
```json
{
  "summary": {
    "totalEmployees": 10,
    "activeEmployees": 10,
    "todayAttendance": 8,
    "pendingLeaves": 2,
    "totalTasks": 25,
    "completedTasks": 20,
    "totalPayroll": 50000.00
  },
  "period": {
    "currentMonth": "January 2024",
    "today": "2024-01-15"
  }
}
```

---

## 🔔 Notifications APIs (`/notifications`)

### 1. Get User Notifications
**GET** `/notifications/user/1`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "userId": 1,
      "title": "New Task Assigned",
      "message": "You have been assigned: Complete API Documentation",
      "type": "TASK",
      "read": false,
      "createdAt": "2024-01-15T10:00:00.000Z"
    }
  ]
}
```

### 2. Mark Notification as Read
**PUT** `/notifications/read/1`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "userId": 1,
    "title": "New Task Assigned",
    "message": "You have been assigned: Complete API Documentation",
    "type": "TASK",
    "read": true,
    "createdAt": "2024-01-15T10:00:00.000Z"
  }
}
```

### 3. Mark All Notifications as Read
**PUT** `/notifications/read-all/1`

**Response:**
```json
{
  "success": true,
  "message": "All notifications marked as read"
}
```

### 4. Get Unread Notification Count
**GET** `/notifications/unread-count/1`

**Response:**
```json
{
  "success": true,
  "count": 3
}
```

### 5. Create Notification
**POST** `/notifications`

**Request Body:**
```json
{
  "userId": 1,
  "title": "System Update",
  "message": "System will be down for maintenance",
  "type": "SYSTEM"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 2,
    "userId": 1,
    "title": "System Update",
    "message": "System will be down for maintenance",
    "type": "SYSTEM",
    "read": false,
    "createdAt": "2024-01-15T15:00:00.000Z"
  }
}
```

---

## ⏰ Check-in Request APIs (`/checkin`)

### 1. Submit Check-in Request
**POST** `/checkin/request`

**Request Body:**
```json
{
  "userId": 1,
  "checkInTime": "2024-01-15T10:30:00.000Z",
  "reason": "Traffic delay"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "userId": 1,
    "date": "2024-01-15T00:00:00.000Z",
    "checkInTime": "2024-01-15T10:30:00.000Z",
    "reason": "Traffic delay",
    "status": "PENDING",
    "createdAt": "2024-01-15T10:30:00.000Z"
  }
}
```

### 2. Get Check-in Requests
**GET** `/checkin/requests`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "userId": 1,
      "date": "2024-01-15T00:00:00.000Z",
      "checkInTime": "2024-01-15T10:30:00.000Z",
      "reason": "Traffic delay",
      "status": "PENDING",
      "createdAt": "2024-01-15T10:30:00.000Z",
      "user": {
        "id": 1,
        "name": "John Doe",
        "email": "john@company.com",
        "department": "Engineering"
      }
    }
  ]
}
```

### 3. Approve/Reject Check-in Request
**PUT** `/checkin/request/1`

**Request Body:**
```json
{
  "status": "APPROVED",
  "approvedBy": 2
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "userId": 1,
    "date": "2024-01-15T00:00:00.000Z",
    "checkInTime": "2024-01-15T10:30:00.000Z",
    "reason": "Traffic delay",
    "status": "APPROVED",
    "approvedBy": 2,
    "approvedAt": "2024-01-15T11:00:00.000Z",
    "createdAt": "2024-01-15T10:30:00.000Z"
  }
}
```

### 4. Get Employee Check-in Requests
**GET** `/checkin/employee/1`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "userId": 1,
      "date": "2024-01-15T00:00:00.000Z",
      "checkInTime": "2024-01-15T10:30:00.000Z",
      "reason": "Traffic delay",
      "status": "APPROVED",
      "createdAt": "2024-01-15T10:30:00.000Z"
    }
  ]
}
```

---

## 📊 Dashboard APIs (`/dashboard`)

### 1. Employee Dashboard Statistics
**GET** `/dashboard/employee-stats`

**Response:**
```json
{
  "success": true,
  "userName": "John Doe",
  "shiftTiming": "9:00 AM - 6:00 PM",
  "location": "Office Location",
  "todayTasks": [
    {
      "title": "Complete API Documentation",
      "status": "PENDING",
      "description": "Create comprehensive API documentation"
    }
  ],
  "attendanceStatus": "Checked In",
  "checkInTime": "2024-01-15T09:00:00.000Z",
  "checkOutTime": null,
  "workDuration": 360,
  "totalTasks": 10,
  "completedTasks": 8,
  "pendingTasks": 2
}
```

### 2. Attendance Statistics
**GET** `/dashboard/attendance/stats`

**Response:**
```json
{
  "success": true,
  "todayAttendance": 8,
  "present": 7,
  "absent": 1,
  "late": 0,
  "workDuration": 0
}
```

### 3. Task Statistics
**GET** `/dashboard/tasks/stats`

**Response:**
```json
{
  "success": true,
  "totalTasks": 25,
  "completedTasks": 20,
  "pendingTasks": 3,
  "inProgressTasks": 2,
  "todayTasks": [
    {
      "title": "Complete API Documentation",
      "status": "PENDING",
      "description": "Create comprehensive API documentation"
    }
  ]
}
```

---

## 👨‍💼 Admin APIs (`/admin`)

### 1. Dashboard Statistics
**GET** `/admin/dashboard-stats`

**Response:**
```json
{
  "success": true,
  "totalEmployees": 10,
  "activeEmployees": 10,
  "pendingLeaves": 2,
  "todayAttendance": 8,
  "totalPayroll": 50000.00,
  "announcements": 5,
  "totalUsers": 12
}
```

### 2. User Statistics
**GET** `/admin/user-stats`

**Response:**
```json
{
  "success": true,
  "totalUsers": 12,
  "employees": 10,
  "admins": 2
}
```

### 3. Attendance Statistics
**GET** `/admin/attendance-stats`

**Response:**
```json
{
  "success": true,
  "todayAttendance": 8,
  "present": 7,
  "absent": 1,
  "late": 0
}
```

### 4. Leave Statistics
**GET** `/admin/leave-stats`

**Response:**
```json
{
  "success": true,
  "pendingLeaves": 2,
  "approvedLeaves": 5,
  "rejectedLeaves": 1,
  "totalRequests": 8
}
```

---

## 🏥 Health Check API

### Health Check
**GET** `/health`

**Response:**
```json
{
  "status": "ok",
  "database": "connected",
  "timestamp": "2024-01-15T10:00:00.000Z"
}
```

---

## 🔌 WebSocket Support

### WebSocket Connection
```
ws://localhost:8080
```

### Real-time Events:
- **attendance**: Attendance check-in/out notifications
- **task**: Task assignment and status updates
- **leave**: Leave request updates
- **notification**: General notifications

### WebSocket Message Format:
```json
{
  "type": "attendance",
  "message": "John Doe checked in",
  "data": {
    "userId": 1,
    "timestamp": "2024-01-15T09:00:00.000Z"
  }
}
```

---

## 📝 Error Responses

### 400 Bad Request
```json
{
  "error": "Invalid email format"
}
```

### 401 Unauthorized
```json
{
  "error": "Access token required"
}
```

### 403 Forbidden
```json
{
  "error": "Invalid or expired token"
}
```

### 404 Not Found
```json
{
  "error": "User not found"
}
```

### 409 Conflict
```json
{
  "error": "Email already exists"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error"
}
```

---

## 🔧 Environment Variables

```env
DATABASE_URL=postgresql://postgres:Nishali@localhost:5432/SERV
JWT_SECRET=your_jwt_secret_here
BCRYPT_ROUNDS=10
PORT=8080
NODE_ENV=development
```

---

## 📋 API Status Codes

- **200**: Success
- **201**: Created
- **400**: Bad Request
- **401**: Unauthorized
- **403**: Forbidden
- **404**: Not Found
- **409**: Conflict
- **500**: Internal Server Error
- **503**: Service Unavailable

---

## 🚀 Getting Started

1. **Install Dependencies:**
   ```bash
   npm install
   ```

2. **Setup Database:**
   ```bash
   npx prisma migrate dev
   npx prisma generate
   ```

3. **Start Server:**
   ```bash
   npm start
   ```

4. **Access APIs:**
   - Base URL: `http://localhost:8080`
   - Health Check: `http://localhost:8080/health`
   - WebSocket: `ws://localhost:8080`

---

## 📚 Additional Resources

- **Database Schema**: Check `prisma/schema.prisma`
- **Test Scripts**: Available in backend root directory
- **Sample Data**: Use provided setup scripts for demo data
- **WebSocket Events**: Real-time notifications for all major actions

---

*This documentation covers all available APIs in the Nishali HRMS backend system. For additional support or questions, refer to the source code or contact the development team.*


