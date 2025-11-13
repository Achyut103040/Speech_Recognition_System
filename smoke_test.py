"""Simple smoke test for the speech app pipeline.

This script attempts to:
 - check installed dependencies
 - record a short WAV (if microphone available) or use a provided WAV
 - generate waveform/spectrogram
 - transcribe using Vosk model under ./models

Usage:
    python smoke_test.py [path_to_wav]

"""
import sys
import os
import tempfile
import time

import audio_utils
import transcribe


def main():
    wav = None
    if len(sys.argv) > 1:
        wav = sys.argv[1]
    else:
        # record a short test clip
        out = os.path.join(os.getcwd(), 'recordings', f'smoke_{int(time.time())}.wav')
        os.makedirs(os.path.dirname(out), exist_ok=True)
        print('Recording 3 seconds...')
        try:
            audio_utils.record_wav(out, duration=3)
            wav = out
        except Exception as e:
            print('Recording failed:', e)
            print('Please provide a WAV file as an argument to this script.')
            return 2

    print('Making visuals...')
    a_out = os.path.join('assets', 'smoke_wave.png')
    s_out = os.path.join('assets', 'smoke_spec.png')
    audio_utils.make_waveform_and_spectrogram(wav, a_out, s_out)
    print('Visuals saved to', a_out, s_out)

    print('Transcribing...')
    app_root = os.path.dirname(__file__)
    # find first model under models/
    model_dir = None
    mroot = os.path.join(app_root, 'models')
    if os.path.exists(mroot):
        for name in os.listdir(mroot):
            p = os.path.join(mroot, name)
            if os.path.isdir(p):
                model_dir = p
                break

    if not model_dir:
        print('No model found under models/. Please download a Vosk model as described in README.')
        return 3

    text = transcribe.transcribe_wav(wav, model_dir=model_dir)
    print('Transcription result:')
    print(text)

    return 0


if __name__ == '__main__':
    sys.exit(main())
