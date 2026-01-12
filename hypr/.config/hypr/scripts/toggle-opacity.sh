#!/usr/bin/env bash

STATE_DIR="$HOME/.cache/hypr-opacity"
mkdir -p "$STATE_DIR"

ADDR=$(hyprctl activewindow -j | jq -r '.address')
[[ -z "$ADDR" || "$ADDR" == "null" ]] && exit 0

STATE_FILE="$STATE_DIR/$ADDR"

if [[ -f "$STATE_FILE" ]]; then
  # Restore decoration opacity behaviour
  hyprctl dispatch setprop "address:$ADDR" opaque -1
  hyprctl dispatch setprop "address:$ADDR" noblur -1
  rm -f "$STATE_FILE"
else
  # Force window to behave as fully opaque
  hyprctl dispatch setprop "address:$ADDR" opaque 1
  hyprctl dispatch setprop "address:$ADDR" noblur 1
  touch "$STATE_FILE"
fi
