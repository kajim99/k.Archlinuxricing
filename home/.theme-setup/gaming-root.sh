#!/bin/bash
# Gaming setup (root part): enable multilib, install Steam + 32-bit NVIDIA/Intel Vulkan drivers + GameMode.
# Run with: sudo bash ~/.theme-setup/gaming-root.sh
set -e
cp -n /etc/pacman.conf /etc/pacman.conf.bak-2026-10-29-multilib
sed -i '/^#\[multilib\]$/{s/^#//;n;s/^#Include/Include/}' /etc/pacman.conf
grep -A1 '^\[multilib\]' /etc/pacman.conf
pacman -Syu --needed --noconfirm steam lib32-nvidia-utils vulkan-intel lib32-vulkan-intel gamemode lib32-gamemode ttf-liberation
usermod -aG gamemode "$SUDO_USER"
echo "GAMING ROOT DONE"
