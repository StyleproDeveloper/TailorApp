# ✅ Backend Deployment Checklist

## 🎯 Pre-Deployment Checklist

### ✅ Code is Ready:
- [x] `backend/vercel.json` - Fixed (uses `rewrites` instead of `routes`)
- [x] `backend/api/index.js` - Optimized for serverless functions
- [x] CORS headers configured in `vercel.json`
- [x] MongoDB connection optimized for serverless

### ⚠️ **CRITICAL: Environment Variables** (Set in Vercel Dashboard)

Before deploying, make sure to set these in **Vercel Project Settings → Environment Variables**:

| Variable | Value | Required | Notes |
|----------|-------|----------|-------|
| `MONGO_URL` | `mongodb+srv://...` | ✅ **YES** | Your MongoDB Atlas connection string |
| `NODE_ENV` | `production` | ✅ **YES** | Set to production |
| `JWT_SECRET` | `your-random-secret` | ✅ **YES** | Any random string (keep it secret!) |
| `PORT` | `5500` | ⚠️ Optional | Defaults to 5500 if not set |

**How to get MONGO_URL:**
1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Click "Connect" on your cluster
3. Choose "Connect your application"
4. Copy the connection string
5. Replace `<password>` with your database password

---

## 🚀 Deployment Steps

### Step 1: Create Project in Vercel
1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Click **"Add New..."** → **"Project"**
3. Import: `StyleproDeveloper/TailorApp`

### Step 2: Configure Project Settings

**Project Name:** `tailorapp-backend` (or any name)

**Framework Preset:** `Other`

**Root Directory:** `./backend` ⚠️ **CRITICAL - MUST SET THIS**

**Build Command:** `npm install` (or leave empty - auto-detected)

**Output Directory:** (leave empty)

**Node.js Version:** `18.x` or `20.x`

### Step 3: Set Environment Variables

**Before clicking Deploy**, go to **Environment Variables** and add:

```
MONGO_URL=mongodb+srv://username:password@cluster.mongodb.net/dbname?retryWrites=true&w=majority
NODE_ENV=production
JWT_SECRET=your-random-secret-key-here-make-it-long-and-random
PORT=5500
```

**Important:** 
- Set for **Production**, **Preview**, and **Development** environments
- Click "Add" for each variable

### Step 4: Deploy

1. Click **"Deploy"**
2. Wait 2-3 minutes for build
3. Check build logs for any errors

### Step 5: Verify Deployment

1. **Test Health Check:**
   ```
   https://your-backend-url.vercel.app/
   ```
   Should return: `{"success":true,"status":200,"message":"Tailor App Backend API is running!"}`

2. **Test API Docs:**
   ```
   https://your-backend-url.vercel.app/api-docs
   ```
   Should show Swagger documentation

3. **Check Logs:**
   - Go to Deployment → Functions tab
   - Look for: `✅ Connected to MongoDB`
   - No errors should appear

---

## 🔍 Troubleshooting

### Issue: Function crashes with 500 error
**Check:**
- [ ] `MONGO_URL` is set correctly
- [ ] MongoDB Atlas allows connections from anywhere (0.0.0.0/0)
- [ ] Database user password is correct
- [ ] Check deployment logs for specific error

### Issue: CORS errors
**Solution:** Already configured in `vercel.json` - should work automatically

### Issue: 404 errors
**Check:**
- [ ] Root Directory is set to `./backend`
- [ ] `api/index.js` exists in backend folder

### Issue: MongoDB connection fails
**Check:**
- [ ] `MONGO_URL` format is correct (starts with `mongodb+srv://`)
- [ ] Password in URL is URL-encoded (special characters)
- [ ] MongoDB Atlas Network Access allows 0.0.0.0/0
- [ ] Database user has correct permissions

---

## 📝 After Deployment

1. **Note the Backend URL:**
   - Example: `https://backend-xxx.vercel.app`
   - You'll need this for frontend configuration

2. **Update Frontend:**
   - Edit `lib/Core/Services/Urls.dart`
   - Update line 23 with your backend URL
   - Commit and push
   - Frontend will auto-redeploy

3. **Test Connection:**
   - Open frontend in browser
   - Check console: `✅ Using PRODUCTION backend: https://...`
   - Try to login - should work!

---

## ✅ Success Indicators

- ✅ Deployment completes without errors
- ✅ Health check returns success message
- ✅ API docs accessible
- ✅ Logs show "✅ Connected to MongoDB"
- ✅ No 500 errors in function logs
- ✅ Frontend can connect (after updating URL)

---

## 🎉 You're Ready!

Everything is configured correctly. Just make sure to:
1. Set environment variables **before** deploying
2. Set Root Directory to `./backend`
3. Test after deployment

Good luck! 🚀

