#!/usr/bin/env bash
# Focus Heroic if it has a window, otherwise launch it
if hyprctl clients -j | grep -qiE '"class": "heroic"'; then
    hyprctl dispatch 'hl.dsp.focus({ window = "class:^([Hh]eroic)$" })'
else
    MANGOHUD=1 heroic &   # invisible MangoHud logs FPS for the phone FPS page (2026-11-19)
fi
