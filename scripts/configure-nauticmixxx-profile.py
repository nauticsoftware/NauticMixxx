#!/usr/bin/env python3
"""Install the NauticMixxx RX3 profile without replacing personal library data."""

from __future__ import annotations

import argparse
from collections import OrderedDict
from pathlib import Path
import plistlib
import shutil
import tempfile
import xml.etree.ElementTree as ET


PROFILE_RELATIVE = Path("Library/Application Support/NauticMixxx")
CONTROLLER_FILES = (
    "Hercules_DJControl_Inpulse_500_RX3.midi.xml",
    "Hercules-DJControl-Inpulse-500-RX3-script.js",
    "midi-components-0.0.js",
)
EFFECT_CHAIN_FILES = (
    "RX3 REVERB.xml",
    "RX3 PING PONG.xml",
    "RX3 NOISE.xml",
    "RX3 FILTER.xml",
)
LEGACY_EFFECT_CHAIN_FILES = ("RX3 SPACE.xml", "RX3 DUB ECHO.xml")
QUICK_EFFECT_PRESETS = (
    "RX3 REVERB",
    "RX3 PING PONG",
    "RX3 NOISE",
    "RX3 FILTER",
)
LEGACY_QUICK_EFFECT_PRESETS = ("RX3 SPACE", "RX3 DUB ECHO")
MANAGED_SECTIONS = (
    "Config",
    "Controls",
    "Pioneered",
    "Skin",
    "Waveform",
    "BPM",
    "Library",
    "Key",
    "Effects",
    "QuickEffectRack1_[Channel1]",
    "QuickEffectRack1_[Channel2]",
)


def default_profile_dir() -> Path:
    container = Path.home() / "Library/Containers/org.mixxx.mixxx/Data"
    return container / PROFILE_RELATIVE


def parse_settings(text: str) -> OrderedDict[str, OrderedDict[str, str]]:
    settings: OrderedDict[str, OrderedDict[str, str]] = OrderedDict()
    section = ""
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            settings.setdefault(section, OrderedDict())
        elif line and not line.startswith(("#", ";")) and section:
            parts = line.split(None, 1)
            if len(parts) == 2:
                settings[section][parts[0]] = parts[1]
    return settings


def merge_settings(text: str, updates: OrderedDict[str, OrderedDict[str, str]]) -> str:
    output: list[str] = []
    seen_sections: set[str] = set()
    seen_keys: dict[str, set[str]] = {section: set() for section in updates}
    section = ""

    def append_missing(current_section: str) -> None:
        if current_section not in updates:
            return
        for key, value in updates[current_section].items():
            if key not in seen_keys[current_section]:
                output.append(f"{key} {value}")
                seen_keys[current_section].add(key)

    for raw_line in text.splitlines():
        stripped = raw_line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            append_missing(section)
            section = stripped[1:-1]
            seen_sections.add(section)
            output.append(raw_line)
            continue

        if section in updates and stripped and not stripped.startswith(("#", ";")):
            key = stripped.split(None, 1)[0]
            if key in updates[section]:
                if key not in seen_keys[section]:
                    output.append(f"{key} {updates[section][key]}")
                    seen_keys[section].add(key)
                continue
        output.append(raw_line)

    append_missing(section)
    for missing_section, values in updates.items():
        if missing_section in seen_sections:
            continue
        if output and output[-1] != "":
            output.append("")
        output.append(f"[{missing_section}]")
        output.extend(f"{key} {value}" for key, value in values.items())
    return "\n".join(output).rstrip() + "\n"


def validate_app(app: Path) -> tuple[Path, Path]:
    plist_path = app / "Contents/Info.plist"
    resources = app / "Contents/Resources"
    if not plist_path.is_file():
        raise ValueError(f"No es una aplicación válida: {app}")
    with plist_path.open("rb") as handle:
        bundle_id = plistlib.load(handle).get("CFBundleIdentifier")
    if bundle_id != "org.mixxx.mixxx":
        raise ValueError(f"Bundle inesperado ({bundle_id!r}): {app}")
    template = resources / "profiles/XDJ_RX3_Mixxx.profile.cfg"
    if not template.is_file():
        raise ValueError(f"Falta el perfil RX3 dentro de la app: {template}")
    for filename in CONTROLLER_FILES:
        if not (resources / "controllers" / filename).is_file():
            raise ValueError(f"Falta el archivo del controlador: {filename}")
    for filename in EFFECT_CHAIN_FILES:
        if not (resources / "effects/chains" / filename).is_file():
            raise ValueError(f"Falta la cadena de efectos: {filename}")
    return resources, template


