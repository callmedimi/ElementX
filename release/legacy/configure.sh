#!/bin/bash
set -e

# Matrix Synapse Post-Installation Configuration Script
# This script configures your server for production use after installation

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
info() { echo -e "${BLUE}[?]${NC} $1"; }

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
  err "Please run as root (sudo ./configure.sh)"
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  err "Docker is not installed. Please run install_server.sh first!"
fi

if [ ! -f "docker-compose.yml" ]; then
  err "docker-compose.yml not found. Are you in the release directory?"
fi

echo ""
echo "=========================================="
echo "  Matrix Synapse Configuration Wizard"
echo "=========================================="
echo ""

# --- Step 1: Server Name Configuration ---
log "Step 1: Server Name Configuration"
echo ""
info "Enter your server name (domain or IP):"
echo "  - If you have a domain: matrix.yourdomain.com"
echo "  - If using IP only: $(hostname -I | awk '{print $1}')"
echo ""
read -p "Server name: " SERVER_NAME

if [ -z "$SERVER_NAME" ]; then
    SERVER_NAME=$(hostname -I | awk '{print $1}')
    warn "No input provided. Using IP: $SERVER_NAME"
fi

log "Server name set to: $SERVER_NAME"

# --- Step 2: Registration Settings ---
echo ""
log "Step 2: Registration Settings"
echo ""
info "Do you want to allow new user registrations?"
echo "  y = Anyone can register (not recommended for public servers)"
echo "  n = Only you can create users (recommended)"
echo ""
read -p "Enable registration? (y/N): " ENABLE_REG

if [[ "$ENABLE_REG" =~ ^[Yy]$ ]]; then
    REGISTRATION="true"
    log "Registration enabled"
else
    REGISTRATION="false"
    log "Registration disabled (recommended)"
fi

# --- Step 3: Create Admin User ---
echo ""
log "Step 3: Create Admin User"
echo ""
info "Let's create your admin account"
read -p "Admin username: " ADMIN_USER

if [ -z "$ADMIN_USER" ]; then
    err "Username cannot be empty"
fi

# --- Step 4: Firewall Configuration ---
echo ""
log "Step 4: Firewall Configuration"
echo ""
info "Configure firewall rules?"
read -p "Set up firewall? (Y/n): " SETUP_FW

# --- Step 5: HTTPS Setup ---
echo ""
log "Step 5: HTTPS/Domain Setup"
echo ""
info "Do you want to set up Nginx Reverse Proxy?"
read -p "Install Nginx? (y/N): " SETUP_HTTPS

# --- Apply Configuration ---
echo ""
log "Applying configuration..."

# Get the correct docker compose command
DOCKER_COMPOSE=$(get_docker_compose_cmd)
log "Using: $DOCKER_COMPOSE"

# Stop container
$DOCKER_COMPOSE down 2>/dev/null || true

# Wait for homeserver.yaml to exist
if [ ! -f "data/homeserver.yaml" ]; then
    warn "homeserver.yaml not found. Generating..."
    $DOCKER_COMPOSE run --rm -e SYNAPSE_SERVER_NAME="$SERVER_NAME" -e SYNAPSE_REPORT_STATS=no synapse generate
fi

# Backup original config
cp data/homeserver.yaml data/homeserver.yaml.bak
log "Backed up original config to homeserver.yaml.bak"

# Update server_name
sed -i "s/^server_name:.*/server_name: \"$SERVER_NAME\"/" data/homeserver.yaml
log "Updated server_name to: $SERVER_NAME"

# Update registration
if [ "$REGISTRATION" = "true" ]; then
    sed -i "s/^enable_registration:.*/enable_registration: true/" data/homeserver.yaml
    sed -i "s/^enable_registration_without_verification:.*/enable_registration_without_verification: true/" data/homeserver.yaml
else
    sed -i "s/^enable_registration:.*/enable_registration: false/" data/homeserver.yaml
fi
log "Registration setting applied"

# Ensure proper listener configuration
if ! grep -q "bind_addresses: \['0.0.0.0'\]" data/homeserver.yaml; then
    warn "Updating listener to bind to all interfaces..."
    sed -i "s/bind_addresses: .*/bind_addresses: ['0.0.0.0']/" data/homeserver.yaml
