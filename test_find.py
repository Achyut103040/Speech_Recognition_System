import os
import glob

script_dir = os.path.dirname(os.path.abspath(__file__))
local_buildozer = os.path.join(script_dir, '.buildozer')

print(f"Script dir: {script_dir}")
print(f"Local buildozer: {local_buildozer}")
print(f"Exists: {os.path.exists(local_buildozer)}")

pattern = os.path.join(local_buildozer, 'android/platform/build-arm64-v8a/build/other_builds/pyjnius-sdl2/*/pyjnius/jnius/*.pxi')
print(f"Pattern: {pattern}")

files = glob.glob(pattern)
print(f"Found {len(files)} files")
for f in files[:3]:
    print(f"  - {f}")
