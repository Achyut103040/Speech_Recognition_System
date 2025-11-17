#!/bin/bash
# Manual Build Commands - Copy/paste these into WSL terminal

# Set PATH
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Go to project
cd ~/speech_recognition

echo "============================================"
echo "STEP 1: Run initial build (will fail)"
echo "============================================"
buildozer android debug

echo ""
echo "============================================"
echo "STEP 2: Patch pyjnius"
echo "============================================"
python3 fix_pyjnius.py

echo ""
echo "============================================"
echo "STEP 3: Rebuild (should succeed)"
echo "============================================"
buildozer android debug

echo ""
echo "============================================"
echo "STEP 4: Copy APK to Windows"
echo "============================================"
mkdir -p /mnt/d/Speech_Recognition/bin
cp bin/*.apk /mnt/d/Speech_Recognition/bin/
ls -lh /mnt/d/Speech_Recognition/bin/*.apk

echo ""
echo "✅ Done! APK is in D:\Speech_Recognition\bin\"
