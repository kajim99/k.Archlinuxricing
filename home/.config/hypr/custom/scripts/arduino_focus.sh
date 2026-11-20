#!/usr/bin/env bash
# Focus Arduino IDE if it has a window, otherwise launch it
if hyprctl clients -j | grep -qiE '"class": "arduino[ -]?ide"'; then
    hyprctl dispatch 'hl.dsp.focus({ window = "class:^([Aa]rduino[ -]?(IDE|ide))$" })'
else
    "$HOME/.local/bin/arduino-ide" &
fi
