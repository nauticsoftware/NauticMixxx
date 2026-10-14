<p align="center">
  <img src="branding/readme/hero-2.0.svg" width="100%" alt="NauticMixxx 2.0 — Your USB. Your set.">
</p>

<p align="center">
  An open-source DJ workspace built around rekordbox USB exports.<br>
  Two decks. An RX3-inspired interface. Native macOS and Windows apps.
</p>

<p align="center">
  <a href="https://github.com/nauticsoftware/NauticMixxx/releases/tag/v2.0.0"><strong>Download 2.0.0</strong></a>
  &nbsp; · &nbsp;
  <a href="docs/releases/v2.0.0/RELEASE_NOTES.md">What's new</a>
  &nbsp; · &nbsp;
  <a href="#installation">Installation</a>
  &nbsp; · &nbsp;
  <a href="docs/RX3-WORKFLOW-2.0-EN.md">Workflow guide</a>
</p>

---

## Get NauticMixxx 2.0

| macOS | Windows | Mixxx Skin |
| :--- | :--- | :--- |
| **Apple Silicon · arm64** | **Windows 10 / 11 · x64** | **Standalone Skin** |
| [Download DMG](https://github.com/nauticsoftware/NauticMixxx/releases/download/v2.0.0/NauticMixxx-2.0.0-macOS-arm64.dmg) | [Download Installer](https://github.com/nauticsoftware/NauticMixxx/releases/download/v2.0.0/NauticMixxx-2.0.0-Windows-x64-Setup.exe) | [Download Skin ZIP](https://github.com/nauticsoftware/NauticMixxx/releases/download/v2.0.0/NauticMixxx-2.0.0-skin.zip) |
| macOS 11+ (Apple Silicon) | Windows 10/11 64-bit | Official Mixxx 2.5+ |

Existing users can update through the signed integrated updater. All new profiles start in English (`en_US`).

## Installation

### macOS (Apple Silicon)
1. Download [`NauticMixxx-2.0.0-macOS-arm64.dmg`](https://github.com/nauticsoftware/NauticMixxx/releases/download/v2.0.0/NauticMixxx-2.0.0-macOS-arm64.dmg).
2. Open the disk image and drag **NauticMixxx.app** into your `/Applications` folder.
3. **First-launch note (un-notarized community build)**: Because NauticMixxx is a free community build signed ad-hoc without Apple notarization, macOS Gatekeeper may block opening it with a double-click on first run. To open:
   - **Right-click** (or `Control`-click) `NauticMixxx.app` in `/Applications` and select **Open**.
   - Click **Open** in the confirmation dialog. Subsequent launches open normally.
4. On launch, grant permission to access external USB volumes when prompted so NauticMixxx can read your rekordbox USB drive.

### Windows (x64)
1. Download [`NauticMixxx-2.0.0-Windows-x64-Setup.exe`](https://github.com/nauticsoftware/NauticMixxx/releases/download/v2.0.0/NauticMixxx-2.0.0-Windows-x64-Setup.exe).
2. Run the setup executable. No prior Mixxx installation or manual profile setup is required.
3. If Windows SmartScreen displays a warning, click **More info** → **Run anyway**.
4. The installer preserves existing user libraries and configures the optimized RX3 profile automatically in `%LOCALAPPDATA%\NauticMixxx`.

### Verifying SHA-256 Checksums
Every official release publishes a [`SHA256SUMS.txt`](https://github.com/nauticsoftware/NauticMixxx/releases/download/v2.0.0/SHA256SUMS.txt) file. You can verify the integrity of your download:

- **macOS / Linux**:
  ```bash
  shasum -a 256 -c SHA256SUMS.txt --ignore-missing
  ```
- **Windows (PowerShell)**:
  ```powershell
  Get-FileHash NauticMixxx-2.0.0-Windows-x64-Setup.exe -Algorithm SHA256
  ```

## A clear view of your set

![NauticMixxx 2.0 PERFORMANCE view with both decks idle](branding/readme/performance-2.0.png)

<sub>PERFORMANCE · macOS capture of the 2.0 interface, with both decks idle.</sub>

## New in 2.0

**Your controls, together.** UTILITY brings deck, mixer, effects, browser, recording and display settings into one encoder-friendly menu. SHORTCUT keeps frequent adjustments close at hand.

**Effects with intent.** Four persistent Beat FX favorites, a contextual momentary X-PAD and refined beat/pitch selection. SLIP and active-loop Hot Cue behavior keep performance actions connected to the transport.

**Preparation that travels.** SOURCE MY SETTINGS, USB appearance preferences and explicit cue, loop, beatgrid, playlist and history saves. USB identity checks, atomic writes and recovery copies protect supported edits.

**Playback that stays aware.** Precise imported constant-tempo grids, persistent controller SYNC and cached emergency playback when a playing USB source disappears.

<details>
<summary><strong>Explore SHORTCUT and UTILITY</strong></summary>

<br>

![SHORTCUT panel in NauticMixxx 2.0](branding/readme/shortcut-2.0.png)

<sub>SHORTCUT · playback, jog response, waveform color and mixer settings.</sub>

<br><br>

![UTILITY panel in NauticMixxx 2.0](branding/readme/utility-2.0.png)

<sub>UTILITY · shared encoder navigation. These two panel images are native UI captures from isolated validation fixtures.</sub>

</details>

## Plug into your workflow

Prepare and export your USB in rekordbox, open NauticMixxx, then browse and load from SOURCE. The app reads exported USB libraries; its local-folder scanner is disabled.

The dedicated **Hercules DJControl Inpulse 500** mapping is joined by RX3 presets for **DDJ-FLX4, DDJ-400, DDJ-SX / SX2 / SX3, DDJ-WeGO3 and Roland DJ-505**. DDJ-FLX6 has an optional browser-only adapter. Read the [controller guide](docs/CONTROLLERS-RX3-1.5-EN.md) for each mapping's scope.

Physical controller and RX3 audio calibration remain pending. Link Export, registered MATCHING pairs and the complete RX3 effect catalogs are unfinished; the [workflow guide](docs/RX3-WORKFLOW-2.0-EN.md) records the current scope.

## Open source, verifiable releases

The release includes corresponding source, a package manifest, signed update feeds and [SHA-256 checksums](https://github.com/nauticsoftware/NauticMixxx/releases/download/v2.0.0/SHA256SUMS.txt). macOS and Windows native regression tests passed; Windows installation, upgrade and uninstallation were checked in [CI](https://github.com/nauticsoftware/NauticMixxx/actions/runs/38434558661). See the [test report](docs/releases/v2.0.0/TEST_REPORT.md).

[Build instructions](docs/BUILDING.md) · [Linux / Raspberry Pi experiments](docs/LINUX-RASPBERRY-PI.md) · [Contributing](CONTRIBUTING.md) · [Changelog](CHANGELOG.md) · [Report an issue](https://github.com/nauticsoftware/NauticMixxx/issues)

---

<sub>NauticMixxx is a community edition built on Mixxx 2.5.6. NauticMixxx components use GPL v3; the Mixxx engine retains GPL v2-or-later terms. [License](LICENSE.md) · [Third-party notices](THIRD_PARTY_NOTICES.md) · [Trademarks](TRADEMARKS.md). Independent from the hardware and software trademark owners named in those notices.</sub>
