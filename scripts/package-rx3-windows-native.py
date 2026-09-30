#!/usr/bin/env python3
"""Package a built and tested Windows RX3 runtime; never substitute stock Mixxx."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import struct
import tarfile
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = (ROOT / 'VERSION').read_text(encoding='utf-8').strip()
NAME = f'NauticMixxx-{VERSION}-Windows-x64'


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
    exe = runtime / 'mixxx.exe'
    with exe.open('rb') as f:
        if f.read(2) != b'MZ':
            raise ValueError('mixxx.exe is not a Windows executable')
        f.seek(0x3c)
        offset = struct.unpack('<I', f.read(4))[0]
        f.seek(offset)
        if f.read(6) != b'PE\x00\x00\x64\x86':
            raise ValueError('mixxx.exe must be a Windows x64 executable')
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


def package(runtime, source, output, settings_file=None):
    validate_runtime(runtime)
    if ET.parse(ROOT / 'skins/XDJ_RX3_Mixxx/skin.xml').findtext('manifest/version') != VERSION:
        raise ValueError('Skin/runtime version mismatch')
    if not (source / 'src/widget/rx3displaystate.h').is_file():
        raise ValueError('Matching patched source is required for distribution')
    destination = output / NAME
    if destination.exists():
        raise ValueError(f'Output exists; move it aside first: {destination}')
    destination.mkdir(parents=True)
    launcher_source = ROOT / 'packaging/windows/INSTALL-NATIVE.bat'
    if not launcher_source.is_file():
        launcher_source = ROOT.parent / 'INSTALL-WINDOWS.bat'
    launcher = launcher_source.read_text(encoding='utf-8')
    (destination / 'INSTALL-WINDOWS.bat').write_bytes(
        launcher.replace('@VERSION@', VERSION).replace('\n', '\r\n').encode('ascii')
    )
    files_root = destination / 'NauticMixxx-Files'
    files_root.mkdir()
    shutil.copytree(runtime, files_root / 'runtime', ignore=shutil.ignore_patterns('*.pdb', 'mixxx-test.exe'))
    for directory in ['skins/XDJ_RX3_Mixxx', 'controllers/Hercules_DJControl_Inpulse_500_RX3', 'effects/chains']:
        shutil.copytree(ROOT / directory, files_root / directory, ignore=shutil.ignore_patterns('.DS_Store', '__pycache__'))
    for original, target in {
        'packaging/windows/install-native-rx3.ps1': 'install-native-rx3.ps1',
        'packaging/windows/README-NATIVE.txt': 'README.txt',
        'packaging/windows/rx3-install-common.ps1': 'windows/rx3-install-common.ps1',
        'packaging/windows/install-hercules-driver.ps1': 'windows/install-hercules-driver.ps1',
    }.items():
        target_path = files_root / target
        target_path.parent.mkdir(parents=True, exist_ok=True)
        text = (ROOT / original).read_text(encoding='utf-8-sig')
        target_path.write_bytes(text.replace('\r\n', '\n').replace('\n', '\r\n').encode('utf-8-sig' if target_path.suffix == '.ps1' else 'utf-8'))
    portable_profile(settings_file, files_root / 'profile/XDJ_RX3_Mixxx.profile.cfg')
    # Complete corresponding source and build recipe travel with the binary.
    source_dir = files_root / 'source'
    source_dir.mkdir()
    def source_filter(member):
        if any(part in {'.git', '__pycache__', '.DS_Store'} for part in Path(member.name).parts):
            return None
        return member
    with tarfile.open(source_dir / f'NauticMixxx-{VERSION}-source.tar.gz', 'w:gz') as tar:
        tar.add(source, arcname='mixxx-2.5.6', filter=source_filter)
    # Keep the recipe at the same relative paths it uses in the project.
    shutil.copytree(ROOT / 'patches', files_root / 'patches')
    for name in ['build-mixxx-rx3-windows.ps1', 'build-app-icon-windows.py', 'package-rx3-windows-native.py']:
        (files_root / 'scripts').mkdir(exist_ok=True)
        shutil.copy2(ROOT / 'scripts' / name, files_root / 'scripts' / name)
    shutil.copy2(ROOT / 'VERSION', files_root / 'VERSION')
    branding = files_root / 'branding/iCon-macOS-Dark-1024x1024@1x.png'
    branding.parent.mkdir(parents=True)
    shutil.copy2(ROOT / 'branding/iCon-macOS-Dark-1024x1024@1x.png', branding)
    icon_source = files_root / 'packaging/DMG_PROJECT/iCon-macOS-Dark-1024x1024@1x.png'
    icon_source.parent.mkdir(parents=True)
    shutil.copy2(ROOT / 'branding/iCon-macOS-Dark-1024x1024@1x.png', icon_source)
    for name in ['install-native-rx3.ps1', 'rx3-install-common.ps1', 'install-hercules-driver.ps1', 'README-NATIVE.txt']:
        recipe = files_root / 'packaging/windows' / name
        recipe.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / 'packaging/windows' / name, recipe)
    shutil.copy2(source / 'LICENSE', source_dir)
    files = sorted(p for p in files_root.rglob('*') if p.is_file())
    manifest = {
        'product': 'NauticMixxx',
        'version': VERSION,
        'platform': 'windows-x64',
        'baseMixxxVersion': '2.5.6',
        'patches': patch_state(),
        'entryPoint': 'INSTALL-WINDOWS.bat',
        'installModes': ['parallel', 'replace'],
        'files': [
            {'path': p.relative_to(files_root).as_posix(), 'sha256': digest(p)} for p in files
        ],
    }
    (files_root / 'payload-sha256.json').write_text(json.dumps(manifest, indent=2) + '\n')
    archive = output / (NAME + '.zip')
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for path in sorted(p for p in destination.rglob('*') if p.is_file()):
            z.write(path, path.relative_to(output))
    archive.with_suffix('.zip.sha256').write_text(digest(archive) + '  ' + archive.name + '\n')
    print(archive)
    return archive


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime', type=Path, required=True)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=ROOT / 'build')
    parser.add_argument('--settings-file', type=Path)
    args = parser.parse_args()
    package(args.runtime.resolve(), args.source.resolve(), args.output.resolve(), args.settings_file)
