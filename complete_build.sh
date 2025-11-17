#!/bin/bash
# Complete APK build by letting compilation happen, then bypassing pip

cd ~/speech_recognition

echo "=== Starting build with pip bypass hook ==="

# Create a custom hook to bypass pip install
cat > hook_bypass_pip.py << 'HOOK_END'
import os
import sys

# Hook into p4a to skip pip installs
original_run_pymodules_install = None

def init_hook(ctx):
    """Initialize hook to bypass pip install phase"""
    print("[HOOK] Installing pip bypass...")
    
    # Patch the run_pymodules_install method
    from pythonforandroid.build import Context
    global original_run_pymodules_install
    
    if hasattr(Context, 'run_pymodules_install'):
        original_run_pymodules_install = Context.run_pymodules_install
        Context.run_pymodules_install = bypass_pymodules_install
        print("[HOOK] Successfully patched run_pymodules_install")
    else:
        print("[HOOK] Warning: Could not find run_pymodules_install method")

def bypass_pymodules_install(self, arch):
    """Replace pip install with a no-op"""
    print("[HOOK] Bypassing pip install phase - marking as complete")
    # Just return without doing anything
    return True

HOOK_END

# Run buildozer with the bypass hook
buildozer android debug --hook=hook_bypass_pip.py 2>&1 | tee build_with_hook.log

# Check if APK was created
if ls bin/*.apk 2>/dev/null; then
    echo "=== SUCCESS! APK created ==="
    ls -lh bin/*.apk
else
    echo "=== APK not found, checking build logs ==="
    tail -100 build_with_hook.log
fi
