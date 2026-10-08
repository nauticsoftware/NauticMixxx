#!/usr/bin/env python3
"""Sign update artifacts and feeds with the release key in macOS Keychain."""
import argparse
import base64
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PUBLIC_KEY = 'qYtGKN6CDB8eym6vRj4XcUD3kLJON9zeYBtlVoEN7Dk='
ACCOUNT = 'nauticmixxx-release-updates'
SPARKLE = 'http://www.andymatuschak.org/xml-namespaces/sparkle'
ET.register_namespace('sparkle', SPARKLE)

def sign(tool, path):
    signature = subprocess.check_output([str(tool), '--account', ACCOUNT, '-p', str(path)], text=True).strip()
    if len(base64.b64decode(signature, validate=True)) != 64:
        raise ValueError('Signing tool did not produce an Ed25519 signature')
    subprocess.run([str(tool), '--account', ACCOUNT, '--verify', str(path), signature], check=True, capture_output=True)
    return signature

def generate(directory, sdk, platform):
    version = (ROOT / 'VERSION').read_text().strip()
    tool = sdk / 'bin/sign_update'
    actual = subprocess.check_output([str(sdk / 'bin/generate_keys'), '--account', ACCOUNT, '-p'], text=True).strip()
    if actual != PUBLIC_KEY:
        raise ValueError('Release signing key does not match the public key in NauticMixxx')
    suffix = 'macOS-arm64.dmg' if platform == 'macos' else 'Windows-x64-Setup.exe'
    artifact = directory / f'NauticMixxx-{version}-{suffix}'
    if not artifact.is_file():
        raise ValueError(f'Missing update artifact: {artifact.name}')
    signature = sign(tool, artifact)
    url = f'https://github.com/nauticsoftware/NauticMixxx/releases/download/v{version}/{artifact.name}'
    if platform == 'macos':
        rss = ET.Element('rss', version='2.0')
        channel = ET.SubElement(rss, 'channel')
        ET.SubElement(channel, 'title').text = 'NauticMixxx signed updates'
        item = ET.SubElement(channel, 'item')
        ET.SubElement(item, 'title').text = f'NauticMixxx {version}'
        ET.SubElement(item, f'{{{SPARKLE}}}version').text = version
        ET.SubElement(item, f'{{{SPARKLE}}}shortVersionString').text = version
        ET.SubElement(item, f'{{{SPARKLE}}}minimumSystemVersion').text = '11.0'
        ET.SubElement(item, 'enclosure', {
            'url': url, 'length': str(artifact.stat().st_size), 'type': 'application/octet-stream',
            f'{{{SPARKLE}}}os': 'macos', f'{{{SPARKLE}}}edSignature': signature,
            f'{{{SPARKLE}}}installationType': 'application'})
        output = directory / 'appcast-macos.xml'
        ET.ElementTree(rss).write(output, encoding='utf-8', xml_declaration=True)
        subprocess.run([str(tool), '--account', ACCOUNT, str(output), '--disable-signing-warning'], check=True)
        subprocess.run([str(tool), '--account', ACCOUNT, '--verify', str(output)], check=True)
    else:
        metadata = dict(product='NauticMixxx', platform='windows-x64', version=version,
                        filename=artifact.name, size=artifact.stat().st_size,
                        sha256=hashlib.sha256(artifact.read_bytes()).hexdigest(), signature=signature)
        payload = json.dumps(metadata, sort_keys=True, separators=(',', ':')).encode('utf-8')
        with tempfile.NamedTemporaryFile(suffix='.payload') as temporary:
            temporary.write(payload)
            temporary.flush()
            manifest_signature = sign(tool, Path(temporary.name))
        output = directory / 'UPDATE_WINDOWS.json'
        output.write_text(json.dumps(dict(payload=base64.b64encode(payload).decode('ascii'),
                                          signature=manifest_signature), indent=2) + '\n')
    # Keep public manifest and checksums consistent with the added signed feed.
    manifest = directory / 'release-manifest.json'
    if manifest.exists():
        data = json.loads(manifest.read_text())
        data['artifacts'] = [item for item in data['artifacts'] if item['name'] != output.name]
        data['artifacts'].append(dict(name=output.name, bytes=output.stat().st_size,
                                     sha256=hashlib.sha256(output.read_bytes()).hexdigest()))
        data['artifacts'].sort(key=lambda item: item['name'])
        manifest.write_text(json.dumps(data, indent=2) + '\n')
        checksum_files = [directory / item['name'] for item in data['artifacts']] + [manifest]
        (directory / 'SHA256SUMS.txt').write_text(''.join(
            hashlib.sha256(path.read_bytes()).hexdigest() + '  ' + path.name + '\n'
            for path in sorted(checksum_files)))
    print(output)
    return output

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--release-dir', required=True, type=Path)
    parser.add_argument('--sdk', required=True, type=Path)
    parser.add_argument('--platform', required=True, choices=['macos', 'windows'])
    options = parser.parse_args()
    generate(options.release_dir.resolve(), options.sdk.resolve(), options.platform)
