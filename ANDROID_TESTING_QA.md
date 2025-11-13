# 🧪 Complete Android Testing & QA Guide

## 📋 Pre-Release Testing Checklist

### Phase 1: Installation Testing

**On Different Android Versions:**

- [ ] Android 7.0 (API 21) - Minimum supported
  - Device: Old phone/emulator
  - APK installs: Yes/No
  - App launches: Yes/No
  - Permissions granted: Yes/No

- [ ] Android 9-10 (API 28-29) - Common
  - Device: 2-3 year old phone
  - Status: ✅

- [ ] Android 12+ (API 31+) - Latest
  - Device: New phone
  - Status: ✅

### Phase 2: Functionality Testing

**Recording Feature:**

```
Test Case 1: Basic Recording
1. Tap "Record" button
   Expected: Recording screen opens
   Actual: [ ] Pass [ ] Fail

2. Set duration to 10 seconds
   Expected: Duration input accepts number
   Actual: [ ] Pass [ ] Fail

3. Grant microphone permission popup
   Expected: Permission request shown
   Actual: [ ] Pass [ ] Fail
   
4. Speak "Hello world, testing speech recognition"
   Expected: Recording indicator active
   Actual: [ ] Pass [ ] Fail

5. Wait for completion
   Expected: Recording stops automatically after 10s
   Actual: [ ] Pass [ ] Fail

6. File saved
   Expected: Audio file in storage
   Actual: [ ] Pass [ ] Fail
   Location: /sdcard/Android/data/org.speechrec/recordings/
```

**Upload Feature:**

```
Test Case 2: File Upload
1. Tap "Upload" button
   Expected: File picker opens
   Actual: [ ] Pass [ ] Fail

2. Select audio file
   Expected: File selected and shown
   Actual: [ ] Pass [ ] Fail

3. Confirm upload
   Expected: Upload completes
   Actual: [ ] Pass [ ] Fail

4. Verify file in app
   Expected: Uploaded file listed
   Actual: [ ] Pass [ ] Fail
```

**Transcription Feature:**

```
Test Case 3: Speech-to-Text
1. Tap "Transcribe" button
   Expected: Transcription interface opens
   Actual: [ ] Pass [ ] Fail

2. Select audio file
   Expected: File selected
   Actual: [ ] Pass [ ] Fail

3. Start transcription
   Expected: Processing indicator shows
   Actual: [ ] Pass [ ] Fail

4. Wait for completion
   Expected: Text output appears
   Actual: [ ] Pass [ ] Fail
   
5. Check accuracy
   Expected: Transcription matches spoken audio
   Actual: [ ] Pass [ ] Fail
   Accuracy: ___% (note percentage)
```

**Visualization Feature:**

```
Test Case 4: Waveform Display
1. Tap "Visualize" button
   Expected: Visualization menu opens
   Actual: [ ] Pass [ ] Fail

2. Select audio file
   Expected: File selected
   Actual: [ ] Pass [ ] Fail

3. Generate visualization
   Expected: Waveform graph displays
   Actual: [ ] Pass [ ] Fail

4. Check graph details
   Expected: Frequency/amplitude shown correctly
   Actual: [ ] Pass [ ] Fail
```

**Navigation:**

```
Test Case 5: Button Navigation
1. Each button opens correct screen
   Record: [ ] Pass
   Upload: [ ] Pass
   Transcribe: [ ] Pass
   Visualize: [ ] Pass
   Settings: [ ] Pass
   Exit: [ ] Pass

2. Back buttons return to home
   From Record: [ ] Pass
   From Upload: [ ] Pass
   From Transcribe: [ ] Pass
   From Visualize: [ ] Pass
   From Settings: [ ] Pass

3. Exit button closes app cleanly
   Expected: App closes, no crash
   Actual: [ ] Pass [ ] Fail
```

### Phase 3: Performance Testing

**Battery & Memory:**

```
Memory Usage:
- At startup: ___MB (should be <50MB)
- During recording: ___MB (should be <100MB)
- During transcription: ___MB (should be <200MB)

Battery drain (30 min use):
- Idle: ___% (should be <5%)
- Recording: ___% (should be <15%)
- Transcription: ___% (should be <20%)

Temperature:
- After 30 min: ___°C (should be <40°C)
```

**Storage:**

```
App Installation:
- Total size: ___MB (should be <150MB)
- Installable space needed: ___MB

Audio file storage:
- 1 min recording: ___MB
- 10 recordings: ___MB
- Total storage usage: ___MB
```

### Phase 4: Compatibility Testing

**Audio Devices:**

- [ ] Built-in microphone ✅
- [ ] Headset with mic ✅
- [ ] Bluetooth headset (if supported)
- [ ] External microphone

**Phone Types:**

- [ ] Phones (small screen) ✅
- [ ] Tablets (large screen) ✅
- [ ] Foldables (if applicable)
- [ ] Different manufacturers (Samsung, Google Pixel, etc.)

### Phase 5: Edge Cases & Stress Testing

**Boundary Tests:**

```
Recording Duration:
- Minimum (0s): [ ] Handled gracefully
- Maximum (60s): [ ] Works without crash
- Invalid input: [ ] Shows error

File Upload:
- Empty file (0 bytes): [ ] Error shown
- Large file (500MB): [ ] Shows error or warning
- Wrong format (.txt): [ ] Error shown
- Corrupted audio: [ ] Graceful handling

Concurrent Operations:
- Record + Upload: [ ] No crashes
- Multiple uploads: [ ] Queued properly
- Transcribe while recording: [ ] Prevented or handled
```

