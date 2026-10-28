#!/usr/bin/env python3
"""Draws the PC Apps starter icons (extras/pc-apps/<os>/icons/*.png), the PC Apps
system-row logo (assets/images/logospng/pcapps.png) and background
(assets/images/systembackground/pcapps.webp). Generic glyphs only — no brand
logos. Run from the repo root: python3 tools/make_pc_icons.py"""
import math, os, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, "assets/fonts/SegoeProDisplay-Bold.ttf")
S = 4                      # supersampling
N = 256 * S
W = 9 * S                  # glyph stroke

CAT = {"tool": "#2f6f9f", "power": "#3a3a3a", "launcher": "#5b3fa8", "emulator": "#2b7a3e", "app": "#b2552a"}

def base(cat):
    im = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    top = tuple(int(CAT[cat][i:i+2], 16) for i in (1, 3, 5))
    for y in range(N):                       # soft vertical gradient
        f = y / N
        c = tuple(int(v * (1.12 - 0.3 * f)) for v in top)
        c = tuple(min(255, x) for x in c)
        d.line([(0, y), (N, y)], fill=c + (255,))
    mask = Image.new("L", (N, N), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, N - 1, N - 1], radius=48 * S, fill=255)
    im.putalpha(mask)
    return im, ImageDraw.Draw(im)

def P(x, y): return (x * S, y * S)
def box(x0, y0, x1, y1): return [x0 * S, y0 * S, x1 * S, y1 * S]

def g_folder(d):
    d.rounded_rectangle(box(52, 84, 204, 188), radius=14 * S, outline="white", width=W)
    d.line([P(52, 100), P(52, 76), P(108, 76), P(122, 92), P(204, 92)], fill="white", width=W, joint="curve")
def g_chart(d):
    d.rounded_rectangle(box(52, 60, 204, 196), radius=14 * S, outline="white", width=W)
    d.line([P(72, 160), P(104, 120), P(132, 146), P(184, 92)], fill="white", width=W, joint="curve")
def g_gear(d):
    cx, cy = 128 * S, 128 * S
    for k in range(8):
        a = k * math.pi / 4
        d.line([(cx + 52 * S * math.cos(a), cy + 52 * S * math.sin(a)),
                (cx + 76 * S * math.cos(a), cy + 76 * S * math.sin(a))], fill="white", width=16 * S)
    d.ellipse(box(76, 76, 180, 180), outline="white", width=W)
    d.ellipse(box(108, 108, 148, 148), outline="white", width=W)
def g_pad(d):
    d.rounded_rectangle(box(40, 92, 216, 176), radius=38 * S, outline="white", width=W)
    d.line([P(80, 134), P(112, 134)], fill="white", width=W); d.line([P(96, 118), P(96, 150)], fill="white", width=W)
    d.ellipse(box(150, 112, 166, 128), fill="white"); d.ellipse(box(170, 132, 186, 148), fill="white")
def g_moon(d):
    # Crescent: a disc minus an offset disc, drawn as a mask so the cut-out
    # shows the tile, not black.
    m = Image.new("L", (N, N), 0); md = ImageDraw.Draw(m)
    md.ellipse(box(60, 56, 200, 196), fill=255)
    md.ellipse(box(100, 34, 240, 174), fill=0)
    d._image.paste((255, 255, 255, 255), (0, 0), m)
def g_restart(d):
    d.arc(box(60, 60, 196, 196), 300, 230, fill="white", width=W)
    d.polygon([P(70, 64), P(106, 70), P(80, 100)], fill="white")
def g_power(d):
    d.arc(box(58, 62, 198, 202), 300, 240, fill="white", width=W)
    d.line([P(128, 46), P(128, 130)], fill="white", width=W)
def g_exit(d):
    d.line([P(120, 60), P(64, 60), P(64, 196), P(120, 196)], fill="white", width=W, joint="curve")
    d.line([P(100, 128), P(196, 128)], fill="white", width=W)
    d.line([P(164, 96), P(196, 128), P(164, 160)], fill="white", width=W, joint="curve")
def g_bag(d):
    d.polygon([P(58, 96), P(198, 96), P(186, 204), P(70, 204)], outline="white", width=W)
    d.arc(box(92, 44, 164, 124), 180, 360, fill="white", width=W)
def g_chat(d):
    d.rounded_rectangle(box(48, 60, 208, 172), radius=36 * S, outline="white", width=W)
    d.polygon([P(84, 166), P(76, 206), P(118, 170)], fill="white")
def g_note(d):
    d.line([P(108, 64), P(108, 172)], fill="white", width=W); d.line([P(108, 64), P(184, 50), P(184, 152)], fill="white", width=W)
    d.ellipse(box(66, 154, 112, 196), fill="white"); d.ellipse(box(142, 136, 188, 178), fill="white")
def g_globe(d):
    d.ellipse(box(52, 52, 204, 204), outline="white", width=W)
    d.ellipse(box(94, 52, 162, 204), outline="white", width=W)
    d.line([P(56, 128), P(200, 128)], fill="white", width=W)
def g_rec(d):
    d.ellipse(box(52, 52, 204, 204), outline="white", width=W); d.ellipse(box(92, 92, 164, 164), fill="white")

def letters(d, text, y=164, size=58):
    f = ImageFont.truetype(FONT, size * S)
    w = d.textbbox((0, 0), text, font=f)[2]
    d.text(((N - w) / 2, y * S), text, font=f, fill="white")
