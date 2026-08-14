#!/bin/bash
# opencode-down.sh - Stop opencode AND remove its network.
# Usage: ./opencode-down.sh
# Replaces the old "sudo docker compose down" command.

set -e

cd /home/frappe/opencode-docker

echo "=== Stopping opencode container ==="
sudo docker compose down 2>&1 | tail -3

echo "=== Removing network ==="
sudo docker network rm opencode-net 2>/dev/null && echo "Removed" || echo "Nothing to remove"
echo "Done."