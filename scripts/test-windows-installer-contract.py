#!/usr/bin/env python3
"""Safety and package-layout contract for the self-contained Windows installer."""

import importlib.util
import hashlib
import json
from pathlib import Path
import struct
import tempfile
import zipfile


ROOT = Path(__file__).resolve().parents[1]


def require(path: str, *needles: str) -> None:
    text = (ROOT / path).read_text(encoding="utf-8-sig")
    missing = [needle for needle in needles if needle not in text]
    if missing:
        raise AssertionError(f"{path} is missing contract markers: {missing}")


require(
    "packaging/windows/install-native-rx3.ps1",
    "[ValidateSet('Ask', 'Parallel', 'Replace')]",
    "Get-LatestStableMixxxVersion",
    "Get-MixxxInstallations",
    "Type REPLACE to continue",
    "Backup-MixxxApplication",
    "Backup-MixxxSettings",
    "Assert-SafeInstallRoot",
    "Test-DirectoryWritable",
    "-Verb RunAs",
    "Test-HerculesAsioDriver",
    "baseMixxxVersion -ne '2.5.6'",
    "Programs\\NauticMixxx\\",
    "Checking package files and SHA-256 hashes",
    "Detecting existing Mixxx installations",
)
require(
    "packaging/windows/rx3-install-common.ps1",
    "function Get-MixxxInstallations",
    "function Get-LatestStableMixxxVersion",
    "function Assert-SafeInstallRoot",
    "function Backup-MixxxApplication",
    "NauticMixxx-Backups\\Applications",
    "Verified {0}/{1} files",
)
require(
    "scripts/build-mixxx-rx3-windows.ps1",
    "build-app-icon-windows.py",
    "NauticMixxx digital DJ software",
    "baseMixxxVersion = '2.5.6'",
    "testsPassed = $true",
)
require(
    "scripts/build-app-icon-windows.py",
    "branding/iCon-macOS-Dark-1024x1024@1x.png",
    "ac61e30ddad3b9a05b1972906855863a0e4d0e2e1130c6cb88a998925f45a44f",
    "format=\"ICO\"",
)
require(
    "scripts/package-rx3-windows-native.py",
    "'entryPoint': 'INSTALL-WINDOWS.bat'",
    "'installModes': ['parallel', 'replace']",
    "info.get('baseMixxxVersion') != '2.5.6'",
    "files_root = destination / 'NauticMixxx-Files'",
)
require(
    "packaging/windows/INSTALL-NATIVE.bat",
    "NauticMixxx-Files",
    "install-native-rx3.ps1",
)

module_path = ROOT / "scripts/package-rx3-windows-native.py"
spec = importlib.util.spec_from_file_location("rx3_windows_package", module_path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

with tempfile.TemporaryDirectory(prefix="rx3-windows-contract-") as temporary:
    base = Path(temporary)
    runtime = base / "runtime"
    source = base / "source"
    output = base / "output"
    runtime.mkdir()
    output.mkdir()
    (source / "src/widget").mkdir(parents=True)
    (source / "src/widget/rx3displaystate.h").write_text("// package fixture\n")
    (source / "LICENSE").write_text("Fixture license\n")
    exe = bytearray(128)
    exe[:2] = b"MZ"
    exe[0x3C:0x40] = struct.pack("<I", 0x40)
    exe[0x40:0x46] = b"PE\0\0\x64\x86"
    (runtime / "mixxx.exe").write_bytes(exe)
    for name in ("Qt6Core.dll", "platforms/qwindows.dll", "sqldrivers/qsqlite.dll", "keyboard/en_US.kbd.cfg"):
        path = runtime / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(b"fixture")
    (runtime / "rx3-tests.xml").write_text('<testsuite tests="75" failures="0" errors="0"/>')
    build_info = {
        "version": module.VERSION, "product": "NauticMixxx", "platform": "windows-x64",
        "baseMixxxVersion": "2.5.6", "testsPassed": True,
        "executableSha256": hashlib.sha256(exe).hexdigest(),
        "patches": module.patch_state(),
    }
    (runtime / "rx3-build.json").write_text(json.dumps(build_info))
    (runtime / "rx3-build.json").write_text(json.dumps({**build_info, "version": "1.0.0"}))
    try:
        module.validate_runtime(runtime)
    except ValueError:
        pass
    else:
        raise AssertionError("The 1.0.0 runtime must not be repackaged as 1.1.0")
    (runtime / "rx3-build.json").write_text(json.dumps(build_info))
    archive = module.package(runtime, source, output)
    with zipfile.ZipFile(archive) as package:
        entries = package.namelist()
        prefix = module.NAME + "/"
        root_items = {entry[len(prefix):].split("/", 1)[0] for entry in entries}
        assert root_items == {"INSTALL-WINDOWS.bat", "NauticMixxx-Files"}, root_items
        launchers = [entry for entry in entries if entry.lower().endswith((".bat", ".cmd"))]
        assert launchers == [prefix + "INSTALL-WINDOWS.bat"], launchers
        launcher = package.read(launchers[0]).decode("ascii")
        assert "NauticMixxx 1.1.0" in launcher
        assert "%RX3_FILES%\\install-native-rx3.ps1" in launcher
        manifest = json.loads(package.read(prefix + "NauticMixxx-Files/payload-sha256.json"))
        assert manifest["version"] == module.VERSION
        assert manifest["patches"] == module.patch_state()
        assert manifest["entryPoint"] == "INSTALL-WINDOWS.bat"
        assert len(manifest["files"]) > 20
        assert all(entry["path"] and not entry["path"].startswith("../") for entry in manifest["files"])
        assert all(hashlib.sha256(package.read(prefix + "NauticMixxx-Files/" + entry["path"])).hexdigest() == entry["sha256"] for entry in manifest["files"])

print("Windows installer contract: OK")
