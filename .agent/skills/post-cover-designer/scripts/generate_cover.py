#!/usr/bin/env python3
"""
generate_cover.py – Generates a 1600×900 blog post cover image using Pillow.

Usage:
    python generate_cover.py \
        --title "My Blog Post Title" \
        --output "content/posts/2024-06-15-my-post/cover.jpg" \
        --technologies "Azure,Bicep,GitHub Actions" \
        --bg-color "#0a1628" \
        --accent-color "#00b4d8"
"""

import argparse
import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Pillow is not installed. Run: pip install pillow", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def hex_to_rgb(hex_color: str) -> tuple[int, int, int]:
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def lerp_color(
    c1: tuple[int, int, int], c2: tuple[int, int, int], t: float
) -> tuple[int, int, int]:
    return (
        int(c1[0] + (c2[0] - c1[0]) * t),
        int(c1[1] + (c2[1] - c1[1]) * t),
        int(c1[2] + (c2[2] - c1[2]) * t),
    )


def draw_gradient(img: Image.Image, color_top: tuple, color_bottom: tuple) -> None:
    draw = ImageDraw.Draw(img)
    width, height = img.size
    for y in range(height):
        t = y / (height - 1)
        color = lerp_color(color_top, color_bottom, t)
        draw.line([(0, y), (width, y)], fill=color)


def get_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    """Try common system fonts; fall back to the built-in bitmap font."""
    candidates = []
    if bold:
        candidates = [
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
            "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf",
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
            "C:/Windows/Fonts/arialbd.ttf",
        ]
    else:
        candidates = [
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
            "/usr/share/fonts/truetype/freefont/FreeSans.ttf",
            "/System/Library/Fonts/Supplemental/Arial.ttf",
            "C:/Windows/Fonts/arial.ttf",
        ]
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default()


def wrap_text(text: str, font: ImageFont.FreeTypeFont | ImageFont.ImageFont, max_width: int, draw: ImageDraw.ImageDraw) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        test = f"{current} {word}".strip()
        bbox = draw.textbbox((0, 0), test, font=font)
        if bbox[2] - bbox[0] <= max_width:
            current = test
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


# ---------------------------------------------------------------------------
# Main generation logic
# ---------------------------------------------------------------------------

def generate_cover(
    title: str,
    output_path: str,
    technologies: list[str],
    bg_color: str = "#0a1628",
    accent_color: str = "#00b4d8",
    width: int = 1600,
    height: int = 900,
) -> None:
    bg_top = hex_to_rgb(bg_color)
    # Slightly lighter variant for the gradient bottom
    bg_bottom = tuple(min(255, int(c * 1.35)) for c in bg_top)  # type: ignore[assignment]
    accent_rgb = hex_to_rgb(accent_color)

    img = Image.new("RGB", (width, height))
    draw_gradient(img, bg_top, bg_bottom)
    draw = ImageDraw.Draw(img)

    # --- Decorative accent bar (top) ---
    bar_h = 8
    draw.rectangle([(0, 0), (width, bar_h)], fill=accent_rgb)

    # --- Decorative accent bar (bottom) ---
    draw.rectangle([(0, height - bar_h), (width, height)], fill=accent_rgb)

    # --- Subtle grid lines for a technical feel ---
    grid_color = tuple(min(255, c + 18) for c in bg_top)  # type: ignore[assignment]
    for x in range(0, width, 80):
        draw.line([(x, bar_h), (x, height - bar_h)], fill=grid_color, width=1)
    for y in range(0, height, 80):
        draw.line([(0, y), (width, y)], fill=grid_color, width=1)

    # --- Diagonal accent shape (bottom-right) ---
    poly = [
        (width - 420, height - bar_h),
        (width, height // 2 + 20),
        (width, height - bar_h),
    ]
    accent_dim = tuple(max(0, c - 60) for c in accent_rgb)  # type: ignore[assignment]
    draw.polygon(poly, fill=accent_dim + (180,))  # type: ignore[operator]

    # --- Title ---
    title_font = get_font(72, bold=True)
    max_title_width = width - 160
    lines = wrap_text(title, title_font, max_title_width, draw)

    line_h = 90
    total_text_h = len(lines) * line_h
    # Center title vertically, shifted slightly upward
    start_y = (height - total_text_h) // 2 - 40

    # Shadow pass
    shadow_offset = 3
    for i, line in enumerate(lines):
        y = start_y + i * line_h
        draw.text((80 + shadow_offset, y + shadow_offset), line, font=title_font, fill=(0, 0, 0, 120))

    # Main title pass
    for i, line in enumerate(lines):
        y = start_y + i * line_h
        draw.text((80, y), line, font=title_font, fill=(255, 255, 255))

    # --- Technology pills ---
    if technologies:
        pill_font = get_font(26)
        pill_padding_x = 22
        pill_padding_y = 10
        pill_gap = 16
        pill_y_bottom = height - 60

        x_cursor = 80
        for tech in technologies:
            bbox = draw.textbbox((0, 0), tech, font=pill_font)
            tw = bbox[2] - bbox[0]
            th = bbox[3] - bbox[1]
            pill_w = tw + pill_padding_x * 2
            pill_h = th + pill_padding_y * 2
            pill_x0 = x_cursor
            pill_y0 = pill_y_bottom - pill_h
            pill_x1 = pill_x0 + pill_w
            pill_y1 = pill_y_bottom

            # Pill background
            draw.rounded_rectangle(
                [(pill_x0, pill_y0), (pill_x1, pill_y1)],
                radius=pill_h // 2,
                fill=accent_rgb,
            )
            # Pill text
            draw.text(
                (pill_x0 + pill_padding_x, pill_y0 + pill_padding_y),
                tech,
                font=pill_font,
                fill=(255, 255, 255),
            )
            x_cursor = pill_x1 + pill_gap

            # Stop if we'd overflow
            if x_cursor + 100 > width - 80:
                break

    # --- Save ---
    os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
    img.convert("RGB").save(output_path, "JPEG", quality=92, optimize=True)
    print(f"Cover saved → {output_path}")


# ---------------------------------------------------------------------------
# CLI entry-point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="Generate a blog post cover image with Pillow.")
    parser.add_argument("--title", required=True, help="Post title")
    parser.add_argument("--output", required=True, help="Output path, e.g. content/posts/slug/cover.jpg")
    parser.add_argument("--technologies", default="", help="Comma-separated technology list")
    parser.add_argument("--bg-color", default="#0a1628", help="Background hex color (default: #0a1628)")
    parser.add_argument("--accent-color", default="#00b4d8", help="Accent hex color (default: #00b4d8)")

    args = parser.parse_args()

    techs = [t.strip() for t in args.technologies.split(",") if t.strip()]

    generate_cover(
        title=args.title,
        output_path=args.output,
        technologies=techs,
        bg_color=args.bg_color,
        accent_color=args.accent_color,
    )


if __name__ == "__main__":
    main()
