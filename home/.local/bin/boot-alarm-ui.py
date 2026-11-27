#!/usr/bin/env python3
"""boot-alarm screen (v4, 2026-11-27) — bottom layer, under windows, see-through over the matrix rain.
1. draws an exact copy of the violet Anurati desktop clock where Quickshell's sits, writes <dir>/ready
   (boot-alarm then stops Quickshell and turns the rain red)
2. the clock's letters fall off the screen like rain drops: one rain step (55 ms) per frame, 2 rain rows per step,
   each letter starting on its own step
3. red glowing letters fall back in the same way, with a short trail, and land in place; the message fades in
4. steady state: red clock + message, glow breathing, real time. Re-checks every 5 s; exits when fixed or on
   `doom off`. argv: <dir> <shared|own>  (own = no wallpaper rain running: draw a red rain here instead)"""
import base64, fcntl, importlib.util, io, math, os, random, struct, subprocess, sys, termios, time
from PIL import Image, ImageDraw, ImageFilter, ImageFont

D, MODE = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "shared")
HOME = os.path.expanduser("~")
ORBITRON = "/usr/share/fonts/Orbitron Black.ttf"   # never Rubik (user, 2026-11-27)
MONO = "/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf"
ANURATI = f"{HOME}/.local/share/fonts/Anurati-Regular.otf"
VIOLET, BLUE = (135, 3, 255), (0, 89, 231)
RED, DEEP, PINK, BG = (255, 36, 66), (120, 0, 22), (255, 120, 140), (8, 1, 3)
STEP = 0.055                                   # the rain's step
try:
    CELL_W, ROW = map(float, open(f"{os.environ['XDG_RUNTIME_DIR']}/matrix-rain.cell").read().split())
except (OSError, ValueError, KeyError):
    CELL_W, ROW = 10.0, 22.0
FALL_ROWS, MAX_DELAY, TRAIL = 2, 12, 3          # rows per step, max start delay in steps, trail copies
S = 2                                          # animation frames are drawn at 1/S size (kitty scales them up)

rain_mod = None
if MODE == "own":
    spec = importlib.util.spec_from_file_location("rain", f"{HOME}/.config/hypr/custom/scripts/matrix-rain.py")
    rain_mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(rain_mod)
    rain_mod.RED, rain_mod.BG = True, BG


def orb(size):
    return ImageFont.truetype(ORBITRON, size)


def gr(ctrl, data=b""):
    w, p, first = sys.stdout.buffer, base64.standard_b64encode(data), True
    if not p:
        w.write(b"\033_G" + ctrl.encode() + b"\033\\")
    while p:
        chunk, p = p[:4096], p[4096:]
        w.write(b"\033_G" + ((ctrl + ",") if first else "").encode() + b"m=" + (b"1" if p else b"0") + b";" + chunk + b"\033\\")
        first = False
    w.flush()


def png(im):
    b = io.BytesIO(); im.save(b, "PNG", compress_level=1); return b.getvalue()


def term():
    rows, cols, xp, yp = struct.unpack("HHHH", fcntl.ioctl(1, termios.TIOCGWINSZ, b"\0" * 8))
    return cols, rows, (xp or 1920), (yp or 1080)


BIG_FONT = 18                                   # rain font size while the alarm is up (normal: 12)


def rain_font(size):
    """Resize the wallpaper rain's characters (its kitty panel listens on matrix-rain.kitty-<pid>)."""
    import glob
    for sock in glob.glob(f"{os.environ.get('XDG_RUNTIME_DIR', '/tmp')}/matrix-rain.kitty-*"):
        subprocess.run(["kitten", "@", "--to", f"unix:{sock}", "set-font-size", str(size)],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=5)


def check():
    env = {**os.environ, "BOOT_CHECK_NO_WAIT": "1"}
    p = subprocess.run([f"{HOME}/.local/bin/boot-check"], capture_output=True, text=True, env=env)
    if os.environ.get("BOOT_CHECK_FAKE"):
        return False, ["TEST (doom) — pretending /boot/vmlinuz-linux is missing"], "sudo pacman -S linux nvidia-open"
    probs = [l[9:] for l in p.stdout.splitlines() if l.startswith("PROBLEM: ")]
    fix = next((l[5:] for l in p.stdout.splitlines() if l.startswith("FIX: ")), "sudo pacman -S linux")
    return p.returncode == 0, probs, fix


