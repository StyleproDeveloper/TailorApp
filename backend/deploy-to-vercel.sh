#!/bin/bash

echo "🚀 Deploying Backend to Vercel..."
echo ""

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "📦 Installing Vercel CLI..."
    npm install -g vercel
fi

# Check if logged in
if ! vercel whoami &> /dev/null; then
    echo "🔐 Please login to Vercel first:"
    echo "   vercel login"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "✅ Logged in to Vercel"
echo "📦 Deploying to production..."
echo ""

# Deploy to production
vercel --prod --yes

echo ""
echo "✅ Deployment complete!"
echo "🔗 Your backend should be available at: https://backend-m5vayhncz-stylepros-projects.vercel.app"
echo ""
echo "📋 Changes deployed:"
echo "   - AdditionalCosts validation fix"
echo "   - Order query performance optimizations"
echo "   - Database indexes added"

