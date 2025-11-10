#!/bin/bash
set -e

echo "🚀 Starting Flutter build for Vercel..."

# Install Flutter if not present
if ! command -v flutter &> /dev/null; then
  echo "📦 Flutter not found. Installing Flutter..."
  
  # Download and install Flutter
  FLUTTER_VERSION="3.24.0"
  FLUTTER_HOME="$HOME/flutter"
  
  if [ ! -d "$FLUTTER_HOME" ]; then
    echo "Downloading Flutter $FLUTTER_VERSION..."
    git clone --branch stable https://github.com/flutter/flutter.git -b $FLUTTER_VERSION $FLUTTER_HOME
  fi
  
  export PATH="$FLUTTER_HOME/bin:$PATH"
  flutter doctor
fi

# Verify Flutter is available
if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter installation failed!"
  exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"

# Get dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Build for web
echo "🔨 Building Flutter web app..."
flutter build web --release

echo "✅ Build completed successfully!"
echo "📁 Output directory: build/web"

