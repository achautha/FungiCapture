"""Create redistributable synthetic plates for installer checks and onboarding."""
import argparse
from pathlib import Path

import numpy as np
from PIL import Image


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    plates = args.destination / "plates"
    plates.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(20261120)
    yy, xx = np.mgrid[:480, :720]
    for plate in range(3):
        rgb = np.full((480, 720, 3), (224, 213, 187), dtype=np.uint8)
        for row in range(2):
            for col in range(3):
                n = plate * 6 + row * 3 + col
                cx, cy = 120 + col * 240, 120 + row * 240
                mask = ((xx - cx) / (35 + n)) ** 2 + ((yy - cy) / (30 + n % 7)) ** 2 <= 1
                texture = rng.integers(-6, 7, (int(mask.sum()), 1))
                colour = np.array([60 + n * 3, 70 + n, 45 + n * 2])
                rgb[mask] = np.clip(colour + texture, 0, 255)
        Image.fromarray(rgb).save(plates / f"SYNTHETIC{plate + 1:02d}.png")
    (args.destination / "README.txt").write_text(
        "SYNTHETIC DATA - not biological observations.\n"
        "Three generated plates, 2 rows x 3 columns each: 18 colonies total.\n"
        "Use plate_batch mode and the classical backend.\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
