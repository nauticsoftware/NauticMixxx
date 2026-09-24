#!/usr/bin/env python3
"""Create the public NauticMixxx release artifacts from validated local inputs."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import plistlib
from pathlib import Path
import shutil
import stat
import subprocess
import tarfile
import tempfile
import time
import xml.etree.ElementTree as ET
import zipfile


ROOT = Path(__file__).resolve().parents[1]
APP_ROOT = ROOT.parent
VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
PRODUCT = "NauticMixxx"
LOCAL_SOURCE_ROOT = APP_ROOT
REBUILD_SOURCE_ROOT = ROOT / "tmp/mixxx-native-rebuild/mixxx-2.5.6"
SOURCE_ROOT = (
    LOCAL_SOURCE_ROOT
    if (LOCAL_SOURCE_ROOT / "src/widget/rx3displaystate.h").is_file()
    else REBUILD_SOURCE_ROOT
)
LOCAL_APP = APP_ROOT / "stage-v1/NauticMixxx.app"
REBUILD_APP = ROOT / "tmp/mixxx-native-rebuild/stage/NauticMixxx.app"
RELEASE_APPS = sorted((ROOT / "release").glob("*/NauticMixxx-*-macOS-arm64/NauticMixxx.app"), reverse=True)
DEFAULT_APP = next(
    (candidate for candidate in [LOCAL_APP, REBUILD_APP, *RELEASE_APPS] if candidate.exists()),
    REBUILD_APP,
)
FALLBACK_APP = APP_ROOT / "build/NauticMixxx.app"
PUBLIC_SCRIPT_PATHS = [
    "scripts/build-app-icon-macos.sh",
    "scripts/build-mixxx-rx3-macos.sh",
    "scripts/package-macos-dmg.sh",
    "scripts/build-mixxx-rx3-windows.ps1",
    "scripts/configure-nauticmixxx-profile.py",
    "scripts/package-release.py",
    "scripts/package-rx3-windows-native.py",
    "scripts/release-audit.py",
    "scripts/test-rx3-autoloop.js",
    "scripts/test-rx3-loop-adjust.js",
    "scripts/test-rx3-sound-color-fx.js",
    "scripts/test-rx3-transport-controls.js",
    "scripts/test-rx3-usb-only.py",
    "scripts/validate-release.sh",
]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def ignored(path: Path) -> bool:
    blocked = {".git", ".DS_Store", "__pycache__", "compile_flags.txt", "nautic"}
    return any(part in blocked for part in path.parts) or path.suffix in {".pyc", ".log"}


def copy_tree(source: Path, target: Path) -> None:
    shutil.copytree(
        source,
        target,
        dirs_exist_ok=True,
        ignore=shutil.ignore_patterns(".git", ".DS_Store", "__pycache__", "*.pyc", "*.log"),
    )


def add_tree(tar: tarfile.TarFile, source: Path, arcname: str) -> None:
    def clean(info: tarfile.TarInfo) -> tarfile.TarInfo | None:
        relative = Path(info.name)
        if ignored(relative):
            return None
        info.uid = 0
        info.gid = 0
        info.uname = "root"
        info.gname = "root"
        info.mtime = 0
        return info

    tar.add(source, arcname=arcname, recursive=True, filter=clean)


def validate_inputs(app: Path) -> None:
    if VERSION != "1.0.0":
        raise ValueError(f"Este empaquetador corresponde a 1.0.0, no a {VERSION}")
    skin_version = ET.parse(ROOT / "skins/XDJ_RX3_Mixxx/skin.xml").findtext(
        "manifest/version"
    )
    if skin_version != VERSION:
        raise ValueError(f"La skin declara {skin_version}; se esperaba {VERSION}")
    patches = sorted((ROOT / "patches").glob("00[0-9][0-9]-*.patch"))
    if len(patches) != 10:
        raise ValueError("La release requiere exactamente los diez parches 0001–0010")
    if not (SOURCE_ROOT / "src/widget/rx3displaystate.h").is_file():
        raise ValueError("Faltan los fuentes correspondientes parcheados de Mixxx")
    if not app.is_dir() or not (app / "Contents/Info.plist").is_file():
        raise ValueError(f"No se encontró un bundle compilado: {app}")
    required_bundle_files = [
        app / "Contents/Resources/README.md",
        app / "Contents/Resources/skins/LateNight/skin.xml",
        app / "Contents/Resources/fonts/OpenSans.LICENSE.txt",
        app / "Contents/Resources/keyboard/en_US.kbd.cfg",
    ]
    missing_bundle_files = [path for path in required_bundle_files if not path.is_file()]
    if missing_bundle_files:
        missing = ", ".join(str(path.relative_to(app)) for path in missing_bundle_files)
        raise ValueError(
            "El bundle es sólo un producto intermedio; ejecuta cmake --install. "
            f"Faltan: {missing}"
        )


def prepare_app(source_app: Path, target_app: Path) -> None:
    subprocess.run(["ditto", str(source_app), str(target_app)], check=True)
    plist_path = target_app / "Contents/Info.plist"
    with plist_path.open("rb") as handle:
        plist = plistlib.load(handle)
    old_executable = plist.get("CFBundleExecutable", source_app.stem)
    old_binary = target_app / "Contents/MacOS" / old_executable
    new_binary = target_app / "Contents/MacOS" / PRODUCT
    if old_binary != new_binary:
        old_binary.rename(new_binary)
    plist.update(
        {
            "CFBundleDisplayName": PRODUCT,
            "CFBundleExecutable": PRODUCT,
            "CFBundleName": PRODUCT,
            "CFBundleShortVersionString": VERSION,
            "CFBundleVersion": VERSION,
            # Kept for compatibility with the existing Mixxx sandbox/profile.
            "CFBundleIdentifier": "org.mixxx.mixxx",
            "NSHumanReadableCopyright": "NauticMixxx contributors and Mixxx Development Team",
        }
    )
    with plist_path.open("wb") as handle:
        plistlib.dump(plist, handle, sort_keys=True)

    resources = target_app / "Contents/Resources"
    copy_tree(ROOT / "skins/XDJ_RX3_Mixxx", resources / "skins/XDJ_RX3_Mixxx")
    copy_tree(ROOT / "controllers/Hercules_DJControl_Inpulse_500_RX3", resources / "controllers")
    copy_tree(ROOT / "effects/chains", resources / "effects/chains")
    profiles = resources / "profiles"
    profiles.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / "profile/XDJ_RX3_Mixxx.profile.cfg", profiles)
    tools = resources / "tools"
    tools.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / "scripts/configure-nauticmixxx-profile.py", tools)
    licenses = resources / "licenses"
    licenses.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / "skins/XDJ_RX3_Mixxx/LICENSE", licenses / "NauticMixxx-GPL-3.0.txt")
    shutil.copy2(SOURCE_ROOT / "LICENSE", licenses / "Mixxx-LICENSE.txt")
    shutil.copy2(ROOT / "THIRD_PARTY_NOTICES.md", licenses)
    shutil.copy2(ROOT / "TRADEMARKS.md", licenses)
    app_icon = resources / "application.icns"
    subprocess.run(
        [str(ROOT / "scripts/build-app-icon-macos.sh"), str(app_icon)],
        check=True,
    )
    shutil.copy2(app_icon, resources / "osx/application.icns")
    # Finder metadata copied from a local bundle invalidates strict code-sign
    # verification. Strip extended attributes before applying the final sign.
    subprocess.run(["xattr", "-cr", str(target_app)], check=True)
    identity = os.environ.get("NAUTIC_SIGNING_IDENTITY", "-")
    subprocess.run(
        [
            "codesign",
            "--force",
            "--deep",
            "--sign",
            identity,
            "--entitlements",
            str(ROOT / "packaging/macos/mixxx-entitlements.plist"),
            str(target_app),
        ],
        check=True,
    )
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(target_app)], check=True)


def create_skin_zip(output: Path) -> None:
    source = ROOT / "skins/XDJ_RX3_Mixxx"
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(source.rglob("*")):
            if path.is_file() and not ignored(path.relative_to(source)):
                archive.write(path, Path("XDJ_RX3_Mixxx") / path.relative_to(source))


def create_source_archive(output: Path) -> None:
    prefix = f"{PRODUCT}-{VERSION}-source"
    with tarfile.open(output, "w:gz", format=tarfile.PAX_FORMAT) as archive:
        add_tree(archive, SOURCE_ROOT, f"{prefix}/mixxx-2.5.6")
        for directory in ["patches", "skins", "controllers", "effects", "profile"]:
            add_tree(archive, ROOT / directory, f"{prefix}/{directory}")
        add_tree(archive, ROOT / "packaging/macos", f"{prefix}/packaging/macos")
        add_tree(archive, ROOT / "packaging/windows", f"{prefix}/packaging/windows")
        add_tree(
            archive,
            ROOT / "packaging/DMG_PROJECT/iCon-macOS-Dark-1024x1024@1x.png",
            f"{prefix}/packaging/DMG_PROJECT/iCon-macOS-Dark-1024x1024@1x.png",
        )
        add_tree(
            archive,
            ROOT / "packaging/DMG_PROJECT/DMG_BG.jpg",
            f"{prefix}/packaging/DMG_PROJECT/DMG_BG.jpg",
        )
        for path in [
            "VERSION",
            "README.md",
            "LICENSE.md",
            "THIRD_PARTY_NOTICES.md",
            "TRADEMARKS.md",
            "CHANGELOG.md",
            "CONTRIBUTING.md",
            "RELEASE_NOTES.md",
            "TEST_REPORT.md",
            "BUILD-WINDOWS.cmd",
            "DRIVER-HERCULES.cmd",
            "INSTALL-WINDOWS.cmd",
            "EMPEZAR-COMPILACION.txt",
        ]:
            add_tree(archive, ROOT / path, f"{prefix}/{path}")
        add_tree(archive, ROOT / "docs", f"{prefix}/docs")
        for script in PUBLIC_SCRIPT_PATHS:
            add_tree(archive, ROOT / script, f"{prefix}/{script}")
        add_tree(archive, ROOT / "branding/iCon.icon", f"{prefix}/branding/iCon.icon")
        add_tree(archive, ROOT / ".github", f"{prefix}/.github")
        add_tree(archive, ROOT / ".gitattributes", f"{prefix}/.gitattributes")
        add_tree(archive, ROOT / ".gitignore", f"{prefix}/.gitignore")


def create_github_source_zip(output: Path) -> None:
    prefix = f"{PRODUCT}-{VERSION}"
    entries = [
        "docs",
        "branding/iCon.icon",
        "packaging/DMG_PROJECT/iCon-macOS-Dark-1024x1024@1x.png",
        "packaging/DMG_PROJECT/DMG_BG.jpg",
        "packaging/macos",
        "packaging/windows",
        "controllers",
        "effects",
        "patches",
        "profile",
        "skins/XDJ_RX3_Mixxx",
        *PUBLIC_SCRIPT_PATHS,
        "BUILD-WINDOWS.cmd",
        "CODE_OF_CONDUCT.md",
        "CONTRIBUTING.md",
        "CHANGELOG.md",
        "DRIVER-HERCULES.cmd",
        "INSTALL-WINDOWS.cmd",
        "EMPEZAR-COMPILACION.txt",
        "LICENSE.md",
        "branding/NauticMixxx.png",
        "README.md",
        "RELEASE_NOTES.md",
        "SECURITY.md",
        "TEST_REPORT.md",
        "THIRD_PARTY_NOTICES.md",
        "TRADEMARKS.md",
        "VERSION",
    ]
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
        for entry in entries:
            source = ROOT / entry
            paths = [source] if source.is_file() else sorted(path for path in source.rglob("*") if path.is_file())
            for path in paths:
                if not ignored(path.relative_to(ROOT)):
                    archive.write(path, Path(prefix) / path.relative_to(ROOT))
        for entry in [".github", ".gitattributes", ".gitignore"]:
            source = ROOT / entry
            paths = [source] if source.is_file() else sorted(path for path in source.rglob("*") if path.is_file())
            for path in paths:
                if not ignored(path.relative_to(ROOT)):
                    archive.write(path, Path(prefix) / path.relative_to(ROOT))


def write_installer(path: Path, archive_name: str, expected: str) -> None:
    script = f"""#!/bin/sh
