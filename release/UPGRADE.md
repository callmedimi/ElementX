# Upgrading Element X Server

This guide covers two upgrade scenarios:
1. **Version Upgrade**: Updating Synapse to a newer version
2. **Migration**: Moving from an existing Synapse installation to this package

---

## 🔄 Scenario 1: Version Upgrade (Existing Installation)

If you already have this package installed and want to upgrade Synapse:

### Quick Upgrade
```bash
# Navigate to your installation
cd /path/to/your/installation

# Pull latest Synapse image
docker-compose pull synapse
# or: docker compose pull synapse

# Restart with new version
docker-compose down
docker-compose up -d

# Verify version
docker-compose exec synapse /start.py --version
```

### Upgrade with Backup
```bash
# 1. Backup your data
sudo tar -czf backup-$(date +%Y%m%d).tar.gz data/

# 2. Stop services
docker-compose down

# 3. Pull latest images
docker-compose pull

# 4. Start services
docker-compose up -d

# 5. Check logs
docker-compose logs -f synapse

# 6. Verify Admin UI
curl http://localhost/admin
```

---

## 🚚 Scenario 2: Migration (From Old Installation)

If you have an existing Synapse server and want to migrate to this package:

### Prerequisites
- Existing server data (`homeserver.yaml`, `homeserver.db`, `media_store`, `signing.key`)
- The `release/online` OR `release/offline` folder from this project
- Root/sudo access on the server

### Migration Steps

#### 1. Backup Current Installation
```bash
# Stop your current server
sudo systemctl stop matrix-synapse
# or: docker-compose down

# Create full backup
sudo tar -czf synapse-backup-$(date +%Y%m%d).tar.gz /path/to/current/synapse
```

#### 2. Prepare New Installation
```bash
# Transfer the release folder to your server
# Choose online/ or offline/ based on your needs

# Navigate to the folder
cd release/online  # or release/offline
```

#### 3. Copy Your Data
```bash
# Create data directory if it doesn't exist
mkdir -p data

# Copy your existing files
cp /path/to/old/homeserver.yaml data/homeserver.yaml
cp /path/to/old/homeserver.db data/homeserver.db  # if using SQLite
cp /path/to/old/signing.key data/signing.key
cp -r /path/to/old/media_store data/media_store
```

#### 4. Update Configuration
The installation script will automatically update your `homeserver.yaml` to:
- Listen on `0.0.0.0` (required for Nginx proxy)
- Enable Admin API
- Configure proper ports

**Important**: Review `data/homeserver.yaml` after installation to ensure your custom settings are preserved.

#### 5. Run Installation
```bash
# Make script executable
chmod +x install_server.sh

# Run installation
sudo ./install_server.sh
```

The script will:
- ✅ Install Docker (if not present)
- ✅ Configure Iranian mirrors
- ✅ Set up Nginx reverse proxy
- ✅ Deploy Synapse Admin UI
- ✅ Update homeserver.yaml for proxy compatibility
- ✅ Start all services

#### 6. Verify Migration
```bash
# Check services are running
docker-compose ps

# Check Synapse logs
docker-compose logs synapse

# Test Matrix API
curl http://localhost/_matrix/client/versions

# Access Admin UI
# Open browser: http://YOUR_SERVER_IP/admin
```

#### 7. Test Your Server
1. **Login to Admin UI**: Use your existing admin credentials
2. **Check users**: Verify all users are present
3. **Test messaging**: Send a test message
4. **Check media**: Verify uploaded files work
5. **Federation**: Test federation if enabled

### Rollback (If Needed)
```bash
# Stop new installation
docker-compose down

# Restore from backup
sudo tar -xzf synapse-backup-YYYYMMDD.tar.gz -C /

# Restart old installation
sudo systemctl start matrix-synapse
```

---

## ⚠️ Important Notes

### Database Compatibility
- **SQLite**: Direct copy works
- **PostgreSQL**: Ensure connection details in `homeserver.yaml` are correct

### Version Compatibility
- This package uses `matrixdotorg/synapse:latest`
- To use a specific version, edit `docker-compose.yml`:
  ```yaml
  image: matrixdotorg/synapse:v1.95.0  # specific version
  ```

### Port Changes
- Old installation: Port 8008
- New installation: Port 80 (Nginx proxy)
- Update your firewall rules accordingly

### Federation
If you use federation, ensure:
- Your domain DNS points to the new server
- Port 8448 is open (if using federation)
- `.well-known` delegation is configured

---

## 🆘 Troubleshooting

### Admin UI Not Loading
```bash
# Check Nginx is running
docker-compose ps nginx

# Check Nginx logs
docker-compose logs nginx
```

### Synapse Not Starting
```bash
# Check logs
docker-compose logs synapse

# Verify homeserver.yaml syntax
docker-compose exec synapse python -m synapse.config -c /data/homeserver.yaml
```

### Database Connection Issues
```bash
# For PostgreSQL, verify connection
docker-compose exec synapse psql -h db_host -U db_user -d synapse

# Check homeserver.yaml database section
cat data/homeserver.yaml | grep -A 10 "database:"
```

---

## 📞 Support

- **Matrix Documentation**: https://matrix-org.github.io/synapse/latest/
- **Upgrade Guide**: https://matrix-org.github.io/synapse/latest/upgrade.html
- **Docker Compose**: https://docs.docker.com/compose/

---

*Always backup before upgrading!*

