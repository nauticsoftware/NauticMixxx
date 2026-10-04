# NauticMixxx 1.8.0

Version 1.8.0 unifies waveform colors throughout Performance and Browser, refines
CUE/loop/HOT CUE markers and adds TIME SCALE / PHRASE overview divisions.
Playheads are 2 pixels wide, red stopped and white playing. See the
[waveform divisions guide](docs/WAVEFORM-DIVISIONS-1.7.md).
Available for macOS Apple Silicon and Windows x64.

![NauticMixxx2](branding/NauticMixxx2.png)
![NauticMixxx](branding/NauticMixxx_Home.png)
![NauticMixxx](branding/NauticMixxx_Performance.png)

NauticMixxx is an open-source community edition of Mixxx 2.5.6. It brings an XDJ-RX3-inspired two-deck display to Mixxx, with a dedicated Hercules DJControl Inpulse 500 mapping.

Version 1.2 fixes the USB Rekordbox workflow and performance preferences: Pioneer Cue, ±6% pitch, first-sound loading when a marker exists, remaining time, beat countdown, visual waveform normalization, highest-quality pitch-bend engine, and orange loop/hot-loop defaults. It disables local library scanning, audio analysis, ReplayGain and waveform disk caching. The waveform menu has BLUE, RGB and 3Band. The Hercules DJControl Inpulse 500 automatically uses the custom RX3 mapping when detected.

Version 1.3 detects authorized Rekordbox USB drives at startup and when connected. SOURCE waits until the exported catalog and categories are ready before opening the drive. Highlighting a playlist previews its tracks; pressing ENTER opens the full track table. The available categories follow their exported Rekordbox order. This release has been tested on macOS Apple Silicon with a real Rekordbox USB drive.

Version 1.4 corrects tagged Rekordbox MP3 timing when macOS CoreAudio confirms gapless trimming, keeping beatgrids, cues, loops and waveforms on the decoded audio timeline. It also centres the startup logo. METRONOME measurements reached less than 0.6 ms maximum MP3 grid-to-kick error at 44.1 and 48 kHz; physical audio comparison and Windows MP3 timing remain unmeasured. See the [timing report](docs/BEATGRID-TIMING-1.4.md).

Version 1.5.1 fixes the audio preferences freeze when adding Hercules booth output alongside M2 main output.

Version 1.5 adds mouse-free navigation presets for seven Pioneer/Roland models, a gentler Inpulse 500 jog rim curve, and a 600 ms ASSISTANT hold to leave BROWSE without loading. New app configurations default to English. Physical controller validation is still pending; read the [controller behavior guide](docs/CONTROLLERS-RX3-1.5-EN.md) and [jog calibration guide](docs/JOG-CALIBRATION-1.5-EN.md).

Version 1.8 adds playing/played browser colors, PLAY and lossless note markers, vector sidebar icons, an animated deck badge and overview progress. It also fixes the reported controller preference teardown crash. See the [v1.8 behavior notes](docs/BROWSER-PLAYBACK-1.8.md).

## Features

- Scalable PERFORMANCE, BROWSE and STATUS views with stacked waveforms, beatgrid, overviews and eight Hot Cues per deck.
- Rekordbox USB browsing and loading in the native NauticMixxx app. Its local music-folder browser and scanner are disabled.
- Hercules DJControl Inpulse 500 mapping with RX3-style browser and loop controls.
- Optional DDJ-FLX4 mapping with RX3 browser controls. Its bindings passed software validation; physical hardware validation is pending. See the [DDJ-FLX4 guide](docs/DDJ-FLX4-EN.md).
- v1.5 presets add mouse-free RX3 browsing for DDJ-400, DDJ-SX, DDJ-SX2, DDJ-SX3, DDJ-WeGO3 and Roland DJ-505; see the [controller guide](docs/CONTROLLERS-RX3-1.5-EN.md). Hardware validation is pending.
- Optional DDJ-FLX6 **browser-only** preset for VIEW, SOURCE, BROWSE, BACK and LOAD 1/2. It does not replace a full controller mapping; see the [DDJ-FLX6 guide](docs/DDJ-FLX6-EN.md).
- Four Sound Color FX, NauticMixxx branding, reproducible patches, tests and release checksums.

## Download and install

Download NauticMixxx 1.8.0 from the [release page](https://github.com/nauticsoftware/NauticMixxx/releases/tag/v1.8.0):

- [macOS Apple Silicon DMG](https://github.com/nauticsoftware/NauticMixxx/releases/download/v1.8.0/NauticMixxx-1.8.0-macOS-arm64.dmg)
- [Windows x64 installer](https://github.com/nauticsoftware/NauticMixxx/releases/download/v1.8.0/NauticMixxx-1.8.0-Windows-x64-Setup.exe)

The Windows installer includes the native NauticMixxx program, RX3 skin, controller mappings and effects. The app and profile are separate from official Mixxx. Uninstall from Windows Settings; personal settings remain in `%LOCALAPPDATA%\NauticMixxx`.

On macOS, open the DMG and drag `NauticMixxx.app` to Applications. This build is ad-hoc signed rather than Apple-notarized, so macOS may ask you to confirm its first launch. See the [English installation guide](docs/INSTALLATION-EN.md).

## Verify a download

After downloading the release files into one directory, run:

```bash
shasum -a 256 -c SHA256SUMS.txt
```

On Windows, use PowerShell's `Get-FileHash -Algorithm SHA256` and compare the result with `SHA256SUMS.txt`.

## Test or build

### Linux and Raspberry Pi

A free native build recipe is available for 64-bit Linux. Raspberry Pi 4 with
64-bit Raspberry Pi OS is an experimental target; physical GPU, audio and
controller testing is pending. Read the [Linux / Raspberry Pi guide](docs/LINUX-RASPBERRY-PI.md)
for dependencies, memory settings, troubleshooting and free GitHub Actions builds.

Native builds, RX3 tests and virtual GUI startup passed on
[Ubuntu 24.04 x86_64 and ARM64](https://github.com/nauticsoftware/NauticMixxx/actions/runs/37158960601)
and [Debian 12 ARM64](https://github.com/nauticsoftware/NauticMixxx/actions/runs/37159816188).
The Bookworm build uses Debian's userland; it still needs physical Pi testing.

```sh
./scripts/install-linux-build-deps.sh
RX3_BUILD_JOBS=1 ./scripts/build-mixxx-rx3-linux.sh
```

The script downloads the official Mixxx base and applies the NauticMixxx patches.
Compiling this overlay repository's root directly does not work. Linux artifacts
are distribution-specific test candidates, rather than universal Pi installers.

### macOS and controller tests

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
