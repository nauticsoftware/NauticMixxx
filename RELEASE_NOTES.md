# NauticMixxx 1.9.1 — Integrated updates and display corrections

- Adds Download and Install and Download in Background. Background downloads are installed after the app closes; playback and Auto DJ prevent an immediate restart.
- Future background downloads are optional and disabled by default. The Updates menu can change the preference and show update status.
- macOS uses Sparkle 2.10.0 with signed feeds and Ed25519-signed update packages. Windows verifies a signed manifest and installer, then waits for the audio process to exit before running the per-user installer.
- Integrated Windows upgrades preserve the existing profile and effects configuration. New profiles continue to start in English.
- Updates use GitHub Releases and a project signing key; no paid update service, Apple Developer ID or paid certificate is required. Builds remain ad-hoc signed on macOS, so operating-system origin warnings can still appear.
- Corrects the black inset around the active STATUS / BEAT FX button.
- GRID turns ZOOM gray; leaving GRID restores the cyan ZOOM outline. GRID tools have separate buttons with four-pixel black gaps. STATUS pad pages share the same title and upper button baseline, including GRID.
- Hercules Inpulse 500 refreshes all pad LEDs after track loading or unloading, including restored Rekordbox hot cues, without changing cue data or the active pad mode.
- Uses #18FC00 only for the 6% pitch range and #F84418 for higher ranges. The badge follows the raw range value, including changes made in preferences.
- Uses #BF3413 for A HOT CUE and #F87020 for MASTER. Performance readout typography follows the supplied reference.
- Selected-deck focus stays on the last user interaction while both decks play. Engine rate, position, metering and synchronization feedback cannot steal GRID selection.
- Mouse wheel and trackpad gestures over either main waveform adjust the same zoom on both decks, including with modifier keys, without changing playback, pitch or GRID.
- QUANTIZE text and its active value use the A.HOT CUE accent (#BF3413).
- Fullscreen releases the windowed size limit so the skin fills the display; returning to windowed mode restores 1280×800 on macOS.
- Version 1.9.0 remains the stable public fallback. Version 1.9.1 is prepared and is not yet published. Installing 1.9.1 from 1.9.0 requires one final manual installation before integrated updates become available.
