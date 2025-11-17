#!/usr/bin/env python3
"""
Fix Python 2->3 'long' type issues in Kivy for Android builds
Fixes all occurrences of Python 2's 'long' type in Kivy source files
"""

import os
import re
import glob

def find_kivy_files():
    """Find all Kivy Python/Cython source files"""
    patterns = [
        '.buildozer/android/platform/build-arm64-v8a/build/other_builds/kivy/**/kivy/**/*.pyx',
        '.buildozer/android/platform/build-arm64-v8a/build/other_builds/kivy/**/kivy/**/*.pxi',
        '.buildozer/android/platform/build-arm64-v8a/build/other_builds/kivy/**/kivy/**/*.py'
    ]
    
    files = []
    for pattern in patterns:
        files.extend(glob.glob(pattern, recursive=True))
    
    return list(set(files))  # Remove duplicates

def patch_file(filepath):
    """Apply Python 3 fixes to a file"""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception as e:
        print(f"⚠️  Could not read {filepath}: {e}")
        return False
    
    original_content = content
    changes = 0
    
    # Fix 1: isinstance(x, long) -> isinstance(x, int)
    if 'isinstance(' in content and 'long' in content:
        new_content = re.sub(r'isinstance\(([^,]+),\s*long\s*\)', r'isinstance(\1, int)', content)
        if new_content != content:
            changes += content.count('isinstance(') - new_content.count('isinstance(')
            content = new_content
    
    # Fix 2: (int, long) -> (int,)  OR  (long, int) -> (int,)
    if '(int, long)' in content or '(long, int)' in content:
        content = re.sub(r'\(int,\s*long\)', '(int,)', content)
        content = re.sub(r'\(long,\s*int\)', '(int,)', content)
        changes += 1
    
    # Fix 3: 'long': -> 'int': (quoted dictionary keys)
    if "'long'" in content:
        content = re.sub(r"'long'\s*:", "'int':", content)
        changes += 1
    
    # Fix 4: long: -> int: (unquoted dictionary keys)
    if re.search(r'\blong\s*:', content):
        content = re.sub(r'\blong\s*:', 'int:', content)
        changes += 1
    
    # Fix 5: return long(...) -> return int(...)
    if 'return long(' in content:
        content = re.sub(r'return long\(', 'return int(', content)
        changes += 1
    
    # Fix 6: def __long__(self): method (remove entirely)
    if 'def __long__' in content:
        # Remove the entire method
        content = re.sub(r'(\n\s+)def __long__\(self\):.*?(?=\n\s+def |\n\nclass |\Z)', '', content, flags=re.DOTALL)
        changes += 1
    
    # Fix 7: = long -> = int (variable assignments)
    if ' = long' in content:
        content = re.sub(r'(\s)=\s*long(?!\w)', r'\1= int', content)
        changes += 1
    
    if content != original_content:
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return changes
        except Exception as e:
            print(f"⚠️  Could not write {filepath}: {e}")
            return False
    
    return 0

def main():
    print("🔍 Searching for Kivy files...")
    files = find_kivy_files()
    
    if not files:
        print("❌ No Kivy files found. Run buildozer first.")
        return
    
    print(f"📝 Found {len(files)} file(s) to check")
    
    modified = 0
    total_changes = 0
    
    for filepath in files:
        result = patch_file(filepath)
        if result:
            modified += 1
            total_changes += result
            filename = os.path.basename(filepath)
            print(f"✅ Fixed {filename} ({result} changes)")
    
    print(f"\n🎉 COMPLETE! Modified {modified}/{len(files)} files ({total_changes} total changes)")

if __name__ == '__main__':
    main()
