# WSL2 Android APK Build Script for Windows
# This script sets up WSL2 Ubuntu and builds the APK
# Much faster than Docker for Windows users

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  WSL2 Android APK Build" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Step 1: Check if WSL2 is installed
Write-Host "`n[1/6] Checking WSL2..." -ForegroundColor Yellow
$wslVersion = wsl --version 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "WSL2 not found. Installing..." -ForegroundColor Red
    Write-Host "Run as Administrator: wsl --install" -ForegroundColor Yellow
    Write-Host "After install, restart Windows and run this script again." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "✓ WSL2 is installed" -ForegroundColor Green
}

# Step 2: Check if Ubuntu is installed
Write-Host "`n[2/6] Checking Ubuntu-22.04 in WSL2..." -ForegroundColor Yellow
$ubuntuCheck = wsl -l -v 2>$null | Select-String "Ubuntu-22.04"

if ($ubuntuCheck) {
    Write-Host "✓ Ubuntu-22.04 found" -ForegroundColor Green
} else {
    Write-Host "Ubuntu-22.04 not found. Installing..." -ForegroundColor Yellow
    wsl --install -d Ubuntu-22.04
    Write-Host "Ubuntu installed. Starting first boot..." -ForegroundColor Green
}

# Step 3: Copy project to WSL home directory
Write-Host "`n[3/6] Copying project to WSL filesystem..." -ForegroundColor Yellow
Write-Host "Source: D:\Speech_Recognition" -ForegroundColor Cyan
Write-Host "Target: \\wsl$\Ubuntu-22.04\home\build" -ForegroundColor Cyan

$wslPath = "\\wsl`$\Ubuntu-22.04\home"
if (-not (Test-Path $wslPath)) {
    Write-Host "✗ Cannot access WSL filesystem. Is WSL2 running?" -ForegroundColor Red
    exit 1
}

# Create build directory in WSL
wsl -d Ubuntu-22.04 mkdir -p /home/build
Write-Host "✓ WSL build directory ready" -ForegroundColor Green

# Copy files (use robocopy for reliability)
Write-Host "Copying files..." -ForegroundColor Cyan
robocopy "D:\Speech_Recognition" "$wslPath\build\speech_recognition" /S /E /XF "*.apk" "*.buildozer*" ".buildozer" 2>&1 | Out-Null

if ($LASTEXITCODE -le 1) {
    Write-Host "✓ Files copied successfully" -ForegroundColor Green
} else {
    Write-Host "Warning: robocopy exit code $LASTEXITCODE (may be OK)" -ForegroundColor Yellow
}

# Step 4: Install build dependencies in WSL
Write-Host "`n[4/6] Installing build dependencies in WSL..." -ForegroundColor Yellow
Write-Host "This may take 3-5 minutes..." -ForegroundColor Cyan

$setupScript = @"
#!/bin/bash
set -e

echo "Updating apt..."
apt-get update -qq

echo "Installing Java..."
apt-get install -y openjdk-11-jdk > /dev/null 2>&1

echo "Installing build tools..."
apt-get install -y python3-pip python3-dev build-essential git wget unzip zip > /dev/null 2>&1

echo "Upgrading pip..."
pip3 install --upgrade pip setuptools wheel cython > /dev/null 2>&1

echo "Installing buildozer..."
pip3 install buildozer > /dev/null 2>&1

echo "✓ Dependencies installed"
"@

$setupScript | wsl -d Ubuntu-22.04 bash

Write-Host "✓ Dependencies installed in WSL" -ForegroundColor Green

# Step 5: Build APK
Write-Host "`n[5/6] Starting APK build in WSL..." -ForegroundColor Yellow
Write-Host "This will take 20-30 minutes (first time)..." -ForegroundColor Cyan
Write-Host "Monitor progress with: wsl -d Ubuntu-22.04 tail -f /home/build/speech_recognition/.buildozer/android/platform/build.log" -ForegroundColor DarkGray

$buildScript = @"
#!/bin/bash
set -e
cd /home/build/speech_recognition
echo "Starting buildozer..."
buildozer -v android debug
"@

$buildScript | wsl -d Ubuntu-22.04 bash

Write-Host "✓ APK build completed!" -ForegroundColor Green

# Step 6: Copy APK back to Windows
Write-Host "`n[6/6] Copying APK back to Windows..." -ForegroundColor Yellow

$apkSource = "$wslPath\build\speech_recognition\bin"
if (Test-Path "$apkSource\*.apk") {
    Copy-Item "$apkSource\*.apk" "D:\Speech_Recognition\bin\" -Force
    Write-Host "✓ APK copied to D:\Speech_Recognition\bin\" -ForegroundColor Green
    Get-ChildItem "D:\Speech_Recognition\bin\*.apk" | ForEach-Object {
        Write-Host "  📦 $($_.Name) ($('{0:N2}' -f ($_.Length / 1MB)) MB)" -ForegroundColor Cyan
    }
} else {
    Write-Host "✗ APK not found in WSL. Build may have failed." -ForegroundColor Red
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  ✓ APK BUILD COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Connect Android phone via USB" -ForegroundColor Cyan
Write-Host "2. Enable USB Debugging (Settings > Developer Options)" -ForegroundColor Cyan
Write-Host "3. Run: adb install bin\speechrecognition-1.0.0-debug.apk" -ForegroundColor Cyan
Write-Host "4. Test on phone" -ForegroundColor Cyan