fi

# Start container
log "Starting Synapse..."
$DOCKER_COMPOSE up -d

# Wait for Synapse to start
log "Waiting for Synapse to start..."
sleep 5

# Create admin user
echo ""
log "Creating admin user: $ADMIN_USER"
$DOCKER_COMPOSE exec synapse register_new_matrix_user \
    -c /data/homeserver.yaml \
    -u "$ADMIN_USER" \
    -a \
    http://localhost:8008

# --- Firewall Setup ---
if [[ "$SETUP_FW" =~ ^[Yy]$ ]] || [ -z "$SETUP_FW" ]; then
    echo ""
    log "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow 8008/tcp comment 'Matrix Synapse'
        
        if [[ "$SETUP_HTTPS" =~ ^[Yy]$ ]]; then
            ufw allow 80/tcp comment 'HTTP'
            ufw allow 443/tcp comment 'HTTPS'
            ufw allow 8448/tcp comment 'Matrix Federation'
        fi
        
        # Always allow Synapse Admin
        ufw allow 8080/tcp comment 'Synapse Admin'
        
        ufw --force enable
        log "Firewall configured"
    else
        warn "UFW not found. Please configure firewall manually"
    fi
fi

# --- HTTPS/Reverse Proxy Setup with Nginx (Docker) ---
if [[ "$SETUP_HTTPS" =~ ^[Yy]$ ]]; then
    echo ""
    log "Configuring Nginx (Docker)..."
    
    # Create config directories
    mkdir -p data/nginx/conf.d
    mkdir -p data/synapse-admin

    # Generate Nginx Config
    log "Generating Nginx Config..."
    cat > data/nginx/conf.d/matrix.conf <<EOF
server {
    listen 80;
    server_name $SERVER_NAME;

    # Synapse Admin Panel (Static Files)
    location /admin {
        alias /var/www/synapse-admin;
        index index.html;
    }

    # Matrix Client/Server API (Proxy to Synapse)
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

    # Check if admin files exist
    if [ ! -f "data/synapse-admin/index.html" ]; then
        echo "<h1>Synapse Admin</h1><p>Please upload the extracted Synapse Admin files to data/synapse-admin</p>" > data/synapse-admin/index.html
        warn "Synapse Admin files not found in 'data/synapse-admin'."
        echo "    Upload the extracted contents of 'synapse-admin-0.11.1.tar.gz' to that directory."
    fi

    log "Restarting Nginx container..."
    $DOCKER_COMPOSE down
    $DOCKER_COMPOSE up -d nginx

    log "Nginx configured."
    log " - Matrix Server: http://$SERVER_NAME"
    log " - Admin Panel:   http://$SERVER_NAME/admin"
else
    log "Your server is available at: http://$SERVER_NAME:8008"
    log "(No reverse proxy configured)"
fi

# --- Final Summary ---
echo ""
echo "=========================================="
echo "  Configuration Complete!"
echo "=========================================="
echo ""
log "Server Details:"
echo "  Server Name: $SERVER_NAME"
echo "  Admin User: @$ADMIN_USER:$SERVER_NAME"
echo "  Registration: $REGISTRATION"
echo ""

if [[ "$SETUP_HTTPS" =~ ^[Yy]$ ]]; then
    echo "  Access URL: https://$SERVER_NAME"
else
    echo "  Access URL: http://$SERVER_NAME:8008"
fi

echo ""
log "Next Steps:"
echo "  1. Test your server: curl http://localhost:8008/_matrix/client/versions"
echo "  2. Download Element X app on your phone/computer"
echo "  3. Sign in with:"
echo "     - Homeserver: http://$SERVER_NAME:8008 (or https://$SERVER_NAME if HTTPS enabled)"
echo "     - Username: @$ADMIN_USER:$SERVER_NAME"
echo "     - Password: (the password you just created)"
echo ""
log "Useful commands:"
echo "  - View logs: docker compose logs -f synapse"
echo "  - Restart: docker compose restart"
echo "  - Create user: docker compose exec synapse register_new_matrix_user -c /data/homeserver.yaml http://localhost:8008"
echo ""
log "Configuration saved to: data/homeserver.yaml"
log "Backup saved to: data/homeserver.yaml.bak"
echo ""
