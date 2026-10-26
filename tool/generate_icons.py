#!/usr/bin/env python3
"""Draws the neon radar launcher icon + all Android mipmaps.

    python3 tool/generate_icons.py

Produces:
  assets/icon/app_icon.png              (1024² legacy icon)
  assets/icon/app_icon_foreground.png   (1024² adaptive foreground, transparent)
  android/app/src/main/res/mipmap-*/ic_launcher.png
  android/app/src/main/res/mipmap-*/ic_launcher_foreground.png
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
ICON_DIR = ROOT / "assets" / "icon"
RES = ROOT / "android" / "app" / "src" / "main" / "res"

SCALE = 4
SIZE = 1024
CANVAS = SIZE * SCALE

CYAN = (0, 229, 255)
PURPLE = (177, 75, 255)
ORANGE = (255, 138, 31)
RED = (255, 51, 85)
NAVY = (8, 9, 14)
NAVY_GLOW = (16, 46, 66)


def radial_background(size: int) -> Image.Image:
    """Deep navy with a soft cyan bloom in the upper third."""
    image = Image.new("RGB", (size, size), NAVY)
    pixels = image.load()
    cx, cy = size * 0.5, size * 0.42
    max_dist = math.hypot(size * 0.5, size * 0.5)
    for y in range(0, size, 2):
        for x in range(0, size, 2):
            dist = math.hypot(x - cx, y - cy) / max_dist
            glow = max(0.0, 1.0 - dist) ** 2.4
            r = int(NAVY[0] + (NAVY_GLOW[0] - NAVY[0]) * glow)
            g = int(NAVY[1] + (NAVY_GLOW[1] - NAVY[1]) * glow)
            b = int(NAVY[2] + (NAVY_GLOW[2] - NAVY[2]) * glow)
            for dy in range(2):
                for dx in range(2):
                    if x + dx < size and y + dy < size:
                        pixels[x + dx, y + dy] = (r, g, b)
    return image.convert("RGBA")


def glow_layer(draw_fn, size: int, blur: float) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(layer))
    return layer.filter(ImageFilter.GaussianBlur(blur))


def draw_mark(size: int, scale: int, foreground: bool) -> Image.Image:
    """The radar mark: rings, rotating sweep, center glow and two blips."""
    s = size * scale
    mark = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(mark)
    cx = cy = s // 2
    radius = s * (0.30 if foreground else 0.335)

    # Rings ------------------------------------------------------------------
    for index, fraction in enumerate((0.34, 0.67, 1.0)):
        r = radius * fraction
        width = int(s * 0.0075) if fraction == 1.0 else int(s * 0.0045)
        alpha = 190 if fraction == 1.0 else 95
        draw.ellipse(
            [cx - r, cy - r, cx + r, cy + r],
            outline=(*CYAN, alpha),
            width=max(2, width),
        )

    # Tick ring --------------------------------------------------------------
    ticks = 48
    for i in range(ticks):
        angle = math.radians(i * 360 / ticks - 90)
        major = i % 4 == 0
        outer = radius * 1.045
        inner = radius * (1.0 if major else 1.022)
        draw.line(
            [
                (cx + math.cos(angle) * inner, cy + math.sin(angle) * inner),
                (cx + math.cos(angle) * outer, cy + math.sin(angle) * outer),
            ],
            fill=(*CYAN, 150 if major else 60),
            width=max(2, int(s * (0.0045 if major else 0.0025))),
        )

    # Crosshair --------------------------------------------------------------
    for angle in (0, 90):
        a = math.radians(angle)
        draw.line(
            [
                (cx - math.cos(a) * radius * 0.92, cy - math.sin(a) * radius * 0.92),
                (cx + math.cos(a) * radius * 0.92, cy + math.sin(a) * radius * 0.92),
            ],
            fill=(*CYAN, 40),
            width=max(2, int(s * 0.002)),
        )

    # Sweep wedge (leading edge pointing up) ---------------------------------
    sweep = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    sweep_draw = ImageDraw.Draw(sweep)
    steps = 70
    start, end = 232.0, 270.0  # PIL: 0° = 3 o'clock, clockwise
    for i in range(steps):
        a0 = start + (end - start) * i / steps
        a1 = a0 + (end - start) / steps + 0.4
        alpha = int(150 * (i / steps) ** 1.9)
        sweep_draw.pieslice(
            [cx - radius, cy - radius, cx + radius, cy + radius],
            a0,
            a1,
            fill=(*CYAN, alpha),
        )
    mark = Image.alpha_composite(mark, sweep)

    # Leading edge flare -----------------------------------------------------
    draw = ImageDraw.Draw(mark)
    top = (cx, cy - radius)
    draw.line([(cx, cy), top], fill=(*CYAN, 235), width=max(2, int(s * 0.0035)))
    flare = glow_layer(
        lambda d: d.ellipse(
            [top[0] - s * 0.035, top[1] - s * 0.035, top[0] + s * 0.035, top[1] + s * 0.035],
            fill=(*CYAN, 210),
        ),
        s,
        blur=s * 0.012,
    )
    mark = Image.alpha_composite(mark, flare)

    # Center glow ------------------------------------------------------------
    core_glow = glow_layer(
        lambda d: d.ellipse(
            [cx - radius * 0.30, cy - radius * 0.30, cx + radius * 0.30, cy + radius * 0.30],
            fill=(*CYAN, 120),
        ),
        s,
        blur=s * 0.02,
    )
    mark = Image.alpha_composite(mark, core_glow)
    draw = ImageDraw.Draw(mark)
    core = radius * 0.075
    draw.ellipse([cx - core, cy - core, cx + core, cy + core], fill=(*CYAN, 255))

    # Blips ------------------------------------------------------------------
    blips = [
        (38, 0.58, RED, 0.045),
        (206, 0.78, PURPLE, 0.036),
        (314, 0.42, ORANGE, 0.028),
    ]
    for degrees, distance, color, dot in blips:
        angle = math.radians(degrees - 90)
        bx = cx + math.cos(angle) * radius * distance
        by = cy + math.sin(angle) * radius * distance
        dot_r = s * dot
        halo = glow_layer(
            lambda d, bx=bx, by=by, dot_r=dot_r, color=color: d.ellipse(
                [bx - dot_r * 1.75, by - dot_r * 1.75, bx + dot_r * 1.75, by + dot_r * 1.75],
                fill=(*color, 85),
            ),
            s,
            blur=s * 0.0055,
        )
        mark = Image.alpha_composite(mark, halo)
        draw = ImageDraw.Draw(mark)
        draw.ellipse([bx - dot_r, by - dot_r, bx + dot_r, by + dot_r], fill=(*color, 255))
        ring = dot_r * 2.1
        draw.ellipse(
            [bx - ring, by - ring, bx + ring, by + ring],
            outline=(*color, 110),
            width=max(2, int(s * 0.0022)),
        )

    return mark.resize((size, size), Image.LANCZOS)


def build_icons() -> None:
    ICON_DIR.mkdir(parents=True, exist_ok=True)

    background = radial_background(SIZE // 2).resize((SIZE, SIZE), Image.BICUBIC)
    mark = draw_mark(SIZE, SCALE, foreground=False)
    legacy = Image.alpha_composite(background, mark).convert("RGB")
    legacy.save(ICON_DIR / "app_icon.png")
    print("wrote assets/icon/app_icon.png")

    foreground = draw_mark(SIZE, SCALE, foreground=True)
    foreground.save(ICON_DIR / "app_icon_foreground.png")
    print("wrote assets/icon/app_icon_foreground.png")

    densities = {
        "mdpi": (48, 108),
        "hdpi": (72, 162),
        "xhdpi": (96, 216),
        "xxhdpi": (144, 324),
        "xxxhdpi": (192, 432),
    }
    for density, (legacy_size, foreground_size) in densities.items():
        folder = RES / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        legacy.resize((legacy_size, legacy_size), Image.LANCZOS).save(
            folder / "ic_launcher.png"
        )
        foreground.resize((foreground_size, foreground_size), Image.LANCZOS).save(
            folder / "ic_launcher_foreground.png"
        )
        print(f"wrote mipmap-{density} icons")


if __name__ == "__main__":
    build_icons()
