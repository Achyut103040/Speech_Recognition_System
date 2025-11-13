# 🐳 Alternative: Build Android APK Using Docker (From Windows)

## ⚡ Fastest Way (Without WSL2)

If you don't want to set up WSL2, use Docker to build APK on Windows!

---

## 📦 Step 1: Install Docker Desktop

1. Download: https://www.docker.com/products/docker-desktop
2. Install and restart Windows
3. Verify: Open PowerShell
   ```powershell
   docker --version
   # Should show: Docker version 20.10+
   ```

---

## 🏗️ Step 2: Create Dockerfile for Buildozer

Create file: `d:\Speech_Recognition\Dockerfile.buildozer`

```dockerfile
FROM ubuntu:22.04

ENV ANDROID_HOME=/root/Android/sdk
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

RUN apt-get update && apt-get install -y \
    openjdk-11-jdk-headless \
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
    cython3 \
    wget \
    unzip

# Install Android SDK
RUN mkdir -p /root/Android/sdk && \
    cd /tmp && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip -q commandlinetools-linux-9477386_latest.zip && \
    mkdir -p /root/Android/sdk/cmdline-tools && \
    mv cmdline-tools /root/Android/sdk/cmdline-tools/latest

# Accept Android licenses
RUN yes | /root/Android/sdk/cmdline-tools/latest/bin/sdkmanager --licenses

# Install SDK components
RUN /root/Android/sdk/cmdline-tools/latest/bin/sdkmanager \
    "build-tools;31.0.0" \
    "platforms;android-31" \
    "ndk;25.1.8937393"

# Install Buildozer
RUN pip3 install --upgrade buildozer cython

WORKDIR /app

CMD ["/bin/bash"]
```

---

## 🚀 Step 3: Build Docker Image

```powershell
cd d:\Speech_Recognition

# Build image (takes 10-15 minutes first time)
docker build -f Dockerfile.buildozer -t buildozer-android .

# Verify image
docker images | findstr buildozer-android
```

---

## 🔨 Step 4: Build APK Using Docker

```powershell
# Run container with your project mounted
docker run -it -v D:\Speech_Recognition:/app buildozer-android /bin/bash

# Inside container:
cd /app
buildozer android debug

# APK created at: /app/bin/speechrecognition-1.0.0-debug.apk
```

---

## 💾 Step 5: APK Ready!

After build completes:
- APK location: `D:\Speech_Recognition\bin\speechrecognition-1.0.0-debug.apk`
- Size: ~100MB
- Ready to install on phone!

---

## 📱 Step 6: Install on Android Phone

```powershell
# Method 1: Via ADB (requires Android Platform Tools)
adb install D:\Speech_Recognition\bin\speechrecognition-1.0.0-debug.apk

# Method 2: Manual
# 1. Copy APK to phone via USB
# 2. Open file manager on phone
# 3. Tap APK to install
```

---

## ✅ Comparison: WSL2 vs Docker

| Aspect | WSL2 | Docker |
|--------|------|--------|
| Setup time | 30 min | 15 min |
| Build time | 3-5 min | 3-5 min |
| Disk space | 5GB | 3GB |
| Learning curve | Medium | Easy |
| Recommended | ✅ For regular builds | ✅ For quick builds |

---

## 🎯 Recommended Path

**Option A: One-Time APK Build (Easiest)**
1. Use Docker (this guide)
2. Build APK
3. Done!

**Option B: Regular Development (Best)**
1. Use WSL2 (more flexibility)
2. Iterate on builds
3. Release versions

---

**Status:** ✅ Ready to build APK from Windows
