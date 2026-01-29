#!/bin/bash
set -e

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

# --- Menu ---
while true; do
    echo ""
    echo "=========================================="
    echo "  Element X Server Management"
    echo "=========================================="
    echo "1. Create New User"
    echo "2. View Synapse Logs"
    echo "3. Restart Synapse"
    echo "4. Check Server Status"
    echo "5. Toggle Public Registration"
    echo "6. Exit"
    echo ""
    read -p "Select an option [1-6]: " OPTION

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
                err "Config file not found in data/homeserver.yaml"
            fi
            
            CURRENT_STATE=$(grep "enable_registration:" data/homeserver.yaml | awk '{print $2}')
            if [ "$CURRENT_STATE" == "true" ]; then
                log "Disabling registration..."
                sed -i "s/enable_registration: true/enable_registration: false/" data/homeserver.yaml
                log "Registration DISABLED."
            else
                log "Enabling registration..."
                sed -i "s/enable_registration: false/enable_registration: true/" data/homeserver.yaml
                log "Registration ENABLED."
            fi
            
            log "Restarting Synapse to apply changes..."
            $DOCKER_COMPOSE restart synapse
            ;;
        6)
            log "Exiting..."
            exit 0
            ;;
        *)
            warn "Invalid option."
            ;;
    esac
done
