# ⬆️ Upgrade & Migration Guide

---

## ✅ Scenario 1: Upgrade Synapse Version

You already have Element X installed and want Synapse to update to the latest version.

```bash
# Go to your installation folder
cd /path/to/your/installation

# Backup first (always!)
sudo tar -czf backup-$(date +%Y%m%d).tar.gz data/

# Pull latest Synapse image and restart
docker compose pull synapse
docker compose down
docker compose up -d

# Confirm the new version
docker compose exec synapse /start.py --version
```

---

## 🚚 Scenario 2: Migrate from an Old Synapse Installation

You have an existing Synapse server (not using this package) and want to move your data over.

### Step 1 — Back up your old server
```bash
sudo systemctl stop matrix-synapse
# or: docker compose down

sudo tar -czf synapse-backup-$(date +%Y%m%d).tar.gz /path/to/old/synapse
```

### Step 2 — Copy your data files
```bash
mkdir -p data
cp /path/to/old/homeserver.yaml  data/homeserver.yaml
cp /path/to/old/homeserver.db    data/homeserver.db   # SQLite only
cp /path/to/old/signing.key      data/signing.key
cp -r /path/to/old/media_store   data/media_store
```

### Step 3 — Run the installer
```bash
chmod +x install_server.sh
sudo ./install_server.sh
```

The script automatically handles Nginx, Docker, permissions, and the Admin UI.

### Step 4 — Verify
```bash
docker compose ps                        # All containers should be "Up"
curl http://localhost/_matrix/client/versions   # Should return JSON
# Open browser: http://YOUR_SERVER_IP/admin
```

### Step 5 — Check your data
- ✅ Log in with your old admin credentials
- ✅ Verify users and rooms are intact
- ✅ Test sending a message

### Rollback (if something goes wrong)
```bash
docker compose down
sudo tar -xzf synapse-backup-YYYYMMDD.tar.gz -C /
sudo systemctl start matrix-synapse
```

---

## ⚠️ Notes

**Database**
- **SQLite**: Direct copy works fine.
- **PostgreSQL**: Make sure connection details in `homeserver.yaml` are correct before running the installer.

**Ports**
- Old Synapse: Port `8008` directly
- New setup: Port `80` / `443` via Nginx — update your firewall if needed.

**SSL / HTTPS**
- The installer will ask if you want to set up HTTPS via Certbot. Just say yes and enter your domain.

**Specific Synapse version**
Edit `docker-compose.yml` if you need a specific version:
```yaml
image: matrixdotorg/synapse:v1.100.0
```

---

## 🆘 Common Errors

| Problem | Fix |
|---|---|
| Synapse keeps restarting | Run `manage.sh` → Option 6 (Quick Fix) |
| Admin UI blank | Check `docker compose logs nginx` |
| 502 Bad Gateway | Synapse isn't up yet — wait 30s or check logs |
| Config error on start | `docker logs synapse` for the exact message |

---

*made with ❤️ by dimi*
