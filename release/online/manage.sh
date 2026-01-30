#!/bin/bash
set -e

# Change to the script's directory to ensure relative paths work
cd "$(dirname "$(readlink -f "$0")")" 2>/dev/null || cd "$(dirname "$0")"

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

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

# Function to fix permissions (Critical for Synapse)
fix_permissions() {
    if [ -d "data" ]; then
        log "Fixing data directory permissions (UID 991)..."
        chown -R 991:991 data
        find data -type d -exec chmod 755 {} \;
        find data -type f -exec chmod 644 {} \;
    fi
}

# --- Menu ---
while true; do
    echo ""
    echo "=========================================="
    echo "  Element X Server Management (v3.3)"
    echo "=========================================="
    echo "1. Create New User"
    echo "2. View Synapse Logs"
    echo "3. Restart Synapse"
    echo "4. Check Server Status"
    echo "5. Toggle Public Registration"
    echo "6. Quick Fix: Repair Config & Permissions"
    echo "7. Exit"
    echo ""
    read -p "Select an option [1-7]: " OPTION

    case $OPTION in
        1)
            echo ""
            log "Creating new user..."
            read -p "Username: " USERNAME
            $DOCKER_COMPOSE exec synapse register_new_matrix_user \
                -c /data/homeserver.yaml \
                -u "$USERNAME" \
                http://localhost:8008
            ;;
        2)
            echo ""
            log "Showing logs (Ctrl+C to exit)..."
            $DOCKER_COMPOSE logs -f synapse
            ;;
        3)
            echo ""
            log "Restarting Synapse..."
            fix_permissions
            $DOCKER_COMPOSE restart synapse
            log "Restart complete."
            ;;
        4)
            echo ""
            $DOCKER_COMPOSE ps
            ;;
        5)
            echo ""
            if [ ! -f "data/homeserver.yaml" ]; then
                err "Config file not found in $(pwd)/data/homeserver.yaml"
            fi
            
            # Simple, robust detection
            IS_ENABLED=false
            if grep -Fq "enable_registration: true" data/homeserver.yaml; then
               IS_ENABLED=true
            fi
            
            # Clean up old settings (Both new and old styles)
            sed -i "/enable_registration:/d" data/homeserver.yaml
            sed -i "/enable_registration_without_verification:/d" data/homeserver.yaml
            
            if [ "$IS_ENABLED" = true ]; then
                log "Current status: ENABLED. Disabling..."
                echo "" >> data/homeserver.yaml
                echo "enable_registration: false" >> data/homeserver.yaml
                echo "enable_registration_without_verification: false" >> data/homeserver.yaml
            else
                log "Current status: DISABLED. Enabling..."
                echo "" >> data/homeserver.yaml
                echo "enable_registration: true" >> data/homeserver.yaml
                echo "enable_registration_without_verification: true" >> data/homeserver.yaml
            fi
            
            # Fix perms and restart
            fix_permissions
            
            log "Configuration updated. Restarting..."
            $DOCKER_COMPOSE stop synapse
            $DOCKER_COMPOSE rm -f synapse
            $DOCKER_COMPOSE up -d synapse
            
            log "Done. Wait 20s for startup."
            ;;
        6)
            echo ""
            log "Attempting to fix configuration & permissions..."
            if [ ! -f "data/homeserver.yaml" ]; then
                err "Config file not found!"
            fi
            
            # Backup
            cp data/homeserver.yaml data/homeserver.yaml.bak_$(date +%s)
            
            # Remove bad lines
            sed -i "/enable_registration:/d" data/homeserver.yaml
            sed -i "/enable_registration_without_verification:/d" data/homeserver.yaml
            
            # Append correct config
            echo "" >> data/homeserver.yaml
            echo "enable_registration: true" >> data/homeserver.yaml
            echo "enable_registration_without_verification: true" >> data/homeserver.yaml
            
            # Ensure shared secret exists
            if ! grep -q "registration_shared_secret:" data/homeserver.yaml; then
                SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
                echo "registration_shared_secret: \"$SECRET\"" >> data/homeserver.yaml
            fi
            
            # CRITICAL: Fix permissions
            fix_permissions
            
            log "Repair applied. Force-restarting Synapse..."
            $DOCKER_COMPOSE stop synapse
            $DOCKER_COMPOSE rm -f synapse
            $DOCKER_COMPOSE up -d synapse
            log "Repair complete. Please wait 30 seconds for boot."
            ;;
        7)
            log "Exiting..."
            exit 0
            ;;
        *)
            warn "Invalid option."
            ;;
    esac
done
