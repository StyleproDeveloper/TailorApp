# ✅ Elastic Beanstalk Setup Checklist

## STEP 1 — Backend Preparation ✅

### ✅ 1. Package.json Start Script
**Status:** ✅ CONFIGURED
```json
"scripts": {
  "start": "node src/server.js"
}
```
**File:** `backend/package.json` - Line 8

### ✅ 2. CORS Installation
**Status:** ✅ INSTALLED
- Package: `cors@^2.8.5` (already in dependencies)
- **File:** `backend/package.json` - Line 22

### ✅ 3. CORS Configuration
**Status:** ✅ CONFIGURED
- CORS is configured in `backend/src/app.js`
- Origin: `*` (allows all origins)
- Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS, HEAD
- **File:** `backend/src/app.js` - Lines 60-70

### ✅ 4. .ebextensions Folder
**Status:** ✅ CREATED
- **File:** `backend/.ebextensions/00-node.config`
  ```yaml
  option_settings:
    aws:elasticbeanstalk:container:nodejs:
      NodeCommand: "npm start"
  ```

### ✅ 5. PORT Configuration
**Status:** ✅ UPDATED
- Default PORT changed to `8080` (Elastic Beanstalk requirement)
- **File:** `backend/src/config/env.config.js` - Line 38
- **File:** `backend/.ebextensions/nodecommand.config` - Line 6

---

## STEP 2 — Install EB CLI

```bash
pip install awsebcli --upgrade
```

## STEP 3 — Configure AWS

```bash
aws configure
```

Enter:
- **AWS Access Key ID:** [Your Access Key]
- **AWS Secret Access Key:** [Your Secret Key]
- **Default region:** `ap-south-1` (Mumbai)
- **Default output format:** `json`

## STEP 4 — Initialize Elastic Beanstalk

```bash
cd backend
eb init
```

Choose:
- **Region:** `ap-south-1` (Mumbai)
- **Platform:** `Node.js`
- **Application name:** `tailor-app-backend`
- **Create new Application?** → `YES`

## STEP 5 — Create Environment

```bash
eb create tailorapp-env
```

This takes 2-5 minutes. You'll receive a URL like:
```
http://tailorapp-env.eba-xyz123.ap-south-1.elasticbeanstalk.com
```

## STEP 6 — Set Environment Variables

### Option A: Via AWS Console
1. Go to **AWS Console → Elastic Beanstalk**
2. Select **tailorapp-env**
3. Go to **Configuration → Software → Environment Properties**
4. Add:
   - `PORT` = `8080`
   - `MONGO_URL` = `your-mongo-atlas-uri`
   - `NODE_ENV` = `production`
   - `JWT_SECRET` = `your-secret-key`

### Option B: Via EB CLI
```bash
eb setenv \
  PORT=8080 \
  MONGO_URL="mongodb+srv://username:password@cluster.mongodb.net/tailorapp" \
  NODE_ENV=production \
  JWT_SECRET="your-secret-key-here"
```

## STEP 7 — Deploy

```bash
eb deploy
```

## STEP 8 — Check Status

```bash
eb status
eb health
eb logs
```

## STEP 9 — Open Application

```bash
eb open
```

---

## 📋 Summary of Changes Made

1. ✅ Created `.ebextensions/00-node.config` with `npm start` command
2. ✅ Updated `.ebextensions/nodecommand.config` to use `npm start` and PORT 8080
3. ✅ Updated `src/config/env.config.js` to default PORT to 8080
4. ✅ Verified CORS is installed and configured
5. ✅ Verified `package.json` has correct start script

---

## 🔍 Verification Commands

```bash
# Check package.json start script
cat package.json | grep -A 1 '"start"'

# Check CORS installation
cat package.json | grep cors

# Check .ebextensions
ls -la .ebextensions/

# Check PORT default
grep "PORT.*8080" src/config/env.config.js
```

---

## 🚨 Important Notes

1. **PORT must be 8080** - Elastic Beanstalk uses this port internally
2. **Environment variables** must be set in AWS Console or via `eb setenv`
3. **MongoDB Atlas** - Make sure your IP whitelist includes AWS IP ranges
4. **CORS** - Already configured to allow all origins (`*`)

---

## 🎯 Next Steps After Deployment

1. Update frontend `Urls.dart` to point to your Elastic Beanstalk URL
2. Test the API endpoints
3. Check CloudWatch logs for any errors
4. Monitor health status: `eb health`

---

**Ready to deploy!** 🚀

