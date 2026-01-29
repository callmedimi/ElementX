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

# --- Checks ---
if [ "$EUID" -ne 0 ]; then
  err "Please run as root (sudo ./install_server.sh)"
fi

if [ ! -d "assets" ]; then
    err "'assets' directory not found. Did you run 'prepare_assets' on a connected machine?"
fi

# Detect Docker Compose
get_docker_compose_cmd() {
    if docker compose version &> /dev/null; then echo "docker compose"; 
    elif command -v docker-compose &> /dev/null; then echo "docker-compose"; 
    else echo "docker compose"; fi
}
DOCKER_COMPOSE=$(get_docker_compose_cmd)

# --- Step 1: Load Images ---
echo ""
log "Step 1: Loading Docker Images..."

if [ -f "assets/synapse_image.tar" ]; then
    log "Loading Synapse image..."
    docker load -i assets/synapse_image.tar
else
    warn "assets/synapse_image.tar missing!"
fi

if [ -f "assets/nginx_image.tar" ]; then
    log "Loading Nginx image..."
    docker load -i assets/nginx_image.tar
else
    warn "assets/nginx_image.tar missing!"
fi

# --- Step 2: Configuration Wizard ---
echo ""
echo "=========================================="
echo "  Offline Server Configuration"
echo "=========================================="

# Server Name
echo ""
info_current_ip=$(hostname -I | awk '{print $1}')
echo "Enter your server name (e.g. matrix.local or your IP: $info_current_ip)"
read -p "Server name: " SERVER_NAME
if [ -z "$SERVER_NAME" ]; then SERVER_NAME=$info_current_ip; fi

# Admin User
echo ""
read -p "Admin username: " ADMIN_USER
if [ -z "$ADMIN_USER" ]; then err "Username required"; fi

# HTTPS/Nginx Setup (Always Yes for this package as it's the intended method)
SETUP_HTTPS="y"

# --- Step 3: Deployment ---
echo ""
log "Deploying..."

# Stop existing
$DOCKER_COMPOSE down 2>/dev/null || true

# Generate Synapse Config
mkdir -p data
if [ ! -f "data/homeserver.yaml" ]; then
    log "Generating Synapse config..."
    $DOCKER_COMPOSE run --rm -e SYNAPSE_SERVER_NAME="$SERVER_NAME" -e SYNAPSE_REPORT_STATS=no synapse generate
    
    # Patch Config
    sed -i "s/^server_name:.*/server_name: \"$SERVER_NAME\"/" data/homeserver.yaml
    sed -i "s/^enable_registration:.*/enable_registration: false/" data/homeserver.yaml
fi

# Ensure connection allows Nginx proxy (required for Upgrade/Migration)
sed -i "s/bind_addresses: .*/bind_addresses: ['0.0.0.0']/" data/homeserver.yaml

# Configure Nginx
log "Configuring Nginx..."
mkdir -p data/nginx/conf.d
cat > data/nginx/conf.d/matrix.conf <<EOF
server {
    listen 80;
    server_name $SERVER_NAME;

    location /admin {
        alias /var/www/synapse-admin;
        index index.html;
    }

    location /_matrix {
        proxy_pass http://synapse:8008;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Host \$host;
        client_max_body_size 50M;
    }
    
    location /_synapse {
        proxy_pass http://synapse:8008;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Host \$host;
        client_max_body_size 50M;
    }
}
EOF

# Extract Admin Files
log "Extracting Synapse Admin..."
mkdir -p data/synapse-admin
if [ -f "assets/synapse-admin.tar.gz" ]; then
    tar -xzf assets/synapse-admin.tar.gz -C data/synapse-admin --strip-components=1
else
    warn "assets/synapse-admin.tar.gz missing!"
    echo "<h1>Error</h1><p>Admin files missing.</p>" > data/synapse-admin/index.html
fi

# Start Services
log "Starting services..."
$DOCKER_COMPOSE up -d

# Create User
echo ""
log "Waiting for Synapse to start..."
sleep 5
log "Creating admin user..."
$DOCKER_COMPOSE exec synapse register_new_matrix_user -c /data/homeserver.yaml -u "$ADMIN_USER" -a http://localhost:8008

echo ""
log "Installation Complete!"
log "Access: http://$SERVER_NAME/admin"
