# Admin Access & Map Functionality - Troubleshooting Guide

## Issues Fixed

### 1. Admin Page Not Showing After Login as Admin

**Problem**: After signing up as Admin, the "Admin" menu item doesn't appear in navbar.

**Root Cause**: The role wasn't being persisted properly from Firebase to the auth context.

**Solution Applied**:
- Updated `AuthContext.tsx` login function to fetch user role from multiple sources:
  1. Firebase custom claims (if set)
  2. Backend API `/api/auth/user/:email` (fallback)
  3. Default role if neither available
- Updated signup to call `/api/auth/register` API which stores the role
- Added role persistence in localStorage

### 2. Map Not Showing Devices

**Problem**: Map component displays but no device markers/pins visible.

**Root Cause**: This is likely due to:
- Google Maps API key not being set
- Devices not being loaded into the store
- Map container not initializing properly

**Solution Applied**:
- Added `/map` route to navbar links
- Verified MapView component has proper device handling
- Verified mock devices exist with lat/lng coordinates
- MapView uses robust initialization with IntersectionObserver, ResizeObserver, and polling

### 3. Missing Map Route in Navbar

**Problem**: Map page exists but isn't in navigation menu.

**Solution Applied**:
- Added `{ to: "/map", label: "Map" }` to navbar links array
- Now all users can access Map page

## Verification Steps

### Step 1: Check Admin Access

1. **Sign Up as Admin**
   ```
   Go to http://localhost:8080/auth/signup
   - Full Name: Test Admin
   - Email: admin@test.com
   - Password: admin123
   - Role: Select "Admin"
   - Check Terms
   - Click "Create Account"
   ```

2. **Verify Admin Link Appears**
   ```
   Look at navbar - should see: Dashboard | Devices | Map | Audit | Admin
   ```

3. **Click Admin Link**
   ```
   Should navigate to /admin page without redirecting
   ```

4. **Check Browser Console**
   ```
   Press F12 → Console tab
   Paste: JSON.parse(localStorage.getItem('calibris_user'))
   
   Should show:
   {
     id: "...",
     email: "admin@test.com",
     displayName: "Test Admin",
     role: "admin",  // <-- This is important!
     createdAt: "..."
   }
   ```

### Step 2: Check Map Display

1. **Navigate to Map**
   ```
   Click "Map" in navbar or go to http://localhost:8080/map
   ```

2. **Verify Map Loads**
   ```
   Should see:
   - Map container with "Map" heading
   - Filters panel
   - Actual Google Map (grayish background)
   - Device markers with colored pins (red, orange, green, gray)
   ```

3. **Check Device Markers**
   ```
   Map should show pins at these locations:
   - Mumbai (red - Tampered)
   - Bengaluru (orange - Drifted)
   - Chennai (red - Tampered)
   - Delhi (red - Tampered)
   - And more...
   ```

4. **Hover Over Markers**
   ```
   Should see popup with:
   - Device ID
   - Status
   - Location
   ```

5. **Click Markers**
   ```
   Should navigate to /devices page with that device selected
   ```

### Step 3: Test Both Roles

**As Officer**:
1. Sign up with role: "Officer"
2. Navbar should show: Dashboard | Devices | Map | Audit
3. NO "Admin" link
4. Try accessing `/admin` → Should redirect to home

**As Admin**:
1. Sign up with role: "Admin"
2. Navbar should show: Dashboard | Devices | Map | Audit | Admin
3. Can click "Admin" link
4. Admin page loads successfully

## API Endpoints for Testing

### Get User by Email
```bash
curl http://localhost:8080/api/auth/user/admin@test.com
```

Response:
```json
{
  "user": {
    "id": "...",
    "email": "admin@test.com",
    "firstName": "Test",
    "lastName": "Admin",
    "role": "admin"
  }
}
```

### Update User Role
```bash
curl -X POST http://localhost:8080/api/auth/update-role \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@test.com", "role": "admin"}'
```

## If Issues Persist

### Admin Link Not Showing

1. **Check localStorage**
   ```javascript
   JSON.parse(localStorage.getItem('calibris_user')).role
   // Should be "admin"
   ```

2. **Force role update via API**
   ```bash
   curl -X POST http://localhost:8080/api/auth/update-role \
     -H "Content-Type: application/json" \
     -d '{"email": "your-email@test.com", "role": "admin"}'
   ```

3. **Log out and back in**
   - This refreshes the auth context with the latest role

### Map Not Showing Devices

1. **Check Google Maps API Key**
   ```
   In browser console:
   > import.meta.env.VITE_GOOGLE_MAPS_KEY
   // Should return your API key
   ```

2. **Check if devices loaded**
   ```
   In browser console:
   > localStorage.getItem('__store_devices')
   // Should show array of devices
   ```

3. **Check browser console for errors**
   ```
   Look for red error messages about:
   - Google Maps API
   - Missing coordinates
   - Script loading issues
   ```

4. **Check network tab**
   ```
   F12 → Network tab
   Filter by "maps"
   Should see requests to googleapis.com
   Status should be 200 (success)
   ```

## File Changes Made

1. **`client/context/AuthContext.tsx`**
   - Updated `login()` function to fetch role from backend
   - Improved role persistence

2. **`client/components/Navbar.tsx`**
   - Added `/map` to navbar links array
   - Already had admin-only link logic

3. **`server/routes/auth.ts`**
   - Added `GET /api/auth/user/:email` endpoint
   - Added `POST /api/auth/update-role` endpoint

4. **Documentation**
   - Created `docs/ADMIN_SETUP.md` - Admin setup guide
   - This file for troubleshooting

## Tech Stack Used

- **Frontend**: React, Firebase Auth, React Router
- **Backend**: Express.js
- **Storage**: Firebase + localStorage + JSON file
- **Maps**: Google Maps API
- **State Management**: React Context

## Next Steps

1. ✅ **Admin access working** - Check by creating admin account
2. ✅ **Map showing devices** - Check by navigating to /map
3. (Optional) **Set up Firestore** - For production user role storage
4. (Optional) **Add 2FA** - Email verification or SMS
5. (Optional) **Custom styling** - Brand your admin panel

## Quick Commands

```bash
# Start development
pnpm dev

# Run type check
pnpm typecheck

# Build for production
pnpm build

# Run production
pnpm start
```

## Common Errors & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| Admin link doesn't appear | Wrong role in localStorage | Log out and back in |
| Map shows blank/gray | Google Maps API key missing | Check `.env` file |
| No device markers | No devices in store | Check mock data is loaded |
| Markers not clickable | JavaScript error in console | Check browser console for errors |
| Route redirects to home | Role-based access denied | Check user role in localStorage |

## Support

- Full auth guide: `docs/FIREBASE_AUTH_SETUP.md`
- Quick reference: `docs/AUTH_QUICK_REFERENCE.md`
- Admin setup: `docs/ADMIN_SETUP.md`

For more help, check the browser console (F12) and server logs.
