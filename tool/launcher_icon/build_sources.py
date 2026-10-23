#!/usr/bin/env python3
"""Build every icon format from the Bosstro emblem.

`icons/bosstro.png` is the source art: the Mostro mascot as a judge, holding a
gavel, inside a gold ring, on a transparent square (D11, A8 in AGENTS.md). It
is a variant of ../app's icon, not a copy, so a phone with both apps shows two
different icons. This script writes:

- `icons/bosstro-<side>.png` (1024 … 16): the disc on transparent corners.
  1024 is the master, and the source of the Android launcher icons (legacy
  icon and adaptive foreground).
- `icons/bosstro-store-512.png`: the disc on the emblem's dark background,
  opaque, for store listings that refuse transparency.
- `icons/bosstro.webp`: the disc at 512 px, lossless WebP.
- `icons/bosstro.ico`: 16 to 256 px, for desktop and web uses.
- `web/favicon.png` and `web/icons/Icon-*.png`: the web favicon and PWA icons; the
  maskable ones put the disc inside the 80 % safe zone on the dark background.
- `assets/images/bosstro_emblem.webp`: the disc at 512 px for in-app use
  (welcome screen, about).
- `android/app/src/main/res/drawable-*/splash_logo.png`: the disc at 160 dp,
  the launch screen logo below Android 12 (12+ draws the adaptive icon).

Then regenerate the launcher icons from the master (see the
`flutter_launcher_icons` block in pubspec.yaml). Needs only Pillow:

    python3 tool/launcher_icon/build_sources.py
    dart run flutter_launcher_icons
"""

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
ICONS = ROOT / 'icons'
SOURCE = ICONS / 'bosstro.png'

SIZE = 1024
# The emblem's own background, behind the opaque store icon and the adaptive
# icon (pubspec.yaml repeats it).
BACKGROUND = (0x11, 0x17, 0x22)
# Inside this share of the disc's radius every pixel is made fully opaque: the
# source's interior is 97-98 % alpha, which would let a light launcher
# background tint the art. The edge keeps its own antialiasing.
OPAQUE_CORE = 0.97
SUPERSAMPLING = 4
PNG_SIDES = [1024, 512, 256, 192, 128, 96, 64, 48, 32, 16]
ICO_SIDES = [16, 24, 32, 48, 64, 128, 256]
STORE_SIDE = 512
WEBP_SIDE = 512
SPLASH_LOGO_DP = 160
# A maskable web icon may be cut to any shape inside a circle of 80 % of its
# side (the "safe zone"), so the disc sits at that size on its background.
MASKABLE_SAFE_ZONE = 0.8
ANDROID_DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}


def disc():
    """The emblem cropped square around its disc, with an opaque core."""
    art = Image.open(SOURCE).convert('RGBA')
    left, top, right, bottom = art.getchannel('A').point(lambda a: 255 if a > 128 else 0).getbbox()
    side = max(right - left, bottom - top)
    cx, cy = (left + right) / 2, (top + bottom) / 2
    # A 1 % margin so the antialiased rim is never cut.
    half = side / 2 * 1.01
    art = art.crop((round(cx - half), round(cy - half), round(cx + half), round(cy + half)))
    art = art.resize((SIZE, SIZE), Image.LANCZOS)

    big = SIZE * SUPERSAMPLING
    core = Image.new('L', (big, big), 0)
    inset = big / 2 * (1 - OPAQUE_CORE / 1.01)
    ImageDraw.Draw(core).ellipse((inset, inset, big - inset, big - inset), fill=255)
    core = core.resize((SIZE, SIZE), Image.LANCZOS)
    art.putalpha(ImageChops.lighter(art.getchannel('A'), core))
    return art


def scaled(image, side):
    return image.resize((side, side), Image.LANCZOS)


def save_png(image, side, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    scaled(image, side).save(path, optimize=True)


def main():
    icon = disc()
    for side in PNG_SIDES:
        save_png(icon, side, ICONS / f'bosstro-{side}.png')

    store = Image.new('RGBA', (SIZE, SIZE), BACKGROUND + (255,))
    store.alpha_composite(icon)
    save_png(store.convert('RGB'), STORE_SIDE, ICONS / 'bosstro-store-512.png')

    scaled(icon, WEBP_SIDE).save(ICONS / 'bosstro.webp', lossless=True, method=6)
    scaled(icon, ICO_SIDES[-1]).save(
        ICONS / 'bosstro.ico', format='ICO', sizes=[(s, s) for s in ICO_SIDES]
    )

    scaled(icon, WEBP_SIDE).save(
        ROOT / 'assets' / 'images' / 'bosstro_emblem.webp', quality=90, method=6
    )

    web = ROOT / 'web'
    save_png(icon, 32, web / 'favicon.png')
    for side in (192, 512):
        save_png(icon, side, web / 'icons' / f'Icon-{side}.png')
        maskable = Image.new('RGBA', (SIZE, SIZE), BACKGROUND + (255,))
        inner = round(SIZE * MASKABLE_SAFE_ZONE)
        offset = (SIZE - inner) // 2
        maskable.alpha_composite(scaled(icon, inner), (offset, offset))
        save_png(maskable.convert('RGB'), side, web / 'icons' / f'Icon-maskable-{side}.png')

    res = ROOT / 'android' / 'app' / 'src' / 'main' / 'res'
    for density, factor in ANDROID_DENSITIES.items():
        save_png(icon, round(SPLASH_LOGO_DP * factor), res / f'drawable-{density}' / 'splash_logo.png')


if __name__ == '__main__':
    main()