**Network Conditions (if using API):**

- [ ] WiFi connected
- [ ] Mobile data
- [ ] Weak signal
- [ ] Switching networks
- [ ] Airplane mode (offline features)

### Phase 6: UI/UX Testing

**Usability:**

```
Button Accessibility:
- Easy to tap on small screen: [ ] Yes [ ] No
- Buttons in logical order: [ ] Yes [ ] No
- Text readable: [ ] Yes [ ] No
- Icons clear: [ ] Yes [ ] No

Orientation:
- Portrait mode: [ ] Works
- Landscape mode: [ ] Works (if supported)
- Rotation handling: [ ] No crash

Permissions:
- First launch shows permissions: [ ] Yes
- Permission grant/deny handled: [ ] Yes
- Re-request if denied: [ ] Yes
```

### Phase 7: Security & Privacy

**Permission Handling:**

```
Microphone Access:
- Permission requested: [ ] Yes
- Permission can be revoked: [ ] Yes
- Behavior when denied: [ ] Graceful error

File Access:
- Reads only own files: [ ] Yes
- Cannot access other app data: [ ] Yes
- Storage permission respected: [ ] Yes

Network Security:
- Uses HTTPS if API calls: [ ] Yes
- No sensitive data in logs: [ ] Yes
- No hardcoded API keys: [ ] Yes
```

---

## 🔧 Testing Tools

### ADB Commands for Testing

```bash
# View live logs
adb logcat

# Filter for app errors
adb logcat | grep speechrecognition

# Check permissions
adb shell pm list permissions -g

# Grant permission manually
adb shell pm grant org.speechrec android.permission.RECORD_AUDIO

# Monitor memory
adb shell dumpsys meminfo org.speechrec

# Check battery
adb shell dumpsys batterymanager

# Take screenshot
adb shell screencap /sdcard/screenshot.png
adb pull /sdcard/screenshot.png

# Record screen
adb shell screenrecord /sdcard/video.mp4
adb pull /sdcard/video.mp4
```

### Android Emulator (Testing without physical phone)

```bash
# Download Android Studio (includes emulator)
# Create virtual device: Settings > Virtual Device Manager
# Launch emulator
emulator -avd Pixel_5_API_31

# Install APK on emulator
adb install bin/speechrecognition-1.0.0-debug.apk

# Same commands work for emulator
```

---

## 📊 Test Results Template

```
APP VERSION: 1.0.0
TEST DATE: 2025-11-11
TESTER: ___________

DEVICE INFO:
  Manufacturer: ___________
  Model: ___________
  Android Version: ___________
  RAM: ___________
  Storage: ___________

TEST RESULTS:

Installation:           [ ] PASS [ ] FAIL
Recording:              [ ] PASS [ ] FAIL
Upload:                 [ ] PASS [ ] FAIL
Transcription:          [ ] PASS [ ] FAIL
Visualization:          [ ] PASS [ ] FAIL
Navigation:             [ ] PASS [ ] FAIL
Performance:            [ ] PASS [ ] FAIL
Permissions:            [ ] PASS [ ] FAIL
Battery Life:           [ ] PASS [ ] FAIL
Storage Usage:          [ ] PASS [ ] FAIL

OVERALL RATING:
  UI/UX:                 ⭐⭐⭐⭐⭐ (1-5)
  Performance:           ⭐⭐⭐⭐⭐ (1-5)
  Stability:             ⭐⭐⭐⭐⭐ (1-5)
  Battery Usage:         ⭐⭐⭐⭐⭐ (1-5)

ISSUES FOUND:
1. _________________________________
2. _________________________________
3. _________________________________

RECOMMENDATIONS:
1. _________________________________
2. _________________________________

APPROVED FOR RELEASE: [ ] YES [ ] NO

Tester Signature: ________________
```

---

## 🐛 Bug Reporting Template

When you find a bug:

```
BUG TITLE: [Short description]

SEVERITY: [ ] Critical [ ] High [ ] Medium [ ] Low

REPRODUCTION STEPS:
1. ___________
2. ___________
3. ___________

EXPECTED RESULT:
___________

ACTUAL RESULT:
___________

DEVICE INFO:
- Phone: ___________
- Android: ___________
- App Version: ___________

LOGS:
[Copy relevant error from: adb logcat]

SCREENSHOT/VIDEO:
[Attach if possible]
```

---

## ✅ Go/No-Go Checklist for Release

Before uploading to Google Play Store:

- [ ] App runs without crashes on Android 7-14
- [ ] All 6 buttons functional
- [ ] Recording works with real microphone
- [ ] Transcription produces correct output
- [ ] Storage usage reasonable (<150MB APK)
- [ ] Battery drain acceptable
- [ ] Permissions properly requested
- [ ] No sensitive data exposed
- [ ] Icons and screenshots ready
- [ ] Privacy policy written
- [ ] App description ready
- [ ] Version bumped (1.0.0)
- [ ] Release notes prepared
- [ ] Tested on at least 2 real devices
- [ ] All known issues documented or fixed

---

## 📈 Analytics to Track

After release:

```
Daily Active Users (DAU)
Weekly Active Users (WAU)
Crash Rate
Session Duration
Feature Usage:
  - Record usage: ___%
  - Upload usage: ___%
  - Transcribe usage: ___%
  - Visualize usage: ___%
User Reviews (rating)
Retention Rate (Day 1, Day 7, Day 30)
```

---

**Status:** ✅ Ready for comprehensive testing
**Next:** Run through all test cases before release
