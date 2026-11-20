#!/bin/bash
# Renders the logo (logo.svg: glitch Apple with Arch-style cracks, violet->blue) when it or this script changes, then runs fastfetch
# Previous Apple logo: ~/Backups/config-backup-2026-10-28/logo-apple-v1/
PNG=~/.cache/fastfetch/arch-hollow.png
SVG=~/.config/fastfetch/logo.svg
if [[ ! -f $PNG || $SVG -nt $PNG || $0 -nt $PNG ]]; then
    mkdir -p "${PNG%/*}"
    rsvg-convert -w 512 -h 512 -o "$PNG" "$SVG"
fi
exec fastfetch "$@"
