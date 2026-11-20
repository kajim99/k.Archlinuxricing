#!/usr/bin/env bash
# Arch maintenance, 2026-10-30. Run with: sudo bash ~/.theme-setup/maintenance-root.sh
set -euo pipefail
step() { printf '\n\e[1;35m== %s\e[0m\n' "$*"; }

ARCHG_UUID=d7f647cd-9b48-4d5b-be6f-372c05cfc7da   # ARCH-G games SSD (Micron 512 GB)
ORPHANS="acpica arduino-builder arduino-builder-debug arduino-ctags-debug cli11 dart-sass extra-cmake-modules gi-docgen gnome-terminal-transparency-debug gst-plugin-gtk4 heroic-games-launcher-bin-debug html2markdown html2markdown-debug kernel-headers-musl libsoup libsoup-debug libwnck3 mpvpaper-debug node-gyp php-apache pnpm python-dbusmock python-gevent-eventemitter python-html2text python-inputs python-pydbus python-python-vlc python-steam python-vcrpy rust scdoc sequoia-sqv spicetify-cli-debug unifdef ventoy-bin-debug vulkan-headers wlogout-debug"

step "1/7 Install Timeshift, cron and ufw"
pacman -S --needed timeshift cronie ufw
systemctl enable --now cronie.service

step "2/7 Configure Timeshift (rsync, snapshots on ARCH-G, daily keep 5, /home excluded)"
mkdir -p /etc/timeshift
[ -f /etc/timeshift/timeshift.json ] && cp /etc/timeshift/timeshift.json /etc/timeshift/timeshift.json.bak
cat > /etc/timeshift/timeshift.json <<EOF
{
  "backup_device_uuid" : "$ARCHG_UUID",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "false",
  "include_btrfs_home_for_backup" : "false",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "false",
  "schedule_daily" : "true",
  "schedule_hourly" : "false",
  "schedule_boot" : "false",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "5",
  "count_hourly" : "6",
  "count_boot" : "5",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude" : [ "/home/**", "/root/**" ],
  "exclude-apps" : []
}
EOF

step "3/7 First snapshot (a few minutes the first time)"
timeshift --create --comments "before maintenance 2026-10-30" --tags O

step "4/7 Remove orphan packages (VLC is marked as kept)"
pacman -D --asexplicit vlc
pacman -Rns $ORPHANS

step "5/7 Package cache: clean now + weekly auto-clean (keep last 3 versions)"
paccache -rk3
paccache -ruk0
systemctl enable --now paccache.timer

step "6/7 Firewall: block incoming, allow outgoing"
ufw default deny incoming
ufw default allow outgoing
ufw --force enable
systemctl enable --now ufw.service

step "7/7 System update"
pacman -Syu

printf '\n\e[1;34mMAINTENANCE ROOT DONE\e[0m\n'
