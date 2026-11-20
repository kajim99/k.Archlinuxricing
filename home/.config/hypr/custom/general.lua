-- Glass windows: see-through when focused, a bit more when unfocused
hl.config({
    decoration = {
        active_opacity = 0.65,
        inactive_opacity = 0.55,
        fullscreen_opacity = 1.0,
        -- Neon glow: violet shadow around the focused window, faint dark one on the rest
        shadow = {
            range = 22,
            render_power = 3,
            color = "rgba(8703ff99)",
            color_inactive = "rgba(00000030)",
        },
    },
})

-- hypr-cube settings, re-applied on config reloads once the plugin is loaded
-- (scripts/plugins-load.sh loads the plugin at login, then reloads the config so this runs)
if hl.plugin and hl.plugin.cube then
    hl.config({ plugin = { hypr_cube = { faces = 4, duration_ms = 220, fov = 30, drag_zoom = 0.8, background = "rgba(140f24ff)" } } })
end

-- hyprbars: Mac-style title bar on every window (plugin loaded by scripts/plugins-load.sh).
-- hyprbars clears its buttons before every config reload, so they are re-added here each time.
if hl.plugin and hl.plugin.hyprbars then
    hl.config({ plugin = { hyprbars = {
        bar_height = 26,
        bar_color = "rgba(140f2480)",        -- dark violet glass
        bar_blur = true,
        ["col.text"] = "rgba(e0dcffff)",
        bar_text_font = "JetBrainsMono Nerd Font",
        bar_text_size = 10,
        bar_text_weight = "medium",
        bar_text_align = "center",
        bar_buttons_alignment = "left",      -- circles on the left, like macOS
        bar_padding = 12,
        bar_button_padding = 8,
        bar_part_of_window = true,
        bar_precedence_over_border = true,
        icon_on_hover = true,
        inactive_button_color = "rgba(4d4d4dff)",   -- macOS gray on unfocused windows
        on_double_click = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
    } } })
    local mini = os.getenv("HOME") .. "/.config/hypr/custom/scripts/minimize.sh"
    -- vivid macOS colors (dark-mode system red/yellow/green; user choice 2026-11-08, not themed on purpose): close (red),
    -- minimize (yellow, shrink animation; Super+U toggles), maximize (green); dark glyphs on hover
    hl.plugin.hyprbars.add_button({ bg_color = "rgb(ff453a)", fg_color = "rgb(4d0000)", size = 15, icon = "×",
        action = [[hyprctl dispatch 'hl.dsp.window.close()']] })
    hl.plugin.hyprbars.add_button({ bg_color = "rgb(ffd60a)", fg_color = "rgb(995700)", size = 15, icon = "−",
        action = mini })
    hl.plugin.hyprbars.add_button({ bg_color = "rgb(32d74b)", fg_color = "rgb(006500)", size = 15, icon = "+",
        action = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']] })
end
