"""Simple transcription server that accepts audio uploads, converts to WAV via ffmpeg,
and runs Vosk transcription locally.

Requirements: ffmpeg available on PATH, a Vosk model under ./models/
Run with: uvicorn server:app --host 0.0.0.0 --port 8000
"""
import os
import subprocess
import tempfile
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse

import transcribe

app = FastAPI()


def find_model_dir():
    root = os.path.join(os.path.dirname(__file__), 'models')
    if not os.path.exists(root):
        return None
    for name in os.listdir(root):
        p = os.path.join(root, name)
        if os.path.isdir(p):
            return p
    return None


@app.post('/transcribe')
async def upload_and_transcribe(file: UploadFile = File(...)):
    if not file:
        raise HTTPException(status_code=400, detail='No file uploaded')

    model_dir = find_model_dir()
    if not model_dir:
        raise HTTPException(status_code=500, detail='No model found on server (place model under models/)')

    suffix = os.path.splitext(file.filename)[1].lower()
    with tempfile.TemporaryDirectory() as td:
        in_path = os.path.join(td, 'in' + suffix)
        out_wav = os.path.join(td, 'out.wav')
        with open(in_path, 'wb') as f:
            contents = await file.read()
            f.write(contents)

        # Convert to WAV 16k mono using ffmpeg
        cmd = ['ffmpeg', '-y', '-i', in_path, '-ar', '16000', '-ac', '1', out_wav]
        try:
            subprocess.check_call(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except subprocess.CalledProcessError:
            raise HTTPException(status_code=500, detail='ffmpeg conversion failed')

        # Transcribe
        try:
            text = transcribe.transcribe_wav(out_wav, model_dir=model_dir)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    return JSONResponse({'text': text})
