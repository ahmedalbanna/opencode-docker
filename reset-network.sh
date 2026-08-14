#!/bin/bash
# reset-network.sh - Reset Docker network for a NEW gateway IP + new UUID.
# Usage: bash reset-network.sh
# This now delegates to opencode-down.sh + opencode-up.sh which
# guarantee a brand new subnet/gateway on every cycle.

cd /home/frappe/opencode-docker

echo "=== Opencode Docker Network Reset (new gateway each cycle) ==="
./opencode-down.sh
./opencode-up.sh

echo ""
echo "Reset complete. New gateway IP shown above."