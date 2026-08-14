#!/bin/bash
# opencode-up.sh - Bring opencode up with a BRAND NEW network (new gateway IP every time).
# Usage: ./opencode-up.sh
# Replace the old "sudo docker compose up -d" command with this script.

set -e

cd /home/frappe/opencode-docker

echo "=== Stopping previous opencode (if any) ==="
sudo docker compose down >/dev/null 2>&1 || true
sudo docker network rm opencode-net >/dev/null 2>&1 || true

OCTET=$(( (RANDOM % 240) + 2 ))
SUBNET="172.${OCTET}.0.0/16"
GATEWAY="172.${OCTET}.0.1"

echo "=== Creating brand new network (gateway will be ${GATEWAY}) ==="
sudo docker network create \
    --driver bridge \
    --subnet "${SUBNET}" \
    --gateway "${GATEWAY}" \
    opencode-net >/dev/null

echo "=== Starting opencode ==="
sudo docker compose up -d

echo ""
echo "=== Waiting for container network to settle ==="
sleep 3

CONTAINER_IP=$(sudo docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' opencode 2>/dev/null || echo "unavailable")
ACTUAL_GW=$(sudo docker inspect --format '{{range .NetworkSettings.Networks}}{{.Gateway}}{{end}}' opencode 2>/dev/null || echo "unavailable")
UUID=$(cat storage/uuid.txt 2>/dev/null || echo "unknown")

echo ""
echo "=== Results ==="
echo "Container IP : $CONTAINER_IP"
echo "Gateway IP   : $ACTUAL_GW"
echo "UUID         : $UUID"
echo "Web UI       : http://localhost:3000"

"$@"