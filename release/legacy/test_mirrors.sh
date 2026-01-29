#!/bin/bash
set -e

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; }

MIRRORS=(
    "docker.iranserver.com"
    "docker.arvancloud.ir"
    "hub.hamdocker.ir"
    "docker.mobinhost.com"
    "docker.isatic.ir"
)

log "Testing connectivity to Docker cache mirrors..."
log "Please wait..."

BEST_MIRROR=""

for mirror in "${MIRRORS[@]}"; do
    echo -n "Checking $mirror... "
    if curl --connect-timeout 3 -sI "https://$mirror/v2/" > /dev/null; then
        echo -e "${GREEN}OK${NC}"
        if [ -z "$BEST_MIRROR" ]; then
            BEST_MIRROR="$mirror"
        fi
    else
        echo -e "${RED}TIMEOUT/FAIL${NC}"
    fi
done

echo ""

if [ -n "$BEST_MIRROR" ]; then
    log "Found reachable mirror: $BEST_MIRROR"
    
    # Backup
    cp docker-compose.yml docker-compose.yml.bak
    
    # Update docker-compose.yml
    # Remove old commented out lines to clean up first (optional, but keeps it clean)
    # We just replace the current image line
    sed -i "s|image: .*/awesometech10/synapse-admin|image: $BEST_MIRROR/awesometech10/synapse-admin|" docker-compose.yml
    
    log "Updated docker-compose.yml to use $BEST_MIRROR"
    log "Trying to pull now..."
    docker compose pull synapse-admin
    docker compose up -d
else
    err "All mirrors failed. Check your network or DNS."
    warn "Ensure you have intranet access to at least one of these providers."
fi
