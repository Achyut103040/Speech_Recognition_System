# 📱 Complete Guide: Android & iOS Deployment + Testing

---

## 🔴 ERROR FIX: "Unknown command/target android"

### **Problem:**
```
buildozer android debug
# Unknown command/target android
```

### **Root Cause:**
- Incomplete or incorrect `buildozer.spec` configuration
- Missing Android SDK/NDK setup on Windows
- Buildozer must run on **Linux** for Android builds

### **Solution: Use WSL2 (Windows Subsystem for Linux)**

**Step 1: Install WSL2**
```powershell
# In Windows PowerShell (as Administrator)
wsl --install

# Restart your computer
```

**Step 2: Install Linux Ubuntu 22.04**
```bash
# After WSL2 installation
wsl --install -d Ubuntu-22.04
```

**Step 3: Set up Ubuntu in WSL2**
```bash
# Inside Ubuntu terminal
sudo apt-get update
sudo apt-get upgrade -y
```

**Step 4: Install Java & Android SDK in WSL2**
```bash
# Install Java
sudo apt-get install -y openjdk-11-jdk-headless

# Download Android SDK (this will take time)
cd ~
wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
unzip commandlinetools-linux-9477386_latest.zip
mkdir -p Android/sdk/cmdline-tools
mv cmdline-tools Android/sdk/cmdline-tools/latest

# Set environment variables
echo 'export ANDROID_HOME=$HOME/Android/sdk' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools' >> ~/.bashrc
source ~/.bashrc

# Accept licenses
yes | sdkmanager --licenses

# Install required SDK versions
sdkmanager "build-tools;31.0.0"
sdkmanager "platforms;android-31"
sdkmanager "ndk;25.1.8937393"
```

**Step 5: Install Buildozer in WSL2**
```bash
# Install system dependencies
sudo apt-get install -y \
    python3-pip \
    build-essential \
    libsdl2-dev \
    libsdl2-image-dev \
    libsdl2-mixer-dev \
    libsdl2-ttf-dev \
    libportmidi-dev \
    libswscale-dev \
    libavformat-dev \
    libavcodec-dev \
    zlib1g-dev \
    git \
    cython3

# Install Buildozer
pip3 install --upgrade buildozer cython
```

**Step 6: Build APK in WSL2**
```bash
# Copy your project to WSL2
# Access Windows files: cd /mnt/d/Speech_Recognition

cd /mnt/d/Speech_Recognition

# Build APK (first time = 20-30 minutes)
buildozer android debug

# APK location: bin/speechrecognition-1.0.0-debug.apk
```

---

## ✅ Building APK (Detailed Steps)

### **Prerequisites Checklist:**

- ☐ WSL2 installed and Ubuntu running
- ☐ Java 11 installed: `java -version`
- ☐ Android SDK installed: `ls $ANDROID_HOME`
- ☐ NDK 25.1+ installed
- ☐ Buildozer installed: `buildozer --version`
- ☐ buildozer.spec configured (✅ Already done)

### **Build Process:**

**Step 1: Navigate to project in WSL2**
```bash
cd /mnt/d/Speech_Recognition
```

**Step 2: Build debug APK (for testing)**
```bash
buildozer android debug
```

Expected output:
```
Buildozer 1.4.0 / Android / Python 3.11.0
Checking system for required tools...
# ... (lots of output)
APK created at: bin/speechrecognition-1.0.0-debug.apk
```

Build time:
- **First time:** 20-30 minutes (downloads lots of dependencies)
- **Subsequent:** 3-5 minutes

**Step 3: Verify APK was created**
```bash
ls -lh bin/*.apk
```

Should show:
```
-rw-r--r-- 1 user user 95M speechrecognition-1.0.0-debug.apk
```

---

## 📱 Testing on Android Phone

### **Method 1: USB Cable + ADB (Fastest)**

**Step 1: Prepare Android Phone**
- Enable Developer Mode: Settings > About > Tap "Build Number" 7 times
- Enable USB Debugging: Settings > Developer Options > USB Debugging
- Connect USB cable to Windows computer

**Step 2: Push APK via ADB**
```bash
# In WSL2 terminal
# First, install Android platform tools
sudo apt-get install -y android-tools-adb android-tools-fastboot

# Connect phone
adb devices
# Should show your device

# Install APK
adb install bin/speechrecognition-1.0.0-debug.apk
```

Output:
```
Success
```

