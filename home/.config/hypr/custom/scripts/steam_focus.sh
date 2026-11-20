#!/usr/bin/env bash
# Focus Steam if it has a window, otherwise launch it
if hyprctl clients -j | grep -qiE '"class": "steam"'; then
    hyprctl dispatch 'hl.dsp.focus({ window = "class:^([Ss]team)$" })'
else
    MANGOHUD=1 steam &   # invisible MangoHud logs FPS for the phone FPS page (2026-11-19)
fi
