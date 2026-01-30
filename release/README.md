# Element X Server & Admin Panel

A complete, self-hosted Matrix Synapse server solution with a built-in Admin Dashboard.
Designed for easy deployment in both **Online** and **Offline (Air-gapped)** environments.

[🇮🇷 **فارسی (Persian)**](./README_FA.md) | [📦 **Upgrade Guide**](./UPGRADE.md)

## Features
*   **Matrix Synapse**: The reference homeserver implementation (latest version).
*   **Synapse Admin**: A beautiful web UI to manage users and rooms.
*   **Nginx Reverse Proxy**: Securely serving API, Admin UI, and Landing Page.
*   **SSL/HTTPS**: Built-in Certbot integration for automatic SSL setup.
*   **Registration Portal**: Responsive, bilingual landing page at `/register`.
*   **Dual Deployment**: Specialized packages for connected and disconnected servers.

---

## ⚡ Quick Install (One-Line Commands)

### 🌐 Online Installation
```bash
# Download and install (requires internet on server)
cd /tmp && curl -fsSL https://github.com/aliqajarian/ElementX/archive/refs/heads/main.tar.gz | tar -xz && cd ElementX-main/release/online && sudo ./install_server.sh
```

### 🔌 Offline Installation
```bash
# Step 1: On PC with internet (Windows)
curl -fsSL https://github.com/aliqajarian/ElementX/archive/refs/heads/main.tar.gz -o ElementX.tar.gz
tar -xzf ElementX.tar.gz
cd ElementX-main/release/offline
prepare_assets.bat

# Step 2: Transfer offline/ folder to server, then:
sudo ./install_server.sh
```

### 🗂️ Legacy Installation
```bash
# For existing installations or custom setups
cd /tmp && curl -fsSL https://github.com/aliqajarian/ElementX/archive/refs/heads/main.tar.gz | tar -xz && cd ElementX-main/release/legacy && sudo ./install_server.sh
```

---

## 📂 Installation Packages

### 1. 🌐 Online Installation
Use this if your server has internet access.
*   **Path**: [`online/`](./online)
*   **How to run**:
    1.  Copy the `online` folder to your server.
    2.  Run `sudo ./install_server.sh`.
    3.  Enter your domain/IP and admin user details when prompted.
    4.  The script will automatically download the Admin Panel and pull Docker images.

### 2. 🔌 Offline Installation
Use this if your server is air-gapped (No Internet).
*   **Path**: [`offline/`](./offline)
*   **Prerequisites**: A generic PC with internet to download assets.
*   **How to run**:
    1.  **On PC**: Run `prepare_assets.bat` (Windows) or `prepare_assets.sh` (Linux). This creates an `assets/` folder.
    2.  **Transfer**: Copy the `offline` folder (including the new `assets/`) to your server via USB or local network.
    3.  **On Server**: Run `sudo ./install_server.sh`. It will load the images from the files.

## ⚙️ Configuration
The server runs on standard ports (`80` and `443` if SSL is enabled).
*   **Landing Page**: `http://<domain>/register` (User registration & App links)
*   **Admin Panel**: `http://<domain>/admin` (Server management)
*   **Matrix Home**: `http://<domain>/` (Proxies to Synapse API)
*   **Config File**: `data/homeserver.yaml`

## 🛠️ Management
74: Use the `manage.sh` script to perform common tasks:
75: 1.  **Create User**: Manually register new Matrix users.
76: 2.  **View Logs**: Real-time Synapse log monitoring.
77: 3.  **Restart**: Quick service restart.
78: 4.  **Check Status**: Verify container health.
79: 5.  **Toggle Registration**: One-click enable/disable for public registration (v3.3 Smart Toggle).
80: 6.  **Quick Fix**: Automatically repair configuration permissions and boot loops.

---

## 🔄 Upgrading

### Version Upgrade (Existing Installation)

If you already have this package installed and want to upgrade Synapse:

```bash
# Navigate to your installation
cd /path/to/your/installation

# Pull latest Synapse image
docker-compose pull synapse

# Restart with new version
docker-compose down
docker-compose up -d

# Verify version
docker-compose exec synapse /start.py --version
```

### Migration (From Old Installation)

If you have an existing Synapse server and want to migrate to this package:

#### Prerequisites
- Existing server data (`homeserver.yaml`, `homeserver.db`, `media_store`, `signing.key`)
- Root/sudo access on the server

#### Migration Steps

**1. Backup Current Installation**
```bash
# Stop your current server
sudo systemctl stop matrix-synapse
# or: docker-compose down

# Create full backup
sudo tar -czf synapse-backup-$(date +%Y%m%d).tar.gz /path/to/current/synapse
```

**2. Prepare New Installation**
```bash
# Transfer the release folder to your server
# Navigate to online/ or offline/
cd release/online  # or release/offline
```

**3. Copy Your Data**
```bash
# Create data directory
mkdir -p data

# Copy your existing files
cp /path/to/old/homeserver.yaml data/homeserver.yaml
cp /path/to/old/homeserver.db data/homeserver.db  # if using SQLite
cp /path/to/old/signing.key data/signing.key
cp -r /path/to/old/media_store data/media_store
```

**4. Run Installation**
```bash
chmod +x install_server.sh
sudo ./install_server.sh
```

The script will automatically:
- ✅ Install Docker (if not present)
- ✅ Configure Iranian mirrors
- ✅ Set up Nginx reverse proxy
- ✅ Deploy Synapse Admin UI
- ✅ Update homeserver.yaml for proxy compatibility
- ✅ Start all services

**5. Verify Migration**
```bash
# Check services
docker-compose ps

# Test Matrix API
curl http://localhost/_matrix/client/versions

# Access Admin UI
# Browser: http://YOUR_SERVER_IP/admin
```

### Important Notes

**Database Compatibility**
- **SQLite**: Direct copy works
- **PostgreSQL**: Ensure connection details in `homeserver.yaml` are correct

**Port Changes**
- Old installation: Port 8008
- New installation: Port 80 (Nginx proxy)
- Update firewall rules accordingly

**Rollback (If Needed)**
```bash
docker-compose down
sudo tar -xzf synapse-backup-YYYYMMDD.tar.gz -C /
sudo systemctl start matrix-synapse
```

For detailed upgrade instructions, see [UPGRADE.md](./UPGRADE.md).

---
*Created for Element X Deployment.*
