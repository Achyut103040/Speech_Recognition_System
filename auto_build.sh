#!/bin/bash
# Complete build script that handles all known issues

cd /mnt/d/Speech_Recognition

echo "=== Step 1: Patch build.py for SSL fix ==="
python3 patch_build.py
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to patch build.py"
    exit 1
fi

echo ""
echo "=== Step 2: Start build and monitor for errors ==="
export PATH='/home/achyut/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH'

MAX_RETRIES=5
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo ""
    echo "=== Build attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES ==="
    
    # Start build
    buildozer android debug 2>&1 | tee build_output.log
    BUILD_EXIT=$?
    
    # Check for success
    if [ $BUILD_EXIT -eq 0 ]; then
        echo ""
        echo "=== BUILD SUCCESS! ==="
        ls -lh bin/*.apk 2>/dev/null
        exit 0
    fi
    
    # Check for pyjnius long error
    if grep -q "jnius/jnius_utils.pxi.*undeclared name not builtin: long" build_output.log; then
        echo ""
        echo "=== Found pyjnius long error, fixing... ==="
        python3 fix_pyjnius.py
        RETRY_COUNT=$((RETRY_COUNT + 1))
        continue
    fi
    
    # Check for kivy weakproxy error
    if grep -q "kivy/weakproxy.pyx.*undeclared name not builtin: long" build_output.log; then
        echo ""
        echo "=== Found kivy weakproxy error, fixing... ==="
        find .buildozer -path '*kivy/arm64-v8a*' -name 'weakproxy.pyx' -exec sed -i '/def __long__/,/return long/d' {} \;
        RETRY_COUNT=$((RETRY_COUNT + 1))
        continue
    fi
    
    # Check for kivy opengl error
    if grep -q "kivy/graphics/opengl.pyx.*isinstance.*long" build_output.log; then
        echo ""
        echo "=== Found kivy opengl error, fixing... ==="
        find .buildozer -path '*kivy/arm64-v8a*' -name 'opengl.pyx' -exec sed -i 's/isinstance(\([^,]*\), (long, int))/isinstance(\1, int)/g' {} \;
        RETRY_COUNT=$((RETRY_COUNT + 1))
        continue
    fi
    
    # Check for kivy context_instructions error
    if grep -q "kivy/graphics/context_instructions.pyx.*long" build_output.log; then
        echo ""
        echo "=== Found kivy context_instructions error, fixing... ==="
        find .buildozer -path '*kivy/arm64-v8a*' -name 'context_instructions.pyx' -exec sed -i 's/cdef long i = long(/cdef int i = int(/g' {} \;
        RETRY_COUNT=$((RETRY_COUNT + 1))
        continue
    fi
    
    # Unknown error
    echo ""
    echo "=== Build failed with unknown error ==="
    tail -50 build_output.log
    exit 1
done

echo ""
echo "=== MAX RETRIES REACHED ==="
echo "Build failed after $MAX_RETRIES attempts"
exit 1
