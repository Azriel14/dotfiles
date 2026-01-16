#!/bin/bash

# Define paths for persistence and configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VPN_CONF="$SCRIPT_DIR/vpn.conf"
CONFIG_DIR="/etc/wireguard"

# Pointing to Style-2 to match your clipboard history UI
THEME_FILE="$HOME/.config/rofi/launchers/type-1/style-2.rasi"

# Import current state to identify the active tunnel
[ -f "$VPN_CONF" ] && source "$VPN_CONF"

# List VPN profiles from /etc/wireguard
# Sudo find ensures we can read the directory; basename cleans up the file paths
vpn_list=$(sudo find "$CONFIG_DIR" -maxdepth 1 -name "*.conf" -type f -exec basename {} .conf \;)

# Execute Rofi with the specified theme
# The search bar is enabled by default by removing previous theme-str overrides
selected_vpn=$(echo -e "$vpn_list" | rofi -dmenu -i -p "VPN" -theme "$THEME_FILE")

# Exit if selection is empty (User cancelled)
[ -z "$selected_vpn" ] && exit 0

# --- CONNECTION HANDSHAKE ---

# 1. Kill any existing WireGuard interface to prevent IP/routing conflicts
# This ensures we don't have two tunnels competing for the default route
active_ifaces=$(ip -brief link show type wireguard | awk '{print $1}')
for iface in $active_ifaces; do
    sudo wg-quick down "$iface" 2>/dev/null
done

# 2. Update the vpn.conf state file with the new selection
echo "VPN_NAME=\"$selected_vpn\"" > "$VPN_CONF"

# 3. Attempt to bring up the new interface
if sudo wg-quick up "$selected_vpn"; then
    notify-send "VPN" "Switched to $selected_vpn"
else
    notify-send "VPN Error" "Failed to connect to $selected_vpn"
fi

# 4. Signal Waybar to refresh the icon immediately via the custom signal (RTMIN+8)
pkill -RTMIN+8 waybar 2>/dev/null || true
