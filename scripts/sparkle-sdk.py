#!/usr/bin/env python3
"""Fetch the free Sparkle SDK only if its pinned SHA-256 matches."""
import argparse
import hashlib
from pathlib import Path
import subprocess
import tarfile

VERSION = '2.10.0'
SHA256 = 'c2bf58aa8387266ac179357b1415d6f2635f044da8be41042af32425dae6da0c'
URL = f'https://github.com/sparkle-project/Sparkle/releases/download/{VERSION}/Sparkle-{VERSION}.tar.xz'

def fetch(destination):
    destination = Path(destination).resolve()
    destination.parent.mkdir(parents=True, exist_ok=True)
    archive = destination.parent / f'Sparkle-{VERSION}.tar.xz'
    if not archive.is_file():
        subprocess.run(['curl', '--fail', '--location', '--retry', '3', URL, '-o', str(archive)], check=True)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != SHA256:
        raise ValueError('Sparkle SDK SHA-256 mismatch; refusing to use it')
    if not (destination / 'Sparkle.framework/Headers/Sparkle.h').is_file():
        destination.mkdir(parents=True, exist_ok=True)
        # The complete archive is pinned to a reviewed upstream release.
        with tarfile.open(archive) as bundle:
            for member in bundle.getmembers():
                target = (destination / member.name).resolve()
                if target != destination and destination not in target.parents:
                    raise ValueError('Archive path escapes the SDK directory')
            bundle.extractall(destination)
    return destination

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--destination', type=Path, required=True)
    options = parser.parse_args()
    print(fetch(options.destination))
