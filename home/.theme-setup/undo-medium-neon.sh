#!/bin/bash
# Back to slightly-neon violet (#7200d9). Login screen/rEFInd: re-run the sudo cp line afterwards.
tar xzf /home/kareem/Backups/Configs/config-backup-2026-10-28/slight-neon-2026-10-30.tar.gz -C / && cp ~/Backups/Videos/deep-space-matrix-login.slight-neon.mp4 ~/Videos/Wallpapers/deep-space-matrix-login.mp4
hyprctl reload >/dev/null; pkill -USR1 -x kitty
S=~/.config/hypr/custom/scripts/matrix-toggle.sh; $S; sleep 3; $S start
echo "Back to slightly neon"
