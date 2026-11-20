#!/usr/bin/env python3
# Tapping Super alone toggles the overview. Hyprland 0.57 no longer cancels Super-release after combos, and
# telling Quickshell "not a tap" raced with fast key releases, so this decides by itself from the raw input:
# Super down -> up with no other key/mouse button in between (and held < 1 s) = tap -> toggle the overview.
# Hyprland's own SUPER+SUPER_L release bind is removed in custom/keybinds.lua.
# Needs read access to /dev/input (user is in the "input" group). Started by super-watch.sh.
import os, select, struct, subprocess, time

EV_KEY = 1
SUPER = {125, 126}                     # KEY_LEFTMETA, KEY_RIGHTMETA
EVENT = struct.Struct("llHHi")
TOGGLE = ["hyprctl", "dispatch", 'hl.dsp.global("quickshell:overviewWorkspacesToggle")']
MAX_TAP = 1.0                          # seconds; longer holds are not taps


def key_devices():
    """Input devices that report keys or mouse buttons (from /proc/bus/input/devices)."""
    devs, block = [], {}
    for line in open("/proc/bus/input/devices").read().splitlines() + [""]:
        if line.startswith("H: Handlers="):
            block["handlers"] = line.split("=", 1)[1].split()
        elif line.startswith("B: EV="):
            block["ev"] = int(line.split("=", 1)[1], 16)
        elif not line.strip() and block:
            if block.get("ev", 0) & (1 << EV_KEY):
                devs += [f"/dev/input/{h}" for h in block.get("handlers", []) if h.startswith("event")]
            block = {}
    return devs


def main():
    fds = {}
    for path in key_devices():
        try:
            fds[os.open(path, os.O_RDONLY | os.O_NONBLOCK)] = path
        except OSError:
            pass
    held = set()          # Super keys currently down
    tap = False           # still a clean tap (nothing else pressed since Super went down)
    since = 0.0
    while True:
        ready, _, _ = select.select(list(fds), [], [])
        for fd in ready:
            try:
                data = os.read(fd, EVENT.size * 64)
            except OSError:   # device unplugged
                os.close(fd); del fds[fd]; continue
            for i in range(0, len(data) - EVENT.size + 1, EVENT.size):
                _, _, typ, code, value = EVENT.unpack_from(data, i)
                if typ != EV_KEY:
                    continue
                if code in SUPER:
                    if value == 1:
                        if not held:
                            tap, since = True, time.monotonic()
                        held.add(code)
                    elif value == 0:
                        held.discard(code)
                        if not held and tap and time.monotonic() - since < MAX_TAP:
                            subprocess.Popen(TOGGLE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                        if not held:
                            tap = False
                elif value == 1:
                    tap = False   # any other key or button (with or without Super) cancels the tap


if __name__ == "__main__":
    main()
