# Element X Server Project

A complete, self-hosted Matrix Synapse server solution with built-in Admin Dashboard.  
Designed for easy deployment in both **Online** and **Offline (Air-gapped)** environments.

[FA **فارسی**](./release/README_FA.md) | [📦 **UPGRADE / راهنمای آپدیت**](./release/UPGRADE.md)
---

## 📂 Project Structure

```
ElementX/
├── README.md                    ← You are here (Development documentation)
├── deploy.bat                   ← [DEV] Bundle preparation script (Windows)
├── install_server.sh            ← [DEV] Master installation script template
├── configure.sh                 ← [DEV] Configuration wizard template
├── verify.bat                   ← [DEV] Bundle verification script
├── download_admin.bat           ← [DEV] Download Synapse Admin UI
├── synapse-admin.tar.gz         ← [DEV] Synapse Admin UI archive
│
└── release/                     ← 📦 DEPLOYMENT PACKAGE (Transfer this to server)
    ├── README.md                ← Installation guide
    ├── README_FA.md             ← Persian installation guide
    ├── UPGRADE.md               ← Upgrade guide for existing servers
    │
    ├── online/                  ← For servers with internet
    │   ├── install_server.sh
    │   └── docker-compose.yml
    │
    ├── offline/                 ← For air-gapped servers
    │   ├── install_server.sh
    │   ├── docker-compose.yml
    │   ├── prepare_assets.bat   ← Run on PC with internet
    │   └── prepare_assets.sh
    │
    ├── legacy/                  ← Old scripts (archived)
    └── synapse/                 ← [OPTIONAL] Synapse source code
```

---

## 🎯 Quick Start

### For End Users (Server Deployment)

**You only need the `release/` folder!**

1. **Choose your deployment type:**
   - **Online**: Server has internet → Use `release/online/`
   - **Offline**: Air-gapped server → Use `release/offline/`

2. **Follow the instructions in:**
   - [`release/README.md`](./release/README.md) (English)
   - [`release/README_FA.md`](./release/README_FA.md) (فارسی)

### For Developers (Bundle Preparation)

**Files outside `release/` are for development only:**

1. **`deploy.bat`** - Prepares the release bundle (not needed on server)
2. **`install_server.sh`** - Template for the installation script
3. **`configure.sh`** - Template for the configuration wizard
4. **`verify.bat`** - Verifies bundle completeness
5. **`download_admin.bat`** - Downloads Synapse Admin UI

**To prepare a new bundle:**
```cmd
deploy.bat
```

This creates/updates the `release/` folder with all necessary files.

---

## ⚡ Quick Install Commands

For end users, one-line installation commands are available in the release README:

