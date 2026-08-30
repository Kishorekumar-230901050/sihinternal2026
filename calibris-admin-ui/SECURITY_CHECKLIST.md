# 🔒 Security Checklist - Calibris Software

## ✅ Security Issues Fixed

### **1. .env File Protection**
- ❌ **Before**: `.gitignore` had `!.env` which **exposed** all credentials to GitHub
- ✅ **Fixed**: Updated `.gitignore` to properly ignore all `.env` files
- ✅ **Action**: Removed `.env` from git tracking (`git rm --cached .env`)

### **2. Hardcoded Credentials Removed**
- ❌ **Before**: `server/scripts/seedAdmin.cjs` had hardcoded password: `Kaviya@123`
- ✅ **Fixed**: Password now required via `ADMIN_PASSWORD` environment variable
- ✅ **Usage**: `ADMIN_PASSWORD=YourSecurePassword123 node server/scripts/seedAdmin.cjs`

### **3. Database Credentials**
- ✅ **Protected**: `DATABASE_URL` is now only in `.env` (not committed to git)
- ✅ **Railway**: Set `DATABASE_URL` as environment variable in Railway dashboard
- ⚠️ **Important**: Your Supabase database URL contains the password - never commit it!

---

## 🔐 Current Protected Credentials

These credentials are **protected** and will **NOT** be pushed to GitHub:

1. **Database URL** (PostgreSQL password): `PHQrgQEBXNFkDnafUvRpQDjNGYFEiDwz`
   - Location: `.env` file (ignored by git)
   - Used by: Backend server to connect to Supabase database
   - Railway: Set as `DATABASE_URL` environment variable

2. **Google Maps API Key**: `AIzaSyDqd9N-rTDtGoUMCnjRs93-Jv89HnbCj5M`
   - Location: `.env` file (ignored by git)
   - Used by: Frontend for displaying device locations
   - Vercel: Set as `VITE_PUBLIC_GOOGLE_MAPS_KEY` environment variable

3. **Firebase API Key**: `AIzaSyDNUTDCPjYxC8vGxGomW6BuMBcwWTBwR68`
   - Location: `.env` file (ignored by git)
   - Used by: Frontend for Firebase authentication
   - Vercel: Set as `VITE_PUBLIC_FIREBASE_API_KEY` environment variable

4. **JWT Secret**: `Secret`
   - Location: `.env` file (ignored by git)
   - ⚠️ **CHANGE THIS**: Use a strong random string in production!
   - Railway: Set as `JWT_SECRET` environment variable

5. **Admin Password**: Previously `Kaviya@123` (now removed from code)
   - ⚠️ **Required**: Set via environment variable when running seedAdmin script
   - Example: `ADMIN_PASSWORD=NewSecurePassword123 node server/scripts/seedAdmin.cjs`

---

## 📋 Pre-Deployment Security Checklist

Before deploying, verify:

- [x] `.env` file is in `.gitignore`
- [x] `.env` file removed from git tracking
- [x] No hardcoded passwords in source code
- [x] `seedAdmin.cjs` requires environment variable for password
- [ ] **IMPORTANT**: Change `JWT_SECRET` to a strong random string
- [ ] **IMPORTANT**: Review Firebase security rules before production

---

## 🚀 Deployment Environment Variables

### **Railway (Backend):**
```
DATABASE_URL=postgresql://postgres:PHQrgQEBXNFkDnafUvRpQDjNGYFEiDwz@shinkansen.proxy.rlwy.net:39404/railway
NODE_ENV=production
PORT=3000
ALLOWED_ORIGINS=https://your-vercel-app.vercel.app,http://localhost:5173
JWT_SECRET=YourStrongRandomJWTSecret123!@#
```

### **Vercel (Frontend):**
```
VITE_API_URL=https://your-railway-app.railway.app/api
VITE_WS_URL=https://your-railway-app.railway.app
VITE_PUBLIC_GOOGLE_MAPS_KEY=AIzaSyDqd9N-rTDtGoUMCnjRs93-Jv89HnbCj5M
VITE_PUBLIC_FIREBASE_API_KEY=AIzaSyDNUTDCPjYxC8vGxGomW6BuMBcwWTBwR68
VITE_PUBLIC_FIREBASE_AUTH_DOMAIN=calibirs-auth.firebaseapp.com
VITE_PUBLIC_FIREBASE_PROJECT_ID=calibirs-auth
VITE_PUBLIC_FIREBASE_STORAGE_BUCKET=calibirs-auth.firebasestorage.app
VITE_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=508807516918
VITE_PUBLIC_FIREBASE_APP_ID=1:508807516918:web:328c5f7e8bce86d0c752d7
```

---

## 🔍 How to Verify Security

### **1. Check .gitignore is protecting .env:**
```bash
git check-ignore .env server/.env
# Should output: .env, server/.env
```

### **2. Verify .env is not tracked:**
```bash
git ls-files | grep "\.env"
# Should only show: .env.example (not .env)
```

### **3. Search for exposed credentials:**
```bash
git log --all --full-history --source -- .env
# Should show the commit where we removed .env from tracking
```

### **4. Verify no secrets in staged files:**
```bash
git diff --cached | grep -i "password\|secret\|api_key"
# Should NOT show any actual credential values
```

---

## ⚠️ IMPORTANT Security Notes

### **What CAN be committed:**
✅ `.env.example` - Template with placeholder values
✅ Public Firebase config (VITE_PUBLIC_* variables)
✅ Code files, configuration files

### **What MUST NOT be committed:**
❌ `.env` - Contains real credentials
❌ `server/.env` - Contains real credentials
❌ Database passwords
❌ Private API keys
❌ JWT secrets
❌ Admin passwords

### **Public vs Private Keys:**
- **Firebase API Key** (`VITE_PUBLIC_FIREBASE_API_KEY`): Prefix `VITE_PUBLIC_` means it's exposed in the client. This is OK for Firebase - security is handled by Firebase Security Rules.
- **Google Maps API Key**: Should be restricted in Google Cloud Console to specific domains
- **Database URL**: NEVER expose - contains password for direct database access
- **JWT Secret**: NEVER expose - used to sign authentication tokens

---

## 🔄 After Deployment Checklist

- [ ] Verify Railway has correct `DATABASE_URL`
- [ ] Verify Railway has strong `JWT_SECRET` (not "Secret")
- [ ] Verify Vercel has all `VITE_*` environment variables
- [ ] Test API calls work (CORS configured correctly)
- [ ] Test WebSocket connects properly
- [ ] Verify no credentials visible in browser console
- [ ] Check Firebase security rules are production-ready
- [ ] Restrict Google Maps API key to your domain only

---

## 🆘 If Credentials Were Exposed

If you accidentally pushed credentials to GitHub:

1. **Change ALL credentials immediately:**
   - Generate new Supabase database password
   - Regenerate Google Maps API key
   - Regenerate Firebase API key
   - Generate new JWT secret

2. **Remove from git history:**
   ```bash
   # This rewrites history - use with caution!
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch .env' \
     --prune-empty --tag-name-filter cat -- --all

   git push origin --force --all
   ```

3. **Update all deployment environment variables** with new credentials

---

## 📞 Questions?

If you're unsure about any security aspect:
- Review `.env.example` for template
- Check `DEPLOYMENT_GUIDE.md` for deployment steps
- Never commit real credentials - always use environment variables!
