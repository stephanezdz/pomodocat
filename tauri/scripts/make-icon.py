#!/usr/bin/env python3
"""
Generate a 1024×1024 PomodoCat app icon (procedural — no external assets).

Run:
    python3 make-icon.py /tmp/pomodocat-icon.png

Then feed the PNG to `npx tauri icon` to produce icon.ico / icon.icns / etc.
"""

from PIL import Image, ImageDraw, ImageFilter
import sys

S = 1024  # canvas size


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def radial_fill(im, center, r, color_in, color_out):
    """Fill a circle with a radial gradient from color_in (center) to color_out (edge)."""
    cx, cy = center
    px = im.load()
    r2 = r * r
    for y in range(max(0, cy - r), min(S, cy + r + 1)):
        for x in range(max(0, cx - r), min(S, cx + r + 1)):
            dx, dy = x - cx, y - cy
            d2 = dx * dx + dy * dy
            if d2 <= r2:
                t = (d2 / r2) ** 0.5
                px[x, y] = (*lerp(color_in, color_out, t), 255)


def main(out_path):
    # Background: rounded-square dark canvas (will be masked into icon shape by macOS).
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bg)
    bd.rounded_rectangle((0, 0, S, S), radius=int(S * 0.22), fill=(26, 22, 32, 255))
    # subtle radial glow
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    radial_fill(glow, (S // 2, int(S * 0.42)), int(S * 0.55),
                (255, 140, 77), (26, 22, 32))
    glow.putalpha(Image.new("L", (S, S), 70))
    bg = Image.alpha_composite(bg, glow)
    im = Image.alpha_composite(im, bg)

    # ----- Tomato body (red→deep-red radial) ---------------------------------
    tomato = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cx, cy = S // 2, int(S * 0.62)
    r = int(S * 0.34)
    radial_fill(tomato, (cx - int(r * 0.18), cy - int(r * 0.18)), r,
                (255, 110, 90), (210, 38, 60))
    im = Image.alpha_composite(im, tomato)

    # tomato highlight (small soft circle top-left)
    hl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hl)
    hr = int(r * 0.30)
    hd.ellipse(
        (cx - int(r * 0.55) - hr, cy - int(r * 0.55) - hr,
         cx - int(r * 0.55) + hr, cy - int(r * 0.55) + hr),
        fill=(255, 220, 200, 110),
    )
    hl = hl.filter(ImageFilter.GaussianBlur(20))
    im = Image.alpha_composite(im, hl)

    # ----- Tomato leaves (green star on top) ---------------------------------
    leaf = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ld = ImageDraw.Draw(leaf)
    leaf_color = (76, 165, 80, 255)
    leaf_dark = (46, 110, 56, 255)
    lcx, lcy = cx, cy - r + int(r * 0.05)
    # Five leaf points around the top of the tomato.
    import math
    for i, angle_deg in enumerate([-90, -54, -18, 18, 54]):
        angle = math.radians(angle_deg)
        tip = (
            lcx + int(math.cos(angle) * r * 0.55),
            lcy + int(math.sin(angle) * r * 0.55),
        )
        side_a = math.radians(angle_deg - 18)
        side_b = math.radians(angle_deg + 18)
        base_a = (
            lcx + int(math.cos(side_a) * r * 0.18),
            lcy + int(math.sin(side_a) * r * 0.18),
        )
        base_b = (
            lcx + int(math.cos(side_b) * r * 0.18),
            lcy + int(math.sin(side_b) * r * 0.18),
        )
        ld.polygon([base_a, tip, base_b], fill=leaf_color)

    # tiny stem
    ld.rounded_rectangle(
        (lcx - int(r * 0.05), lcy - int(r * 0.18),
         lcx + int(r * 0.05), lcy + int(r * 0.05)),
        radius=int(r * 0.04),
        fill=leaf_dark,
    )
    im = Image.alpha_composite(im, leaf)

    # ----- Cat sitting on top: ears + face silhouette in white ---------------
    cat = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cd = ImageDraw.Draw(cat)

    # Cat head: white circle perched on the tomato's upper-front area.
    head_cx, head_cy = cx, int(S * 0.42)
    head_r = int(S * 0.20)
    # Head shadow under chin onto tomato
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(
        (head_cx - head_r, head_cy + int(head_r * 0.45),
         head_cx + head_r, head_cy + head_r + int(head_r * 0.25)),
        fill=(0, 0, 0, 80),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    im = Image.alpha_composite(im, shadow)

    # Ears (triangles, slightly rotated outward).
    ear_w = int(head_r * 0.65)
    ear_h = int(head_r * 0.85)
    # left
    cd.polygon([
        (head_cx - int(head_r * 0.85), head_cy - int(head_r * 0.10)),
        (head_cx - int(head_r * 0.10), head_cy - int(head_r * 0.55)),
        (head_cx - int(head_r * 0.18), head_cy - int(head_r * 0.95)),
    ], fill=(252, 252, 252, 255))
    # right
    cd.polygon([
        (head_cx + int(head_r * 0.85), head_cy - int(head_r * 0.10)),
        (head_cx + int(head_r * 0.10), head_cy - int(head_r * 0.55)),
        (head_cx + int(head_r * 0.18), head_cy - int(head_r * 0.95)),
    ], fill=(252, 252, 252, 255))

    # Inner ear pink
    cd.polygon([
        (head_cx - int(head_r * 0.70), head_cy - int(head_r * 0.18)),
        (head_cx - int(head_r * 0.20), head_cy - int(head_r * 0.50)),
        (head_cx - int(head_r * 0.25), head_cy - int(head_r * 0.80)),
    ], fill=(255, 165, 180, 255))
    cd.polygon([
        (head_cx + int(head_r * 0.70), head_cy - int(head_r * 0.18)),
        (head_cx + int(head_r * 0.20), head_cy - int(head_r * 0.50)),
        (head_cx + int(head_r * 0.25), head_cy - int(head_r * 0.80)),
    ], fill=(255, 165, 180, 255))

    # Head circle (drawn after ears so it joins them at the base).
    cd.ellipse(
        (head_cx - head_r, head_cy - int(head_r * 0.85),
         head_cx + head_r, head_cy + int(head_r * 1.0)),
        fill=(252, 252, 252, 255),
    )

    # Eyes (closed/cute — two short curves)
    eye_y = head_cy + int(head_r * 0.05)
    eye_dx = int(head_r * 0.40)
    eye_w = int(head_r * 0.22)
    eye_h = int(head_r * 0.10)
    for sign in (-1, +1):
        cd.arc(
            (head_cx + sign * eye_dx - eye_w, eye_y - eye_h,
             head_cx + sign * eye_dx + eye_w, eye_y + eye_h),
            start=200, end=340,
            fill=(35, 28, 38, 255), width=int(head_r * 0.07),
        )

    # Nose (tiny pink triangle)
    nose_y = head_cy + int(head_r * 0.32)
    nose_w = int(head_r * 0.10)
    cd.polygon([
        (head_cx - nose_w, nose_y),
        (head_cx + nose_w, nose_y),
        (head_cx, nose_y + int(head_r * 0.10)),
    ], fill=(255, 130, 145, 255))

    # Whiskers (subtle gray lines)
    wh = (130, 130, 140, 200)
    wlen = int(head_r * 0.55)
    wy = nose_y + int(head_r * 0.05)
    for sign in (-1, +1):
        for off in (-0.07, 0.0, 0.07):
            y = wy + int(head_r * off)
            cd.line(
                (head_cx + sign * int(head_r * 0.20), y,
                 head_cx + sign * (wlen + int(head_r * 0.20)), y - int(head_r * 0.04 * sign)),
                fill=wh, width=int(head_r * 0.025),
            )

    im = Image.alpha_composite(im, cat)

    im.save(out_path, "PNG")
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "/tmp/pomodocat-icon.png"
    main(out)
