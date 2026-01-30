#!/bin/bash
echo "========================================"
echo "      DEBUGGING ELEMENT X SERVER v2"
echo "========================================"

# 1. Config Check
echo "[1] CONFIG CHECK (Tail):"
tail -n 12 data/homeserver.yaml
echo ""

# 2. Permissions (Numeric IDs)
echo "[2] PERMISSIONS (Numeric):"
ls -nd data
ls -n data/homeserver.yaml
echo ""

# 3. Logs (Direct Docker Command)
echo "[3] CONTAINER LOGS:"
docker logs --tail 50 synapse
echo ""

echo "========================================"
