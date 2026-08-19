#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VPN_CONF="$SCRIPT_DIR/vpn.conf"
CONFIG_DIR="/etc/wireguard"

THEME_FILE="$HOME/.config/rofi/launchers/type-1/style-2.rasi"

[ -f "$VPN_CONF" ] && source "$VPN_CONF"

vpn_list=$(sudo find "$CONFIG_DIR" -maxdepth 1 -name "*.conf" -type f -exec basename {} .conf \;)

selected_vpn=$(echo -e "$vpn_list" | rofi -dmenu -i -p "VPN" -theme "$THEME_FILE")

[ -z "$selected_vpn" ] && exit 0

active_ifaces=$(ip -brief link show type wireguard | awk '{print $1}')
for iface in $active_ifaces; do
    sudo wg-quick down "$iface" 2>/dev/null
done

echo "VPN_NAME=\"$selected_vpn\"" > "$VPN_CONF"

if sudo wg-quick up "$selected_vpn"; then
    notify-send "VPN" "Switched to $selected_vpn"
else
    notify-send "VPN Error" "Failed to connect to $selected_vpn"
fi

pkill -RTMIN+8 waybar 2>/dev/null || true
