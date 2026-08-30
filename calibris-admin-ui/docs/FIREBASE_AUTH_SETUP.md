# Firebase Authentication Setup Guide

This guide explains the professional Firebase authentication system set up for your Calibris application with role-based access control (Admin/Officer).

## Overview

The authentication system uses:
- **Firebase Authentication** for user management and password security
- **Role-based Access Control** (RBAC) with Admin and Officer roles
- **JWT Tokens** for session management
- **Protected Routes** that redirect unauthorized users
- **Professional UI** with sign-in and sign-up pages

## File Structure

### Frontend Files

1. **`client/lib/firebase.ts`** - Firebase app initialization
   - Initializes Firebase with your credentials
   - Exports auth, db, and storage instances
   - Configuration comes from `.env` variables

2. **`client/lib/auth.ts`** - Firebase authentication functions
   - `loginUser()` - Sign in with email/password
   - `registerUser()` - Create new account
   - `logoutUser()` - Sign out
   - `onAuthStateChanged()` - Listen to auth changes
   - Other utilities for password reset, profile updates

3. **`client/context/AuthContext.tsx`** - React auth state management
   - Manages logged-in user state
   - Provides `useAuth()` hook for any component
   - Handles Firebase authentication events
   - Persists user data in localStorage

4. **`client/pages/Auth/Login.tsx`** - Professional login page
   - Role selection (Admin / Officer tabs)
   - Email & password fields
   - Form validation
   - Error handling
   - Link to sign-up page

5. **`client/pages/Auth/SignUp.tsx`** - Professional sign-up page
   - Role selection during registration
   - Display name, email, password fields
   - Password confirmation
   - Terms agreement checkbox
   - Form validation

6. **`client/App.tsx`** - Main application with routing
   - Updated routes with auth protection
   - `PrivateRoute` component for protected pages
   - Role-based route restrictions
   - Loading states

### Backend Files

1. **`server/routes/auth.ts`** - Express auth endpoints
   - `POST /api/auth/register` - Register new Firebase users
   - `POST /api/auth/login` - Legacy login (for non-Firebase auth)
   - User data persistence in `server/data/users.json`

### Configuration Files

1. **`.env`** - Environment variables (with your actual credentials)
   - `VITE_PUBLIC_FIREBASE_API_KEY` - Firebase API Key
   - `VITE_PUBLIC_FIREBASE_AUTH_DOMAIN` - Firebase Auth Domain
   - `VITE_PUBLIC_FIREBASE_PROJECT_ID` - Firebase Project ID
   - `VITE_PUBLIC_FIREBASE_STORAGE_BUCKET` - Firebase Storage Bucket
   - `VITE_PUBLIC_FIREBASE_MESSAGING_SENDER_ID` - Firebase Messaging ID
   - `VITE_PUBLIC_FIREBASE_APP_ID` - Firebase App ID

2. **`.env.example`** - Template for environment variables
   - Safe to commit to git
   - Shows structure without exposing secrets
   - For new developers to set up their own `.env`

## How It Works

### Authentication Flow

1. **User visits application** → Redirected to `/auth/login` if not authenticated
2. **User selects role** (Admin or Officer)
3. **User enters credentials** → Firebase validates them
4. **Firebase returns auth token** → Stored in React state & localStorage
5. **User redirected to dashboard** → Can now access protected pages
6. **Role-based access** → Certain pages only accessible to specific roles

### Role-Based Access Control (RBAC)

**Officer Role:**
- Access: Dashboard, Devices, Map, Audit
- Denied: Admin panel

**Admin Role:**
- Access: All pages including Admin panel
- Full system access

### Protected Routes

Routes are protected using the `PrivateRoute` component:

```tsx
<Route
  path="/admin"
  element={
    <PrivateRoute requiredRoles={["admin"]}>
      <AdminPage />
    </PrivateRoute>
  }
/>
```

If a user tries to access restricted pages, they are redirected to `/`.

## Usage

### For Users

1. **Sign In**
   - Visit `/auth/login`
   - Select role (Admin or Officer)
   - Enter email and password
   - Click "Sign In"

2. **Sign Up (Create New Account)**
   - Click "Create an Account" link on login page
   - Fill in name, email, password
   - Select role (Admin or Officer)
   - Agree to terms
   - Click "Create Account"

3. **Sign Out**
   - Click avatar in navbar
   - Click "Logout"

### For Developers

#### Using Authentication in Components

