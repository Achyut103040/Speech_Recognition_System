#!/usr/bin/env bash
# Build a one-file Linux executable using PyInstaller
# Run from project root in an activated venv

set -e
command -v python >/dev/null 2>&1 || { echo "Python not found; activate your venv."; exit 1; }
pip install --upgrade pip pyinstaller
pyinstaller --noconfirm --onefile --add-data "app.kv:.":"assets:assets" main.py || true
echo "Done. Check dist/" 
