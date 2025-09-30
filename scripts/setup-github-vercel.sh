#!/bin/bash

echo "🚀 Setting up GitHub-Vercel Integration for Tailor App"
echo "=================================================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Please run this script from the root of your Flutter project"
    exit 1
fi

echo "📋 Step 1: Get Vercel Project Information"
echo "----------------------------------------"

# Get Vercel project information
echo "Getting Vercel project information..."
vercel project ls

echo ""
echo "📋 Step 2: Get Vercel Token and Org ID"
echo "-------------------------------------"

# Get Vercel token
echo "Getting Vercel token..."
vercel token

# Get Vercel org ID
echo "Getting Vercel org ID..."
vercel whoami

echo ""
echo "📋 Step 3: GitHub Secrets Setup Instructions"
echo "-------------------------------------------"
echo "Go to your GitHub repository: https://github.com/StyleproDeveloper/TailorApp"
echo "Navigate to: Settings → Secrets and variables → Actions"
echo "Add the following secrets:"
echo ""
echo "1. VERCEL_TOKEN"
echo "   - Get this by running: vercel token"
echo "   - Or from: https://vercel.com/account/tokens"
echo ""
echo "2. VERCEL_ORG_ID"
echo "   - Get this by running: vercel whoami"
echo "   - Look for 'orgId' in the output"
echo ""
echo "3. VERCEL_PROJECT_ID (for frontend)"
echo "   - Get this by running: vercel project ls"
echo "   - Find your main frontend project ID"
echo ""
echo "4. VERCEL_BACKEND_PROJECT_ID (for backend)"
echo "   - Get this by running: vercel project ls"
echo "   - Find your backend project ID"
echo ""

echo "📋 Step 4: Alternative - Use Vercel Dashboard"
echo "--------------------------------------------"
echo "You can also connect your GitHub repository directly from Vercel:"
echo ""
echo "1. Go to: https://vercel.com/dashboard"
echo "2. Click 'New Project'"
echo "3. Import from GitHub: StyleproDeveloper/TailorApp"
echo "4. Configure build settings:"
echo "   - Framework Preset: Other"
echo "   - Build Command: flutter build web --release"
echo "   - Output Directory: build/web"
echo "   - Install Command: flutter pub get"
echo ""

echo "🎉 Setup Complete!"
echo "=================="
echo "After setting up the secrets, every push to main/master will automatically deploy:"
echo "- Frontend: Flutter web app"
echo "- Backend: Node.js API"
echo ""
echo "To test the deployment:"
echo "1. Make a small change to your code"
echo "2. Commit and push to GitHub"
echo "3. Check the Actions tab in your GitHub repository"
echo "4. Watch the automatic deployment happen!"
