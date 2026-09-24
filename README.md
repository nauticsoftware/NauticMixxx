# NauticMixxx 1.0.0

![NauticMixxx](branding/NauticMixxx.png)

NauticMixxx is a community and open source edition of Mixxx 2.5.6,
Designed to offer a visual flow of two decks inspired by a cabin
XDJ-RX3 and a deep integration with Hercules DJControl Inpulse 500.
Version 1.0.0 brings together the native application, the skin, the mapping, the Sound
Colour FX, the rekordbox USB browser and playable patches in one
Verifiable distribution.

## What does it include?

- 1280×800 scaleable interface with PERFORMANCE, BROWSE and STATUS views.
- Stacked waveforms, perimeter beat grid, overview and eight Hot Cues per deck.
- Exclusive navigation and charging from USB prepared by rekordbox; the assistant,
- Scan and local music library sources are blocked.
- Specific mapping for Hercules DJControl Inpulse 500.
- Four Sound Colour FX and loop controls adapted to the hardware.
- Startup screen, icon and status without clues with NauticMixxx identity.
- SOURCE/USB reopening correction during playback.
- Sources, patches, tests and checksums to audit each release.

## Download and install

Publicisable files are generated in `release/1.0.0/`:

- `NauticMixxx-1.0.0-macOS-arm64.dmg`
- `NauticMixxx-1.0.0-macOS-arm64.zip`
- `NauticMixxx-1.0.0-source.tar.gz`
- `NauticMixxx-1.0.0-skin.zip`
- `SHA256SUMS.txt` y `release-manifest.json`

In macOS, open the DMG, drag **NauticMixxx.app** to Applications and open it.
The ZIP contains the same application as an alternative download. La
Local compilation is signed ad hoc; a general publication must
Sign and notarise with an Apple Developer account. Consultation
[`docs/INSTALLATION.md`](docs/INSTALLATION.md).

Windows x64 has a reproducible flow using GitHub Actions. The
Artefact is generated from the same base and the same ten patches; consult
[`docs/BUILDING.md`](docs/BUILDING.md).

## Verify a download

```bash
cd release/1.0.0
shasum -a 256 -c SHA256SUMS.txt
```

## Try the current version

The application ready for the physical test is in
`release/1.0.0/NauticMixxx-1.0.0-macOS-arm64/NauticMixxx.app`. Connect the Hercules DJControl Inpulse 500,
Open that application and follow [`docs/HARDWARE_TEST.md`](docs/HARDWARE_TEST.md).

## Development and release
```bash
./scripts/validate-release.sh
python3 scripts/package-release.py
```

macOS native build plays with:
```bash
./scripts/build-mixxx-rx3-macos.sh
```
## Structure of the repository

- `patches/`: reproducible changes applied on Mixxx 2.5.6.
- `controllers/`, `effects/`, `skins/` and `profile/`: NauticMixxx components.
- `scripts/` and `packaging/`: compilation, distribution and verification.
- `release/1.0.0/`: local artefacts; public binaries are attached to GitHub Releases.
- 
Documentation:

- [Installation](docs/INSTALLATION.md)
- [Reproducible Compilation](docs/BUILDING.md)
- [Tests and scope of 1.0](docs/TESTING.md)
- [Physical test of the six fixes](docs/HARDWARE_TEST.md)
- [Organisation and cleaning policy](docs/WORKSPACE.md)
- [How to publish the release](docs/RELEASING.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Changes](CHANGELOG.md)
- [Contribute](CONTRIBUTING.md)

## License and brands

The work of NauticMixxx is published under GNU GPL v3. The Mixxx engine retains
GNU GPL v2 or later and its notices. Consult [LICENSE.md](LICENSE.md) and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

NauticMixxx is not an official product nor is it affiliated with the holders of the
Mentioned brands. Check [TRADEMARKS.md](TRADEMARKS.md).
