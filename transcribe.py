import os
import json
import soundfile as sf

try:
    from vosk import Model, KaldiRecognizer
except Exception:
    Model = None
    KaldiRecognizer = None


def transcribe_wav(wav_path, model_dir='models'):
    """Transcribe a WAV file using Vosk offline model.

    Returns the full recognized text. Raises an error if model not found or Vosk not installed.
    """
    if Model is None or KaldiRecognizer is None:
        raise RuntimeError('Vosk not installed. Please install `vosk` and a model.')

    if model_dir is None:
        raise FileNotFoundError('model_dir is None. Please provide a model directory path.')

    if not os.path.exists(model_dir):
        raise FileNotFoundError(f'Model directory not found: {model_dir}. Please download a Vosk model and place it there.')

    model = Model(model_dir)

    data, samplerate = sf.read(wav_path, dtype='int16')
    # If stereo, convert to mono by averaging channels
    if data.ndim > 1:
        data = data.mean(axis=1).astype('int16')

    rec = KaldiRecognizer(model, samplerate)

    results = []
    # Process in chunks
    CHUNK = 4000
    idx = 0
    while idx < len(data):
        chunk = data[idx:idx+CHUNK].tobytes()
        if rec.AcceptWaveform(chunk):
            j = json.loads(rec.Result())
            results.append(j.get('text', ''))
        idx += CHUNK

    final = json.loads(rec.FinalResult())
    results.append(final.get('text', ''))

    return ' '.join([r for r in results if r])
