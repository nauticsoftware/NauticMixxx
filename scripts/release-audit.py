#!/usr/bin/env python3
"""Fail when public NauticMixxx inputs or artifacts contain unsafe local data."""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
APP_ROOT = ROOT.parent
VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
PUBLIC_INPUTS = [
    ROOT / "README.md",
    ROOT / "LICENSE.md",
    ROOT / "THIRD_PARTY_NOTICES.md",
    ROOT / "TRADEMARKS.md",
    ROOT / "CHANGELOG.md",
    ROOT / "CONTRIBUTING.md",
    ROOT / "SECURITY.md",
    ROOT / "RELEASE_NOTES.md",
    ROOT / "docs",
    ROOT / "scripts",
    ROOT / "patches",
    ROOT / "skins/XDJ_RX3_Mixxx",
    ROOT / "controllers/Hercules_DJControl_Inpulse_500_RX3",
    ROOT / "effects",
    ROOT / "packaging/DMG_PROJECT/iCon-macOS-Dark-1024x1024@1x.png",
    ROOT / "packaging/DMG_PROJECT/DMG_BG.jpg",
    ROOT / "packaging/macos",
    ROOT / "packaging/windows",
]
BLOCKED_NAMES = {".DS_Store", "mixxxdb.sqlite", "mixxx.cfg", "effects.xml", "compile_flags.txt"}
BLOCKED_SUFFIXES = {".p12", ".mobileprovision", ".provisionprofile", ".key"}
PRIVATE_PATTERNS = [
    re.compile(rb"/Users/[A-Za-z0-9._-]+/"),
    re.compile(rb"BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY"),
    re.compile(rb"gh[pousr]_[A-Za-z0-9_]{20,}"),
]


def files_under(paths: list[Path]):
    for base in paths:
        if base.is_file():
            yield base
        elif base.is_dir():
            yield from (
                path
                for path in base.rglob("*")
                if path.is_file() and path.name != ".DS_Store" and "__pycache__" not in path.parts
            )


def audit(paths: list[Path]) -> list[str]:
    errors: list[str] = []
    for path in files_under(paths):
        if path.name in BLOCKED_NAMES or path.suffix.lower() in BLOCKED_SUFFIXES:
            errors.append(f"archivo privado/bloqueado: {path}")
            continue
        if path.stat().st_size > 750 * 1024 * 1024:
            errors.append(f"archivo mayor a 750 MB: {path}")
            continue
        if path.stat().st_size > 20 * 1024 * 1024:
            continue
        try:
            data = path.read_bytes()
        except OSError as error:
            errors.append(f"no se pudo leer {path}: {error}")
            continue
        for pattern in PRIVATE_PATTERNS:
            if pattern.search(data):
                errors.append(f"dato privado ({pattern.pattern!r}): {path}")
    return errors


def validate_metadata() -> list[str]:
    errors: list[str] = []
    skin = ET.parse(ROOT / "skins/XDJ_RX3_Mixxx/skin.xml")
    if skin.findtext("manifest/title") != "NauticMixxx":
        errors.append("el título de la skin no es NauticMixxx")
    if skin.findtext("manifest/version") != VERSION:
        errors.append("la versión de la skin no coincide con VERSION")
    if len(list((ROOT / "patches").glob("00[0-9][0-9]-*.patch"))) != 10:
        errors.append("deben existir exactamente diez parches numerados")
    required = [
        ROOT / "branding/iCon.icon/icon.json",
        ROOT / "branding/NauticMixxx.png",
        ROOT / "skins/XDJ_RX3_Mixxx/LICENSE",
    ]
    # The monorepo keeps Mixxx's license one level above `nautic/`; the
    # standalone public repository does not. Only require it when the parent
    # is recognizably the complete Mixxx source tree.
    native_license = APP_ROOT / "LICENSE"
    if (APP_ROOT / "src").is_dir():
        required.append(native_license)
    errors.extend(f"falta: {path}" for path in required if not path.is_file())
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path)
    args = parser.parse_args()
    paths = [path.resolve() for path in args.paths] if args.paths else PUBLIC_INPUTS
    errors = validate_metadata() + audit(paths)
    if errors:
        print("AUDITORÍA FALLIDA", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(f"Auditoría pública NauticMixxx {VERSION}: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
