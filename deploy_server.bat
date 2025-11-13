@echo off
REM Multi-server deployment helper for Windows
REM Supports: Local, Docker, WSL2, and cloud options

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "SERVER_PORT=8000"
set "SERVER_HOST=0.0.0.0"

color 0A
echo.
echo ============================================================
echo    Speech Recognition Server Deployment (Windows)
echo ============================================================
echo.

:MENU
echo.
echo Choose deployment method:
echo   1 - Local (development - Python directly)
echo   2 - Docker (requires Docker Desktop)
echo   3 - WSL2 (Windows Subsystem for Linux 2)
echo   4 - Deploy to AWS EC2
echo   5 - Deploy to Azure Container Instances
echo   0 - Exit
echo.
set /p CHOICE=Enter choice (0-5): 

if "%CHOICE%"=="1" goto LOCAL
if "%CHOICE%"=="2" goto DOCKER
if "%CHOICE%"=="3" goto WSL2
if "%CHOICE%"=="4" goto AWS
if "%CHOICE%"=="5" goto AZURE
if "%CHOICE%"=="0" goto END
echo Invalid choice. Please try again.
goto MENU

:LOCAL
echo.
echo [1] LOCAL DEPLOYMENT
echo =====================
echo Starting FastAPI server on %SERVER_HOST%:%SERVER_PORT%
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    color 0C
    echo ERROR: Python not found. Install from https://www.python.org/
    pause
    exit /b 1
)

REM Check if ffmpeg is installed
ffmpeg -version >nul 2>&1
if errorlevel 1 (
    color 0C
    echo ERROR: ffmpeg not found. Install from https://ffmpeg.org/
    echo On Windows: Use chocolatey or download from ffmpeg.org
    pause
    exit /b 1
)

echo Installing Python dependencies...
pip install --upgrade pip
pip install -r "%SCRIPT_DIR%requirements.txt"

echo.
color 0B
echo Starting server...
echo Access at: http://localhost:%SERVER_PORT%/docs
echo.
uvicorn server:app --host %SERVER_HOST% --port %SERVER_PORT% --reload

goto END

:DOCKER
echo.
echo [2] DOCKER DEPLOYMENT
echo =====================
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    color 0C
    echo ERROR: Docker not installed or not in PATH
    echo Install Docker Desktop from https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

set /p BUILD=Do you want to build the image? (y/n): 
if /i "%BUILD%"=="y" (
    echo Creating Dockerfile...
    (
        echo FROM python:3.11-slim
        echo.
        echo WORKDIR /app
        echo.
        echo RUN apt-get update ^&^& apt-get install -y ffmpeg ^&^& rm -rf /var/lib/apt/lists/*
        echo.
        echo COPY requirements.txt .
        echo RUN pip install --no-cache-dir -r requirements.txt
        echo.
        echo COPY . .
        echo RUN mkdir -p models
        echo.
        echo EXPOSE 8000
        echo CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]
    ) > "%SCRIPT_DIR%Dockerfile"
    
    echo Building Docker image...
    docker build -t speech-recognition-server:latest "%SCRIPT_DIR%"
)

echo.
set /p RUN=Do you want to run the container? (y/n): 
if /i "%RUN%"=="y" (
    echo Starting container...
    docker run -d ^
        --name speech-server ^
        -p %SERVER_PORT%:8000 ^
        -v "%SCRIPT_DIR%models:/app/models" ^
        speech-recognition-server:latest
    
    color 0B
    echo.
    echo Server running at http://localhost:%SERVER_PORT%
    echo View logs: docker logs speech-server
    echo Stop container: docker stop speech-server
    echo.
)

goto MENU

:WSL2
echo.
echo [3] WSL2 DEPLOYMENT
echo ===================
echo Using Windows Subsystem for Linux 2
echo.

REM Check if wsl is available
wsl --version >nul 2>&1
if errorlevel 1 (
    color 0C
    echo ERROR: WSL2 not installed
    echo Install WSL2: wsl --install
    pause
    exit /b 1
)

echo Running deployment in WSL2...
wsl bash "%SCRIPT_DIR%deploy_server.sh" local

goto MENU

:AWS
echo.
echo [4] AWS EC2 DEPLOYMENT
echo ======================
echo.
set /p EC2_IP=Enter EC2 instance IP or DNS: 
set /p SSH_KEY=Enter SSH key path (e.g., C:\path\to\key.pem): 

if not exist "%SSH_KEY%" (
    color 0C
    echo ERROR: SSH key not found: %SSH_KEY%
    pause
    exit /b 1
)

echo.
echo Uploading files to EC2...
REM Using scp via git bash or putty pscp tool
echo This requires scp (from Git Bash or PuTTY tools)
echo Manual steps:
echo   1. Use WinSCP or PuTTY to upload the Speech_Recognition directory
echo   2. SSH into the instance
echo   3. Run: bash deploy_server.sh local
echo.
pause

goto MENU

:AZURE
echo.
echo [5] AZURE CONTAINER INSTANCES
echo =============================
echo.

REM Check if Azure CLI is installed
az --version >nul 2>&1
if errorlevel 1 (
    color 0C
    echo ERROR: Azure CLI not installed
    echo Install from: https://docs.microsoft.com/cli/azure/install-azure-cli-windows
    pause
    exit /b 1
)

set /p RG=Enter Azure resource group name: 
set /p ACR=Enter Azure Container Registry name: 

echo.
echo Building and pushing to ACR...
az acr build ^
    --registry %ACR% ^
    --image speech-recognition-server:latest ^
    "%SCRIPT_DIR%"

echo.
echo Deploying to Container Instances...
az container create ^
    --resource-group %RG% ^
    --name speech-server ^
    --image %ACR%.azurecr.io/speech-recognition-server:latest ^
    --cpu 2 ^
    --memory 2 ^
    --registry-login-server %ACR%.azurecr.io ^
    --ip-address Public ^
    --ports 8000

color 0B
echo.
echo Deployment complete!
echo.

goto MENU

:END
echo.
color 0A
echo DEPLOYMENT SUMMARY
echo ==================
echo.
echo To test the API:
echo   curl http://localhost:8000/docs
echo.
echo To transcribe audio:
echo   curl -X POST http://localhost:8000/transcribe -F "file=@example.wav"
echo.
echo Security checklist:
echo   [ ] Use HTTPS in production
echo   [ ] Add authentication
echo   [ ] Rate limit requests
echo   [ ] Validate file uploads
echo   [ ] Use firewall restrictions
echo.
pause
exit /b 0
