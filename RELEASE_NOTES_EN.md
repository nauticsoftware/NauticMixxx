# NauticMixxx 1.3.0 — 2026-10-01

## Rekordbox USB browsing on macOS Apple Silicon and Windows x64

- Detects and prepares exported USB drives in the background at startup and
  when they are connected. SOURCE shows “READING…” and opens a drive only
  after its catalog, playlists and exported categories are ready.
- Shows visible categories in their Rekordbox export order. Highlighting a
  playlist previews its tracks on the right; ENTER or double click opens the
  full table. Folders preview their child playlists.
- The full table displays PREVIEW, TRACK, ARTIST, BPM and GENRE with compact
  text. MATCHING and FOLDER are marked “COMING SOON”.
- Tested with a real USB drive containing 1,133 songs, 6 playlists and 10
  categories. Forty focused catalog, playlist, Rekordbox database and display
  tests passed. Physical hot plug and controller checks remain pending.

The macOS arm64 app is ad hoc signed and not notarized. The native Windows x64
installer includes the 1.3.0 USB browsing changes and passed 78 native tests
plus silent installation and uninstallation checks. Physical controller and Rekordbox USB
checks on Windows remain pending. The app icon is generated from `branding/`.

---

# NauticMixxx 1.2.0 — 2026-09-30

## Waveforms

- Blue, RGB, and 3-Band detail and overview use the exported Rekordbox ANLZ
  data (PWV3/PWV5/PWV7 and PWAV/PWV4/PWV6). Blue and RGB also use decoded PCM
  to retain the signal's polarity and level. The USB export is read only.
- 3-Band is the initial style. The overview follows the selected style, and
  the second preference can either keep the colors fixed or let mixer EQs
  attenuate the corresponding bands.
- Beat ticks appear only above and below the waveform from its first audible
  sound. Red bar ticks extend two pixels farther outward than white ticks.
- The position readout stays on the waveform; the countdown to the next
  marker appears under the track key in each deck.
- Reference screenshots and quantitative comparisons are included in the
  calibration report. Pixel perfect matching has **not** been achieved.

## Playback and controllers

The native app starts in Rekordbox USB mode. Local library selection, scans,
analysis, ReplayGain, and waveform disk caching are disabled. Pioneer Cue,
fixed ±6% tempo, remaining time, Rubber Band Finer, visual waveform
normalization, and beat countdown are configured. New loops and hot loops
default to orange (`#FF8800`). The custom Hercules DJControl Inpulse 500 RX3
mapping is selected when the controller is found at startup. When no controller
is present, detection retries periodically. Hot plugging while another
controller is active requires a restart.

Skip silence uses an existing first-sound marker. Rekordbox USB tracks without
that marker start at the beginning because audio analysis is disabled.

## Windows x64 direct installer

Download and run `NauticMixxx-1.2.0-Windows-x64-Setup.exe` directly. The NSIS installer contains the native NauticMixxx application, the same icon artwork as macOS, the RX3 skin, Hercules Inpulse 500 and optional FLX6 browser mappings, four Sound Color FX chains, and the portable macOS preset values. The Windows application and Start menu entry are named NauticMixxx. No BAT, ZIP extraction, existing Mixxx install, or additional download is required.

Setup installs per user, keeps a separate profile, and leaves personal library data when uninstalled. Windows audio device and channel routing must be selected on each PC. The EXE is unsigned and may trigger a SmartScreen prompt. The Windows CI build runs native tests plus silent installation and uninstallation checks; physical controller and Rekordbox USB checks remain pending.

## macOS download

The Apple Silicon (`arm64`) DMG contains the app and an Applications shortcut;
installation and controller guides remain in the alternative ZIP and source
package. The app is signed ad hoc and is not notarized, so macOS may request
confirmation on first launch. The local validation passed 60 native tests;
five optional external-fixture tests were skipped. Physical Inpulse 500 and
Rekordbox USB checks remain pending.

---

# NauticMixxx 1.1.0

The RX3-style display now fills the 1280×800 reference window, with refined spacing around the waveforms and STATUS / BEAT FX controls.

The macOS Apple Silicon release contains the native NauticMixxx app and updated skin. The app is ad-hoc signed, so macOS may ask you to confirm opening it. The Windows x64 release is a skin-only installer: extract the ZIP and run `INSTALL-WINDOWS.bat`. It updates an existing NauticMixxx 1.0 skin in place, or downloads official Mixxx 2.5.6 if needed. Run `UNINSTALL-WINDOWS.bat` for complete NauticMixxx removal. The Windows ZIP does not contain a new native NauticMixxx executable, so native RX3 engine features require an existing compatible app.

Installer and configuration messages are in English. See the [installation instructions](https://github.com/nauticsoftware/NauticMixxx/blob/v1.1.0/docs/INSTALLATION-EN.md).

An optional **DDJ-FLX6 browser-only** MIDI preset is included. VIEW toggles BROWSE, the BROWSE knob moves and enters, BACK returns, SHIFT + VIEW opens SOURCE on the native build, and LOAD 1/2 loads tracks. This preset does not map the rest of the controller and is not selected automatically. See the [DDJ-FLX6 guide](https://github.com/nauticsoftware/NauticMixxx/blob/v1.1.0/docs/DDJ-FLX6-EN.md) before using it. It has been checked in software; physical FLX6 testing is pending.
