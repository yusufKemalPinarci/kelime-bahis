"""Kelime Bahis Play Store feature graphic (1024x500) — reuses the app icon's
design system (same gradient background, same gold-on-terracotta tile, same
LibreCaslonText brand type) so store presence matches the actual app icon.

Run: python scripts/generate_feature_graphic.py
"""

import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

from generate_app_icon import (
    radial_background,
    build_tile_layer,
    bold_glyph_layer,
    BRASS,
    GOLD,
    CREAM,
    FONT_PATH,
)

W, H = 1024, 500
SS = 3
BIG_W, BIG_H = W * SS, H * SS

OUT = "play_store_assets/feature_graphic_1024x500.png"


def gold_gradient_text(size, xy, text, font, anchor="lm"):
    """Vertical gold gradient fill (like the in-app ShaderMask title)."""
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).text(xy, text, font=font, fill=255, anchor=anchor)
    bbox = mask.getbbox()
    if bbox is None:
        return Image.new("RGBA", size, (0, 0, 0, 0))
    top, bottom = bbox[1], bbox[3]

    grad = np.zeros((size[1], size[0], 3), dtype=np.float64)
    stops = [0.0, 0.5, 0.75, 1.0]
    colors = [(191, 149, 63), (252, 246, 186), (179, 135, 40), (251, 245, 183)]
    yy = np.arange(size[1])
    t = np.clip((yy - top) / max(1, (bottom - top)), 0, 1)
    row = np.zeros((size[1], 3), dtype=np.float64)
    for ch in range(3):
        row[:, ch] = np.interp(t, stops, [c[ch] for c in colors])
    grad[:, :, :] = row[:, None, :]

    grad_img = Image.fromarray(grad.astype(np.uint8), "RGB").convert("RGBA")
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    out.paste(grad_img, (0, 0), mask)
    return out


def main():
    bg = radial_background(max(BIG_W, BIG_H))
    bg = bg.crop((
        (bg.width - BIG_W) // 2,
        (bg.height - BIG_H) // 2,
        (bg.width - BIG_W) // 2 + BIG_W,
        (bg.height - BIG_H) // 2 + BIG_H,
    )).convert("RGBA")

    canvas = bg.copy()
    draw = ImageDraw.Draw(canvas)

    # --- Left: brand title ---
    title_font = ImageFont.truetype(FONT_PATH, int(72 * SS))
    sub_font = ImageFont.truetype(FONT_PATH, int(22 * SS))

    margin_x = int(56 * SS)
    rule_w = int(430 * SS)
    line1_y = int(135 * SS)
    line2_y = int(215 * SS)
    rule2_y = int(272 * SS)
    sub_y = int(302 * SS)

    def rule(y):
        draw.rectangle(
            [margin_x, y, margin_x + rule_w, y + max(1, SS // 2)],
            fill=GOLD + (150,),
        )

    rule(int(60 * SS))
    title1 = gold_gradient_text((BIG_W, BIG_H), (margin_x, line1_y), "KELİME", title_font, anchor="lm")
    title2 = gold_gradient_text((BIG_W, BIG_H), (margin_x, line2_y), "BAHİS", title_font, anchor="lm")
    canvas = Image.alpha_composite(canvas, title1)
    canvas = Image.alpha_composite(canvas, title2)
    draw = ImageDraw.Draw(canvas)
    rule(rule2_y)

    draw.text(
        (margin_x, sub_y),
        "Türkçe kelime · offline oynanır",
        font=sub_font,
        fill=CREAM + (235,),
        anchor="lm",
    )

    # --- Right: the app icon tile, gently rotated ---
    tile_canvas = int(420 * SS)
    tile_layer, _, _ = build_tile_layer(tile_canvas, tile_frac=0.86, corner_frac=0.20)
    tile_img = tile_layer

    font_size = int(tile_canvas * 0.86 * 0.20 * 2.5)
    tdraw = ImageDraw.Draw(tile_img)
    k_font = ImageFont.truetype(FONT_PATH, int(tile_canvas * 0.30))
    cx = tile_canvas / 2
    cy = tile_canvas * 0.44
    glyph = bold_glyph_layer(tile_canvas, (cx, cy), "K", k_font, CREAM + (255,), tile_canvas * 0.010)
    tile_img = Image.alpha_composite(tile_img, glyph)
    tdraw = ImageDraw.Draw(tile_img)
    rule_w2 = tile_canvas * 0.86 * 0.30
    rule_y2 = tile_canvas * 0.685
    rule_h2 = max(2, int(tile_canvas * 0.006))
    tdraw.rounded_rectangle(
        [cx - rule_w2 / 2, rule_y2, cx + rule_w2 / 2, rule_y2 + rule_h2],
        radius=rule_h2 / 2,
        fill=GOLD + (235,),
    )

    tile_img = tile_img.rotate(-9, resample=Image.BICUBIC, expand=True)

    paste_x = BIG_W - tile_img.width + int(40 * SS)
    paste_y = (BIG_H - tile_img.height) // 2
    canvas.alpha_composite(tile_img, (paste_x, paste_y))

    # Downsample for crisp anti-aliasing
    final = canvas.resize((W, H), Image.LANCZOS).convert("RGB")
    final.save(OUT)
    print(f"wrote {OUT} {final.size}")


if __name__ == "__main__":
    main()
