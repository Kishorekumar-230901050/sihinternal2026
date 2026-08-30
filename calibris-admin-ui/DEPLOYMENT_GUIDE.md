# 🚀 Calibris Deployment Guide

## Complete Guide to Deploy Backend (Railway) + Frontend (Vercel)

---

## ✅ Files Ready for Deployment

All necessary files have been created and configured:

### **Backend (Railway):**
- ✅ `server/production-server.ts` - Production backend server
- ✅ `railway.json` - Railway configuration
- ✅ `package.json` - Updated with production scripts

### **Frontend (Vercel):**
- ✅ `client/config/api.ts` - API configuration with environment variables
- ✅ `client/hooks/useTamperAlerts.ts` - Updated to use WS_URL
- ✅ `vercel.json` - Vercel configuration

---

## 📋 Pre-Deployment Checklist

### **1. GitHub Repository**
```bash
# Make sure all code is pushed to GitHub
git status
git add .
git commit -m "Prepare for Railway + Vercel deployment"
git push origin master
```

### **2. Database**
- ✅ Supabase PostgreSQL database URL ready
- ✅ Database migration `004-add-last-seen.sql` completed

---

## 🔧 Part 1: Deploy Backend to Railway

### **Step 1: Create Railway Account**
1. Go to https://railway.app
2. Click "Login" → Sign in with GitHub
3. Authorize Railway to access your GitHub repos

### **Step 2: Create New Project**
1. Click "New Project"
2. Select "Deploy from GitHub repo"
3. Choose your `Calibris-software` repository
4. Click "Deploy Now"

### **Step 3: Configure Environment Variables**

In Railway Dashboard → Your Project → Variables tab, add:

```
DATABASE_URL=your_supabase_postgres_url
NODE_ENV=production
PORT=3000
ALLOWED_ORIGINS=http://localhost:5173
```

**Replace `your_supabase_postgres_url` with your actual Supabase URL!**

### **Step 4: Wait for Deployment**
- Railway will automatically build and deploy (takes 1-2 minutes)
- Check the "Deployments" tab for progress
- Once deployed, you'll see a green "Success" status

### **Step 5: Get Your Railway URL**
1. Go to "Settings" tab
2. Under "Domains", you'll see your Railway URL
3. Example: `https://calibris-backend-production.up.railway.app`
4. **Copy this URL** - you'll need it for Vercel!

### **Step 6: Test Backend**
```bash
# Test health endpoint
curl https://your-railway-url.railway.app/health

# Should return:
# {"status":"ok","timestamp":"2025-12-10T...","environment":"production"}
```

---

## 🎨 Part 2: Deploy Frontend to Vercel

### **Step 1: Create Vercel Account**
1. Go to https://vercel.com
2. Click "Sign Up" → Sign up with GitHub
3. Authorize Vercel to access your GitHub repos

### **Step 2: Import Project**
1. Click "Add New..." → "Project"
2. Find and select your `Calibris-software` repository
3. Click "Import"

### **Step 3: Configure Build Settings**

Vercel should auto-detect these, but verify:

```
Framework Preset: Vite
Root Directory: ./
Build Command: npm run build:client
Output Directory: dist/client
Install Command: npm install
```

### **Step 4: Add Environment Variables**

Click "Environment Variables" and add:

```
VITE_API_URL=https://your-railway-url.railway.app/api
VITE_WS_URL=https://your-railway-url.railway.app
```

**IMPORTANT:** Replace `your-railway-url.railway.app` with the actual Railway URL from Step 1.5!

### **Step 5: Deploy**
1. Click "Deploy"
2. Vercel will build and deploy (takes 30-60 seconds)
3. Once done, you'll see "Congratulations!"

### **Step 6: Get Your Vercel URL**
- Vercel will show your deployment URL
- Example: `https://calibris-software.vercel.app`
- **Copy this URL** - you need to update Railway CORS!

---

## 🔗 Part 3: Connect Frontend & Backend

### **Step 1: Update Railway CORS**

Go back to Railway Dashboard → Variables → Edit `ALLOWED_ORIGINS`:

```
ALLOWED_ORIGINS=https://calibris-software.vercel.app,http://localhost:5173
```

**Replace with your actual Vercel URL!**

### **Step 2: Trigger Railway Redeploy**
1. Go to Railway → Deployments
2. Click the "..." menu on latest deployment
3. Click "Redeploy"

Wait for redeployment to complete (~1 minute)

### **Step 3: Test Integration**
1. Open your Vercel URL: `https://calibris-software.vercel.app`
2. Open browser console (F12)
3. Check Network tab - should see API calls to Railway
4. Should see "✅ Connected to WebSocket server" in console

---

## 🎯 Verification Checklist

### **Backend (Railway):**
```bash
# Test health endpoint
curl https://your-railway-url.railway.app/health
✅ Should return status: "ok"

# Test devices endpoint
curl https://your-railway-url.railway.app/api/devices
✅ Should return device array

# Check logs
Railway Dashboard → Deployments → View Logs
✅ Should see "Backend API server running on port 3000"
```

