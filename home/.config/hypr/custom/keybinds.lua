hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- Super+S: Spotify instead of scratchpad (scratchpad stays on Ctrl+Super+S)
hl.unbind("SUPER + S")
hl.bind("SUPER + S", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/spotify_focus.sh"), { description = "App: Spotify" })

-- Super+D: Vesktop (Discord) instead of end-4's Maximize (dropped by choice 2026-11-17; fullscreen is Super+F)
hl.unbind("SUPER + D")
hl.bind("SUPER + D", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/vesktop_focus.sh"), { description = "App: Vesktop (Discord)" })

-- Flip the focused split between top/bottom and side by side
hl.bind("SUPER + SHIFT + J", hl.dsp.layout("togglesplit"), { description = "Window: Toggle split direction" })

-- Print: snip a region, copy to clipboard and save to ~/Pictures/Screenshots
-- (moved from Super+Shift+S 2026-11-08; replaces end-4's Print = full screenshot to clipboard)
hl.unbind("Print")
hl.bind("Print", hl.dsp.exec_cmd("pidof slurp || hyprshot --freeze --mode region --output-folder " .. os.getenv("HOME") .. "/Pictures/Screenshots"), { description = "Utilities: Screen snip" })

-- Super+Shift+S: force-kill Spotify right away, like End Task (Super+S opens it again)
hl.unbind("SUPER + SHIFT + S")
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("pkill -KILL -x spotify"), { description = "App: Force-kill Spotify" })
-- Super+Shift+Q does the same: the Fantech ATOM drops S while Super + LEFT Shift are held (Right Shift works)
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("pkill -KILL -x spotify"), { description = "App: Force-kill Spotify" })

-- Super+Shift+D: display off right away, everything keeps running; any key or mouse move wakes it
-- (the delay stops the key release from waking it again; also in the Ctrl+Alt+Delete session menu)
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("sh -c \"sleep 0.6; hyprctl dispatch 'hl.dsp.dpms({ action = \\\"disable\\\" })'\""), { description = "Display: Turn off screen" })

-- Matrix rain over the wallpaper: on/off (off stops it completely)
hl.bind("CTRL + SUPER + Slash", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/matrix-toggle.sh"), { description = "Desktop: Toggle matrix rain" })

-- Only 5 workspaces: drop Super(+Alt)+6..0 (number row, raw keycodes and keypad)
do
    local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
    local numpadkey = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }
    for i = 6, 10 do
        hl.unbind("SUPER + " .. (i % 10))
        hl.unbind("SUPER + code:" .. numberkey[i])
        hl.unbind("SUPER + code:" .. numpadkey[i])
        hl.unbind("SUPER + ALT + " .. (i % 10))
        hl.unbind("SUPER + ALT + code:" .. numpadkey[i])
    end
end

