#!/bin/bash
set -e

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./fix_dns.sh)"
  exit 1
fi

log "Backing up current resolv.conf..."
cp /etc/resolv.conf /etc/resolv.conf.bak

log "Configuring DNS Config (Shecan + Google)..."
# We modify /etc/resolv.conf directly. Note: systemd-resolved might overwrite this on reboot
# unless we unlink it, but this is a quick fix for the session.

rm -f /etc/resolv.conf
cat > /etc/resolv.conf <<EOF
nameserver 178.22.122.100
nameserver 185.51.200.2
nameserver 8.8.8.8
options timeout:2 attempts:3
EOF

log "DNS updated."
log "Testing connection to docker.io..."

if ping -c 3 registry-1.docker.io &> /dev/null; then
    log "Connection successful!"
else
    warn "Ping failed, but DNS resolution might still work. Try pulling now."
fi

log "Restarting Docker to pick up network changes..."
systemctl restart docker

log "Ready. Please try 'docker compose up -d' again."
