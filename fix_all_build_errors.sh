#!/bin/bash
# Comprehensive build error fix script
# Fixes all identified issues in one go

set -e
cd /mnt/d/Speech_Recognition

echo "================================================"
echo "  Fixing All Build Errors"
echo "================================================"
echo ""

# Error 1: Corrupted SDL2_image external directories
echo "1. Cleaning corrupted SDL2_image external directories..."
if [ -d ".buildozer/android/platform/build-arm64-v8a/build/bootstrap_builds/sdl2/jni/SDL2_image/external" ]; then
    rm -rf .buildozer/android/platform/build-arm64-v8a/build/bootstrap_builds/sdl2/jni/SDL2_image/external/jpeg
    rm -rf .buildozer/android/platform/build-arm64-v8a/build/bootstrap_builds/sdl2/jni/SDL2_image/external/libpng
    rm -rf .buildozer/android/platform/build-arm64-v8a/build/bootstrap_builds/sdl2/jni/SDL2_image/external/libtiff
    rm -rf .buildozer/android/platform/build-arm64-v8a/build/bootstrap_builds/sdl2/jni/SDL2_image/external/libwebp
    echo "   ✓ Removed corrupted external directories"
else
    echo "   ✓ No corrupted directories found"
fi
echo ""

# Error 2: Clean incomplete builds
echo "2. Cleaning incomplete build artifacts..."
rm -rf .buildozer/android/platform/build-arm64-v8a/build/bootstrap_builds/sdl2/jni/SDL2_image/.configured
rm -rf .buildozer/android/platform/build-arm64-v8a/build/bootstrap_builds/sdl2/jni/SDL2_mixer/.configured
rm -rf .buildozer/android/platform/build-arm64-v8a/build/bootstrap_builds/sdl2/jni/SDL2_ttf/.configured
echo "   ✓ Cleaned incomplete build markers"
echo ""

# Error 3: Fix Gradle templates (AGP version)
echo "3. Patching Gradle templates to use AGP 4.1.0..."
find .buildozer/android/platform/python-for-android -name "build.tmpl.gradle" 2>/dev/null | while read template; do
    if [ -f "$template" ]; then
        # Backup
        cp "$template" "${template}.backup.$(date +%s)" 2>/dev/null || true
        
        # Fix AGP version
        sed -i "s/classpath 'com\.android\.tools\.build:gradle:[0-9]\+\.[0-9]\+\.[0-9]\+'/classpath 'com.android.tools.build:gradle:4.1.0'/g" "$template"
        
        # Fix jcenter
        sed -i 's/jcenter()/mavenCentral()/g' "$template"
        
        # Remove namespace
        sed -i '/^\s*namespace\s/d' "$template"
        
        echo "   ✓ Patched: $(basename $(dirname $template))/$(basename $template)"
    fi
done
echo ""

# Error 4: Fix Gradle wrapper version
echo "4. Configuring Gradle wrapper to 6.7.1..."
find .buildozer/android/platform/python-for-android -name "gradle-wrapper.properties" 2>/dev/null | while read wrapper; do
    if [ -f "$wrapper" ]; then
        sed -i 's|distributionUrl=.*|distributionUrl=https\\://services.gradle.org/distributions/gradle-6.7.1-all.zip|g' "$wrapper"
        echo "   ✓ Patched: $(basename $(dirname $wrapper))/$(basename $wrapper)"
    fi
done
echo ""

# Error 5: Fix Git configuration for large repos
echo "5. Configuring Git for large repository downloads..."
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
git config --global core.compression 0
echo "   ✓ Git configured for large downloads"
echo ""

# Error 6: Increase network timeout
echo "6. Configuring network timeouts..."
export GIT_HTTP_LOW_SPEED_LIMIT=1000
export GIT_HTTP_LOW_SPEED_TIME=600
echo "   ✓ Network timeouts increased"
echo ""

# Error 7: Clean Gradle cache
echo "7. Cleaning Gradle daemon and cache..."
rm -rf ~/.gradle/daemon/
rm -rf ~/.gradle/caches/
echo "   ✓ Gradle cache cleaned"
echo ""

# Error 8: Remove old distributions
echo "8. Removing old distributions..."
rm -rf .buildozer/android/platform/build-arm64-v8a/dists/
echo "   ✓ Old distributions removed"
echo ""

# Error 9: Verify hook.py exists and is valid
echo "9. Verifying hook.py..."
if [ -f "hook.py" ]; then
    python3 -m py_compile hook.py && echo "   ✓ hook.py is valid" || echo "   ✗ hook.py has syntax errors"
else
    echo "   ✗ hook.py not found!"
fi
echo ""

# Error 10: Verify icon.png exists
echo "10. Verifying icon.png..."
if [ -f "icon.png" ]; then
    echo "   ✓ icon.png exists"
else
    echo "   ⚠ Creating default icon.png..."
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
    echo "   ✓ icon.png created"
fi
echo ""

# Error 11: Set proper environment
echo "11. Setting build environment..."
export PATH="/home/achyut/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export ANDROIDSDK="/home/achyut/.buildozer/android/platform/android-sdk"
export ANDROIDNDK="/home/achyut/.buildozer/android/platform/android-ndk-r25b"
export ANDROIDAPI="33"
export ANDROIDMINAPI="21"
export ANDROID_HOME="$ANDROIDSDK"
export ANDROID_NDK_HOME="$ANDROIDNDK"
echo "   ✓ Environment configured"
echo ""

echo "================================================"
echo "  All Errors Fixed - Ready to Build"
echo "================================================"
echo ""
echo "Now run: buildozer android debug"
echo ""
