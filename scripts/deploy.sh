#!/bin/bash

echo "🚀 Deploying Tailor App to Production..."

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

echo "🎉 Ready for deployment!"
echo ""
echo "Next steps:"
echo "1. Push to GitHub: git add . && git commit -m 'Deploy to production' && git push"
echo "2. Deploy frontend to Vercel: https://vercel.com/new"
echo "3. Deploy backend to Railway: https://railway.app/new"
echo ""
echo "Don't forget to:"
echo "- Set environment variables in Railway for backend"
echo "- Update frontend URLs to point to Railway backend URL"
echo "- Configure CORS in backend for production domain"
