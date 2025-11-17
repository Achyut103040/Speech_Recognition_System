"""
Custom p4a hook to patch pyjnius for Python 3 compatibility.
This runs automatically during buildozer build process.
"""
import os
import glob

def patch_pyjnius_files():
    """Patch all pyjnius_utils.pxi files for Python 3"""
    # Find build directory
    patterns = [
        "/home/*/speech_recognition/.buildozer/android/platform/build-*/build/other_builds/pyjnius*/*/pyjnius/jnius/jnius_utils.pxi",
        "/home/*/.buildozer/android/platform/build-*/build/other_builds/pyjnius*/*/pyjnius/jnius/jnius_utils.pxi",
    ]
    
    for pattern in patterns:
        for filepath in glob.glob(pattern):
            if os.path.exists(filepath):
                with open(filepath, 'r') as f:
                    content = f.read()
                
                if 'isinstance(arg, long)' in content:
                    fixed = content.replace('isinstance(arg, long)', 'isinstance(arg, int)')
                    with open(filepath, 'w') as f:
                        f.write(fixed)
                    print(f"[HOOK] ✅ Patched pyjnius for Python 3: {filepath}")

# Run patch when hook is loaded
patch_pyjnius_files()

def before_apk_build(toolchain_ctx):
    """Fix Gradle compatibility before APK build"""
    import re
    from pythonforandroid.logger import info
    
    info("Hook: Fixing Gradle compatibility...")
    
    # Get the current working directory which is the dist directory
    dist_dir = os.getcwd()
    info(f"Hook: Current directory: {dist_dir}")
    build_gradle = os.path.join(dist_dir, 'build.gradle')
    info(f"Hook: Looking for: {build_gradle}")
    
    if os.path.exists(build_gradle):
        info(f"Hook: File exists, reading...")
        with open(build_gradle, 'r') as f:
            content = f.read()
        
        original_length = len(content)
        info(f"Hook: Original length: {original_length}")
        
        # Fix Gradle plugin version
        old_content = content
        content = content.replace(
            "classpath 'com.android.tools.build:gradle:8.1.1'",
            "classpath 'com.android.tools.build:gradle:7.4.2'"
        )
        if content != old_content:
            info("Hook: Replaced Gradle version 8.1.1 -> 7.4.2")
        else:
            info("Hook: WARNING - Gradle version not replaced!")
        
        # Remove namespace line completely
        old_content = content
        content = re.sub(r'    namespace [\'\"].*?[\'\"]\n', '', content)
        if content != old_content:
            info("Hook: Removed namespace line")
        else:
            info("Hook: WARNING - namespace not removed!")
        
        # Replace jcenter with mavenCentral
        old_content = content
        content = content.replace('jcenter()', 'mavenCentral()')
        if content != old_content:
            info("Hook: Replaced jcenter() -> mavenCentral()")
        else:
            info("Hook: WARNING - jcenter() not replaced!")
        
        new_length = len(content)
        info(f"Hook: New length: {new_length}, changed: {new_length != original_length}")
        
        with open(build_gradle, 'w') as f:
            f.write(content)
        
        info("Hook: Written build.gradle")
        
        # Verify the changes
        with open(build_gradle, 'r') as f:
            verify = f.read()
        if '7.4.2' in verify:
            info("Hook: VERIFIED - 7.4.2 found in file")
        else:
            info("Hook: ERROR - 7.4.2 NOT in file after write!")
    else:
        info(f"Hook: build.gradle not found at {build_gradle}")

def before_apk_assemble(toolchain_ctx):
    """Fix Gradle compatibility immediately before assembleDebug"""
    import re
    from pythonforandroid.logger import info
    
    info("Hook: before_apk_assemble - Fixing Gradle compatibility...")
    
    # Get the current working directory which is the dist directory
    dist_dir = os.getcwd()
    info(f"Hook: Current directory: {dist_dir}")
    build_gradle = os.path.join(dist_dir, 'build.gradle')
    info(f"Hook: Looking for: {build_gradle}")
    
    # Fix gradle wrapper version
    gradle_wrapper_props = os.path.join(dist_dir, 'gradle', 'wrapper', 'gradle-wrapper.properties')
    if os.path.exists(gradle_wrapper_props):
        with open(gradle_wrapper_props, 'r') as f:
            wrapper_content = f.read()
        wrapper_content = wrapper_content.replace('gradle-8.0.2-all.zip', 'gradle-6.9-all.zip')
        wrapper_content = wrapper_content.replace('gradle-8.1', 'gradle-6.9')
        wrapper_content = wrapper_content.replace('gradle-7.6', 'gradle-6.9')
        with open(gradle_wrapper_props, 'w') as f:
            f.write(wrapper_content)
        info("Hook: Fixed gradle wrapper to 7.6")
    
    if os.path.exists(build_gradle):
        info(f"Hook: File exists, reading...")
        with open(build_gradle, 'r') as f:
            content = f.read()
        
        original_length = len(content)
        info(f"Hook: Original length: {original_length}")
        
        # Fix Gradle plugin version
        old_content = content
        content = content.replace(
            "classpath 'com.android.tools.build:gradle:8.1.1'",
            "classpath 'com.android.tools.build:gradle:7.4.2'"
        )
        if content != old_content:
            info("Hook: Replaced Gradle version 8.1.1 -> 7.4.2")
        else:
            info("Hook: WARNING - Gradle version not replaced!")
        
        # Remove namespace line completely
        old_content = content
        content = re.sub(r'    namespace [\'\"].*?[\'\"]\n', '', content)
        if content != old_content:
            info("Hook: Removed namespace line")
        else:
            info("Hook: WARNING - namespace not removed!")
        
        # Replace jcenter with mavenCentral
        old_content = content
        content = content.replace('jcenter()', 'mavenCentral()')
        if content != old_content:
            info("Hook: Replaced jcenter() -> mavenCentral()")
        else:
            info("Hook: WARNING - jcenter() not replaced!")
        
        new_length = len(content)
        info(f"Hook: New length: {new_length}, changed: {new_length != original_length}")
        
        with open(build_gradle, 'w') as f:
            f.write(content)
        
        info("Hook: Written build.gradle in before_apk_assemble")
        
        # Verify the changes
        with open(build_gradle, 'r') as f:
            verify = f.read()
        if '7.4.2' in verify:
            info("Hook: VERIFIED - 7.4.2 found in file")
        else:
            info("Hook: ERROR - 7.4.2 NOT in file after write!")
    else:
        info(f"Hook: build.gradle not found at {build_gradle}")

def after_apk_build(toolchain_ctx):
    from pythonforandroid.logger import info
    info("Hook: after_apk_build")
