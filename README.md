# 🚀 GHOST CMD - Multi-Agent Control Panel

**GHOST CMD** adalah sistem kontrol panel terpusat untuk mengelola multiple agent/bot secara realtime dengan local TXT storage dan Cloudflare tunnel.

## 📊 Arsitektur

```
┌─────────────────────────────────────────┐
│     DASHBOARD (Server Utama - 1x)       │
│  - Port: 5000                           │
│  - URL: https://dashboard.jujulefek.qzz.io │
│  - Storage: JSON files (./data/slots/)  │
│  - Slot Capacity: 192 agents            │
└─────────────────────────────────────────┘
         ↑           ↑           ↑
    Agent 1    Agent 2    Agent N
    Port 7860  Port 7860  Port 7860
    (Tunnel 1) (Tunnel 2) (Tunnel N)
```

---

## 🎯 QUICK START

### **STEP 1: Install Dashboard (Server Utama - 1 kali)**

```bash
# Clone repo
git clone https://github.com/umnodqib/ghost-cmd.git
cd ghost-cmd/dashboard

# Jalankan installer (perlu root)
sudo bash install.sh

# Follow prompts:
# - Cloudflare authentication
# - Create tunnel nama: ghost-dashboard
# - Domain: dashboard.jujulefek.qzz.io
```

✅ **Output Dashboard:**
- Local: `http://localhost:5000`
- Public: `https://dashboard.jujulefek.qzz.io` (via tunnel)
- Auth Key: `GHOST_SECRET_2026`

---

### **STEP 2: Install Agent (Di Setiap Server - Bisa Berapa Kali)**

```bash
# Clone repo di server agent
git clone https://github.com/umnodqib/ghost-cmd.git
cd ghost-cmd/agent

# Jalankan installer
sudo bash install.sh

# Follow prompts:
# - Dashboard URL: https://dashboard.jujulefek.qzz.io
# - Create tunnel? (y/n)
# - If yes:
#   - Cloudflare auth
#   - Tunnel name: ghost-agent-01 (berbeda untuk setiap agent)
#   - Public hostname: agent-01.yourdomain.com
```

✅ **Output Agent:**
- Local: `http://localhost:7860`
- Public: `https://agent-01.yourdomain.com` (via tunnel)
- Auto register ke dashboard
- Auto pull email.txt & link.txt dari dashboard
- Auto run login.py & loop.py

---

## 📋 WORKFLOW LENGKAP

### **1. Dashboard Startup**

```
Dashboard start
  ↓
Port 5000 berjalan
  ↓
Cloudflare tunnel aktif
  ↓
Siap menerima agent registrasi
```

### **2. Agent Startup**

```
Agent script start (agent.py)
  ↓
Register ke dashboard (POST /api/register)
  ↓
Dashboard assign slot ID (1-192)
  ↓
Agent terima email.txt & link.txt
  ↓
Auto run login.py (create chrome profiles)
  ↓
Auto run loop.py (click links in loop)
  ↓
Report status setiap aksi
```

### **3. Dashboard Control**

Kamu bisa:

- **View Slots**: Lihat status semua agent (online/offline/busy)
- **Edit Slot**: Ubah email & links untuk slot tertentu
- **Send Commands**:
  - `LOGIN`: Jalankan login.py
  - `LOOP`: Jalankan loop.py
  - `STOP`: Matikan proses
  - `SYNC`: Clean RAM
- **Bulk Upload**: Upload email & links ke multiple slots sekaligus
- **Mass Commands**: Kirim command ke multiple slots sekaligus
- **View Logs**: Lihat log per slot

---

## 🛠️ COMMANDS

### **Dashboard**

```bash
# Start dashboard
systemctl start ghost-dashboard
systemctl start ghost-tunnel

# View logs
journalctl -u ghost-dashboard -f
journalctl -u ghost-tunnel -f

# Restart
systemctl restart ghost-dashboard
```

### **Agent**

```bash
# Start agent
systemctl start ghost-agent
systemctl start ghost-agent-tunnel  # if created

# View logs
journalctl -u ghost-agent -f
journalctl -u ghost-agent-tunnel -f  # if created

# Restart
systemctl restart ghost-agent
```

---

## 📁 FILE STRUCTURE

### **Dashboard**

```
dashboard/
├── app.py                    # Flask backend
├── requirements.txt          # Python dependencies
├── install.sh              # Installation script
├── templates/
│   └── index.html          # Dashboard UI
├── data/
│   ├── slots/              # Slot JSON files (auto-created)
│   │   ├── slot_1.json
│   │   ├── slot_2.json
│   │   └── ...
│   └── logs/               # Agent logs (auto-created)
│       ├── slot_1.log
│       ├── slot_2.log
│       └── ...
└── config.yaml             # Cloudflare tunnel config
```

### **Agent**

