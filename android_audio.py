"""Android audio recorder using MediaRecorder via pyjnius.

This wrapper records to a container file (3gp) using the platform MediaRecorder.
On Android the app should record to a file and then upload/convert on a server or
use a native transcription pipeline. This helper provides start/stop functions.
"""
from jnius import autoclass, JavaException


class AndroidMediaRecorder:
    def __init__(self):
        self.MediaRecorder = autoclass('android.media.MediaRecorder')
        self.rec = None
        self.path = None

    def start(self, path):
        try:
            self.rec = self.MediaRecorder()
            # Use MIC as audio source
            self.rec.setAudioSource(self.MediaRecorder.AudioSource.MIC)
            # THREE_GPP is widely supported
            self.rec.setOutputFormat(self.MediaRecorder.OutputFormat.THREE_GPP)
            # Use AMR_NB encoder which is available on most devices
            self.rec.setAudioEncoder(self.MediaRecorder.AudioEncoder.AMR_NB)
            self.rec.setOutputFile(path)
            self.rec.prepare()
            self.rec.start()
            self.path = path
        except JavaException as e:
            # Wrap Java errors
            raise RuntimeError(f'Android MediaRecorder error: {e}')

    def stop(self):
        if not self.rec:
            return None
        try:
            # stop may raise if called too soon
            self.rec.stop()
        except JavaException:
            pass
        try:
            self.rec.reset()
            self.rec.release()
        except JavaException:
            pass
        path = self.path
        self.rec = None
        self.path = None
        return path


# module-level helper
recorder = AndroidMediaRecorder()
