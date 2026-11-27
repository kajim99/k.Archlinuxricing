#!/usr/bin/env python3
# Matrix rain, N-CM style (2026-11-16, ported from the Windows Lively wallpaper Documents\windows-theme\N-CM):
# ASCII + katakana, each character violet or neon blue (~60% violet, ~15% in-between), on solid #05010d.
# One step every 55 ms; old characters fade into the background like the canvas trail (fade 0.07 per step).
# Runs inside a solid kitty panel on the wallpaper layer (see matrix-toggle.sh). One column = 2 cells, so
# full-width katakana fit and the spacing matches the 16 px Windows grid.
# SIGRTMIN+1 / SIGRTMIN+2 = split colors on/off (lock screen): deep violet left half, blue right half.
# SIGUSR1 = rewind: every column is pulled back up off the top, then the script exits.
# SIGRTMIN+3 / SIGRTMIN+4 = red mode on/off (boot-alarm, 2026-11-27): new drops red, old ones fade out.
# Writes its cell size to $XDG_RUNTIME_DIR/matrix-rain.cell ("<cell w px> <cell h px>") so boot-alarm moves in rain rows.
import fcntl, os, random, shutil, signal, struct, sys, termios, time

ASCII = [chr(i) for i in range(33, 127)]
KATA = list("アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲンｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉ")
CHARS = ASCII + KATA
VIOLET = (135, 3, 255)
BLUE = (0, 89, 231)
BG = (5, 1, 13)
VIOLET_SHARE = 0.6
BLEND_SHARE = 0.15
STEP = 0.055           # seconds per step (cmatrix-like)
KEEP = 1 - 0.07        # brightness kept per step (canvas fade 0.07)
GONE = 0.04            # below this a cell is erased
RESTART = 0.025        # chance per step that a column past the bottom starts again
CW = 2                 # terminal cells per rain column
REWIND_SPEED = 2       # rows per step while rewinding
SPLIT = False          # set by the lock screen
RED = False            # set by boot-alarm
REDS = ((255, 30, 60), (150, 0, 24))


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def pick_color():
    if random.random() < BLEND_SHARE:
        return mix(VIOLET, BLUE, 0.3 + random.random() * 0.4)
    return VIOLET if random.random() < VIOLET_SHARE else BLUE


def split_color(col, cols):
    x = col / max(1, cols - 1)
    t = min(1.0, max(0.0, (x - 0.55) / 0.1))      # violet-heavy: short blend at 55-65% of the width
    return mix(VIOLET, BLUE, t * t * (3 - 2 * t))


def put(out, col, row, ch, rgb, k):
    r, g, b = mix(BG, rgb, k)
    out.append(f"\x1b[{row + 1};{col * CW + 1}H\x1b[38;2;{r};{g};{b}m{ch}")


def erase(out, col, row):
    out.append(f"\x1b[{row + 1};{col * CW + 1}H" + " " * CW)


class Rain:
    def __init__(self):
        self.rewinding = False
        self.heads = None
        self.resize()

    def resize(self, *_):
        w, self.rows = shutil.get_terminal_size()
        self.cols = max(1, w // CW)
        self.drops = [random.randint(-self.rows, 0) for _ in range(self.cols)]
        self.col_color = [pick_color() for _ in range(self.cols)]
        self.cells = {}  # (col, row) -> [char, rgb, brightness]
        sys.stdout.write(f"\x1b[48;2;{BG[0]};{BG[1]};{BG[2]}m\x1b[2J\x1b[1m")
        try:  # cell size for boot-alarm
            r, c, xp, yp = struct.unpack("HHHH", fcntl.ioctl(1, termios.TIOCGWINSZ, b"\0" * 8))
            if xp and yp:
                with open(os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "matrix-rain.cell"), "w") as f:
                    f.write(f"{xp / c:.3f} {yp / r:.3f}\n")
        except OSError:
            pass

    def color(self, col):
        if RED:
            return mix(REDS[0], REDS[1], random.random() ** 2)
        if SPLIT:
            return split_color(col, self.cols)
        return self.col_color[col] if random.random() < 0.5 else pick_color()

    def start_rewind(self, *_):
        if self.rewinding:
            return
        self.rewinding = True
        lowest = {}
        for (col, row) in self.cells:
            lowest[col] = max(lowest.get(col, -1), row)
        self.heads = [lowest.get(col, -1) + 1 if col in lowest else -1 for col in range(self.cols)]

    def fade(self, out):
        for key in list(self.cells):
            cell = self.cells[key]
            cell[2] *= KEEP
            if cell[2] < GONE:
                del self.cells[key]
                erase(out, *key)
            else:
                put(out, key[0], key[1], cell[0], cell[1], cell[2])

    def step(self):
        out = []
        self.fade(out)
        if self.rewinding:
            self.rewind_step(out)
        else:
            for col in range(self.cols):
                row = self.drops[col]
                if 0 <= row < self.rows:
                    ch, rgb = random.choice(CHARS), self.color(col)
                    self.cells[(col, row)] = [ch, rgb, 1.0]
                    put(out, col, row, ch, rgb, 1.0)
                self.drops[col] += 1
                if row >= self.rows and random.random() < RESTART:
                    self.drops[col] = 0
                    self.col_color[col] = pick_color()
        sys.stdout.write("".join(out))
        sys.stdout.flush()

    def rewind_step(self, out):
        # Heads climb back up; everything at or below a head vanishes, the rest keeps fading
        for col in range(self.cols):
            if self.heads[col] < 0:
                continue
            self.heads[col] -= REWIND_SPEED
            head = self.heads[col]
            for key in [k for k in self.cells if k[0] == col and k[1] >= head]:
                del self.cells[key]
                erase(out, *key)
            if head >= 0:
                put(out, col, head, random.choice(CHARS), self.color(col), 1.0)
                self.cells[(col, head)] = [" ", BG, 0.0]  # erased on the next step

    def done(self):
        return self.rewinding and not self.cells and all(h < 0 for h in self.heads)


def main():
    sys.stdout.write("\x1b[?1049h\x1b[?25l")  # alternate screen, hide cursor
    rain = Rain()
    signal.signal(signal.SIGWINCH, rain.resize)
    signal.signal(signal.SIGUSR1, rain.start_rewind)

    def set_split(on):
        global SPLIT
        SPLIT = on

    signal.signal(signal.SIGRTMIN + 1, lambda *_: set_split(True))
    signal.signal(signal.SIGRTMIN + 2, lambda *_: set_split(False))

    def set_red(on):
        global RED
        RED = on

    signal.signal(signal.SIGRTMIN + 3, lambda *_: set_red(True))
    signal.signal(signal.SIGRTMIN + 4, lambda *_: set_red(False))

    def quit_(*_):
        sys.stdout.write("\x1b[0m\x1b[?25h\x1b[?1049l")
        sys.stdout.flush()
        sys.exit(0)

    signal.signal(signal.SIGTERM, quit_)
    signal.signal(signal.SIGINT, quit_)
    while not rain.done():
        start = time.monotonic()
        rain.step()
        time.sleep(max(0.0, STEP - (time.monotonic() - start)))
    quit_()


if __name__ == "__main__":
    main()
