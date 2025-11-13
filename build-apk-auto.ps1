# Automated APK Build Script for Docker + Kivy
# Usage: PowerShell -ExecutionPolicy Bypass -File build-apk-auto.ps1

param([switch]$SkipStop = $false)

$ErrorActionPreference = "Continue"

Write-Host "`n" -NoNewline
Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  AUTOMATED DOCKER APK BUILD                                               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# STEP 1: Stop hanging containers
Write-Host "`n[STEP 1] Stopping hanging Docker containers..." -ForegroundColor Green

if (-not $SkipStop) {
    $running = docker ps -q 2>$null
    if ($running) {
        Write-Host "Stopping containers..." -ForegroundColor Yellow
        $running | ForEach-Object { docker stop $_ --time=10 2>$null | Out-Null }
        Start-Sleep -Seconds 2
    } else {
        Write-Host "No running containers" -ForegroundColor Gray
    }
}

# STEP 2: Verify Docker
Write-Host "`n[STEP 2] Checking Docker installation..." -ForegroundColor Green
$dockerVersion = docker --version 2>$null
if (-not $dockerVersion) {
    Write-Host "ERROR: Docker not found!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ $dockerVersion" -ForegroundColor Green

# STEP 3: Check disk space
Write-Host "`n[STEP 3] Checking D: drive space..." -ForegroundColor Green
$drive = Get-PSDrive D -ErrorAction SilentlyContinue
if ($drive) {
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    Write-Host "   Free space: $freeGB GB" -ForegroundColor Yellow
    if ($freeGB -lt 25) {
        Write-Host "   WARNING: Less than 25GB free!" -ForegroundColor Red
    } else {
        Write-Host "   ✅ Sufficient space" -ForegroundColor Green
    }
}

# STEP 4: Verify build files
Write-Host "`n[STEP 4] Verifying build files..." -ForegroundColor Green
@("buildozer.spec", "main.py", "app.kv") | ForEach-Object {
    if (Test-Path "d:\Speech_Recognition\$_") {
        Write-Host "   ✅ $_" -ForegroundColor Green
    } else {
        Write-Host "   ERROR: $_ not found" -ForegroundColor Red
        exit 1
    }
}

# STEP 5: Pull Kivy image
Write-Host "`n[STEP 5] Pulling kivy/kivy:latest image..." -ForegroundColor Green
Write-Host "   (First time: 1-2GB download, 5-10 min)" -ForegroundColor Gray
docker pull kivy/kivy:latest 2>&1 | Select-Object -Last 5
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to pull image" -ForegroundColor Red
    exit 1
}

# STEP 6: Run build
Write-Host "`n[STEP 6] Starting Docker build..." -ForegroundColor Green
Write-Host "   Mount: D:\Speech_Recognition -> /app" -ForegroundColor Gray
Write-Host "   Time: 30-60 min (first time)" -ForegroundColor Gray
Write-Host "   " -NoNewline
Write-Host "═" * 76 -ForegroundColor Cyan
Write-Host ""

$buildScript = @"
set -e
apt-get update -qq
apt-get install -y openjdk-11-jdk wget unzip zip git build-essential python3-pip ca-certificates 2>&1 | tail -2
pip3 install --upgrade pip setuptools wheel cython buildozer 2>&1 | tail -2
echo ""
echo "===== STARTING BUILDOZER ====="
cd /app
buildozer -v android debug
echo "===== BUILD COMPLETED ====="
"@

docker run -it --rm `
  -v D:\Speech_Recognition:/app `
  --workdir /app `
  --memory 8g `
  kivy/kivy:latest `
  bash -c $buildScript

Write-Host ""
Write-Host "   " -NoNewline
Write-Host "═" * 76 -ForegroundColor Cyan

# STEP 7: Check result
Write-Host "`n[STEP 7] Checking for APK..." -ForegroundColor Green
$apkPath = "d:\Speech_Recognition\bin\speechrecognition-1.0.0-debug.apk"
if (Test-Path $apkPath) {
    $apkSize = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
    Write-Host "✅ APK CREATED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "   File: $apkPath" -ForegroundColor Yellow
    Write-Host "   Size: $apkSize MB" -ForegroundColor Yellow
} else {
    Write-Host "❌ APK not found - build failed" -ForegroundColor Red
}

# STEP 8: Next steps
Write-Host "`n[STEP 8] Next Steps" -ForegroundColor Green
Write-Host "   1. Connect Android phone via USB" -ForegroundColor Yellow
Write-Host "   2. Enable USB Debugging in Settings" -ForegroundColor Yellow
Write-Host "   3. Run: adb install '$apkPath'" -ForegroundColor Yellow
Write-Host "   4. Test all features on phone" -ForegroundColor Yellow

Write-Host "`n" -NoNewline
Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Build completed at $(Get-Date)  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
