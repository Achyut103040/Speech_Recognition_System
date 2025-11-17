#!/usr/bin/env python3
"""Fix build.gradle syntax issues"""
import re
import sys

gradle_path = '.buildozer/android/platform/build-arm64-v8a/dists/speechrecognitiondebug/build.gradle'

try:
    with open(gradle_path, 'r') as f:
        content = f.read()
    
    # Replace jcenter with mavenCentral
    content = content.replace('jcenter()', 'mavenCentral()')
    
    # Remove namespace line (causes syntax errors in older Gradle)
    content = re.sub(r'\s*namespace\s+[\'"].*?[\'"]\s*\n', '', content)
    
    with open(gradle_path, 'w') as f:
        f.write(content)
    
    print('✓ Fixed build.gradle')
    sys.exit(0)
    
except Exception as e:
    print(f'✗ Error: {e}')
    sys.exit(1)
