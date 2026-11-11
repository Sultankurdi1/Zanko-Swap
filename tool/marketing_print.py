"""Print-ready posters with a QR code to the ZankoSwap download page.

Usage:
  pip install segno
  python3 tool/marketing_print.py

Output in store/marketing/:
  poster-a4.png        Campus poster, A4 at 300 dpi
  counter-card-a6.png  Card for cafe / copy shop counters, A6 at 300 dpi
  qr-download.png      The QR code alone

The QR always points at DOWNLOAD_URL. That page links to the stores, so the
printed posters keep working after the app is published.
"""

import io
import re
import sys
from pathlib import Path

import segno
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
from store_images import (  # noqa: E402
    BODY_FONT, ICON, LATIN_FONT, ORANGE, TITLE_FONT, WHITE, font, glow, gradient, rounded,
)

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "store" / "marketing"
DOWNLOAD_URL = "https://sultankurdi1.github.io/Zanko-Swap/download/"
INK = (40, 20, 90)
RTL = {"direction": "rtl", "language": "ckb"}


def qr_image(size):
    buf = io.BytesIO()
    segno.make(DOWNLOAD_URL, error="h").save(buf, kind="png", scale=20, border=0, dark="#28145a")
    buf.seek(0)
    return Image.open(buf).convert("RGB").resize((size, size), Image.NEAREST)


LATIN_RUN = re.compile(r"[A-Za-z0-9][A-Za-z0-9 .%-]*[A-Za-z0-9%]|[A-Za-z0-9%]")


def _runs(text, fnt):
    """Splits Kurdish text with English words into runs, each with its font."""
    latin = font(LATIN_FONT, int(fnt.size * 0.92))
    runs, pos = [], 0
    for m in LATIN_RUN.finditer(text):
        if m.start() > pos:
            runs.append((text[pos:m.start()], fnt, RTL))
        runs.append((m.group(), latin, {}))
        pos = m.end()
    if pos < len(text):
        runs.append((text[pos:], fnt, RTL))
    return runs


def mixed_width(draw, text, fnt):
    return sum(draw.textlength(t, font=f, **k) for t, f, k in _runs(text, fnt))


def draw_rtl(draw, right, y, text, fnt, fill):
    """Draws right-to-left text whose top is at y; English words keep a Latin font."""
    top = draw.textbbox((0, 0), "ئا", font=fnt, anchor="ls", **RTL)[1]
    baseline = y - top
    x = right
    for t, f, k in _runs(text, fnt):
        w = draw.textlength(t, font=f, **k)
        x -= w
        draw.text((x, baseline), t, font=f, fill=fill, anchor="ls", **k)
    return int(fnt.size * 1.3)


def center_rtl(draw, y, text, fnt, width, fill):
    w = mixed_width(draw, text, fnt)
    return draw_rtl(draw, (width + w) / 2, y, text, fnt, fill)


def brand(img, draw, cx, y, icon_size, name_size):
    icon = rounded(Image.open(ICON).convert("RGB").resize((icon_size, icon_size), Image.LANCZOS), icon_size // 4)
    name = font(LATIN_FONT, name_size)
    zw = draw.textlength("Zanko", font=name)
    sw = draw.textlength("Swap", font=name)
    gap = icon_size // 4
    total = icon_size + gap + zw + sw
    x = int(cx - total / 2)
    img.alpha_composite(icon, (x, y))
    ty = y + (icon_size - name_size) // 2 - name_size // 6
    draw.text((x + icon_size + gap, ty), "Zanko", font=name, fill=WHITE)
    draw.text((x + icon_size + gap + zw, ty), "Swap", font=name, fill=ORANGE)


def qr_card(img, cx, y, qr_size, caption, sub, scale):
    pad = int(50 * scale)
    w = qr_size + pad * 2
    h = qr_size + pad * 2 + int(190 * scale)
    x = cx - w // 2
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([x, y + 30, x + w, y + h + 30], int(60 * scale), fill=(20, 0, 60, 120))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(int(40 * scale))))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle([x, y, x + w, y + h], int(60 * scale), fill=WHITE)
    img.paste(qr_image(qr_size), (x + pad, y + pad))
    ty = y + pad + qr_size + int(35 * scale)
    ty += center_rtl(draw, ty, caption, font(TITLE_FONT, int(64 * scale)), img.width, INK) + int(28 * scale)
    center_rtl(draw, ty, sub, font(BODY_FONT, int(42 * scale)), img.width, (110, 90, 160))
    return y + h


