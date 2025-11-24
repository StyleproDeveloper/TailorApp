# 🚀 Production Deployment Guide

This guide will help you deploy the Tailor App to production.

## 📋 Pre-Deployment Checklist

### ✅ Code Ready
- [x] All features implemented and tested
- [x] Trial period system implemented
- [x] S3 integration for image storage
- [x] Payment history edit functionality
- [x] Environment variables configured

### ⚠️ **CRITICAL: Environment Variables**

Before deploying, ensure all environment variables are set in your deployment platform.

## 🎯 Deployment Options

### Option 1: Vercel (Recommended for Backend) ⭐

**Best for:** Serverless backend, automatic scaling, easy deployment

#### Backend Deployment Steps:

1. **Install Vercel CLI (if not already installed):**
   ```bash
   npm install -g vercel
   ```

2. **Login to Vercel:**
   ```bash
   vercel login
   ```

3. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

4. **Link to existing project or create new:**
   ```bash
   vercel link
   # OR create new project
   vercel
   ```

5. **Set Environment Variables in Vercel Dashboard:**
   
   Go to: **Project Settings → Environment Variables**
   
   Add these variables for **Production**, **Preview**, and **Development**:
   
   ```
   MONGO_URL=mongodb+srv://username:password@cluster.mongodb.net/tailorapp?retryWrites=true&w=majority
   NODE_ENV=production
   JWT_SECRET=your-secure-random-secret-key-here-minimum-32-characters
   PORT=5500
   AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID
   AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY
   AWS_REGION=ap-south-1
   FRONTEND_URL=https://your-frontend-domain.com
   ```

6. **Deploy to Production:**
   ```bash
   vercel --prod
   ```

7. **Get your backend URL:**
   After deployment, Vercel will provide a URL like:
   ```
   https://tailorapp-backend.vercel.app
   ```

#### Frontend Deployment Steps:

1. **Navigate to root directory:**
   ```bash
   cd /Users/dhivyan/TailorApp
   ```

2. **Build Flutter Web App:**
   ```bash
   flutter build web --release
   ```

3. **Deploy to Vercel:**
   ```bash
   vercel --prod
   ```

4. **Update Frontend API URL:**
   After backend deployment, update the frontend API URL in:
   - `lib/Core/Services/Urls.dart`
   - Change `baseUrl` to your Vercel backend URL

---

### Option 2: AWS Elastic Beanstalk (Traditional Server)

**Best for:** Full control, traditional server setup

#### Steps:

1. **Install EB CLI:**
   ```bash
   pip install awsebcli
   ```

2. **Navigate to backend:**
   ```bash
   cd backend
   ```

3. **Initialize Elastic Beanstalk:**
   ```bash
   eb init -p "node.js-18" tailorapp-backend --region ap-south-1
   ```

4. **Create environment:**
   ```bash
   eb create tailorapp-prod-env \
     --instance-type t3.small \
     --platform "Node.js 18"
   ```

5. **Set environment variables:**
   ```bash
   eb setenv \
     MONGO_URL="mongodb+srv://..." \
     JWT_SECRET="your-secret-key" \
     NODE_ENV=production \
     PORT=8080 \
     AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY_ID" \
     AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_ACCESS_KEY" \
     AWS_REGION="ap-south-1" \
     FRONTEND_URL="https://your-frontend-domain.com"
   ```

6. **Deploy:**
   ```bash
   eb deploy
   ```

7. **Get URL:**
   ```bash
   eb status
   ```

---

### Option 3: Railway (Easy Deployment)

**Best for:** Simple deployment, automatic HTTPS

#### Steps:

