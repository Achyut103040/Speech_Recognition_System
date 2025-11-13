"""
This script patches the pyjnius source code to fix Python 3 compatibility.
Run this BEFORE buildozer.
"""
import os
import re

def fix_pyjnius():
    pyjnius_path = os.path.expanduser(
        '~/.buildozer/android/platform/build-arm64-v8a_armeabi-v7a/build/'
        'other_builds/pyjnius-sdl2/armeabi-v7a__ndk_target_21/pyjnius/jnius/jnius_utils.pxi'
    )
    
    if not os.path.exists(pyjnius_path):
        print(f"❌ File not found: {pyjnius_path}")
        print("Run buildozer once first, then run this script.")
        return False
    
    with open(pyjnius_path, 'r') as f:
        content = f.read()
    
    # Fix the 'long' type issue for Python 3
    # Replace: (isinstance(arg, long) and arg < 2147483648)
    # With: (isinstance(arg, int) and arg < 2147483648)
    fixed_content = re.sub(
        r'\(isinstance\(arg,\s*long\)',
        '(isinstance(arg, int)',
        content
    )
    
    if fixed_content != content:
        with open(pyjnius_path, 'w') as f:
            f.write(fixed_content)
        print(f"✅ Fixed pyjnius at: {pyjnius_path}")
        return True
    else:
        print("⚠️ No changes needed or pattern not found")
        return False

if __name__ == '__main__':
    fix_pyjnius()