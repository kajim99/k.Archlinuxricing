#!/bin/bash
# Loads the Hyprland plugins in ~/.local/share/hypr-plugins (hypr-cube: 3D cube workspaces,
# hyprbars: Mac-style title bars), then reloads the config so their settings in
# custom/general.lua (guarded by `if hl.plugin.<name>`) apply. Run at Hyprland start and by
# plugins-rebuild. A plugin built for another Hyprland version refuses to load; things then
# fall back (normal workspace switching, no title bars) until `plugins-rebuild`.
failed=()
for so in ~/.local/share/hypr-plugins/*.so; do
    name=$(basename "$so" .so)
    hyprctl plugin list | grep -q "Plugin $name " && continue
    hyprctl plugin load "$so" | grep -qx ok || failed+=("$name")
done
hyprctl reload config-only >/dev/null
if (( ${#failed[@]} )); then
    notify-send -a "Plugins" "Some Hyprland plugins are off: ${failed[*]}" "Hyprland was updated, so they need a rebuild. Run: plugins-rebuild"
fi
