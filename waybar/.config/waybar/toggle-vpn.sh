#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VPN_CONF="$SCRIPT_DIR/vpn.conf"

# Create vpn.conf if it doesn't exist
if [ ! -f "$VPN_CONF" ]; then
    echo "VPN_NAME=\"\"" > "$VPN_CONF"
    # Try to auto-configure with first available VPN
    configs_path="/etc/wireguard"
    if [ -d "$configs_path" ]; then
        first_config=$(sudo find "$configs_path" -maxdepth 1 -name "*.conf" -type f 2>/dev/null | head -n1 | xargs -r basename -s .conf)
        if [ -n "$first_config" ]; then
            echo "VPN_NAME=\"$first_config\"" > "$VPN_CONF"
        fi
    fi
fi

# Source the config
source "$VPN_CONF"

# Check if VPN_NAME is set
if [ -z "$VPN_NAME" ]; then
    notify-send "VPN Error" "No VPN configuration found. Right-click to select one."
    exit 1
fi

# Toggle VPN
if ip link show | grep -q "$VPN_NAME" 2>/dev/null; then
    # VPN is connected, disconnect it
    if timeout 2 env SUDO_ASKPASS=/bin/false sudo -A -n wg-quick down "$VPN_NAME" 2>/dev/null; then
        notify-send "VPN Disconnected" "Disconnected from $VPN_NAME"
    elif timeout 2 sudo -n wg-quick down "$VPN_NAME" 2>/dev/null; then
        notify-send "VPN Disconnected" "Disconnected from $VPN_NAME"
    else
        notify-send "VPN Error" "Failed to disconnect from $VPN_NAME"
    fi
else
    # VPN is disconnected, connect it
    if timeout 2 env SUDO_ASKPASS=/bin/false sudo -A -n wg-quick up "$VPN_NAME" 2>/dev/null; then
        notify-send "VPN Connected" "Connected to $VPN_NAME"
    elif timeout 2 sudo -n wg-quick up "$VPN_NAME" 2>/dev/null; then
        notify-send "VPN Connected" "Connected to $VPN_NAME"
    else
        notify-send "VPN Error" "Failed to connect to $VPN_NAME"
    fi
fi

# Force waybar to update
pkill -RTMIN+8 waybar 2>/dev/null || true
