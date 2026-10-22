"""Generate the app icon (§6): a 3x3 grid of rounded squares, five filled in the Day and
Night colours, four empty, on a near-black background. 1024x1024 RGB PNG, no alpha.

    uv run --with pillow scripts/make_icon.py
"""
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 1024
BACKGROUND = (17, 17, 17)        # near-black
EMPTY = (38, 38, 38)             # empty cell, just visible against the background
DAY = (0xFF, 0xA9, 0x4D)         # #FFA94D
NIGHT = (0x4C, 0x6E, 0xF5)       # #4C6EF5

CELL = 232
GAP = 44
RADIUS = 56
MARGIN = (SIZE - 3 * CELL - 2 * GAP) // 2

# Reads like a 2D 2N rota: Day Day Night / Night . . / . Day .
GRID = [
    [DAY, DAY, NIGHT],
    [NIGHT, None, None],
    [None, DAY, None],
]

out = Path(__file__).resolve().parents[1] / "Rota" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon.png"
out.parent.mkdir(parents=True, exist_ok=True)

image = Image.new("RGB", (SIZE, SIZE), BACKGROUND)
draw = ImageDraw.Draw(image)
for row, colours in enumerate(GRID):
    for col, colour in enumerate(colours):
        x = MARGIN + col * (CELL + GAP)
        y = MARGIN + row * (CELL + GAP)
        draw.rounded_rectangle((x, y, x + CELL, y + CELL), radius=RADIUS, fill=colour or EMPTY)

image.save(out, format="PNG", optimize=True)
print(f"wrote {out} ({image.size[0]}x{image.size[1]}, mode {image.mode})")
