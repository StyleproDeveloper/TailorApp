# 🚀 AWS Quick Start Guide

## Fastest Deployment: Elastic Beanstalk (5 minutes)

### Step 1: Install Prerequisites
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Elastic Beanstalk CLI
pip install awsebcli
```

### Step 2: Configure AWS
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter default region (e.g., us-east-1)
# Enter default output format (json)
```

### Step 3: Deploy
```bash
cd backend

# Initialize Elastic Beanstalk
eb init -p "node.js-18" tailorapp-backend --region us-east-1

# Create environment
eb create tailorapp-backend-env --instance-type t3.micro

# Set environment variables
eb setenv \
  MONGO_URL="mongodb+srv://username:password@cluster.mongodb.net/tailorapp" \
  JWT_SECRET="your-secret-key-here" \
  NODE_ENV=production \
  PORT=5500

# Deploy
eb deploy

# Get your URL
eb status
```

### Step 4: Update Frontend
Update your frontend `Urls.dart` to point to the new AWS backend URL:
```dart
static String _getProductionUrl() {
  return 'https://your-app.elasticbeanstalk.com';
}
```

## Alternative: Use the Deployment Script
```bash
cd backend
./aws-deploy.sh
# Follow the prompts
```

## Cost Estimate
- **Elastic Beanstalk (t3.micro):** ~$10-15/month
- **Lambda (serverless):** Pay per request (~$0.20 per 1M requests)
- **ECS Fargate:** ~$15-30/month (depending on usage)

## Need Help?
See `AWS_DEPLOYMENT_GUIDE.md` for detailed instructions.

