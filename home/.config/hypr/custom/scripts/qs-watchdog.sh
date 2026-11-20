#!/usr/bin/env bash
# Restarts the Quickshell desktop (bar, sidebars, Super overview) if it stops.
# Backs off if it keeps dying (5 restarts in 2 minutes -> wait 60 s) so it can't loop.
# Also restarts it if Quickshell is running but the top bar never appeared (max 2 tries, then notify).
# Black box (2026-11-19): before every restart it saves the last Quickshell log lines + any crash dump to
# ~/.local/state/qs-crashes/ (newest 10 kept), so the cause of a vanished bar can be read afterwards.
exec 9>"$XDG_RUNTIME_DIR/qs-watchdog.lock"; flock -n 9 || exit 0   # only one watchdog (lock file)
sleep 10   # let end-4 start the shell first at login
blackbox() {   # $1 = why: stopped | no-bar
    local d=$HOME/.local/state/qs-crashes run
    mkdir -p "$d"
    run=$(ls -td "$XDG_RUNTIME_DIR"/quickshell/by-id/*/ 2>/dev/null | head -1)   # newest instance = the one that failed
    {
        echo "$(date '+%F %T')  $1  (instance ${run%/})"
        echo "--- crash dumps in the last 2 min"; coredumpctl list /usr/bin/quickshell --since=-2min --no-pager 2>&1 | tail -3
        echo "--- last log lines"; tail -n 120 "${run}log.log" 2>&1
    } > "$d/$(date +%F_%H-%M-%S)-$1.txt"
    ls -t "$d"/*.txt | tail -n +11 | xargs -r rm -f
}
restarts=()
barMisses=0    # checks in a row with qs running but no bar
barTries=0     # restarts done for the current missing-bar incident
barGaveUp=0
while true; do
    if ! pgrep -x qs >/dev/null; then
        now=$(date +%s)
        restarts=($(for t in "${restarts[@]}"; do (( now - t < 120 )) && echo $t; done) $now)
        if (( ${#restarts[@]} > 5 )); then
            notify-send -a "Watchdog" "Shell keeps stopping" "Waiting 60 s before trying again" -u critical
            sleep 60; restarts=()
            continue
        fi
        blackbox stopped
        setsid -f qs -c ii >/dev/null 2>&1 < /dev/null 9>&-   # 9>&-: don't pass the lock file to qs
        notify-send -a "Watchdog" "Desktop restarted" "The bar had stopped, it's back now"
        sleep 10; barMisses=0
    elif [[ $(hyprctl locked) == true ]] || hyprctl layers | grep -q 'namespace: quickshell:bar'; then   # bar is hidden while locked, and qs draws the lock
        barMisses=0; barTries=0; barGaveUp=0
    elif (( ! barGaveUp )) && (( ++barMisses >= 3 )); then   # ~9 s without a bar
        if (( barTries >= 2 )); then
            notify-send -a "Watchdog" "Top bar won't load" "Tried restarting twice. Press Ctrl+Super+R or ask Claude." -u critical
            barGaveUp=1
        else
            (( barTries++ ))
            blackbox no-bar
            pkill -x qs; sleep 1
            setsid -f qs -c ii >/dev/null 2>&1 < /dev/null 9>&-   # 9>&-: don't pass the lock file to qs
            notify-send -a "Watchdog" "Top bar was missing" "Restarted the desktop to bring it back"
            sleep 10
        fi
        barMisses=0
    fi
    sleep 3
done
