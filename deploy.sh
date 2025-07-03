#!/bin/bash

# Script to deploy the News Summary API on Ubuntu server

set -e

echo "🚀 Starting deployment of News Summary API..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Python and pip if not already installed
echo "🐍 Installing Python and pip..."
sudo apt install -y python3 python3-pip python3-venv python3-full

# Install Node.js and npm for Playwright
echo "📦 Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install uv (which includes uvx)
echo "📦 Installing uv (includes uvx)..."
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Create application directory
APP_DIR="/opt/news-summary-api"
echo "📁 Creating application directory: $APP_DIR"
sudo mkdir -p $APP_DIR

# Copy application files (excluding .git directory)
echo "📋 Copying application files..."
rsync -av --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' . $APP_DIR/ || {
    echo "rsync not available, using cp with exclusions..."
    find . -type f -not -path './.git/*' -not -name '*.pyc' -not -path './__pycache__/*' -exec cp --parents {} $APP_DIR/ \;
}

# Change ownership
sudo chown -R $USER:$USER $APP_DIR

cd $APP_DIR

# Create virtual environment
echo "🔧 Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Create requirements.txt without version conflicts
echo "📝 Creating compatible requirements.txt..."
cat > requirements.txt << 'EOF'
fastapi
uvicorn
pydantic
python-dotenv
httpx
aiofiles
requests
openai
anthropic
agents
EOF

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Install Playwright MCP server with sudo
echo "🎭 Installing Playwright MCP server..."
sudo npm install -g @playwright/mcp@latest

# Install Playwright browsers
echo "🌐 Installing Playwright browsers..."
sudo npx playwright install

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
Environment=PATH=$APP_DIR/venv/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=$APP_DIR/venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create .env file
echo "📝 Creating environment file..."
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
    else
        cat > .env << 'ENVEOF'
OPENAI_API_KEY=sk-your-openai-api-key
ANTHROPIC_API_KEY=sk-ant-your-anthropic-api-key
HOST=0.0.0.0
PORT=8000
LOG_LEVEL=INFO
ENVEOF
    fi
    echo "⚠️  Please edit .env file and add your API keys!"
fi

# Set up nginx reverse proxy
echo "🔧 Setting up Nginx reverse proxy..."
sudo apt install -y nginx

sudo tee /etc/nginx/sites-available/news-summary-api > /dev/null <<EOF
server {
    listen 80;
    server_name _;  # Accept any domain
    
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
echo "2. Test API: curl http://localhost:8000/health"
echo "3. Check service status: sudo systemctl status news-summary-api"
echo "4. View logs: sudo journalctl -u news-summary-api -f"
echo ""
echo "🌐 API will be available at: http://your_server_ip"
echo "📖 API documentation: http://your_server_ip/docs"