def g_small(glyph):
    # draw the glyph shrunk into the upper part of the tile, leaving room for letters
    def f(d):
        tmp = Image.new("RGBA", (N, N), (0, 0, 0, 0)); glyph(ImageDraw.Draw(tmp))
        tmp = tmp.resize((int(N * 0.62), int(N * 0.62)), Image.LANCZOS)
        d._image.alpha_composite(tmp, (int(N * 0.19), int(N * 0.02)))
    return f

ICONS = [
    ("files", "tool", g_folder, None), ("file-explorer", "tool", g_folder, None),
    ("task-manager", "tool", g_chart, None), ("system-monitor", "tool", g_chart, None),
    ("windows-settings", "tool", g_gear, None), ("settings", "tool", g_gear, None),
    ("ds4windows", "tool", g_pad, None),
    ("sleep", "power", g_moon, None), ("restart", "power", g_restart, None),
    ("shut-down", "power", g_power, None), ("exit-to-desktop", "power", g_exit, None),
    ("steam", "launcher", g_small(g_bag), "ST"), ("steam-big-picture", "launcher", g_small(g_bag), "BP"),
    ("epic-games", "launcher", g_small(g_bag), "EG"), ("gog-galaxy", "launcher", g_small(g_bag), "GOG"),
    ("playnite", "launcher", g_small(g_bag), "PN"), ("ea-app", "launcher", g_small(g_bag), "EA"),
    ("battle-net", "launcher", g_small(g_bag), "BN"), ("lutris", "launcher", g_small(g_bag), "LU"),
    ("heroic", "launcher", g_small(g_bag), "HE"),
    ("retroarch", "emulator", g_small(g_pad), "RA"), ("dolphin", "emulator", g_small(g_pad), "DO"),
    ("pcsx2", "emulator", g_small(g_pad), "P2"), ("duckstation", "emulator", g_small(g_pad), "DS"),
    ("ppsspp", "emulator", g_small(g_pad), "PSP"),
    ("discord", "app", g_chat, None), ("spotify", "app", g_note, None), ("browser", "app", g_globe, None),
    ("obs-studio", "app", g_rec, None),
]

def icons():
    # Each starter folder carries the icons its own metadata file names
    # (assets.boxFront: icons/<slug>.png), so copying one folder is enough.
    import re
    for osname in ("windows", "linux"):
        folder = os.path.join(ROOT, "extras/pc-apps", osname)
        meta = open(os.path.join(folder, "metadata.pegasus.txt")).read()
        wanted = set(re.findall(r"assets\.boxFront: icons/([\w-]+)\.png", meta))
        out = os.path.join(folder, "icons"); os.makedirs(out, exist_ok=True)
        for name, cat, glyph, text in ICONS:
            if name not in wanted: continue
            im, d = base(cat); glyph(d)
            if text: letters(d, text)
            im.resize((256, 256), Image.LANCZOS).save(os.path.join(out, name + ".png"), optimize=True)

def system_assets():
    # Logo: a monitor glyph and "PC APPS", white, ~5.4:1 like the other logos.
    h = 118 * S; w = 640 * S
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rounded_rectangle([10 * S, 14 * S, 140 * S, 90 * S], radius=8 * S, outline="white", width=10 * S)
    d.line([(52 * S, 108 * S), (98 * S, 108 * S)], fill="white", width=10 * S)
    d.line([(75 * S, 90 * S), (75 * S, 108 * S)], fill="white", width=10 * S)
    f = ImageFont.truetype(FONT, 92 * S)
    d.text((168 * S, 2 * S), "PC APPS", font=f, fill="white")
    bb = im.getbbox(); im = im.crop(bb)
    im = im.resize((round(im.width / S), round(im.height / S)), Image.LANCZOS)
    im.save(os.path.join(ROOT, "assets/images/logospng/pcapps.png"), optimize=True)
    # Background: deep blue-violet gradient, soft glows and a field of faint
    # app tiles drifting to the right — abstract, no brands.
    random.seed(7)
    W2, H2 = 1920, 1080
    bg = Image.new("RGB", (W2, H2))
    px = bg.load()
    for y in range(H2):
        for x in range(0, W2, 4):
            t = x / W2; u = y / H2
            r = int(14 + 30 * t + 10 * u); g = int(18 + 14 * (1 - u)); b = int(46 + 60 * t * (1 - u))
            for k in range(4):
                if x + k < W2: px[x + k, y] = (r, g, b)
    glow = Image.new("RGB", (W2, H2), (0, 0, 0)); gd = ImageDraw.Draw(glow)
    for cx, cy, rr, col in [(1350, 380, 420, (90, 60, 190)), (1650, 820, 360, (40, 120, 200)), (500, 900, 300, (60, 40, 120))]:
        gd.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=col)
    glow = glow.filter(ImageFilter.GaussianBlur(160))
    bg = Image.blend(bg, glow, 0.6)
    tiles = Image.new("RGBA", (W2, H2), (0, 0, 0, 0)); td = ImageDraw.Draw(tiles)
    for i in range(70):
        s = random.randint(60, 170); x = random.randint(700, 1880); y = random.randint(-40, 1060)
        a = int(18 + 60 * ((x - 700) / 1200) * random.random())
        td.rounded_rectangle([x, y, x + s, y + s], radius=s // 5, outline=(255, 255, 255, a), width=3)
    tiles = tiles.filter(ImageFilter.GaussianBlur(1.2))
    bg = bg.convert("RGBA"); bg.alpha_composite(tiles)
    bg.convert("RGB").save(os.path.join(ROOT, "assets/images/systembackground/pcapps.webp"), quality=86)

if __name__ == "__main__":
    icons(); system_assets(); print("done")
