#!/usr/bin/env python3
"""Build the Windows skin-only ZIP with install/uninstall BATs and one folder."""

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import zipfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
VERSION = (ROOT / 'VERSION').read_text(encoding='utf-8').strip()
NAME = f'NauticMixxx-{VERSION}-Windows-x64-Skin'


def digest(path):
    checksum = hashlib.sha256()
    with path.open('rb') as file:
        for block in iter(lambda: file.read(1024 * 1024), b''):
            checksum.update(block)
    return checksum.hexdigest()


def package(output):
    skin_version = ET.parse(ROOT / 'skins/XDJ_RX3_Mixxx/skin.xml').findtext('manifest/version')
    if skin_version != VERSION:
        raise ValueError(f'Skin version {skin_version} does not match VERSION {VERSION}')
    output.mkdir(parents=True, exist_ok=True)
    destination = output / NAME
    archive = output / f'{NAME}.zip'
    if destination.exists() or archive.exists():
        raise ValueError(f'Output already exists; move it aside first: {destination} or {archive}')
    destination.mkdir()
    launcher = (ROOT / 'packaging/windows/INSTALL-SKIN.bat').read_text(encoding='ascii')
    (destination / 'INSTALL-WINDOWS.bat').write_bytes(
        launcher.replace('@VERSION@', VERSION).replace('\n', '\r\n').encode('ascii')
    )
    uninstaller = (ROOT / 'packaging/windows/UNINSTALL-SKIN.bat').read_text(encoding='ascii')
    (destination / 'UNINSTALL-WINDOWS.bat').write_bytes(
        uninstaller.replace('\n', '\r\n').encode('ascii')
    )
    files_root = destination / 'NauticMixxx-Files'
    files_root.mkdir()
    for directory in ('skins/XDJ_RX3_Mixxx', 'controllers/Hercules_DJControl_Inpulse_500_RX3', 'controllers/Pioneer_DDJ_FLX4_RX3', 'controllers/Pioneer_DDJ_FLX6_RX3', 'controllers/Pioneer_Roland_RX3', 'effects/chains'):
        shutil.copytree(ROOT / directory, files_root / directory,
                        ignore=shutil.ignore_patterns('.DS_Store', '__pycache__'))
    files = {
        'packaging/windows/install-skin-rx3.ps1': 'install-skin-rx3.ps1',
        'packaging/windows/uninstall-nauticmixxx.ps1': 'uninstall-nauticmixxx.ps1',
        'packaging/windows/rx3-install-common.ps1': 'windows/rx3-install-common.ps1',
        'packaging/windows/install-hercules-driver.ps1': 'windows/install-hercules-driver.ps1',
        'packaging/windows/cleanup-public-shortcut.ps1': 'windows/cleanup-public-shortcut.ps1',
        'packaging/windows/README-SKIN.txt': 'README.txt',
        'docs/DDJ-FLX6-EN.md': 'DDJ-FLX6-EN.md',
        'docs/CONTROLLERS-RX3-1.5.md': 'CONTROLLERS-RX3-1.5.md',
        'profile/XDJ_RX3_Mixxx.profile.cfg': 'profile/XDJ_RX3_Mixxx.profile.cfg',
    }
    for source, target in files.items():
        destination_file = files_root / target
        destination_file.parent.mkdir(parents=True, exist_ok=True)
        content = (ROOT / source).read_text(encoding='utf-8-sig')
        destination_file.write_bytes(content.replace('\r\n', '\n').replace('\n', '\r\n').encode(
            'utf-8-sig' if destination_file.suffix == '.ps1' else 'utf-8'))
    icon_source = ROOT / 'packaging/windows/NauticMixxx.ico'
    if digest(icon_source) != '5a4ae1e00065ea4d85e4959af2e22b3f1b6ca5b7d2ee4eb2638aa4834b407ed5':
        raise ValueError('The NauticMixxx Windows icon is missing or was changed')
    icon_target = files_root / 'branding/NauticMixxx.ico'
    icon_target.parent.mkdir(parents=True)
    shutil.copy2(icon_source, icon_target)
    manifest = {
        'product': 'NauticMixxx',
        'kind': 'skin-only',
        'version': VERSION,
        'platform': 'windows-x64',
        'entryPoint': 'INSTALL-WINDOWS.bat',
        'uninstallEntryPoint': 'UNINSTALL-WINDOWS.bat',
        'mixxxDownload': 'https://downloads.mixxx.org/releases/2.5.6/mixxx-2.5.6-win64.msi',
        'files': [
            {'path': path.relative_to(files_root).as_posix(), 'sha256': digest(path)}
            for path in sorted(files_root.rglob('*')) if path.is_file()
        ],
    }
    (files_root / 'payload-sha256.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED) as package_file:
        for path in sorted(destination.rglob('*')):
            if path.is_file():
                package_file.write(path, path.relative_to(output))
    archive.with_suffix('.zip.sha256').write_text(f'{digest(archive)}  {archive.name}\n', encoding='ascii')
    print(archive)
    return archive


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'build/test-candidate' / VERSION)
    arguments = parser.parse_args()
    package(arguments.output.resolve())
