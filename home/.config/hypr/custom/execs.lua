
-- Matrix rain layer over the wallpaper (toggle: see custom/keybinds.lua)
hl.on("hyprland.start", function ()
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/matrix-toggle.sh start")
end)

-- Matrix rain watcher: restarts the rain if it dies (respects the off toggle)
hl.on("hyprland.start", function ()
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/matrix-toggle.sh watch")
end)

-- Violet/blue cursor (Bibata recolor in ~/.local/share/icons/Bibata-Violet); runs after end-4's setcursor
hl.on("hyprland.start", function ()
    hl.exec_cmd("hyprctl setcursor Bibata-Violet 24")
end)

-- Restart the Quickshell desktop automatically if it stops (see scripts/qs-watchdog.sh)
hl.on("hyprland.start", function ()
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/qs-watchdog.sh")
end)

-- Super combos must not also open the overview on Super release (see scripts/super-watch.py)
hl.on("hyprland.start", function ()
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/super-watch.sh")
end)

-- Hyprland plugins (hypr-cube 3D workspaces, hyprbars Mac title bars); says to run plugins-rebuild if one won't load
hl.on("hyprland.start", function ()
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/plugins-load.sh")
end)

-- Battery mode: power saver, 60 Hz, paused wallpaper/rain, no blur, dimmer screen on battery; all back on AC (see scripts/power-watch.sh)
hl.on("hyprland.start", function ()
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/power-watch.sh")
end)

-- Portals crash on logout and systemd gives up before the next login; clear that and restart them (2026-11-17)
hl.on("hyprland.start", function ()
    hl.exec_cmd("sh -c 'sleep 2; systemctl --user reset-failed; systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal-gtk plasma-xdg-desktop-portal-kde xdg-desktop-portal'")
end)

-- KDE Connect daemon: Hyprland skips /etc/xdg/autostart, so start it here (2026-11-20)
hl.on("hyprland.start", function ()
    hl.exec_cmd("kdeconnectd")
end)

-- OFF 2026-11-20: PhoneBox moved to the Tab A7 (no tethering needed). Uncomment to bring it back.
-- Phone plugged in -> USB tethering on, as a private link for KDE Connect only (see ~/.local/bin/phone-tether)
-- hl.on("hyprland.start", function ()
--     hl.exec_cmd("$HOME/.local/bin/phone-tether")
-- end)
