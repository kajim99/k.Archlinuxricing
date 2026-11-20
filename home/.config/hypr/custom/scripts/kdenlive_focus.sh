#!/usr/bin/env bash
# Focus Kdenlive if it has a window, otherwise launch it
if hyprctl clients -j | grep -qiE '"class": "(org\.kde\.)?kdenlive"'; then
    hyprctl dispatch 'hl.dsp.focus({ window = "class:^(org\\.kde\\.)?kdenlive$" })'
else
    kdenlive &
fi
