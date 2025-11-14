# 🚀 AWS Deployment Guide for Tailor App Backend

This guide covers deploying the Tailor App backend to various AWS services.

## 📋 Prerequisites

1. **AWS Account** - Sign up at [aws.amazon.com](https://aws.amazon.com)
2. **AWS CLI** - Install from [aws.amazon.com/cli](https://aws.amazon.com/cli/)
3. **MongoDB Atlas** - For production database
4. **Node.js 18+** - For local development

## 🎯 Deployment Options

### Option 1: AWS Elastic Beanstalk (Recommended for Beginners) ⭐

**Best for:** Quick deployment, automatic scaling, easy management

#### Steps:

1. **Install Elastic Beanstalk CLI:**
   ```bash
   pip install awsebcli
   ```

2. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

3. **Initialize Elastic Beanstalk:**
   ```bash
   eb init -p "node.js-18" tailorapp-backend --region us-east-1
   ```

4. **Create environment:**
   ```bash
   eb create tailorapp-backend-env \
     --instance-type t3.micro \
     --platform "Node.js 18"
   ```

5. **Set environment variables:**
   ```bash
   eb setenv MONGO_URL="mongodb+srv://..." \
            JWT_SECRET="your-secret-key" \
            NODE_ENV=production \
            PORT=5500
   ```

6. **Deploy:**
   ```bash
   eb deploy
   ```

7. **Get your URL:**
   ```bash
   eb status
   ```

**Cost:** ~$10-15/month (t3.micro instance)

---

### Option 2: AWS ECS/Fargate (Docker Containers) 🐳

**Best for:** Container-based deployments, microservices

#### Steps:

1. **Build Docker image:**
   ```bash
   cd backend
   docker build -t tailorapp-backend:latest .
   ```

2. **Create ECR repository:**
   ```bash
   aws ecr create-repository --repository-name tailorapp-backend --region us-east-1
   ```

3. **Get ECR login:**
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
   ```

4. **Tag and push image:**
   ```bash
   docker tag tailorapp-backend:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/tailorapp-backend:latest
   docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/tailorapp-backend:latest
   ```

5. **Create ECS cluster and service** (via AWS Console or CLI)

**Cost:** Pay per use (~$0.04/vCPU-hour + $0.004/GB-hour)

---

### Option 3: AWS Lambda (Serverless) ⚡

**Best for:** Cost-effective, auto-scaling, pay-per-request

#### Steps:

1. **Install Serverless Framework:**
   ```bash
   npm install -g serverless
   ```

2. **Configure AWS credentials:**
   ```bash
   aws configure
   ```

3. **Set environment variables:**
   ```bash
   export MONGO_URL="mongodb+srv://..."
   export JWT_SECRET="your-secret-key"
   ```

4. **Deploy:**
   ```bash
   cd backend
   serverless deploy
   ```

**Cost:** Pay per request (~$0.20 per 1M requests)

---

### Option 4: AWS EC2 (Virtual Server) 💻

**Best for:** Full control, custom configurations

#### Steps:

1. **Launch EC2 instance:**
   - Choose Amazon Linux 2 or Ubuntu
   - Instance type: t3.micro (free tier eligible)
   - Security group: Allow port 5500 (or 80/443)

2. **SSH into instance:**
   ```bash
   ssh -i your-key.pem ec2-user@your-instance-ip
   ```

3. **Install Node.js:**
   ```bash
   curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
   sudo yum install -y nodejs
   ```

4. **Clone and deploy:**
   ```bash
   git clone https://github.com/StyleproDeveloper/TailorApp.git
   cd TailorApp/backend
   npm install --production
   ```

5. **Set environment variables:**
   ```bash
   export MONGO_URL="mongodb+srv://..."
   export JWT_SECRET="your-secret-key"
   export NODE_ENV=production
   export PORT=5500
   ```

6. **Run with PM2 (process manager):**
   ```bash
   npm install -g pm2
   pm2 start src/server.js --name tailorapp-backend
   pm2 save
   pm2 startup
   ```

**Cost:** ~$10-15/month (t3.micro)

---

## 🔐 Environment Variables

Set these in your AWS service:

| Variable | Description | Example |
|----------|-------------|---------|
| `MONGO_URL` | MongoDB connection string | `mongodb+srv://user:pass@cluster.mongodb.net/db` |
| `JWT_SECRET` | Secret for JWT tokens | `your-random-secret-key` |
| `NODE_ENV` | Environment | `production` |
| `PORT` | Server port | `5500` |

---

## 🔒 Security Best Practices

1. **Use AWS Secrets Manager** for sensitive data
2. **Enable HTTPS** (use Application Load Balancer)
3. **Restrict security groups** to specific IPs if possible
4. **Use IAM roles** instead of access keys
5. **Enable CloudWatch** for monitoring

---

## 📊 Monitoring

- **CloudWatch Logs** - View application logs
- **CloudWatch Metrics** - Monitor performance
- **X-Ray** - Trace requests (optional)

---

## 🚨 Troubleshooting

### Connection Issues:
- Check security groups allow port 5500
- Verify MongoDB Atlas IP whitelist includes AWS IPs
- Check environment variables are set correctly

### Performance Issues:
- Increase instance size (Elastic Beanstalk/EC2)
- Increase Lambda memory/timeout
- Enable connection pooling in MongoDB

### Deployment Failures:
- Check CloudWatch logs
- Verify all dependencies in `package.json`
- Ensure Node.js version matches (18.x)

---

## 📞 Support

For issues:
1. Check AWS CloudWatch logs
2. Review application logs
3. Verify environment variables
4. Check MongoDB connection

---

## 🎯 Quick Start (Elastic Beanstalk)

```bash
# 1. Install EB CLI
pip install awsebcli

# 2. Initialize
cd backend
eb init -p "node.js-18" tailorapp-backend

# 3. Create environment
eb create tailorapp-backend-env

# 4. Set environment variables
eb setenv MONGO_URL="..." JWT_SECRET="..." NODE_ENV=production

# 5. Deploy
eb deploy

# 6. Open in browser
eb open
```

---

**Recommended:** Start with **Elastic Beanstalk** for the easiest deployment experience! 🚀

