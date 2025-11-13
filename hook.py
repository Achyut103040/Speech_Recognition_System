"""
Custom p4a hook to patch pyjnius for Python 3 compatibility.
This runs automatically during buildozer build process.
"""
import os
import glob

def patch_pyjnius_files():
    """Patch all pyjnius_utils.pxi files for Python 3"""
    # Find build directory
    patterns = [
        "/home/*/speech_recognition/.buildozer/android/platform/build-*/build/other_builds/pyjnius*/*/pyjnius/jnius/jnius_utils.pxi",
        "/home/*/.buildozer/android/platform/build-*/build/other_builds/pyjnius*/*/pyjnius/jnius/jnius_utils.pxi",
    ]
    
    for pattern in patterns:
        for filepath in glob.glob(pattern):
            if os.path.exists(filepath):
                with open(filepath, 'r') as f:
                    content = f.read()
                
                if 'isinstance(arg, long)' in content:
                    fixed = content.replace('isinstance(arg, long)', 'isinstance(arg, int)')
                    with open(filepath, 'w') as f:
                        f.write(fixed)
                    print(f"[HOOK] ✅ Patched pyjnius for Python 3: {filepath}")

# Run patch when hook is loaded
patch_pyjnius_files()
