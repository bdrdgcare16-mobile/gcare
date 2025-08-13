# 🚀 Quick Backend Integration Guide

## ⚡ **Fast Setup (5 minutes)**

### **1. Start Backend Server**
```bash
cd backend
npm install
npm run dev
```

### **2. Test Backend**
Open browser: `http://localhost:3000/health`

### **3. API Endpoints Available**
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `GET /tasks` - Get all tasks
- `POST /tasks` - Create new task
- `PUT /tasks/:id` - Update task
- `DELETE /tasks/:id` - Delete task

## 🔧 **Flutter App Configuration**

### **API Base URL**
- **Android Emulator**: `http://10.0.2.2:3000`
- **Web**: `http://localhost:3000`
- **Physical Device**: `http://YOUR_COMPUTER_IP:3000`

### **Features Implemented**
✅ **Real API Integration** with fallback to mock data
✅ **Error Handling** with timeout protection
✅ **Authentication** with JWT tokens
✅ **Task Management** (CRUD operations)
✅ **User Session Management**

## 🎯 **How It Works**

1. **App tries real API first**
2. **If API fails** → Falls back to mock data
3. **No interruption** to user experience
4. **Console logs** show API status

## 📱 **Testing**

### **Login Credentials**
- **Admin**: `admin@test.com` / `admin123`
- **Employee**: `employee@test.com` / `employee123`

### **Check Console**
Look for these messages:
- ✅ `API connected successfully`
- ⚠️ `API Error: ... - Using mock data`

## 🔄 **Switch Between Real/Mock**

In `lib/services/api_base.dart`:
```dart
const bool useMockOnly = false; // Real API
const bool useMockOnly = true;  // Mock only
```

## 🚨 **Troubleshooting**

### **Backend Won't Start**
1. Check if port 3000 is free
2. Run `npm install` in backend folder
3. Check Node.js version (v16+)

### **API Connection Fails**
1. Verify backend is running on port 3000
2. Check firewall settings
3. Use correct IP address for your device

### **Flutter App Issues**
1. Check console for error messages
2. Verify API base URL
3. Restart Flutter app

## 📊 **Current Status**
- ✅ **Backend**: Ready to run
- ✅ **Flutter**: Connected to real APIs
- ✅ **Fallback**: Mock data available
- ✅ **Error Handling**: Implemented 