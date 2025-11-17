#!/bin/bash
# Fix pyjnius long errors in BUILD source
set -e

cd /mnt/d/Speech_Recognition

echo "Fixing pyjnius long errors in build source..."

PYJNIUS_SRC=".buildozer/android/platform/build-arm64-v8a/build/other_builds/pyjnius-sdl2/arm64-v8a__ndk_target_21/pyjnius"

if [ -d "$PYJNIUS_SRC" ]; then
    cd "$PYJNIUS_SRC"
    
    # Fix all pyjnius files with long references
    echo "Patching all pyjnius files with 'long' references..."
    
    # Fix jnius_utils.pxi
    if [ -f "jnius/jnius_utils.pxi" ]; then
        sed -i 's/isinstance(arg, long)/isinstance(arg, int)/g' jnius/jnius_utils.pxi
        echo "✓ Fixed jnius_utils.pxi"
    fi
    
    # Fix jnius_conversion.pxi
    if [ -f "jnius/jnius_conversion.pxi" ]; then
        # Fix isinstance checks
        sed -i 's/(int, long)/(int)/g' jnius/jnius_conversion.pxi
        sed -i 's/isinstance(py_arg, (int, long))/isinstance(py_arg, int)/g' jnius/jnius_conversion.pxi
        sed -i 's/isinstance(obj, (int, long))/isinstance(obj, int)/g' jnius/jnius_conversion.pxi
        
        # Fix dictionary definition: long: 'J' → # long removed for Python 3
        sed -i 's/^            long: '\''J'\'',$/            # long: '\''J'\'',  # Removed for Python 3 compatibility/g' jnius/jnius_conversion.pxi
        
        echo "✓ Fixed jnius_conversion.pxi"
    fi
    
    # Also check for any other long references
    echo "Checking for other 'long' references..."
    grep -r "isinstance.*long" jnius/ 2>/dev/null | grep -v ".pyc" | grep -v "# long" || echo "No other long references found"
    
    echo "✓ All pyjnius long errors fixed in build source"
else
    echo "✗ pyjnius build directory not found"
    exit 1
fi
