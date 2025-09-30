#!/bin/bash

echo "🚀 Deploying Tailor App Backend to Vercel..."

# Check if we're in the backend directory
if [ ! -f "package.json" ]; then
    echo "❌ Please run this script from the backend directory"
    exit 1
fi

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "📦 Installing Vercel CLI..."
    npm install -g vercel
fi

echo "🔐 Please login to Vercel:"
echo "1. Run: vercel login"
echo "2. Follow the authentication process"
echo "3. Then run: vercel --prod"
echo ""
echo "📋 Environment Variables to set in Vercel:"
echo "- MONGO_URL: Your MongoDB Atlas connection string"
echo "- JWT_SECRET: A secure random string for JWT tokens"
echo "- NODE_ENV: production"
echo ""
echo "🔗 After deployment:"
echo "- Your backend will be available at: https://your-app.vercel.app"
echo "- API documentation: https://your-app.vercel.app/api-docs"
echo ""
echo "📖 For detailed setup instructions, see BACKEND_ALTERNATIVES.md"

# Try to deploy if already logged in
if vercel whoami &> /dev/null; then
    echo "✅ Already logged in to Vercel. Deploying..."
    vercel --prod
else
    echo "⚠️  Please login to Vercel first: vercel login"
fi