-- Relative workspace moves stop at 1 and 5 (see scripts/ws-step.sh)
do
    local step = os.getenv("HOME") .. "/.config/hypr/custom/scripts/ws-step.sh "
    local focus = {
        ["CTRL + SUPER + Left"] = "-1", ["CTRL + SUPER + Right"] = "+1",
        ["SUPER + Page_Up"] = "-1", ["SUPER + Page_Down"] = "+1",
        ["CTRL + SUPER + Page_Up"] = "-1", ["CTRL + SUPER + Page_Down"] = "+1",
        ["SUPER + mouse_up"] = "-1", ["SUPER + mouse_down"] = "+1",
        ["CTRL + SUPER + mouse_up"] = "-1", ["CTRL + SUPER + mouse_down"] = "+1",
        ["CTRL + SUPER + BracketLeft"] = "-1", ["CTRL + SUPER + BracketRight"] = "+1",
        ["CTRL + SUPER + Up"] = "-5", ["CTRL + SUPER + Down"] = "+5",  -- jump to first/last
    }
    local move = {
        ["SUPER + SHIFT + mouse_up"] = "-1", ["SUPER + SHIFT + mouse_down"] = "+1",
        ["SUPER + ALT + mouse_up"] = "-1", ["SUPER + ALT + mouse_down"] = "+1",
        ["SUPER + SHIFT + Page_Up"] = "-1", ["SUPER + SHIFT + Page_Down"] = "+1",
        ["SUPER + ALT + Page_up"] = "-1", ["SUPER + ALT + Page_down"] = "+1",
        ["CTRL + SUPER + SHIFT + Left"] = "-1", ["CTRL + SUPER + SHIFT + Right"] = "+1",
    }
    -- ±1 steps spin the 3D cube (hypr-cube plugin, loaded by scripts/cube-load.sh) when it is
    -- loaded; without it (e.g. after a Hyprland update, before cube-rebuild) they use ws-step.sh.
    -- Cube switched off 2026-11-05 (its last build always returned to workspace 1). To turn it
    -- back on: set CUBE_ON = true and rename ~/.local/share/hypr-plugins/hypr-cube.so.off to .so
    local CUBE_ON = false
    for key, dir in pairs(focus) do
        hl.unbind(key)
        if dir == "+1" or dir == "-1" then
            hl.bind(key, function()
                if CUBE_ON and hl.plugin and hl.plugin.cube then
                    if dir == "+1" then hl.plugin.cube.next() else hl.plugin.cube.prev() end
                else
                    hl.dispatch(hl.dsp.exec_cmd(step .. dir))
                end
            end)
        else
            hl.bind(key, hl.dsp.exec_cmd(step .. dir))
        end
    end
    -- Super+Alt+left-drag: grab the cube and spin it freely (snaps to a face, Esc cancels)
    hl.bind("SUPER + ALT + mouse:272", function()
        if CUBE_ON and hl.plugin and hl.plugin.cube then hl.plugin.cube.drag() end
    end)
    for key, dir in pairs(move) do
        hl.unbind(key)
        hl.bind(key, hl.dsp.exec_cmd(step .. dir .. " move"))
    end
end

-- Super+C: focus VS Code if open, otherwise launch it (replaces end-4's "first available editor")
hl.unbind("SUPER + C")
hl.bind("SUPER + C", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/code_focus.sh"), { description = "App: VS Code" })

-- Games: Super+G Steam, Super+H Heroic (focus if open); widget overlay moved to Super+Shift+G
hl.unbind("SUPER + G")
hl.bind("SUPER + G", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/steam_focus.sh"), { description = "App: Steam" })
hl.bind("SUPER + H", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/heroic_focus.sh"), { description = "App: Heroic" })
hl.bind("SUPER + SHIFT + G", hl.dsp.global("quickshell:overlayToggle"), { description = "Shell: Toggle widget overlay" })

-- Super+A: focus Arduino IDE if open, otherwise launch it (left sidebar stays on Super+B / Super+O)
hl.unbind("SUPER + A")
hl.bind("SUPER + A", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/arduino_focus.sh"), { description = "App: Arduino IDE" })

-- Super+Shift+E: focus Kdenlive if open, otherwise launch it
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/kdenlive_focus.sh"), { description = "App: Kdenlive" })

-- Super tap -> overview is decided by scripts/super-watch.py (race-free); drop Hyprland's Super-release binds
hl.unbind("SUPER + SUPER_L")
hl.unbind("SUPER + SUPER_R")

-- Super+U: minimize the focused window (shrink animation, like the violet circle); with nothing
-- focused it brings back the last minimized one instead (see scripts/minimize.sh)
hl.bind("SUPER + U", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom/scripts/minimize.sh toggle"), { description = "Window: Minimize / restore" })

-- Super+Ctrl+V: simple sound popup (outputs, volume, mic, per-app) instead of pavucontrol; press again to close
hl.unbind("CTRL + SUPER + V")
hl.bind("CTRL + SUPER + V", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/audio-panel"), { description = "App: Sound settings" })

-- Super+R: Roblox (Sober flatpak, runs on the RTX 4050 via flatpak env overrides)
hl.bind("SUPER + R", hl.dsp.exec_cmd("flatpak run --user org.vinegarhq.Sober"), { description = "App: Roblox (Sober)" })
