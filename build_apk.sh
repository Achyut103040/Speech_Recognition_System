#!/bin/bash
# Quick Build Script for Speech Recognition APK
# Handles pyjnius patching automatically

set -e  # Exit on error

# Set correct PATH
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

echo "=========================================="
echo "Speech Recognition APK Builder"
echo "=========================================="
echo ""

# Change to project directory
cd ~/speech_recognition || cd /mnt/d/Speech_Recognition

echo "Step 1/4: Starting initial build..."
echo "Note: Build may fail at pyjnius - this is expected!"
echo ""

# Run initial build (will likely fail at pyjnius)
if buildozer android debug 2>&1 | tee /tmp/build_initial.log; then
    echo "✅ Build succeeded on first try!"
else
    echo "⚠️  Build failed (expected if pyjnius error)"
    
    # Check if it's the pyjnius error
    if grep -q "undeclared name not builtin: long" /tmp/build_initial.log; then
        echo ""
        echo "Step 2/4: Detected pyjnius Python 3 compatibility issue"
        echo "Running automatic patch..."
        echo ""
        
        # Run the patch script
        python3 fix_pyjnius.py || python fix_pyjnius.py
        
        echo ""
        echo "Step 3/4: Rebuilding with patched pyjnius..."
        echo ""
        
        # Rebuild
        buildozer android debug
        
        echo ""
        echo "✅ Build completed successfully!"
    else
        echo "❌ Build failed with a different error"
        echo "Check /tmp/build_initial.log for details"
        exit 1
    fi
fi

echo ""
echo "Step 4/4: Copying APK to Windows..."

# Copy APK to Windows
if [ -d "/mnt/d/Speech_Recognition" ]; then
    cp bin/*.apk /mnt/d/Speech_Recognition/bin/ 2>/dev/null || mkdir -p /mnt/d/Speech_Recognition/bin && cp bin/*.apk /mnt/d/Speech_Recognition/bin/
    echo "✅ APK copied to D:\Speech_Recognition\bin\"
else
    echo "⚠️  Windows path not found, APK is in: $(pwd)/bin/"
fi

echo ""
echo "=========================================="
echo "✅ BUILD COMPLETE!"
echo "=========================================="
echo ""
echo "APK Location:"
ls -lh bin/*.apk | tail -1
echo ""
echo "Next steps:"
echo "1. Transfer APK to your Android phone"
echo "2. Install the APK"
echo "3. Grant permissions when prompted"
echo "4. Test the app!"
echo ""
