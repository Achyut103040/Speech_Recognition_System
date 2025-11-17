#!/bin/bash
# Complete APK Build System with Error Handling and Retries
set -e

cd /mnt/d/Speech_Recognition

echo "================================================"
echo "  Speech Recognition APK Build System v2.0"
echo "  With Comprehensive Error Handling"
echo "================================================"
echo ""

# Step 1: Fix all known errors
echo "Step 1: Running comprehensive error fixes..."
bash fix_all_build_errors.sh
echo ""

# Step 2: Set environment with proper PATH for Cython
export PATH="/home/achyut/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export ANDROIDSDK="/home/achyut/.buildozer/android/platform/android-sdk"
export ANDROIDNDK="/home/achyut/.buildozer/android/platform/android-ndk-r25b"
export ANDROIDAPI="33"
export ANDROIDMINAPI="21"
export ANDROID_HOME="$ANDROIDSDK"
export ANDROID_NDK_HOME="$ANDROIDNDK"
export GIT_HTTP_LOW_SPEED_LIMIT=1000
export GIT_HTTP_LOW_SPEED_TIME=600

echo "Step 2: Building APK with retry logic..."
echo "This may take 10-15 minutes..."
echo ""

# Build with retry on network errors
MAX_RETRIES=3
RETRY_COUNT=0
BUILD_SUCCESS=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ $BUILD_SUCCESS -eq 0 ]; do
    if [ $RETRY_COUNT -gt 0 ]; then
        echo ""
        echo "Retry attempt $RETRY_COUNT of $MAX_RETRIES..."
        echo "Cleaning corrupted downloads..."
        
        # Clean corrupted SDL2 external directories
        rm -rf .buildozer/android/platform/build-arm64-v8a/build/bootstrap_builds/sdl2/jni/SDL2_image/external/jpeg 2>/dev/null || true
        rm -rf .buildozer/android/platform/build-arm64-v8a/build/bootstrap_builds/sdl2/jni/SDL2_image/external/libpng 2>/dev/null || true
        rm -rf .buildozer/android/platform/build-arm64-v8a/build/bootstrap_builds/sdl2/jni/SDL2_image/external/libtiff 2>/dev/null || true
        rm -rf .buildozer/android/platform/build-arm64-v8a/build/bootstrap_builds/sdl2/jni/SDL2_image/external/libwebp 2>/dev/null || true
        
        sleep 5
    fi
    
    # Run buildozer
    if /home/achyut/.local/bin/buildozer android debug 2>&1 | tee build_attempt_$RETRY_COUNT.log; then
        BUILD_SUCCESS=1
        echo ""
        echo "✓ Build succeeded!"
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        
        # Check error type
        if grep -q "fatal: destination path.*already exists" build_attempt_$((RETRY_COUNT - 1)).log; then
            echo ""
            echo "✗ Git clone conflict detected - cleaning and retrying..."
        elif grep -q "RPC failed\|early EOF\|Connection reset" build_attempt_$((RETRY_COUNT - 1)).log; then
            echo ""
            echo "✗ Network error detected - retrying with better settings..."
        elif grep -q "Could not compile build file" build_attempt_$((RETRY_COUNT - 1)).log; then
            echo ""
            echo "✗ Gradle error detected - checking build.gradle..."
            
            # Show the problematic line
            if [ -f ".buildozer/android/platform/build-arm64-v8a/dists/speechrecognitiondebug/build.gradle" ]; then
                echo "Current build.gradle AGP version:"
                grep "com.android.tools.build:gradle:" .buildozer/android/platform/build-arm64-v8a/dists/speechrecognitiondebug/build.gradle | head -1
            fi
            
            # Re-patch templates
            echo "Re-patching templates..."
            find .buildozer/android/platform/python-for-android -name "build.tmpl.gradle" -exec sed -i "s/gradle:[0-9]\+\.[0-9]\+\.[0-9]\+/gradle:4.1.0/g" {} \;
        else
            echo ""
            echo "✗ Unknown error - check build_attempt_$((RETRY_COUNT - 1)).log"
        fi
    fi
done

echo ""
echo "================================================"
echo "  Build Status Check"
echo "================================================"
echo ""

# Check results
if [ $BUILD_SUCCESS -eq 1 ]; then
    APK_FILE=$(find bin -name "*.apk" -type f 2>/dev/null | head -1)
    
    if [ -n "$APK_FILE" ]; then
        echo "✓✓✓ SUCCESS! APK CREATED ✓✓✓"
        echo ""
        ls -lh "$APK_FILE"
        echo ""
        echo "APK Location: $(realpath "$APK_FILE")"
        echo "Size: $(du -h "$APK_FILE" | cut -f1)"
        echo ""
        echo "================================================"
        echo "  Installation Instructions"
        echo "================================================"
        echo ""
        echo "Method 1 - ADB (Recommended):"
        echo "  adb install -r \"$APK_FILE\""
        echo ""
        echo "Method 2 - File Transfer:"
        echo "  1. Copy APK to your phone"
        echo "  2. Open file manager and tap the APK"
        echo "  3. Grant install permissions if asked"
        echo ""
        
        # Save APK to easy location
        cp "$APK_FILE" /mnt/d/SpeechRecognition.apk 2>/dev/null || true
        echo "APK also copied to: D:\\SpeechRecognition.apk"
        echo ""
        
        exit 0
    else
        echo "✗ Build reported success but no APK found!"
        exit 1
    fi
else
    echo "✗✗✗ BUILD FAILED AFTER $MAX_RETRIES ATTEMPTS ✗✗✗"
    echo ""
    echo "Check the log files:"
    echo "  - build_attempt_0.log"
    echo "  - build_attempt_1.log"
    echo "  - build_attempt_2.log"
    echo ""
    echo "Common issues:"
    echo "  1. Network timeout - Check internet connection"
    echo "  2. Gradle errors - May need different p4a version"
    echo "  3. Disk space - Ensure >5GB free"
    echo ""
    
    exit 1
fi