# ---------- the clock, letter by letter (same layout as Quickshell's NcmClock) ----------
def clock_lines():
    now = time.localtime()
    return [(time.strftime("%A", now).upper(), ImageFont.truetype(ANURATI, 72), 40, False),
            (time.strftime("%-d %B %Y", now), ImageFont.truetype(MONO, 26), 4, True),
            (time.strftime("%-I:%M %p", now), ImageFont.truetype(MONO, 26), 4, True)]


def letters(W, H):
    """[(char, font, x, y, small)] at full-res screen positions; y0 = (H - columnHeight)/2 - 172 like NcmClock."""
    d = ImageDraw.Draw(Image.new("L", (1, 1)))
    lines = clock_lines()
    heights = [sum(f.getmetrics()) for _, f, _, _ in lines]
    y = (H - sum(heights)) / 2 - 172
    out = []
    for (s, f, sp, small), h in zip(lines, heights):
        widths = [d.textlength(c, font=f) for c in s]
        x = (W - (sum(widths) + sp * len(s))) / 2
        for c, w in zip(s, widths):
            if c != " ":
                out.append((c, f, x, y, small))
            x += w + sp
        y += h
    return out, y                                  # y = bottom of the clock


def sprite(c, f, small, red, glow=1.0):
    """One letter with its shadow (+ red glow), as in the desktop clock."""
    a, dsc = f.getmetrics()
    w = int(ImageDraw.Draw(Image.new("L", (1, 1))).textlength(c, font=f)) + 4
    pad = 24 if red else 4
    im = Image.new("RGBA", (w + 2 * pad, a + dsc + 2 * pad), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    if red:
        main, shadow = (PINK if small else RED), DEEP
    else:
        main, shadow = (BLUE, VIOLET) if small else (VIOLET, BLUE)
    d.text((pad + 2, pad + 2), c, font=f, fill=shadow + (255,))
    d.text((pad, pad), c, font=f, fill=main + (255,))
    if red:
        halo = Image.new("RGBA", im.size, RED + (0,))
        halo.putalpha(im.getchannel("A").point(lambda v: int(v * (0.5 + 0.5 * glow))))
        out = Image.new("RGBA", im.size, (0, 0, 0, 0))
        out.alpha_composite(halo.filter(ImageFilter.GaussianBlur(12)))
        out.alpha_composite(halo.filter(ImageFilter.GaussianBlur(4)))
        out.alpha_composite(im)
        im = out
    return im, pad


def message(W, probs, fix):
    """The text under the clock (transparent, with a soft dark backing + red glow)."""
    BH = 460
    sharp = Image.new("RGBA", (W, BH), (0, 0, 0, 0))
    d = ImageDraw.Draw(sharp)
    y = 20
    def c(s, f, fill, dy):
        nonlocal y
        d.text(((W - d.textlength(s, font=f)) / 2, y), s, font=f, fill=fill); y += dy
    c("DON'T RESTART — ARCH WON'T BOOT", orb(42), (255, 255, 255, 255), 70)
    for pr in probs[:3]:
        c(pr, orb(19), (255, 170, 185, 255), 34)
    y += 18
    c("Super + Enter opens a terminal. Run:", orb(18), (230, 200, 206, 255), 44)
    fc = ImageFont.truetype(MONO, 36)
    cw = d.textlength("$ " + fix, font=fc) + 80
    x0 = (W - cw) / 2
    d.rounded_rectangle((x0, y, x0 + cw, y + 74), radius=20, fill=(30, 4, 10, 235), outline=RED + (210,), width=2)
    d.text((x0 + 40, y + 16), "$", font=fc, fill=RED + (255,))
    d.text((x0 + 40 + d.textlength("$ ", font=fc), y + 16), fix, font=fc, fill=(255, 255, 255, 255))
    y += 104
    c("Restart, shut down and sleep are blocked  |  only terminals can open  |  false alarm: doom off",
      orb(14), (170, 120, 128, 255), 0)
    back = Image.new("L", (W, BH), 0)
    ImageDraw.Draw(back).rounded_rectangle((W * 0.18, 70, W * 0.82, BH - 60), radius=140, fill=225)
    out = Image.merge("RGBA", (*[Image.new("L", (W, BH), v) for v in BG], back.filter(ImageFilter.GaussianBlur(50))))
    halo = Image.new("RGBA", (W, BH), RED + (0,))
    halo.putalpha(sharp.getchannel("A").point(lambda v: int(v * 0.55)))
    out.alpha_composite(halo.filter(ImageFilter.GaussianBlur(10)))
    out.alpha_composite(sharp)
    return out


def clock_backing(W, H, top, bottom):
    back = Image.new("L", (W, H), 0)
    ImageDraw.Draw(back).rounded_rectangle((W * 0.25, top - 40, W * 0.75, bottom + 30), radius=120, fill=200)
    return Image.merge("RGBA", (*[Image.new("L", (W, H), v) for v in BG], back.filter(ImageFilter.GaussianBlur(50))))


# ---------- frames ----------
def fall_frames(W, H, lets, probs, fix, clock_bottom):
    """Rain-rhythm animation, one frame per rain step, at 1/S size."""
    w, h = W // S, H // S
    dy = FALL_ROWS * ROW
    out_delay = [random.randint(0, MAX_DELAY) for _ in lets]
    in_delay = [random.randint(0, MAX_DELAY) for _ in lets]
    small = lambda im: im.resize((max(1, im.width // S), max(1, im.height // S)), Image.LANCZOS)
    vio = [(small(im), p) for im, p in (sprite(c, f, sm, False) for c, f, _, _, sm in lets)]
    red = [(small(im), p) for im, p in (sprite(c, f, sm, True) for c, f, _, _, sm in lets)]
    top = min(l[3] for l in lets)
    in_steps = [math.ceil((l[3] + 140) / dy) for l in lets]   # from just above the screen, whole rain steps
    n_out = MAX_DELAY + math.ceil(H / dy) + 1
    n_in = max(d + s for d, s in zip(in_delay, in_steps)) + 1
    msg = small(message(W, probs, fix))
    back = clock_backing(W, H, top, clock_bottom).resize((w, h), Image.BILINEAR)
    frames = []
    for k in range(n_out):                                     # violet letters fall away
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        for (c, f, x, y, sm), (sp, pad), d in zip(lets, vio, out_delay):
            yy = y + max(0, k - d) * dy
            if yy < H:
                im.alpha_composite(sp, (int((x - pad) / S), int((yy - pad) / S)))
        frames.append(im)
    for k in range(n_in + 8):                                  # red letters rain in, then the message fades in
        im = back.copy()
        im.putalpha(im.getchannel("A").point(lambda v: int(v * min(1, k / 6))))
        for (c, f, x, y, sm), (sp, pad), d, n in zip(lets, red, in_delay, in_steps):
            if k < d:
                continue
            s = min(n, k - d)
            yy = y - (n - s) * dy
            if s < n:                                           # fading trail above a falling letter
                for j in range(TRAIL, 0, -1):
                    t = sp.copy(); t.putalpha(t.getchannel("A").point(lambda v, j=j: int(v * 0.35 / j)))
                    py = int((yy - j * dy - pad) / S)
                    if py >= 0:
                        im.alpha_composite(t, (int((x - pad) / S), py))
                    elif py > -t.height:
                        im.alpha_composite(t.crop((0, -py, t.width, t.height)), (int((x - pad) / S), 0))
            py = int((yy - pad) / S)
            if py >= 0:
                im.alpha_composite(sp, (int((x - pad) / S), py))
            elif py > -sp.height:
                im.alpha_composite(sp.crop((0, -py, sp.width, sp.height)), (int((x - pad) / S), 0))
        if k > n_in:
            m = msg.copy(); m.putalpha(m.getchannel("A").point(lambda v: int(v * min(1, (k - n_in) / 7))))
            im.alpha_composite(m, (0, int((clock_bottom + 30) / S)))
        frames.append(im)
    return [png(f) for f in frames]


def steady_frames(W, H, lets, probs, fix, clock_bottom):
    """Red clock + message, glow breathing (10 frames, full size, kitty loops them)."""
    top = min(l[3] for l in lets)
    base = clock_backing(W, H, top, clock_bottom)
    base.alpha_composite(message(W, probs, fix), (0, int(clock_bottom + 30)))
    out = []
    for i in range(10):
        g = (1 - math.cos(2 * math.pi * i / 10)) / 2
        im = base.copy()
        for c, f, x, y, sm in lets:
            sp, pad = sprite(c, f, sm, True, g)
            im.alpha_composite(sp, (int(x - pad), int(y - pad)))
        out.append(png(im))
    return out


def play(img_id, frames, cols, rows, gap_ms, loop):
    sys.stdout.write("\033[H"); sys.stdout.flush()
    gr(f"a=T,f=100,i={img_id},p=1,c={cols},r={rows},C=1,z=1,q=2", frames[0])
    for f in frames[1:]:
        gr(f"a=f,i={img_id},f=100,z={gap_ms},q=2", f)
    gr(f"a=a,i={img_id},r=1,z={gap_ms},q=2")
    gr(f"a=a,i={img_id},s=3,v={1 if loop else 2},q=2")


def main():
    sys.stdout.write("\x1b[?1049h\x1b[?25l\x1b[2J"); sys.stdout.flush()
    time.sleep(0.1)
    cols, rows, W, H = term()
    ok, probs, fix = check()
    lets, bottom = letters(W, H)
    fall = fall_frames(W, H, lets, probs, fix, bottom)
    steady_id = 32
    play(31, fall, cols, rows, int(STEP * 1000), False)
    open(os.path.join(D, "ready"), "w").close()          # boot-alarm: stop Quickshell + turn the rain red now
    t_end = time.monotonic() + len(fall) * STEP
    steady = steady_frames(W, H, lets, probs, fix, bottom)
    key = (tuple(probs), fix, time.strftime("%H:%M"))
    rain = rain_mod.Rain() if rain_mod else None
    switched, last = False, time.monotonic()
    try:
        while True:
            s = time.monotonic()
            if rain:
                rain.step()
            if not switched and s >= t_end:
                play(steady_id, steady, cols, rows, 130, True); gr("a=d,d=i,i=31,q=2"); switched = True
                rain_font(BIG_FONT)                     # red clock landed: the wallpaper rain gets bigger
            if s - last > 5:
                last = s
                if os.path.exists(os.path.join(D, "off")):
                    return
                ok, probs, fix = check()
                if ok:
                    gr("a=d,d=A,q=2")
                    msg = Image.new("RGBA", (W, 200), (0, 0, 0, 0))
                    d = ImageDraw.Draw(msg); f = orb(46); t = "Fixed — Arch will boot normally"
                    d.text(((W - d.textlength(t, font=f)) / 2, 60), t, font=f, fill=(120, 255, 150, 255))
                    sys.stdout.write(f"\033[{int(rows * 0.45)};1H"); sys.stdout.flush()
                    gr(f"a=T,f=100,i=40,c={cols},C=1,z=1,q=2", png(msg))
                    time.sleep(2.5); return
                nk = (tuple(probs), fix, time.strftime("%H:%M"))
                if switched and nk != key:                    # new minute / new problem: redraw the steady clock
                    key = nk; lets, bottom = letters(W, H)
                    old, steady_id = steady_id, (33 if steady_id == 32 else 32)
                    play(steady_id, steady_frames(W, H, lets, probs, fix, bottom), cols, rows, 130, True)
                    gr(f"a=d,d=i,i={old},q=2")
            time.sleep(max(0.0, STEP - (time.monotonic() - s)))
    finally:
        gr("a=d,d=A,q=2")
        sys.stdout.write("\x1b[0m\x1b[?25h\x1b[?1049l"); sys.stdout.flush()


if __name__ == "__main__":
    main()
