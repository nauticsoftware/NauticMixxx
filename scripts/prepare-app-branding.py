#!/usr/bin/env python3
"""Embed the canonical NauticMixxx icon in Qt without third-party packages."""

from pathlib import Path
import struct
import sys


def prepare(source: Path, project: Path) -> None:
    icon = project / "branding/iCon-macOS-Dark-1024x1024@1x.png"
    data = icon.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n" or struct.unpack(">II", data[16:24]) != (1024, 1024):
        raise ValueError("The required NauticMixxx icon must be a 1024x1024 PNG")
    destination = source / "res/images/icons/nauticmixxx.png"
    destination.write_bytes(data)
    for relative, old, new in [
        ("src/defs_urls.h", ":/images/icons/scalable/apps/mixxx.svg", ":/images/icons/nauticmixxx.png"),
        ("res/mixxx.qrc", "<file>images/icons/scalable/apps/mixxx.svg</file>", "<file>images/icons/nauticmixxx.png</file>"),
    ]:
        path = source / relative
        text = path.read_text()
        if old not in text and new not in text:
            raise ValueError(f"Unsupported application icon definition: {relative}")
        path.write_text(text.replace(old, new))


if __name__ == "__main__":
    prepare(Path(sys.argv[1]), Path(sys.argv[2]))