- **Online Mode**: [`release/README.md#quick-install`](./release/README.md#-quick-install-one-line-commands)
- **Offline Mode**: [`release/README.md#quick-install`](./release/README.md#-quick-install-one-line-commands)
- **Legacy Mode**: [`release/README.md#quick-install`](./release/README.md#-quick-install-one-line-commands)

These commands allow users to download and install with a single copy-paste command.

---

## 📋 File Organization

### 📁 Development Files (Outside `release/`)
**These files stay on your development machine - DO NOT transfer to server**

| File | Purpose | When to Use |
|------|---------|-------------|
| `deploy.bat` | Bundle preparation | After editing templates |
| `install_server.sh` | Installation template | Development only |
| `configure.sh` | Configuration template | Development only |
| `verify.bat` | Bundle verification | Before deployment |
| `download_admin.bat` | Download Admin UI | When updating Admin UI |
| `synapse-admin.tar.gz` | Admin UI archive | Auto-downloaded |

### 📦 Deployment Files (Inside `release/`)
**Transfer ONLY this folder to your server**

- `release/online/` - For servers with internet
- `release/offline/` - For air-gapped servers  
- `release/README.md` - Installation guide (English)
- `release/README_FA.md` - Installation guide (Persian)
- `release/UPGRADE.md` - Upgrade guide

### 🔄 Development Workflow

```
1. Edit templates (install_server.sh, configure.sh)
2. Run deploy.bat
3. Verify with verify.bat
4. Transfer release/ to server
```

### ✅ What to Transfer to Server

**For Online Deployment:**
```
release/online/
```

**For Offline Deployment:**
```
release/offline/
(after running prepare_assets.bat)
```

### ❌ What NOT to Transfer

- `deploy.bat` - Development tool
- `verify.bat` - Development tool
- `download_admin.bat` - Development tool
- Root-level `install_server.sh` - Template only
- Root-level `configure.sh` - Template only

---

## 🚀 Installation (Quick Reference)

### Online Installation
```bash
# On your server
cd release/online
sudo ./install_server.sh
```

### Offline Installation
```bash
# Step 1: On PC with internet (Windows)
cd release/offline
prepare_assets.bat

# Step 2: Transfer release/offline/ to server

# Step 3: On server
cd release/offline
sudo ./install_server.sh
```

---

## 🔄 Upgrade Process

### Upgrading Synapse Version

If you already have a running server and want to upgrade Synapse:

```bash
# On your server
cd /path/to/your/installation

# Pull latest Synapse image
docker-compose pull synapse
# or: docker compose pull synapse

# Restart with new version
docker-compose down
docker-compose up -d

# Check version
docker-compose exec synapse /start.py --version
```

### Migrating from Old Installation

If you have an existing Synapse server and want to migrate to this package:

**See [`release/UPGRADE.md`](./release/UPGRADE.md) for detailed instructions.**

**Quick steps:**
1. **Backup** your existing data
2. **Stop** your current server
3. **Copy** your data files to the new installation:
   - `homeserver.yaml` → `data/homeserver.yaml`
   - `homeserver.db` → `data/homeserver.db`
   - `signing.key` → `data/signing.key`
   - `media_store/` → `data/media_store/`
4. **Run** the new installation script
5. **Verify** everything works

---

## 📋 What Files Do You Need?

### ✅ For Server Deployment
**Only the `release/` folder:**
- Transfer `release/online/` OR `release/offline/` to your server
- Everything else stays on your development machine

### ✅ For Development
**Files outside `release/`:**
- `deploy.bat` - Bundle preparation
- `install_server.sh` - Installation template
- `configure.sh` - Configuration template
- `verify.bat` - Verification tool
- `download_admin.bat` - Admin UI downloader

---

## 🌐 Iranian Mirror Support

This installation uses **8 Iranian Ubuntu mirrors** for fast, reliable downloads:

1. IranServer - `mirror.iranserver.com`
2. Pishgaman - `ubuntu.pishgaman.net`
3. ArvanCloud - `mirror.arvancloud.ir`
4. ASIS - `ubuntu.asis.ai`
5. Parspack - `mirror.parspack.co`
6. HostIran - `mirror.hostiran.ir`
7. Yazd University - `mirror.yazd.ac.ir`
8. Rasanegar - `mirror.rasanegar.com`

**Docker Registry Mirrors:**
1. IranServer - `docker.iranserver.com`
2. MobinHost - `docker.mobinhost.com`
3. HamDocker - `hub.hamdocker.ir`
4. ArvanCloud - `docker.arvancloud.ir`

---

## 🔧 Features

- ✅ **Matrix Synapse** - Latest homeserver
- ✅ **Synapse Admin UI** - Web-based management
- ✅ **Nginx Reverse Proxy** - Secure access
- ✅ **Docker Compose** - Easy deployment
- ✅ **Iranian Mirrors** - Fast downloads
- ✅ **Offline Support** - Air-gapped deployment
- ✅ **Auto-configuration** - Interactive wizard
- ✅ **HTTPS Support** - Optional Caddy integration

---

## 📞 Support

- **Installation Issues**: Check `release/README.md`
- **Upgrade Questions**: See `release/UPGRADE.md`
- **Matrix Documentation**: https://matrix-org.github.io/synapse/latest/
- **Docker Documentation**: https://docs.docker.com/

---

## 📝 Development Workflow

1. **Edit templates**: Modify `install_server.sh`, `configure.sh`
2. **Run deploy.bat**: Updates `release/` folder
3. **Verify bundle**: Run `verify.bat`
4. **Test deployment**: Transfer `release/` to test server
5. **Commit changes**: Git commit the updated files

---

*Created for Element X Deployment with Iranian mirror support.*
