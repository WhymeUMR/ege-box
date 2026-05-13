"""Generate the launcher icon from assets/logo.png.

Output:
  assets/icon.png  - 1024x1024, logo on Off White (#F2F2F2) background.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "logo.png"
SIZE = 1024
PADDING = 0.15  # 15% safe-area padding


def fit(logo: Image.Image, size: int, pad: float) -> Image.Image:
    inner = int(size * (1 - 2 * pad))
    w, h = logo.size
    scale = min(inner / w, inner / h)
    new_size = (max(1, int(w * scale)), max(1, int(h * scale)))
    return logo.resize(new_size, Image.LANCZOS)


def compose(bg, logo_resized: Image.Image) -> Image.Image:
    canvas = Image.new("RGBA", (SIZE, SIZE), bg)
    x = (SIZE - logo_resized.width) // 2
    y = (SIZE - logo_resized.height) // 2
    canvas.paste(logo_resized, (x, y), logo_resized)
    return canvas


def main() -> None:
    logo = Image.open(SRC).convert("RGBA")
    fitted = fit(logo, SIZE, PADDING)

    # Off White background per palette (#F2F2F2)
    compose((0xF2, 0xF2, 0xF2, 255), fitted).save(ROOT / "assets/icon.png")

    print("ok")


if __name__ == "__main__":
    main()
