#!/usr/bin/env bash
# Installs Kareem's Arch rice (Hyprland + end-4, violet/blue) on a fresh Arch install.
#   git clone https://github.com/kareemnubani4-beep/k.Archlinuxricing ~/dotfiles && ~/dotfiles/restore.sh
# DRY=1 ~/dotfiles/restore.sh   -> only prints what it would do, changes nothing.
# Order: sudo once -> base tools + yay -> end-4 (pinned) -> packages -> your files over end-4's
#        -> system files/services/groups -> cloned repos (+ local patches) -> checklist.
# Never touches the bootloader; rEFInd stays a manual step in the checklist.
set -uo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; S="$R/system"
DRY="${DRY:-}"; STAMP=$(date +%F-%H%M); BK="$HOME/restore-backup-$STAMP"
END4_COMMIT=2f0c8bf42b803f4d597572f2a014d4e78d7d9f26
CLONED="$HOME/Projects/Cloned"
FAILED=()

say() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
run() { printf '\033[34m+ %s\033[0m\n' "$*"; [ -n "$DRY" ] || "$@" || { FAILED+=("$*"); return 1; }; }

[ "$EUID" -ne 0 ] || { echo "Run as your user, not root (it asks for sudo itself)."; exit 1; }
[ -d "$R/home" ] || { echo "No $R/home - is this the dotfiles repo?"; exit 1; }
[ -n "$DRY" ] && say "DRY RUN - nothing will be changed"

say "sudo (asked once)"
if [ -z "$DRY" ]; then
  sudo -v || exit 1
  while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
fi

say "Base tools + yay"
run sudo pacman -Syu --needed --noconfirm base-devel git rsync
if ! command -v yay >/dev/null; then
  run git clone https://aur.archlinux.org/yay.git "$CLONED/yay" && run bash -c "cd '$CLONED/yay' && makepkg -si --noconfirm"
fi

say "end-4 dots-hyprland at pinned commit ${END4_COMMIT:0:7}"
[ -d "$CLONED/dots-hyprland" ] || run git clone https://github.com/end-4/dots-hyprland.git "$CLONED/dots-hyprland"
run git -C "$CLONED/dots-hyprland" checkout -q "$END4_COMMIT"
run bash -c "cd '$CLONED/dots-hyprland' && ./setup install -f -s"

say "Packages (official repos, then AUR)"
if [ -z "$DRY" ]; then
  mapfile -t avail < <(comm -12 <(grep -vxFf "$R/packages-aur.txt" "$R/packages-native.txt" | sort) <(pacman -Slq | sort -u))
  missing=$(comm -23 <(grep -vxFf "$R/packages-aur.txt" "$R/packages-native.txt" | sort) <(pacman -Slq | sort -u))
  [ -n "$missing" ] && echo "Not in repos anymore, skipped: $missing"
  run sudo pacman -S --needed --noconfirm "${avail[@]}"
  run yay -S --needed --noconfirm $(cat "$R/packages-aur.txt")
else
  echo "+ pacman -S --needed $(grep -vxcFf "$R/packages-aur.txt" "$R/packages-native.txt") repo packages; yay -S $(wc -l < "$R/packages-aur.txt") AUR packages"
fi
if [ -s "$S/flatpaks.txt" ]; then
  while read -r app inst; do
    [ -n "$app" ] || continue
    run flatpak remote-add --if-not-exists "--$inst" flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    run flatpak install -y --noninteractive "--$inst" flathub "$app"
  done < "$S/flatpaks.txt"
fi

say "Your files over end-4's (replaced files saved in $BK)"
run rsync -a --backup --backup-dir="$BK" "$R/home/" "$HOME/"
if [ "$HOME" != /home/kareem ]; then  # files were written on a machine where home = /home/kareem
  (cd "$R/home" && grep -rlI /home/kareem . ) | while read -r f; do run sed -i "s|/home/kareem|$HOME|g" "$HOME/${f#./}"; done
fi

say "System files, services, groups"
for f in /etc/systemd/system/refind-first.service /etc/sddm.conf.d/theme.conf \
         /etc/tmpfiles.d/loq-power.conf /etc/tmpfiles.d/platform-profile.conf; do
  [ -f "$S$f" ] && run sudo install -D -m644 "$S$f" "$f"
done
[ -f "$S/usr/local/bin/refind-first" ] && run sudo install -D -m755 "$S/usr/local/bin/refind-first" /usr/local/bin/refind-first
T=/usr/share/sddm/themes/sddm-astronaut-theme/Themes
[ -d "$T" ] && run sudo install -m644 "$S/astronaut.conf.user" "$T/astronaut.conf.user"
run sudo systemd-tmpfiles --create
run sudo systemctl daemon-reload
while read -r u; do
  [ -n "$u" ] && [[ $u != *@.* ]] && systemctl cat "$u" >/dev/null 2>&1 && run sudo systemctl enable "$u"
done < "$S/system-units.txt"
for g in $(cat "$S/groups.txt"); do
  [ "$g" = "$USER" ] || { getent group "$g" >/dev/null && run sudo usermod -aG "$g" "$USER"; }
done
run systemctl --user daemon-reload
while read -r u; do
  [ -n "$u" ] && systemctl --user cat "$u" >/dev/null 2>&1 && run systemctl --user enable "$u"
done < "$S/user-units.txt"

say "Cloned repos (+ your local patches)"
while read -r name url _commit; do
  d="$CLONED/$name"; [ -d "$d" ] || run git clone -q "$url" "$d"
  if [ -f "$S/patches/$name/BASE" ]; then
    read -r branch base < "$S/patches/$name/BASE"
    run git -C "$d" checkout -q -B "$branch" "$base" && run git -C "$d" am -q "$S/patches/$name"/*.patch
  fi
done < "$S/cloned-repos.txt"

say "Done. Manual steps left:"
cat <<'EOF'
 1. Reboot, log in to Hyprland, then run:  plugins-rebuild
 2. rEFInd (bootloader, never automatic): sudo refind-install, then your own theme
 3. Spotify: log in, then: spicetify backup apply
 4. Hardware-specific bits (Lenovo power files, NVIDIA prime-run): edit for your machine
EOF
[ -d "$BK" ] && echo "Replaced files saved in: $BK"
if [ ${#FAILED[@]} -gt 0 ]; then
  printf '\n\033[1;31mThese steps failed (rest continued):\033[0m\n'; printf '  - %s\n' "${FAILED[@]}"
fi
