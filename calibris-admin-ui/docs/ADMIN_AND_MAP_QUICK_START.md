# Admin Access & Map - Quick Start Guide

## 🚀 Start Here

### 1. Start Your Application
```bash
cd /workspaces/Calibris-software
pnpm dev
```
App runs at: `http://localhost:8080`

### 2. Create an Admin Account
```
1. Navigate to: http://localhost:8080/auth/signup
2. Fill in form:
   - Full Name: Your Name
   - Email: admin@test.com
   - Password: test1234
   - Role: Select "Admin" button
   - ✓ Check "I agree to terms"
3. Click "Create Account"
```

### 3. Verify Admin Access
```
After signup, check navbar for:
Dashboard | Devices | Map | Audit | Admin ← Should be here!

If Admin link not visible:
- Click your avatar (top right) → Logout
- Login again with your admin@test.com
- Admin link should now appear
```

### 4. View the Admin Page
```
Click "Admin" in navbar
Should see admin-specific content
```

### 5. Check the Map
```
Click "Map" in navbar
Should see:
- Google Map displaying India
- Colored device pins at various locations
  - Red = Tampered
  - Orange = Drifted
  - Green = Online
  - Gray = Offline
```

## ✅ Verification Checklist

- [ ] App starts without errors
- [ ] Can navigate to /auth/signup
- [ ] Can create admin account with role selection
- [ ] Admin link appears in navbar after login
- [ ] Can click Admin link and access admin page
- [ ] Map link appears in navbar
- [ ] Map page loads with Google Map visible
- [ ] Device markers visible on map
- [ ] Can hover over markers to see device info
- [ ] Can click markers to navigate to devices

## 🔍 If Issues Occur

### Admin Link Not Showing

**Solution 1: Refresh**
```
1. Click your avatar (top right)
2. Click "Logout"
3. Go to /auth/login
4. Login again
5. Admin link should appear
```

**Solution 2: Promote via API**
```bash
# Open terminal and run:
curl -X POST http://localhost:8080/api/auth/update-role \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@test.com", "role": "admin"}'

# Then logout and login again
```

### Map Not Showing Devices

**Check 1: Google Maps API Key**
```
Open browser console (F12) and paste:
> import.meta.env.VITE_GOOGLE_MAPS_KEY

Should show your API key (non-empty string)
```

**Check 2: Devices Loaded**
```
In browser console, paste:
> const devices = JSON.parse(localStorage.getItem('calibris_devices'));
> devices?.length

Should show: 10+ (number of devices)
```

**Check 3: Map Container**
```
Open browser DevTools (F12)
Elements tab
Look for: <div> with height > 0
Map should be inside this container
```

## 📚 Detailed Documentation

For in-depth guides, see:
- **Setup**: `docs/ADMIN_SETUP.md`
- **Troubleshooting**: `docs/ADMIN_ACCESS_AND_MAP_TROUBLESHOOTING.md`
- **Full Summary**: `docs/FIX_ADMIN_ACCESS_SUMMARY.md`
- **Auth Guide**: `docs/FIREBASE_AUTH_SETUP.md`

## 🧪 Testing Different Roles

### Test as Officer
```
1. Go to /auth/signup
2. Fill form with:
   - Role: "Officer" (select button)
3. Create account
4. Check navbar:
   - Should see: Dashboard | Devices | Map | Audit
   - Should NOT see: Admin
5. Try to access /admin
   - Should redirect to home
```

### Test as Admin
```
1. Go to /auth/signup
2. Fill form with:
   - Role: "Admin" (select button)
3. Create account
4. Check navbar:
   - Should see: Dashboard | Devices | Map | Audit | Admin
5. Click Admin
   - Should load admin page
```

## 🎯 Common Tasks

### Create Multiple Test Accounts
```
Account 1 (Officer):
- Email: officer@test.com
- Password: test1234
- Role: Officer

Account 2 (Admin):
- Email: admin@test.com
- Password: test1234
- Role: Admin
```

### Test Map Functionality
```
1. Go to /map
2. Hover over any marker
3. See device details popup
4. Click marker
5. Navigate to /devices page with device selected
```

### Check User Role in Browser
```
Open console (F12) and paste:
JSON.parse(localStorage.getItem('calibris_user'))

Shows:
{
  id: "...",
  email: "admin@test.com",
  displayName: "Your Name",
  role: "admin",     ← This is important
  createdAt: "..."
}
```

## 🚨 Troubleshooting Checklist

| Issue | Check |
|-------|-------|
| App won't start | Run `pnpm dev` from correct directory |
| Can't signup | Check `.env` has Firebase keys |
| Admin link missing | Logout and login again |
| Map blank | Check Google Maps API key in `.env` |
| No device markers | Refresh page, open console for errors |
| Redirected to home on /admin | You're not admin - check localStorage role |

## 📞 Getting Help

1. **Check browser console** (F12 → Console)
   - Look for red error messages
   - Copy full error text

2. **Check server logs** (terminal running `pnpm dev`)
   - Look for error messages from backend

3. **Read documentation**
   - Start with `docs/FIX_ADMIN_ACCESS_SUMMARY.md`
   - Then `docs/ADMIN_ACCESS_AND_MAP_TROUBLESHOOTING.md`

4. **Verify configuration**
   - Check `.env` file has all Firebase keys
   - Check Google Maps API key is set

## ✨ Features Working

✅ Firebase Authentication
✅ Role-Based Access Control (Admin/Officer)
✅ Admin Panel Route Protection
✅ Map Display with Device Markers
✅ Responsive Navigation
✅ User Session Persistence
✅ Logout Functionality
✅ Form Validation

---

**You're all set!** Start with the 5 steps above and you'll have a fully functional admin system with map access. 🎉