App should now appear on phone home screen! 🎉

**Step 3: Grant Permissions**
- Open app
- Permission popup appears: "Allow app to record audio?"
- Tap "Allow"

**Step 4: Test Features**

✅ Record Button:
- Enter duration: 10
- Tap "Start Recording"
- Speak for 10 seconds
- Audio saved to phone storage

✅ Upload Button:
- Browse phone files
- Select audio file
- Confirm upload

✅ Transcribe Button:
- Select audio file
- Processing starts
- Text output appears

✅ Other Buttons:
- Visualize: Shows waveform graph
- Settings: App settings
- Exit: Closes app

---

### **Method 2: Manual Installation (No ADB)**

**Step 1: Copy APK to Windows**
```bash
# In WSL2
cp bin/speechrecognition-1.0.0-debug.apk /mnt/d/
```

**Step 2: Transfer to Phone**
- Connect phone via USB
- Copy APK from Windows to phone Downloads folder
- Eject USB

**Step 3: Install on Phone**
- Open file manager on phone
- Navigate to Downloads
- Tap APK file
- Tap "Install"
- Accept permissions
- Done!

---

## 🍎 iOS Deployment (Single App for Both Android & iOS)

### **Challenge:**
- iOS requires macOS and Xcode
- Can only build iOS on Mac
- Android can build on any OS (with proper setup)

### **Solution: Build Separately**

**Option A: macOS (Recommended for public release)**

Prerequisites:
- Mac with M1/M2+ chip (or Intel)
- macOS 11+
- Xcode 13+
- Kivy-iOS toolchain

**Install Kivy-iOS:**
```bash
# On Mac terminal
pip3 install kivy-ios

# Create build directory
cd ~/projects
git clone https://github.com/kivy/kivy-ios.git
cd kivy-ios

# Compile toolchain
python3 toolchain.py create python3
```

**Build iOS App:**
```bash
# In your Speech Recognition project on Mac
python3 ~/kivy-ios/toolchain.py create \
    --title "Speech Recognition" \
    --package org.speechrec.app \
    --version 1.0.0 \
    --private $(pwd) \
    python3 numpy kivy vosk
```

**Result:**
- `.ipa` file (Install on iPhone)
- Upload to App Store

---

## 🎯 Single Codebase, Multiple Platforms (Best Practice)

Your app works on both platforms because **Kivy** is cross-platform! 🎉

```
YourApp/
├── main.py          ← Works on Android & iOS
├── app.kv           ← Same UI for both
├── android_audio.py ← Android-specific (auto-selected)
├── buildozer.spec   ← Android config
└── requirements.txt ← Same dependencies
```

### **Platform-Specific Code:**

```python
# In your Python files
import sys
from kivy.utils import platform

if platform == 'android':
    # Android-specific code
    from android.permissions import request_permissions, Permission
    request_permissions([Permission.RECORD_AUDIO])
elif platform == 'ios':
    # iOS-specific code
    # (usually not needed for audio)
    pass
else:
    # Windows/Mac/Linux
    pass
```

---

## 📦 Building for Public Release

### **Android Release APK:**

**Step 1: Update version in buildozer.spec**
```ini
version = 1.0.0
```

**Step 2: Build release APK**
```bash
buildozer android release
```

**Step 3: Sign APK (for Google Play)**
```bash
# Create keystore (do this once)
keytool -genkey -v -keystore ~/my-release-key.keystore \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias upload

# Sign APK
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
    -keystore ~/my-release-key.keystore \
    bin/speechrecognition-1.0.0-release-unsigned.apk upload

# Align APK
zipalign -v 4 \
    bin/speechrecognition-1.0.0-release-unsigned.apk \
    bin/speechrecognition-1.0.0-release.apk
```

**Step 4: Upload to Google Play Store**

1. Create Google Play Developer account ($25 one-time)
2. Create new app entry
3. Upload signed APK
4. Add description, screenshots, privacy policy
5. Submit for review
6. **Published in 2-4 hours!**

---

### **iOS Release:**

**Step 1: Enroll Apple Developer Program ($99/year)**

**Step 2: Create certificates in Xcode**
- Xcode > Preferences > Accounts
- Add your Apple ID
- Create certificates

**Step 3: Build for distribution**
```bash
# On Mac
python3 toolchain.py create \
    --version 1.0.0 \
    --release \
    --provisioning-profile "path/to/profile.mobileprovision" \
    python3 numpy kivy vosk
```

