#!/usr/bin/env python3
"""Wrap a screenshot in a macOS terminal window frame and export a PNG.

Title bar with red/yellow/green traffic lights, rounded corners, a soft drop
shadow, and (by default) a transparent background so it drops onto any layout.
The title-bar shade is auto-matched to the screenshot's own background.
"""
import argparse, os
from PIL import Image, ImageDraw, ImageFilter


def hexrgb(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("input", help="path to the source screenshot")
    ap.add_argument("-o", "--output", help="output PNG (default: <input>-framed.png)")
    ap.add_argument("--lights", choices=["left", "right"], default="left",
                    help="traffic-light side (macOS convention is left)")
    ap.add_argument("--no-shadow", action="store_true", help="drop the shadow, tighter margins")
    ap.add_argument("--bg", default="transparent",
                    help="'transparent' or a hex like #101210 for a solid background")
    ap.add_argument("--scale", type=float, default=1.0, help="output scale, e.g. 2 for @2x")
    ap.add_argument("--radius", type=int, default=15, help="corner radius in px (pre-scale)")
    ap.add_argument("--titlebar", default="auto", help="'auto' or a hex color")
    args = ap.parse_args()

    shot = Image.open(args.input).convert("RGBA")
    icc = shot.info.get("icc_profile")           # preserve color profile (macOS = Display P3)
    term_bg = shot.getpixel((4, 4))[:3]          # sample bg before any resize

    S = args.scale
    if S != 1.0:
        shot = shot.resize((round(shot.width * S), round(shot.height * S)), Image.LANCZOS)
    W, SH = shot.size

    TITLE = round(46 * S)
    RADIUS = round(args.radius * S)
    PAD_B = round(8 * S)                          # dark strip so rounding never clips content
    titlebar = (tuple(min(c + 18, 255) for c in term_bg)
                if args.titlebar == "auto" else hexrgb(args.titlebar))

    # ---- window (opaque) ----
    win_w, win_h = W, TITLE + SH + PAD_B
    win = Image.new("RGBA", (win_w, win_h), titlebar + (255,))
    body = Image.new("RGBA", (win_w, SH + PAD_B), term_bg + (255,))
    body.paste(shot, (0, 0))
    win.paste(body, (0, TITLE))

    # ---- traffic lights ----
    d = ImageDraw.Draw(win)
    lights = [("#ff5f57", "#e0443e"), ("#febc2e", "#dea123"), ("#28c840", "#1aab29")]
    r, cy, gap, edge = round(7 * S), TITLE // 2, round(26 * S), round(22 * S)
    for i, (fill, ring) in enumerate(lights):
        cx = edge + i * gap if args.lights == "left" else win_w - edge - (2 - i) * gap
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill, outline=ring, width=max(1, round(S)))

    # ---- round the corners ----
    mask = Image.new("L", (win_w, win_h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, win_w - 1, win_h - 1], RADIUS, fill=255)
    win.putalpha(mask)

    # ---- canvas + shadow ----
    PAD = round((16 if args.no_shadow else 54) * S)
    canvas_bg = (0, 0, 0, 0) if args.bg == "transparent" else hexrgb(args.bg) + (255,)
    canvas = Image.new("RGBA", (win_w + PAD * 2, win_h + PAD * 2), canvas_bg)

    if not args.no_shadow:
        shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        off = round(14 * S)
        ImageDraw.Draw(shadow).rounded_rectangle(
            [PAD, PAD + off, PAD + win_w, PAD + off + win_h], RADIUS + round(4 * S), fill=(0, 0, 0, 150))
        canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(round(22 * S))))

    canvas.alpha_composite(win, (PAD, PAD))

    out = args.output or os.path.splitext(args.input)[0] + "-framed.png"
    canvas.save(out, icc_profile=icc)            # re-embed source profile so colors match
    print("saved:", out, canvas.size, "| profile:", "kept" if icc else "none (sRGB)")


if __name__ == "__main__":
    main()
