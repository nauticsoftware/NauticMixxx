#!/usr/bin/env python3
"""Embed and sign the sandbox-aware updater using free ad-hoc signing by default."""
import argparse
import os
from pathlib import Path
import plistlib
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
PUBLIC_KEY = 'qYtGKN6CDB8eym6vRj4XcUD3kLJON9zeYBtlVoEN7Dk='
FEED_URL = 'https://github.com/nauticsoftware/NauticMixxx/releases/latest/download/appcast-macos.xml'

def configure(app, sdk, identity='-'):
    app, sdk = Path(app).resolve(), Path(sdk).resolve()
    source = sdk / 'Sparkle.framework'
    if not (source / 'Headers/Sparkle.h').is_file():
        raise ValueError('Verified Sparkle SDK is required')
    framework = app / 'Contents/Frameworks/Sparkle.framework'
    subprocess.run(['ditto', str(source), str(framework)], check=True)
    info = app / 'Contents/Info.plist'
    with info.open('rb') as handle:
        data = plistlib.load(handle)
    data.update(SUFeedURL=FEED_URL, SUPublicEDKey=PUBLIC_KEY,
                SUEnableAutomaticChecks=False, SUAutomaticallyUpdate=False,
                SUSendProfileInfo=False, SURequireSignedFeed=True,
                SUVerifyUpdateBeforeExtraction=True, SUEnableInstallerLauncherService=True)
    with info.open('wb') as handle:
        plistlib.dump(data, handle)
    licenses = app / 'Contents/Resources/licenses'
    licenses.mkdir(parents=True, exist_ok=True)
    (licenses / 'Sparkle-LICENSE.txt').write_bytes((sdk / 'LICENSE').read_bytes())
    with (ROOT / 'packaging/macos/mixxx-entitlements.plist').open('rb') as handle:
        entitlements = plistlib.load(handle)
    identifier = data['CFBundleIdentifier']
    entitlements['com.apple.security.temporary-exception.mach-lookup.global-name'] = [
        identifier + '-spks', identifier + '-spki']
    subprocess.run(['xattr', '-cr', str(app)], check=True)
    # Sign all modified nested libraries first. Never propagate app-sandbox
    # entitlements into Sparkle's installer using codesign --deep.
    executable = app / 'Contents/MacOS' / data['CFBundleExecutable']
    magic = {b'\xcf\xfa\xed\xfe', b'\xce\xfa\xed\xfe', b'\xca\xfe\xba\xbe', b'\xbe\xba\xfe\xca'}
    for path in sorted(app.rglob('*'), key=lambda p: len(p.parts), reverse=True):
        if path.is_symlink() or not path.is_file() or path == executable:
            continue
        with path.open('rb') as handle:
            is_macho = handle.read(4) in magic
        if is_macho:
            command = ['codesign', '--force', '--sign', identity, '--preserve-metadata=entitlements']
            if framework in path.parents:
                command += ['--options', 'runtime']
            subprocess.run(command + [str(path)], check=True)
    bundles = [p for p in app.rglob('*') if p.is_dir() and not p.is_symlink()
               and p.suffix in {'.app', '.xpc', '.framework'}]
    for bundle in sorted(bundles, key=lambda p: len(p.parts), reverse=True):
        command = ['codesign', '--force', '--sign', identity, '--preserve-metadata=entitlements']
        if bundle == framework or framework in bundle.parents:
            command += ['--options', 'runtime']
        subprocess.run(command + [str(bundle)], check=True)
    with tempfile.NamedTemporaryFile(suffix='.plist') as temporary:
        temporary.write(plistlib.dumps(entitlements))
        temporary.flush()
        subprocess.run(['codesign', '--force', '--sign', identity, '--entitlements', temporary.name, str(app)], check=True)
    subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app', type=Path, required=True)
    parser.add_argument('--sdk', type=Path, required=True)
    options = parser.parse_args()
    configure(options.app, options.sdk, os.environ.get('NAUTIC_SIGNING_IDENTITY', '-'))
