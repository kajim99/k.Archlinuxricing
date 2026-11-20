#!/usr/bin/env python3
"""Darken every violet in the theme files by a lightness factor (2026-10-30: 0.75, #8a2be2 -> #6818b1).

Only violets change: hue 256-295 deg, saturation > 0.35, lightness 0.17-0.88. Near-black purple-navy
backgrounds and near-white text are left alone.  Usage: darken-violet.py [--dry-run] [--neon] [--hue LO-HI] [--lmin L] FILE...
2026-10-30 blue pass: --hue 195-245 --lmin 0.22 (#2f6fd6 -> #2053a4).
Formats: #rrggbb / #rrggbbaa, #aarrggbb in .qml, bare rrggbb(aa) in Hyprland/fuzzel/hyprlock files,
"r,g,b" in KDE color files, (r, g, b) tuples in .py files.
"""
import colorsys
import re
import sys

FACTOR = 0.75
BARE_HEX = ("colors.lua", "fuzzel_theme.ini", "colors.conf", "vivid-colors.sh")


HUE, LMIN = (256, 295), 0.17


def darker(r, g, b):
    h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    if not (HUE[0] / 360 <= h <= HUE[1] / 360 and s > 0.35 and LMIN < l < 0.88):
        return None
    r2, g2, b2 = colorsys.hls_to_rgb(h, min(l * FACTOR, 0.88), 1.0 if NEON else s)
    return round(r2 * 255), round(g2 * 255), round(b2 * 255)


def hex_sub(m):
    pre, digits = m.group(1), m.group(2)
    argb = PATH.endswith(".qml") and len(digits) == 8
    rgb = digits[2:] if argb else digits[:6]
    new = darker(*(int(rgb[i:i + 2], 16) for i in (0, 2, 4)))
    if new is None:
        return m.group(0)
    out = "%02x%02x%02x" % new
    if rgb.isupper():
        out = out.upper()
    return pre + (digits[:2] + out if argb else out + digits[6:])


def triple_sub(m):
    new = darker(*(int(m.group(i)) for i in (2, 4, 6)))
    if new is None or max(int(m.group(i)) for i in (2, 4, 6)) > 255:
        return m.group(0)
    return f"{m.group(1)}{new[0]}{m.group(3)}{new[1]}{m.group(5)}{new[2]}"


args = sys.argv[1:]
dry = "--dry-run" in args
# --neon (2026-10-30 violet pass, #6818b1 -> #7200d9): full saturation, lightness x1.08
NEON = "--neon" in args
if NEON:
    FACTOR = 1.08; args.remove("--neon")
# --factor F overrides the lightness factor (2026-10-30 medium neon: 1.092, #7200d9 -> #7c00ed)
if "--factor" in args:
    i = args.index("--factor"); FACTOR = float(args[i + 1]); del args[i:i + 2]
if "--hue" in args:
    i = args.index("--hue"); HUE = tuple(map(float, args[i + 1].split("-"))); del args[i:i + 2]
if "--lmin" in args:
    i = args.index("--lmin"); LMIN = float(args[i + 1]); del args[i:i + 2]
for PATH in [a for a in args if a != "--dry-run"]:
    text = open(PATH).read()
    bare = PATH.endswith(BARE_HEX)
    hexre = r"(#|(?<![0-9A-Za-z]))([0-9a-fA-F]{8}|[0-9a-fA-F]{6})(?![0-9A-Za-z])" if bare else r"(#)([0-9a-fA-F]{8}|[0-9a-fA-F]{6})(?![0-9A-Za-z])"
    new = re.sub(hexre, hex_sub, text)
    if PATH.endswith(".colors") or PATH.endswith("kdeglobals"):
        new = re.sub(r"(=|(?<=\n))(\d{1,3})(,)(\d{1,3})(,)(\d{1,3})(?![\d,])", triple_sub, new)
    if PATH.endswith(".py"):
        new = re.sub(r"(\()(\d{1,3})(, *)(\d{1,3})(, *)(\d{1,3})(?=\))", triple_sub, new)
    changes = sum(1 for a, b in zip(text.splitlines(), new.splitlines()) if a != b)
    print(f"{changes:4} lines  {PATH}")
    if not dry and new != text:
        open(PATH, "w").write(new)
