#!/usr/bin/env python3
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except Exception as e:
    raise SystemExit("Pillow is required. Install with: pip3 install pillow")


ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "store" / "screenshots" / "pngs"
OUT.mkdir(parents=True, exist_ok=True)


def rounded_rect(draw, xy, r, fill):
    draw.rounded_rectangle(xy, radius=r, fill=fill)


def draw_cookie(draw, cx, cy, scale=1.0):
    # Simple fortune cookie shape
    w = int(300 * scale)
    h = int(170 * scale)
    x0, y0 = cx - w // 2, cy - h // 2
    x1, y1 = cx + w // 2, cy + h // 2
    draw.ellipse((x0, y0, x1, y1), fill="#F3C66A", outline="#E2A84A", width=max(1, int(3 * scale)))
    # cookie fold
    draw.arc((x0 + int(20*scale), y0 + int(25*scale), x1 - int(20*scale), y1 + int(20*scale)), 15, 165, fill="#D49B45", width=max(1, int(3*scale)))
    # fortune slip
    slip_w = int(120 * scale)
    slip_h = int(18 * scale)
    sx0 = cx + int(35 * scale)
    sy0 = cy - int(75 * scale)
    draw.rounded_rectangle((sx0, sy0, sx0 + slip_w, sy0 + slip_h), radius=max(2, int(3*scale)), fill="#FFFFFF")


def draw_text(draw, x, y, text, size=24, fill="#111827"):
    try:
        font = ImageFont.truetype("Arial.ttf", size)
    except Exception:
        font = ImageFont.load_default()
    draw.text((x, y), text, fill=fill, font=font)


def make_hero():
    img = Image.new("RGB", (1280, 720), "#FBF7EF")
    d = ImageDraw.Draw(img)
    rounded_rect(d, (60, 560, 1220, 645), 12, "#FFFFFF")
    draw_cookie(d, 360, 300, 1.3)
    draw_text(d, 620, 240, "Cookie — one small daily fortune", size=46)
    draw_text(d, 620, 300, "Gentle, private and predictable.", size=24, fill="#6B7280")
    draw_text(d, 620, 335, "A tiny moment of calm every day.", size=24, fill="#6B7280")
    draw_text(d, 90, 592, "Auto-open daily popup • Copy and share • Local-only storage", size=22, fill="#374151")
    img.save(OUT / "hero-fortune-cookie.png")


def make_640():
    img = Image.new("RGB", (640, 400), "#FBF7EF")
    d = ImageDraw.Draw(img)
    draw_cookie(d, 180, 170, 0.9)
    rounded_rect(d, (270, 50, 610, 250), 14, "#FFFFFF")
    draw_text(d, 295, 90, "Be brave enough", size=24)
    draw_text(d, 295, 120, "to live creatively.", size=24)
    draw_text(d, 295, 170, "One peaceful thought per day", size=16, fill="#6B7280")
    img.save(OUT / "screenshot-fortune-1.png")


def make_440():
    img = Image.new("RGB", (440, 280), "#FBF7EF")
    d = ImageDraw.Draw(img)
    draw_cookie(d, 120, 130, 0.62)
    draw_text(d, 200, 55, "Today's thought", size=22)
    draw_text(d, 200, 95, "Do not be afraid", size=15)
    draw_text(d, 200, 117, "to take that next step.", size=15)
    draw_text(d, 200, 156, "Tap to copy or share", size=12, fill="#6B7280")
    img.save(OUT / "screenshot-fortune-2.png")


if __name__ == "__main__":
    make_hero()
    make_640()
    make_440()
    print(f"Generated PNG assets in: {OUT}")
