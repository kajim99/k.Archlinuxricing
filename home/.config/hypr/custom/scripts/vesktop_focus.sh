#!/usr/bin/env bash
# Focus Vesktop (Discord) if it has a window, otherwise launch it
if hyprctl clients -j | grep -qiE '"class": "vesktop"'; then
    hyprctl dispatch 'hl.dsp.focus({ window = "class:^([Vv]esktop)$" })'
else
    vesktop &
fi
