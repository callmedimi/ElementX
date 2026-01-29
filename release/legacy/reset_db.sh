#!/bin/bash
set -e

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Detect docker compose
get_docker_compose_cmd() {
    if docker compose version &> /dev/null; then
        echo "docker compose"
    elif command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    else
        echo "docker compose"
    fi
}

DOCKER_COMPOSE=$(get_docker_compose_cmd)

echo ""
warn "This will DELETE the existing database (homeserver.db)."
warn "All users and chat history will be lost."
read -p "Are you sure you want to continue? (y/N): " CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    log "Stopping Synapse..."
    $DOCKER_COMPOSE down

    if [ -f "data/homeserver.db" ]; then
        log "Removing database..."
        rm data/homeserver.db
        log "Database removed."
    else
        warn "data/homeserver.db not found, nothing to delete."
    fi

    log "Starting Synapse..."
    $DOCKER_COMPOSE up -d

    echo ""
    log "Reset complete!"
    echo "You can now run ./configure.sh to recreate your admin user."
else
    log "Operation cancelled."
fi
