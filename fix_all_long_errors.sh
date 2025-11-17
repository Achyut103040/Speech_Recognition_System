#!/bin/bash
# Comprehensive fix for ALL Python 2 'long' type errors in build sources
set -e

cd /mnt/d/Speech_Recognition

echo "================================================"
echo "  Fixing ALL 'long' Type Errors in Build Sources"
echo "================================================"
echo ""

# Fix pyjnius
echo "1. Fixing pyjnius long errors..."
PYJNIUS_SRC=".buildozer/android/platform/build-arm64-v8a/build/other_builds/pyjnius-sdl2/arm64-v8a__ndk_target_21/pyjnius"

if [ -d "$PYJNIUS_SRC" ]; then
    cd "$PYJNIUS_SRC"
    
    # Fix jnius_utils.pxi
    if [ -f "jnius/jnius_utils.pxi" ]; then
        sed -i 's/isinstance(arg, long)/isinstance(arg, int)/g' jnius/jnius_utils.pxi
        echo "  ✓ Fixed jnius/jnius_utils.pxi"
    fi
    
    # Fix jnius_conversion.pxi
    if [ -f "jnius/jnius_conversion.pxi" ]; then
        # Fix isinstance checks
        sed -i 's/(int, long)/(int)/g' jnius/jnius_conversion.pxi
        sed -i 's/isinstance(py_arg, (int, long))/isinstance(py_arg, int)/g' jnius/jnius_conversion.pxi
        sed -i 's/isinstance(obj, (int, long))/isinstance(obj, int)/g' jnius/jnius_conversion.pxi
        
        # Fix dictionary: long: 'J', → # long removed
        sed -i '/^            long: /d' jnius/jnius_conversion.pxi
        
        echo "  ✓ Fixed jnius/jnius_conversion.pxi"
    fi
    
    cd /mnt/d/Speech_Recognition
    echo "✓ pyjnius fixed"
else
    echo "⚠ pyjnius source not found yet"
fi
echo ""

# Fix kivy
echo "2. Fixing kivy long errors..."
KIVY_SRC=".buildozer/android/platform/build-arm64-v8a/build/other_builds/kivy/arm64-v8a__ndk_target_21/kivy"

if [ -d "$KIVY_SRC" ]; then
    cd "$KIVY_SRC"
    
    # Fix kivy/weakproxy.pyx
    if [ -f "kivy/weakproxy.pyx" ]; then
        # Remove __long__ method entirely (not needed in Python 3)
        sed -i '/def __long__(self):/,+1d' kivy/weakproxy.pyx
        echo "  ✓ Fixed kivy/weakproxy.pyx"
    fi
    
    # Fix kivy/_event.pyx
    if [ -f "kivy/_event.pyx" ]; then
        sed -i 's/isinstance([^,]*, long)/isinstance(\1, int)/g' kivy/_event.pyx 2>/dev/null || true
        sed -i 's/(int, long)/(int)/g' kivy/_event.pyx 2>/dev/null || true
        echo "  ✓ Fixed kivy/_event.pyx"
    fi
    
    # Fix any other kivy files with long
    find kivy -name "*.pyx" -o -name "*.pxi" | while read file; do
        if grep -q "long" "$file" 2>/dev/null; then
            sed -i 's/(int, long)/(int)/g' "$file" 2>/dev/null || true
            sed -i 's/isinstance(\([^,]*\), long)/isinstance(\1, int)/g' "$file" 2>/dev/null || true
            sed -i '/def __long__(self):/,+1d' "$file" 2>/dev/null || true
            echo "  ✓ Fixed $file"
        fi
    done
    
    cd /mnt/d/Speech_Recognition
    echo "✓ kivy fixed"
else
    echo "⚠ kivy source not found yet"
fi
echo ""

echo "================================================"
echo "  All 'long' errors fixed!"
echo "================================================"
echo ""
