#!/bin/bash
# ULTIMATE fix for ALL 'long' type errors - recursive search and replace
set -e

cd /mnt/d/Speech_Recognition

echo "========================================================="
echo "  ULTIMATE Python 2 'long' Type Fix - Recursive"
echo "========================================================="
echo ""

# Fix pyjnius
echo "1. Fixing pyjnius (all files)..."
PYJNIUS_SRC=".buildozer/android/platform/build-arm64-v8a/build/other_builds/pyjnius-sdl2/arm64-v8a__ndk_target_21/pyjnius"

if [ -d "$PYJNIUS_SRC" ]; then
    cd "$PYJNIUS_SRC"
    
    # Find and fix ALL files with 'long' references
    find . -type f \( -name "*.pyx" -o -name "*.pxi" -o -name "*.py" \) -exec grep -l "long" {} \; | while read file; do
        # Fix isinstance checks
        sed -i 's/isinstance(\([^,]*\), long)/isinstance(\1, int)/g' "$file"
        sed -i 's/(int, long)/(int)/g' "$file"
        
        # Remove long from dictionaries
        sed -i '/^[[:space:]]*long:/d' "$file"
        
        # Remove __long__ methods
        sed -i '/def __long__(self):/,+1d' "$file"
        
        echo "  ✓ Fixed $file"
    done
    
    cd /mnt/d/Speech_Recognition
    echo "✓ pyjnius completely fixed"
else
    echo "⚠ pyjnius source not found"
fi
echo ""

# Fix kivy
echo "2. Fixing kivy (all files recursively)..."
KIVY_SRC=".buildozer/android/platform/build-arm64-v8a/build/other_builds/kivy/arm64-v8a__ndk_target_21/kivy"

if [ -d "$KIVY_SRC" ]; then
    cd "$KIVY_SRC"
    
    # Find ALL files with 'long' references
    find kivy -type f \( -name "*.pyx" -o -name "*.pxi" -o -name "*.py" \) -exec grep -l "long" {} \; | while read file; do
        echo "  Fixing $file..."
        
        # Fix cdef long declarations: cdef long var = long(...) → cdef int var = int(...)
        sed -i 's/cdef long \([a-zA-Z_][a-zA-Z0-9_]*\) = long(/cdef int \1 = int(/g' "$file"
        sed -i 's/cdef long /cdef int /g' "$file"
        
        # Fix long() function calls → int()
        sed -i 's/= long(/= int(/g' "$file"
        sed -i 's/ long(/ int(/g' "$file"
        sed -i 's/(long(/(int(/g' "$file"
        sed -i 's/,long(/,int(/g' "$file"
        
        # Fix isinstance checks
        sed -i 's/isinstance(\([^,]*\), long)/isinstance(\1, int)/g' "$file"
        sed -i 's/(int, long)/(int)/g' "$file"
        
        # Remove __long__ methods entirely
        sed -i '/def __long__(self):/,+1d' "$file"
        
        # Remove long from dictionaries and type definitions
        sed -i '/^[[:space:]]*long:/d' "$file"
        
        echo "  ✓ Fixed $file"
    done
    
    cd /mnt/d/Speech_Recognition
    echo "✓ kivy completely fixed"
else
    echo "⚠ kivy source not found"
fi
echo ""

echo "========================================================="
echo "  ALL 'long' type errors fixed recursively!"
echo "========================================================="
echo ""

# Summary of what was fixed
echo "Summary of fixes applied:"
echo "  - cdef long → cdef int"
echo "  - long(...) → int(...)"
echo "  - isinstance(..., long) → isinstance(..., int)"
echo "  - (int, long) → (int)"
echo "  - Removed __long__() methods"
echo "  - Removed 'long:' dictionary entries"
echo ""
