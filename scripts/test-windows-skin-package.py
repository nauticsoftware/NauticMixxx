#!/usr/bin/env python3
"""Check the skin-only Windows ZIP structure, contents and install contract."""

import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import zipfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    'rx3_skin_package', ROOT / 'scripts/package-rx3-windows-skin.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

with tempfile.TemporaryDirectory(prefix='rx3-skin-package-') as directory:
    archive = module.package(Path(directory))
    with zipfile.ZipFile(archive) as package:
        names = package.namelist()
        prefix = module.NAME + '/'
        root_items = {name[len(prefix):].split('/', 1)[0] for name in names}
        assert root_items == {'INSTALL-WINDOWS.bat', 'UNINSTALL-WINDOWS.bat', 'NauticMixxx-Files'}, root_items
        launchers = [name for name in names if name.lower().endswith(('.bat', '.cmd'))]
        assert set(launchers) == {prefix + 'INSTALL-WINDOWS.bat', prefix + 'UNINSTALL-WINDOWS.bat'}, launchers
        assert not any(name.lower().endswith(('.exe', '.msi')) for name in names)
        launcher = package.read(prefix + 'INSTALL-WINDOWS.bat').decode('ascii')
        assert 'NauticMixxx-Files' in launcher
        assert 'install-skin-rx3.ps1' in launcher
        assert 'Press any key to close this window' in launcher
        uninstaller_launcher = package.read(prefix + 'UNINSTALL-WINDOWS.bat').decode('ascii')
        assert 'uninstall-nauticmixxx.ps1' in uninstaller_launcher
        assert 'NauticMixxx-Files' in uninstaller_launcher
        manifest = json.loads(package.read(prefix + 'NauticMixxx-Files/payload-sha256.json'))
        assert manifest['product'] == 'NauticMixxx'
        assert manifest['kind'] == 'skin-only'
        assert manifest['version'] == module.VERSION == '1.2.0'
        assert manifest['entryPoint'] == 'INSTALL-WINDOWS.bat'
        assert manifest['uninstallEntryPoint'] == 'UNINSTALL-WINDOWS.bat'
        assert len(manifest['files']) > 20
        flx6_xml = prefix + 'NauticMixxx-Files/controllers/Pioneer_DDJ_FLX6_RX3/Pioneer-DDJ-FLX6-RX3-Browser.midi.xml'
        flx6_js = prefix + 'NauticMixxx-Files/controllers/Pioneer_DDJ_FLX6_RX3/Pioneer-DDJ-FLX6-RX3-Browser.js'
        assert flx6_xml in names and flx6_js in names
        assert prefix + 'NauticMixxx-Files/DDJ-FLX6-EN.md' in names
        mapping = ET.fromstring(package.read(flx6_xml))
        bindings = {(control.findtext('status'), control.findtext('midino'))
                    for control in mapping.findall('./controller/controls/control')}
        assert {('0x96', note) for note in ('0x7A', '0x68', '0x41', '0x65', '0x46', '0x47')}.issubset(bindings)
        assert ('0xB6', '0x40') in bindings
        icon = package.read(prefix + 'NauticMixxx-Files/branding/NauticMixxx.ico')
        assert icon[:4] == b'\x00\x00\x01\x00' and int.from_bytes(icon[4:6], 'little') == 7
        for file in manifest['files']:
            assert file['path'] and not file['path'].startswith(('/', '../'))
            content = package.read(prefix + 'NauticMixxx-Files/' + file['path'])
            assert hashlib.sha256(content).hexdigest() == file['sha256'], file['path']
        installer = package.read(prefix + 'NauticMixxx-Files/install-skin-rx3.ps1').decode('utf-8-sig')
        for marker in ('Install-OfficialMixxx', 'Get-MixxxInstallations',
                       'Get-InstalledSkinVersion', 'Backup-SkinSettings',
                       "Where-Object { $_.Kind -eq 'NauticMixxx' }",
                       'NauticMixxx.lnk', 'NauticMixxx.ico',
                       "[P] Parallel", "[R] Replace", 'will not downgrade it'):
            assert marker in installer, marker
        uninstaller = package.read(prefix + 'NauticMixxx-Files/uninstall-nauticmixxx.ps1').decode('utf-8-sig')
        for marker in ('Get-OwnedApplicationRoots', 'Mixxx-RX3', 'NauticMixxx-Backups',
                       'Remove-Rx3StandardProfile', 'Get-NauticShortcutPaths',
                       'Type UNINSTALL', 'shared Hercules driver are retained'):
            assert marker in uninstaller, marker
        common = package.read(prefix + 'NauticMixxx-Files/windows/rx3-install-common.ps1').decode('utf-8-sig')
        assert '0d1f01a1f5c2e4d4180cd462e60365d0230b405808e7bd2b6625b62a53a29c72' in common
        assert 'https://downloads.mixxx.org/releases/' in common
        assert 'mixxx-$mixxxVersion-win64.msi' in common

print('Windows skin package contract: OK')
