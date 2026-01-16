#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VPN_CONF="$SCRIPT_DIR/vpn.conf"

# Find available VPN configurations
configs_path="/etc/wireguard"
configs=()

# Check if directory exists
if [ ! -d "$configs_path" ]; then
    echo "Directory $configs_path does not exist"
    read -p "Press Enter to continue..."
    exit 1
fi

# Use sudo to list .conf files since /etc/wireguard requires elevated permissions
echo "Scanning for VPN configurations..."
while IFS= read -r -d '' conf_file; do
    if [ -n "$conf_file" ]; then
        # Extract basename without .conf extension
        basename_conf=$(basename "$conf_file" .conf)
        configs+=("$basename_conf")
    fi
done < <(sudo find "$configs_path" -maxdepth 1 -name "*.conf" -type f -print0 2>/dev/null)

if [ ${#configs[@]} -eq 0 ]; then
    echo "No WireGuard configurations found in $configs_path"
    echo "Make sure you have .conf files in /etc/wireguard/"
    echo ""
    echo "To get Proton VPN configurations:"
    echo "1. Log in to your Proton VPN account"
    echo "2. Go to Downloads section"
    echo "3. Download WireGuard configurations"
    echo "4. Place the .conf files in /etc/wireguard/"
    read -p "Press Enter to continue..."
    exit 1
fi

# Get current VPN name if exists
current_vpn=""
if [ -f "$VPN_CONF" ]; then
    source "$VPN_CONF"
    current_vpn="$VPN_NAME"
fi

# Present a selection menu
echo "Current VPN: ${current_vpn:-"None"}"
echo ""
echo "Available VPN configurations:"
echo "0) Disconnect current VPN (if any)"

for i in "${!configs[@]}"; do
    echo "$((i+1))) ${configs[i]}"
done

echo ""
read -p "Select option (0-${#configs[@]}): " choice

# Handle disconnect option
if [ "$choice" = "0" ]; then
    if [ -n "$current_vpn" ] && ip link show | grep -q "$current_vpn" 2>/dev/null; then
        echo "Disconnecting from $current_vpn..."
        if sudo wg-quick down "$current_vpn"; then
            echo "Successfully disconnected from $current_vpn"
        else
            echo "Failed to disconnect from $current_vpn"
        fi
    else
        echo "No VPN currently connected"
    fi
    read -p "Press Enter to continue..."
    exit 0
fi

# Validate selection
if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#configs[@]}" ]; then
    selected_vpn="${configs[$((choice-1))]}"
    
    # Update vpn.conf
    echo "VPN_NAME=\"$selected_vpn\"" > "$VPN_CONF"
    echo "VPN configuration updated to $selected_vpn"
    
    # If a VPN is currently connected, disconnect it
    if [ -n "$current_vpn" ] && ip link show | grep -q "$current_vpn" 2>/dev/null; then
        echo "Disconnecting from $current_vpn..."
        sudo wg-quick down "$current_vpn"
    fi
    
    # Connect to the new VPN
    echo "Connecting to $selected_vpn..."
    if sudo wg-quick up "$selected_vpn"; then
        echo "Successfully connected to $selected_vpn"
    else
        echo "Failed to connect to $selected_vpn"
    fi
    
    read -p "Press Enter to continue..."
else
    echo "Invalid selection."
    read -p "Press Enter to continue..."
    exit 1
fi
