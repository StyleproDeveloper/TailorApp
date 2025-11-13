# Frontend-Backend Connection Guide

## 🔍 How They Connect

### Current Architecture

```
┌─────────────────┐         HTTP Requests         ┌─────────────────┐
│   Frontend      │ ────────────────────────────> │    Backend      │
│  (Flutter Web)  │ <──────────────────────────── │ (Node.js/Express)│
│  Vercel Deploy  │         JSON Responses        │  Vercel Deploy  │
└─────────────────┘                               └─────────────────┘
        │                                                  │
        │                                                  │
        └────────────────── GitHub ───────────────────────┘
                        (Separate Projects)
```

### The Connection Mechanism

1. **Frontend** (`lib/Core/Services/Urls.dart`)
   - Contains hardcoded backend URL
   - All API calls use `Urls.baseUrl + endpoint`
   - Example: `https://backend-url.vercel.app/auth/login`

2. **Backend** (`api/index.js`)
   - Receives HTTP requests from frontend
   - Processes requests and returns JSON responses
   - CORS headers allow cross-origin requests

3. **They're Separate Projects**
   - Frontend and backend are deployed separately on Vercel
   - Each has its own GitHub repository/project
   - They communicate via HTTP/HTTPS

---

## ⚠️ The Problem: New Deployments = New URLs

### What Happens

1. **Backend Deployment:**
   ```
   Old: https://tailor-app-backend-abc123-stylepros-projects.vercel.app
   New: https://tailor-app-backend-xyz789-stylepros-projects.vercel.app
   ```

2. **Frontend Still Points to Old URL:**
   ```dart
   // Urls.dart - Still has old URL
   final url = 'https://tailor-app-backend-abc123-stylepros-projects.vercel.app';
   ```

3. **Result:**
   - Frontend tries to connect to old backend URL
   - Old deployment might be deleted or inactive
   - Connection fails ❌

---

## ✅ Solutions

### Solution 1: Manual Update (Current)

**After each backend deployment:**

1. Get new backend URL from Vercel dashboard
2. Update `Urls.dart`:
   ```dart
   final url = 'https://NEW-BACKEND-URL.vercel.app';
   ```
3. Commit and push frontend
4. Frontend redeploys with new URL

**Pros:** Simple, works immediately  
**Cons:** Manual step required

---

### Solution 2: Use Production URL (RECOMMENDED) ⭐

**Setup once, works forever:**

1. **In Vercel Backend Project:**
   - Go to Settings → Domains
   - Use the default production URL: `tailor-app-backend.vercel.app`
   - OR add a custom domain: `api.yourdomain.com`

2. **Update Frontend Once:**
   ```dart
   // Urls.dart
   final url = 'https://tailor-app-backend.vercel.app'; // Stable URL
   ```

3. **Deploy Backend:**
   - Deploy normally (creates preview URL)
   - When ready, click "Promote to Production"
   - Production URL stays the same!

**Pros:**
- ✅ Stable URL that never changes
- ✅ No frontend updates needed
- ✅ Professional setup
- ✅ Works for production

**Cons:** Requires one-time setup

---

### Solution 3: Environment Variables (Advanced)

Use Vercel environment variables to inject backend URL at build time.

---

## 📋 Step-by-Step: Update Frontend After Backend Deployment

### Quick Steps

1. **Get New Backend URL:**
   ```
   Vercel Dashboard → Backend Project → Latest Deployment → Copy URL
   ```

2. **Update Frontend:**
   ```bash
   # Edit lib/Core/Services/Urls.dart
   # Change line 23 to new URL
   ```

3. **Commit & Push:**
   ```bash
   git add lib/Core/Services/Urls.dart
   git commit -m "Update backend URL to latest deployment"
   git push
   ```

4. **Frontend Auto-Deploys:**
   - Vercel detects push
   - Automatically redeploys frontend
   - Frontend now uses new backend URL

5. **Test:**
   - Open frontend URL
   - Check browser console: `✅ Using PRODUCTION backend: https://...`
   - Try logging in

---

## 🎯 Recommended: Set Up Production URL

### Backend Setup

1. **Vercel Dashboard → Backend Project**
2. **Settings → Domains**
3. **Use Default Production URL:**
   - Vercel provides: `tailor-app-backend.vercel.app`
   - This URL is stable and doesn't change

4. **OR Add Custom Domain:**
   - Add: `api.yourdomain.com`
   - Configure DNS as instructed

### Frontend Update (One Time)

```dart
// lib/Core/Services/Urls.dart
final url = 'https://tailor-app-backend.vercel.app'; // Production URL
```

### Deployment Workflow

1. **Deploy Backend:**
   - Push to GitHub → Vercel creates preview deployment
   - Preview URL: `tailor-app-backend-xyz123-stylepros-projects.vercel.app`

2. **Test Preview:**
   - Test the preview deployment
   - Make sure everything works

3. **Promote to Production:**
   - Click "Promote to Production" in Vercel dashboard
   - Production URL stays: `tailor-app-backend.vercel.app`
   - Frontend automatically uses latest production deployment

4. **No Frontend Update Needed!** ✅

---

## 🔍 How to Verify Connection

### Check Browser Console

When frontend loads, you should see:
```
🌐 Detected hostname: tailor-app-lemon.vercel.app
🌐 Detected protocol: https:
✅ Using PRODUCTION backend: https://tailor-app-backend.vercel.app
```

### Check Network Tab

1. Open DevTools → Network
2. Try logging in
3. Look for request to: `https://tailor-app-backend.vercel.app/auth/login`
4. Should return 200 OK with CORS headers

### Check Backend Logs

1. Vercel Dashboard → Backend Project → Functions
2. View logs
3. Should see incoming requests from frontend

---

## 🚨 Troubleshooting

### Frontend Can't Connect to Backend

**Symptoms:**
- CORS errors in console
- Network errors
- "Connection failed" messages

**Check:**
1. ✅ Backend URL in `Urls.dart` matches actual backend deployment
2. ✅ Backend is deployed and running
3. ✅ CORS headers are set (check Network tab → Response Headers)
4. ✅ No typos in URL

### Backend URL Changed

**Symptoms:**
- Old URL returns 404
- New deployment has different URL

**Fix:**
1. Get new URL from Vercel dashboard
2. Update `Urls.dart`
3. Redeploy frontend

### CORS Still Failing

**Check:**
1. Backend logs show: `✅ OPTIONS preflight handled`
2. Network tab shows CORS headers in response
3. Hard refresh browser (Ctrl+Shift+R)

---

## 📚 Summary

### Current Setup
- Frontend and backend are separate Vercel projects
- Frontend has hardcoded backend URL in `Urls.dart`
- When backend redeploys, frontend needs URL update

### Recommended Setup
- Use Vercel production URL for backend
- Update frontend once with production URL
- Promote deployments to production (URL stays same)
- No more URL updates needed! ✅

### The CORS Fix
- ✅ Real and legitimate fix
- ✅ Handles CORS at serverless function entry point
- ✅ Recommended by Vercel documentation
- ✅ Works consistently across deployments

