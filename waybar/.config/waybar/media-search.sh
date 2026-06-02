#!/bin/bash

MPV_SOCKET="/tmp/mpv_socket"
CACHE="/tmp/waybar_media_cache"
MODE_FILE="/tmp/mpv_mode"
THEME="$HOME/.config/rofi/launchers/type-1/style-2.rasi"
SEARCH_THEME="$HOME/.config/rofi/media-search.rasi"
BOOKMARKS="$HOME/.config/waybar/media-bookmarks"

kill_current() {
    if [ -S "$MPV_SOCKET" ]; then
        echo '{"command":["quit"]}' | socat -t1 - "$MPV_SOCKET" 2>/dev/null
        sleep 0.3
    fi
    pkill -x mpv 2>/dev/null
}

play() {
    local url="$1" title="$2"
    local mode; mode=$(cat "$MODE_FILE" 2>/dev/null || echo "play")
    kill_current
    local flags=(--no-video --audio-display=no --input-ipc-server="$MPV_SOCKET" --really-quiet)
    case "$mode" in
        loop-track) flags+=(--loop-file=inf) ;;
        shuffle)    flags+=(--shuffle --loop-playlist=inf) ;;
    esac
    echo "$title" > "$CACHE"
    mpv "${flags[@]}" "$url" &
    for i in $(seq 1 20); do [ -S "$MPV_SOCKET" ] && break; sleep 0.1; done
    pkill -RTMIN+10 waybar 2>/dev/null
}

# ── Search prompt ──────────────────────────────────────────────────────────────
# Pipe bookmark names in — user can pick one or type a new search
bm_names=$(grep -v '^\s*$' "$BOOKMARKS" | cut -d'|' -f1 | sed 's/[[:space:]]*$//')
query=$(echo "$bm_names" | rofi -dmenu -p "󰝚" -theme "$SEARCH_THEME" -i -matching fuzzy)
[ -z "$query" ] && exit

# Bookmark match → play saved URL directly
bm_url=$(grep -F "$query |" "$BOOKMARKS" | cut -d'|' -f2 | sed 's/^[[:space:]]*//' | head -1)
if [ -n "$bm_url" ]; then
    title="$query"
    play "$bm_url" "$title"; exit
fi

# Direct URL
if echo "$query" | grep -qE '^https?://'; then
    title=$(yt-dlp --print "%(title)s" --no-playlist --quiet "$query" 2>/dev/null | head -1)
    [ -z "$title" ] && title="$(basename "$query")"
    play "$query" "$title"; exit
fi

# Service prefix: "sc: query" = SoundCloud, default = YouTube
if [[ "$query" =~ ^sc:[[:space:]]* ]]; then
    service="scsearch"
    query="${query#sc:}"
    query="${query#"${query%%[![:space:]]*}"}"
else
    service="ytsearch"
fi

# ── Fetch results ──────────────────────────────────────────────────────────────
notify-send "Media Player" "Searching…" -t 1500 -u low

mapfile -t all < <(yt-dlp "${service}20:${query}" \
    --flat-playlist \
    --print "%(title)s" \
    --print "%(webpage_url)s" \
    --quiet 2>/dev/null)

if [ ${#all[@]} -eq 0 ]; then
    notify-send "Media Player" "No results — try different keywords" -t 3000
    exit
fi

displays=(); urls=()
for ((i = 0; i < ${#all[@]}; i += 2)); do
    displays+=("${all[$i]}")
    urls+=("${all[$i+1]}")
done

# ── Pick track ─────────────────────────────────────────────────────────────────
selected=$(printf '%s\n' "${displays[@]}" | \
    rofi -dmenu -p "󰝚  Pick" -theme "$THEME" -i -matching fuzzy)
[ -z "$selected" ] && exit

url=""
for i in "${!displays[@]}"; do
    if [ "${displays[$i]}" = "$selected" ]; then
        url="${urls[$i]}"
        title=$(echo "${displays[$i]}" | awk -F' — ' '{print $1}')
        break
    fi
done
[ -z "$url" ] && exit

play "$url" "$title"
