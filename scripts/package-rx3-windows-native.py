#!/usr/bin/env python3
"""Build a native NSIS installer from the tested NauticMixxx Windows runtime."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
VERSION = (ROOT / 'VERSION').read_text(encoding='utf-8').strip()
NAME = f'NauticMixxx-{VERSION}-Windows-x64-Setup.exe'


def patch_state():
    patches = sorted((ROOT / 'patches').glob('00[0-9][0-9]-*.patch'))
    if len(patches) != 12:
        raise ValueError('Expected twelve NauticMixxx patches')
    return ','.join(digest(p).upper() for p in patches)


def portable_profile(source, destination):
    """Copy only values allowlisted by the portable profile template."""
    template = (ROOT / 'profile/XDJ_RX3_Mixxx.profile.cfg').read_text()
    current = {}
    if source:
        section = ''
        for line in source.read_text().splitlines():
            if line.startswith('[') and line.endswith(']'):
                section = line
            elif line and not line.startswith(('#', ';')):
                parts = line.split(None, 1)
                if len(parts) == 2:
                    current[(section, parts[0])] = parts[1]
    output = []
    section = ''
    for line in template.splitlines():
        if line.startswith('[') and line.endswith(']'):
            section = line
        elif line and not line.startswith(('#', ';')):
            key, value = line.split(None, 1)
            value = current.get((section, key), value)
            if (section, key) == ('[Config]', 'ScaleFactor'):
                value = '1'
            line = key + ' ' + value
        output.append(line)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text('\n'.join(output) + '\n')


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def validate_runtime(runtime):
    exe = runtime / 'NauticMixxx.exe'
    with exe.open('rb') as f:
        if f.read(2) != b'MZ':
            raise ValueError('NauticMixxx.exe is not a Windows executable')
        f.seek(0x3c)
        offset = struct.unpack('<I', f.read(4))[0]
        f.seek(offset)
        if f.read(6) != b'PE\x00\x00\x64\x86':
            raise ValueError('NauticMixxx.exe must be a Windows x64 executable')
    info = json.loads((runtime / 'rx3-build.json').read_text(encoding='utf-8-sig'))
    if (info.get('version') != VERSION or info.get('platform') != 'windows-x64'
            or info.get('product') != 'NauticMixxx' or info.get('baseMixxxVersion') != '2.5.6'
            or info.get('testsPassed') is not True or info.get('executableSha256', '').lower() != digest(exe)
            or info.get('patches', '').upper() != patch_state()):
        raise ValueError('Runtime has no matching successful RX3 build/test record')
    result = ET.parse(runtime / 'rx3-tests.xml').getroot()
    if int(result.get('failures', '-1')) != 0 or int(result.get('errors', '0')) != 0 or int(result.get('tests', '0')) < 75:
        raise ValueError('Expected the complete passing RX3 regression suite')
    for name in ['Qt6Core.dll', 'platforms/qwindows.dll', 'sqldrivers/qsqlite.dll', 'keyboard/en_US.kbd.cfg']:
        if not (runtime / name).is_file():
            raise ValueError(f'Missing runtime dependency: {name}')


def package(runtime, source, output, settings_file=None, makensis='makensis'):
    validate_runtime(runtime)
    if ET.parse(ROOT / 'skins/XDJ_RX3_Mixxx/skin.xml').findtext('manifest/version') != VERSION:
        raise ValueError('Skin/runtime version mismatch')
    if not (source / 'src/widget/rx3displaystate.h').is_file():
        raise ValueError('Matching patched source is required for distribution')
    output.mkdir(parents=True, exist_ok=True)
    destination = output / NAME
    if destination.exists():
        raise ValueError(f'Output exists; move it aside first: {destination}')
    with tempfile.TemporaryDirectory(prefix='nauticmixxx-nsis-') as temporary:
        files_root = Path(temporary)
        shutil.copytree(runtime, files_root / 'runtime', ignore=shutil.ignore_patterns('*.pdb', 'mixxx-test.exe'))
        icon = files_root / 'NauticMixxx.ico'
        shutil.copy2(runtime / 'NauticMixxx.ico', icon)
        for directory in ['skins/XDJ_RX3_Mixxx', 'controllers/Hercules_DJControl_Inpulse_500_RX3',
                          'controllers/Pioneer_DDJ_FLX6_RX3', 'effects/chains']:
            shutil.copytree(ROOT / directory, files_root / directory, ignore=shutil.ignore_patterns('.DS_Store', '__pycache__'))
        portable_profile(settings_file, files_root / 'profile/XDJ_RX3_Mixxx.profile.cfg')
        for name in ['LICENSE', 'THIRD_PARTY_NOTICES.md']:
            shutil.copy2(ROOT / name, files_root / name)
        command = [makensis, '/V2', f'/DVERSION={VERSION}', f'/DPAYLOAD={files_root}',
                   f'/DOUTPUT={destination}', f'/DICON={icon}',
                   f'/DPROFILE_SCRIPT={ROOT / "packaging/windows/configure-profile.ps1"}',
                   str(ROOT / 'packaging/windows/NauticMixxx.nsi')]
        subprocess.run(command, check=True)
    if not destination.is_file() or destination.stat().st_size < 1024 * 1024:
        raise ValueError('NSIS did not create a complete installer')
    destination.with_suffix('.exe.sha256').write_text(digest(destination) + '  ' + destination.name + '\n')
    print(destination)
    return destination


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime', type=Path, required=True)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=ROOT / 'build')
    parser.add_argument('--settings-file', type=Path)
    parser.add_argument('--makensis', default='makensis')
    args = parser.parse_args()
    package(args.runtime.resolve(), args.source.resolve(), args.output.resolve(), args.settings_file, args.makensis)
