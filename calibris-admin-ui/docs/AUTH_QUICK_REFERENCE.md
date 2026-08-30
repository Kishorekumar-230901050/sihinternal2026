# Firebase Auth Quick Reference

## Setup (One-Time)

1. **Add Firebase credentials to `.env`**
   ```bash
   VITE_PUBLIC_FIREBASE_API_KEY=your-key
   VITE_PUBLIC_FIREBASE_AUTH_DOMAIN=your-domain.firebaseapp.com
   VITE_PUBLIC_FIREBASE_PROJECT_ID=your-project
   VITE_PUBLIC_FIREBASE_STORAGE_BUCKET=your-bucket
   VITE_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your-sender-id
   VITE_PUBLIC_FIREBASE_APP_ID=your-app-id
   ```

2. **Enable Authentication in Firebase Console**
   - Go to Authentication → Sign-in methods
   - Enable "Email/Password"

3. **Start the app**
   ```bash
   pnpm dev
   ```

## User Flows

### Sign Up (New User)
1. Click "Create an Account" on login page
2. Select role (Admin/Officer)
3. Fill form and submit
4. Auto-redirected to dashboard

### Sign In (Existing User)
1. Go to `/auth/login`
2. Select role (Admin/Officer)
3. Enter credentials
4. Auto-redirected to dashboard

### Sign Out
1. Click avatar in navbar
2. Click "Logout"
3. Redirected to `/auth/login`

## Role Access

| Page | Officer | Admin |
|------|---------|-------|
| Dashboard | ✓ | ✓ |
| Devices | ✓ | ✓ |
| Map | ✓ | ✓ |
| Audit | ✓ | ✓ |
| Admin | ✗ | ✓ |

## Code Examples

### Use Auth Hook
```tsx
import { useAuth } from "@/context/AuthContext";

export function MyComponent() {
  const { user, logout } = useAuth();
  
  return (
    <div>
      <p>Welcome, {user?.displayName}</p>
      <p>Role: {user?.role}</p>
      <button onClick={logout}>Logout</button>
    </div>
  );
}
```

### Protect a Route
```tsx
<Route 
  path="/admin" 
  element={<PrivateRoute requiredRoles={["admin"]}><Admin /></PrivateRoute>}
/>
```

### Show Content by Role
```tsx
{user?.role === "admin" && <AdminPanel />}
{user?.role === "officer" && <OfficerPanel />}
```

## Key Files

| File | Purpose |
|------|---------|
| `client/lib/firebase.ts` | Firebase setup |
| `client/lib/auth.ts` | Auth functions |
| `client/context/AuthContext.tsx` | Auth state |
| `client/pages/Auth/Login.tsx` | Login page |
| `client/pages/Auth/SignUp.tsx` | Signup page |
| `.env` | Your credentials |
| `.env.example` | Template |

## Environment Variables

```
# Public (safe to expose)
VITE_PUBLIC_FIREBASE_API_KEY
VITE_PUBLIC_FIREBASE_AUTH_DOMAIN
VITE_PUBLIC_FIREBASE_PROJECT_ID
VITE_PUBLIC_FIREBASE_STORAGE_BUCKET
VITE_PUBLIC_FIREBASE_MESSAGING_SENDER_ID
VITE_PUBLIC_FIREBASE_APP_ID

# Private (server only)
JWT_SECRET
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Firebase config missing | Check `.env` has all VITE_PUBLIC_* vars |
| Login fails | Create user first via signup or Firebase Console |
| Officer accessing admin pages | Check route has `requiredRoles={["admin"]}` |
| Not logged in after refresh | Check localStorage isn't disabled |

## Testing

```bash
# TypeScript check
pnpm typecheck

# Development
pnpm dev

# Production build
pnpm build

# Run production
pnpm start
```

## Deploy

1. Set env variables on hosting platform
2. Enable Firebase Authentication
3. Test sign-up and role access
4. Deploy!

## Docs

- Full guide: `docs/FIREBASE_AUTH_SETUP.md`
- Implementation: `docs/AUTH_IMPLEMENTATION_SUMMARY.md`
- Firebase: https://firebase.google.com/docs/auth
