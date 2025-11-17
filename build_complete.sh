#!/bin/bash
# Complete APK Build System - Fixed and Tested
# This script handles all known Gradle/p4a compatibility issues

set -e  # Exit on error

echo "================================================"
echo "  Speech Recognition APK Build System v1.0"
echo "================================================"
echo ""

# Change to project directory
cd /mnt/d/Speech_Recognition

# Environment setup
export PATH="/home/achyut/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export ANDROIDSDK="/home/achyut/.buildozer/android/platform/android-sdk"
export ANDROIDNDK="/home/achyut/.buildozer/android/platform/android-ndk-r25b"
export ANDROIDAPI="33"
export ANDROIDMINAPI="21"
export ANDROID_HOME="$ANDROIDSDK"
export ANDROID_NDK_HOME="$ANDROIDNDK"

echo "✓ Environment configured"
echo ""

# Step 1: Clean previous failed builds
echo "Step 1: Cleaning previous builds..."
rm -rf .buildozer/android/platform/build-arm64-v8a/dists/speechrecognitiondebug/build.gradle 2>/dev/null || true
rm -rf .buildozer/android/platform/build-arm64-v8a/dists/speechrecognitiondebug/.gradle 2>/dev/null || true
rm -rf bin/*.apk 2>/dev/null || true
echo "✓ Cleaned"
echo ""

# Step 2: Fix Gradle templates in ALL p4a source locations
echo "Step 2: Patching python-for-android Gradle templates..."

# Find and patch ALL build.tmpl.gradle files
find ".buildozer/android/platform/python-for-android" -name "build.tmpl.gradle" 2>/dev/null | while read template; do
    if [ -f "$template" ]; then
        # Backup original
        cp "$template" "${template}.backup" 2>/dev/null || true
        
        # Apply fixes:
        # 1. Use AGP 4.1.0 (stable, compatible with older Gradle)
        sed -i "s/classpath 'com\.android\.tools\.build:gradle:[0-9]\+\.[0-9]\+\.[0-9]\+'/classpath 'com.android.tools.build:gradle:4.1.0'/g" "$template"
        
        # 2. Replace deprecated jcenter with mavenCentral
        sed -i 's/jcenter()/mavenCentral()/g' "$template"
        
        # 3. Remove namespace (incompatible with AGP 4.x)
        sed -i '/namespace/d' "$template"
        
        echo "✓ Patched: $template"
    fi
done

echo "✓ All templates patched to AGP 4.1.0"
echo ""

# Step 3: Fix Gradle wrapper properties templates
echo "Step 3: Configuring Gradle wrapper..."

# Find and patch ALL gradle-wrapper.properties files
find ".buildozer/android/platform/python-for-android" -name "gradle-wrapper.properties" 2>/dev/null | while read wrapper; do
    if [ -f "$wrapper" ]; then
        # Use Gradle 6.7.1 (compatible with AGP 4.1.0)
        sed -i 's|distributionUrl=.*|distributionUrl=https\\://services.gradle.org/distributions/gradle-6.7.1-all.zip|g' "$wrapper"
        echo "✓ Patched: $wrapper"
    fi
done

echo "✓ All wrappers configured for Gradle 6.7.1"
echo ""

# Step 4: Verify hook.py exists
echo "Step 4: Verifying build hook..."
if [ -f "hook.py" ]; then
    echo "✓ hook.py found"
else
    echo "✗ ERROR: hook.py not found!"
    exit 1
fi
echo ""

# Step 5: Verify icon exists
echo "Step 5: Verifying icon..."
if [ -f "icon.png" ]; then
    echo "✓ icon.png found"
else
    echo "⚠ Creating default icon..."
    python3 << 'PYEOF'
from PIL import Image, ImageDraw, ImageFont
img = Image.new('RGB', (512, 512), color='#2196F3')
d = ImageDraw.Draw(img)
try:
    font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 200)
except:
    font = ImageFont.load_default()
d.text((256, 256), 'SR', fill='white', anchor='mm', font=font)
img.save('icon.png')
PYEOF
    echo "✓ Icon created"
fi
echo ""

# Step 6: Build APK
echo "Step 6: Building APK..."
echo "This may take 5-10 minutes..."
echo ""

# Add buildozer to PATH explicitly
export PATH="/home/achyut/.local/bin:$PATH"

buildozer android debug 2>&1 | tee build.log || {
    echo ""
    echo "✗ Build failed! Check build.log for details"
    echo ""
    echo "Last 50 lines of log:"
    tail -50 build.log
    exit 1
}

echo ""
echo "================================================"
echo "  Build Status Check"
echo "================================================"
echo ""

# Check if APK was created
APK_FILE=$(find bin -name "*.apk" -type f 2>/dev/null | head -1)

if [ -n "$APK_FILE" ]; then
    echo "✓ SUCCESS! APK created:"
    echo ""
    ls -lh "$APK_FILE"
    echo ""
    
    APK_SIZE=$(du -h "$APK_FILE" | cut -f1)
    echo "Size: $APK_SIZE"
    echo "Location: $(realpath "$APK_FILE")"
    echo ""
    
    # Get APK info
    if command -v aapt &> /dev/null; then
        echo "APK Details:"
        aapt dump badging "$APK_FILE" | grep -E "package:|versionCode|versionName|sdkVersion|targetSdkVersion" | head -5
        echo ""
    fi
    
    echo "================================================"
    echo "  Installation Instructions"
    echo "================================================"
    echo ""
    echo "Method 1 - USB Cable:"
    echo "  1. Enable USB Debugging on your Realme 13 Pro"
    echo "  2. Connect phone via USB"
    echo "  3. Run: adb install -r \"$APK_FILE\""
    echo ""
    echo "Method 2 - File Transfer:"
    echo "  1. Copy APK to your phone's Downloads folder"
    echo "  2. Open file manager on phone"
    echo "  3. Tap the APK file to install"
    echo "  4. Enable 'Install from Unknown Sources' if prompted"
    echo ""
    echo "Method 3 - Cloud Transfer:"
    echo "  1. Upload APK to Google Drive/Dropbox"
    echo "  2. Download on your phone"
    echo "  3. Install from Downloads"
    echo ""
    
    exit 0
else
    echo "✗ FAILED: No APK file found in bin/ directory"
    echo ""
    echo "Checking for partial builds..."
    find .buildozer -name "*.apk" -type f 2>/dev/null || echo "No APK files found anywhere"
    echo ""
    echo "Please check build.log for errors"
    exit 1
fi
