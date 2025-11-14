# 🔧 Fix CloudFront 504 Error - Origin Protocol Issue

## 🚨 Problem Found!

**Issue:** Origin Protocol is set to `https-only` but your Elastic Beanstalk backend is HTTP (port 80).

**Result:** CloudFront tries to connect via HTTPS → Backend only accepts HTTP → 504 Gateway Timeout

---

## ✅ Solution: Change Origin Protocol to HTTP

### Step 1: Go to CloudFront Console

**Direct Link:**
https://console.aws.amazon.com/cloudfront/v3/home#/distributions/E33KE9HKOMIJGU

### Step 2: Edit Distribution

1. Click **"Edit"** button (top right)
2. Go to **"Origins"** tab
3. Click on your origin: `tailorapp-env.eba-trkapp28.ap-south-1.elasticbeanstalk.com`

### Step 3: Fix Origin Protocol

**Change these settings:**

1. **Origin Protocol:**
   - ❌ Currently: `HTTPS only`
   - ✅ Change to: **`HTTP only`**

2. **HTTP Port:**
   - Should be: `80`

3. **HTTPS Port:**
   - Can leave as `443` (not used)

4. **Origin Response Timeout:**
   - Set to: **30 seconds** (if available)

5. **Connection Timeout:**
   - Set to: **10 seconds** (if available)

### Step 4: Also Check Cache Behavior

While you're editing, go to **"Behaviors"** tab:

1. Click on default behavior (`*`)
2. Verify:
   - **Cache Policy:** `Managed-CachingDisabled` (for API)
   - **Origin Request Policy:** `Managed-AllViewer` (forwards all headers)
   - **Viewer Protocol Policy:** `Redirect HTTP to HTTPS` ✅ (this is correct)

### Step 5: Save Changes

1. Click **"Save changes"**
2. Wait **5-10 minutes** for deployment
3. Status will change from "In Progress" to "Deployed"

---

## 🧪 Test After Fix

After deployment completes:

```bash
# Test health endpoint
curl https://d3mi5vcvr32isw.cloudfront.net/health

# Should return:
# {"status":"healthy","timestamp":"...","uptime":...}
```

---

## 📋 Summary

**The Fix:**
- Change Origin Protocol: `HTTPS only` → `HTTP only`
- CloudFront will use HTTPS for users (secure)
- CloudFront will use HTTP to connect to backend (correct)

**Why This Works:**
- Users → CloudFront: HTTPS ✅ (secure)
- CloudFront → Backend: HTTP ✅ (backend is HTTP)
- Backend → CloudFront: HTTP response
- CloudFront → Users: HTTPS response ✅ (secure)

---

## ✅ After Fix

Your backend will be:
- ✅ Accessible via HTTPS
- ✅ Secure for users
- ✅ Working correctly
- ✅ No more 504 errors

