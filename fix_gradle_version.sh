#!/bin/bash
# Fix build.gradle for older Gradle compatibility

GRADLE_FILE=".buildozer/android/platform/build-arm64-v8a/dists/speechrecognitiondebug/build.gradle"

if [ ! -f "$GRADLE_FILE" ]; then
    echo "Error: build.gradle not found"
    exit 1
fi

# Change Gradle plugin version from 8.1.1 to 7.4.2
sed -i "s/classpath 'com.android.tools.build:gradle:8.1.1'/classpath 'com.android.tools.build:gradle:7.4.2'/g" "$GRADLE_FILE"

# Remove namespace if present
sed -i '/namespace/d' "$GRADLE_FILE"

# Change jcenter to mavenCentral
sed -i 's/jcenter()/mavenCentral()/g' "$GRADLE_FILE"

echo "Fixed build.gradle with:"
echo "- Gradle plugin 7.4.2"
echo "- mavenCentral instead of jcenter"
echo "- namespace removed"

head -30 "$GRADLE_FILE"
