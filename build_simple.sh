#!/bin/bash
set -e

echo "=== Direct P4A APK Build ===" 
cd /mnt/d/Speech_Recognition

# Set environment
export PATH="/home/achyut/.local/bin:/usr/bin:/bin"
export ANDROIDSDK="/home/achyut/.buildozer/android/platform/android-sdk"
export ANDROIDNDK="/home/achyut/.buildozer/android/platform/android-ndk-r25b"
export ANDROIDAPI="33"
export ANDROID_HOME="$ANDROIDSDK"
export ANDROID_NDK_HOME="$ANDROIDNDK"

# Fix Gradle version in template to use older stable version
TEMPLATE="/mnt/d/Speech_Recognition/.buildozer/android/platform/python-for-android/pythonforandroid/bootstraps/common/build/templates/build.tmpl.gradle"
if [ -f "$TEMPLATE" ]; then
    echo "Patching template to use Gradle 4.1.0..."
    sed -i "s/gradle:[0-9]\.[0-9]\.[0-9]/gradle:4.1.0/g" "$TEMPLATE"
    sed -i "s/gradle:[0-9]\.[0-9]/gradle:4.1.0/g" "$TEMPLATE"
    sed -i "s/jcenter()/mavenCentral()/g" "$TEMPLATE"
    sed -i "/namespace/d" "$TEMPLATE"
    echo "Template patched"
fi

# Build APK using p4a directly
echo "Building APK..."
cd /mnt/d/Speech_Recognition/.buildozer/android/platform/python-for-android

python3 -m pythonforandroid.toolchain apk \
    --bootstrap sdl2 \
    --dist_name speechrecognitiondebug \
    --name "Speech Recognition Debug" \
    --version 1.0.2 \
    --package org.speechrec.speechrecognitiondebug \
    --minsdk 21 \
    --ndk-api 21 \
    --private /mnt/d/Speech_Recognition/.buildozer/android/app \
    --permission INTERNET \
    --permission RECORD_AUDIO \
    --permission WRITE_EXTERNAL_STORAGE \
    --permission READ_EXTERNAL_STORAGE \
    --permission MANAGE_EXTERNAL_STORAGE \
    --android-entrypoint org.kivy.android.PythonActivity \
    --android-apptheme "@android:style/Theme.NoTitleBar" \
    --presplash /mnt/d/Speech_Recognition/icon.png \
    --icon /mnt/d/Speech_Recognition/icon.png \
    --orientation landscape \
    --enable-androidx \
    --copy-libs \
    --arch arm64-v8a \
    --storage-dir=/mnt/d/Speech_Recognition/.buildozer/android/platform/build-arm64-v8a \
    --hook=/mnt/d/Speech_Recognition/hook.py \
    --ignore-setup-py \
    --debug

echo ""
echo "=== Build Complete ==="
echo "Checking for APK..."
find /mnt/d/Speech_Recognition/.buildozer -name "*.apk" -type f 2>/dev/null | head -5

