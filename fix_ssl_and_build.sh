#!/bin/bash
# Build APK by pre-downloading pip packages to avoid SSL issues

cd ~/speech_recognition

echo "=== Downloading required packages locally ==="

# Download packages using system pip (which has SSL)
mkdir -p pip_packages
pip3 download -d pip_packages Cython certifi chardet idna requests urllib3 2>&1 | grep -E "Saved|ERROR"

echo "=== Starting build (will stop at pip phase) ==="

# Start build in background
buildozer android debug > build_log.txt 2>&1 &
BUILD_PID=$!

# Wait for venv to be created
echo "Waiting for venv creation..."
while [ ! -d .buildozer/android/platform/build-arm64-v8a/build/venv ]; do
    sleep 2
    if ! ps -p $BUILD_PID > /dev/null; then
        echo "Build process died, checking if it needs restart..."
        break
    fi
done

# Wait a bit more for pip to start failing
sleep 5

echo "=== Installing packages into venv from local cache ==="

# Kill the build temporarily
pkill -STOP -f buildozer

# Install packages into the venv from local files (no network needed)
if [ -d .buildozer/android/platform/build-arm64-v8a/build/venv ]; then
    .buildozer/android/platform/build-arm64-v8a/build/venv/bin/pip install \
        --no-index \
        --find-links=pip_packages \
        Cython certifi chardet idna requests urllib3 2>&1 | grep -E "Successfully|ERROR"
    
    echo "=== Packages installed, resuming build ==="
    # Resume the build
    pkill -CONT -f buildozer
    
    # Wait for build to complete
    wait $BUILD_PID
    
    echo "=== Build completed, checking for APK ==="
    ls -lh bin/*.apk 2>/dev/null || echo "No APK found"
else
    echo "ERROR: venv not created"
    pkill -KILL -f buildozer
fi
