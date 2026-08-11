"""Kelime Bahis app icon generator — brand-consistent, adaptive-icon-safe.

Reuses the exact palette/typography from the in-app theme (game_colors.dart,
table_surface.dart) so the launcher icon matches what players see once the
app opens. Produces:
  assets/branding/app_icon.png             -- flat square (legacy icon / store listing)
  assets/branding/app_icon_foreground.png  -- transparent, padded for adaptive-icon safe zone

Run: python scripts/generate_app_icon.py
"""

import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SIZE = 1024
SS = 3  # supersample factor for crisp vector-like edges
BIG = SIZE * SS

FONT_PATH = "assets/fonts/LibreCaslonText-Regular.ttf"
OUT_FLAT = "assets/branding/app_icon.png"
OUT_FG = "assets/branding/app_icon_foreground.png"
OUT_BG = "assets/branding/app_icon_background.png"

# Palette — lifted directly from lib/views/theme/game_colors.dart
BG_CENTER = (42, 34, 24)     # 0xFF2A2218 (TableSurface gradient start)
BG_MID = (23, 19, 12)        # 0xFF17130C  GameColors.bg
BG_EDGE = (18, 13, 7)        # 0xFF120D07  GameColors.bgLowest
TERRA_HI = (208, 96, 74)     # lightened GameColors.brand for gradient highlight
TERRA_LO = (137, 43, 26)     # 0xFF892B1A  GameColors.brandDeep
BRASS = (212, 175, 55)       # 0xFFD4AF37  GameColors.brass
GOLD = (233, 195, 73)        # 0xFFE9C349  GameColors.gold
CREAM = (236, 225, 213)      # 0xFFECE1D5  GameColors.ink


def radial_background(size):
    """Replicates TableSurface's RadialGradient (center/mid/edge stops)."""
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float64)
    cx = cy = size / 2
    r = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / (size / 2 * 1.15)
    r = np.clip(r, 0, 1)

    stops = [0.0, 0.55, 1.0]
    colors = [BG_CENTER, BG_MID, BG_EDGE]
    out = np.zeros((size, size, 3), dtype=np.float64)
    for ch in range(3):
        out[..., ch] = np.interp(r, stops, [c[ch] for c in colors])
    return Image.fromarray(out.astype(np.uint8), "RGB")


def diagonal_gradient_tile(w, h, hi, lo):
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float64)
    t = (xx / w + yy / h) / 2
    out = np.zeros((h, w, 3), dtype=np.float64)
    for ch in range(3):
        out[..., ch] = hi[ch] + (lo[ch] - hi[ch]) * t
    return Image.fromarray(out.astype(np.uint8), "RGB")


def rounded_mask(w, h, radius):
    m = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=radius, fill=255)
    return m


def build_tile_layer(canvas_size, tile_frac=0.62, corner_frac=0.20):
    """Terracotta rounded tile + bevel border + soft drop shadow, on transparent RGBA."""
    layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    tile_size = int(canvas_size * tile_frac)
    radius = int(tile_size * corner_frac)
    off = (canvas_size - tile_size) // 2

    # Drop shadow
    shadow = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    shadow_mask = rounded_mask(tile_size, tile_size, radius)
    shadow_layer = Image.new("RGBA", (tile_size, tile_size), (0, 0, 0, 235))
    shadow.paste(shadow_layer, (off, off + int(canvas_size * 0.018)), shadow_mask)
    shadow = shadow.filter(ImageFilter.GaussianBlur(canvas_size * 0.02))
    layer = Image.alpha_composite(layer, shadow)

    # Tile fill (diagonal terracotta gradient)
    fill = diagonal_gradient_tile(tile_size, tile_size, TERRA_HI, TERRA_LO).convert("RGBA")
    mask = rounded_mask(tile_size, tile_size, radius)
    tile_rgba = Image.new("RGBA", (tile_size, tile_size), (0, 0, 0, 0))
    tile_rgba.paste(fill, (0, 0), mask)
    layer.paste(tile_rgba, (off, off), tile_rgba)

    # Brass bevel border (inner highlight + outer rim)
    border = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    bd = ImageDraw.Draw(border)
    bw = max(2, int(canvas_size * 0.006))
    bd.rounded_rectangle(
        [off, off, off + tile_size - 1, off + tile_size - 1],
        radius=radius,
        outline=BRASS + (210,),
        width=bw,
    )
    layer = Image.alpha_composite(layer, border)

    return layer, off, tile_size


def bold_glyph_layer(canvas_size, xy, text, font, fill, weight_px):
    """Faux-bold via alpha-mask dilation (MaxFilter) — clean edges, no stairstepping."""
    mask = Image.new("L", (canvas_size, canvas_size), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.text(xy, text, font=font, fill=255, anchor="mm")

    k = max(1, int(round(weight_px)))
    if k % 2 == 0:
        k += 1
    if k > 1:
        mask = mask.filter(ImageFilter.MaxFilter(k))
    mask = mask.filter(ImageFilter.GaussianBlur(canvas_size * 0.0009))

    solid = Image.new("RGBA", (canvas_size, canvas_size), fill)
    out = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    out.paste(solid, (0, 0), mask)
    return out


def build_foreground(canvas_size):
    layer, off, tile_size = build_tile_layer(canvas_size)

    font_size = int(tile_size * 0.56)
    font = ImageFont.truetype(FONT_PATH, font_size)
    cx = off + tile_size / 2
    cy = off + tile_size * 0.44
    glyph = bold_glyph_layer(
        canvas_size, (cx, cy), "K", font, CREAM + (255,), tile_size * 0.018
    )
    layer = Image.alpha_composite(layer, glyph)
    draw = ImageDraw.Draw(layer)

    # Thin gold accent rule beneath the glyph (echoes the in-app title divider)
    rule_w = tile_size * 0.30
    rule_y = off + tile_size * 0.685
    rule_h = max(2, int(canvas_size * 0.006))
    draw.rounded_rectangle(
        [cx - rule_w / 2, rule_y, cx + rule_w / 2, rule_y + rule_h],
        radius=rule_h / 2,
        fill=GOLD + (235,),
    )

    return layer


def downsample(img, size):
    return img.resize((size, size), Image.LANCZOS)


def main():
    fg_big = build_foreground(BIG)
    fg = downsample(fg_big, SIZE)
    fg.save(OUT_FG)
    print(f"wrote {OUT_FG} {fg.size} (transparent, adaptive-icon foreground)")

    bg_big = radial_background(BIG).convert("RGBA")
    bg = downsample(bg_big, SIZE).convert("RGB")
    bg.save(OUT_BG)
    print(f"wrote {OUT_BG} {bg.size} (adaptive-icon background layer)")

    flat_big = Image.alpha_composite(bg_big, fg_big)
    flat = downsample(flat_big, SIZE).convert("RGB")
    flat.save(OUT_FLAT)
    print(f"wrote {OUT_FLAT} {flat.size} (flat square, legacy icon / store listing)")


if __name__ == "__main__":
    main()
