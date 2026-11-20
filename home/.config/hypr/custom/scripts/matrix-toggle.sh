#!/bin/bash
# Toggles the matrix rain layer (N-CM style; it IS the wallpaper now, below the desktop clock and windows).
# Usage: matrix-toggle.sh [start]   ("start" is for login: only starts it if not running and not switched off)
# Turning it off with the toggle is remembered across logins until it's toggled back on.
SCRIPT=~/.config/hypr/custom/scripts/matrix-rain.py
OFF_FLAG=~/.local/state/matrix-rain.off
LOG=~/.cache/matrix-rain-start.log
PATTERN="^python3 -I .*/matrix-rain\.py$"

launch() {
    # N-CM (2026-11-16): solid #05010d on the wallpaper layer, so end-4's desktop clock (bottom layer) stays on top
    kitten panel --detach --edge=center --layer=background --focus-policy=not-allowed \
        --app-id=kitty-matrix-rain --os-window-tag=kitty-matrix-rain \
        -o background=#05010d -o background_opacity=1 -o window_margin_width=0 -o font_size=12 \
        -o "font_family=JetBrainsMono Nerd Font" \
        sh -c "exec python3 -I '$SCRIPT' 2>>'$LOG'"   # exec keeps the process name for $PATTERN; errors go to the log
}

# Watcher (started at login): brings the rain back if it dies, unless it was switched off.
# Needs 2 misses in a row (~20 s) so it doesn't race the toggle; 3 restarts in 2 min -> notify, wait 10 min.
if [[ "$1" == "watch" ]]; then
    exec 9>"$XDG_RUNTIME_DIR/matrix-watch.lock"; flock -n 9 || exit 0   # only one watcher
    sleep 30   # let the login start happen first
    misses=0; restarts=()
    while true; do
        sleep 10
        if [[ -e "$OFF_FLAG" ]] || pgrep -f "$PATTERN" >/dev/null; then misses=0; continue; fi
        (( ++misses < 2 )) && continue
        misses=0
        now=$(date +%s)
        restarts=($(for t in "${restarts[@]}"; do (( now - t < 120 )) && echo $t; done) $now)
        if (( ${#restarts[@]} > 3 )); then
            echo "$(date '+%F %T') watcher: keeps dying, waiting 10 min" >>"$LOG"
            notify-send -a "Matrix rain" "Matrix rain keeps stopping" "Waiting 10 min before trying again. Log: ~/.cache/matrix-rain-start.log"
            sleep 600; restarts=()
            continue
        fi
        echo "$(date '+%F %T') watcher: rain had stopped, restarting" >>"$LOG"
        launch >>"$LOG" 2>&1 9>&-
    done
fi

if [[ "$1" == "start" ]]; then
    pgrep -f "$PATTERN" >/dev/null && exit 0
    [[ -e "$OFF_FLAG" ]] && { echo "$(date '+%F %T') off flag set, not starting" >>"$LOG"; exit 0; }
    # Wait for the compositor to be ready, then retry if the panel doesn't come up
    for i in $(seq 1 30); do hyprctl monitors >/dev/null 2>&1 && break; sleep 1; done
    sleep 2
    for attempt in 1 2 3 4 5; do
        launch >>"$LOG" 2>&1
        sleep 3
        if pgrep -f "$PATTERN" >/dev/null; then
            echo "$(date '+%F %T') started on attempt $attempt" >>"$LOG"
            exit 0
        fi
        echo "$(date '+%F %T') attempt $attempt failed" >>"$LOG"
        sleep 2
    done
    exit 1
fi

mkdir -p "$(dirname "$OFF_FLAG")"
if pgrep -f "$PATTERN" >/dev/null; then
    touch "$OFF_FLAG"
    # Rewind the rain off the top; the script exits by itself when done, closing the panel
    pkill -USR1 -f "$PATTERN"
    exit 0
fi
rm -f "$OFF_FLAG"
launch
