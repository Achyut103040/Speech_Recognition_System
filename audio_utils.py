import os
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from kivy.utils import platform as kivy_platform

# Try to import desktop audio libs; on Android these will not be available
try:
    import sounddevice as sd
    import soundfile as sf
except Exception:
    sd = None
    sf = None

# Android helper - only import if on Android to avoid import errors on desktop
android_recorder = None
if kivy_platform == 'android':
    try:
        from android_audio import recorder as android_recorder
    except Exception:
        android_recorder = None


def record_wav(path, duration=5, samplerate=16000, channels=1):
    """Record audio for `duration` seconds and write to `path` as WAV.

    This function blocks for `duration` seconds while recording.
    """
    if kivy_platform == 'android' and android_recorder is not None:
        # On Android, use MediaRecorder to write a 3gp container file.
        # We change extension to .3gp for Android native recording.
        out_path = os.path.splitext(path)[0] + '.3gp'
        android_recorder.start(out_path)
        import time
        time.sleep(duration)
        android_recorder.stop()
        return out_path

    if sd is None or sf is None:
        raise RuntimeError('sounddevice/soundfile not available in this environment')

    data = sd.rec(int(duration * samplerate), samplerate=samplerate, channels=channels, dtype='float32')
    sd.wait()
    sf.write(path, data, samplerate)
    return path


def load_wav(path):
    if sf is None:
        raise RuntimeError('soundfile not available to read audio on this platform')
    data, sr = sf.read(path)
    # Ensure mono
    if data.ndim > 1:
        data = np.mean(data, axis=1)
    return data, sr


def make_waveform_and_spectrogram(wav_path, out_wave_img, out_spec_img):
    """Generate waveform and spectrogram images from a WAV file.

    Saves two PNGs: waveform and spectrogram.
    """
    data, sr = load_wav(wav_path)
    times = np.arange(len(data)) / float(sr)

    # Waveform
    plt.figure(figsize=(8, 3))
    plt.plot(times, data, linewidth=0.6)
    plt.xlabel('Time (s)')
    plt.ylabel('Amplitude')
    plt.title('Waveform')
    plt.tight_layout()
    plt.savefig(out_wave_img)
    plt.close()

    # Spectrogram
    plt.figure(figsize=(8, 3))
    plt.specgram(data, NFFT=1024, Fs=sr, noverlap=512, cmap='viridis')
    plt.xlabel('Time (s)')
    plt.ylabel('Frequency (Hz)')
    plt.title('Spectrogram')
    plt.colorbar(label='Intensity dB')
    plt.tight_layout()
    plt.savefig(out_spec_img)
    plt.close()


class Recorder:
    """Non-blocking recorder using sounddevice.InputStream and soundfile.SoundFile.

    Usage:
        r = Recorder()
        r.start('out.wav')
        ...
        r.stop()
    """

    def __init__(self):
        self._sf = None
        self._stream = None
        self._path = None

    def start(self, path, samplerate=16000, channels=1):
        # On Android use native recorder which records into a 3gp file
        if kivy_platform == 'android' and android_recorder is not None:
            if self._stream is not None:
                raise RuntimeError('Recorder already running')
            out_path = os.path.splitext(path)[0] + '.3gp'
            os.makedirs(os.path.dirname(out_path) or '.', exist_ok=True)
            android_recorder.start(out_path)
            self._path = out_path
            # _stream is used as a marker for running
            self._stream = True
            return

        if sd is None or sf is None:
            raise RuntimeError('sounddevice/soundfile not available in this environment')

        if self._stream is not None:
            raise RuntimeError('Recorder already running')
        self._path = path
        os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
        self._sf = sf.SoundFile(path, mode='w', samplerate=samplerate, channels=channels, subtype='PCM_16')

        def callback(indata, frames, time, status):
            if status:
                # keep simple logging; avoid printing too often
                print('Recorder status:', status)
            # write a copy to avoid underlying buffer reuse issues
            self._sf.write(indata.copy())

        self._stream = sd.InputStream(samplerate=samplerate, channels=channels, callback=callback)
        self._stream.start()

    def stop(self):
        if kivy_platform == 'android' and android_recorder is not None and self._stream:
            # stop Android native recorder
            android_path = android_recorder.stop()
            self._stream = None
            self._sf = None
            return android_path

        if self._stream is None:
            return
        try:
            self._stream.stop()
            self._stream.close()
        finally:
            self._stream = None
        if self._sf is not None:
            try:
                self._sf.close()
            finally:
                self._sf = None


# module-level default recorder
recorder = Recorder()
