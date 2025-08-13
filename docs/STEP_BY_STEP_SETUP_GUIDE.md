# 🚀 STEP-BY-STEP FLUTTER APP SETUP GUIDE

## 🎯 **MISSION: Fix Dependencies, Test App, Build APK**

This guide will help you resolve all three critical issues:
1. ✅ Install Flutter dependencies
2. ✅ Test the app on device/emulator
3. ✅ Build APK for submission

---

## 📋 **STEP 1: CHECK FLUTTER INSTALLATION**

### **1.1 Verify Flutter is Installed**
```bash
flutter --version
```
**Expected Output:**
```
Flutter 3.x.x • channel stable • https://github.com/flutter/flutter.git
Framework • revision xxxxxxxx (x weeks ago) • 2024-xx-xx xx:xx:xx -xxxx
Engine • revision xxxxxxxx
Tools • Dart 3.x.x • DevTools 2.x.x
```

### **1.2 If Flutter Not Found:**
1. Download Flutter from: https://flutter.dev/docs/get-started/install
2. Extract to `C:\flutter`
3. Add `C:\flutter\bin` to your PATH
4. Restart your terminal

---

## 📋 **STEP 2: FIX DEPENDENCIES**

### **2.1 Clean the Project**
```bash
flutter clean
```
This removes all build files and cached data.

### **2.2 Install Dependencies**
```bash
flutter pub get
```
This downloads all packages listed in `pubspec.yaml`.

### **2.3 Check for Errors**
```bash
flutter analyze
```
This checks your code for issues.

**Expected Output:**
```
No issues found!
```

---

## 📋 **STEP 3: TEST THE APP**

### **3.1 Test on Web (Easiest)**
```bash
flutter run -d chrome
```
This will:
- Open your app in Chrome browser
- Show real-time updates as you edit code
- Let you test all features

### **3.2 Test on Mobile Device**
1. **Enable Developer Options** on your phone
2. **Enable USB Debugging**
3. **Connect phone via USB**
4. **Run:**
```bash
flutter devices
flutter run -d [device-id]
```

### **3.3 Test on Emulator**
1. **Open Android Studio**
2. **Open AVD Manager**
3. **Start an emulator**
4. **Run:**
```bash
flutter run -d [emulator-id]
```

---

## 📋 **STEP 4: BUILD APK**

### **4.1 Build Release APK**
```bash
flutter build apk --release
```

### **4.2 Find Your APK**
The APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### **4.3 Test APK on Phone**
1. Copy `app-release.apk` to your phone
2. Install it (allow unknown sources)
3. Test all features

---

## 🎯 **QUICK START (Using Batch File)**

### **Option 1: Use the Complete Setup Guide**
```bash
# Double-click this file in your project folder:
COMPLETE_SETUP_GUIDE.bat
```

### **Option 2: Manual Commands**
```bash
# Step 1: Fix dependencies
flutter clean
flutter pub get
flutter analyze

# Step 2: Test app
flutter run -d chrome

# Step 3: Build APK
flutter build apk --release
```

---

## 🔧 **TROUBLESHOOTING**

### **Issue 1: "flutter: command not found"**
**Solution:**
1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Add Flutter to PATH
3. Restart terminal

### **Issue 2: "Dependencies failed to resolve"**
**Solution:**
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

### **Issue 3: "Build failed"**
**Solution:**
```bash
flutter doctor
flutter clean
flutter pub get
flutter build apk --release
```

### **Issue 4: "App crashes on startup"**
**Solution:**
1. Check console for error messages
2. Verify all imports are correct
3. Test with `flutter run --debug` for detailed errors

---

## 📱 **TESTING CHECKLIST**

### **✅ Core Features to Test:**
- [ ] **Login Screen**: Try logging in with test credentials
- [ ] **Employee Dashboard**: Check if all sections load
- [ ] **Profile Screen**: Test profile management
- [ ] **Attendance**: Test check-in/check-out
- [ ] **Tasks**: Test task management
- [ ] **Leave Requests**: Test leave application
- [ ] **Navigation**: Test all menu items

### **✅ Test Credentials:**
```
Admin: admin@techcorp.com / Admin@123
HR: hr@techcorp.com / Admin@123
Employee: babyreeta16@gmail.com / Employee@123
```

---

## 🎉 **SUCCESS INDICATORS**

### **✅ Dependencies Fixed:**
- `flutter pub get` runs without errors
- `flutter analyze` shows "No issues found"
- No red squiggly lines in your IDE

### **✅ App Tested:**
- App opens without crashing
- All screens load properly
- Features work as expected
- No console errors

### **✅ APK Built:**
- `flutter build apk --release` completes successfully
- APK file exists at `build/app/outputs/flutter-apk/app-release.apk`
- APK installs and runs on phone

---

## 🚀 **NEXT STEPS AFTER SUCCESS**

1. **Take Screenshots** of your app for submission
2. **Test APK** on different devices
3. **Prepare App Description** for app store
4. **Submit to App Store** (Google Play Store, etc.)

---

## 💡 **PRO TIPS**

- **Always test on real device** before submission
- **Keep backup** of your working APK
- **Document any issues** you encounter
- **Test all user flows** thoroughly

---

**🎯 You're now ready to fix your app and build it for submission!** 