#!/usr/bin/env python3
"""Static safety contract for the self-contained Windows installer."""

from pathlib import Path


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
    "Escribe REEMPLAZAR para continuar",
    "Backup-MixxxApplication",
    "Backup-MixxxSettings",
    "Assert-SafeInstallRoot",
    "Test-DirectoryWritable",
    "-Verb RunAs",
    "Test-HerculesAsioDriver",
    "baseMixxxVersion -ne '2.5.6'",
    "Programs\\NauticMixxx\\1.0.0",
)
require(
    "packaging/windows/rx3-install-common.ps1",
    "function Get-MixxxInstallations",
    "function Get-LatestStableMixxxVersion",
    "function Assert-SafeInstallRoot",
    "function Backup-MixxxApplication",
    "NauticMixxx-Backups\\Applications",
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
    "iCon-macOS-Dark-1024x1024@1x.png",
    "ac61e30ddad3b9a05b1972906855863a0e4d0e2e1130c6cb88a998925f45a44f",
    "format=\"ICO\"",
)
require(
    "scripts/package-rx3-windows-native.py",
    "'entryPoint': 'INSTALL-WINDOWS.cmd'",
    "'installModes': ['parallel', 'replace']",
    "info.get('baseMixxxVersion') != '2.5.6'",
)
require(
    "packaging/windows/INSTALL-NATIVE.cmd",
    "unico archivo que necesitas ejecutar",
    "install-mixxx-rx3-windows.ps1",
)

print("Windows installer contract: OK")
