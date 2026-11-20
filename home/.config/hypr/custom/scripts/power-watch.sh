#!/bin/bash
# Battery mode (2026-11-14), silent, started at login (custom/execs.lua).
#   On battery:  power profile -> power-saver, screen 144 -> 60 Hz, video wallpaper + matrix rain paused,
#                no blur/shadows/animations, screen brightness 60%, keyboard backlight off.
#   Plugged in:  everything back (previous mode: purple max / red performance kept, else Balanced; brightness + kbd remembered).
# Plugged in, red Performance (Fn+Q) is switched to purple max (power-mode max) within 5 s.
# Checks the charger every 5 s; while on battery it re-pauses the wallpaper/rain (hypridle resumes them on wake).
exec 9>"$XDG_RUNTIME_DIR/power-watch.lock"; flock -n 9 || exit 0
AC=/sys/class/power_supply/ACAD/online
KBD=platform::kbd_backlight
ST=~/.local/state/power-watch; mkdir -p "$ST"

hypr() { hyprctl eval "$1" >/dev/null 2>&1; }

pause_eye_candy() {
    pkill -STOP -x mpvpaper
    pkill -STOP -f '^python3 -I .*/matrix-rain\.py$'
}

battery_mode() {
    [[ -e $ST/profile ]] || "$HOME/.local/bin/power-mode" get >"$ST/profile"   # saver|balanced|max|performance|custom
    [[ -e $ST/brightness ]] || brightnessctl g >"$ST/brightness"
    [[ -e $ST/kbd ]] || brightnessctl -d "$KBD" g >"$ST/kbd"
    "$HOME/.local/bin/power-mode" saver
    hypr 'hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })'
    hypr 'hl.config({ decoration = { blur = { enabled = false }, shadow = { enabled = false } }, animations = { enabled = false } })'
    brightnessctl -q set 60%
    brightnessctl -q -d "$KBD" set 0
    pause_eye_candy
}

ac_mode() {
    # back to the mode from before unplugging: purple max / red performance stay, anything else -> Balanced
    case "$(cat "$ST/profile" 2>/dev/null)" in
        max) "$HOME/.local/bin/power-mode" max ;;
        performance) powerprofilesctl set performance ;;
        *) "$HOME/.local/bin/power-mode" balanced ;;
    esac
    rm -f "$ST/profile"
    hypr 'hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })'
    hypr 'hl.config({ decoration = { blur = { enabled = true }, shadow = { enabled = true } }, animations = { enabled = true } })'
    if [[ -e $ST/brightness ]]; then brightnessctl -q set "$(cat "$ST/brightness")"; rm -f "$ST/brightness"; fi
    if [[ -e $ST/kbd ]]; then brightnessctl -q -d "$KBD" set "$(cat "$ST/kbd")"; rm -f "$ST/kbd"; fi
    pkill -CONT -x mpvpaper
    pkill -CONT -f '^python3 -I .*/matrix-rain\.py$'
}

last=""
while true; do
    now=$(cat "$AC" 2>/dev/null || echo 1)
    if [[ "$now" != "$last" ]]; then
        if [[ "$now" == 0 ]]; then battery_mode; else ac_mode; fi
        last=$now
    elif [[ "$now" == 0 ]]; then
        pause_eye_candy
    elif [[ "$("$HOME/.local/bin/power-mode" get)" == performance ]]; then
        "$HOME/.local/bin/power-mode" max   # plugged in: red Performance (e.g. from Fn+Q) -> purple max
    fi
    sleep 5
done
