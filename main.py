"""
Speech Recognition App - Crash-Safe Version
"""
import sys
import traceback
from io import StringIO

# Capture all errors to a log file
class ErrorLogger:
    def __init__(self):
        self.log_file = '/sdcard/speechapp_crash.log'
        self.original_stderr = sys.stderr
        
    def write_error(self, msg):
        try:
            with open(self.log_file, 'a') as f:
                f.write(msg + '\n')
        except:
            pass
        self.original_stderr.write(msg)
        
    def log_exception(self, exc_type, exc_value, exc_traceback):
        error_msg = ''.join(traceback.format_exception(exc_type, exc_value, exc_traceback))
        self.write_error(f"\n{'='*50}\nFATAL ERROR:\n{'='*50}\n{error_msg}")

# Install error logger immediately
error_logger = ErrorLogger()
sys.excepthook = error_logger.log_exception

try:
    error_logger.write_error("=" * 50)
    error_logger.write_error("App Starting...")
    error_logger.write_error(f"Python Version: {sys.version}")
    error_logger.write_error(f"Platform: {sys.platform}")
    
    # Import Kivy with error handling
    error_logger.write_error("Importing Kivy...")
    from kivy.app import App
    from kivy.uix.screenmanager import ScreenManager, Screen
    from kivy.uix.boxlayout import BoxLayout
    from kivy.uix.button import Button
    from kivy.uix.label import Label
    from kivy.lang import Builder
    from kivy.utils import platform
    from kivy.logger import Logger
    from kivy.clock import Clock
    from kivy.config import Config
    
    error_logger.write_error("Kivy imported successfully")
    
    # Force portrait mode to prevent landscape crash
    #Config.set('graphics', 'orientation', 'portrait')
    
    # Try to import Android-specific modules
    if platform == 'android':
        error_logger.write_error("Importing Android modules...")
        try:
            from android.permissions import request_permissions, Permission, check_permission
            from android.runnable import run_on_ui_thread
            from jnius import autoclass
            
            PythonActivity = autoclass('org.kivy.android.PythonActivity')
            error_logger.write_error("Android modules imported successfully")
            ANDROID_AVAILABLE = True
        except Exception as e:
            error_logger.write_error(f"Android import failed: {e}")
            ANDROID_AVAILABLE = False
    else:
        ANDROID_AVAILABLE = False
        error_logger.write_error("Not on Android platform")
    
    # Simplified KV layout (no external file)
    KV = '''
ScreenManager:
    id: screen_manager
    
    Screen:
        name: 'main'
        BoxLayout:
            orientation: 'vertical'
            padding: 20
            spacing: 10
            
            Label:
                id: status_label
                text: 'Speech Recognition Ready'
                size_hint: (1, 0.2)
                font_size: '18sp'
                color: (1, 1, 1, 1)
            
            Button:
                text: '🎤 Record Audio'
                size_hint: (1, 0.15)
                on_press: app.test_feature('record')
                background_color: (0.2, 0.6, 0.8, 1)
            
            Button:
                text: '📁 Upload Audio'
                size_hint: (1, 0.15)
                on_press: app.test_feature('upload')
                background_color: (0.4, 0.7, 0.4, 1)
            
            Button:
                text: '📝 Transcribe'
                size_hint: (1, 0.15)
                on_press: app.test_feature('transcribe')
                background_color: (0.8, 0.6, 0.2, 1)
            
            Button:
                text: '📊 Visualize'
                size_hint: (1, 0.15)
                on_press: app.test_feature('visualize')
                background_color: (0.6, 0.4, 0.8, 1)
            
            Button:
                text: '📋 View Crash Log'
                size_hint: (1, 0.1)
                on_press: app.show_log()
                background_color: (0.5, 0.5, 0.5, 1)
            
            Button:
                text: '❌ Exit'
                size_hint: (1, 0.1)
                on_press: app.stop()
                background_color: (0.8, 0.2, 0.2, 1)
'''
    
    error_logger.write_error("KV string defined")
    
    class SpeechApp(App):
        def build(self):
            try:
                error_logger.write_error("Building UI...")
                
                # Request permissions on Android
                if platform == 'android' and ANDROID_AVAILABLE:
                    error_logger.write_error("Requesting Android permissions...")
                    self.request_android_permissions()
                
                # Build UI from KV string
                self.root = Builder.load_string(KV)
                error_logger.write_error("UI built successfully")
                
                return self.root
                
            except Exception as e:
                error_logger.write_error(f"Build failed: {e}")
                error_logger.write_error(traceback.format_exc())
                
                # Return error screen
                layout = BoxLayout(orientation='vertical', padding=20)
                layout.add_widget(Label(
                    text=f'App failed to start:\n{str(e)}\n\nCheck /sdcard/speechapp_crash.log',
                    color=(1, 0, 0, 1)
                ))
                return layout
        
        def on_start(self):
            """Called when app starts"""
            error_logger.write_error("App started successfully!")
            self.update_status("✅ App Ready - Tap a button to test")
        
        def request_android_permissions(self):
            """Request Android runtime permissions"""
            try:
                permissions = [
                    Permission.RECORD_AUDIO,
                    Permission.WRITE_EXTERNAL_STORAGE,
                    Permission.READ_EXTERNAL_STORAGE,
                    Permission.INTERNET
                ]
                request_permissions(permissions)
                error_logger.write_error("Permissions requested")
            except Exception as e:
                error_logger.write_error(f"Permission request failed: {e}")
        
        def update_status(self, message):
            """Update status label"""
            try:
                self.root.ids.status_label.text = message
                Logger.info(f"Status: {message}")
            except Exception as e:
                Logger.error(f"Status update failed: {e}")
        
        def test_feature(self, feature):
            """Test feature buttons"""
            try:
                error_logger.write_error(f"Testing feature: {feature}")
                self.update_status(f"✅ {feature.capitalize()} button works!")
                
                # Write success to log
                with open('/sdcard/speechapp_test.log', 'a') as f:
                    f.write(f"{feature} button pressed successfully\n")
                    
            except Exception as e:
                error_logger.write_error(f"Feature test failed: {e}")
                self.update_status(f"❌ Error: {str(e)}")
        
        def show_log(self):
            """Show crash log contents"""
            try:
                with open('/sdcard/speechapp_crash.log', 'r') as f:
                    log_content = f.read()
                self.update_status(f"Log has {len(log_content)} bytes")
                error_logger.write_error("Log viewed by user")
            except Exception as e:
                self.update_status(f"No log file: {str(e)}")
    
    error_logger.write_error("App class defined, starting main...")
    
    if __name__ == '__main__':
        try:
            error_logger.write_error("Running SpeechApp...")
            SpeechApp().run()
        except Exception as e:
            error_logger.write_error(f"App.run() failed: {e}")
            error_logger.write_error(traceback.format_exc())
            raise

except Exception as e:
    error_logger.write_error(f"CRITICAL IMPORT ERROR: {e}")
    error_logger.write_error(traceback.format_exc())
    raise