```typescript
import { useAuth } from "@/context/AuthContext";

export function MyComponent() {
  const { user, login, logout, signup } = useAuth();

  // Check if user is logged in
  if (!user) return <div>Please log in</div>;

  // Access user info
  console.log(user.email, user.role, user.displayName);

  // Perform login
  await login("user@example.com", "password123", "officer");

  // Perform logout
  await logout();

  return <div>Welcome, {user.displayName}!</div>;
}
```

#### Protecting Routes

```typescript
// Officer + Admin access
<Route path="/devices" element={<PrivateRoute><DevicesPage /></PrivateRoute>} />

// Admin only
<Route
  path="/admin"
  element={
    <PrivateRoute requiredRoles={["admin"]}>
      <AdminPage />
    </PrivateRoute>
  }
/>
```

#### Conditional UI Based on Role

```typescript
import { useAuth } from "@/context/AuthContext";

export function Component() {
  const { user } = useAuth();

  return (
    <>
      {user?.role === "admin" && <AdminPanel />}
      {user?.role === "officer" && <OfficerPanel />}
    </>
  );
}
```

## Security Considerations

### Public vs. Private Keys

- **Public (VITE_PUBLIC_ prefix)**: Safe to expose in client-side code
  - Firebase API Key
  - Project ID
  - Auth Domain
  - Storage Bucket
  - App ID
  
- **Private (no prefix)**: Keep secret, use only on server
  - `JWT_SECRET` - Used for JWT signing
  - Firebase Admin SDK keys

### Environment Variables

- `.env` contains your actual credentials - **Never commit this file**
- `.env.example` is a template - **Safe to commit**
- In production, use your hosting provider's secret manager (Vercel, Netlify, etc.)

### Password Security

- Firebase handles password hashing and encryption
- Passwords are never stored in your database
- All passwords are transmitted over HTTPS
- Never log or expose passwords in console

### Token Handling

- Auth tokens are stored in localStorage
- In production, consider using httpOnly cookies for better security
- Tokens have expiration times
- Refresh tokens automatically via `onAuthStateChanged`

## Demo Credentials

For testing, you can use these credentials (if created in Firebase):

```
Email: demo@calibris.com
Password: demo1234
```

Create actual test users in Firebase Console for development.

## Deployment

### Before Deploying

1. **Set environment variables** on your hosting platform:
   - Use your platform's secret manager (Vercel Secrets, Netlify Environment, etc.)
   - Add all `VITE_PUBLIC_*` variables
   - Add `JWT_SECRET`

2. **Enable Firebase Services**:
   - Go to Firebase Console
   - Enable Authentication (Email/Password)
   - Configure Firestore Database (if needed)
   - Set up Security Rules

3. **Test in staging**:
   - Test sign-up with new email
   - Test sign-in with test account
   - Test role-based access
   - Verify admin can access all pages

### Platforms with Easy Setup

- **Vercel**: Env variables in project settings
- **Netlify**: Environment variables in site settings
- **Heroku**: Config variables

## Troubleshooting

### Issue: "Firebase config is missing"

**Solution**: Check that all `VITE_PUBLIC_FIREBASE_*` variables are set in `.env`

### Issue: "Cannot read property 'email' of null"

**Solution**: User is not authenticated. Wrap component in `PrivateRoute` or check `user` before accessing properties.

### Issue: "Login fails with invalid credentials"

**Solution**: 
- Make sure user account exists in Firebase
- Check that email/password are correct
- Verify Firebase Authentication is enabled in console

### Issue: "Officer can access admin pages"

**Solution**: 
- Check `PrivateRoute` has correct `requiredRoles` prop
- Verify user role is set correctly in Firebase custom claims
- Clear localStorage and log in again

## Next Steps

1. **Connect to Database**: Store user preferences in Firestore
2. **Add Email Verification**: Require email confirmation
3. **Implement 2FA**: Add two-factor authentication
4. **Social Login**: Add Google/GitHub sign-in
5. **Custom Claims**: Set admin/officer roles via Firebase Admin SDK
6. **Activity Logging**: Log login/logout events for audit trail

## Resources

- [Firebase Authentication Docs](https://firebase.google.com/docs/auth)
- [Firebase Console](https://console.firebase.google.com)
- [React Router Docs](https://reactrouter.com)
- [Material-UI Docs](https://mui.com)

## Support

For issues or questions:
1. Check Firebase Console for errors
2. Review browser console for JavaScript errors
3. Check network tab to see API responses
4. Review server logs for backend errors
