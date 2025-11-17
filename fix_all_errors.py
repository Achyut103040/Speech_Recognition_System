#!/usr/bin/env python3
"""
Complete fix for ALL Python 2 'long' errors in build directories
"""
import os
import glob
import re

def fix_all_long_errors():
    """Fix ALL Python 2 'long' errors recursively in build directories"""
    
    base_paths = [
        '.buildozer/android/platform/build-arm64-v8a/build/other_builds/pyjnius-sdl2',
        '.buildozer/android/platform/build-arm64-v8a/build/other_builds/kivy',
        '.buildozer/android/platform/build-armeabi-v7a/build/other_builds/pyjnius-sdl2',
        '.buildozer/android/platform/build-armeabi-v7a/build/other_builds/kivy',
    ]
    
    patterns_to_fix = [
        # Pattern 1: cdef long variable declarations (use long long for C compatibility)
        (r'\bcdef\s+long\s+([a-zA-Z_])', r'cdef long long \1'),
        
        # Pattern 2: isinstance checks with long
        (r'isinstance\s*\(\s*([^,]+?)\s*,\s*\(\s*long\s*,\s*int\s*\)\s*\)', r'isinstance(\1, int)'),
        (r'isinstance\s*\(\s*([^,]+?)\s*,\s*\(\s*int\s*,\s*long\s*\)\s*\)', r'isinstance(\1, int)'),
        (r'isinstance\s*\(\s*([^,]+?)\s*,\s*long\s*\)', r'isinstance(\1, int)'),
        
        # Pattern 3: long() function calls
        (r'(?<![a-zA-Z_])long\s*\(', 'int('),
        
        # Pattern 4: long in type tuples
        (r'\(\s*int\s*,\s*long\s*\)', '(int)'),
        (r'\(\s*long\s*,\s*int\s*\)', '(int)'),
        
        # Pattern 5: Dictionary with long as key
        (r'{\s*long\s*:', '{ int:'),
        (r',\s*long\s*:', ', int:'),
        (r'\n\s+long\s*:\s*[\'"]', '\n            # long removed - '),
    ]
    
    files_fixed = []
    
    for base_path in base_paths:
        if not os.path.exists(base_path):
            continue
            
        # Find all .pyx, .pxi, and .py files
        for ext in ['**/*.pyx', '**/*.pxi', '**/*.py']:
            pattern = os.path.join(base_path, ext)
            for filepath in glob.glob(pattern, recursive=True):
                try:
                    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                    
                    original_content = content
                    
                    # Apply all pattern fixes
                    for pattern, replacement in patterns_to_fix:
                        content = re.sub(pattern, replacement, content)
                    
                    # Remove __long__ methods entirely (Python 2 only)
                    content = re.sub(
                        r'^\s*def\s+__long__\s*\([^)]*\)\s*:.*?(?=\n\s{0,4}def\s|\n\s{0,4}cdef\s|\Z)',
                        '',
                        content,
                        flags=re.MULTILINE | re.DOTALL
                    )
                    
                    if content != original_content:
                        with open(filepath, 'w', encoding='utf-8') as f:
                            f.write(content)
                        files_fixed.append(filepath)
                        print(f"✅ Fixed: {os.path.relpath(filepath)}")
                        
                except Exception as e:
                    print(f"⚠️  Error fixing {filepath}: {e}")
    
    return files_fixed

if __name__ == '__main__':
    print("=" * 70)
    print("FIXING ALL PYTHON 2 'long' ERRORS IN BUILD DIRECTORIES")
    print("=" * 70)
    print()
    
    fixed = fix_all_long_errors()
    
    print()
    print("=" * 70)
    print(f"✅ FIXED {len(fixed)} FILES")
    print("=" * 70)
    
    if fixed:
        print("\nFiles modified:")
        for f in fixed:
            print(f"  • {os.path.relpath(f)}")
    else:
        print("\n⚠️  No files found to fix. Build directories may not exist yet.")
        print("Run buildozer once to generate build files, then run this script again.")
