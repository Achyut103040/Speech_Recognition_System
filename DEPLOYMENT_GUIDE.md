# 🚀 Speech Recognition App - Multi-Platform Deployment Guide

## ✅ Current Status
- **App**: Fully functional on Windows
- **All buttons**: Working (Record, Upload, Visualize, Transcribe, Settings, Exit)
- **Layout**: Fixed (all 6 buttons visible)
- **Ready for**: Testing and multi-platform deployment

---

## 📋 Table of Contents
1. [Desktop Deployment (Windows/Mac/Linux)](#desktop)
2. [Android Deployment](#android)
3. [Web Deployment (Browser)](#web)
4. [Docker Deployment](#docker)
5. [Cloud Deployment](#cloud)
6. [Troubleshooting](#troubleshooting)

---

## 🖥️ Desktop Deployment (Windows/Mac/Linux) {#desktop}

### 1. **Windows**

**Current Setup** ✅

```bash
# Install dependencies
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt

# Run the app
python main.py
```

**Package as Executable (.exe)**

```bash
# Install PyInstaller
pip install pyinstaller

# Create executable
pyinstaller --onefile --windowed --icon=app_icon.ico main.py

# Find executable in: dist/main.exe
```

---

### 2. **macOS**

**Install Python**
```bash
# Using Homebrew
brew install python3

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Run the app
python3 main.py
```

**Package as .app**
```bash
pip install py2app

# Create setup.py for macOS packaging
```

---

### 3. **Linux (Ubuntu/Debian)**

**Install Dependencies**
```bash
# Audio libraries
sudo apt-get install python3 python3-pip python3-dev
sudo apt-get install libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev
sudo apt-get install libportmidi-dev libswscale-dev libavformat-dev libavcodec-dev zlib1g-dev

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Run the app
python3 main.py
```

---

## 📱 Android Deployment {#android}

### **Method 1: Kivy to APK (Recommended for your app)**

**Step 1: Install Buildozer**
```bash
pip install buildozer cython

# On Windows, install Java and Android SDK first
# https://github.com/kivy/buildozer/wiki/Android
```

**Step 2: Create buildozer.spec**
```ini
[app]
title = Speech Recognition
package.name = speechrecognition
package.domain = org.speechrec

source.dir = .
source.include_exts = py,png,jpg,kv,atlas,ttf

version = 1.0.0

requirements = python3,kivy,vosk,numpy,matplotlib,requests,sounddevice,soundfile,fastapi,uvicorn

orientation = portrait
fullscreen = 0
icon.filename = %(source.dir)s/data/icon.png
presplash.filename = %(source.dir)s/data/presplash.png

# Android permissions
android.permissions = RECORD_AUDIO,INTERNET,READ_EXTERNAL_STORAGE,WRITE_EXTERNAL_STORAGE
android.api = 31
android.minapi = 21
android.ndk = 25c
android.accept_sdk_license = True

# Services
android.services = org.speechrec.VoskService
```

**Step 3: Build APK**
```bash
# Debug build (fast)
buildozer android debug

# Release build (optimized)
buildozer android release

# Find APK in: bin/speechrecognition-1.0.0-debug.apk
```

**Step 4: Install on Android Device**
```bash
# Connect device via USB
adb install bin/speechrecognition-1.0.0-debug.apk

# Or manually copy .apk to phone and install
```

---

### **Method 2: BeeWare (Alternative)**

```bash
pip install briefcase

# Initialize project
briefcase new

# Build for Android
briefcase build android
briefcase run android
```

---

### **Android Specific Considerations**

**Audio Recording on Android:**
- The `android_audio.py` file handles Android-specific audio
- Permissions needed: `RECORD_AUDIO`, `WRITE_EXTERNAL_STORAGE`
- Audio stored in: `/sdcard/Android/data/org.speechrec/files/recordings/`

**Update android_audio.py:**
```python
from kivy.core.window import Window
from android.permissions import request_permissions, Permission, check_permission

# Request permissions on startup
request_permissions([
    Permission.RECORD_AUDIO,
    Permission.READ_EXTERNAL_STORAGE,
    Permission.WRITE_EXTERNAL_STORAGE
])

# Audio storage path for Android
AUDIO_DIR = "/sdcard/Android/data/org.speechrec/files/recordings/"
```

---

## 🌐 Web Deployment (Browser) {#web}

### **Option 1: Kivy JS (Pyodide + Tornado)**

```bash
pip install kivy tornado pyscript

# Create web server
```

**server_web.py:**
```python
from tornado.web import Application, RequestHandler
from tornado.ioloop import IOLoop
import asyncio

class AppHandler(RequestHandler):
    def get(self):
        self.write(open('index.html').read())

if __name__ == '__main__':
    app = Application([
        (r"/", AppHandler),
    ])
    app.listen(8080)
    print("Server running on http://localhost:8080")
    IOLoop.current().start()
```

---

### **Option 2: FastAPI Web Interface**

Already have `server.py` with FastAPI! Extend it:

```python
from fastapi import FastAPI, File, UploadFile
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import shutil

app = FastAPI()

# Serve static files (HTML/CSS/JS)
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.post("/api/upload-audio/")
async def upload_audio(file: UploadFile = File(...)):
    """Upload audio file for transcription"""
    with open(f"uploads/{file.filename}", "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    return {"filename": file.filename}

@app.post("/api/transcribe/")
async def transcribe(file: UploadFile = File(...)):
    """Transcribe uploaded audio"""
    audio_path = f"uploads/{file.filename}"
    with open(audio_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    from transcribe import transcribe_audio
    result = transcribe_audio(audio_path)
    return {"transcription": result}

@app.get("/api/visualizations/")
async def get_visualizations():
    """Get list of available visualizations"""
    import os
    return {"files": os.listdir("visualizations/")}
```

**Create static/index.html:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Speech Recognition</title>
    <link rel="stylesheet" href="/static/style.css">
</head>
<body>
    <div class="container">
        <h1>Speech Recognition</h1>
        
        <div class="controls">
            <button id="recordBtn">Record Audio</button>
            <button id="uploadBtn">Upload Audio</button>
            <button id="transcribeBtn">Transcribe</button>
            <button id="visualizeBtn">Visualize</button>
        </div>
        
        <div id="results"></div>
    </div>
    
    <script src="/static/app.js"></script>
</body>
</html>
```

**Run web server:**
```bash
uvicorn server:app --host 0.0.0.0 --port 8000 --reload
```

Access at: `http://localhost:8000`

---

## 🐳 Docker Deployment {#docker}

### **Create Dockerfile**

```dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libsdl2-dev \
    libsdl2-image-dev \
    libsdl2-mixer-dev \
    libsdl2-ttf-dev \
    libportmidi-dev \
    libswscale-dev \
    libavformat-dev \
    libavcodec-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app files
COPY . .

# Download Vosk model
RUN python model_downloader.py

# Expose port for FastAPI server
EXPOSE 8000

# Run app
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Build and Run:**
```bash
# Build Docker image
docker build -t speech-recognition .

# Run container
docker run -p 8000:8000 -v ~/recordings:/app/recordings speech-recognition

# Access at: http://localhost:8000
```

---

## ☁️ Cloud Deployment {#cloud}

### **1. Heroku**

```bash
# Install Heroku CLI
# https://devcenter.heroku.com/articles/heroku-cli

# Login
heroku login

# Create app
heroku create my-speech-recognition-app

# Deploy
git push heroku main

# View logs
heroku logs --tail
```

---

### **2. AWS Lambda + API Gateway**

```python
# lambda_handler.py
from transcribe import transcribe_audio
import json

def lambda_handler(event, context):
    """AWS Lambda handler for transcription"""
    
    # Get audio file from S3
    bucket = event['bucket']
    key = event['key']
    
    # Transcribe
    result = transcribe_audio(f"s3://{bucket}/{key}")
    
    return {
        'statusCode': 200,
        'body': json.dumps({'transcription': result})
    }
```

---

### **3. Google Cloud Run**

```bash
# Create app.yaml
runtime: python312
env: standard
entrypoint: uvicorn server:app --host 0.0.0.0 --port 8080

# Deploy
gcloud run deploy speech-recognition --source .
```

---

### **4. Microsoft Azure**

```bash
# Install Azure CLI
# https://docs.microsoft.com/en-us/cli/azure/

# Create resource group
az group create --name speechrec-rg --location eastus

# Create app service
az appservice plan create --name speechrec-plan --resource-group speechrec-rg --sku FREE

# Deploy
az webapp create --resource-group speechrec-rg --plan speechrec-plan --name speechrec-app

# Push code
git push azure main
```

---

## 🔧 Troubleshooting {#troubleshooting}

### **Issue: Audio not recording on Android**
```python
# Solution: Check permissions in buildozer.spec
android.permissions = RECORD_AUDIO,WRITE_EXTERNAL_STORAGE

# Request permissions at runtime
from android.permissions import request_permissions, Permission
request_permissions([Permission.RECORD_AUDIO])
```

---

### **Issue: Vosk model too large for mobile**
```python
# Use smaller model or online transcription
# Option 1: Smaller Vosk model
# vosk-model-small-en-us-0.15

# Option 2: Online service (Google Speech-to-Text, AWS Transcribe)
```

---

### **Issue: App crashes on startup (Android)**
```python
# Add error handling
try:
    from vosk import Model, KaldiRecognizer
except ImportError:
    # Use offline mode
    Model = None
```

---

## 📦 Requirements.txt

```
kivy==2.3.1
vosk==0.3.45
sounddevice==0.4.5
soundfile==0.12.1
numpy==1.24.3
matplotlib==3.8.0
requests==2.31.0
fastapi==0.100.0
uvicorn==0.23.0
python-multipart==0.0.6
```

---

## 🚀 Quick Start Checklist

- [ ] Clean install on Windows: `python main.py`
- [ ] Test all 6 buttons (Record, Upload, Visualize, Transcribe, Settings, Exit)
- [ ] Download Vosk model: `python model_downloader.py`
- [ ] Test recording functionality
- [ ] Test transcription
- [ ] Package for Windows: `pyinstaller`
- [ ] Build Android APK: `buildozer android debug`
- [ ] Deploy web version: `uvicorn server:app`
- [ ] Test on target platform

---

## 📞 Platform-Specific Tips

| Platform | Best For | Notes |
|----------|----------|-------|
| **Windows** | Desktop users | Single file .exe executable |
| **macOS** | Mac users | Requires macOS SDK |
| **Linux** | Server/Linux users | Good for Docker |
| **Android** | Mobile users | 50% reduction needed for APK size |
| **Web** | Browser access | FastAPI server good option |
| **Docker** | Containerization | Consistent across platforms |
| **Cloud** | Scalability | AWS/Azure/GCP options available |

---

## 🎯 Recommended Deployment Path

### **Phase 1: Windows Desktop** ✅ DONE
- Buildable executable (.exe)
- Full feature testing

### **Phase 2: Android Mobile** 🔜 NEXT
- Buildozer APK creation
- Audio recording testing

### **Phase 3: Web Browser** 🔄 OPTIONAL
- FastAPI + HTML interface
- No installation needed

### **Phase 4: Cloud** ☁️ FUTURE
- Docker containerization
- Heroku/AWS/Azure deployment
- Scalable backend

---

**Created**: 2025-11-11
**Last Updated**: 2025-11-11
**Status**: Ready for Multi-Platform Deployment
