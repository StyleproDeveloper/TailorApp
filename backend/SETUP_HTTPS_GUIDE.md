# 🔒 Setup HTTPS for Elastic Beanstalk Backend

## Current Status

✅ SSL Certificate Requested: `arn:aws:acm:ap-south-1:992382837321:certificate/ed2a0308-deaa-4a75-9aab-419e88fa80b5`

⚠️ **Certificate needs validation** before it can be used.

---

## 🎯 Method 1: AWS Console (Easiest - Recommended)

### Step 1: Validate Certificate

1. **Go to AWS Certificate Manager:**
   - Console: https://ap-south-1.console.aws.amazon.com/acm/home?region=ap-south-1
   - Find certificate: `ed2a0308-deaa-4a75-9aab-419e88fa80b5`

2. **If certificate needs DNS validation:**
   - Click on the certificate
   - Copy the CNAME record
   - Add it to your domain's DNS (if using custom domain)
   - OR request a new certificate for the Elastic Beanstalk domain

### Step 2: Configure HTTPS in Elastic Beanstalk

1. **Go to Elastic Beanstalk Console:**
   - https://ap-south-1.console.aws.amazon.com/elasticbeanstalk/home?region=ap-south-1#/environments

2. **Select Environment:** `tailorapp-env`

3. **Go to Configuration → Load Balancer**

4. **Add HTTPS Listener:**
   - Click "Add listener"
   - **Port:** 443
   - **Protocol:** HTTPS
   - **SSL Certificate:** Select your certificate from ACM
   - **SSL Policy:** ELBSecurityPolicy-TLS-1-2-2017-01
   - Click "Apply"

5. **Configure HTTP Redirect (Optional but Recommended):**
   - Edit the HTTP listener (port 80)
   - Set default action to "Redirect to HTTPS"
   - Port: 443
   - Protocol: HTTPS
   - Status code: 301
   - Click "Apply"

6. **Wait for update** (2-3 minutes)

### Step 3: Update Frontend

After HTTPS is configured, update the frontend URL to use `https://` instead of `http://`

---

## 🎯 Method 2: Using EB CLI (Advanced)

### Step 1: Save Current Configuration

```bash
cd backend
eb config save
```

### Step 2: Edit Configuration

1. Open `.elasticbeanstalk/saved_configs/tailorapp-env.cfg.yml`
2. Add HTTPS listener configuration
3. Save the file

### Step 3: Apply Configuration

```bash
eb config put tailorapp-env
eb deploy
```

---

## 🎯 Method 3: Request Certificate for Custom Domain (Best for Production)

### Step 1: Request Certificate

```bash
aws acm request-certificate \
  --domain-name api.yourdomain.com \
  --validation-method DNS \
  --region ap-south-1
```

### Step 2: Validate Certificate

1. Get validation records:
```bash
aws acm describe-certificate \
  --certificate-arn <cert-arn> \
  --region ap-south-1
```

2. Add CNAME record to your domain DNS

### Step 3: Add Custom Domain to Elastic Beanstalk

1. Go to Elastic Beanstalk Console
2. Configuration → Load Balancer
3. Add custom domain
4. Configure HTTPS listener with your certificate

---

## ✅ After HTTPS is Configured

### Update Frontend URL

Change in `lib/Core/Services/Urls.dart`:

```dart
// From:
final url = 'http://tailorapp-env.eba-trkapp28.ap-south-1.elasticbeanstalk.com';

// To:
final url = 'https://tailorapp-env.eba-trkapp28.ap-south-1.elasticbeanstalk.com';
```

### Test HTTPS

```bash
curl https://tailorapp-env.eba-trkapp28.ap-south-1.elasticbeanstalk.com/health
```

---

## 🔍 Troubleshooting

### Certificate Not Validated

- Check DNS records are correct
- Wait 5-10 minutes for DNS propagation
- Verify certificate status in ACM console

### HTTPS Not Working

- Check load balancer listener configuration
- Verify certificate is attached to listener
- Check security groups allow port 443

### Mixed Content Errors

- Ensure frontend uses HTTPS
- Update all API calls to use HTTPS
- Check CORS configuration allows HTTPS origins

---

## 📋 Quick Checklist

- [ ] Certificate requested in ACM
- [ ] Certificate validated (DNS or email)
- [ ] HTTPS listener added to load balancer
- [ ] HTTP redirect configured (optional)
- [ ] Frontend URL updated to HTTPS
- [ ] Test HTTPS endpoint
- [ ] Update CORS if needed

---

## 🎯 Recommended: Use AWS Console Method

**Fastest and easiest way:**
1. Go to Elastic Beanstalk Console
2. Configuration → Load Balancer
3. Add HTTPS listener
4. Select certificate
5. Apply changes

**Takes ~5 minutes!** ⚡

