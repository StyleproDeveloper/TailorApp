# 🔧 AWS Elastic Beanstalk Deployment Fix

## Issue
The deployment is failing with:
```
ERROR: Failed to check health. Verify the permissions on the environment's service role and try again later.
```

## Solution

### Option 1: Fix via AWS Console (Recommended)

1. **Go to AWS Elastic Beanstalk Console:**
   - Visit: https://ap-south-1.console.aws.amazon.com/elasticbeanstalk
   - Select your environment: `tailorapp-env`

2. **Check Service Role:**
   - Go to **Configuration** → **Security**
   - Check **Service role** and **Instance profile**
   - Ensure they have proper permissions

3. **Update Service Role Permissions:**
   - Go to **IAM Console**: https://console.aws.amazon.com/iam
   - Find the service role: `aws-elasticbeanstalk-service-role`
   - Attach these policies:
     - `AWSElasticBeanstalkService`
     - `AWSElasticBeanstalkHealthEnhanced`
     - `AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy`

4. **Retry Deployment:**
   ```bash
   cd backend
   export PATH="$HOME/.local/bin:$PATH"
   eb deploy
   ```

### Option 2: Wait and Retry

Sometimes AWS permissions take time to propagate. Wait 1-2 hours and try again:
```bash
cd backend
export PATH="$HOME/.local/bin:$PATH"
eb deploy
```

### Option 3: Manual Deployment via AWS Console

1. Go to Elastic Beanstalk Console
2. Select `tailorapp-env`
3. Click **Upload and Deploy**
4. Upload the application version
5. Deploy

---

## Current Backend URL

Your backend is currently running at:
```
http://tailorapp-env.eba-trkapp28.ap-south-1.elasticbeanstalk.com
```

## Environment Variables to Set

Make sure these are set in AWS EB Console → Configuration → Software → Environment Properties:

- `MONGO_URL` - MongoDB connection string
- `NODE_ENV=production`
- `JWT_SECRET` - Your JWT secret
- `PORT=8080`
- `AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY`
- `AWS_REGION=ap-south-1`
- `FRONTEND_URL` - Your frontend Vercel URL






