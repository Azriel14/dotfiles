#!/bin/bash

WORK_MIN=45
WORK_MAX=60

TIP_IDLE="Click to start  ·  Right click to reset"

STATE_FILE="/tmp/animedoro_state"
OT_FILE="/tmp/animedoro_overtime"

fmt_time() { printf "%02d:%02d" $(($1 / 60)) $(($1 % 60)); }
get_phase() { cut -d'|' -f1 "$STATE_FILE" 2>/dev/null || echo "idle"; }
get_start() { cut -d'|' -f2 "$STATE_FILE" 2>/dev/null || echo "0"; }
save_state() { echo "$1|$2" > "$STATE_FILE"; }

case "$1" in
    click-left)
        phase=$(get_phase)
        now=$(date +%s)
        case "$phase" in
            idle)
                save_state "work" "$now"
                ;;
            work)
                elapsed_min=$(( (now - $(get_start)) / 60 ))
                if [ "$elapsed_min" -lt "$WORK_MIN" ]; then
                    left=$(( WORK_MIN - elapsed_min ))
                else
                    save_state "break" "$now"
                    rm -f "$OT_FILE"
                fi
                ;;
            break)
                save_state "idle" "0"
                ;;
        esac
        pkill -RTMIN+9 waybar 2>/dev/null
        ;;

    click-right)
        rm -f "$STATE_FILE" "$OT_FILE"
        pkill -RTMIN+9 waybar 2>/dev/null
        ;;

    status)
        phase=$(get_phase)
        start=$(get_start)
        now=$(date +%s)

        case "$phase" in
            idle)
                printf '{"text":"󱎫  Animedoro","class":"idle","tooltip":"%s"}\n' "$TIP_IDLE"
                ;;

            work)
                elapsed=$(( now - start ))
                elapsed_min=$(( elapsed / 60 ))
                time_str=$(fmt_time "$elapsed")

                if [ "$elapsed_min" -lt "$WORK_MIN" ]; then
                    class="work" icon="󰔛"
                elif [ "$elapsed_min" -lt "$WORK_MAX" ]; then
                    class="work-ready" icon="󰔛"
                else
                    if [ ! -f "$OT_FILE" ]; then
                        touch "$OT_FILE"
                    fi
                    class="work-over" icon="󱎫"
                fi

                printf '{"text":"%s  %s","class":"%s"}\n' "$icon" "$time_str" "$class"
                ;;

            break)
                elapsed=$(( now - start ))
                time_str=$(fmt_time "$elapsed")
                printf '{"text":"󰎁  %s","class":"break"}\n' "$time_str"
                ;;
        esac
        ;;
esac
