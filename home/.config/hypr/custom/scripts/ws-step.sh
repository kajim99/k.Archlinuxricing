#!/bin/bash
# Steps to the previous/next workspace, never below 1 or past the last one: the `wp` count
# (base 5, changed with `wp -N` / `wp --N` in fish) or the highest workspace in use, if higher.
# Usage: ws-step.sh <-1|+1> [move]   ("move" takes the focused window along)
cur=$(hyprctl activeworkspace -j | jq -r '.id')
(( cur < 1 )) && exit 0   # special/temporary workspaces: do nothing
COUNT=$(cat "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/wp-count" 2>/dev/null || echo 5)
MAX=$(hyprctl workspaces -j | jq --argjson c "${COUNT:-5}" '[.[].id | select(. > 0)] + [$c] | max')
target=$(( cur + $1 ))
(( target < 1 )) && target=1
(( target > MAX )) && target=$MAX
(( target == cur )) && exit 0
if [[ "$2" == "move" ]]; then
    hyprctl dispatch "hl.dsp.window.move({ workspace = $target })" >/dev/null
else
    hyprctl dispatch "hl.dsp.focus({ workspace = $target })" >/dev/null
fi
