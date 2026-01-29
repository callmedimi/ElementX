#!/bin/bash
set -e

# --- Colors ---
GREEN='\033[0;32m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./install_admin_online.sh)"
  exit 1
fi

log "Downloading Synapse Admin (Static)..."
# Create directory
mkdir -p data/synapse-admin

# Download
curl -L -o synapse-admin.tar.gz https://github.com/Awesome-Technologies/synapse-admin/releases/download/0.11.1/synapse-admin-0.11.1.tar.gz

log "Extracting files..."
tar -xzf synapse-admin.tar.gz -C data/synapse-admin --strip-components=1

# Clean up
rm synapse-admin.tar.gz

log "Files installed to data/synapse-admin"
echo ""
log "Now updating configuration..."
./configure.sh

echo ""
log "Done! Admin panel should be available at http://$(hostname -I | awk '{print $1}')/admin"
