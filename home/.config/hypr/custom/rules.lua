-- Glass: re-enable blur behind windows (end-4 disables it in hyprland/rules.lua)
hl.window_rule({ name = "glass-blur", match = { class = ".*" }, no_blur = false })

-- Keep browsers, media and games solid so pages and videos don't look washed out
hl.window_rule({ name = "solid-zen",     match = { class = "^(zen|zen-browser)$" }, opaque = true })
hl.window_rule({ name = "solid-firefox", match = { class = "^(firefox)$" },          opaque = true })
hl.window_rule({ name = "solid-media",   match = { class = "^(vlc|mpv)$" },          opaque = true })
-- Spotify is glass like other windows (0.85 focused / 0.75 unfocused from general.lua); frosted panels in Spicetify VioletNeon
hl.window_rule({ name = "solid-games",   match = { class = "^(steam_app_.*)$" },     opaque = true })
hl.window_rule({ name = "solid-sober",   match = { class = "^(org\\.vinegarhq\\.Sober|[Ss]ober)$" }, opaque = true })  -- Roblox (Sober flatpak)

-- Kitty handles its own transparency (background_opacity) so text stays sharp
hl.window_rule({ name = "solid-kitty",   match = { class = "^(kitty)$" },            opaque = true })

-- Glass left sidebar (notifications/calendar dashboard): blur behind it too
hl.layer_rule({ match = { namespace = "quickshell:sidebarLeft" }, ignore_alpha = 0.3 })

-- VS Code: see-through, a bit less than other windows so code stays readable (0.92 → 0.75 on 2026-11-08)
hl.window_rule({ name = "glass-code", match = { class = "^([Cc]ode)$" }, opacity = "0.75 0.70" })

-- Glass shell: blur behind the bar and every expandable panel/popup.
-- end-4's own blur rules use old names (bar[0-9]*, sideleft...), the shell now uses quickshell:<name>.
local glass_layers = "^quickshell:(bar|verticalBar|sidebarLeft|sidebarRight|overview|popup|notificationPopup|onScreenDisplay|mediaControls|cheatsheet|session|actionCenter|polkit|dock|wallpaperSelector|osk|wNotificationCenter|wOnScreenDisplay|wStartMenu|wTaskView)$"
hl.layer_rule({ match = { namespace = glass_layers }, blur = true })
hl.layer_rule({ match = { namespace = glass_layers }, ignore_alpha = 0.2 })

-- Extra workspaces made with `wp -N` (fish): keep them persistent across config reloads.
-- The count lives in this Hyprland session's runtime folder, so logout/reboot goes back to the base 5.
do
    local sig, run = os.getenv("HYPRLAND_INSTANCE_SIGNATURE"), os.getenv("XDG_RUNTIME_DIR")
    local f = sig and run and io.open(run .. "/hypr/" .. sig .. "/wp-count", "r")
    if f then
        local count = tonumber(f:read("*l")) or 5
        f:close()
        for ws = 6, count do
            hl.workspace_rule({ workspace = tostring(ws), persistent = true })
        end
    end
end

-- Floating popup terminal for `wp` / `tools` run from the Super search bar (~/.local/bin/wp, tools)
hl.window_rule({ match = { class = "^tools-popup$" }, float = true })
hl.window_rule({ match = { class = "^tools-popup$" }, center = true })
hl.window_rule({ match = { class = "^tools-popup$" }, size = {"(monitor_w*0.45)", "(monitor_h*0.60)"} })

-- Sound popup (~/.local/bin/audio-panel, Super+Ctrl+V): small floating card in the middle
hl.window_rule({ match = { class = "^dev\\.kareem\\.AudioPanel$" }, float = true })
hl.window_rule({ match = { class = "^dev\\.kareem\\.AudioPanel$" }, center = true })
hl.window_rule({ match = { class = "^dev\\.kareem\\.AudioPanel$" }, pin = true })
hl.window_rule({ match = { class = "^dev\\.kareem\\.AudioPanel$" }, opaque = true })
