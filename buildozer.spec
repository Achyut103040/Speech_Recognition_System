[app]

# (str) Title of your application
title = Speech Recognition Debug

# (str) Package name
package.name = speechrecognitiondebug

# (str) Package domain
package.domain = org.speechrec

# (source.dir) Source code where the main.py live
source.dir = .

# (source.include_exts) Source files to include
source.include_exts = py,png,jpg,kv,atlas,ttf,wav

# (source.exclude_exts) Source files to exclude
source.exclude_exts = spec

# (source.exclude_dirs) Exclude directories
source.exclude_dirs = tests, bin, venv, .venv

# (version) app version
version = 1.0.2

# Minimal requirements to isolate crash
requirements = python3,kivy,android,pyjnius

# (int) Target Android API
android.api = 33

# (int) Minimum API required
android.minapi = 21

# (int) Android NDK version to use
android.ndk = 25b

# (bool) Copy library instead of making a libpymodules.so
android.copy_libs = 1

# (str) The Android arch to build for
android.archs = arm64-v8a

# (bool) Enable AndroidX support
android.enable_androidx = True

# (list) Android permissions
android.permissions = INTERNET,RECORD_AUDIO,WRITE_EXTERNAL_STORAGE,READ_EXTERNAL_STORAGE,MANAGE_EXTERNAL_STORAGE

# (bool) Indicate if the application uses cleartext traffic
android.uses_cleartext_traffic = True

# (bool) Automatically accept Android SDK licenses
android.accept_sdk_license = True

# Force portrait mode to prevent landscape crash
android.orientation = portrait

# Prevent screen rotation crash
android.manifest_placeholders = android:configChanges="orientation|screenSize"

# Enable crash logging
android.logcat_filters = *:E python:D SpeechApp:D

# Presplash configuration
presplash.filename = %(source.dir)s/icon.png
icon.filename = %(source.dir)s/icon.png

# p4a options - CRITICAL: Skip pyjnius to avoid Python 2 'long' type errors
p4a.bootstrap = sdl2
p4a.hook = %(source.dir)s/hook.py

[buildozer]

# (int) Log level
log_level = 2

# (int) Display warning
warn_on_root = 1