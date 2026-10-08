# NauticMixxx 1.9.1 — Integrated updates and display corrections

- Adds Download and Install and Download in Background. Background downloads are installed after the app closes; playback and Auto DJ prevent an immediate restart.
- Future background downloads are optional and disabled by default. The Updates menu can change the preference and show update status.
- macOS uses Sparkle 2.10.0 with signed feeds and Ed25519-signed update packages. Windows verifies a signed manifest and installer, then waits for the audio process to exit before running the per-user installer.
- Integrated Windows upgrades preserve the existing profile and effects configuration. New profiles continue to start in English.
- Updates use GitHub Releases and a project signing key; no paid update service, Apple Developer ID or paid certificate is required. Builds remain ad-hoc signed on macOS, so operating-system origin warnings can still appear.
- Corrects the black inset around the active STATUS / BEAT FX button.
- Uses #18FC00 only for the 6% pitch range and #F84418 for higher ranges. The badge follows the raw range value, including changes made in preferences.
- Uses #BF3413 for A HOT CUE and #F87020 for MASTER. Performance readout typography follows the supplied reference.
- Fullscreen releases the windowed size limit so the skin fills the display; returning to windowed mode restores 1280×800 on macOS.
- Version 1.9.0 remains the stable public fallback. Version 1.9.1 is being prepared and is not yet published. Installing 1.9.1 from 1.9.0 requires one final manual installation before integrated updates become available.
