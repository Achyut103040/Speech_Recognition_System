@echo off
REM Automated Docker APK Build Script
REM Usage: build-apk.bat

setlocal enabledelayedexpansion

echo.
echo ============================================================================
echo AUTOMATED DOCKER APK BUILD
echo ============================================================================
echo.

echo [STEP 1] Stopping hanging Docker containers...
for /f "tokens=*" %%i in ('docker ps -q 2^>nul') do (
    echo Stopping container %%i
    docker stop %%i --time=10 >nul 2>&1
)

echo.
echo [STEP 2] Checking Docker installation...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker not found!
    exit /b 1
)
docker --version
echo.

echo [STEP 3] Checking D: drive space...
for /f "tokens=*" %%i in ('powershell -Command "Get-PSDrive D | Select-Object -ExpandProperty Free"') do (
    echo Free space: %%i bytes
)
echo.

echo [STEP 4] Verifying build files...
if not exist "d:\Speech_Recognition\buildozer.spec" (
    echo ERROR: buildozer.spec not found
    exit /b 1
)
if not exist "d:\Speech_Recognition\main.py" (
    echo ERROR: main.py not found
    exit /b 1
)
if not exist "d:\Speech_Recognition\app.kv" (
    echo ERROR: app.kv not found
    exit /b 1
)
echo OK: All required files present
echo.

echo [STEP 5] Pulling Kivy image...
docker pull kivy/kivy:latest
if errorlevel 1 (
    echo ERROR: Failed to pull image
    exit /b 1
)
echo.

echo [STEP 6] Starting Docker build (30-60 minutes)...
echo ============================================================================
cd /d d:\Speech_Recognition
docker run -it --rm -v D:\Speech_Recognition:/app --workdir /app --memory 8g kivy/kivy:latest bash -c "apt-get update -qq && apt-get install -y openjdk-11-jdk wget unzip zip git build-essential python3-pip ca-certificates 2>&1 | tail -2 && pip3 install --upgrade pip setuptools wheel cython buildozer 2>&1 | tail -2 && echo ===== STARTING BUILDOZER ===== && buildozer -v android debug && echo ===== BUILD COMPLETED ====="
echo ============================================================================
echo.

echo [STEP 7] Checking for APK...
if exist "d:\Speech_Recognition\bin\speechrecognition-1.0.0-debug.apk" (
    echo APK created successfully!
    dir "d:\Speech_Recognition\bin\speechrecognition-1.0.0-debug.apk"
    echo.
    echo Next steps:
    echo 1. Connect Android phone via USB
    echo 2. Enable USB Debugging in phone Settings
    echo 3. Run: adb install "d:\Speech_Recognition\bin\speechrecognition-1.0.0-debug.apk"
    echo 4. Test all features on phone
) else (
    echo ERROR: APK not found - build may have failed
)
echo.
echo Build completed!
echo.
pause
