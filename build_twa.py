#!/usr/bin/env python3
"""
Build Trusted Web Activity (TWA) for Google Play Store
This wraps your web app in a native Android container
"""

import os
import subprocess
import json

def create_twa_project():
    """Create TWA project using Bubblewrap"""
    
    print("🌐 Creating TWA (Trusted Web Activity) for Google Play Store...")
    print("=" * 60)
    
    # Install bubblewrap CLI
    print("\n📦 Installing Bubblewrap CLI...")
    subprocess.run(['npm', 'install', '-g', '@bubblewrap/cli'], check=False)
    
    # Initialize TWA project
    print("\n🎯 Initializing TWA project...")
    
    config = {
        "webManifestUrl": "https://YOUR_DOMAIN.com/manifest.json",
        "host": "YOUR_DOMAIN.com",
        "name": "Speech Recognition",
        "launcherName": "SpeechRec",
        "display": "standalone",
        "themeColor": "#1976D2",
        "backgroundColor": "#2196F3",
        "startUrl": "/",
        "iconUrl": "https://YOUR_DOMAIN.com/static/icon-512.png",
        "maskableIconUrl": "https://YOUR_DOMAIN.com/static/icon-512.png",
        "shortcuts": [],
        "signingKey": {
            "path": "./android.keystore",
            "alias": "android"
        },
        "appVersionName": "1.0.0",
        "appVersionCode": 1,
        "enableNotifications": False,
        "isChromeOSOnly": False,
        "fallbackType": "customtabs",
        "features": {
            "locationDelegation": {
                "enabled": False
            }
        },
        "alphaDependencies": {
            "enabled": False
        },
        "minSdkVersion": 21,
        "packageId": "org.speechrec.speechrecognition"
    }
    
    # Save config
    with open('twa-manifest.json', 'w') as f:
        json.dump(config, f, indent=2)
    
    print("\n✅ TWA configuration created!")
    print("\n📝 Next steps:")
    print("1. Deploy your web app to a domain (e.g., speechrec.com)")
    print("2. Update twa-manifest.json with your domain")
    print("3. Generate signing key: bubblewrap keytool")
    print("4. Build TWA: bubblewrap build")
    print("5. Upload to Google Play Console")
    
    print("\n🔑 Generate signing key:")
    print("   bubblewrap keytool")
    
    print("\n🔨 Build TWA APK:")
    print("   bubblewrap build")
    
    print("\n📱 Test TWA:")
    print("   bubblewrap install")
    
    print("\n🚀 Upload to Play Store:")
    print("   1. Create app at play.google.com/console")
    print("   2. Upload APK from app-release-signed.apk")
    print("   3. Add assetlinks.json to /.well-known/assetlinks.json on your domain")

if __name__ == '__main__':
    create_twa_project()
