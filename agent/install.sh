#!/bin/bash

# ==========================================
# 🚀 GHOST CMD - AGENT INSTALLER
# ==========================================
# Auto-install, update, dan restart agent
# Fixed untuk Python 3.11+ externally managed environment
# Usage: sudo bash install.sh
# Update: sudo bash install.sh update

set -e

echo "🚀 GHOST CMD Agent Installer"
echo "======================================"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Script harus dijalankan dengan sudo!"
   exit 1
fi

# ==========================================
# CHECK MODE: UPDATE or INSTALL
# ==========================================
MODE="${1:-install}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$MODE" = "update" ]; then
    echo "🔄 UPDATE MODE - Pulling latest changes..."
    cd "$SCRIPT_DIR"
    
    # Activate venv & update
    if [ -d "venv" ]; then
        source venv/bin/activate
        git pull origin main
        pip install --upgrade -r requirements.txt
        deactivate
    else
        echo "⚠️ Virtual environment not found, running full install instead"
    fi
    
    systemctl restart ghost-agent
    echo "✅ Agent updated and restarted!"
    exit 0
fi

# ==========================================
# 1️⃣ SETUP VARIABLES
# ==========================================
AGENT_DIR="$SCRIPT_DIR"
REPO_URL="https://github.com/umnodqib/ghost-cmd.git"
SERVICE_NAME="ghost-agent"
PYTHON_CMD=$(which python3 || which python)
VENV_DIR="$AGENT_DIR/venv"

echo "📦 Python: $PYTHON_CMD"
echo "📁 Agent Dir: $AGENT_DIR"
echo "📁 Virtual Env: $VENV_DIR"

# ==========================================
# 2️⃣ CREATE/UPDATE AGENT DIRECTORY
# ==========================================
if [ ! -d ".git" ]; then
    echo "📥 Clone repository..."
    cd /opt/ghost-cmd 2>/dev/null || mkdir -p /opt/ghost-cmd
    cd /opt/ghost-cmd
    git clone "$REPO_URL" agent
    cd agent
else
    echo "🔄 Update repository..."
    cd "$AGENT_DIR"
    git pull origin main
fi

cd "$AGENT_DIR"
echo "✅ Repository ready at $AGENT_DIR"

# ==========================================
# 3️⃣ CREATE VIRTUAL ENVIRONMENT
# ==========================================
echo "🐍 Setting up Python virtual environment..."

if [ ! -d "$VENV_DIR" ]; then
    echo "📦 Creating new virtual environment..."
    $PYTHON_CMD -m venv "$VENV_DIR"
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi

# ==========================================
# 4️⃣ ACTIVATE VENV & INSTALL DEPENDENCIES
# ==========================================
echo "📦 Installing Python dependencies..."

# Source venv
source "$VENV_DIR/bin/activate"

# Upgrade pip
"$VENV_DIR/bin/pip" install --upgrade pip wheel setuptools -q

# Install requirements
if [ -f "requirements.txt" ]; then
    "$VENV_DIR/bin/pip" install -r requirements.txt -q
    echo "✅ Dependencies installed successfully"
else
    echo "⚠️ requirements.txt not found, skipping pip install"
fi

deactivate

# ==========================================
# 5️⃣ CONFIGURE ENVIRONMENT
# ==========================================
echo "⚙️ Configuring environment..."

# Create .env file if not exists
if [ ! -f "$AGENT_DIR/.env" ]; then
    echo "📝 Creating .env file..."
    read -p "📡 Enter Dashboard URL [https://dashboard.jujulefek.qzz.io]: " DASHBOARD_URL
    DASHBOARD_URL="${DASHBOARD_URL:-https://dashboard.jujulefek.qzz.io}"
    
    cat > "$AGENT_DIR/.env" << EOF
DASHBOARD_URL=$DASHBOARD_URL
AUTH_KEY=GHOST_SECRET_2026
EOF
    echo "✅ .env created"
else
    echo "✅ .env already exists"
    cat "$AGENT_DIR/.env"
fi

# ==========================================
# 6️⃣ CREATE SYSTEMD SERVICE
# ==========================================
echo "🔧 Setting up systemd service..."

PYTHON_VENV_BIN="$VENV_DIR/bin/python"

cat > "/etc/systemd/system/${SERVICE_NAME}.service" << EOF
[Unit]
Description=GHOST CMD Agent
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$AGENT_DIR
EnvironmentFile=$AGENT_DIR/.env
ExecStart=$PYTHON_VENV_BIN $AGENT_DIR/agent.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload
echo "✅ Systemd service created"

# ==========================================
# 7️⃣ CREATE DIRECTORIES
# ==========================================
echo "📁 Creating required directories..."
mkdir -p "$AGENT_DIR/chrome_profiles"
mkdir -p "$AGENT_DIR/logs"
chmod -R 755 "$AGENT_DIR"
echo "✅ Directories ready"

# ==========================================
# 8️⃣ START/RESTART SERVICE
# ==========================================
echo "🚀 Starting agent service..."

if systemctl is-active --quiet $SERVICE_NAME; then
    echo "🔄 Restarting $SERVICE_NAME..."
    systemctl restart $SERVICE_NAME
else
    echo "▶️ Starting $SERVICE_NAME..."
    systemctl start $SERVICE_NAME
    systemctl enable $SERVICE_NAME
fi

# Wait untuk service start
sleep 2

# Check status
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "✅ Service is running!"
else
    echo "⚠️ Service might still be starting, check with: sudo systemctl status $SERVICE_NAME"
fi

# ==========================================
# 9️⃣ DISPLAY INFO
# ==========================================
echo ""
echo "======================================"
echo "✅ GHOST CMD Agent Installed!"
echo "======================================"
echo ""
echo "📋 Commands:"
echo "  Start:    sudo systemctl start $SERVICE_NAME"
echo "  Stop:     sudo systemctl stop $SERVICE_NAME"
echo "  Restart:  sudo systemctl restart $SERVICE_NAME"
echo "  Status:   sudo systemctl status $SERVICE_NAME"
echo "  Logs:     sudo journalctl -u $SERVICE_NAME -f"
echo "  Update:   cd $AGENT_DIR && sudo bash install.sh update"
echo ""
echo "📊 Agent running on: http://localhost:7860"
echo "📡 Dashboard: $(grep DASHBOARD_URL $AGENT_DIR/.env | cut -d= -f2)"
echo ""
echo "🎯 Next step: Monitor logs dengan 'sudo journalctl -u $SERVICE_NAME -f'"
echo "======================================"
echo ""
echo "📝 Virtual Environment Info:"
echo "   Location: $VENV_DIR"
echo "   Python:   $PYTHON_VENV_BIN"
echo ""
