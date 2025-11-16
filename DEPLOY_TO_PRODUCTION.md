# 🚀 Deploy to Production - Step by Step Guide

## Current Status
- ✅ All changes committed locally
- ⚠️ Need to push to GitHub (requires authentication)
- ⚠️ Need to deploy backend to AWS Elastic Beanstalk
- ✅ Frontend will auto-deploy on Vercel once GitHub is updated

---

## Step 1: Push to GitHub

### Option A: Using GitHub Personal Access Token

1. **Get your GitHub token** (if you don't have one):
   - Go to: https://github.com/settings/tokens
   - Generate new token (classic)
   - Select scopes: `repo` (full control)
   - Copy the token

2. **Push to GitHub:**
   ```bash
   cd /Users/dhivyan/TailorApp
   
   # Push using token (replace YOUR_TOKEN with your actual token)
   git push https://YOUR_TOKEN@github.com/StyleproDeveloper/TailorApp.git master
   
   # OR configure credential helper
   git config --global credential.helper store
   git push origin master
   # When prompted, use your GitHub username and token as password
   ```

### Option B: Using SSH (if configured)
```bash
cd /Users/dhivyan/TailorApp
git remote set-url origin git@github.com:StyleproDeveloper/TailorApp.git
git push origin master
```

---

## Step 2: Deploy Backend to AWS Elastic Beanstalk

### Option A: Using EB CLI (if installed)

```bash
cd /Users/dhivyan/TailorApp/backend

# Check if EB CLI is installed
eb --version

# If not installed, install it:
# pip3 install awsebcli

# Initialize EB (if not already done)
eb init

# Deploy to production
eb deploy tailorapp-env

# OR if environment name is different, check with:
eb list

# Monitor deployment
eb logs --follow

# Check status
eb status

# Test production endpoint
curl https://d3mi5vcvr32isw.cloudfront.net/health
```

### Option B: Using AWS Console (Manual Deployment)

1. **Go to AWS Elastic Beanstalk Console:**
   - https://ap-south-1.console.aws.amazon.com/elasticbeanstalk

2. **Select your environment** (e.g., `tailorapp-env`)

3. **Upload and Deploy:**
   - Click "Upload and Deploy"
   - Create a ZIP file of the backend:
     ```bash
     cd /Users/dhivyan/TailorApp/backend
     zip -r backend-deploy.zip . -x "node_modules/*" ".git/*" "*.log" ".env"
     ```
   - Upload the ZIP file
   - Add version label (e.g., "v1.0.0-payment-history")
   - Click "Deploy"

4. **Wait for deployment** (2-5 minutes)

5. **Verify deployment:**
   ```bash
   curl https://d3mi5vcvr32isw.cloudfront.net/health
   ```

---

## Step 3: Verify Frontend Auto-Deployment on Vercel

Once you push to GitHub:

1. **Vercel should auto-deploy** (if connected to GitHub)
   - Go to: https://vercel.com/dashboard
   - Check your project: `tailor-app` or similar
   - Wait for deployment to complete (usually 2-3 minutes)

2. **If auto-deploy is not working:**
   - Go to Vercel Dashboard
   - Select your project
   - Click "Deployments" tab
   - Click "Redeploy" → Select latest commit

3. **Test frontend:**
   - Open your Vercel URL (e.g., `https://tailor-app-lemon.vercel.app`)
   - Test the new features:
     - Order details page
     - PDF generation with payment history
     - Payment tracking

---

## Step 4: Update Frontend Backend URL (if needed)

If your backend URL changed, update it in:
- `lib/Core/Services/Urls.dart`
- Current production URL: `https://d3mi5vcvr32isw.cloudfront.net`

---

## Step 5: Post-Deployment Testing

### Test Backend:
```bash
# Health check
curl https://d3mi5vcvr32isw.cloudfront.net/health

# Test orders endpoint
curl "https://d3mi5vcvr32isw.cloudfront.net/orders/1?pageNumber=1&pageSize=10"

# Test payments endpoint
curl "https://d3mi5vcvr32isw.cloudfront.net/payments/1/order/61"
```

### Test Frontend:
1. ✅ Login works
2. ✅ Orders load correctly (no 500 errors)
3. ✅ Order details show payment information
4. ✅ PDF generation includes payment history
5. ✅ Payment tracking works

---

## 🚨 Troubleshooting

### Backend Deployment Fails:
```bash
cd /Users/dhivyan/TailorApp/backend
eb logs --all | grep -i error
eb status
```

### Frontend Not Updating:
- Clear browser cache
- Check Vercel deployment logs
- Verify GitHub push was successful

### CORS Issues:
- Verify backend CORS settings in `backend/src/app.js`
- Check CloudFront configuration

---

## 📋 Deployment Checklist

- [ ] Push code to GitHub
- [ ] Deploy backend to AWS Elastic Beanstalk
- [ ] Verify backend health endpoint
- [ ] Verify frontend auto-deployed on Vercel
- [ ] Test login functionality
- [ ] Test orders API (no 500 errors)
- [ ] Test PDF generation with payment history
- [ ] Test payment tracking features
- [ ] Monitor logs for errors

---

## 🎯 Quick Commands Reference

```bash
# Push to GitHub
cd /Users/dhivyan/TailorApp
git push origin master

# Deploy backend (if EB CLI installed)
cd backend
eb deploy

# Check backend status
eb status
eb logs --follow

# Test backend
curl https://d3mi5vcvr32isw.cloudfront.net/health
```

---

**Note:** If you need help with GitHub authentication or AWS deployment, let me know!


