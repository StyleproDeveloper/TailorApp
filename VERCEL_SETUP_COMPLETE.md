# 🚀 Complete Vercel Setup Guide for Tailor App

This guide will help you set up both **Frontend** and **Backend** projects correctly in Vercel.

## 📋 Prerequisites

- GitHub repository: `StyleproDeveloper/TailorApp`
- Vercel account (sign up at https://vercel.com)
- MongoDB Atlas connection string

---

## 🎨 **PART 1: Frontend Project Setup**

### Step 1: Create Frontend Project

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Click **"Add New..."** → **"Project"**
3. Click **"Import Git Repository"**
4. Select: **StyleproDeveloper/TailorApp**
5. Click **"Import"**

### Step 2: Configure Frontend Project

**Project Name:** `tailorapp-frontend` (or any name you prefer)

**Framework Preset:** `Other`

**Root Directory:** `./` (leave empty or set to `./`)

**Build Command:**
```bash
chmod +x build.sh && bash build.sh
```

**Output Directory:**
```
build/web
```

**Install Command:**
```bash
echo 'Install handled in build script'
```

**Node.js Version:** `18.x` or `20.x` (Vercel will auto-detect)

### Step 3: Environment Variables (Frontend)

**No environment variables needed for frontend** - it auto-detects the backend URL.

### Step 4: Deploy Frontend

1. Click **"Deploy"**
2. Wait 5-10 minutes for the build to complete (Flutter installation takes time)
3. Once deployed, note the deployment URL (e.g., `https://tailorapp-frontend-xxx.vercel.app`)

---

## 🔧 **PART 2: Backend Project Setup**

### Step 1: Create Backend Project

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Click **"Add New..."** → **"Project"**
3. Click **"Import Git Repository"**
4. Select: **StyleproDeveloper/TailorApp** (same repo)
5. Click **"Import"**

### Step 2: Configure Backend Project

**Project Name:** `tailorapp-backend` (or any name you prefer)

**Framework Preset:** `Other`

**Root Directory:** `./backend` ⚠️ **IMPORTANT: Set this to `./backend`**

**Build Command:**
```bash
npm install
```
(Or leave empty - Vercel will auto-detect from package.json)

**Output Directory:** Leave empty (not needed for Node.js)

**Install Command:** Leave empty (auto-detected)

**Node.js Version:** `18.x` or `20.x`

### Step 3: Environment Variables (Backend)

Go to **Settings** → **Environment Variables** and add:

| Variable Name | Value | Environment |
|--------------|-------|-------------|
| `MONGO_URL` | `mongodb+srv://...` (your MongoDB Atlas connection string) | Production, Preview, Development |
| `NODE_ENV` | `production` | Production, Preview, Development |
| `JWT_SECRET` | `your-secret-key-here` (generate a random string) | Production, Preview, Development |
| `PORT` | `5500` | Production, Preview, Development |

**How to get MongoDB connection string:**
1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Click "Connect" on your cluster
3. Choose "Connect your application"
4. Copy the connection string
5. Replace `<password>` with your database password

### Step 4: Deploy Backend

1. Click **"Deploy"**
2. Wait 2-3 minutes for the build
3. Once deployed, note the deployment URL (e.g., `https://tailorapp-backend-xxx.vercel.app`)

---

## ✅ **Verification Steps**

### Test Frontend:
1. Visit your frontend URL
2. Check browser console for errors
3. Verify it shows: `✅ Using PRODUCTION backend: https://...`

### Test Backend:
1. Visit: `https://your-backend-url.vercel.app/`
2. Should see: `{"success":true,"status":200,"message":"Tailor App Backend API is running!"}`
3. Test API docs: `https://your-backend-url.vercel.app/api-docs`

### Test CORS:
1. Open frontend in browser
2. Try to login
3. Check browser console - should NOT see CORS errors

---

## 🔄 **Updating Backend URL in Frontend**

If your backend URL changes, update it in:
- File: `lib/Core/Services/Urls.dart`
- Line 23: Update the backend URL

Then redeploy the frontend.

---

## 📝 **Project Summary**

After setup, you should have:

### Frontend Project:
- **Name:** `tailorapp-frontend`
- **Root:** `./`
- **URL:** `https://tailorapp-frontend-xxx.vercel.app`
- **Build:** Flutter web app

### Backend Project:
- **Name:** `tailorapp-backend`
- **Root:** `./backend` ⚠️ **CRITICAL**
- **URL:** `https://tailorapp-backend-xxx.vercel.app`
- **Build:** Node.js API

---

## 🚨 **Common Issues & Solutions**

### Issue 1: Frontend build fails with "Flutter not found"
**Solution:** The build script will install Flutter automatically. Just wait 5-10 minutes.

### Issue 2: Backend returns 404
**Solution:** Make sure **Root Directory** is set to `./backend` in backend project settings.

### Issue 3: CORS errors
**Solution:** 
- Verify backend has CORS headers in `backend/vercel.json`
- Check backend deployment includes latest code with CORS fixes
- Hard refresh browser (Ctrl+Shift+R)

### Issue 4: MongoDB connection fails
**Solution:**
- Verify `MONGO_URL` environment variable is set correctly
- Check MongoDB Atlas allows connections from anywhere (0.0.0.0/0)
- Verify database user password is correct

### Issue 5: Backend shows "Cannot GET /"
**Solution:** This is normal for root path. Test `/api-docs` or `/shops` endpoints instead.

---

## 🎯 **Quick Setup Checklist**

- [ ] Frontend project created with correct root directory (`./`)
- [ ] Frontend build command set: `chmod +x build.sh && bash build.sh`
- [ ] Frontend output directory set: `build/web`
- [ ] Backend project created with root directory (`./backend`) ⚠️
- [ ] Backend environment variables set (MONGO_URL, NODE_ENV, JWT_SECRET, PORT)
- [ ] Both projects deployed successfully
- [ ] Frontend URL tested and working
- [ ] Backend health check works (`/` endpoint)
- [ ] CORS working (no errors in browser console)
- [ ] Login functionality tested

---

## 📞 **Need Help?**

If you encounter issues:
1. Check Vercel build logs for errors
2. Verify all configuration matches this guide
3. Ensure environment variables are set correctly
4. Check MongoDB Atlas connection settings

**Remember:** The most common mistake is forgetting to set **Root Directory** to `./backend` for the backend project!

