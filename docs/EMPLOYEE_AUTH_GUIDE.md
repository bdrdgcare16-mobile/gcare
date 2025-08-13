# Employee Authentication Guide

This guide explains how to use the employee authentication system with email and password.

## 🚀 Quick Start

### 1. Existing Test Accounts

You can immediately test the system with these pre-configured accounts:

**Employee Account:**
- Email: `employee@test.com`
- Password: `password123`

**Admin Account:**
- Email: `admin@test.com`
- Password: `password123`

### 2. How to Login

#### In Flutter App:
1. Open the login screen
2. Enter the employee email and password
3. Click "Login as Employee"
4. You'll be redirected to the employee dashboard

#### Via API:
```bash
POST /auth/login
Content-Type: application/json

{
  "email": "employee@test.com",
  "password": "password123"
}
```

## 📝 Adding New Employees

### Method 1: Using the Node.js Script

1. Navigate to the backend directory:
```bash
cd backend
```

2. Run the employee management script:
```bash
node add_employee.js
```

This will create sample employees and show you how to add more.

### Method 2: Using the API Endpoint

```bash
POST /users/employees
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john.doe@company.com",
  "password": "john123"
}
```

### Method 3: Direct Database Seeding

Edit `backend/prisma/seed.ts` and add more employees:

```typescript
const newEmployee = await prisma.user.upsert({
  where: { email: 'new.employee@company.com' },
  update: {},
  create: {
    email: 'new.employee@company.com',
    password: await bcrypt.hash('newpassword123', 10),
    name: 'New Employee',
    role: Role.EMPLOYEE,
  },
});
```

Then run:
```bash
cd backend
npx prisma db seed
```

## 🔐 Security Features

### Password Requirements:
- Minimum 6 characters
- Automatically hashed using bcrypt
- Stored securely in database

### Email Validation:
- Must be valid email format
- Must be unique in the system
- Used as login identifier

### JWT Authentication:
- Tokens expire after 24 hours
- Secure token generation
- Role-based access control

## 📱 Flutter App Integration

The Flutter app automatically handles:
- Email validation
- Password validation
- Loading states
- Error messages
- Session management
- Role-based navigation

### Login Flow:
1. User enters email and password
2. App validates input format
3. API call to `/auth/login`
4. JWT token received and stored
5. User redirected based on role
6. Session maintained for subsequent requests

## 🛠️ API Endpoints

### Authentication
- `POST /auth/login` - Employee/Admin login
- `POST /auth/register` - Create new account
- `POST /auth/forgot-password` - Reset password request
- `POST /auth/reset-password` - Reset password with token

### Employee Management
- `POST /users/employees` - Create new employee
- `GET /users/employees` - List all employees
- `GET /users/employees/:id` - Get specific employee

## 🔧 Database Schema

```sql
User {
  id: Int (Primary Key)
  email: String (Unique)
  password: String (Hashed)
  name: String
  role: Role (ADMIN | EMPLOYEE)
  createdAt: DateTime
  updatedAt: DateTime
}
```

## 🚨 Error Handling

Common error responses:

```json
{
  "error": "Invalid credentials"
}
```

```json
{
  "error": "Email already exists"
}
```

```json
{
  "error": "Password must be at least 6 characters"
}
```

## 📋 Testing

### Test Employee Login:
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "employee@test.com",
    "password": "password123"
  }'
```

### Create New Employee:
```bash
curl -X POST http://localhost:3000/users/employees \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Employee",
    "email": "test@company.com",
    "password": "test123"
  }'
```

## 🔄 Password Reset

If an employee forgets their password:

1. Use the "Forgot Password?" link in the app
2. Enter their email address
3. Check email for reset link
4. Set new password

## 📞 Support

For issues with employee authentication:
1. Check the backend logs
2. Verify database connection
3. Ensure email format is valid
4. Confirm password meets requirements 