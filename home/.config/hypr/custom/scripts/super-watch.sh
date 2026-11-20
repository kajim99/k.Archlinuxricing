#!/usr/bin/env bash
# Keeps super-watch.py running (restarts it if it stops; picks up newly plugged keyboards on restart).
exec 9>"$XDG_RUNTIME_DIR/super-watch.lock"; flock -n 9 || exit 0   # only one copy
while true; do
    python3 -I "$HOME/.config/hypr/custom/scripts/super-watch.py"
    sleep 2
done
