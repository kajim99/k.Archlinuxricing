#!/bin/bash
# Resume Rocket League (legendary "Sugar") verify+repair with retries; survives Claude session restarts.
export LEGENDARY_CONFIG_PATH=~/.config/heroic/legendaryConfig/legendary
LEG=/opt/Heroic/resources/app.asar.unpacked/build/bin/x64/linux/legendary
LOG=~/.local/state/Heroic/logs/games/Sugar_legendary/repair-cli.log
for try in 1 2 3 4 5 6 7 8; do
  echo "=== attempt $try $(date +%T)" >> $LOG
  $LEG repair Sugar -y >> $LOG 2>&1
  if jq -e '.Sugar.needs_verification == false' $LEGENDARY_CONFIG_PATH/installed.json >/dev/null; then
    notify-send -a Heroic "Rocket League repaired" "Ready to play — open Heroic (Super+H)"; echo "REPAIR-OK"; exit 0
  fi
  sleep 20
done
notify-send -a Heroic "Rocket League repair failed" "Check repair-cli.log"; exit 1
