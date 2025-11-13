#!/usr/bin/env bash
# Multi-server deployment helper for Speech Recognition transcription server
# Supports: Local, Docker, Cloud (AWS/GCP), and Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_PORT=${SERVER_PORT:-8000}
SERVER_HOST=${SERVER_HOST:-0.0.0.0}

echo -e "${GREEN}=== Speech Recognition Server Deployment ===${NC}\n"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to deploy locally
deploy_local() {
    echo -e "${YELLOW}[1] Local Deployment${NC}"
    echo "Starting FastAPI server on ${SERVER_HOST}:${SERVER_PORT}"
    echo ""
    echo "Prerequisites:"
    echo "  - Python 3.8+"
    echo "  - ffmpeg installed (apt install ffmpeg / brew install ffmpeg)"
    echo ""
    
    if ! command_exists ffmpeg; then
        echo -e "${RED}Error: ffmpeg not found. Install it first:${NC}"
        echo "  Ubuntu/Debian: sudo apt install ffmpeg"
        echo "  macOS: brew install ffmpeg"
        echo "  Windows: choco install ffmpeg"
        exit 1
    fi
    
    echo "Installing dependencies..."
    pip install --upgrade pip
    pip install -r "$SCRIPT_DIR/requirements.txt"
    
    echo -e "${GREEN}Starting server...${NC}"
    uvicorn server:app --host "$SERVER_HOST" --port "$SERVER_PORT" --reload
}

# Function to deploy with Docker
deploy_docker() {
    echo -e "${YELLOW}[2] Docker Deployment${NC}"
    
    if ! command_exists docker; then
        echo -e "${RED}Error: Docker not installed. Install from https://www.docker.com${NC}"
        exit 1
    fi
    
    echo "Creating Dockerfile..."
    cat > "$SCRIPT_DIR/Dockerfile" << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y ffmpeg && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app files
COPY . .

# Create models directory
RUN mkdir -p models

# Download a small model on startup (optional; can be mounted)
# RUN python -c "from model_downloader import ensure_vosk_model; ensure_vosk_model()"

# Expose port
EXPOSE 8000

# Run server
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]
EOF
    
    echo "Building Docker image..."
    docker build -t speech-recognition-server:latest .
    
    echo -e "${GREEN}Running Docker container...${NC}"
    docker run -d \
        --name speech-server \
        -p "$SERVER_PORT:8000" \
        -v "$SCRIPT_DIR/models:/app/models" \
        speech-recognition-server:latest
    
    echo -e "${GREEN}Server running at http://localhost:${SERVER_PORT}${NC}"
    echo "To stop: docker stop speech-server"
    echo "To remove: docker rm speech-server"
}

