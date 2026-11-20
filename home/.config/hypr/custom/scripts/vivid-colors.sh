#!/bin/bash
# Repaints end-4's pastel Material theme in vivid purple/blue on deep purple-navy, everywhere matugen writes colors:
# shell (colors.json), GTK3/4, Qt/KDE, fuzzel, hyprlock, Hyprland borders.
# Called by switchwall.sh right after it regenerates the theme. The old->new map is saved so the delayed KDE pass
# (kde-material-you-colors finishes in the background after us) can be remapped too.
MAP=~/.cache/vivid-colors-map.json

python3 -I - "$1" "$MAP" <<'EOF'
import json, os, re, sys

mode, map_path = sys.argv[1], sys.argv[2]
H = os.path.expanduser
COLORS = H("~/.local/state/quickshell/user/generated/colors.json")

NEW = {
    # violet accents
    "primary": "#8703ff", "on_primary": "#ffffff", "primary_container": "#45009e", "on_primary_container": "#ead9ff",
    "primary_fixed": "#ead9ff", "primary_fixed_dim": "#8703ff", "on_primary_fixed": "#1f0640",
    "on_primary_fixed_variant": "#5000c4", "inverse_primary": "#ac40ff", "surface_tint": "#8703ff",
    # blue accents (same blue as the fastfetch logo)
    "secondary": "#0059e7", "on_secondary": "#001d45", "secondary_container": "#112c5c", "on_secondary_container": "#d8e6ff",
    "secondary_fixed": "#d8e6ff", "secondary_fixed_dim": "#0059e7", "on_secondary_fixed": "#001433",
    "on_secondary_fixed_variant": "#112c5c",
    "tertiary": "#0059e7", "on_tertiary": "#001d45", "tertiary_container": "#112c5c", "on_tertiary_container": "#dbe7ff",
    "tertiary_fixed": "#d8e6ff", "tertiary_fixed_dim": "#0059e7", "on_tertiary_fixed": "#001433",
    "on_tertiary_fixed_variant": "#112c5c",
    # deep purple-navy surfaces, violet secondary text
    "background": "#0d0a1a", "surface": "#0d0a1a", "surface_dim": "#0d0a1a", "surface_bright": "#2e2552",
    "surface_container_lowest": "#08060f", "surface_container_low": "#120e24", "surface_container": "#17122e",
    "surface_container_high": "#1f1839", "surface_container_highest": "#282045", "surface_variant": "#282045",
    "on_background": "#f4f1ff", "on_surface": "#f4f1ff", "on_surface_variant": "#9e5fff",
    "outline": "#5600e8", "outline_variant": "#29008e",
    "inverse_surface": "#f4f1ff", "inverse_on_surface": "#17122e",
}

if mode == "--kde-only":
    remap = json.load(open(map_path))
else:
    # colors.json is fresh from matugen here: record old -> new (first role wins on shared old values)
    old = json.load(open(COLORS))
    remap = {}
    for role, new in NEW.items():
        o = old.get(role, "").lower().lstrip("#")
        if o and o not in remap:
            remap[o] = new.lstrip("#")
    json.dump(remap, open(map_path, "w"))
    old.update(NEW)
    # Shell only (colors.json is read by Quickshell alone): text/icons blue instead of white.
    # Apps keep white text because their files were remapped from NEW above, not from this.
    old.update({
        "on_background": "#0059e7", "on_surface": "#0059e7", "on_surface_variant": "#0059e7", "outline": "#004ac9",
    })
    json.dump(old, open(COLORS, "w"), indent=2)

# 6-digit hex, optionally followed by 2 alpha digits (fuzzel/hyprland use rrggbbaa); one pass, so no chained swaps
hex6 = re.compile(r"(?i)(?<![0-9a-f])([0-9a-f]{6})(?=(?:[0-9a-f]{2})?(?![0-9a-f]))")

def repaint(path):
    path = H(path)
    if not os.path.isfile(path):
        return
    text = open(path).read()
    new = hex6.sub(lambda m: remap.get(m.group(1).lower(), m.group(1)), text)
    if new != text:
        open(path, "w").write(new)

schemes = H("~/.local/share/color-schemes")
kde = ["~/.config/kdeglobals"] + [os.path.join(schemes, n) for n in os.listdir(schemes) if n.startswith("MaterialYouDark")]
others = ["~/.config/gtk-3.0/gtk.css", "~/.config/gtk-4.0/gtk.css", "~/.config/fuzzel/fuzzel_theme.ini",
          "~/.config/hypr/hyprlock/colors.conf", "~/.config/hypr/hyprland/colors.lua"]
for f in (kde if mode == "--kde-only" else others + kde):
    repaint(f)
EOF

if [[ "$1" != "--kde-only" ]]; then
    # Window borders: purple -> blue gradient on the focused window
    sed -i -E 's|^(\s*active_border\s*=\s*).*,$|\1{ colors = {"rgba(8703ffee)", "rgba(8703ffee)", "rgba(8703ffee)", "rgba(0059e7cc)"}, angle = 45 },|; s|(border_color = )"[^"]*"|\1"rgba(8703ffAA) rgba(0059e777)"|' ~/.config/hypr/hyprland/colors.lua
    hyprctl reload >/dev/null 2>&1
    # KDE's theme tool finishes after us in the background; repaint its output again once it's done
    setsid -f bash -c 'sleep 10; "$0" --kde-only' "$0" >/dev/null 2>&1 < /dev/null
fi
