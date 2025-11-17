#!/bin/bash
# Ultimate Build Script - Fixes ALL errors and builds APK

set -e

echo "==========================================================================="
echo "  ULTIMATE APK BUILD SCRIPT - COMPREHENSIVE ERROR FIXING"
echo "==========================================================================="
echo ""

cd /mnt/d/Speech_Recognition

# Set proper environment
export PATH="/home/achyut/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PYTHONPATH=""
export ANDROIDSDK="/home/achyut/.buildozer/android/platform/android-sdk"
export ANDROIDNDK="/home/achyut/.buildozer/android/platform/android-ndk-r25b"
export ANDROIDAPI="33"
export ANDROIDMINAPI="21"
export ANDROID_HOME="$ANDROIDSDK"
export ANDROID_NDK_HOME="$ANDROIDNDK"

echo "✓ Environment configured"
echo ""

# Step 1: Clean corrupted/incomplete builds
echo "==========================================================================="
echo "Step 1: Cleaning corrupted builds..."
echo "==========================================================================="

rm -rf .buildozer/android/platform/build-arm64-v8a/build/other_builds/kivy/arm64-v8a__ndk_target_21/kivy 2>/dev/null || true
rm -rf .buildozer/android/platform/build-arm64-v8a/build/other_builds/pyjnius-sdl2/arm64-v8a__ndk_target_21/pyjnius 2>/dev/null || true
rm -rf .buildozer/android/platform/build-arm64-v8a/build/bootstrap_builds/sdl2/jni/SDL2_image/external 2>/dev/null || true
rm -rf ~/.gradle/daemon 2>/dev/null || true
rm -rf ~/.gradle/caches 2>/dev/null || true

echo "✓ Cleaned corrupted builds"
echo ""

# Step 2: Fix Gradle templates
echo "==========================================================================="
echo "Step 2: Fixing Gradle templates..."
echo "==========================================================================="

find .buildozer/android/platform/python-for-android -name "build.tmpl.gradle" 2>/dev/null | while read template; do
    if [ -f "$template" ]; then
        # Fix AGP version
        sed -i "s/classpath 'com\.android\.tools\.build:gradle:[0-9]\+\.[0-9]\+\.[0-9]\+'/classpath 'com.android.tools.build:gradle:4.1.0'/g" "$template"
        
        # Fix repositories
        sed -i 's/jcenter()/mavenCentral()/g' "$template"
        
        # Remove namespace
        sed -i '/^\s*namespace\s/d' "$template"
        
        echo "  ✓ Fixed: $(basename $(dirname $template))/$(basename $template)"
    fi
done

echo "✓ Gradle templates fixed"
echo ""

# Step 3: Fix Gradle wrapper
echo "==========================================================================="
echo "Step 3: Fixing Gradle wrapper..."
echo "==========================================================================="

find .buildozer/android/platform/python-for-android -name "gradle-wrapper.properties" 2>/dev/null | while read wrapper; do
    if [ -f "$wrapper" ]; then
        sed -i 's|distributionUrl=.*|distributionUrl=https\\://services.gradle.org/distributions/gradle-6.7.1-all.zip|g' "$wrapper"
        echo "  ✓ Fixed: $(basename $(dirname $wrapper))/$(basename $wrapper)"
    fi
done

echo "✓ Gradle wrapper fixed"
echo ""

# Step 4: Configure Git for large downloads
echo "==========================================================================="
echo "Step 4: Configuring Git..."
echo "==========================================================================="

git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
git config --global core.compression 0

export GIT_HTTP_LOW_SPEED_LIMIT=1000
export GIT_HTTP_LOW_SPEED_TIME=600

echo "✓ Git configured"
echo ""

# Step 5: Build with automatic Python long error fixing
echo "==========================================================================="
echo "Step 5: Starting build with automatic error fixing..."
echo "==========================================================================="
echo ""

BUILD_ATTEMPT=0
MAX_ATTEMPTS=3
BUILD_SUCCESS=0

