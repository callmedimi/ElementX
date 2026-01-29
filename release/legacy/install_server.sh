#!/bin/bash
set -e

# Metrix Home Server (Synapse) Auto-Installer (Docker Version)
# Usage: sudo ./install_server.sh

# --- Configuration ---
# All major Iranian Ubuntu mirrors for maximum redundancy
MIRROR_IRANSERVER="mirror.iranserver.com"
MIRROR_PISHGAMAN="ubuntu.pishgaman.net"
MIRROR_ARVANCLOUD="mirror.arvancloud.ir"
MIRROR_ASIS="ubuntu.asis.ai"
MIRROR_PARSPACK="mirror.parspack.co"
MIRROR_HOSTIRAN="mirror.hostiran.ir"
MIRROR_YAZD="mirror.yazd.ac.ir"
MIRROR_RASANEGAR="mirror.rasanegar.com"

# Docker registry mirrors
REGISTRY_IRANSERVER="https://docker.iranserver.com"
REGISTRY_MOBINHOST="https://docker.mobinhost.com"
REGISTRY_HAMDOCKER="https://hub.hamdocker.ir"
REGISTRY_ARVANCLOUD="https://docker.arvancloud.ir"

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- Docker Compose Compatibility ---
# Detect which docker compose command to use (V1 vs V2)
get_docker_compose_cmd() {
    if docker compose version &> /dev/null; then
        echo "docker compose"
    elif command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    else
        echo "docker compose"  # Default to V2 syntax
    fi
}

# --- Checks ---
if [ "$EUID" -ne 0 ]; then
  err "Please run as root (sudo ./install_server.sh)"
fi

if [ ! -f "docker-compose.yml" ]; then
  warn "docker-compose.yml not found in current directory. Creating default..."
  cat > docker-compose.yml <<EOF
version: '3.3'
services:
  synapse:
    image: matrixdotorg/synapse:latest
    container_name: synapse
    restart: unless-stopped
    ports:
      - 8008:8008
    volumes:
      - ./data:/data
    environment:
      - SYNAPSE_SERVER_NAME=matrix.local
      - SYNAPSE_REPORT_STATS=no
EOF
fi

# --- Step 1: Configure System Mirrors (APT) ---
log "Configuring APT to use Iranian mirrors with backups..."

# Set non-interactive mode to prevent prompts
export DEBIAN_FRONTEND=noninteractive

if [ ! -f /etc/apt/sources.list.bak ]; then
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
fi

CODENAME=$(lsb_release -cs || echo "jammy")

# Use ALL available Iranian mirrors for maximum redundancy
# Using [trusted=yes] to bypass signature verification issues with Iranian mirrors
# IMPORTANT: No international mirrors to ensure everything downloads from Iran
cat > /etc/apt/sources.list <<EOF
# Mirror 1: IranServer (Primary - most reliable)
deb [trusted=yes] http://${MIRROR_IRANSERVER}/ubuntu/ ${CODENAME} main restricted universe multiverse
deb [trusted=yes] http://${MIRROR_IRANSERVER}/ubuntu/ ${CODENAME}-updates main restricted universe multiverse
deb [trusted=yes] http://${MIRROR_IRANSERVER}/ubuntu/ ${CODENAME}-backports main restricted universe multiverse
deb [trusted=yes] http://${MIRROR_IRANSERVER}/ubuntu/ ${CODENAME}-security main restricted universe multiverse

# Mirror 2: Pishgaman
deb [trusted=yes] http://${MIRROR_PISHGAMAN}/ubuntu/ ${CODENAME} main restricted universe multiverse
deb [trusted=yes] http://${MIRROR_PISHGAMAN}/ubuntu/ ${CODENAME}-updates main restricted universe multiverse

# Mirror 3: ArvanCloud
deb [trusted=yes] http://${MIRROR_ARVANCLOUD}/ubuntu/ ${CODENAME} main restricted universe multiverse
deb [trusted=yes] http://${MIRROR_ARVANCLOUD}/ubuntu/ ${CODENAME}-updates main restricted universe multiverse

# Mirror 4: ASIS
deb [trusted=yes] http://${MIRROR_ASIS}/ubuntu/ ${CODENAME} main restricted universe multiverse
deb [trusted=yes] http://${MIRROR_ASIS}/ubuntu/ ${CODENAME}-updates main restricted universe multiverse

# Mirror 5: Parspack
deb [trusted=yes] http://${MIRROR_PARSPACK}/ubuntu/ ${CODENAME} main restricted universe multiverse

# Mirror 6: HostIran
deb [trusted=yes] http://${MIRROR_HOSTIRAN}/ubuntu/ ${CODENAME} main restricted universe multiverse

# Mirror 7: Yazd University
deb [trusted=yes] http://${MIRROR_YAZD}/ubuntu/ ${CODENAME} main restricted universe multiverse

# Mirror 8: Rasanegar
deb [trusted=yes] http://${MIRROR_RASANEGAR}/ubuntu/ ${CODENAME} main restricted universe multiverse
EOF

log "Updating APT cache with all Iranian mirrors..."
if ! apt-get update; then
    warn "APT update had some errors, but continuing with available packages..."
fi

# --- Step 2: Install Docker ---
if ! command -v docker &> /dev/null; then
    log "Docker not found. Installing from local mirrors..."
    
    # Try installing docker.io first (version 28.2.2-0ubuntu1~24.04.1 or similar)
    # This is available in main Ubuntu repos (mirrored by Iranian mirrors)
    # Using DEBIAN_FRONTEND=noninteractive to prevent prompts
    if DEBIAN_FRONTEND=noninteractive apt-get install -y -q docker.io docker-compose-plugin; then
        log "Docker installed successfully via docker.io package"
    else
        warn "docker.io installation failed, trying podman-docker as fallback..."
        # Fallback to podman-docker if docker.io fails
        if DEBIAN_FRONTEND=noninteractive apt-get install -y -q podman-docker; then
            log "Podman-docker installed successfully as Docker alternative"
        else
            err "Failed to install Docker or Podman. Please check your internet connection and mirrors."
        fi
    fi
else
    log "Docker is already installed ($(docker --version))"
fi

# Apply registry mirrors to daemon.json
log "Configuring Docker Registry Mirrors (all Iranian mirrors)..."
mkdir -p /etc/docker
DAEMON_JSON="/etc/docker/daemon.json"

# Create new daemon.json with all Iranian Docker registry mirrors
cat > "$DAEMON_JSON" <<EOF
{
  "registry-mirrors": [
    "$REGISTRY_IRANSERVER",
    "$REGISTRY_MOBINHOST",
    "$REGISTRY_HAMDOCKER",
    "$REGISTRY_ARVANCLOUD"
  ]
}
EOF

# Restart Docker to apply mirrors
systemctl daemon-reload
systemctl restart docker

# --- Step 3: Run Synapse ---
# Get the correct docker compose command
DOCKER_COMPOSE=$(get_docker_compose_cmd)
log "Using: $DOCKER_COMPOSE"

log "Generating Synapse Configuration..."
# We run a temporary container to generate the config file
$DOCKER_COMPOSE run --rm -e SYNAPSE_SERVER_NAME=matrix.local -e SYNAPSE_REPORT_STATS=no synapse generate || true

log "Starting Synapse Container..."
$DOCKER_COMPOSE up -d

log "Installation Complete!"
log "Synapse should be running on port 8008."
log "Check status: $DOCKER_COMPOSE ps"
log "Create admin user: $DOCKER_COMPOSE exec synapse register_new_matrix_user -c /data/homeserver.yaml http://localhost:8008"
