#!/bin/bash

# AWS Deployment Script for Tailor App Backend
# Supports: EC2, Elastic Beanstalk, ECS, Lambda

set -e

echo "🚀 AWS Deployment Script for Tailor App Backend"
echo "================================================"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed."
    echo "📦 Install it from: https://aws.amazon.com/cli/"
    exit 1
fi

# Check if we're in the backend directory
if [ ! -f "package.json" ]; then
    echo "❌ Please run this script from the backend directory"
    exit 1
fi

# Function to deploy to Elastic Beanstalk
deploy_elastic_beanstalk() {
    echo "🌱 Deploying to AWS Elastic Beanstalk..."
    
    # Check if EB CLI is installed
    if ! command -v eb &> /dev/null; then
        echo "📦 Installing Elastic Beanstalk CLI..."
        pip install awsebcli
    fi
    
    # Initialize EB if not already done
    if [ ! -f ".elasticbeanstalk/config.yml" ]; then
        echo "🔧 Initializing Elastic Beanstalk..."
        eb init -p "node.js-18" tailorapp-backend --region us-east-1
    fi
    
    # Create environment if it doesn't exist
    if ! eb list | grep -q "tailorapp-backend-env"; then
        echo "🌍 Creating Elastic Beanstalk environment..."
        eb create tailorapp-backend-env \
            --instance-type t3.micro \
            --platform "Node.js 18" \
            --envvars MONGO_URL="$MONGO_URL",JWT_SECRET="$JWT_SECRET",NODE_ENV=production,PORT=5500
    fi
    
    # Deploy
    echo "📤 Deploying application..."
    eb deploy
    
    echo "✅ Deployment complete!"
    echo "🔗 Your app URL: $(eb status | grep 'CNAME' | awk '{print $2}')"
}

# Function to deploy to ECS/Fargate
deploy_ecs() {
    echo "🐳 Deploying to AWS ECS/Fargate..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Build Docker image
    echo "🔨 Building Docker image..."
    docker build -t tailorapp-backend:latest .
    
    # Tag for ECR (replace with your ECR repository URI)
    ECR_REPO="your-account-id.dkr.ecr.us-east-1.amazonaws.com/tailorapp-backend"
    echo "🏷️  Tagging image for ECR..."
    docker tag tailorapp-backend:latest $ECR_REPO:latest
    
    # Login to ECR
    echo "🔐 Logging in to ECR..."
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO
    
    # Push to ECR
    echo "📤 Pushing image to ECR..."
    docker push $ECR_REPO:latest
    
    # Update ECS service (replace with your cluster and service names)
    echo "🔄 Updating ECS service..."
    aws ecs update-service \
        --cluster tailorapp-cluster \
        --service tailorapp-backend-service \
        --force-new-deployment \
        --region us-east-1
    
    echo "✅ Deployment complete!"
}

# Function to deploy to Lambda (serverless)
deploy_lambda() {
    echo "⚡ Deploying to AWS Lambda..."
    
    # Check if serverless framework is installed
    if ! command -v serverless &> /dev/null; then
        echo "📦 Installing Serverless Framework..."
        npm install -g serverless
    fi
    
    # Deploy using serverless
    echo "📤 Deploying to Lambda..."
    serverless deploy
    
    echo "✅ Deployment complete!"
}

# Main menu
echo "Select deployment method:"
echo "1) AWS Elastic Beanstalk (Easiest - Recommended)"
echo "2) AWS ECS/Fargate (Docker containers)"
echo "3) AWS Lambda (Serverless)"
echo "4) Exit"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        deploy_elastic_beanstalk
        ;;
    2)
        deploy_ecs
        ;;
    3)
        deploy_lambda
        ;;
    4)
        echo "👋 Exiting..."
        exit 0
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

