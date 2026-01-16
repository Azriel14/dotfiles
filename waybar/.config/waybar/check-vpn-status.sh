#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VPN_CONF="$SCRIPT_DIR/vpn.conf"

# Create vpn.conf if it doesn't exist
if [ ! -f "$VPN_CONF" ]; then
    echo "VPN_NAME=\"\"" > "$VPN_CONF"
fi

# Source the config
source "$VPN_CONF"

# Check if VPN_NAME is set and not empty
if [ -z "$VPN_NAME" ]; then
    echo "{\"text\": \"󱙱\", \"class\": \"inactive\", \"tooltip\": \"No VPN configured\"}"
    exit 0
fi

# Check VPN status
if ip link show | grep -q "$VPN_NAME" 2>/dev/null; then
    echo "{\"text\": \"󰌾\", \"class\": \"active\", \"tooltip\": \"VPN Connected: $VPN_NAME\"}"
else
    echo "{\"text\": \"󱙱\", \"class\": \"inactive\", \"tooltip\": \"VPN Disconnected\"}"
fi
