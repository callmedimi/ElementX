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

# Detect Docker Compose
get_docker_compose_cmd() {
    if docker compose version &> /dev/null; then echo "docker compose"; 
    elif command -v docker-compose &> /dev/null; then echo "docker-compose"; 
    else echo "docker compose"; fi
}
DOCKER_COMPOSE=$(get_docker_compose_cmd)

echo "=========================================="
echo "  Online Server Installation"
echo "=========================================="

# --- Step 1: Configuration ---
echo ""
info_current_ip=$(hostname -I | awk '{print $1}')
echo "Enter your server name (e.g. matrix.local or your IP: $info_current_ip)"
read -p "Server name: " SERVER_NAME
if [ -z "$SERVER_NAME" ]; then SERVER_NAME=$info_current_ip; fi

echo ""
read -p "Admin username: " ADMIN_USER
if [ -z "$ADMIN_USER" ]; then err "Username required"; fi

# --- Step 2: Download Assets ---
echo ""
log "Downloading Synapse Admin..."
mkdir -p data/synapse-admin
# Always get latest 0.11.1
curl -L -o synapse-admin.tar.gz https://github.com/Awesome-Technologies/synapse-admin/releases/download/0.11.1/synapse-admin-0.11.1.tar.gz

log "Extracting Synapse Admin..."
tar -xzf synapse-admin.tar.gz -C data/synapse-admin --strip-components=1
rm synapse-admin.tar.gz

# --- Step 3: Server Config ---
echo ""
log "Configuring Services..."

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

# --- SSL Setup (Certbot Standalone) ---
echo ""
read -p "Do you want to enable HTTPS via Certbot? (y/N): " ENABLE_SSL
if [[ "$ENABLE_SSL" =~ ^[Yy]$ ]]; then
    log "Setting up HTTPS via Certbot..."
    
    # Install certbot if not exists
    if ! command -v certbot &> /dev/null; then
        log "Installing certbot..."
        apt-get update && apt-get install -y certbot
    fi

    # Acquire certificate
    log "Acquiring certificate for $SERVER_NAME..."
    certbot certonly --standalone --agree-tos --register-unsafely-without-email -d "$SERVER_NAME"
    
    # SSL Paths
    SSL_CERT="/etc/letsencrypt/live/$SERVER_NAME/fullchain.pem"
    SSL_KEY="/etc/letsencrypt/live/$SERVER_NAME/privkey.pem"

    # Configure Nginx with SSL
    mkdir -p data/nginx/conf.d
    cat > data/nginx/conf.d/matrix.conf <<EOF
server {
    listen 80;
    server_name $SERVER_NAME;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $SERVER_NAME;

    ssl_certificate $SSL_CERT;
    ssl_certificate_key $SSL_KEY;

    location /admin {
        alias /var/www/synapse-admin;
        index index.html;
    }

    location / {
        proxy_pass http://synapse:8008;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Host \$host;
    }

    location /.well-known/matrix/client {
        return 200 '{"m.homeserver": {"base_url": "https://$SERVER_NAME"}}';
        add_header Content-Type application/json;
        add_header Access-Control-Allow-Origin *;
    }

    location /.well-known/matrix/server {
        return 200 '{"m.server": "$SERVER_NAME:443"}';
        add_header Content-Type application/json;
        add_header Access-Control-Allow-Origin *;
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
else
    # Configure Nginx without SSL
    mkdir -p data/nginx/conf.d
    cat > data/nginx/conf.d/matrix.conf <<EOF
server {
    listen 80;
    server_name $SERVER_NAME;

    location /admin {
        alias /var/www/synapse-admin;
        index index.html;
    }

    location / {
        proxy_pass http://synapse:8008;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Host \$host;
    }

    location /.well-known/matrix/client {
        return 200 '{"m.homeserver": {"base_url": "http://$SERVER_NAME"}}';
        add_header Content-Type application/json;
        add_header Access-Control-Allow-Origin *;
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
fi

# --- Step 4: Start ---
echo ""
log "Starting Services (Pulling images)..."
$DOCKER_COMPOSE up -d

echo ""
log "Waiting for Synapse to start..."
sleep 5
log "Creating admin user..."
$DOCKER_COMPOSE exec synapse register_new_matrix_user -c /data/homeserver.yaml -u "$ADMIN_USER" -a http://localhost:8008

echo ""
log "Installation Complete!"
log "Access: http://$SERVER_NAME/admin"
