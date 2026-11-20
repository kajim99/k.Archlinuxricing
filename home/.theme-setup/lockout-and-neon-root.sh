#!/usr/bin/env bash
# 2026-10-30. Run with: sudo bash ~/.theme-setup/lockout-and-neon-root.sh
set -euo pipefail
H=/home/kareem

# 1. Failed-password lockout: 7 tries, then 2 minutes (was Arch default 3 tries / 10 min).
#    Shared by sudo, SDDM login and the lock screen.
cp /etc/security/faillock.conf /etc/security/faillock.conf.bak-2026-10-30
sed -i -E '/^\s*(deny|unlock_time)\s*=/d' /etc/security/faillock.conf
printf '\n# Set 2026-10-30: 7 tries, then locked for 2 minutes\ndeny = 7\nunlock_time = 120\n' >> /etc/security/faillock.conf
faillock --user kareem --reset

# 2. Neon violet login screen + rEFInd logo
cp $H/Backups/config-backup-2026-10-28/sddm-login/astronaut.conf.user /usr/share/sddm/themes/sddm-astronaut-theme/Themes/
cp $H/Videos/Wallpapers/deep-space-matrix-login.mp4 /usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds/
cp $H/.theme-setup/arch-logo.png /efi/EFI/refind/themes/pb/arch.png

echo "ALL DONE: 7 tries / 2 min, login screen + rEFInd updated"
