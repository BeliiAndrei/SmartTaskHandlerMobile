"""Export the project icon to Android mipmaps and a Windows ICO.

Run from any directory with: python tool/generate_app_icons.py
Requires Pillow. The source artwork is assets/icons/smart_task_handler.png.
"""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "icons" / "smart_task_handler.png"
RESOURCES = ROOT / "android" / "app" / "src" / "main" / "res"
SIZES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}


def main() -> None:
    with Image.open(SOURCE) as original:
        icon = original.convert("RGBA")
        if icon.width != icon.height:
            raise ValueError("Launcher artwork must be square")

        for density, size in SIZES.items():
            target = RESOURCES / f"mipmap-{density}" / "ic_launcher.png"
            icon.resize((size, size), Image.Resampling.LANCZOS).save(target)

        icon.save(
            ROOT / "assets" / "icons" / "smart_task_handler.ico",
            format="ICO",
            sizes=[(size, size) for size in (16, 32, 48, 64, 128, 256)],
        )


if __name__ == "__main__":
    main()