### **Frontend (Vercel):**
```
1. Open https://your-vercel-url.vercel.app
✅ Dashboard should load

2. Open browser console (F12)
✅ Should see "✅ Connected to WebSocket server"

3. Check Network tab
✅ API calls should go to Railway URL

4. Trigger test alert
✅ Real-time alert should appear
```

---

## 🐛 Troubleshooting

### **Problem: Frontend shows CORS error**
```
Error: "Access-Control-Allow-Origin header is missing"
```

**Solution:**
1. Check Railway `ALLOWED_ORIGINS` includes your Vercel URL
2. Verify no typos in the URL (http vs https, trailing slash)
3. Redeploy Railway after changing environment variables

### **Problem: WebSocket not connecting**
```
Error: "WebSocket connection failed"
```

**Solution:**
1. Check `VITE_WS_URL` in Vercel environment variables
2. Ensure it's the Railway URL (no `/api` at the end)
3. Redeploy Vercel after changing environment variables

### **Problem: API calls return 404**
```
Error: "GET /api/devices 404"
```

**Solution:**
1. Check `VITE_API_URL` ends with `/api`
2. Verify Railway backend is running (check logs)
3. Test health endpoint manually with curl

### **Problem: Database connection error**
```
Error: "Connection terminated unexpectedly"
```

**Solution:**
1. Check `DATABASE_URL` in Railway is correct
2. Verify Supabase database is active
3. Check Railway logs for specific error message

---

## 📱 Testing on Mobile

### **Test on Your Phone:**
1. Open browser on phone
2. Visit your Vercel URL
3. Dashboard should work perfectly!

### **Share with Others:**
- Just send them your Vercel URL
- Works on any device with internet!

---

## 🌐 Custom Domain Setup (Optional - Later)

### **For Frontend (Vercel):**
1. Buy domain (e.g., `calibris.in` from Namecheap)
2. Vercel Dashboard → Settings → Domains → Add Domain
3. Follow DNS configuration instructions
4. Result: `https://calibris.in` points to your app!

### **For Backend (Railway):**
1. Railway Dashboard → Settings → Domains → Custom Domain
2. Add subdomain: `api.calibris.in`
3. Update DNS with CNAME record
4. Result: `https://api.calibris.in` for backend!

### **Update Environment Variables:**

**Vercel:**
```
VITE_API_URL=https://api.calibris.in/api
VITE_WS_URL=https://api.calibris.in
```

**Railway:**
```
ALLOWED_ORIGINS=https://calibris.in,https://www.calibris.in
```

---

## 🔄 Making Changes After Deployment

### **Backend Changes:**
```bash
# 1. Make changes locally
# Edit server/routes/devices.ts

# 2. Test locally
npm run dev:api

# 3. Push to GitHub
git add server/routes/devices.ts
git commit -m "Add new device API endpoint"
git push origin master

# 4. Railway auto-deploys! (1-2 minutes)
```

### **Frontend Changes:**
```bash
# 1. Make changes locally
# Edit client/pages/Dashboard.tsx

# 2. Test locally
npm run dev

# 3. Push to GitHub
git add client/pages/Dashboard.tsx
git commit -m "Update dashboard UI"
git push origin master

# 4. Vercel auto-deploys! (30 seconds)
```

### **Database Changes:**
```bash
# 1. Create migration locally
# server/migrations/005-new-feature.sql

# 2. Test migration locally
npx tsx server/migrations/run-new-feature.ts

# 3. Run on production via Railway CLI or dashboard
```

---

## 💰 Cost Breakdown

```
Railway (Backend):
- Hobby Plan: $5/month
- Includes: 500GB bandwidth, PostgreSQL database

Vercel (Frontend):
- Hobby Plan: FREE
- Includes: 100GB bandwidth, unlimited deployments

Total: $5/month (Backend only)
```

---

## 📊 URLs Summary

After deployment, you'll have:

```
Frontend (Vercel):
https://calibris-software.vercel.app
↓ Calls API ↓

Backend (Railway):
https://calibris-backend.railway.app/api
```

**Save these URLs!** You'll need them to configure your Luckfox devices.

---

## ✅ Final Checklist

Before considering deployment complete:

```
☐ Railway backend deployed and running
☐ Railway health endpoint responds
☐ Vercel frontend deployed
☐ Frontend loads in browser
☐ API calls from frontend to backend work
☐ WebSocket connects successfully
☐ Real-time alerts working
☐ Database queries work
☐ CORS configured correctly
☐ Environment variables set correctly
☐ Both URLs saved for future reference
```

---

## 🎉 Success!

Your Calibris software is now deployed and accessible from anywhere in the world!

**Frontend:** `https://your-app.vercel.app`
**Backend API:** `https://your-backend.railway.app/api`

Share the Vercel URL with your team, jury, or anyone who needs access!

---

## 📞 Need Help?

If you encounter issues:

1. **Check Railway logs:**
   - Railway Dashboard → Deployments → View Logs

2. **Check Vercel logs:**
   - Vercel Dashboard → Deployments → View Function Logs

3. **Check browser console:**
   - F12 → Console tab
   - Look for error messages

4. **Test endpoints manually:**
   ```bash
   curl https://your-railway-url/health
   curl https://your-railway-url/api/devices
   ```

Good luck with your deployment! 🚀
