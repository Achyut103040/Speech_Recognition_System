@echo off
cls
echo ================================================================
echo       Speech Recognition APK Builder for Android
echo ================================================================
echo.
echo This script will:
echo   1. Run initial buildozer build (will fail at pyjnius)
echo   2. Automatically patch pyjnius files
echo   3. Rebuild APK (should succeed)
echo   4. Copy APK to Windows
echo.
echo Estimated time: 15-25 minutes
echo.
pause
echo.

echo ================================================================
echo STEP 1: Running initial build in WSL...
echo ================================================================
echo.
echo Note: Build will fail with pyjnius error - this is EXPECTED!
echo.

wsl -d Ubuntu-22.04 bash -c "export PATH='/usr/bin:/bin:/usr/sbin:/sbin:$PATH' && cd ~/speech_recognition && buildozer android debug 2>&1 | tee /tmp/build_step1.log"

echo.
echo ================================================================
echo STEP 2: Patching pyjnius for Python 3 compatibility...
echo ================================================================
echo.

wsl -d Ubuntu-22.04 bash -c "export PATH='/usr/bin:/bin:/usr/sbin:/sbin:$PATH' && cd ~/speech_recognition && python3 fix_pyjnius.py"

if errorlevel 1 (
    echo.
    echo ERROR: Pyjnius patching failed!
    echo Check that buildozer created the pyjnius files.
    echo.
    pause
    exit /b 1
)

echo.
echo ================================================================
echo STEP 3: Rebuilding APK with patched pyjnius...
echo ================================================================
echo.

wsl -d Ubuntu-22.04 bash -c "export PATH='/usr/bin:/bin:/usr/sbin:/sbin:$PATH' && cd ~/speech_recognition && buildozer android debug"

if errorlevel 1 (
    echo.
    echo ERROR: Build failed even after patching!
    echo Check WSL terminal for error details.
    echo.
    pause
    exit /b 1
)

echo.
echo ================================================================
echo STEP 4: Copying APK to Windows...
echo ================================================================
echo.

wsl -d Ubuntu-22.04 bash -c "export PATH='/usr/bin:/bin:/usr/sbin:/sbin:$PATH' && cd ~/speech_recognition && mkdir -p /mnt/d/Speech_Recognition/bin && cp -v bin/*.apk /mnt/d/Speech_Recognition/bin/"

echo.
echo ================================================================
echo BUILD COMPLETE!
echo ================================================================
echo.

if exist "D:\Speech_Recognition\bin\*.apk" (
    echo SUCCESS! APK created:
    dir /b D:\Speech_Recognition\bin\*.apk
    for %%F in (D:\Speech_Recognition\bin\*.apk) do echo Size: %%~zF bytes
    echo.
    echo Location: D:\Speech_Recognition\bin\
    echo.
    echo NEXT STEPS:
    echo 1. Transfer APK to your Android phone
    echo 2. Install the APK
    echo 3. Grant microphone and storage permissions
    echo 4. Test the app!
    echo.
) else (
    echo ERROR: APK file not found in D:\Speech_Recognition\bin\
    echo Check the build output above for errors.
    echo.
)

pause
