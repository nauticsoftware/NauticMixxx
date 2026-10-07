# NauticMixxx 1.9.0 validation report

## macOS arm64

- Production Release bundle: 110 native tests passed, 0 failed, 11 optional
  external fixture/render tests skipped. Public-input audit, XML, ten controller
  JavaScript suites, controller presets, Windows installer/skin contracts and
  USB-only policy passed.
- Expanded control/GRID regression suite: 163 passed, 0 failed, 5 optional
  fixtures skipped. Final browser/table-state suite: 43 passed, 0 failed,
  1 optional performance render skipped. These overlapping suites are not additive.
- Native checks cover selected-deck input versus engine feedback, GRID actions,
  marker geometry, USB track policy, full-width facets, continuous divider pixels,
  adjacent columns and last-row scrolling. Qt renders cover normal and overflowing
  browser facets, centered pad dividers, BEAT JUMP corners and deck/BPM badges.
- Controller tests verify the exact 2000 ms GRID hold, encoder routing, short-press
  exit, rotation cancellation, transport controls, loops and browser navigation.
- Production ZIP-extracted and DMG-mounted bundles pass strict signature, version,
  canonical icon and isolated-test-profile exclusion checks. Finder displays the
  project icon. DMG integrity verification passed. Signing is ad hoc;
  Apple notarization is not provided.

## Windows x64

- Native Release build on windows-2022: 140 tests passed, 0 failed,
  6 optional fixtures skipped. All 27 source patch hashes match the
  release inputs. Application/installer identity and canonical icon validation passed.
- The actual NSIS EXE passed silent installation and uninstallation, English profile,
  USB-only settings, skin/controller/effects payload and user-profile preservation checks.
- [Windows build and installer evidence](https://github.com/nauticsoftware/NauticMixxx/actions/runs/37702640895).

## Public source and limitations

- [Source validation evidence](https://github.com/nauticsoftware/NauticMixxx/actions/runs/37702624002)
  covers implementation/packaging commit a4df3c531588a7c6331fd0334d92c07eb6ebb478.
- Public payloads exclude local research, graph caches, profiles, music and logs.
  Corresponding native sources, 27 patches, licenses and current release notes are included.
- Physical controller, touchscreen and target-machine audio/USB validation remains
  pending. Live macOS accessibility inspection returned AXError.cannotComplete;
  automated native widget checks and renders passed.
- RELATED KEY is a visible placeholder. MATCHING computes compatible keys and a
  six-percent BPM window; saved Rekordbox matching pairs are not imported.
- GRID Reset restores the entry snapshot for the track in that session. Temporary
  USB grid changes are not exported. Deck wave cadence is approximate, not a
  measured Pioneer hardware cadence. No native Linux 1.9 build is claimed.
