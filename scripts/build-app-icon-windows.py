#!/usr/bin/env python3
"""Build the Windows ICO from the canonical user-provided NauticMixxx icon."""

import argparse
import hashlib
from pathlib import Path
import struct

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "packaging/DMG_PROJECT/iCon-macOS-Dark-1024x1024@1x.png"
SOURCE_SHA256 = "ac61e30ddad3b9a05b1972906855863a0e4d0e2e1130c6cb88a998925f45a44f"
SIZES = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    if hashlib.sha256(SOURCE.read_bytes()).hexdigest() != SOURCE_SHA256:
        raise SystemExit("The canonical NauticMixxx icon is missing or was changed")
    with Image.open(SOURCE) as image:
        if image.size != (1024, 1024):
            raise SystemExit("The canonical NauticMixxx icon must be 1024x1024")
        icon = image.convert("RGBA")
        args.output.parent.mkdir(parents=True, exist_ok=True)
        icon.save(args.output, format="ICO", sizes=SIZES, bitmap_format="png")

    data = args.output.read_bytes()
    reserved, kind, count = struct.unpack_from("<HHH", data)
    if (reserved != 0 or kind != 1 or count < len(SIZES)):
        raise SystemExit("The generated Windows icon is incomplete")
    print(f"NauticMixxx Windows icon: {args.output}")


if __name__ == "__main__":
    main()