# Function to deploy to AWS EC2
deploy_aws_ec2() {
    echo -e "${YELLOW}[3] AWS EC2 Deployment${NC}"
    echo ""
    echo "Prerequisites:"
    echo "  1. Create an EC2 instance (Ubuntu 22.04 recommended)"
    echo "  2. Open security group to allow port 8000 (or use 443 with reverse proxy)"
    echo "  3. Have SSH key and instance IP ready"
    echo ""
    
    read -p "Enter EC2 instance IP or DNS: " EC2_HOST
    read -p "Enter SSH key path (e.g., ~/.ssh/my-key.pem): " SSH_KEY
    
    if [ ! -f "$SSH_KEY" ]; then
        echo -e "${RED}SSH key not found: $SSH_KEY${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Deploying to EC2 (${EC2_HOST})...${NC}"
    
    # Upload files
    scp -i "$SSH_KEY" -r "$SCRIPT_DIR"/* "ubuntu@${EC2_HOST}:~/speech-app/"
    
    # Run deployment script on EC2
    ssh -i "$SSH_KEY" "ubuntu@${EC2_HOST}" << 'EOFSCRIPT'
cd ~/speech-app
sudo apt update
sudo apt install -y python3-pip ffmpeg
pip install -r requirements.txt

# Create systemd service
sudo tee /etc/systemd/system/speech-server.service > /dev/null << EOF
[Unit]
Description=Speech Recognition Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/speech-app
ExecStart=/usr/bin/python3 -m uvicorn server:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable speech-server
sudo systemctl start speech-server

echo "Service status:"
sudo systemctl status speech-server
EOFSCRIPT
    
    echo -e "${GREEN}Server deployed to http://${EC2_HOST}:8000${NC}"
}

# Function to deploy to Google Cloud Run
deploy_gcloud_run() {
    echo -e "${YELLOW}[4] Google Cloud Run Deployment${NC}"
    echo ""
    echo "Prerequisites:"
    echo "  1. Google Cloud account with billing enabled"
    echo "  2. gcloud CLI installed and authenticated"
    echo "  3. Project set with: gcloud config set project YOUR_PROJECT_ID"
    echo ""
    
    if ! command_exists gcloud; then
        echo -e "${RED}Error: gcloud CLI not installed. Install from https://cloud.google.com/sdk${NC}"
        exit 1
    fi
    
    echo "Creating .gcloudignore..."
    cat > "$SCRIPT_DIR/.gcloudignore" << 'EOF'
# .git and Git-related files
.git/
.gitignore

# Python
__pycache__/
*.py[cod]
.venv/

# IDE
.vscode/
.idea/

# Project-specific
recordings/
*.pyc
EOF
    
    echo "Building and deploying to Cloud Run..."
    gcloud run deploy speech-recognition-server \
        --source . \
        --platform managed \
        --region us-central1 \
        --memory 2Gi \
        --timeout 600 \
        --allow-unauthenticated \
        --set-env-vars "WORKERS=4"
    
    echo -e "${GREEN}Deployment complete!${NC}"
    gcloud run services describe speech-recognition-server --platform managed --region us-central1
}

# Function to deploy with docker-compose (multi-service)
deploy_docker_compose() {
    echo -e "${YELLOW}[5] Docker Compose Deployment (with Nginx reverse proxy)${NC}"
    
    if ! command_exists docker-compose; then
        echo -e "${RED}Error: docker-compose not installed${NC}"
        exit 1
    fi
    
    echo "Creating docker-compose.yml..."
    cat > "$SCRIPT_DIR/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  api:
    build: .
    container_name: speech-api
    ports:
      - "8000:8000"
    environment:
      - WORKERS=4
    volumes:
      - ./models:/app/models
    restart: unless-stopped

  nginx:
    image: nginx:latest
    container_name: speech-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on:
      - api
    restart: unless-stopped
EOF
    
    echo "Creating nginx.conf..."
    cat > "$SCRIPT_DIR/nginx.conf" << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream api {
        server api:8000;
    }

    server {
        listen 80;
        server_name _;

        client_max_body_size 100M;

        location / {
            proxy_pass http://api;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF
    
    echo -e "${GREEN}Starting docker-compose stack...${NC}"
    docker-compose up -d
    
    echo -e "${GREEN}Services running:${NC}"
    docker-compose ps
}

# Function to generate deployment summary
print_summary() {
    cat << EOF

${GREEN}=== Deployment Summary ===${NC}

Deployment Options:
  1. Local         - Run directly (development)
  2. Docker        - Single container (production-ready)
  3. AWS EC2       - Single VM on AWS
  4. Google Cloud  - Serverless on Cloud Run
  5. Docker Compose- Multi-service with Nginx

Next Steps:
  1. Test the API: curl -X GET http://localhost:8000/docs
  2. Upload audio:
     curl -X POST http://localhost:8000/transcribe \\
       -F "file=@example.wav"
  3. Configure app to use server URL in Settings

Security Checklist:
  [ ] Use HTTPS in production (TLS certificate)
  [ ] Add authentication (API key, OAuth)
  [ ] Rate limit requests
  [ ] Validate file uploads (size, format)
  [ ] Use firewall to restrict access
  [ ] Regular backups of models

EOF
}

# Main menu
show_menu() {
    echo ""
    echo -e "${YELLOW}Choose deployment method:${NC}"
    echo "  1) Local (development)"
    echo "  2) Docker (production-ready)"
    echo "  3) AWS EC2"
    echo "  4) Google Cloud Run"
    echo "  5) Docker Compose (with Nginx)"
    echo "  0) Exit"
    echo ""
}

# Main loop
if [ $# -eq 0 ]; then
    while true; do
        show_menu
        read -p "Enter choice (0-5): " choice
        
        case $choice in
            1) deploy_local ;;
            2) deploy_docker ;;
            3) deploy_aws_ec2 ;;
            4) deploy_gcloud_run ;;
            5) deploy_docker_compose ;;
            0) 
                print_summary
                exit 0
                ;;
            *) echo -e "${RED}Invalid choice${NC}" ;;
        esac
    done
else
    case "$1" in
        local) deploy_local ;;
        docker) deploy_docker ;;
        aws) deploy_aws_ec2 ;;
        gcloud) deploy_gcloud_run ;;
        compose) deploy_docker_compose ;;
        summary) print_summary ;;
        *) 
            echo "Usage: $0 {local|docker|aws|gcloud|compose|summary}"
            exit 1
            ;;
    esac
fi