1. **Go to Railway Dashboard:**
   - Visit [railway.app](https://railway.app)
   - Sign up/Login

2. **Create New Project:**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your repository

3. **Configure Backend:**
   - Root Directory: `./backend`
   - Build Command: `npm install`
   - Start Command: `npm start`

4. **Set Environment Variables:**
   Add all environment variables in Railway dashboard

5. **Deploy:**
   Railway will automatically deploy on every push to main branch

---

## 🔐 Environment Variables Reference

### Required Variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `MONGO_URL` | MongoDB connection string | `mongodb+srv://user:pass@cluster.mongodb.net/db` |
| `NODE_ENV` | Environment mode | `production` |
| `JWT_SECRET` | Secret key for JWT tokens | `your-random-secret-key` |
| `PORT` | Server port | `5500` or `8080` |

### Optional Variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS S3 access key | `YOUR_AWS_ACCESS_KEY_ID` |
| `AWS_SECRET_ACCESS_KEY` | AWS S3 secret key | `YOUR_AWS_SECRET_ACCESS_KEY` |
| `AWS_REGION` | AWS region | `ap-south-1` |
| `FRONTEND_URL` | Frontend URL for CORS | `https://your-app.com` |

---

## 📝 Post-Deployment Steps

### 1. Update Frontend API URL

After backend is deployed, update the frontend:

1. Open `lib/Core/Services/Urls.dart`
2. Update `baseUrl` to your production backend URL:
   ```dart
   static const String baseUrl = 'https://your-backend-url.vercel.app';
   ```

3. Rebuild and redeploy frontend:
   ```bash
   flutter build web --release
   vercel --prod
   ```

### 2. Test Production Endpoints

Test these critical endpoints:

```bash
# Health check
curl https://your-backend-url.vercel.app/health

# Test login
curl -X POST https://your-backend-url.vercel.app/auth/login \
  -H "Content-Type: application/json" \
  -d '{"mobileNumber":"+919876543210"}'
```

### 3. Verify S3 Integration

1. Create a test shop
2. Upload an image
3. Verify image is stored in S3 bucket
4. Verify image displays correctly in frontend

### 4. Verify Trial Period

1. Create a new shop
2. Verify `trialStartDate` and `trialEndDate` are set
3. Verify `subscriptionType` is set to "Trial"
4. Test login with expired trial (if needed)

### 5. Monitor Logs

```bash
# Vercel
vercel logs --follow

# AWS EB
eb logs --follow

# Railway
# Check logs in Railway dashboard
```

---

## 🐛 Troubleshooting

### Issue: CORS Errors

**Solution:** Ensure `FRONTEND_URL` is set correctly in backend environment variables.

### Issue: MongoDB Connection Failed

**Solution:** 
1. Check `MONGO_URL` is correct
2. Verify MongoDB Atlas IP whitelist includes `0.0.0.0/0` (all IPs)
3. Check MongoDB user has correct permissions

### Issue: S3 Upload Fails

**Solution:**
1. Verify AWS credentials are correct
2. Check AWS IAM permissions for S3
3. Verify bucket CORS configuration

### Issue: Images Not Displaying

**Solution:**
1. Check S3 bucket CORS settings
2. Verify image URLs are absolute (start with `https://`)
3. Check browser console for errors

---

## 📊 Monitoring & Maintenance

### Recommended Tools:

1. **Vercel Analytics** - Monitor API performance
2. **MongoDB Atlas Monitoring** - Database performance
3. **AWS CloudWatch** - S3 and AWS service monitoring
4. **Sentry** - Error tracking (optional)

### Regular Checks:

- [ ] Monitor API response times
- [ ] Check error logs weekly
- [ ] Review S3 storage usage
- [ ] Monitor MongoDB connection pool
- [ ] Check trial expiration dates

---

## 🔄 Continuous Deployment

### GitHub Actions (Optional)

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.ORG_ID }}
          vercel-project-id: ${{ secrets.PROJECT_ID }}
          vercel-args: '--prod'
```

---

## ✅ Deployment Checklist

Before going live:

- [ ] All environment variables set
- [ ] MongoDB connection tested
- [ ] S3 integration tested
- [ ] Frontend API URL updated
- [ ] CORS configured correctly
- [ ] Trial period system tested
- [ ] Payment functionality tested
- [ ] Image upload/download tested
- [ ] Error handling verified
- [ ] Logs monitoring set up
- [ ] Backup strategy in place

---

## 🎉 Success!

Once deployed, your app will be live at:
- **Backend:** `https://your-backend-url.vercel.app`
- **Frontend:** `https://your-frontend-url.vercel.app`

**Next Steps:**
1. Test all features in production
2. Monitor logs for first 24 hours
3. Set up alerts for errors
4. Document any production-specific configurations

