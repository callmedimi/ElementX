#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Element X Offline Packager (Linux)${NC}"
echo "Preparing offline assets..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed.${NC}"
    exit 1
fi

mkdir -p assets

echo ""
echo "[1/3] Downloading Synapse Admin..."
curl -L -o assets/synapse-admin.tar.gz https://github.com/Awesome-Technologies/synapse-admin/releases/download/0.11.1/synapse-admin-0.11.1.tar.gz

echo ""
echo "[2/3] Saving Docker Images..."
echo "  - Nginx..."
docker pull nginx:alpine
docker save -o assets/nginx_image.tar nginx:alpine

echo "  - Synapse..."
docker pull matrixdotorg/synapse:latest
docker save -o assets/synapse_image.tar matrixdotorg/synapse:latest

echo ""
echo -e "${GREEN}[SUCCESS] Assets saved to 'assets/' folder.${NC}"
echo "Copy this 'offline' directory to your server and run './install_server.sh'"