```
agent/
├── agent.py                # Main agent controller
├── login.py               # Email login automation
├── loop.py                # Link click loop
├── modul_bot.py          # Selenium bot module
├── requirements.txt       # Python dependencies
├── install.sh            # Installation script
├── chrome_profiles/      # Chrome user profiles (auto-created)
├── email.txt             # Email list (from dashboard)
├── link.txt              # Link list (from dashboard)
├── mapping_profil.txt    # Profile mapping (auto-created)
├── bot_log.txt           # Agent logs
├── monitor.json          # Loop status (auto-created)
└── agent-tunnel.yaml     # Cloudflare tunnel config (optional)
```

---

## 🔌 API ENDPOINTS

### **Dashboard**

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/status` | GET | Dashboard status (online/busy/data count) |
| `/api/slots` | GET | All slots data |
| `/api/slot/<id>` | GET/POST | Get/update specific slot |
| `/api/register` | POST | Agent registration |
| `/api/report` | POST | Agent status report |
| `/api/ack` | POST | Acknowledge registration |
| `/api/command/<slot>/<cmd>` | POST | Send command to agent |
| `/api/logs/<slot>` | GET | Get slot logs |
| `/api/bulk/upload` | POST | Bulk upload data |
| `/api/mass/command/<cmd>` | POST | Mass command to multiple slots |

### **Agent**

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/` | GET | Agent status page |
| `/status` | GET | Current state (IDLE/BUSY_LOGIN/BUSY_LOOP) |
| `/start/login` | POST | Trigger login.py |
| `/start/loop` | POST | Trigger loop.py |
| `/stop` | POST | Stop all processes |
| `/clean_ram` | POST | Clean system memory |
| `/logs` | GET | Agent logs |

---

## 📊 Data Format

### **Slot JSON** (`data/slots/slot_N.json`)

```json
{
  "id": 1,
  "status": "🔌 WS CONNECTED",
  "ip": "35.229.178.87",
  "emails": 2,
  "links": 5,
  "isLooping": true,
  "isOffline": false,
  "lastUpdate": "2026-06-22T10:30:00",
  "agent_url": "http://localhost:7860",
  "emails_file": "user1@gmail.com\nuser2@gmail.com",
  "links_file": "link1.com\nlink2.com\n..."
}
```

### **Email/Link Format**

```
email.txt:
user1@gmail.com
user2@yahoo.com
user3@outlook.com

link.txt:
https://example1.com
https://example2.com
https://example3.com
```

---

## 🔐 Security

- **Auth Key**: `GHOST_SECRET_2026` (set di environment)
- **Header**: Semua request perlu `X-Auth-Key: GHOST_SECRET_2026`
- **Local Storage**: Data hanya tersimpan di TXT/JSON, bukan database
- **Tunnel**: Cloudflare tunnel aman dan otomatis

---

## 🚨 Troubleshooting

### **Agent tidak muncul di dashboard**

```bash
# Check agent logs
journalctl -u ghost-agent -f

# Pastikan dashboard URL benar
grep DASHBOARD_URL /opt/ghost-cmd/agent/.env

# Manual test registration
curl -X POST https://dashboard.jujulefek.qzz.io/api/register \
  -H "X-Auth-Key: GHOST_SECRET_2026" \
  -H "Content-Type: application/json" \
  -d '{"url":"http://localhost:7860","ip":"1.2.3.4"}'
```

### **Chrome tidak jalan**

```bash
# Check Chrome installation
google-chrome --version

# Install jika belum
sudo apt-get install -y google-chrome-stable

# Check Xvfb
ps aux | grep Xvfb
```

### **Tunnel tidak aktif**

```bash
# Check tunnel status
journalctl -u ghost-dashboard-tunnel -f

# Manual test tunnel
cloudflared tunnel --config config.yaml run
```

---

## 📈 Performance

- **Max Agents**: 192 per dashboard
- **Concurrent Tasks**: Unlimited (limited by server resources)
- **Memory**: ~50MB per agent (Chrome profiles)
- **Network**: Tunnel encryption overhead ~5%
- **Data Storage**: ~1KB per slot

---

## 🔄 Update

```bash
# Dashboard
cd dashboard
git pull
systemctl restart ghost-dashboard

# Agent
cd ../agent
git pull
systemctl restart ghost-agent
```

---

## ❓ FAQ

**Q: Bisakah dashboard dan agent di server sama?**
A: Ya, bisa. Tapi disarankan terpisah untuk performa lebih baik.

**Q: Berapa max slots?**
A: 192 slots per dashboard (configurable di `app.py`).

**Q: Apakah data aman?**
A: Ya, data tersimpan local di file JSON. Tidak ada database eksternal.

**Q: Bisa pakai database MySQL?**
A: Bisa, tapi saat ini hanya support TXT/JSON. Custom update diperlukan.

**Q: Cara backup data?**
A: Copy folder `dashboard/data/slots/` dan `dashboard/data/logs/`.

---

## 📞 Support

Untuk masalah:

1. Check logs: `journalctl -u ghost-* -f`
2. Check network: `curl -v https://dashboard.jujulefek.qzz.io`
3. Check Cloudflare: `cloudflared tunnel info`

---

## 📝 License

Private - DO NOT DISTRIBUTE

---

**Created by**: DOTAJA  
**Version**: 1.0  
**Last Updated**: 2026-06-22
