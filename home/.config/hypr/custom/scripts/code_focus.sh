#!/usr/bin/env bash
# Focus VS Code if it has a window, otherwise launch it
if hyprctl clients -j | grep -qiE '"class": "code(-url-handler)?"'; then
    hyprctl dispatch 'hl.dsp.focus({ window = "class:^([Cc]ode)$" })'
else
    code &
fi
