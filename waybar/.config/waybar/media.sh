#!/bin/bash

CACHE="/tmp/waybar_media_cache"
MPV_SOCKET="/tmp/mpv_socket"
MODE_FILE="/tmp/mpv_mode"

inactive() { echo '{"text":"","class":"inactive"}'; exit; }

mpv_alive() {
    [ -S "$MPV_SOCKET" ] || return 1
    echo '{"command":["get_property","pid"]}' | socat -t1 - "$MPV_SOCKET" 2>/dev/null | grep -q '"error":"success"'
}

mpv_cmd() { echo "{\"command\":[$1]}" | socat -t1 - "$MPV_SOCKET" 2>/dev/null; }
mpv_get() { echo "{\"command\":[\"get_property\",\"$1\"]}" | socat -t1 - "$MPV_SOCKET" 2>/dev/null | jq -r '.data // empty'; }
mpv_raw() { echo "$1" | socat -t1 - "$MPV_SOCKET" 2>/dev/null; }

apply_mode() {
    mpv_raw '{"command":["set_property","loop-file",false]}'
    mpv_raw '{"command":["set_property","loop-playlist",false]}'
    case "$1" in
        loop-track) mpv_raw '{"command":["set_property","loop-file","inf"]}' ;;
        shuffle)
            mpv_raw '{"command":["set_property","loop-playlist","inf"]}'
            mpv_raw '{"command":["playlist-shuffle"]}'
            ;;
        play) mpv_raw '{"command":["playlist-unshuffle"]}' ;;
    esac
}

case "$1" in
    play-pause)
        mpv_alive && mpv_cmd '"cycle","pause"'
        pkill -RTMIN+10 waybar 2>/dev/null
        ;;

    next)
        if mpv_alive; then
            mode=$(cat "$MODE_FILE" 2>/dev/null || echo "play")
            [ "$mode" = "loop-track" ] \
                && mpv_raw '{"command":["seek",0,"absolute"]}' \
                || mpv_raw '{"command":["playlist-next","force"]}'
        fi
        pkill -RTMIN+10 waybar 2>/dev/null
        ;;

    prev)
        if mpv_alive; then
            mode=$(cat "$MODE_FILE" 2>/dev/null || echo "play")
            [ "$mode" = "loop-track" ] \
                && mpv_raw '{"command":["seek",0,"absolute"]}' \
                || mpv_raw '{"command":["playlist-prev","force"]}'
        fi
        pkill -RTMIN+10 waybar 2>/dev/null
        ;;

    stop)
        if mpv_alive; then
            mpv_cmd '"quit"'
            rm -f "$MPV_SOCKET"
        fi
        pkill -RTMIN+10 waybar 2>/dev/null
        ;;

    cycle-mode)
        mode=$(cat "$MODE_FILE" 2>/dev/null || echo "play")
        single=false
        mpv_alive && [ "$(mpv_get "playlist-count")" = "1" ] && single=true
        case "$mode" in
            play)       echo "loop-track" > "$MODE_FILE" ;;
            loop-track) $single && echo "play" > "$MODE_FILE" || echo "shuffle" > "$MODE_FILE" ;;
            shuffle)    echo "play"       > "$MODE_FILE" ;;
        esac
        mpv_alive && apply_mode "$(cat "$MODE_FILE")"
        pkill -RTMIN+10 waybar 2>/dev/null
        ;;

    icon-mode)
        mpv_alive || inactive
        mode=$(cat "$MODE_FILE" 2>/dev/null || echo "play")
        case "$mode" in
            loop-track) echo '{"text":"󰑘","class":"on"}' ;;
            shuffle)    echo '{"text":"󰒝","class":"on"}' ;;
            *)          echo '{"text":"󰑖","class":"off"}' ;;
        esac
        ;;

    click-title)
        mpv_alive && exit
        exec "$HOME/.config/waybar/media-search.sh"
        ;;

    icon-prev)
        mpv_alive || inactive
        echo '{"text":"󰒮"}'
        ;;

    icon-play)
        mpv_alive || inactive
        pause=$(mpv_get "pause")
        [ "$pause" = "true" ] && echo '{"text":"󰐊","class":"paused"}' || echo '{"text":"󰏤"}'
        ;;

    icon-next)
        mpv_alive || inactive
        echo '{"text":"󰒭"}'
        ;;

    title)
        if mpv_alive; then
            raw=$(mpv_get "media-title")
            if [ -n "$raw" ]; then
                [ ${#raw} -gt 35 ] && raw="${raw:0:35}…"
                echo "$raw" > "$CACHE"
                pause=$(mpv_get "pause")
                [ "$pause" = "true" ] && class="paused" || class="playing"
                jq -cn --arg t "$raw" --arg c "$class" '{text: $t, class: $c}'
                exit
            fi
        fi
        echo '{"text":"󰝚  Media Player","class":"gone"}'
        ;;
esac
