#!/bin/bash

# Path to the state file - must match select.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VPN_CONF="$SCRIPT_DIR/vpn.conf"

# Initialize state file if missing
if [ ! -f "$VPN_CONF" ]; then
    echo "VPN_NAME=\"\"" > "$VPN_CONF"
fi

# Load the current VPN_NAME variable
source "$VPN_CONF"

# If no VPN is defined in the config, show the inactive icon
if [ -z "$VPN_NAME" ]; then
    echo "{\"text\": \"󱙱\", \"class\": \"inactive\", \"tooltip\": \"No VPN configured\"}"
    exit 0
fi

# Check if the network interface for the selected VPN is actually up
if ip link show | grep -q "$VPN_NAME" 2>/dev/null; then
    # Active state: Interface found
    echo "{\"text\": \"󰌾\", \"class\": \"active\", \"tooltip\": \"VPN Connected: $VPN_NAME\"}"
else
    # Inactive state: Config exists but interface is down
    echo "{\"text\": \"󱙱\", \"class\": \"inactive\", \"tooltip\": \"VPN Disconnected\"}"
fi
