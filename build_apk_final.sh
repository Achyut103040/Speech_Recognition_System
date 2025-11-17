#!/bin/bash
# Skip SSL packages and build APK directly

cd ~/speech_recognition

# Mark packages as installed to skip pip install
mkdir -p .buildozer/android/platform/build-arm64-v8a/build
touch .buildozer/android/platform/build-arm64-v8a/build/.packages_installed

# Build APK
export PATH="/home/achyut/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
buildozer -v android debug