def poster_a4():
    w, h = 2480, 3508
    img = gradient((w, h)).convert("RGBA")
    glow(img, (300, 300), 900, WHITE, 40)
    glow(img, (2300, 3300), 1000, ORANGE, 70)
    draw = ImageDraw.Draw(img)

    brand(img, draw, w // 2, 190, 230, 150)
    y = 560
    y += center_rtl(draw, y, "کتێبەکەت بفرۆشە،", font(TITLE_FONT, 150), w, WHITE) + 70
    y += center_rtl(draw, y, "کتێبی هەرزان بکڕە", font(TITLE_FONT, 150), w, (255, 214, 170)) + 90
    y += center_rtl(draw, y, "ئەپی بازاڕی قوتابیانی کوردستان", font(BODY_FONT, 80), w, (240, 236, 255)) + 140

    items = [
        "کڕین و فرۆشتنی کتێب، ئامێر و کەلوپەلی خوێندن",
        "پرسیارەکانی تاقیکردنەوەی ساڵانی پێشوو",
        "توێژینەوە و سەرچاوە بە PDF",
        "داشکاندنی تایبەت لە کافێ و فۆتۆکۆپی",
    ]
    body = font(BODY_FONT, 66)
    right = w - 330
    for text in items:
        th = draw_rtl(draw, right, y, text, body, WHITE)
        dot_x = right + 70
        dot_y = y + th // 2
        draw.ellipse([dot_x - 26, dot_y - 26, dot_x + 26, dot_y + 26], fill=ORANGE)
        draw.line([(dot_x - 12, dot_y), (dot_x - 3, dot_y + 10), (dot_x + 13, dot_y - 10)], fill=WHITE, width=8)
        y += th + 60

    qr_card(img, w // 2, y + 140, 1000, "سکان بکە و دایبگرە", "بەخۆڕاییە، بە کوردی و عەرەبی و English", 1.0)
    img.convert("RGB").save(OUT / "poster-a4.png", dpi=(300, 300), optimize=True)


def counter_card_a6():
    w, h = 1240, 1748
    img = gradient((w, h)).convert("RGBA")
    glow(img, (1100, 1600), 500, ORANGE, 70)
    draw = ImageDraw.Draw(img)

    brand(img, draw, w // 2, 90, 120, 80)
    y = 290
    y += center_rtl(draw, y, "ئەم شوێنە لە ئەپی ZankoSwap هەیە", font(TITLE_FONT, 64), w, WHITE) + 50
    y += center_rtl(draw, y, "داشکاندن بۆ قوتابیان", font(BODY_FONT, 52), w, (255, 214, 170)) + 40

    bw, bh = 420, 150
    bx = (w - bw) // 2
    draw.rounded_rectangle([bx, y, bx + bw, y + bh], 36, outline=WHITE, width=6)
    pct = font(LATIN_FONT, 96)
    draw.text((bx + bw - 30 - draw.textlength("%", font=pct), y + 12), "%", font=pct, fill=WHITE)
    y += bh + 60

    qr_card(img, w // 2, y + 20, 620, "سکان بکە و دایبگرە", "کتێب بکڕە و بفرۆشە", 0.8)
    img.convert("RGB").save(OUT / "counter-card-a6.png", dpi=(300, 300), optimize=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    qr_image(1200).save(OUT / "qr-download.png", dpi=(300, 300))
    poster_a4()
    counter_card_a6()
    print(f"Done: {OUT}")


if __name__ == "__main__":
    main()
