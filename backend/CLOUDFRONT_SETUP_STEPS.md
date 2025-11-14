# ☁️ CloudFront HTTPS Setup - Step-by-Step Guide

## Current CloudFront Console Interface

The console now uses a step-by-step wizard. Follow these exact steps:

---

## Step 1: Get Started

1. You should see **"Get Started"** or **"Create Distribution"** button
2. Click **"Create Distribution"** or **"Get Started"**

---

## Step 2: Specify Origin

**Origin Domain:**
- Enter: `tailorapp-env.eba-trkapp28.ap-south-1.elasticbeanstalk.com`
- OR click the dropdown and select your Elastic Beanstalk environment if it appears

**Origin Name:**
- Auto-filled (or enter: `tailorapp-backend-origin`)

**Origin Path:**
- Leave empty (unless you need a specific path)

**Origin Protocol:**
- Select: **HTTP only** (CloudFront will handle HTTPS)

**HTTP Port:**
- `80` (default)

**HTTPS Port:**
- `443` (default)

**Origin SSL Protocols:**
- Select: **TLSv1.2** (or leave default)

Click **"Next"** or **"Continue"**

---

## Step 3: Default Cache Behavior

**Viewer Protocol Policy:**
- Select: **Redirect HTTP to HTTPS** ⭐ (This is important!)

**Allowed HTTP Methods:**
- Select: **GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE**
- OR select **"All"** if available

**Cache Policy:**
- Select: **CachingDisabled** (Important for API - no caching)
- If not available, select **"Managed-CachingDisabled"**

**Origin Request Policy:**
- Select: **AllViewer** or **"Managed-AllViewer"**
- This forwards all headers to your backend

**Response Headers Policy:**
- Leave default or select **"Managed-SimpleCORS"** if available

Click **"Next"** or **"Continue"**

---

## Step 4: Distribution Settings

**Price Class:**
- Select: **Use Only North America and Europe** (cheapest option)

**Alternate Domain Names (CNAMEs):**
- Leave empty (unless you have a custom domain)

**SSL Certificate:**
- Select: **Default CloudFront Certificate (free)** ⭐
- This provides free HTTPS

**Default Root Object:**
- Leave empty (for API)

**Custom Error Responses:**
- Leave defaults

**Comment:**
- Optional: "Tailor App Backend API"

**Web Application Firewall:**
- Leave unchecked (unless you want extra security)

Click **"Next"** or **"Continue"**

---

## Step 5: Review and Create

1. Review all settings
2. Make sure:
   - ✅ Origin points to your Elastic Beanstalk URL
   - ✅ Viewer Protocol Policy is "Redirect HTTP to HTTPS"
   - ✅ Cache Policy is "CachingDisabled"
   - ✅ SSL Certificate is "Default CloudFront Certificate"

3. Click **"Create Distribution"**

---

## Step 6: Wait for Deployment

- Status will show **"In Progress"**
- Wait **10-15 minutes** for deployment
- Status will change to **"Deployed"** when ready

---

## Step 7: Get Your HTTPS URL

Once deployed:

1. Find your distribution in the list
2. Copy the **Distribution Domain Name**
   - It will look like: `d1234567890.cloudfront.net`
3. Your HTTPS URL will be: `https://d1234567890.cloudfront.net`

---

## Step 8: Test

Test your HTTPS endpoint:

```bash
curl https://[your-cloudfront-domain]/health
```

Should return:
```json
{"status":"healthy","timestamp":"...","uptime":...}
```

---

## ✅ After CloudFront is Ready

Once you have the CloudFront URL, I'll:
1. Update the frontend to use the HTTPS CloudFront URL
2. Test the connection
3. Verify everything works

---

## 🔍 Troubleshooting

### Can't find "CachingDisabled" policy?
- Look for **"Managed-CachingDisabled"** in the dropdown
- Or select **"No caching"** if available

### Origin not found?
- Make sure you enter the full Elastic Beanstalk URL
- Check that your EB environment is running

### SSL Certificate options not showing?
- Make sure you're in the correct region
- Default CloudFront Certificate should always be available

---

**Need help?** Share a screenshot or describe which step you're on!

