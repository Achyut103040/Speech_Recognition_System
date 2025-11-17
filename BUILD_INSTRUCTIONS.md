# 🔧 Build Instructions - Speech Recognition APK

## ⚠️ Critical: Pyjnius Python 3 Compatibility Fix Required

This project requires a **mandatory patch** to fix a known Python 3 compatibility issue in the `pyjnius` library during the Android build process.

---

## 📋 Prerequisites

1. **WSL2 with Ubuntu** (or Linux environment)
2. **Buildozer installed**: `pip install buildozer`
3. **All dependencies**: Java 17, Android SDK, NDK (buildozer will download if missing)

---

## 🚀 Build Process (3 Steps)

### Step 1: Initial Build (Will Fail - Expected!)

```bash
cd ~/speech_recognition
buildozer android debug
```

**Expected Result:** Build will fail with error:
```
jnius/jnius_utils.pxi:323:37: undeclared name not builtin: long
```

This is **normal** and **expected**. The pyjnius library has a Python 2 vs Python 3 compatibility issue.

---

### Step 2: Run the Pyjnius Fix Script

```bash
python fix_pyjnius.py
```

**Expected Output:**
```
🔍 Searching for pyjnius files...
📁 Found X pyjnius file(s)
🔧 Patching files...
✅ Patched: jnius_utils.pxi (3 lines changed)
✅ Patched: jnius_conversion.pxi (2 lines changed)
✅ Complete! Patched X/X file(s)
📦 Now run: buildozer android debug
```

**What this does:**
- Finds all `.pxi` files in pyjnius source
- Replaces Python 2 `long` type with Python 3 `int` type
- Fixes tuple and dictionary type definitions

---

### Step 3: Rebuild (Should Succeed!)

```bash
buildozer android debug
```

**Expected Result:** Build completes successfully!
```
# Android packaging done!
# APK speechrecognition-1.0.2-arm64-v8a-debug.apk available in the bin directory
```

---

## 📦 Copy APK to Windows

```bash
cp bin/*.apk /mnt/d/Speech_Recognition/bin/
```

---

## 🔄 Full Build Script (All Steps Combined)

For convenience, here's a complete script:

```bash
#!/bin/bash
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
cd ~/speech_recognition

echo "Step 1: Initial build (will fail at pyjnius)..."
buildozer android debug 2>&1 | grep -A5 "pyjnius"

echo ""
echo "Step 2: Patching pyjnius..."
python fix_pyjnius.py

echo ""
echo "Step 3: Rebuilding..."
buildozer android debug

echo ""
echo "Step 4: Copying APK to Windows..."
cp bin/*.apk /mnt/d/Speech_Recognition/bin/

echo "✅ Build complete! APK is in D:\Speech_Recognition\bin\"
```

Save this as `build_apk.sh` and run:
```bash
chmod +x build_apk.sh
./build_apk.sh
```

---

## 🐛 Troubleshooting

### Issue: "No pyjnius files found"

**Cause:** Buildozer hasn't downloaded/unpacked pyjnius yet.

**Solution:** Run `buildozer android debug` at least once first, even if it fails.

---

### Issue: Build still fails after patching

**Possible causes:**

1. **Multiple architecture build:** The `buildozer.spec` is configured for `arm64-v8a` only. If you changed it to include `armeabi-v7a`, you need to patch files for BOTH architectures:

```bash
# Find and patch all pyjnius files (both architectures)
find ~/.buildozer -name "*.pxi" -path "*/pyjnius/jnius/*" -exec sed -i 's/isinstance(arg, long)/isinstance(arg, int)/g' {} \;
```

2. **Cached build:** Clean the build cache:

```bash
rm -rf .buildozer/android/platform/build-arm64-v8a
buildozer android clean
```

Then repeat Steps 1-3.

---

### Issue: "PATH environment variable" errors

**Cause:** WSL PATH is not configured correctly.

**Solution:**
```bash
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
echo 'export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## 📱 Portrait Mode Configuration

The app is configured to launch in **portrait mode only** to prevent landscape crashes:

### Configuration Files:

**buildozer.spec:**
```ini
android.orientation = portrait
```

**main.py:**
```python
from kivy.config import Config
Config.set('graphics', 'orientation', 'portrait')
```

If you need landscape mode, you must fix the underlying crash issue first (see crash logs).

---

## 🔍 Runtime Audio Format Note

**Important:** The Android recorder (`android_audio.py`) outputs `.3gp` format files, NOT `.wav` files.

**Current behavior:**
- Record Audio → Creates `.3gp` file
- Upload Audio → Expects `.wav`, `.mp3`, `.flac` files

**To handle this:**

Option 1: Convert `.3gp` to `.wav` before processing:
```python
import subprocess
subprocess.run(['ffmpeg', '-i', 'recording.3gp', 'recording.wav'])
```

Option 2: Update `app.kv` file chooser filters to accept `.3gp`:
```yaml
filters: ['*.wav', '*.mp3', '*.flac', '*.3gp']
```

Option 3: Update `android_audio.py` to record directly to PCM/WAV format (more complex).

---

## ✅ Successful Build Checklist

- [ ] `buildozer.spec` has all dependencies: `python3,kivy,android,pyjnius,numpy,soundfile,vosk,requests`
- [ ] Initial build run (failed with pyjnius error)
- [ ] `fix_pyjnius.py` script executed successfully
- [ ] Rebuild completed without errors
- [ ] APK file exists in `bin/` directory
- [ ] APK copied to Windows at `D:\Speech_Recognition\bin\`
- [ ] APK installed on Android device
- [ ] Permissions granted on first launch

---

## 📊 Build Output Summary

**Expected APK:**
- Name: `speechrecognitiondebug-1.0.2-arm64-v8a-debug.apk`
- Size: ~25-30 MB
- Architecture: ARM64-v8a (64-bit)
- Min Android: API 21 (Android 5.0)
- Target Android: API 33 (Android 13)

---

## 🎯 Next Steps After Build

1. **Transfer APK to phone** (USB, email, or cloud)
2. **Install APK** (enable "Unknown Sources" if needed)
3. **Grant permissions** when app requests them:
   - Microphone (RECORD_AUDIO)
   - Storage (READ/WRITE_EXTERNAL_STORAGE)
4. **Test features:**
   - Record Audio
   - Upload Audio
   - Transcribe
   - Visualize
5. **If crashes:** Get logs with `adb logcat | grep -i "python\|speechapp\|fatal"`

---

## 📞 Support

If build still fails after following these steps, provide:
1. Full build log: `buildozer -v android debug > build.log 2>&1`
2. Output of `python fix_pyjnius.py`
3. List of pyjnius files found: `find ~/.buildozer -name "*.pxi" -path "*/pyjnius/*"`

---

**Last Updated:** November 13, 2025  
**Buildozer Version:** 1.5.0  
**Python Version:** 3.11  
**Target NDK:** 25b