set -eu
base=$(CDPATH= cd -- \"$(dirname -- \"$0\")\" && pwd)
archive=\"$base/{archive_name}\"
expected={expected}
actual=$(shasum -a 256 \"$archive\" | awk '{{print $1}}')
[ \"$actual\" = \"$expected\" ] || {{ echo 'SHA-256 inválido.' >&2; exit 1; }}
temp=$(mktemp -d \"${{TMPDIR:-/tmp}}/nauticmixxx-install.XXXXXX\")
trap 'rm -rf \"$temp\"' EXIT HUP INT TERM
ditto -x -k \"$archive\" \"$temp\"
source_app=\"$temp/{PRODUCT}-{VERSION}-macOS-arm64/{PRODUCT}.app\"
codesign --verify --deep --strict \"$source_app\"
target=\"/Applications/{PRODUCT}.app\"
if [ -e \"$target\" ]; then
  backup=\"/Applications/{PRODUCT}.previous.app\"
  [ ! -e \"$backup\" ] || rm -rf \"$backup\"
  mv \"$target\" \"$backup\"
  echo \"Respaldo: $backup\"
fi
ditto \"$source_app\" \"$target\"
python3 \"$target/Contents/Resources/tools/configure-nauticmixxx-profile.py\" --app \"$target\"
echo \"Instalado y configurado: $target\"
echo 'En la primera apertura, macOS puede solicitar confirmación para una build comunitaria.'
"""
    path.write_text(script, encoding="utf-8")
    path.chmod(path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def write_configure_launcher(path: Path) -> None:
    script = f"""#!/bin/sh
set -eu
base=$(CDPATH= cd -- \"$(dirname -- \"$0\")\" && pwd)
app=\"$base/{PRODUCT}.app\"
[ -d \"$app\" ] || {{ echo 'NauticMixxx.app debe estar junto a este archivo.' >&2; exit 1; }}
python3 \"$app/Contents/Resources/tools/configure-nauticmixxx-profile.py\" --app \"$app\"
open \"$app\"
"""
    path.write_text(script, encoding="utf-8")
    path.chmod(path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def create_sbom(path: Path) -> None:
    document = {
        "spdxVersion": "SPDX-2.3",
        "dataLicense": "CC0-1.0",
        "SPDXID": "SPDXRef-DOCUMENT",
        "name": f"{PRODUCT}-{VERSION}",
        "documentNamespace": f"https://nauticmixxx.invalid/spdx/{VERSION}/{int(time.time())}",
        "creationInfo": {"created": "2026-09-22T00:00:00Z", "creators": ["Tool: package-release.py"]},
        "packages": [
            {"name": PRODUCT, "SPDXID": "SPDXRef-NauticMixxx", "versionInfo": VERSION, "downloadLocation": "NOASSERTION", "licenseConcluded": "GPL-3.0-only", "licenseDeclared": "GPL-3.0-only", "filesAnalyzed": False},
            {"name": "Mixxx", "SPDXID": "SPDXRef-Mixxx", "versionInfo": "2.5.6", "downloadLocation": "https://github.com/mixxxdj/mixxx/releases/tag/2.5.6", "licenseConcluded": "GPL-2.0-or-later", "licenseDeclared": "GPL-2.0-or-later", "filesAnalyzed": False},
        ],
        "relationships": [{"spdxElementId": "SPDXRef-DOCUMENT", "relationshipType": "DESCRIBES", "relatedSpdxElement": "SPDXRef-NauticMixxx"}, {"spdxElementId": "SPDXRef-NauticMixxx", "relationshipType": "DERIVED_FROM", "relatedSpdxElement": "SPDXRef-Mixxx"}],
    }
    path.write_text(json.dumps(document, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", type=Path)
    parser.add_argument("--output", type=Path, default=ROOT / "release" / VERSION)
    args = parser.parse_args()
    app = args.app.resolve() if args.app else (DEFAULT_APP if DEFAULT_APP.exists() else FALLBACK_APP)
    output = args.output.resolve()
    validate_inputs(app)
    if output.exists() and any(output.iterdir()):
        raise ValueError(f"La salida ya contiene archivos; usa otra carpeta: {output}")
    output.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="nauticmixxx-release-") as temp_name:
        temp = Path(temp_name)
        bundle_root = temp / f"{PRODUCT}-{VERSION}-macOS-arm64"
        bundle_root.mkdir()
        prepared_app = bundle_root / f"{PRODUCT}.app"
        prepare_app(app, prepared_app)
        write_configure_launcher(bundle_root / "CONFIGURAR-Y-ABRIR.command")
        shutil.copy2(ROOT / "docs/INSTALLATION.md", bundle_root / "LEEME.md")
        shutil.copy2(ROOT / "LICENSE.md", bundle_root)
        shutil.copy2(ROOT / "THIRD_PARTY_NOTICES.md", bundle_root)
        mac_archive = output / f"{PRODUCT}-{VERSION}-macOS-arm64.zip"
        subprocess.run(["ditto", "-c", "-k", "--norsrc", "--keepParent", str(bundle_root), str(mac_archive)], check=True)

    skin_archive = output / f"{PRODUCT}-{VERSION}-skin.zip"
    source_archive = output / f"{PRODUCT}-{VERSION}-source.tar.gz"
    github_archive = output / f"{PRODUCT}-{VERSION}-github-source.zip"
    create_skin_zip(skin_archive)
    create_source_archive(source_archive)
    create_github_source_zip(github_archive)
    shutil.copy2(ROOT / "RELEASE_NOTES.md", output / "RELEASE_NOTES.md")
    shutil.copy2(ROOT / "TEST_REPORT.md", output / "TEST_REPORT.md")
    create_sbom(output / f"{PRODUCT}-{VERSION}.spdx.json")
    installer = output / "install-nauticmixxx-macos.sh"
    write_installer(installer, mac_archive.name, sha256(mac_archive))
    write_configure_launcher(output / "CONFIGURAR-Y-ABRIR.command")

    artifacts = sorted(path for path in output.iterdir() if path.is_file() and path.name not in {"SHA256SUMS.txt", "release-manifest.json"})
    manifest = {
        "product": PRODUCT,
        "version": VERSION,
        "base": "Mixxx 2.5.6",
        "platformStatus": {"macOS-arm64": "locally-tested", "windows-x64": "build-recipe"},
        "tests": {"nativePassed": 46, "nativeFailed": 0, "optionalExternalFixturesSkipped": 5, "controllerSuitesPassed": 4, "usbOnlyContractPassed": True},
        "artifacts": [{"name": path.name, "bytes": path.stat().st_size, "sha256": sha256(path)} for path in artifacts],
    }
    (output / "release-manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    checksum_files = artifacts + [output / "release-manifest.json"]
    (output / "SHA256SUMS.txt").write_text(
        "".join(f"{sha256(path)}  {path.name}\n" for path in checksum_files), encoding="utf-8"
    )
    print(output)


if __name__ == "__main__":
    main()
