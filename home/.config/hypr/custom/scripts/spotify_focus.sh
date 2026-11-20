#!/usr/bin/env bash
# Focus Spotify if it has a window, otherwise launch it
if hyprctl clients -j | grep -qiE '"class": "spotify"'; then
    hyprctl dispatch 'hl.dsp.focus({ window = "class:^([Ss]potify)$" })'
else
    spotify &
fi
