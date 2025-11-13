#!/usr/bin/env python3
"""
Cross-platform Speech Recognition Web App
Works on: Android, iOS, Desktop browsers
Deployable to: Google Play Store (via TWA), App Store (via PWA), Web hosting
"""

from flask import Flask, render_template, request, jsonify, send_from_directory
from flask_cors import CORS
import os
import wave
import json
from datetime import datetime
import vosk
import base64

app = Flask(__name__, static_folder='web_static', template_folder='web_templates')
CORS(app)  # Enable CORS for PWA

# Configure paths
UPLOAD_FOLDER = 'web_uploads'
RECORDINGS_FOLDER = 'web_recordings'
MODEL_PATH = 'models/vosk-model-small-en-us-0.15'

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(RECORDINGS_FOLDER, exist_ok=True)

# Initialize Vosk model
model = None

def init_model():
    global model
    if os.path.exists(MODEL_PATH):
        try:
            model = vosk.Model(MODEL_PATH)
            print(f"✅ Vosk model loaded from {MODEL_PATH}")
        except Exception as e:
            print(f"⚠️  Model load failed: {e}")
            model = None
    else:
        print(f"⚠️  Model not found at {MODEL_PATH}")
        model = None

@app.route('/')
def index():
    """Main app page - PWA manifest included"""
    return render_template('index.html')

@app.route('/manifest.json')
def manifest():
    """PWA manifest for installability"""
    return jsonify({
        "name": "Speech Recognition",
        "short_name": "SpeechRec",
        "description": "Multi-platform speech recognition app",
        "start_url": "/",
        "display": "standalone",
        "background_color": "#2196F3",
        "theme_color": "#1976D2",
        "orientation": "landscape",
        "icons": [
            {
                "src": "/static/icon-192.png",
                "sizes": "192x192",
                "type": "image/png",
                "purpose": "any maskable"
            },
            {
                "src": "/static/icon-512.png",
                "sizes": "512x512",
                "type": "image/png",
                "purpose": "any maskable"
            }
        ],
        "categories": ["utilities", "productivity"],
        "screenshots": [
            {
                "src": "/static/screenshot.png",
                "sizes": "1280x720",
                "type": "image/png"
            }
        ]
    })

@app.route('/service-worker.js')
def service_worker():
    """Service worker for offline support"""
    return send_from_directory('web_static', 'service-worker.js')

@app.route('/api/transcribe', methods=['POST'])
def transcribe():
    """Transcribe audio file or base64 audio data"""
    try:
        if not model:
            return jsonify({'error': 'Model not loaded'}), 500
        
        # Handle file upload
        if 'file' in request.files:
            file = request.files['file']
            if file.filename == '':
                return jsonify({'error': 'No file selected'}), 400
            
            filepath = os.path.join(UPLOAD_FOLDER, f"upload_{datetime.now().strftime('%Y%m%d_%H%M%S')}.wav")
            file.save(filepath)
        
        # Handle base64 audio data (from browser recording)
        elif request.json and 'audio' in request.json:
            audio_data = base64.b64decode(request.json['audio'].split(',')[1])
            filepath = os.path.join(RECORDINGS_FOLDER, f"recording_{datetime.now().strftime('%Y%m%d_%H%M%S')}.wav")
            with open(filepath, 'wb') as f:
                f.write(audio_data)
        else:
            return jsonify({'error': 'No audio data provided'}), 400
        
        # Transcribe
        wf = wave.open(filepath, "rb")
        if wf.getnchannels() != 1 or wf.getsampwidth() != 2 or wf.getcomptype() != "NONE":
            return jsonify({'error': 'Audio must be WAV format mono PCM'}), 400
        
        rec = vosk.KaldiRecognizer(model, wf.getframerate())
        rec.SetWords(True)
        
        results = []
        while True:
            data = wf.readframes(4000)
            if len(data) == 0:
                break
            if rec.AcceptWaveform(data):
                result = json.loads(rec.Result())
                if 'text' in result and result['text']:
                    results.append(result['text'])
        
        # Get final result
        final_result = json.loads(rec.FinalResult())
        if 'text' in final_result and final_result['text']:
            results.append(final_result['text'])
        
        transcription = ' '.join(results)
        
        return jsonify({
            'success': True,
            'transcription': transcription,
            'file': os.path.basename(filepath)
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/recordings')
def list_recordings():
    """List all recordings"""
    try:
        recordings = []
        for folder in [RECORDINGS_FOLDER, UPLOAD_FOLDER]:
            if os.path.exists(folder):
                for file in os.listdir(folder):
                    if file.endswith('.wav'):
                        filepath = os.path.join(folder, file)
                        recordings.append({
                            'name': file,
                            'size': os.path.getsize(filepath),
                            'modified': datetime.fromtimestamp(os.path.getmtime(filepath)).isoformat()
                        })
        return jsonify({'recordings': recordings})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'timestamp': datetime.now().isoformat()
    })

if __name__ == '__main__':
    print("🌐 Starting Cross-Platform Speech Recognition Server...")
    init_model()
    
    # Run on all interfaces for mobile access
    app.run(host='0.0.0.0', port=5000, debug=True)
