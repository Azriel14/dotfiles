#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VPN_CONF="$SCRIPT_DIR/vpn.conf"

[ -f "$VPN_CONF" ] && source "$VPN_CONF"

if [ -z "$VPN_NAME" ]; then
    notify-send "VPN Error" "No VPN selected. Right-click to choose one."
    exit 1
fi

# Check if the specifically configured VPN is the one that's up
if ip link show "$VPN_NAME" &>/dev/null; then
    # It's currently active, so we turn it OFF
    sudo wg-quick down "$VPN_NAME"
    notify-send "VPN" "Disconnected from $VPN_NAME"
else
    # It's not active. First, kill any other rogue VPNs that might be up
    active_ifaces=$(ip -brief link show type wireguard | awk '{print $1}')
    for iface in $active_ifaces; do
        sudo wg-quick down "$iface" 2>/dev/null
    done

    # Now turn ON the preferred VPN
    if sudo wg-quick up "$VPN_NAME"; then
        notify-send "VPN" "Connected to $VPN_NAME"
    else
        notify-send "VPN Error" "Failed to connect to $VPN_NAME"
    fi
fi

pkill -RTMIN+8 waybar 2>/dev/null || true
