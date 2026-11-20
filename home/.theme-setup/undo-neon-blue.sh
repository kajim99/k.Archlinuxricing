#!/bin/bash
# Back to blue #2053a4 (violet stays medium neon). Login screen/rEFInd: re-run the sudo cp line afterwards.
tar xzf /home/kareem/Backups/config-backup-2026-10-28/medium-neon-before-blue-2026-10-30.tar.gz -C / && cp ~/Backups/videos/deep-space-matrix-login.before-neon-blue.mp4 ~/Videos/Wallpapers/deep-space-matrix-login.mp4
hyprctl reload >/dev/null; pkill -USR1 -x kitty
S=~/.config/hypr/custom/scripts/matrix-toggle.sh; $S; sleep 3; $S start
echo "Blue restored to #2053a4"
