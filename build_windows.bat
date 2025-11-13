@echo off
REM Build a one-file Windows executable using PyInstaller
REM Run from project root in an activated venv

WHERE python >nul 2>&1 || (
  echo Python not found in PATH. Activate your venv first.
  exit /b 1
)

pip install pyinstaller --upgrade
pyinstaller --noconfirm --onefile --add-data "app.kv;." --add-data "assets;assets" main.py
echo Done. See dist\main.exe
