# 🔧 Fix CloudFront 504 Gateway Timeout

## Problem
CloudFront is returning 504 Gateway Timeout errors, meaning it can't reach your Elastic Beanstalk backend.

## Solution: Update CloudFront Configuration

### Step 1: Go to CloudFront Console
1. Open: https://console.aws.amazon.com/cloudfront/v3/home#/distributions
2. Click on distribution: `d3mi5vcvr32isw.cloudfront.net`
3. Click **"Edit"** button (top right)

### Step 2: Fix Origin Settings

1. **Go to "Origins" tab**
2. **Click on your origin** (tailorapp-env.eba-trkapp28...)
3. **Edit the following:**

   **Origin Domain:**
   - Should be: `tailorapp-env.eba-trkapp28.ap-south-1.elasticbeanstalk.com`
   - ✅ Verify this is correct

   **Origin Path:**
   - Should be: **EMPTY** (not `/path`)
   - ⚠️ If you see `/path`, delete it!

   **Origin Protocol:**
   - Should be: **HTTP only**

   **HTTP Port:**
   - Should be: `80`

   **Origin Response Timeout:**
   - Change to: **30 seconds** (default might be too short)

   **Connection Timeout:**
   - Change to: **10 seconds**

4. **Click "Save changes"**

### Step 3: Fix Cache Behavior

1. **Go to "Behaviors" tab**
2. **Click on the default behavior** (the `*` path pattern)
3. **Edit the following:**

   **Cache Policy:**
   - Select: **Managed-CachingDisabled**
   - This disables caching for API endpoints

   **Origin Request Policy:**
   - Select: **Managed-AllViewer**
   - This forwards all headers, query strings, and cookies to backend

   **Viewer Protocol Policy:**
   - Should be: **Redirect HTTP to HTTPS**

   **Allowed HTTP Methods:**
   - Select: **GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE**
   - Or select **"All"** if available

4. **Click "Save changes"**

### Step 4: Wait for Deployment

- Status will show "In Progress"
- Wait **5-10 minutes** for changes to deploy
- Status will change to "Deployed"

### Step 5: Test

After deployment, test:
```bash
curl https://d3mi5vcvr32isw.cloudfront.net/health
```

Should return:
```json
{"status":"healthy","timestamp":"...","uptime":...}
```

---

## 🔍 Alternative: Check Security Groups

If 504 persists after fixing configuration:

1. **Go to Elastic Beanstalk Console:**
   - https://ap-south-1.console.aws.amazon.com/elasticbeanstalk

2. **Select environment:** `tailorapp-env`

3. **Go to Configuration → Security**

4. **Check Security Group:**
   - Should allow inbound traffic on port 80 from anywhere (0.0.0.0/0)
   - Or at least allow CloudFront IP ranges

5. **If needed, update security group:**
   - Add inbound rule: HTTP (port 80) from 0.0.0.0/0

---

## 📋 Quick Checklist

- [ ] Origin domain is correct
- [ ] Origin path is **EMPTY** (not `/path`)
- [ ] Origin response timeout is 30 seconds
- [ ] Cache policy is `Managed-CachingDisabled`
- [ ] Origin request policy is `Managed-AllViewer`
- [ ] Security group allows HTTP traffic on port 80

---

## 🚨 Most Common Issue

**Origin Path is set to `/path` instead of empty!**

This is the #1 cause of 504 errors. Make sure Origin Path is completely empty.