def configure_quick_effect_order(profile_dir: Path) -> None:
    effects_path = profile_dir / "effects.xml"
    if effects_path.is_file():
        current = effects_path.read_bytes()
        root = ET.fromstring(current)
    else:
        current = b""
        root = ET.Element("Effects")

    preset_list = root.find("QuickEffectPresetList")
    if preset_list is None:
        preset_list = ET.SubElement(root, "QuickEffectPresetList")

    managed = set(QUICK_EFFECT_PRESETS + LEGACY_QUICK_EFFECT_PRESETS)
    for child in list(preset_list):
        if child.tag == "ChainPresetName" and (child.text or "").strip() in managed:
            preset_list.remove(child)

    for name in reversed(QUICK_EFFECT_PRESETS):
        node = ET.Element("ChainPresetName")
        node.text = name
        preset_list.insert(0, node)

    ET.indent(root, space=" ")
    updated = ET.tostring(root, encoding="utf-8", xml_declaration=True) + b"\n"
    if updated == current:
        return
    if current:
        shutil.copy2(effects_path, profile_dir / "effects.xml.previous")
    with tempfile.NamedTemporaryFile(
        "wb", dir=profile_dir, prefix="effects.xml.", delete=False
    ) as handle:
        handle.write(updated)
        temporary = Path(handle.name)
    temporary.chmod(0o600)
    temporary.replace(effects_path)


def configure(app: Path, profile_dir: Path, dry_run: bool = False) -> list[str]:
    resources, template_path = validate_app(app)
    template = parse_settings(template_path.read_text(encoding="utf-8"))
    updates: OrderedDict[str, OrderedDict[str, str]] = OrderedDict(
        (section, template[section]) for section in MANAGED_SECTIONS
    )

    controllers_dir = profile_dir / "controllers"
    effects_chain_dir = profile_dir / "effects/chains"
    mapping_path = controllers_dir / CONTROLLER_FILES[0]
    updates["ControllerPreset"] = OrderedDict(
        (("DJControl_Inpulse_500", str(mapping_path.resolve())),)
    )
    updates["Controller"] = OrderedDict((("DJControl_Inpulse_500", "1"),))

    config_path = profile_dir / "mixxx.cfg"
    current = config_path.read_text(encoding="utf-8") if config_path.is_file() else ""
    merged = merge_settings(current, updates)
    changes = [
        "perfil RX3 actualizado",
        "mapping Inpulse 500 instalado y asignado",
        "cadenas Sound Color FX instaladas",
        "FX1–FX4 ordenados como Reverb, Ping Pong, Noise y Filter",
        "playhead ubicado al 25 % desde la izquierda",
        "biblioteca local bloqueada; navegación limitada a USB Rekordbox",
    ]
    if dry_run:
        return changes

    profile_dir.mkdir(parents=True, exist_ok=True)
    controllers_dir.mkdir(parents=True, exist_ok=True)
    effects_chain_dir.mkdir(parents=True, exist_ok=True)
    if config_path.is_file() and current != merged:
        shutil.copy2(config_path, profile_dir / "mixxx.cfg.previous")
    for filename in CONTROLLER_FILES:
        shutil.copy2(resources / "controllers" / filename, controllers_dir / filename)
    for filename in EFFECT_CHAIN_FILES:
        shutil.copy2(resources / "effects/chains" / filename, effects_chain_dir / filename)
    for filename in LEGACY_EFFECT_CHAIN_FILES:
        legacy_path = effects_chain_dir / filename
        if legacy_path.is_file():
            shutil.copy2(legacy_path, legacy_path.with_suffix(".xml.previous"))
            legacy_path.unlink()

    configure_quick_effect_order(profile_dir)

    if current != merged:
        with tempfile.NamedTemporaryFile(
            "w", encoding="utf-8", dir=profile_dir, prefix="mixxx.cfg.", delete=False
        ) as handle:
            handle.write(merged)
            temporary = Path(handle.name)
        temporary.chmod(0o600)
        temporary.replace(config_path)
    return changes


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Configura NauticMixxx como un sistema de dos decks tipo XDJ-RX3."
    )
    parser.add_argument("--app", type=Path, required=True)
    parser.add_argument("--profile-dir", type=Path, default=default_profile_dir())
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    changes = configure(args.app.resolve(), args.profile_dir.resolve(), args.dry_run)
    prefix = "Se aplicarían" if args.dry_run else "Aplicados"
    print(f"{prefix}: " + "; ".join(changes) + ".")
    print(f"Perfil: {args.profile_dir.resolve()}")


if __name__ == "__main__":
    main()
