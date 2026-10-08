# NauticMixxx 1.9.1 validation report

## macOS arm64

- Current native Release build: 139 native tests passed, 0 failed, 12 optional
  external audio/USB/render fixtures skipped. These tests cover updater state,
  Ed25519 verification, selected-deck stability with both decks generating engine
  feedback, wheel-only shared zoom, GRID routing, thin numeric fonts, browser state
  and USB capability policy.
- Real sandboxed, ad-hoc signed Sparkle installation probes passed both immediate
  install/relaunch and background install on quit, from 1.9.0 to 1.9.1, with a
  signed local feed and signed payload. Both preserved the profile sentinel.
  The background probe was manually relaunched after installation, as intended.
  Final probes include the branded installer helper. Fixtures execute outside
  Desktop to avoid granting macOS folder access solely for testing.
- Native renders verify loaded REMAIN, pitch and BPM values using the thin
  reference faces. Raw six-percent range highlights green; higher ranges restore red.
- Live app inspection verified fullscreen expansion to 2560×1440 and return to
  the frameless 1280×800 window. The STATUS inset is visible on all four sides.
  Finder displays the project icon on the final preview 4; generated application
  and embedded Updater.app icon bytes match the canonical icon. The final DMG
  passes checksum, version, profile exclusion and strict nested-signature checks.
- Public-input audit, XML, controller JavaScript suites, controller preset tests,
  Windows installer/skin contracts and USB-only policy passed.

## Windows x64

- Final 1.9.1 native build and actual NSIS install/upgrade/uninstall passed:
  153 native tests passed, 0 failed, 7 optional external fixtures/render exports
  skipped. Selected-deck, shared-wheel and thin-font regression tests passed.
  The installer, application and helper contain the canonical project icon;
  all 28 native patch hashes match the local prepared source.
- Silent /UPDATE preserves user mixxx.cfg and effects.xml byte for byte. Fresh
  installs default to English and USB-only operation. Uninstall preserves profiles.
- [Initial updater build and installer evidence](https://github.com/nauticsoftware/NauticMixxx/actions/runs/37712144630).
- [Final native build and installer evidence](https://github.com/nauticsoftware/NauticMixxx/actions/runs/37714289047).

## Scope and limitations

- Version 1.9.0 remains the public stable fallback. Version 1.9.1 is prepared on a
  separate branch; it is not published as a release. Source inputs contain 28
  reproducible native patches, current English release notes and third-party licenses.
- Release signing keys stay in macOS Keychain. Public packages contain only the
  verification key. No paid update service, Developer ID or Windows certificate is used.
  macOS signing is ad hoc and is not notarized.
- Windows manifest/artifact checks and installer upgrade are tested separately;
  a live Windows update against a future GitHub release still needs a target-machine check.
- Physical controller, touchscreen and target-machine audio/USB checks remain pending.
  Optional METRONOME/real USB fixtures and the Hercules audio hardware fixture are unavailable.
- RELATED KEY remains a visible placeholder. GRID Reset restores the entry snapshot;
  temporary grid changes are not exported to USB. Playback-wave cadence is approximate.
- A manual installation is needed once when upgrading from 1.9.0 to acquire the updater.
  Linux retains the existing manual download fallback.
