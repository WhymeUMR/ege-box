"""Generate launcher icon variants from assets/logo.png.

Outputs (all 1024x1024):
  assets/icon_light.png       - logo on white background (default / iOS light)
  assets/icon_dark.png        - logo on black background (Android dark fallback)
  assets/icon_ios_dark.png    - logo on transparent (iOS dark mode adds black)
  assets/icon_monochrome.png  - white silhouette on transparent (Android themed)
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

    compose((255, 255, 255, 255), fitted).save(ROOT / "assets/icon_light.png")
    compose((0, 0, 0, 255), fitted).save(ROOT / "assets/icon_dark.png")
    compose((0, 0, 0, 0), fitted).save(ROOT / "assets/icon_ios_dark.png")

    # Monochrome: white silhouette from alpha channel
    alpha = fitted.split()[-1]
    mono_logo = Image.merge("RGBA", (
        Image.new("L", fitted.size, 255),
        Image.new("L", fitted.size, 255),
        Image.new("L", fitted.size, 255),
        alpha,
    ))
    compose((0, 0, 0, 0), mono_logo).save(ROOT / "assets/icon_monochrome.png")

    print("ok")


if __name__ == "__main__":
    main()
