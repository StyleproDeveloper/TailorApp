#!/bin/bash
# Don't use set -e to allow better error handling

echo "🚀 Starting Flutter build for Vercel..."

# Install Flutter if not present
if ! command -v flutter &> /dev/null; then
  echo "📦 Flutter not found. Installing Flutter..."
  
  # Download and install Flutter (use latest stable with Dart 3.6.0+)
  FLUTTER_VERSION="stable"
  FLUTTER_HOME="$HOME/flutter"
  
  if [ ! -d "$FLUTTER_HOME" ]; then
    echo "Downloading Flutter stable (latest)..."
    git clone --depth 1 --branch stable https://github.com/flutter/flutter.git $FLUTTER_HOME || {
      echo "❌ Failed to clone Flutter repository"
      exit 1
    }
  else
    # Update Flutter to latest stable
    cd $FLUTTER_HOME || exit 1
    git checkout stable || exit 1
    git pull || exit 1
    cd - || exit 1
  fi
  
  export PATH="$FLUTTER_HOME/bin:$PATH"
  
  # Verify Flutter is now available
  if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter installation failed - flutter command not found after installation"
    exit 1
  fi
  
  # Skip flutter doctor to save time (it can be slow)
  echo "✅ Flutter installed successfully"
else
  echo "✅ Flutter already available"
fi

# Verify Flutter is available
if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter installation failed!"
  exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"

# Enable web support (if not already enabled)
echo "🌐 Checking web support..."
flutter config --enable-web 2>/dev/null || true

# Get dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get || {
  echo "❌ Failed to get Flutter dependencies"
  exit 1
}

# Clean previous build (optional, but helps with cached issues)
echo "🧹 Cleaning previous build..."
flutter clean 2>/dev/null || true

# Get dependencies again after clean
flutter pub get || {
  echo "❌ Failed to get Flutter dependencies after clean"
  exit 1
}

# Build for web
echo "🔨 Building Flutter web app..."
flutter build web --release --web-renderer canvaskit || {
  echo "❌ Flutter build failed!"
  echo "📋 Attempting build with html renderer..."
  flutter build web --release --web-renderer html || {
    echo "❌ Both renderers failed!"
    echo "📋 Build error details:"
    flutter build web --release --verbose 2>&1 | tail -100
    exit 1
  }
}

# Verify build output exists
if [ ! -d "build/web" ]; then
  echo "❌ Build output directory not found!"
  exit 1
fi

echo "✅ Build completed successfully!"
echo "📁 Output directory: build/web"
ls -la build/web/ | head -20

