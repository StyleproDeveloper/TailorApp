#!/bin/bash
set -e

echo "🚀 Building Tailor App APK..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed!"
    exit 1
fi

# Check Android SDK
if ! flutter doctor | grep -q "Android toolchain.*✓"; then
    echo "⚠️  Android SDK not found!"
    echo "📋 Please install Android Studio first:"
    echo "   1. Download from: https://developer.android.com/studio"
    echo "   2. Install Android SDK via Tools → SDK Manager"
    echo "   3. Run: flutter doctor --android-licenses"
    echo "   4. Then run this script again"
    exit 1
fi

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build APK
echo "🔨 Building release APK..."
flutter build apk --release

# Show location
echo ""
echo "✅ APK built successfully!"
echo "📱 Location: build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "📊 APK Size:"
ls -lh build/app/outputs/flutter-apk/app-release.apk 2>/dev/null || echo "APK file not found"
