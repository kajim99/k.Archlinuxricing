#!/usr/bin/env python3
"""boot-alarm step 3 (2026-11-27): overlay that shows the desktop screenshot, then lets it fall off the
screen column by column in the matrix rain's rhythm (55 ms steps). Writes <dir>/ready once the picture is up
(so the desktop can be cleared behind it) and <dir>/fall-done at the end, then exits."""
import base64, fcntl, io, os, random, struct, sys, termios, time
from PIL import Image

D = sys.argv[1]
STEP = 0.055                 # rain step
FPS, G = 30, 2600.0          # frames/s, fall acceleration in screen px/s²
BG = (8, 1, 3)


def gr(ctrl, data=b""):
    w, p, first = sys.stdout.buffer, base64.standard_b64encode(data), True
    if not p:
        w.write(b"\033_G" + ctrl.encode() + b"\033\\")
    while p:
        chunk, p = p[:4096], p[4096:]
        head = (ctrl + ",") if first else ""
        w.write(b"\033_G" + head.encode() + b"m=" + (b"1" if p else b"0") + b";" + chunk + b"\033\\")
        first = False
    w.flush()


def size():
    rows, cols, xp, yp = struct.unpack("HHHH", fcntl.ioctl(1, termios.TIOCGWINSZ, b"\0" * 8))
    return cols, rows


sys.stdout.write("\033[?25l\033[2J\033[H"); sys.stdout.flush()
time.sleep(0.15)
cols, rows = size()
shot = os.path.join(D, "shot.png")
gr(f"a=T,t=f,f=100,i=1,p=1,c={cols},r={rows},C=1,q=2", shot.encode())
open(os.path.join(D, "ready"), "w").close()

# render the fall at half resolution (kitty scales it to the screen)
src = Image.open(shot).convert("RGB")
W, H = src.width // 2, src.height // 2
src = src.resize((W, H), Image.BILINEAR)
cw = 8                                   # 16 screen px per column = the rain's grid
ncol = (W + cw - 1) // cw
delay = [random.randint(0, 14) * STEP for _ in range(ncol)]
g = G / 2
total = max(delay) + (2 * H / g) ** 0.5 + 0.1
strips = [src.crop((i * cw, 0, min(W, (i + 1) * cw), H)) for i in range(ncol)]
frames = []
for f in range(int(total * FPS) + 1):
    t = f / FPS
    im = Image.new("RGB", (W, H), BG)
    for i, s in enumerate(strips):
        dt = t - delay[i]
        y = 0 if dt <= 0 else int(0.5 * g * dt * dt)
        if y < H:
            im.paste(s, (i * cw, y))
    buf = io.BytesIO(); im.save(buf, "PNG", compress_level=1); frames.append(buf.getvalue())

gap = int(1000 / FPS)
gr(f"a=T,f=100,i=2,p=1,c={cols},r={rows},C=1,q=2", frames[0])
gr("a=d,d=i,i=1,q=2")
for fr in frames[1:]:
    gr(f"a=f,i=2,f=100,z={gap},q=2", fr)
gr(f"a=a,i=2,r=1,z={gap},q=2")
gr("a=a,i=2,s=3,v=2,q=2")               # play once
time.sleep(len(frames) * gap / 1000 + 0.05)
open(os.path.join(D, "fall-done"), "w").close()
time.sleep(0.25)                          # let the red screen draw its first frame underneath
