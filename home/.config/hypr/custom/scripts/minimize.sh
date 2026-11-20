#!/bin/bash
# Mac-style minimize for Hyprland (2026-11-05): the window shrinks and fades toward the bottom
# center (~0.3 s, using Hyprland's own windowsMove animation), then hides in special:minimized.
# Usage: minimize.sh            minimize the focused window (hyprbars violet button)
#        minimize.sh restore    bring back the most recently minimized one, growing back
#        minimize.sh restore ADDR   bring back that window (media-focus, phone cover tap)
#        minimize.sh toggle     Super+U: minimize the focused window, or restore if none is focused
# Each minimized window's old place is kept in this Hyprland session's runtime folder.
STATE=$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/minimized
ANIM=0.32
mkdir -p "$STATE"

d() { hyprctl dispatch "$1" >/dev/null; }

# Small box at the bottom center of the monitor the window is on: x y w h
dock_box() {
    hyprctl monitors -j | jq -r --argjson m "$1" '.[] | select(.id == $m)
        | (.width / .scale | floor) as $w | (.height / .scale | floor) as $h
        | [(.x + ($w - $w*0.12)/2 | floor), (.y + $h - $h*0.12 - 12 | floor), ($w*0.12 | floor), ($h*0.12 | floor)] | @tsv'
}

win=$(hyprctl activewindow -j)
if [[ "$1" == "toggle" ]]; then
    if [[ -n "$(jq -r '.address // empty' <<<"$win")" && "$(jq -r .workspace.name <<<"$win")" != special:* ]]; then
        set -- minimize
    else
        set -- restore
    fi
fi

if [[ "$1" != "restore" ]]; then
    addr=$(jq -r '.address // empty' <<<"$win")
    [[ -z "$addr" || "$(jq -r .workspace.name <<<"$win")" == special:* ]] && exit 0
    W="address:$addr"
    [[ "$(jq -r .fullscreen <<<"$win")" != "0" ]] && d "hl.dsp.window.fullscreen({ action = \"unset\", window = \"$W\" })"
    jq -c '{floating, at, size, monitor}' <<<"$win" > "$STATE/$addr"

    read -r x y w h < <(dock_box "$(jq .monitor <<<"$win")")
    read -r ox oy ow oh < <(jq -r '[.at[0], .at[1], .size[0], .size[1]] | @tsv' <<<"$win")
    if [[ "$(jq .floating <<<"$win")" != "true" ]]; then
        d "hl.dsp.window.float({ action = \"enable\", window = \"$W\" })"
        # keep it where it was tiled, so the shrink starts from the right spot
        d "hl.dsp.window.resize({ x = $ow, y = $oh, \"exact\", window = \"$W\" })"
        d "hl.dsp.window.move({ x = $ox, y = $oy, \"exact\", window = \"$W\" })"
    fi
    d "hl.dsp.window.resize({ x = $w, y = $h, \"exact\", window = \"$W\" })"
    d "hl.dsp.window.move({ x = $x, y = $y, \"exact\", window = \"$W\" })"
    d "hl.dsp.window.set_prop({ prop = \"opacity\", value = \"0.0\", window = \"$W\" })"
    sleep $ANIM
    d "hl.dsp.window.move({ workspace = \"special:minimized\", follow = false, window = \"$W\" })"
    exit 0
fi

# restore: newest minimized window that still exists
for f in ${2:-$(ls -t "$STATE" 2>/dev/null)}; do
    hyprctl clients -j | jq -e --arg a "$f" 'any(.[]; .address == $a)' >/dev/null && { addr=$f; break; }
    rm -f "$STATE/$f"
done
[[ -z "$addr" ]] && { notify-send -a Windows "Nothing minimized"; exit 0; }
W="address:$addr"
saved=$(cat "$STATE/$addr")
rm -f "$STATE/$addr"

ws=$(hyprctl activeworkspace -j | jq .id)
mon=$(hyprctl activeworkspace -j | jq .monitorID)
read -r x y w h < <(dock_box "$mon")
read -r ox oy ow oh < <(jq -r '[.at[0], .at[1], .size[0], .size[1]] | @tsv' <<<"$saved")

# Start small and invisible at the bottom, then grow back to the old spot
d "hl.dsp.window.resize({ x = $w, y = $h, \"exact\", window = \"$W\" })"
d "hl.dsp.window.move({ x = $x, y = $y, \"exact\", window = \"$W\" })"
d "hl.dsp.window.move({ workspace = $ws, window = \"$W\" })"
sleep 0.05
d "hl.dsp.window.resize({ x = $ow, y = $oh, \"exact\", window = \"$W\" })"
d "hl.dsp.window.move({ x = $ox, y = $oy, \"exact\", window = \"$W\" })"
d "hl.dsp.window.set_prop({ prop = \"opacity\", value = \"1.0\", window = \"$W\" })"
d "hl.dsp.focus({ window = \"$W\" })"
if [[ "$(jq .floating <<<"$saved")" != "true" ]]; then
    sleep $ANIM
    d "hl.dsp.window.float({ action = \"disable\", window = \"$W\" })"
fi
