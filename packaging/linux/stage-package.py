#!/usr/bin/env python3
"""Stage a Linux build using the NauticMixxx name, icon, skin and controller presets."""
from pathlib import Path
import hashlib
import json
import platform
import shutil
import sys


def stage(prefix: Path, source: Path, project: Path) -> None:
    resources = prefix / 'share/mixxx'
    if not (resources / 'controllers').is_dir():
        raise ValueError('CMake did not install Mixxx resources')
    binary = prefix / 'libexec/nauticmixxx/NauticMixxx'
    binary.parent.mkdir(parents=True, exist_ok=True)
    (prefix / 'bin/mixxx').replace(binary)
    launcher = prefix / 'bin/nauticmixxx'
    launcher.write_text('#!/bin/sh\nset -eu\n'
                        'prefix=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)\n'
                        'exec python3 "$prefix/libexec/nauticmixxx/launch.py" "$prefix" "$@"\n')
    launcher.chmod(0o755)
    shutil.copy2(project / 'packaging/linux/launch.py', binary.parent / 'launch.py')
    shutil.copytree(project / 'skins/XDJ_RX3_Mixxx', resources / 'skins/XDJ_RX3_Mixxx', dirs_exist_ok=True)
    for name in ('Hercules_DJControl_Inpulse_500_RX3', 'Pioneer_DDJ_FLX4_RX3',
                 'Pioneer_DDJ_FLX6_RX3', 'Pioneer_Roland_RX3'):
        shutil.copytree(project / 'controllers' / name, resources / 'controllers', dirs_exist_ok=True)
    shutil.copytree(project / 'effects/chains', resources / 'effects/chains', dirs_exist_ok=True)
    (resources / 'profiles').mkdir(exist_ok=True)
    shutil.copy2(project / 'profile/XDJ_RX3_Mixxx.profile.cfg', resources / 'profiles')
    # Remove the upstream desktop identity rather than shipping two app entries.
    (prefix / 'share/applications/org.mixxx.Mixxx.desktop').unlink(missing_ok=True)
    (prefix / 'share/metainfo/org.mixxx.Mixxx.metainfo.xml').unlink(missing_ok=True)
    shutil.rmtree(prefix / 'share/icons/hicolor', ignore_errors=True)
    icon = prefix / 'share/icons/hicolor/1024x1024/apps/nauticmixxx.png'
    icon.parent.mkdir(parents=True, exist_ok=True)
    original = project / 'branding/iCon-macOS-Dark-1024x1024@1x.png'
    shutil.copy2(original, icon)
    licenses = resources / 'licenses'
    licenses.mkdir(exist_ok=True)
    shutil.copy2(source / 'LICENSE', licenses / 'Mixxx-LICENSE.txt')
    for name in ('LICENSE.md', 'THIRD_PARTY_NOTICES.md'):
        shutil.copy2(project / name, licenses / name)
    shutil.copy2(project / 'docs/LINUX-RASPBERRY-PI.md', prefix / 'LINUX-README.md')
    metadata = dict(product='NauticMixxx', version=(project / 'VERSION').read_text().strip(),
                    architecture=platform.machine(), distribution=(platform.freedesktop_os_release()
                        if platform.system() == 'Linux' else {'ID': 'non-linux-test-fixture'}),
                    source='Mixxx 2.5.6 with 17 NauticMixxx patches', optimization='portable',
                    icon_sha256=hashlib.sha256(original.read_bytes()).hexdigest(),
                    limitations=['Native distro libraries required; not a universal Linux package',
                                 'Pi 4 GPU, USB audio, controllers and real-time performance untested',
                                 'Denon export and local key detection disabled in Linux recipe'])
    (prefix / 'rx3-build.json').write_text(json.dumps(metadata, indent=2) + '\n')


if __name__ == '__main__':
    stage(*(Path(arg).resolve() for arg in sys.argv[1:]))
