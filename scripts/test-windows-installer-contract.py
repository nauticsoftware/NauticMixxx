#!/usr/bin/env python3
"""Verify native installer inputs and the safety gate before invoking NSIS."""
import hashlib
import importlib.util
import json
from pathlib import Path
import struct
import tempfile
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
script = (ROOT / 'packaging/windows/NauticMixxx.nsi').read_text()
for required in ('Name "NauticMixxx"', 'RequestExecutionLevel user',
                 'NauticMixxx.exe', 'Uninstall-NauticMixxx.exe',
                 'WriteRegStr HKCU', 'CreateShortcut', 'Icon "${ICON}"',
                 'File /r "${PAYLOAD}\\runtime\\*"'):
    assert required in script, required
assert r'${PAYLOAD}\controllers\Pioneer_DDJ_FLX4_RX3\*' in script
assert r'${PAYLOAD}\controllers\Pioneer_Roland_RX3\*' in script
assert 'Locale en_US' in (ROOT / 'profile/XDJ_RX3_Mixxx.profile.cfg').read_text()
assert '.bat' not in script.lower()
build = (ROOT / 'scripts/build-mixxx-rx3-windows.ps1').read_text()
assert 'NauticMixxx.exe' in build and 'NauticMixxx.ico' in build
assert 'build-app-icon-windows.py' in build
icon = (ROOT / 'scripts/build-app-icon-windows.py').read_text()
assert 'branding/iCon-macOS-Dark-1024x1024@1x.png' in icon

spec = importlib.util.spec_from_file_location('windows_package', ROOT / 'scripts/package-rx3-windows-native.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
with tempfile.TemporaryDirectory() as directory:
    base = Path(directory)
    runtime, source, output = (base / name for name in ('runtime', 'source', 'output'))
    runtime.mkdir()
    (source / 'src/widget').mkdir(parents=True)
    (source / 'src/widget/rx3displaystate.h').write_text('// fixture\n')
    exe = bytearray(128)
    exe[:2] = b'MZ'
    exe[0x3c:0x40] = struct.pack('<I', 0x40)
    exe[0x40:0x46] = b'PE\0\0\x64\x86'
    (runtime / 'NauticMixxx.exe').write_bytes(exe)
    (runtime / 'NauticMixxx.ico').write_bytes(b'icon')
    for name in ('Qt6Core.dll', 'platforms/qwindows.dll', 'sqldrivers/qsqlite.dll', 'keyboard/en_US.kbd.cfg'):
        path = runtime / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(b'fixture')
    (runtime / 'rx3-tests.xml').write_text('<testsuite tests="75" failures="0" errors="0"/>')
    info = {'version': module.VERSION, 'product': 'NauticMixxx', 'platform': 'windows-x64',
            'baseMixxxVersion': '2.5.6', 'testsPassed': True,
            'executableSha256': hashlib.sha256(exe).hexdigest(), 'patches': module.patch_state()}
    (runtime / 'rx3-build.json').write_text(json.dumps(info))
    module.validate_runtime(runtime)
    (runtime / 'rx3-build.json').write_text(json.dumps({**info, 'version': '0.0.0'}))
    try:
        module.validate_runtime(runtime)
    except ValueError:
        pass
    else:
        raise AssertionError('Mismatched runtime accepted')
    (runtime / 'rx3-build.json').write_text(json.dumps(info))
    def fake_makensis(command, check):
        assert check and command[0] == 'makensis'
        assert any(arg.startswith('/DICON=') for arg in command)
        assert any(arg.startswith('/DPAYLOAD=') for arg in command)
        setup = next(arg.removeprefix('/DOUTPUT=') for arg in command if arg.startswith('/DOUTPUT='))
        Path(setup).write_bytes(b'MZ' + b'0' * 1024 * 1024)
    with mock.patch.object(module.subprocess, 'run', side_effect=fake_makensis):
        setup = module.package(runtime, source, output)
    assert setup.name == module.NAME
    assert setup.with_suffix('.exe.sha256').is_file()
print('Windows NSIS installer contract: OK')
