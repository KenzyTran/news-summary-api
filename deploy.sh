#!/bin/bash

# Script to deploy the News Summary API on Ubuntu server

set -e

echo "🚀 Starting deployment of News Summary API..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Python and pip if not already installed
echo "🐍 Installing Python and pip..."
sudo apt install -y python3 python3-pip python3-venv

# Install Node.js and npm for Playwright
echo "📦 Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install uvx (for mcp-server-fetch)
echo "📦 Installing uvx..."
pip3 install --user uvx

# Create application directory
APP_DIR="/opt/news-summary-api"
echo "📁 Creating application directory: $APP_DIR"
sudo mkdir -p $APP_DIR
sudo chown $USER:$USER $APP_DIR

# Copy application files
echo "📋 Copying application files..."
cp -r . $APP_DIR/
cd $APP_DIR

# Create virtual environment
echo "🔧 Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip install -r requirements.txt

# Install Playwright
echo "🎭 Installing Playwright..."
npm install -g @playwright/mcp@latest

# Install Playwright browsers
echo "🌐 Installing Playwright browsers..."
npx playwright install

# Create systemd service file
echo "⚙️ Creating systemd service..."
sudo tee /etc/systemd/system/news-summary-api.service > /dev/null <<EOF
[Unit]
Description=News Summary API
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR
Environment=PATH=$APP_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=$APP_DIR/venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create .env file from example
echo "📝 Creating environment file..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "⚠️  Please edit .env file and add your API keys!"
fi

# Set up nginx reverse proxy
echo "🔧 Setting up Nginx reverse proxy..."
sudo apt install -y nginx

sudo tee /etc/nginx/sites-available/news-summary-api > /dev/null <<EOF
server {
    listen 80;
    server_name your_domain.com;  # Replace with your domain
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable nginx site
sudo ln -sf /etc/nginx/sites-available/news-summary-api /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# Enable and start the service
echo "🚀 Starting News Summary API service..."
sudo systemctl daemon-reload
sudo systemctl enable news-summary-api
sudo systemctl start news-summary-api

# Install firewall and open ports
echo "🔥 Configuring firewall..."
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

echo "✅ Deployment completed!"
echo ""
echo "📋 Post-deployment checklist:"
echo "1. Edit $APP_DIR/.env and add your OpenAI/Anthropic API keys"
echo "2. Update server_name in /etc/nginx/sites-available/news-summary-api"
echo "3. Restart services: sudo systemctl restart news-summary-api nginx"
echo "4. Check service status: sudo systemctl status news-summary-api"
echo "5. View logs: sudo journalctl -u news-summary-api -f"
echo ""
echo "🌐 API will be available at: http://your_domain.com"
echo "📖 API documentation: http://your_domain.com/docs"
