# 🔧 CloudFront Troubleshooting Guide

## Common Issues and Solutions

### Issue 1: 504 Gateway Timeout

**Symptoms:**
- CloudFront returns 504 errors
- Backend is healthy but not reachable through CloudFront

**Solutions:**
1. **Check Origin Configuration:**
   - Go to CloudFront Console
   - Select your distribution
   - Check "Origins" tab
   - Verify origin domain is correct
   - Verify origin path is empty (not `/path`)

2. **Check Origin Request Policy:**
   - Should forward all headers
   - Should forward query strings
   - Should forward cookies

3. **Check Timeout Settings:**
   - Origin response timeout: Should be at least 30 seconds
   - Connection timeout: Should be at least 10 seconds

---

### Issue 2: CORS Errors

**Symptoms:**
- Browser shows CORS errors
- API calls fail with CORS policy errors

**Solutions:**
1. **Update Origin Request Policy:**
   - Must forward `Origin` header
   - Must forward `Access-Control-Request-Method` header
   - Must forward `Access-Control-Request-Headers` header

2. **Check Backend CORS:**
   - Backend should allow CloudFront origin
   - Or allow all origins (`*`)

---

### Issue 3: Rate Limiting

**Symptoms:**
- "Too many requests" errors
- Backend rate limiting is triggered

**Solutions:**
1. **Disable Caching for API:**
   - Use `CachingDisabled` policy
   - Or `Managed-CachingDisabled`

2. **Adjust Rate Limiting:**
   - Increase rate limit in backend
   - Or whitelist CloudFront IPs

---

### Issue 4: Wrong Response Headers

**Symptoms:**
- Missing CORS headers
- Wrong content-type

**Solutions:**
1. **Use Response Headers Policy:**
   - Add CORS headers
   - Or let backend handle it (forward all headers)

---

## 🔍 Quick Fix: Update CloudFront Configuration

### Step 1: Go to CloudFront Console
https://console.aws.amazon.com/cloudfront/v3/home#/distributions

### Step 2: Select Your Distribution
Click on: `d3mi5vcvr32isw.cloudfront.net`

### Step 3: Edit Distribution
Click "Edit" button

### Step 4: Check Cache Behavior
1. Go to "Behaviors" tab
2. Click on default behavior (the `*` path)
3. Edit the following:

**Cache Policy:**
- Select: `Managed-CachingDisabled` or `CachingDisabled`

**Origin Request Policy:**
- Select: `Managed-AllViewer` or `AllViewer`
- This forwards all headers, query strings, and cookies

**Response Headers Policy:**
- Select: `Managed-SimpleCORS` (if available)
- Or leave default (backend handles CORS)

**Viewer Protocol Policy:**
- Should be: `Redirect HTTP to HTTPS`

### Step 5: Save Changes
Click "Save changes"
Wait 5-10 minutes for deployment

---

## 🧪 Test After Fix

```bash
# Test health endpoint
curl https://d3mi5vcvr32isw.cloudfront.net/health

# Test root endpoint
curl https://d3mi5vcvr32isw.cloudfront.net/

# Test with CORS headers
curl -H "Origin: https://your-frontend.com" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS \
     https://d3mi5vcvr32isw.cloudfront.net/auth/login
```

---

## 📋 Configuration Checklist

- [ ] Origin domain is correct
- [ ] Origin path is empty
- [ ] Cache policy is `CachingDisabled`
- [ ] Origin request policy forwards all headers
- [ ] Viewer protocol is `Redirect HTTP to HTTPS`
- [ ] Allowed methods include: GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE
- [ ] Response headers policy allows CORS (or backend handles it)

---

## 🚨 If Still Not Working

1. **Check CloudFront Logs:**
   - Enable CloudFront access logs
   - Check for specific errors

2. **Test Direct Backend:**
   ```bash
   curl http://tailorapp-env.eba-trkapp28.ap-south-1.elasticbeanstalk.com/health
   ```
   Should work directly

3. **Check Security Groups:**
   - Elastic Beanstalk security group should allow CloudFront IPs
   - Or allow all HTTP traffic (port 80)

4. **Contact Support:**
   - Share specific error message from browser
   - Share CloudFront distribution ID
   - Share backend URL

