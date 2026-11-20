#!/bin/bash
# Theme setup (root part): Papirus icons, skip GRUB menu, violet/blue TTY colors. Run with: sudo bash ~/.theme-setup/apply-root.sh
set -e
pacman -S --needed --noconfirm papirus-icon-theme
cp -n /etc/default/grub /etc/default/grub.bak-2026-10-29
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/; s/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub
grep -q 'vt.default_red' /etc/default/grub || sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 vt.default_red=13,255,93,255,47,138,79,217,79,255,137,255,61,177,137,255 vt.default_grn=10,92,228,199,111,43,214,211,71,122,240,217,127,75,221,255 vt.default_blu=26,138,199,119,214,226,255,230,117,162,216,154,232,255,255,255"/' /etc/default/grub
grep -E '^GRUB_(TIMEOUT|TIMEOUT_STYLE|CMDLINE_LINUX_DEFAULT)=' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
echo "ROOT PART DONE"
