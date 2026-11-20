#!/usr/bin/env python3
# Bakes desktop-style cmatrix rain (same look as matrix-rain.py) over a wallpaper video for the SDDM login screen.
# The rain is periodic over the video length, so the loop is seamless.
# Colors: deep violet streams on the left, blue on the right, soft blend across the middle fifth.
# Usage: render-login-video.py <wallpaper.mp4> <out.mp4>
import random, subprocess, sys
from multiprocessing import Pool
from PIL import Image, ImageDraw, ImageFont

SRC, OUT = sys.argv[1], sys.argv[2]
W, H, FPS, N = 1920, 1080, 30, 515           # source video: 1080p30, 515 frames (17.17 s)
CW, CH = 11, 24                               # kitty 13pt cell size (MonaspiceKr)
COLS, ROWS = W // CW, H // CH
CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+[]{}<>/\\|;:~"
VIOLET, BLUE = (135, 3, 255), (0, 89, 231)
TRAIL_BRIGHTNESS = 0.6
STEP = 16 / FPS                                # desktop rain updates at 16 fps


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def split_color(col):
    x = col / (COLS - 1)
    t = min(1.0, max(0.0, (x - 0.55) / 0.1))  # violet-heavy: short blend at 55-65%
    return mix(VIOLET, BLUE, t * t * (3 - 2 * t))


def color_for(age, trail, col):
    base = split_color(col)
    if age <= 0:
        return base
    t = age / trail
    c = base if t <= 0.7 else mix(base, (0, 0, 0), (t - 0.7) / 0.3 * 0.85)
    return mix((0, 0, 0), c, TRAIL_BRIGHTNESS)


rng = random.Random(7)
drops = []  # (col, start frame, speed rows/frame @30fps, trail length in desktop steps, seed)
for col in range(COLS):
    for s in sorted(rng.sample(range(N), 2)):
        drops.append((col, s, rng.uniform(0.35, 0.9) * STEP, rng.randint(8, 22), rng.randrange(1 << 30)))

font = ImageFont.truetype("/usr/share/fonts/OTF/MonaspiceKrNerdFont-Regular.otf", 17)
fontb = ImageFont.truetype("/usr/share/fonts/OTF/MonaspiceKrNerdFont-Bold.otf", 17)


def mask(ch, f):
    m = Image.new("L", (CW + 4, CH))
    ImageDraw.Draw(m).text((0, 2), ch, font=f, fill=255)
    return m


MASKS = {ch: mask(ch, font) for ch in CHARS}
MASKS_B = {ch: mask(ch, fontb) for ch in CHARS}


def frame(f):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for col, s, v, trail, seed in drops:
        hrow = int(((f - s) % N) * v)          # periodic: frame N == frame 0
        for back in range(trail + 1):
            row = hrow - back
            if row < 0:
                break
            age = back / (v / STEP) if back else 0
            if age > trail or row >= ROWS:
                continue
            flick = (f // 12) if age > 0 else f
            ch = CHARS[(seed + row * 131 + (flick if (seed + row) % 33 == 0 else 0)) % len(CHARS)]
            im.paste(color_for(age, trail, col) + (255,), (col * CW, row * CH), (MASKS_B if age <= 0 else MASKS)[ch])
    return im.tobytes()


if __name__ == "__main__":
    ff = subprocess.Popen(["ffmpeg", "-v", "error", "-y", "-i", SRC,
                           "-f", "rawvideo", "-pix_fmt", "rgba", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
                           "-filter_complex", "[0:v][1:v]overlay=0:0:shortest=1,format=yuv420p",
                           "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-an", "-movflags", "+faststart", OUT],
                          stdin=subprocess.PIPE)
    with Pool(10) as p:
        for buf in p.imap(frame, range(N), chunksize=4):
            ff.stdin.write(buf)
    ff.stdin.close()
    sys.exit(ff.wait())
