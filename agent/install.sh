#!/bin/bash
# GHOST CMD - Agent Installer
# Fixed untuk Python 3.11+ externally managed environment
# Run on agent machine
set -e

echo "🚀 GHOST CMD Agent Installer"
echo "=================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root: sudo bash install.sh"
    exit 1
fi

# ==========================================
# CHECK MODE: UPDATE or INSTALL
# ==========================================
MODE="${1:-install}"

if [ "$MODE" = "update" ]; then
    echo "🔄 UPDATE MODE - Pulling latest changes..."
    cd "$(dirname "$0")"
    git pull origin main
    systemctl restart ghost-agent
    echo "✅ Agent updated and restarted!"
    exit 0
fi

# ==========================================
# 1. System Update
# ==========================================
echo "📦 Updating system packages..."
apt-get update && apt-get upgrade -y
apt-get install -y python3 python3-pip python3-venv git curl wget

# ==========================================
# 2. Setup Python Environment
# ==========================================
echo "🐍 Setting up Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# ==========================================
# 3. Setup Data Directories
# ==========================================
echo "📁 Creating data directories..."
mkdir -p chrome_profiles
mkdir -p logs

# ==========================================
# 4. Configure Environment
# ==========================================
echo "⚙️ Configuring environment..."

# Create .env file if not exists
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file..."
    read -p "📡 Enter Dashboard URL [https://dashboard.jujulefek.qzz.io]: " DASHBOARD_URL
    DASHBOARD_URL="${DASHBOARD_URL:-https://dashboard.jujulefek.qzz.io}"
    
    cat > ".env" << EOF
DASHBOARD_URL=$DASHBOARD_URL
AUTH_KEY=GHOST_SECRET_2026
EOF
    echo "✅ .env created"
else
    echo "✅ .env already exists"
    cat ".env"
fi

# ==========================================
# 5. Create Systemd Service for Agent
# ==========================================
echo "⚙️ Creating GHOST Agent systemd service..."

SCRIPT_DIR="$(pwd)"

cat > /etc/systemd/system/ghost-agent.service <<EOF
[Unit]
Description=GHOST CMD Agent
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$SCRIPT_DIR
EnvironmentFile=$SCRIPT_DIR/.env
ExecStart=$SCRIPT_DIR/venv/bin/python3 agent.py
Restart=always
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ghost-agent.service

# ==========================================
# 6. Start Services
# ==========================================
echo "🚀 Starting services..."
systemctl start ghost-agent.service

sleep 3

# ==========================================
# 7. Final Message
# ==========================================
echo ""
echo "✅ Installation Complete!"
echo "=================================="
echo "📊 Agent running on: http://localhost:7860"
echo "📡 Dashboard: $(grep DASHBOARD_URL .env | cut -d= -f2)"
echo ""
echo "🔧 Service Management:"
echo "   systemctl status ghost-agent"
echo ""
echo "🔄 Restart commands:"
echo "   systemctl restart ghost-agent"
echo ""
echo "📦 UPDATE CODE (ketika ada perubahan):"
echo "   cd agent && sudo bash install.sh update"
echo ""
echo "📋 View Logs:"
echo "   journalctl -u ghost-agent -f"
echo ""
echo "🎉 Selamat! Agent kamu sudah aktif."
