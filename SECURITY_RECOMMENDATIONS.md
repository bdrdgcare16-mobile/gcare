# SERV Security Recommendations

## 🚨 Critical: Google Maps API Key Security

The Google Maps API key in `android/app/src/main/AndroidManifest.xml` is currently hardcoded and exposed.

### Immediate Actions Required:

1. **Restrict API Key in Google Cloud Console:**
   - Go to: https://console.cloud.google.com/google-maps-api/
   - Select your API key
   - Under "Application restrictions", select "Android apps"
   - Add:
     - Package name: `com.serv.serv_app`
     - SHA-1 certificate fingerprint: [Get from your release keystore]

2. **Enable Only Required APIs:**
   - Google Maps Android API
   - Google Places API for Android (if used)
   - Disable all other APIs

3. **Add HTTP Referrers (if web version exists):**
   - `*.servappbackend.web.app`
   - `localhost:*` for development

### How to get SHA-1 certificate:
```bash
# For debug keystore:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release keystore:
keytool -list -v -keystore path/to/your/release.keystore -alias your-alias
```

### Long-term Solution:
Consider moving the API key to environment variables and loading it at build time using gradle properties.

## 🔐 Dependency Security

### Fixed Vulnerabilities:
- Applied `npm audit fix` - reduced from 32 to 13 vulnerabilities

### Remaining Vulnerabilities (Require Manual Review):
- **nodemailer** (High) - Requires breaking version upgrade
- **uuid** (Moderate) - Requires breaking version upgrade  
- **firebase-admin** dependencies - Requires major version upgrade

### Commands for remaining fixes:
```bash
# For breaking changes (test thoroughly):
npm audit fix --force
```

## 🛡️ General Security Recommendations

### Environment Variables:
- JWT_SECRET is now properly required
- Generate secure JWT secret: `openssl rand -base64 32`

### Firebase Security:
- Firestore rules properly enforce company isolation
- Consider adding employee-specific data access controls

### Rate Limiting:
- Not yet implemented (see Step 6 below)

### File Upload Security:
- Current validation is basic (MIME type + size limit)
- Consider adding virus scanning for production

## 📋 Testing Checklist

After applying security fixes, test:
- [ ] Login functionality
- [ ] Attendance tracking
- [ ] My Attendance page
- [ ] Attendance approvals
- [ ] Tasks management
- [ ] Rewards system
- [ ] Location tracking
- [ ] Firebase deployment

## 🔧 Deployment Commands

```bash
# Set JWT_SECRET before deploying:
export JWT_SECRET="your-secure-jwt-secret-here"

# Deploy to Firebase:
firebase deploy --only functions

# For local development with .env:
npm run serve
```
