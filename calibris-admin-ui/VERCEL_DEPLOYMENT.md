# Vercel Frontend Deployment Guide

## ✅ Prerequisites Completed
- ✅ Backend deployed to Railway: https://calibris-fullstack-production.up.railway.app
- ✅ Backend health check passing
- ✅ Code pushed to GitHub: https://github.com/Poovannan-vp/calibris-fullstack.git
- ✅ All configuration files ready

## 🚀 Deploy to Vercel (Step-by-Step)

### Step 1: Go to Vercel
1. Open https://vercel.com
2. Click **"Sign Up"** or **"Log In"**
3. Sign in with your **GitHub account**

### Step 2: Import Your Project
1. Click **"Add New..."** → **"Project"**
2. You'll see a list of your GitHub repositories
3. Find **"Poovannan-vp/calibris-fullstack"**
4. Click **"Import"**

### Step 3: Configure Project Settings
Vercel will auto-detect settings from `vercel.json`. Verify:
- **Framework Preset**: Vite
- **Build Command**: `npm run build:client`
- **Output Directory**: `dist/client`
- **Install Command**: `npm install`

### Step 4: Add Environment Variables
Click **"Environment Variables"** and add these:

#### Required API Variables:
```
VITE_API_URL=https://calibris-fullstack-production.up.railway.app/api
VITE_WS_URL=https://calibris-fullstack-production.up.railway.app
```

#### Required Firebase Variables (from your .env file):
```
VITE_PUBLIC_FIREBASE_API_KEY=AIzaSyDNUTDCPjYxC8vGxGomW6BuMBcwWTBwR68
VITE_PUBLIC_FIREBASE_AUTH_DOMAIN=calibirs-auth.firebaseapp.com
VITE_PUBLIC_FIREBASE_PROJECT_ID=calibirs-auth
VITE_PUBLIC_FIREBASE_STORAGE_BUCKET=calibirs-auth.firebasestorage.app
VITE_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=508807516918
VITE_PUBLIC_FIREBASE_APP_ID=1:508807516918:web:328c5f7e8bce86d0c752d7
```

#### Required Google Maps Variable (for map display):
```
VITE_PUBLIC_GOOGLE_MAPS_KEY=AIzaSyDqd9N-rTDtGoUMCnjRs93-Jv89HnbCj5M
```

#### Optional Variables:
```
VITE_PUBLIC_BUILDER_KEY=__BUILDER_PUBLIC_KEY__
```

**💡 Tip**: For each variable:
- Click **"Add"**
- Enter **Name** (e.g., `VITE_API_URL`)
- Enter **Value** (e.g., `https://calibris-fullstack-production.up.railway.app/api`)
- Select **"Production, Preview, Development"** (all environments)
- Click **"Save"**

### Step 5: Deploy
1. Click **"Deploy"**
2. Wait 2-3 minutes for build to complete
3. You'll get a URL like: `https://your-project-name.vercel.app`

### Step 6: Update Railway CORS
After deployment, you need to update Railway to allow your Vercel URL:

1. Go to Railway dashboard: https://railway.app
2. Select your **calibris-fullstack-production** project
3. Go to **Variables** tab
4. Find or add **ALLOWED_ORIGINS**
5. Update value to include your Vercel URL:
```
https://your-project-name.vercel.app,http://localhost:5173,http://localhost:3000
```
6. Click **"Save"**
7. Railway will automatically redeploy

## 🧪 Testing After Deployment

### 1. Test Frontend
Open your Vercel URL: `https://your-project-name.vercel.app`

You should see:
- ✅ Login page loads
- ✅ No CORS errors in browser console (F12)
- ✅ Can log in successfully

### 2. Test Real-Time Alerts
1. Open browser console (F12)
2. Check for WebSocket connection:
```
✅ Client connected: [socket-id]
```

### 3. Test API Connection
1. Log in to the dashboard
2. Check if devices are loading
3. Test adding a device
4. Verify tamper alerts work

## 🔧 Troubleshooting

### Build Fails on Vercel
**Issue**: Build fails with missing dependencies
**Fix**:
- Check that `package.json` has all frontend dependencies
- Verify `vercel.json` has correct build command

### CORS Errors
**Issue**: Browser shows CORS policy errors
**Fix**:
- Verify `ALLOWED_ORIGINS` in Railway includes your Vercel URL
- Make sure URL format matches exactly (no trailing slash)

### WebSocket Not Connecting
**Issue**: Real-time alerts not working
**Fix**:
- Check `VITE_WS_URL` environment variable in Vercel
- Verify it matches Railway URL exactly
- Check browser console for connection errors

### Environment Variables Not Working
**Issue**: App shows "localhost" in network requests
**Fix**:
- Go to Vercel → Project → Settings → Environment Variables
- Verify all variables are set for "Production" environment
- Redeploy: Deployments → Click "..." → "Redeploy"

## 📝 Post-Deployment Checklist

- [ ] Frontend deployed to Vercel
- [ ] Backend accessible from frontend (no CORS errors)
- [ ] WebSocket connection established
- [ ] Login/authentication working
- [ ] Device management working
- [ ] Real-time tamper alerts working
- [ ] Updated Railway ALLOWED_ORIGINS with Vercel URL

## 🎉 Success!

Once everything is working:
- **Frontend URL**: https://your-project-name.vercel.app
- **Backend URL**: https://calibris-fullstack-production.up.railway.app
- **Database**: Railway PostgreSQL

Your Calibris Tamper Detection System is now **fully deployed and operational**!

## 🔐 Security Notes

- ✅ All secrets are in environment variables (not in code)
- ✅ .env files are protected by .gitignore
- ✅ CORS is configured for specific origins only
- ✅ Backend validates all incoming requests
- ✅ Firebase handles authentication securely

## 📞 Support

If you encounter issues:
1. Check browser console (F12) for errors
2. Check Railway logs for backend errors
3. Check Vercel deployment logs for build errors
4. Verify all environment variables are set correctly
