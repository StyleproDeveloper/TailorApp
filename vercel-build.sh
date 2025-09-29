#!/bin/bash

# Vercel build script for Flutter web
echo "🚀 Building Flutter web app for Vercel..."

# Install Flutter dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Build Flutter web app
echo "🔨 Building Flutter web app..."
flutter build web --release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Flutter build successful!"
    echo "📁 Build output: build/web/"
else
    echo "❌ Flutter build failed!"
    exit 1
fi

echo "🎉 Build completed successfully!"
