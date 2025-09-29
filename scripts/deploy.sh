#!/bin/bash

echo "🚀 Deploying Tailor App to Production..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Not in a git repository. Please initialize git first."
    exit 1
fi

# Check if we have uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "📝 You have uncommitted changes. Committing them now..."
    git add .
    git commit -m "Deploy to production - $(date '+%Y-%m-%d %H:%M:%S')"
fi

# Build Flutter web app
echo "📦 Building Flutter web app..."
flutter build web --release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Flutter build successful!"
else
    echo "❌ Flutter build failed!"
    exit 1
fi

# Check if GitHub Actions workflow exists
if [ -f ".github/workflows/deploy.yml" ]; then
    echo "🔄 GitHub Actions workflow detected!"
    echo "📤 Pushing to GitHub to trigger automated deployment..."
    git push origin main
    
    if [ $? -eq 0 ]; then
        echo "✅ Code pushed to GitHub successfully!"
        echo ""
        echo "🎉 Automated deployment initiated!"
        echo ""
        echo "📊 Monitor deployment progress:"
        echo "- GitHub Actions: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions"
        echo "- Railway (Backend): https://railway.app/dashboard"
        echo "- Vercel (Frontend): https://vercel.com/dashboard"
        echo ""
        echo "⏱️  Deployment typically takes 3-5 minutes"
        echo "🔗 Your app will be available at:"
        echo "- Frontend: https://your-app.vercel.app (after Vercel deployment)"
        echo "- Backend: https://your-app.railway.app (after Railway deployment)"
    else
        echo "❌ Failed to push to GitHub!"
        echo "Please check your git configuration and try again."
        exit 1
    fi
else
    echo "⚠️  GitHub Actions workflow not found!"
    echo ""
    echo "📋 Manual deployment steps:"
    echo "1. Push to GitHub: git push origin main"
    echo "2. Deploy frontend to Vercel: https://vercel.com/new"
    echo "3. Deploy backend to Railway: https://railway.app/new"
    echo ""
    echo "📖 For automated deployment, see DEPLOYMENT.md"
    echo ""
    echo "Don't forget to:"
    echo "- Set environment variables in Railway for backend"
    echo "- Update frontend URLs to point to Railway backend URL"
    echo "- Configure CORS in backend for production domain"
fi

