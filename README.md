# NauticMixxx 1.2.0

![NauticMixxx](branding/NauticMixxx.png)

NauticMixxx is an open-source community edition of Mixxx 2.5.6. It brings an XDJ-RX3-inspired two-deck display to Mixxx, with a dedicated Hercules DJControl Inpulse 500 mapping.

Version 1.2 fixes the USB Rekordbox workflow and performance preferences: Pioneer Cue, ±6% pitch, first-sound loading when a marker exists, remaining time, beat countdown, visual waveform normalization, highest-quality pitch-bend engine, and orange loop/hot-loop defaults. It disables local library scanning, audio analysis, ReplayGain and waveform disk caching. The waveform menu has BLUE, RGB and 3Band. The Hercules DJControl Inpulse 500 automatically uses the custom RX3 mapping when detected.

## Features

- Scalable PERFORMANCE, BROWSE and STATUS views with stacked waveforms, beatgrid, overviews and eight Hot Cues per deck.
- Rekordbox USB browsing and loading in the native NauticMixxx app. Its local music-folder browser and scanner are disabled.
- Hercules DJControl Inpulse 500 mapping with RX3-style browser and loop controls.
- Optional DDJ-FLX6 **browser-only** preset for VIEW, SOURCE, BROWSE, BACK and LOAD 1/2. It does not replace a full controller mapping; see the [DDJ-FLX6 guide](docs/DDJ-FLX6-EN.md).
- Four Sound Color FX, NauticMixxx branding, reproducible patches, tests and release checksums.

## Download and install

The 1.2.0 macOS candidate and its checksums are generated under `build/release-candidate/1.2.0/`. The Windows native binary still needs a Windows x64 build and hardware validation. See [release notes](RELEASE_NOTES.md) and the [installation guide](docs/INSTALLATION-EN.md).

The most recently published version is [NauticMixxx 1.1.0](https://github.com/nauticsoftware/NauticMixxx/releases/tag/v1.1.0):

- [macOS Apple Silicon DMG](https://github.com/nauticsoftware/NauticMixxx/releases/download/v1.1.0/NauticMixxx-1.1.0-macOS-arm64.dmg)
- [macOS Apple Silicon ZIP](https://github.com/nauticsoftware/NauticMixxx/releases/download/v1.1.0/NauticMixxx-1.1.0-macOS-arm64.zip)
- [Windows x64 skin installer ZIP](https://github.com/nauticsoftware/NauticMixxx/releases/download/v1.1.0/NauticMixxx-1.1.0-Windows-x64-Skin.zip)
- [Rebuildable source archive](https://github.com/nauticsoftware/NauticMixxx/releases/download/v1.1.0/NauticMixxx-1.1.0-source.tar.gz)
- [SHA-256 checksums](https://github.com/nauticsoftware/NauticMixxx/releases/download/v1.1.0/SHA256SUMS.txt)

On macOS, open the DMG and drag `NauticMixxx.app` to Applications. The ZIP is an alternative download of the same app. This build is ad-hoc signed rather than Apple-notarized, so macOS may ask you to confirm its first launch. See the [English installation guide](docs/INSTALLATION-EN.md).

The published Windows 1.1 ZIP is a skin-only installer. It cannot provide the fixed 1.2 engine behavior. Build and test the native Windows package before distributing it; see the [build guide](docs/BUILDING.md).

The [v1.0.0 tag](https://github.com/nauticsoftware/NauticMixxx/tree/v1.0.0) remains available as an archive.

## Verify a download

After downloading the release files into one directory, run:

```bash
shasum -a 256 -c SHA256SUMS.txt
```

On Windows, use PowerShell's `Get-FileHash -Algorithm SHA256` and compare the result with `SHA256SUMS.txt`.

## Test or build

For a physical Inpulse 500 test, follow the [hardware test guide](docs/HARDWARE_TEST.md). The optional FLX6 browser mapping has been checked in software but has not yet been tested on physical DDJ-FLX6 hardware.

To validate the source checkout or build the native macOS app:

```bash
./scripts/validate-release.sh
./scripts/build-mixxx-rx3-macos.sh
```

The `patches/` directory contains changes against Mixxx 2.5.6. `controllers/`, `effects/`, `skins/` and `profile/` hold the NauticMixxx components; `scripts/` and `packaging/` contain build and release tooling. Downloadable binaries, the manifest and checksums are attached to [GitHub Releases](https://github.com/nauticsoftware/NauticMixxx/releases).

More documentation: [validation](docs/VALIDATION-1.1.md), [architecture](docs/ARCHITECTURE.md), [changelog](CHANGELOG.md), [contributing](CONTRIBUTING.md) and [release process](docs/RELEASING.md).

## License and trademarks

NauticMixxx components are released under GNU GPL v3. The Mixxx engine retains its GNU GPL v2-or-later terms and notices. See [LICENSE.md](LICENSE.md) and [third-party notices](THIRD_PARTY_NOTICES.md). NauticMixxx is not an official product of, or affiliated with, the trademark owners named in the [trademark notice](TRADEMARKS.md).
