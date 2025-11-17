"""
This script patches the pyjnius source code to fix Python 3 compatibility.
Run this AFTER buildozer fails with 'long' type errors, then rebuild.

Usage:
1. Run: buildozer android debug (will fail with pyjnius error)
2. Run: python fix_pyjnius.py
3. Run: buildozer android debug (should succeed)
"""
import os
import glob
import re
import subprocess
import sys

def find_pyjnius_files():
    """Find all pyjnius .pxi files in buildozer cache"""
    # Check both project-local and user home buildozer directories
    script_dir = os.path.dirname(os.path.abspath(__file__))
    local_buildozer = os.path.join(script_dir, '.buildozer')
    home_buildozer = os.path.expanduser('~/.buildozer')
    
    buildozer_path = None
    if os.path.exists(local_buildozer):
        buildozer_path = local_buildozer
    elif os.path.exists(home_buildozer):
        buildozer_path = home_buildozer
    else:
        print("❌ No .buildozer directory found!")
        print("Run 'buildozer android debug' first to create it.")
        return []
    
    print(f"🔍 Searching in: {buildozer_path}")
    
    # Multiple search patterns for different configurations
    search_patterns = [
        # arm64-v8a with sdl2 bootstrap (most common)
        os.path.join(buildozer_path, 'android/platform/build-arm64-v8a/build/other_builds/pyjnius-sdl2/*/pyjnius/jnius/*.pxi'),
        # arm64-v8a without bootstrap suffix
        os.path.join(buildozer_path, 'android/platform/build-arm64-v8a/build/other_builds/pyjnius/*/pyjnius/jnius/*.pxi'),
        # armeabi-v7a with sdl2
        os.path.join(buildozer_path, 'android/platform/build-armeabi-v7a/build/other_builds/pyjnius-sdl2/*/pyjnius/jnius/*.pxi'),
        # Multi-arch builds
        os.path.join(buildozer_path, 'android/platform/build-*/build/other_builds/pyjnius*/*/pyjnius/jnius/*.pxi'),
    ]
    
    files = []
    for pattern in search_patterns:
        found = glob.glob(pattern, recursive=True)
        for f in found:
            if f not in files and os.path.isfile(f):
                files.append(f)
                print(f"  Found: {f}")
    
    # Also try using find command if on Linux/WSL
    if not files:
        print("  Trying 'find' command...")
        try:
            result = subprocess.run(
                ['find', buildozer_path, '-name', '*.pxi', '-path', '*/pyjnius/jnius/*'],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.stdout:
                for line in result.stdout.strip().split('\n'):
                    if line and line not in files and os.path.isfile(line):
                        files.append(line)
                        print(f"  Found: {line}")
        except (FileNotFoundError, subprocess.TimeoutExpired):
            pass  # find command not available or took too long
    
    return files


def patch_file(filepath):
    """Patch a single pyjnius file"""
    try:
        print(f"\n🔧 Patching: {filepath}")
        
        with open(filepath, 'r') as f:
            content = f.read()
        
        original = content
        
        # Fix 1: isinstance(arg, long) -> isinstance(arg, int)
        content = re.sub(
            r'isinstance\(arg,\s*long\)',
            'isinstance(arg, int)',
            content
        )
        
        # Fix 2: (int, long) -> (int,)
        content = re.sub(
            r'\(int,\s*long\)',
            '(int,)',
            content
        )
        
        # Fix 3: 'long': value -> 'int': value in dictionaries
        content = re.sub(
            r"'long'\s*:",
            "'int':",
            content
        )
        
        # Fix 4: long: value -> int: value in dictionaries (without quotes)
        content = re.sub(
            r'\blong\s*:',
            'int:',
            content
        )
        
        if content != original:
            with open(filepath, 'w') as f:
                f.write(content)
            
            # Count changes
            orig_lines = original.split('\n')
            new_lines = content.split('\n')
            changes = sum(1 for a, b in zip(orig_lines, new_lines) if a != b)
            
            print(f"✅ SUCCESS! Changed {changes} lines")
            return True
        else:
            print(f"⚠️  Already patched (no 'long' references found)")
            return False
            
    except Exception as e:
        print(f"❌ ERROR: {e}")
        return False

def fix_pyjnius():
    """Main function to find and patch all pyjnius files"""
    print("=" * 70)
    print("Pyjnius Python 3 Compatibility Patcher")
    print("=" * 70)
    print("")
    
    files = find_pyjnius_files()
    
    if not files:
        print("\n" + "=" * 70)
        print("❌ NO PYJNIUS FILES FOUND")
        print("=" * 70)
        print("\n📝 INSTRUCTIONS:")
        print("1. Run: buildozer android debug")
        print("2. Wait for it to FAIL with error: 'undeclared name not builtin: long'")
        print("3. Run: python fix_pyjnius.py")
        print("4. Run: buildozer android debug (again - should succeed)")
        print("")
        return False
    
    print(f"\n📁 Found {len(files)} file(s) to patch\n")
    
    patched_count = 0
    for filepath in files:
        if patch_file(filepath):
            patched_count += 1
    
    print("\n" + "=" * 70)
    if patched_count > 0:
        print(f"✅ PATCHING COMPLETE! Modified {patched_count}/{len(files)} file(s)")
        print("=" * 70)
        print("\n📦 NEXT STEP:")
        print("   Run: buildozer android debug")
        print("")
        return True
    else:
        print(f"⚠️  ALL FILES ALREADY PATCHED ({len(files)} file(s) checked)")
        print("=" * 70)
        print("\n📦 You can run the build now:")
        print("   Run: buildozer android debug")
        print("")
        return True

if __name__ == '__main__':
    success = fix_pyjnius()
    sys.exit(0 if success else 1)