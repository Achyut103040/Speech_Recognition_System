#!/usr/bin/env python3
"""Patch python-for-android build.py to use local pip cache"""

import os
import sys

build_py_path = '.buildozer/android/platform/python-for-android/pythonforandroid/build.py'

if not os.path.exists(build_py_path):
    print(f"Error: {build_py_path} not found")
    sys.exit(1)

# Read the file
with open(build_py_path, 'r') as f:
    content = f.read()

# Store original for backup
with open(build_py_path + '.orig', 'w') as f:
    f.write(content)

# Patch 1: pip upgrade (line ~708)
content = content.replace(
    '"source venv/bin/activate && pip install -U pip"',
    '"source venv/bin/activate && pip install -U pip --no-index --find-links=/tmp/pip_cache || true"'
)

# Patch 2: Cython install (line ~714)
content = content.replace(
    '"venv/bin/pip install Cython"',
    '"venv/bin/pip install Cython --no-index --find-links=/tmp/pip_cache"'
)

# Patch 3: Requirements install (line ~758)
old_line = '"venv/bin/pip " +\n                "install -v --target'
new_line = '"venv/bin/pip " +\n                "install -v --no-index --find-links=/tmp/pip_cache --target'

if old_line in content:
    content = content.replace(old_line, new_line)
    print("✓ Patched requirements install line")
else:
    print("⚠ Warning: requirements install pattern not found")

# Write the patched content
with open(build_py_path, 'w') as f:
    f.write(content)

print("✓ Successfully patched build.py to use local pip cache")
print("  Backup saved as build.py.orig")
