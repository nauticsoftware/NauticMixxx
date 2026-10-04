# NauticMixxx 1.8.0 — browser playback and deck display

- Validation: 103 native tests passed on macOS and 133 on Windows; actual EXE installation/uninstallation verified.
- Browser rows use bright green while playing and darker green after 60 seconds of actual playback in the session. Seek distance does not count.
- PLAY replaces the note during playback; H marks lossless files, including ALAC detection in M4A. Sidebar category icons are drawn as vectors.
- Compact DECK/number spacing and growing, blinking vector waves only during PLAY. The 800 ms cycle is approximate; no exact Pioneer cadence is claimed.
- Overview progress is white behind the PLAYHEAD and gray ahead. MASTER reaches the right inner edge with centered text; BPM labels move left in both views.
- Matching STATUS padding and a fix for the reported controller preference lifetime crash.
- New profiles default to English. Packages use the NauticMixxx icon. macOS builds are ad-hoc signed, not notarized.
- First-install microphone permission crash reproduction and physical Pioneer timing comparison remain pending.

# NauticMixxx 1.7.0 — waveforms and overview divisions

BLUE, RGB and 3Band now apply throughout Performance, Browser, overviews and
track-list previews. Preview caches follow the chosen waveform style.

- Main and overview playheads are 2 pixels wide: red stopped, white playing.
- CUE and loop starts use small white triangles in front of the playhead.
  Loop shading remains; thick boundaries, boxes and the end marker are removed.
- HOT CUE squares move outward over the beat ticks, leaving a short tick visible.
  Existing HOT CUE colors remain unchanged.
- Overviews have a thicker white baseline, wider spacing and larger HOT CUEs.
  B overlaps A, C overlaps B, and so on through H, regardless of time order.
- Preferences → Waveforms → WAVEFORM DIVISIONS selects TIME SCALE (30-second
  marks) or PHRASE (song-structure blocks exported by Rekordbox). Missing phrase
  analysis leaves an empty strip. No audio analysis or USB writes are performed.
- Removes the cyan bar count beside the main playhead.
- Includes the approved Hercules Inpulse 500 jog rim adjustment and fixes a
  preference-page lifetime crash after controller rescanning.

New profiles default to English and all packages use NauticMixxx's own icon.
Physical equivalence of the jog behavior to XDJ/CDJ hardware remains unmeasured.
macOS is ad-hoc signed without Apple notarization; Windows is unsigned.
See TEST_REPORT.md for validation and platform status.

---

# NauticMixxx 1.6.0 — update notice at startup

NauticMixxx checks the latest stable public GitHub release once when the app starts. If a newer version is available, an English notice shows the installed and available versions.

- **Download** opens the official release page for manual installation.
- **Later** closes the notice for the current session.
- **Skip this version** remembers that version and only alerts again for a later release.
- The check runs asynchronously with a five-second limit. Offline, invalid and failed responses stay silent. Playback or Auto DJ cancels the notice; there are no checks during the session.
- New profiles retain `en_US`, the project icon and all v1.5.1 audio fixes.

Install v1.6 manually to enable notices for future releases. Older versions do not gain this feature automatically. No Apple developer account or Apple credentials are required.

Downloads include the native macOS Apple Silicon app (DMG or ZIP) and the native Windows x64 installer. macOS is ad-hoc signed and not Apple-notarized; Windows is unsigned. Use the documented first-launch steps and verify `SHA256SUMS.txt`. Linux build recipes are included; no v1.6 Linux binary is published here.

See [update behavior](docs/UPDATES-1.6.md), [installation guide](docs/INSTALLATION-EN.md) and `TEST_REPORT.md` for validation and remaining hardware limits.

---

# NauticMixxx 1.5.1 — audio output reconfiguration freeze fix

Fixes freezing when accepting or applying audio changes with M2 main output, DJControl Inpulse 500 channels 3–4 for headphones and channels 1–2 for booth.

- Stream completion uses a mutex-free atomic signal.
- The engine clock stops before secondary streams close and starts after they are ready.
- Experimental secondary blocking streams are aborted without waiting for a callback that cannot run on those streams.
- New profiles retain the English default and all packages retain the NauticMixxx icon.

See TEST_REPORT.md for validation and platform availability. The macOS build is ad-hoc signed and is not Apple-notarized.

# NauticMixxx 1.5.0 — public release