while [ $BUILD_ATTEMPT -lt $MAX_ATTEMPTS ] && [ $BUILD_SUCCESS -eq 0 ]; do
    BUILD_ATTEMPT=$((BUILD_ATTEMPT + 1))
    
    echo ""
    echo "-----------------------------------------------------------------------"
    echo "Build Attempt $BUILD_ATTEMPT of $MAX_ATTEMPTS"
    echo "-----------------------------------------------------------------------"
    echo ""
    
    # Run buildozer
    if /home/achyut/.local/bin/buildozer android debug 2>&1 | tee "build_attempt_${BUILD_ATTEMPT}.log"; then
        BUILD_SUCCESS=1
        echo ""
        echo "✅ Build succeeded on attempt $BUILD_ATTEMPT!"
        break
    else
        echo ""
        echo "⚠️  Build attempt $BUILD_ATTEMPT failed"
        
        # Check if it's a Python 'long' error
        if grep -q "undeclared name not builtin: long" "build_attempt_${BUILD_ATTEMPT}.log"; then
            echo ""
            echo "Detected Python 2 'long' error - applying fixes..."
            
            # Run Python fix script
            python3 fix_all_errors.py
            
            echo ""
            echo "Fixes applied, retrying build..."
            
        elif grep -q "fatal: destination path.*already exists" "build_attempt_${BUILD_ATTEMPT}.log"; then
            echo ""
            echo "Detected corrupted git clone - cleaning..."
            
            rm -rf .buildozer/android/platform/build-arm64-v8a/build/bootstrap_builds/sdl2/jni/SDL2_image/external 2>/dev/null || true
            
        elif grep -q "Could not compile build file" "build_attempt_${BUILD_ATTEMPT}.log"; then
            echo ""
            echo "Detected Gradle error - re-applying template fixes..."
            
            find .buildozer/android/platform/python-for-android -name "build.tmpl.gradle" -exec sed -i "s/gradle:[0-9]\+\.[0-9]\+\.[0-9]\+/gradle:4.1.0/g" {} \;
            
        else
            echo ""
            echo "Unknown error - check build_attempt_${BUILD_ATTEMPT}.log"
        fi
        
        # Don't retry if this was the last attempt
        if [ $BUILD_ATTEMPT -eq $MAX_ATTEMPTS ]; then
            break
        fi
        
        echo ""
        echo "Waiting 5 seconds before retry..."
        sleep 5
    fi
done

echo ""
echo "==========================================================================="
echo "  BUILD RESULT"
echo "==========================================================================="
echo ""

# Check for APK
APK_FILE=$(find bin -name "*.apk" -type f 2>/dev/null | head -1)

if [ -n "$APK_FILE" ]; then
    echo "✅✅✅ SUCCESS! APK CREATED ✅✅✅"
    echo ""
    ls -lh "$APK_FILE"
    echo ""
    echo "APK Location: $(realpath "$APK_FILE")"
    echo "Size: $(du -h "$APK_FILE" | cut -f1)"
    echo ""
    
    # Copy to easy location
    cp "$APK_FILE" /mnt/d/SpeechRecognition.apk 2>/dev/null && echo "✓ Copied to D:\\SpeechRecognition.apk"
    
    echo ""
    echo "==========================================================================="
    echo "  INSTALLATION INSTRUCTIONS"
    echo "==========================================================================="
    echo ""
    echo "Method 1 - ADB (Recommended):"
    echo "  1. Connect phone via USB"
    echo "  2. Enable USB debugging"
    echo "  3. Run: adb install -r \"$APK_FILE\""
    echo ""
    echo "Method 2 - File Transfer:"
    echo "  1. Copy D:\\SpeechRecognition.apk to phone"
    echo "  2. Open file manager and tap APK"
    echo "  3. Install (enable unknown sources if needed)"
    echo ""
    
    exit 0
else
    echo "❌❌❌ BUILD FAILED AFTER $MAX_ATTEMPTS ATTEMPTS ❌❌❌"
    echo ""
    echo "Check log files:"
    for i in $(seq 1 $BUILD_ATTEMPT); do
        echo "  - build_attempt_${i}.log"
    done
    echo ""
    echo "Last 50 lines of final attempt:"
    echo "-----------------------------------------------------------------------"
    tail -50 "build_attempt_${BUILD_ATTEMPT}.log"
    echo ""
    
    exit 1
fi