**Step 4: Upload to App Store**
- Xcode > Product > Archive
- Distribute app
- Upload to App Store Connect
- Fill in app details
- Submit for review
- **Review time: 1-3 days**

---

## 🔄 Troubleshooting

### **Issue 1: "buildozer: command not found"**
Solution:
```bash
# Install in WSL2
pip3 install buildozer cython

# Check installation
buildozer --version
```

### **Issue 2: "SDK/NDK not found"**
Solution:
```bash
# Ensure paths are set
echo $ANDROID_HOME
# Should show: /home/user/Android/sdk

# If not set:
export ANDROID_HOME=$HOME/Android/sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
```

### **Issue 3: "No module named 'vosk'"**
Solution:
- Vosk may not compile on Android
- Use online transcription API instead (Google Speech-to-Text)
- Or use pre-built Vosk model

### **Issue 4: "App crashes on startup"**
Solution:
```bash
# Check logs
adb logcat | grep python
# Look for error messages

# Common issues:
# 1. Missing permissions → Grant in app settings
# 2. Missing model file → Download before first use
# 3. Wrong audio device → Check if microphone detected
```

### **Issue 5: "APK too large (>150MB)"**
Solution:
- Remove unused dependencies
- Use smaller Vosk model (vosk-model-small-en-us-0.15)
- Enable ProGuard minification
- Split APK by architecture

---

## ✅ Testing Checklist

### **Before Release:**

- ☐ App runs on Android 7+ (minimum API 21)
- ☐ All permissions granted properly
- ☐ Recording works with microphone
- ☐ Transcription works
- ☐ Buttons don't crash
- ☐ Tested on 2-3 different phones
- ☐ Battery usage reasonable
- ☐ Data privacy compliant
- ☐ Privacy policy included
- ☐ Screenshots taken (for app store)
- ☐ Icon created (512x512 PNG)
- ☐ Description written
- ☐ Release notes ready

### **On Real Devices:**

| Device | Android | Status |
|--------|---------|--------|
| Your phone | 12+ | ✅ Test |
| Friend's phone | 9+ | ✅ Test |
| Old phone | 7 | ✅ Test (minimum) |
| Tablet | Any | ✅ Test |

---

## 📊 Deployment Timeline

| Step | Time | Platform |
|------|------|----------|
| Setup WSL2/Linux | 30 min | Windows |
| Install Android SDK | 20 min | Windows |
| Build first APK | 25 min | Windows/Linux |
| Build subsequent | 3-5 min | Windows/Linux |
| Test on phone | 15 min | Android |
| Create release APK | 5 min | Windows/Linux |
| Sign APK | 5 min | Windows/Linux |
| Upload to Google Play | 10 min | Browser |
| Review & Publish | 2-4 hours | Google |
| **Total** | **~2 hours** | **First time** |

---

## 🚀 Single Codebase Strategy (RECOMMENDED)

**Maintain ONE code repository:**

```
speech-recognition/
├── main.py             (Same for Android & iOS)
├── app.kv              (Same for Android & iOS)
├── requirements.txt    (Shared dependencies)
├── buildozer.spec      (Android config)
├── ios/
│   └── build.py        (iOS build wrapper)
└── README.md           (Build instructions)
```

**To build both:**

```bash
# Android (on WSL2)
cd /mnt/d/speech-recognition
buildozer android debug

# iOS (on macOS)
cd ~/speech-recognition
python3 toolchain.py create ... python3 kivy ...
```

**Same code, different packages!** 🎉

---

## 📞 Quick Reference

| Task | Command |
|------|---------|
| Build Android debug | `buildozer android debug` |
| Build Android release | `buildozer android release` |
| Install on phone | `adb install bin/*.apk` |
| View logs | `adb logcat` |
| Reset build | `buildozer android clean` |
| Update version | Edit `buildozer.spec` version line |

---

## ✨ Final Tips

1. **Test Early:** Build APK and test on real phone immediately
2. **Permissions:** Always request and test permissions
3. **Size Optimization:** Keep APK under 100MB
4. **Version Control:** Use git to track builds
5. **Release Notes:** Keep changelog for each version
6. **Screenshots:** Take 4-5 good screenshots for app store
7. **Privacy Policy:** Include one (required by stores)
8. **Support Email:** Have one ready for user support

---

**Status:** ✅ Ready to deploy to Android
**Next:** Follow steps above to build APK and test on phone!