- **English by default:** new app configurations and installation profiles use `en_US`, independently of the OS language. Explicit language choices still apply.
- **Leave BROWSE without loading:** on Inpulse 500, hold ASSISTANT for 600 ms to return to PERFORMANCE. A tap opens SOURCE on release. SHIFT + ASSISTANT keeps its side-panel action; holding BROWSE still enters GRID.
- **Inpulse jog rim:** slow-turn messages have a stronger initial response and fast-turn messages are compressed. Defaults are slow 1.9, fast 2.4 and sensitivity 1.0. Scratch, pause, SHIFT, loops and grid use their existing paths.
- **Seven complete controller presets:** DDJ-400, DDJ-SX, DDJ-SX2, DDJ-SX3, DDJ-WeGO3, DDJ-FLX4 and Roland DJ-505 offer mouse-free RX3 source/category/track navigation and a VIEW gesture to leave BROWSE. The native app selects presets by MIDI model name.
- **SX3 is experimental:** the community fragment is reconstructed over its SX2 base; LEDs, pads and channels need hardware confirmation.

Read the [controller behavior guide](docs/CONTROLLERS-RX3-1.5-EN.md) for every button and reassigned function, and the [jog calibration guide](docs/JOG-CALIBRATION-1.5-EN.md) for the curve, Pioneer comparison and physical test procedure. Pioneer/Roland jog sensitivity remains supplied by each original mapping.

Automated script/XML checks cover navigation, preserved mappings, gesture timing and the jog curve. Physical tests on these seven controllers and numerical jog equivalence to XDJ/CDJ are pending. See TEST_REPORT.md for build evidence.

---

# NauticMixxx 1.4.0 — 2026-10-03

## Rekordbox MP3 timing on macOS

- Fixes the coordinate mismatch between exported Rekordbox timestamps and
  MP3 audio trimmed by CoreAudio. Beatgrids, CUEs, Hot Cues, loops and ANLZ
  waveforms now use the same decoded audio timeline.
- Reads the tagged encoder delay and applies compensation only when the
  opened CoreAudio decoder confirms the expected sample rate and audible
  length. Untagged or unconfirmed files and other decoders remain unchanged.
- On the supplied METRONOME export, the approximately 25 ms / 23 ms MP3
  offsets fell to a maximum grid-to-kick error below 0.6 ms across 64 beats
  at both 44.1 and 48 kHz. Eight repeated CUE-position seeks returned stable
  PCM. WAV timestamps remain exactly as exported.
- Preserves the 150-column/s ANLZ detail clock without stretching encoder
  padding across the waveform. Original USB audio and analysis files are
  never rewritten.

## Interface and controller updates

- Centres the startup NauticMixxx logo across the full window, including
  the BEAT FX panel width. Checked at normal and enlarged window sizes.
- Retains the Inpulse 500 startup fix and the community DDJ-FLX4 RX3 browser
  mapping introduced in 1.3.1.
- Development test bundles use isolated profiles. The public macOS release
  keeps the existing profile location for updates.

## Packages and validation

Native packages are provided for macOS Apple Silicon and Windows x64,
with the NauticMixxx icon, source archives and SHA-256 checksums.
Windows validation passed 93 native tests and actual EXE installation and
uninstallation; four optional external fixtures were skipped. Results are
recorded in TEST_REPORT.md.

The timing measurements above are for macOS CoreAudio, not a Windows MP3
measurement. PQTZ has integer-millisecond precision; the supplied 44.1 kHz
WAV already exports its first kick beat at 999 ms while its CUE is 1000 ms.
The app preserves that source data. Physical CUE output, output-device
latency and Windows hardware comparison with Rekordbox were not measured.
The bundled FFmpeg 6 provider could not open the two supplied MP3 fixtures;
the successful MP3 timing checks used CoreAudio.

The macOS app is ad hoc signed and not notarized. The Windows installer is
unsigned. See the installation guides for first-launch instructions and
[the timing report](docs/BEATGRID-TIMING-1.4.md) for scope and measurements.

---

# NauticMixxx 1.3.1 — 2026-10-02

This update fixes a startup error that could disable the **Hercules DJControl Inpulse 500** mapping. The side-panel state is now read when its button is pressed, after the skin is available. The fix was checked with a connected Inpulse 500 on macOS.

It also includes the community-contributed **DDJ-FLX4** mapping with RX3 browser controls. Its bindings passed automated tests; physical FLX4 testing is still pending. Updated native packages are provided for macOS Apple Silicon and Windows x64.

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
