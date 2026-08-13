#!/bin/bash
set -e

# Ensure storage directory exists
STORAGE_DIR="/home/frappe/opencode-docker/storage"
UUID_FILE="${STORAGE_DIR}/uuid.txt"

# Always generate a new unique identifier on every startup
# This ensures fresh identifier on each 'docker compose down && up'
CONTAINER_ID=$(cat /etc/hostname 2>/dev/null || echo "unknown")
TIMESTAMP=$(date +%s%N)
UNIQUE_ID="opencode-${CONTAINER_ID}-${TIMESTAMP}"
echo "$UNIQUE_ID" > "$UUID_FILE"

echo "Generated new UUID on startup: $UNIQUE_ID"

# Ensure config directory permissions
chmod 755 "$STORAGE_DIR"
chmod 755 /home/frappe/opencode-docker/config

# Change to Frappe home directory if it exists (for Frappe development)
FP_HOME="/home/frappe"
if [ -d "$FP_HOME" ]; then
    cd "$FP_HOME"
    echo "Working directory set to: $(pwd)"
fi

# Get container's IP address from docker network
# In bridge network, we can get the IP via docker inspect
CONTAINER_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' opencode 2>/dev/null || echo "127.0.0.1")
echo "Container IP address: $CONTAINER_IP"

# Read port and hostname from environment variables with defaults
# To customize, edit the OPENCODE_PORT and OPENCODE_HOST variables in docker-compose.yml
OPENCODE_PORT="${OPENCODE_PORT:-8080}"
OPENCODE_HOST="${OPENCODE_HOST:-127.0.0.1}"

# Reverse SSH tunnel configuration
# Set REVERSE_SSH_HOST and REVERSE_SSH_PORT env vars to enable
# Example: REVERSE_SSH_HOST=user@your-server.com REVERSE_SSH_PORT=22
if [ -n "${REVERSE_SSH_HOST:-}" ] && [ -n "${REVERSE_SSH_PORT:-}" ]; then
    echo "Setting up reverse SSH tunnel to ${REVERSE_SSH_HOST}:${REVERSE_SSH_PORT}..."
    # Run ssh in background to establish reverse tunnel
    # -N: don't execute remote command
    # -R: remote forward: local_port:host:host_port
    # -f: background after connecting
    # -o ServerAliveInterval=60: keep-alive
    ssh -N -R "${REVERSE_SSH_PORT:-2222}:localhost:${REVERSE_SSH_PORT:-2222}" \
        -f -o ServerAliveInterval=60 -o ServerAliveCountMax=3 \
        "${REVERSE_SSH_HOST}" &
    REVERSE_PID=$!
    echo "Reverse SSH tunnel started (PID: $REVERSE_PID)"
    echo "Forwarding container port 2222 to ${REVERSE_SSH_HOST}:${REVERSE_SSH_PORT}"
    echo "On your machine: ssh -p ${REVERSE_SSH_PORT:-2222} localhost"
fi

echo "Starting opencode on ${OPENCODE_HOST}:${OPENCODE_PORT}"
exec opencode serve --port "${OPENCODE_PORT}" --hostname "${OPENCODE_HOST}" --mdns false