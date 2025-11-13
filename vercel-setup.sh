#!/bin/bash

# Vercel Setup Helper Script
# This script helps verify your Vercel project configuration

echo "🚀 Vercel Setup Verification Script"
echo "===================================="
echo ""

# Check if vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "⚠️  Vercel CLI not found. Install it with: npm i -g vercel"
    echo ""
    echo "You can still set up projects via Vercel Dashboard:"
    echo "https://vercel.com/dashboard"
    exit 0
fi

echo "✅ Vercel CLI found"
echo ""

# Check frontend configuration
echo "📋 Frontend Configuration Check:"
echo "-------------------------------"
if [ -f "vercel.json" ]; then
    echo "✅ vercel.json found"
    echo "   Build Command: chmod +x build.sh && bash build.sh"
    echo "   Output Directory: build/web"
else
    echo "❌ vercel.json not found"
fi

if [ -f "build.sh" ]; then
    echo "✅ build.sh found"
    if [ -x "build.sh" ]; then
        echo "✅ build.sh is executable"
    else
        echo "⚠️  build.sh is not executable (run: chmod +x build.sh)"
    fi
else
    echo "❌ build.sh not found"
fi

echo ""

# Check backend configuration
echo "📋 Backend Configuration Check:"
echo "-------------------------------"
if [ -f "backend/vercel.json" ]; then
    echo "✅ backend/vercel.json found"
else
    echo "❌ backend/vercel.json not found"
fi

if [ -f "backend/api/index.js" ]; then
    echo "✅ backend/api/index.js found"
else
    echo "❌ backend/api/index.js not found"
fi

if [ -f "backend/package.json" ]; then
    echo "✅ backend/package.json found"
else
    echo "❌ backend/package.json not found"
fi

echo ""
echo "===================================="
echo "📝 Setup Instructions:"
echo ""
echo "FRONTEND PROJECT:"
echo "  1. Root Directory: ./ (or leave empty)"
echo "  2. Build Command: chmod +x build.sh && bash build.sh"
echo "  3. Output Directory: build/web"
echo "  4. Framework: Other"
echo ""
echo "BACKEND PROJECT:"
echo "  1. Root Directory: ./backend ⚠️ CRITICAL"
echo "  2. Build Command: npm install (or auto-detected)"
echo "  3. Framework: Other"
echo "  4. Environment Variables:"
echo "     - MONGO_URL"
echo "     - NODE_ENV=production"
echo "     - JWT_SECRET"
echo "     - PORT=5500"
echo ""
echo "Go to: https://vercel.com/dashboard to create projects"
echo ""

