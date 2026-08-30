# Admin Setup Guide

## Creating an Admin User

There are two ways to create an admin user for your Calibris application:

### Method 1: Sign Up and Then Promote to Admin (Recommended)

1. **Sign up** as a regular officer first
   - Go to `/auth/signup`
   - Select "Officer" role
   - Fill in details and create account

2. **Promote to Admin** via API call
   ```bash
   curl -X POST http://localhost:8080/api/auth/update-role \
     -H "Content-Type: application/json" \
     -d '{"email": "yourEmail@example.com", "role": "admin"}'
   ```

3. **Log out** and log back in to refresh your role

### Method 2: Sign Up as Admin Directly

1. **Sign up** with Admin role selected
   - Go to `/auth/signup`
   - Select "Admin" role
   - Fill in details and create account

2. **Verify** by logging out and logging back in
   - If Admin menu item appears in navbar, you're an admin ✓
   - If not, try the promotion method above

## Verifying Admin Status

### Check Your Role in Browser Console
```javascript
// Open browser console (F12)
// In Console tab, paste:
const user = JSON.parse(localStorage.getItem('calibris_user'));
console.log('Current role:', user?.role);
console.log('All user data:', user);
```

### Check User Info via API
```bash
curl http://localhost:8080/api/auth/user/yourEmail@example.com
```

## Admin Features

Once you're an admin, you should see:
- **All regular pages**: Dashboard, Devices, Map, Audit
- **Admin menu item** in the navbar (top navigation)
- **Admin panel** at `/admin` route
- **Full access** to all system features

## Troubleshooting Admin Access

| Problem | Solution |
|---------|----------|
| Admin menu not appearing after signup | Log out and log back in |
| Still don't see Admin link | Use the update-role API call above |
| Can see Admin link but page won't load | Check your user object in browser console |
| Map not showing devices | Check that devices exist in the system |

## Creating Demo Accounts

For testing:

```bash
# Create Officer account
# Go to /auth/signup
# Email: officer@demo.com
# Password: demo1234
# Role: Officer

# Create Admin account  
# Go to /auth/signup
# Email: admin@demo.com
# Password: demo1234
# Role: Admin (or sign up as officer then promote)
```

## Production Considerations

In production, you should:

1. **Protect the update-role endpoint**
   ```typescript
   // Add middleware to check if user is admin
   router.post("/update-role", requireAuth, requireRole("admin"), (req, res) => {
     // ... endpoint code
   });
   ```

2. **Use Firebase Custom Claims** instead of local file
   ```typescript
   // Set custom claims on Firebase user
   const customClaims = { role: "admin" };
   admin.auth().setCustomUserClaims(uid, customClaims);
   ```

3. **Audit role changes**
   - Log who changed which user's role
   - Track timestamp of changes
   - Store in audit log

## Need Help?

- Check `docs/FIREBASE_AUTH_SETUP.md` for full setup guide
- Check `docs/AUTH_QUICK_REFERENCE.md` for quick reference
- Check browser console for error messages
- Check server logs for backend errors

## API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login user (legacy) |
| GET | `/api/auth/user/:email` | Get user info by email |
| POST | `/api/auth/update-role` | Update user role |

## Quick Start

```bash
# 1. Start the app
pnpm dev

# 2. Go to http://localhost:8080/auth/signup

# 3. Sign up with admin role

# 4. Refresh the page or log out/in

# 5. Check navbar for Admin menu item

# 6. If not there, use:
curl -X POST http://localhost:8080/api/auth/update-role \
  -H "Content-Type: application/json" \
  -d '{"email": "your-email@example.com", "role": "admin"}'

# 7. Log out and back in

# 8. Admin menu should now appear!
```
