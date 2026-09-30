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

## macOS download

The Apple Silicon (`arm64`) DMG contains the app and an Applications shortcut;
installation and controller guides remain in the alternative ZIP and source
package. The app is signed ad hoc and is not notarized, so macOS may request
confirmation on first launch. The local validation passed 60 native tests;
five optional external-fixture tests were skipped. Physical Inpulse 500 and
Rekordbox USB checks, and the native Windows build, remain pending.

---

# NauticMixxx 1.1.0

The RX3-style display now fills the 1280×800 reference window, with refined spacing around the waveforms and STATUS / BEAT FX controls.

The macOS Apple Silicon release contains the native NauticMixxx app and updated skin. The app is ad-hoc signed, so macOS may ask you to confirm opening it. The Windows x64 release is a skin-only installer: extract the ZIP and run `INSTALL-WINDOWS.bat`. It updates an existing NauticMixxx 1.0 skin in place, or downloads official Mixxx 2.5.6 if needed. Run `UNINSTALL-WINDOWS.bat` for complete NauticMixxx removal. The Windows ZIP does not contain a new native NauticMixxx executable, so native RX3 engine features require an existing compatible app.

Installer and configuration messages are in English. See the [installation instructions](https://github.com/nauticsoftware/NauticMixxx/blob/v1.1.0/docs/INSTALLATION-EN.md).

An optional **DDJ-FLX6 browser-only** MIDI preset is included. VIEW toggles BROWSE, the BROWSE knob moves and enters, BACK returns, SHIFT + VIEW opens SOURCE on the native build, and LOAD 1/2 loads tracks. This preset does not map the rest of the controller and is not selected automatically. See the [DDJ-FLX6 guide](https://github.com/nauticsoftware/NauticMixxx/blob/v1.1.0/docs/DDJ-FLX6-EN.md) before using it. It has been checked in software; physical FLX6 testing is pending.
