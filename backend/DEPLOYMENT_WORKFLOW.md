# 🔄 Backend Deployment Workflow

## How to Test and Deploy Backend Changes to Production

---

## 📋 Development Workflow

### Step 1: Make Changes Locally

1. **Edit your code** in the `backend/src/` directory
2. **Test locally:**
   ```bash
   cd backend
   npm install  # if you added new dependencies
   npm run dev   # starts with nodemon (auto-restarts on changes)
   ```

3. **Test endpoints:**
   ```bash
   # Health check
   curl http://localhost:5500/health
   
   # Test specific endpoint
   curl http://localhost:5500/auth/login -X POST -H "Content-Type: application/json" -d '{"mobile":"..."}'
   ```

---

## 🧪 Testing Before Production

### Option 1: Test Locally (Recommended First Step)

```bash
cd backend

# Set environment variables
export MONGO_URL="mongodb+srv://StylePro:stylePro123@stylepro.5ttc1.mongodb.net/"
export JWT_SECRET="your-secret-key"
export NODE_ENV=development
export PORT=5500

# Start server
npm start

# Test in another terminal
curl http://localhost:5500/health
```

### Option 2: Create Staging Environment (Best Practice)

Create a separate Elastic Beanstalk environment for testing:

```bash
cd backend

# Create staging environment
eb create tailorapp-staging-env --instance-type t3.micro

# Set environment variables
eb setenv \
  MONGO_URL="mongodb+srv://..." \
  JWT_SECRET="..." \
  NODE_ENV=staging \
  PORT=8080

# Deploy to staging
eb deploy tailorapp-staging-env

# Test staging URL
curl https://[staging-cloudfront-url]/health
```

**Benefits:**
- Test in production-like environment
- No risk to production
- Can test with real data

---

## 🚀 Deploy to Production

### Method 1: Using EB CLI (Recommended)

```bash
cd backend

# 1. Make sure you're on the right branch
git status

# 2. Commit your changes
git add .
git commit -m "Description of changes"

# 3. Deploy to Elastic Beanstalk
eb deploy tailorapp-env

# 4. Wait for deployment (2-5 minutes)
# Watch the logs:
eb logs --follow

# 5. Check status
eb status

# 6. Test production
curl https://d3mi5vcvr32isw.cloudfront.net/health
```

### Method 2: Using Git Push (Automatic Deployment)

If you set up automatic deployment:

```bash
cd backend

# 1. Commit changes
git add .
git commit -m "Description of changes"

# 2. Push to GitHub
git push origin master

# 3. Elastic Beanstalk will auto-deploy (if configured)
# Check deployment status in AWS Console
```

---

## ✅ Post-Deployment Checklist

### 1. Verify Deployment

```bash
# Check EB status
eb status

# Check health
curl https://d3mi5vcvr32isw.cloudfront.net/health

# Check logs for errors
eb logs --all
```

### 2. Test Critical Endpoints

```bash
# Health check
curl https://d3mi5vcvr32isw.cloudfront.net/health

# Root endpoint
curl https://d3mi5vcvr32isw.cloudfront.net/

# Login endpoint (test with your credentials)
curl -X POST https://d3mi5vcvr32isw.cloudfront.net/auth/login \
  -H "Content-Type: application/json" \
  -d '{"mobile":"your-mobile-number"}'
```

### 3. Monitor Logs

```bash
# View recent logs
eb logs

# Follow logs in real-time
eb logs --follow

# View specific log file
eb logs --all | grep ERROR
```

### 4. Check CloudWatch

- Go to AWS Console → CloudWatch
- Check application logs
- Monitor errors and performance

---

## 🔄 Rollback if Something Goes Wrong

### Quick Rollback

```bash
cd backend

# List previous deployments
eb list-platform-versions

# Rollback to previous version
eb deploy --version [previous-version-label]

# Or use AWS Console:
# 1. Go to Elastic Beanstalk Console
# 2. Select environment
# 3. Go to "Application versions"
# 4. Select previous version
# 5. Click "Deploy"
```

---

## 📝 Best Practices

### 1. Always Test Locally First
- Test all changes locally before deploying
- Use `npm run dev` for development
- Test all affected endpoints

### 2. Use Staging Environment
- Create a staging environment for testing
- Test there before production
- Use same configuration as production

### 3. Commit Before Deploying
- Always commit changes to Git
- Write clear commit messages
- Tag important releases

### 4. Monitor After Deployment
- Check logs immediately after deploy
- Monitor for errors
- Test critical functionality

### 5. Deploy During Low Traffic
- Deploy during off-peak hours
- Notify users if needed
- Have rollback plan ready

---

## 🛠️ Common Deployment Commands

```bash
# Check current status
eb status

# Deploy latest code
eb deploy

# Deploy specific environment
eb deploy tailorapp-env

# View logs
eb logs
eb logs --follow

# Check health
eb health

# Open in browser
eb open

# SSH into instance (if needed)
eb ssh

# Set environment variables
eb setenv KEY=value KEY2=value2

# List environments
eb list

# Switch environment
eb use tailorapp-env
```

---

## 🔍 Testing Checklist

Before deploying to production:

- [ ] Code tested locally
- [ ] All endpoints tested
- [ ] Environment variables verified
- [ ] Dependencies updated (if any)
- [ ] Database migrations run (if any)
- [ ] No console errors
- [ ] Logs reviewed
- [ ] Performance acceptable
- [ ] Security checks passed

---

## 🚨 Troubleshooting Deployment Issues

### Deployment Fails

```bash
# Check logs
eb logs --all

# Check status
eb status

# View recent events
eb events
```

### Application Not Starting

```bash
# Check application logs
eb logs --all | grep -i error

# Check environment variables
eb printenv

# Restart environment
eb restart
```

### Performance Issues

```bash
# Check instance health
eb health

# View CloudWatch metrics
# Go to AWS Console → CloudWatch → Metrics
```

---

## 📊 Deployment Workflow Diagram

```
┌─────────────┐
│ Local Dev   │ → Test locally
└─────────────┘
      ↓
┌─────────────┐
│ Git Commit  │ → Commit changes
└─────────────┘
      ↓
┌─────────────┐
│ EB Deploy   │ → Deploy to Elastic Beanstalk
└─────────────┘
      ↓
┌─────────────┐
│ Test Prod   │ → Test production endpoints
└─────────────┘
      ↓
┌─────────────┐
│ Monitor     │ → Watch logs and metrics
└─────────────┘
```

---

## 🎯 Quick Reference

### Daily Development
```bash
cd backend
npm run dev          # Start local server
# Make changes
# Test locally
git add .
git commit -m "Description"
```

### Deploy to Production
```bash
cd backend
eb deploy            # Deploy to production
eb logs --follow     # Watch deployment
curl https://d3mi5vcvr32isw.cloudfront.net/health  # Test
```

### Emergency Rollback
```bash
cd backend
eb deploy --version [previous-version]
```

---

## 📞 Need Help?

- **View logs:** `eb logs`
- **Check status:** `eb status`
- **AWS Console:** https://ap-south-1.console.aws.amazon.com/elasticbeanstalk
- **CloudWatch:** Monitor performance and errors

---

**Remember:** Always test locally first, then staging (if available), then production! 🚀

