#!/bin/bash
# Back to medium neon #7c00ed with the even violet/blue split. Login screen/rEFInd: re-run the sudo cp line afterwards.
tar xzf /home/kareem/Backups/config-backup-2026-10-28/before-violet-standout-2026-10-30.tar.gz -C / && cp ~/Backups/videos/deep-space-matrix-login.before-violet-standout.mp4 ~/Videos/Wallpapers/deep-space-matrix-login.mp4
hyprctl reload >/dev/null; pkill -USR1 -x kitty
S=~/.config/hypr/custom/scripts/matrix-toggle.sh; $S; sleep 3; $S start
echo "Violet stand-out undone"
