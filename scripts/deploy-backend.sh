#!/bin/bash

echo "🚀 Deploying Tailor App Backend to Railway..."

# Check if we're in the backend directory
if [ ! -f "package.json" ]; then
    echo "❌ Please run this script from the backend directory"
    exit 1
fi

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "📦 Installing Railway CLI..."
    npm install -g @railway/cli
fi

echo "🔐 Please login to Railway:"
echo "1. Run: railway login"
echo "2. Follow the authentication process"
echo "3. Then run: railway up"
echo ""
echo "📋 Environment Variables to set in Railway:"
echo "- MONGO_URL: Your MongoDB Atlas connection string"
echo "- JWT_SECRET: A secure random string for JWT tokens"
echo "- NODE_ENV: production"
echo "- PORT: 5500 (or leave empty for Railway to assign)"
echo ""
echo "🔗 After deployment:"
echo "- Your backend will be available at: https://your-app.railway.app"
echo "- API documentation: https://your-app.railway.app/api-docs"
echo ""
echo "📖 For detailed setup instructions, see DEPLOYMENT.md"

# Try to deploy if already logged in
if railway whoami &> /dev/null; then
    echo "✅ Already logged in to Railway. Deploying..."
    railway up
else
    echo "⚠️  Please login to Railway first: railway login"
fi
