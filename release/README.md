# Element X Server & Admin Panel

> 🚀 Self-hosted Matrix chat server with a bilingual registration page, web admin panel, and one-command setup. Made for both online **and** offline servers.

[🇮🇷 فارسی](./README_FA.md) · [⬆️ Upgrade Guide](./UPGRADE.md)

---

## ✨ What You Get

| Feature | Details |
|---|---|
| 💬 Matrix Synapse | Latest homeserver |
| 🛡️ Nginx Proxy | HTTPS/SSL via Certbot |
| 🖥️ Admin Panel | Web UI at `/admin` |
| 📋 Registration Page | Bilingual (EN/FA) at `/` |
| 🔛 Registration Toggle | 1-click on/off via `manage.sh` |
| 📦 Online & Offline | Supports air-gapped servers |

---

## ⚡ Install in 1 Command

### 🌐 Online Server (has internet)
```bash
cd /tmp && curl -fsSL https://github.com/callmedimi/ElementX/archive/refs/heads/main.tar.gz | tar -xz && cd ElementX-main/release/online && sudo ./install_server.sh
```

### 🔌 Offline / Air-gapped Server
> **On your PC first (requires internet):**
```bash
# Download the repo, then run:
cd release/offline
# Windows:
prepare_assets.bat
# Linux/Mac:
bash prepare_assets.sh
```
> Then transfer the full `offline/` folder to your server:
```bash
sudo ./install_server.sh
```

---

## ⚙️ After Installation

| URL | What it is |
|---|---|
| `https://yourdomain.com/register` | Registration page for new users |
| `https://yourdomain.com/admin` | Admin panel (manage users & rooms) |
| `data/homeserver.yaml` | Synapse config file |


---

## 🛠️ Managing Your Server

Run on your server inside the installation folder:
```bash
sudo ./manage.sh
```

| Option | Action |
|---|---|
| 1 | Create a new user manually |
| 2 | View live Synapse logs |
| 3 | Restart Synapse |
| 4 | Check container status |
| 5 | Toggle public registration ON/OFF |
| 6 | ⚠️ Quick Fix – repair config & permissions |

---

## 🆘 Troubleshooting

**Server won't start / 502 error?**
- Run `manage.sh` → choose **Option 6 (Quick Fix)**.

**Registration page still shows form when disabled?**
- Run `manage.sh` → **Option 5** to toggle. It auto-updates the page.

**Synapse config got corrupted?**
- Option 6 takes a backup and restores a working config automatically.

---

*made with ❤️ by dimi*
