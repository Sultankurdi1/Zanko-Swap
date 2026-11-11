"""Makes the store listing images for Google Play and the App Store.

Usage:
  1. Put phone screenshots in store/raw/ named 01.png, 02.png, ... in the order
     they should appear. The number picks the caption from CAPTIONS below.
  2. python3 tool/store_images.py

Output goes to store/out/:
  play-icon-512.png        Google Play app icon
  play-feature-1024x500.png Google Play feature graphic
  play/NN.png              Google Play phone screenshots (1080x1920)
  ios/NN.png               App Store 6.9" iPhone screenshots (1320x2868)
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "store" / "raw"
OUT = ROOT / "store" / "out"
ICON = ROOT / "tool" / "icons" / "app_icon_ios.png"

FONT_DIR = Path("/usr/share/fonts/truetype/noto")
TITLE_FONT = FONT_DIR / "NotoKufiArabic-Bold.ttf"
BODY_FONT = FONT_DIR / "NotoSansArabic-Regular.ttf"
LATIN_FONT = FONT_DIR / "NotoSans-Bold.ttf"

TOP = (122, 27, 210)
BOTTOM = (54, 169, 232)
ORANGE = (247, 154, 85)
WHITE = (255, 255, 255)

CAPTIONS = {
    1: ("بازاڕی قوتابیان", "کتێب، ئامێر و کەلوپەلی خوێندن بکڕە و بفرۆشە"),
    2: ("هەموو وردەکارییەک", "وێنە، نرخ و هەڵسەنگاندنی فرۆشیار لە یەک شوێن"),
    3: ("ڕاستەوخۆ قسە بکە", "چاتی خێرا لەگەڵ فرۆشیار، بێ ژمارەی تەلەفۆن"),
    4: ("لە چەند چرکەیەکدا", "کاڵاکەت دابنێ و بیگەیەنە هەموو قوتابیان"),
    5: ("توێژینەوە و تاقیکردنەوە", "سەرچاوەی خوێندن بۆ هەموو بەشەکان"),
    6: ("پەیمانگا و خزمەتگوزاری", "شوێن و خزمەتگوزارییەکانی نزیک خۆت بدۆزەرەوە"),
    7: ("پارێزراو و متمانەپێکراو", "وشە و وێنەی نەشیاو ڕێگەپێنەدراوە"),
    8: ("هەژماری خۆت", "پرۆفایل، کاڵا هەڵگیراوەکان و ڕێکخستنەکان"),
}


def font(path, size):
    return ImageFont.truetype(str(path), size, layout_engine=ImageFont.Layout.RAQM)


def gradient(size, top=TOP, bottom=BOTTOM):
    w, h = size
    img = Image.new("RGB", size)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(h - 1, 1)
        c = tuple(round(a + (b - a) * t) for a, b in zip(top, bottom))
        draw.line([(0, y), (w, y)], fill=c)
    return img


def glow(img, center, radius, color, alpha):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    x, y = center
    ImageDraw.Draw(layer).ellipse(
        [x - radius, y - radius, x + radius, y + radius], fill=color + (alpha,)
    )
    layer = layer.filter(ImageFilter.GaussianBlur(radius // 2))
    img.paste(layer, (0, 0), layer)


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *img.size], radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def centered_text(draw, y, text, fnt, width, fill, rtl=True):
    kwargs = {"direction": "rtl", "language": "ckb"} if rtl else {}
    box = draw.textbbox((0, 0), text, font=fnt, **kwargs)
    tw = box[2] - box[0]
    draw.text(((width - tw) / 2 - box[0], y - box[1]), text, font=fnt, fill=fill, **kwargs)
    return box[3] - box[1]


def wrap(draw, text, fnt, max_width):
    words, lines, line = text.split(), [], ""
    for word in words:
        trial = f"{line} {word}".strip()
        box = draw.textbbox((0, 0), trial, font=fnt, direction="rtl", language="ckb")
        if box[2] - box[0] <= max_width or not line:
            line = trial
        else:
            lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines


def play_icon():
    icon = Image.open(ICON).convert("RGB").resize((512, 512), Image.LANCZOS)
    icon.save(OUT / "play-icon-512.png", optimize=True)


def feature_graphic():
    w, h = 1024, 500
    img = gradient((h, w), TOP, BOTTOM).rotate(90, expand=True).convert("RGBA")
    glow(img, (180, 80), 260, WHITE, 40)
    glow(img, (900, 460), 220, ORANGE, 70)

    icon = rounded(Image.open(ICON).convert("RGB").resize((300, 300), Image.LANCZOS), 66)
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([674, 116, 974, 416], 66, fill=(20, 0, 60, 110))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    img.alpha_composite(shadow)
    img.alpha_composite(icon, (664, 100))

    draw = ImageDraw.Draw(img)
    name = font(LATIN_FONT, 84)
    draw.text((70, 120), "Zanko", font=name, fill=WHITE)
    zw = draw.textlength("Zanko", font=name)
    draw.text((70 + zw, 120), "Swap", font=name, fill=ORANGE)

    line = font(TITLE_FONT, 40)
    sub = font(BODY_FONT, 30)
    rtl = {"direction": "rtl", "language": "ckb"}
    right = 600
    for y, text, fnt in [
        (250, "بازاڕی قوتابیانی کوردستان", line),
        (330, "کڕین، فرۆشتن و گۆڕینەوە بە ئاسانی", sub),
    ]:
        box = draw.textbbox((0, 0), text, font=fnt, **rtl)
        draw.text((right - (box[2] - box[0]) - box[0], y - box[1]), text, font=fnt, fill=WHITE, **rtl)

    img.convert("RGB").save(OUT / "play-feature-1024x500.png", optimize=True)


def framed(shot, number, size, folder):
    w, h = size
    s = w / 1080
    img = gradient(size).convert("RGBA")
    glow(img, (int(w * 0.15), int(h * 0.08)), int(420 * s), WHITE, 35)
    glow(img, (int(w * 0.9), int(h * 0.95)), int(460 * s), ORANGE, 60)
    draw = ImageDraw.Draw(img)

    title, subtitle = CAPTIONS.get(number, ("ZankoSwap", ""))
    y = int(110 * s)
    y += centered_text(draw, y, title, font(TITLE_FONT, int(82 * s)), w, WHITE) + int(40 * s)
    body = font(BODY_FONT, int(44 * s))
    for line in wrap(draw, subtitle, body, int(w * 0.84)):
        y += centered_text(draw, y, line, body, w, (240, 236, 255)) + int(18 * s)

    top = y + int(60 * s)
    max_h = h - top - int(70 * s)
    max_w = int(w * 0.8)
    scale = min(max_w / shot.width, max_h / shot.height)
    sw, sh = int(shot.width * scale), int(shot.height * scale)
    radius = int(56 * s)
    bezel = int(14 * s)
    x = (w - sw) // 2

    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [x - bezel, top - bezel + int(30 * s), x + sw + bezel, top + sh + bezel + int(30 * s)],
        radius + bezel,
        fill=(25, 0, 70, 120),
    )
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(int(40 * s))))
    ImageDraw.Draw(img).rounded_rectangle(
        [x - bezel, top - bezel, x + sw + bezel, top + sh + bezel], radius + bezel, fill=(18, 18, 24)
    )
    img.alpha_composite(rounded(shot.resize((sw, sh), Image.LANCZOS), radius), (x, top))

    img.convert("RGB").save(OUT / folder / f"{number:02d}.png", optimize=True)


def main():
    (OUT / "play").mkdir(parents=True, exist_ok=True)
    (OUT / "ios").mkdir(parents=True, exist_ok=True)
    play_icon()
    feature_graphic()

    shots = sorted(p for p in RAW.glob("*") if p.suffix.lower() in {".png", ".jpg", ".jpeg"}) if RAW.exists() else []
    for path in shots:
        try:
            number = int(path.stem)
        except ValueError:
            print(f"Skipped {path.name}: name it 01.png, 02.png, ...")
            continue
        shot = Image.open(path).convert("RGB")
        framed(shot, number, (1080, 1920), "play")
        framed(shot, number, (1320, 2868), "ios")
        print(f"Made {path.name}")

    if not shots:
        print("No screenshots in store/raw/ yet; made the icon and feature graphic only.")
    print(f"Done: {OUT}")


if __name__ == "__main__":
    main()
