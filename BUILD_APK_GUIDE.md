# Building Android APK - Step by Step Guide

## 📱 Prerequisites

To build an APK file, you need:
1. **Flutter SDK** ✅ (Already installed: Flutter 3.35.7)
2. **Android SDK** ❌ (Not installed - need to install)
3. **Java JDK** (Usually comes with Android Studio)

---

## 🚀 Quick Setup (Recommended)

### Option 1: Install Android Studio (Easiest)

1. **Download Android Studio:**
   - Go to: https://developer.android.com/studio
   - Download for macOS
   - Install the application

2. **Setup Android SDK:**
   - Open Android Studio
   - Go to: **Tools → SDK Manager**
   - Install:
     - Android SDK Platform-Tools
     - Android SDK Build-Tools
     - Android SDK (latest version, e.g., Android 14.0)
   - Click "Apply" and wait for installation

3. **Accept Android Licenses:**
   ```bash
   flutter doctor --android-licenses
   ```
   (Press 'y' for all prompts)

4. **Verify Setup:**
   ```bash
   flutter doctor
   ```
   Should show: `[✓] Android toolchain`

---

## 🔨 Build the APK

Once Android SDK is installed:

### Step 1: Get Dependencies
```bash
cd /Users/dhivyan/TailorApp
flutter pub get
```

### Step 2: Build Release APK
```bash
flutter build apk --release
```

### Step 3: Find Your APK
The APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📦 Build Options

### Standard APK (Recommended)
```bash
flutter build apk --release
```
**Output:** `build/app/outputs/flutter-apk/app-release.apk`
**Size:** ~30-50 MB (includes all architectures)

### Split APKs (Smaller size per device)
```bash
flutter build apk --split-per-abi --release
```
**Output:** 
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (32-bit)
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (64-bit)
- `build/app/outputs/flutter-apk/app-x86_64-release.apk` (x86_64)

**Use this if:** You want smaller APK files for specific device types

### App Bundle (For Google Play Store)
```bash
flutter build appbundle --release
```
**Output:** `build/app/outputs/bundle/release/app-release.aab`
**Use this if:** You're publishing to Google Play Store

---

## 🔐 Signing the APK (Optional but Recommended)

For production releases, you should sign your APK:

### Step 1: Generate Keystore
```bash
keytool -genkey -v -keystore ~/tailor-app-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias tailor-app
```

### Step 2: Create `android/key.properties`
```properties
storePassword=<password from step 1>
keyPassword=<password from step 1>
keyAlias=tailor-app
storeFile=<path to keystore file, e.g., /Users/dhivyan/tailor-app-key.jks>
```

### Step 3: Update `android/app/build.gradle.kts`
```kotlin
// Add at the top
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Update buildTypes
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}

// Add signing configs
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}
```

---

## 🧪 Test the APK

### Option 1: Install on Connected Device
```bash
# Connect Android device via USB
# Enable USB debugging on device
flutter install
```

### Option 2: Install APK Manually
1. Transfer `app-release.apk` to your Android device
2. On device: **Settings → Security → Allow installation from unknown sources**
3. Open the APK file and install

---

## 🐛 Troubleshooting

### Error: "No Android SDK found"
**Solution:** Install Android Studio and setup SDK (see Option 1 above)

### Error: "Android licenses not accepted"
**Solution:**
```bash
flutter doctor --android-licenses
# Press 'y' for all prompts
```

### Error: "Gradle build failed"
**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

### Error: "Out of memory"
**Solution:** Increase Gradle memory in `android/gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m
```

---

## 📋 Quick Build Script

Create a file `build-apk.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Building Tailor App APK..."

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
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

Make it executable:
```bash
chmod +x build-apk.sh
./build-apk.sh
```

---

## 📱 Current App Info

- **App Name:** tailorapp
- **Package ID:** com.example.tailorapp
- **Version:** 1.0.0+1
- **Min SDK:** (from Flutter defaults, usually 21)
- **Target SDK:** (from Flutter defaults, usually 34)

---

## 🎯 Next Steps After Building

1. **Test the APK** on a real Android device
2. **Update version** in `pubspec.yaml` if needed:
   ```yaml
   version: 1.0.1+2  # version+buildNumber
   ```
3. **Sign the APK** for production (see Signing section above)
4. **Distribute:**
   - Share APK file directly
   - Upload to Google Play Store (requires App Bundle)
   - Use internal testing track

---

## 📚 Additional Resources

- [Flutter Build Documentation](https://docs.flutter.dev/deployment/android)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Google Play Console](https://play.google.com/console)

