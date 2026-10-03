#!/usr/bin/env python3
"""Check isolated profile behavior, Linux package identity and ELF architecture."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded


launch = module('linux_launch', ROOT / 'packaging/linux/launch.py')
stage = module('linux_stage', ROOT / 'packaging/linux/stage-package.py')
with tempfile.TemporaryDirectory() as directory:
    base = Path(directory)
    prefix, source = base / 'install with spaces', base / 'source'
    resources = prefix / 'share/mixxx'
    (resources / 'controllers').mkdir(parents=True)
    (prefix / 'bin').mkdir()
    (prefix / 'bin/mixxx').write_bytes(b'fixture executable')
    source.mkdir()
    (source / 'LICENSE').write_text('fixture upstream license')
    stage.stage(prefix, source, ROOT)
    profile = base / 'profile'
    profile.mkdir()
    database = profile / 'mixxxdb.sqlite'
    database.write_bytes(b'personal database fixture')
    launch.seed_profile(resources, profile)
    cfg = profile / 'mixxx.cfg'
    assert 'Locale en_US' in cfg.read_text()
    assert 'ResizableSkin XDJ_RX3_Mixxx' in cfg.read_text()
    assert 'UsbOnlyMode 1' in cfg.read_text()
    assert (profile / 'controllers/DDJ-SX3-Nautic-RX3.midi.xml').is_file()
    order = ET.parse(profile / 'effects.xml').findall('./QuickEffectPresetList/ChainPresetName')
    assert [node.text for node in order] == ['RX3 REVERB', 'RX3 PING PONG', 'RX3 NOISE', 'RX3 FILTER']
    cfg.write_text(cfg.read_text() + '\n[Personal]\nKeepThisSetting 42\n')
    saved = cfg.read_bytes()
    launch.seed_profile(resources, profile)
    assert cfg.read_bytes() == saved, 'relaunch changed existing settings'
    assert database.read_bytes() == b'personal database fixture'
    entry = launch.desktop_entry(prefix)
    assert f'Exec="{prefix}/bin/nauticmixxx"' in entry
    assert 'Name=NauticMixxx' in entry and 'nauticmixxx.png' in entry
    assert not (prefix / 'bin/mixxx').exists()

parser = argparse.ArgumentParser()
parser.add_argument('--stage', type=Path)
args = parser.parse_args()
if args.stage:
    prefix = args.stage.resolve()
    info = json.loads((prefix / 'rx3-build.json').read_text())
    icon = prefix / 'share/icons/hicolor/1024x1024/apps/nauticmixxx.png'
    expected = hashlib.sha256((ROOT / 'branding/iCon-macOS-Dark-1024x1024@1x.png').read_bytes()).hexdigest()
    assert hashlib.sha256(icon.read_bytes()).hexdigest() == expected == info['icon_sha256']
    assert info['product'] == 'NauticMixxx' and info['version'] == (ROOT / 'VERSION').read_text().strip()
    binary = prefix / 'libexec/nauticmixxx/NauticMixxx'
    with binary.open('rb') as file:
        header = file.read(20)
    assert header[:4] == b'\x7fELF' and header[4] == 2, 'must be a 64-bit ELF binary'
    machine = int.from_bytes(header[18:20], 'little' if header[5] == 1 else 'big')
    assert machine == {'aarch64': 183, 'x86_64': 62}[info['architecture']]
    assert not (prefix / 'share/applications/org.mixxx.Mixxx.desktop').exists()
    assert not list((prefix / 'share/icons').rglob('mixxx.*'))
    for relative in ('skins/XDJ_RX3_Mixxx/skin.xml', 'controllers/Nautic-RX3-Browser.js',
                     'controllers/DDJ-400-Nautic-RX3.midi.xml', 'controllers/DJ-505-Nautic-RX3.midi.xml',
                     'profiles/XDJ_RX3_Mixxx.profile.cfg', 'licenses/Mixxx-LICENSE.txt'):
        assert (prefix / 'share/mixxx' / relative).is_file(), relative
    with tempfile.TemporaryDirectory() as directory:
        env = {**os.environ, 'XDG_DATA_HOME': directory, 'QT_QPA_PLATFORM': 'offscreen'}
        subprocess.run([str(prefix / 'bin/nauticmixxx'), '--install-desktop'], env=env, check=True)
        subprocess.run(['desktop-file-validate', str(Path(directory) / 'applications/org.nauticsoftware.NauticMixxx.desktop')], check=True)
        subprocess.run([str(prefix / 'bin/nauticmixxx'), '--version'], env=env, check=True)
print('Linux package, English profile, user-data preservation and desktop identity: OK')
