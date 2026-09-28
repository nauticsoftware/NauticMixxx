# NauticMixxx 1.1.0

The RX3-style display now fills the 1280×800 reference window, with refined spacing around the waveforms and STATUS / BEAT FX controls. Beatgrid lines stop at the intended height, and the playback marker is red and slightly thicker.

The macOS Apple Silicon release contains the native NauticMixxx app and updated skin. The app is ad-hoc signed, so macOS may ask you to confirm opening it. The Windows x64 release is a skin-only installer: extract the ZIP and run `INSTALL-WINDOWS.bat`. It updates an existing NauticMixxx 1.0 skin in place, or downloads official Mixxx 2.5.6 if needed. Run `UNINSTALL-WINDOWS.bat` for complete NauticMixxx removal. The Windows ZIP does not contain a new native NauticMixxx executable, so native RX3 engine features require an existing compatible app.

Installer and configuration messages are in English. See the [installation instructions](https://github.com/nauticsoftware/NauticMixxx/blob/v1.1.0/docs/INSTALLATION-EN.md).

An optional **DDJ-FLX6 browser-only** MIDI preset is included. VIEW toggles BROWSE, the BROWSE knob moves and enters, BACK returns, SHIFT + VIEW opens SOURCE on the native build, and LOAD 1/2 loads tracks. This preset does not map the rest of the controller and is not selected automatically. See the [DDJ-FLX6 guide](https://github.com/nauticsoftware/NauticMixxx/blob/v1.1.0/docs/DDJ-FLX6-EN.md) before using it. It has been checked in software; physical FLX6 testing is pending.
