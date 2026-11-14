#!/usr/bin/env python3
"""Draws Ace's 1024x1024 app icon (glowing orb with two eyes) in Nimbus colors.

Run from the repo root:  python3 tools/make_icon.py
Writes the icon into the app and widget asset catalogs.
"""
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
TARGETS = [
    os.path.join(ROOT, "Ace", "Resources", "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png"),
]
S = 1024
BG_TOP = (14, 12, 31)      # #0E0C1F
BG_BOTTOM = (6, 6, 11)     # #06060B
ACE = (91, 182, 255)       # #5BB6FF
ACCENT = (143, 124, 255)   # #8F7CFF


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def main():
    img = Image.new("RGB", (S, S))
    px = img.load()
    for y in range(S):
        c = lerp(BG_TOP, BG_BOTTOM, y / (S - 1))
        for x in range(S):
            px[x, y] = c

    # outer glow
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    cx, cy, r = S // 2, S // 2, 300
    gd.ellipse((cx - r - 90, cy - r - 90, cx + r + 90, cy + r + 90), fill=ACE + (150,))
    glow = glow.filter(ImageFilter.GaussianBlur(110))
    img.paste(glow, (0, 0), glow)

    # orb body with a soft radial shade
    orb = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    op = orb.load()
    hx, hy = cx - 110, cy - 130
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            dx, dy = x - cx, y - cy
            if dx * dx + dy * dy <= r * r:
                d = ((x - hx) ** 2 + (y - hy) ** 2) ** 0.5 / (r * 1.6)
                d = min(1.0, d)
                c = lerp((210, 238, 255), ACE, min(1.0, d * 1.4))
                c = lerp(c, ACCENT, max(0.0, d - 0.55) * 1.6)
                op[x, y] = c + (255,)
    img.paste(orb, (0, 0), orb)

    # two eyes, slightly rounded rectangles like the in-app eyes
    eyes = ImageDraw.Draw(img)
    ew, eh, gap = 70, 150, 70
    for sx in (-1, 1):
        ex = cx + sx * (gap + ew // 2)
        eyes.rounded_rectangle((ex - ew // 2, cy - eh // 2 - 10, ex + ew // 2, cy + eh // 2 - 10),
                               radius=34, fill=(12, 16, 40))
        eyes.ellipse((ex - 14, cy - eh // 2 + 14, ex + 6, cy - eh // 2 + 34), fill=(235, 245, 255))

    for path in TARGETS:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        img.save(path, "PNG")
        print("wrote", os.path.normpath(path))


if __name__ == "__main__":
    main()
