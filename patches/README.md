# NauticMixxx native patches

## 0020 — Waveform ecosystem and overview divisions for v1.7

Unifies BLUE/RGB/3Band rendering across Performance, Browser and track previews.
Updates CUE/loop triangles, marker layering and HOT CUE placement; removes the
cyan bar countdown. Overview divisions switch between 30-second TIME SCALE
marks and PHRASE blocks decoded from Rekordbox PSSI/PQTZ. Later HOT CUE letters
progressively overlap earlier ones. Playheads remain red stopped and white
playing, with width 2 in the skin. Fixes retired controller preference-page
references and adds native regression tests. The Inpulse 500 rim calibration
and skin geometry are maintained in the overlay's controller and skin files.


## 0019 — Startup update notice for v1.6

Apply after 0001–0018. Adds one asynchronous GitHub latest-release request at
startup with a five-second deadline, strict stable version parsing and no
retries, redirects or background polling. The English notice offers Download
(the trusted NauticMixxx release page), Later and Skip this version.

The product version comes from nautic/VERSION in this workspace or the
NAUTICMIX_VERSION CMake argument in reconstructed source trees. Mixxx's own
engine version remains unchanged for configuration/database compatibility.
Playback or Auto DJ cancels the check and dismisses an already open notice.
Malformed feeds, drafts, prereleases, HTTP/network errors, oversized responses
and late responses are silently ignored. StartupUpdateCheckerTest covers the
version policy and real HTTP transport against a local deterministic server.

## 0017 — English by default

New configurations use `en_US` independently of the operating-system language.
Explicit user language preferences and command-line overrides still apply.
Installation profiles also set `Locale en_US`.

## 0016 — Selección automática de controladores RX3 para v1.5

Prioriza los presets completos de DDJ-400, DDJ-SX, DDJ-SX2, DDJ-SX3,
DDJ-WeGO3, DDJ-FLX4 y Roland DJ-505 cuando el nombre del puerto MIDI contiene
el modelo. Conserva la búsqueda normal de mappings si falta el preset RX3.
La detección y los mensajes de navegación requieren prueba con cada equipo.

## 0015 — Timing del decodificador Rekordbox para v1.4

Aplica después de 0014. Proyecta grid, cues, loops y waveforms sobre la
coordenada del PCM abierto. Compensa el inicio de MP3 únicamente cuando
CoreAudio y el tag Info/Xing confirman trimming. Conserva los WAV y el
export original. Incluye pruebas METRONOME y arranque aislado para bundles
macOS de test con plantilla interna. Evidencia y límites en
[BEATGRID-TIMING-1.4.md](../docs/BEATGRID-TIMING-1.4.md).

## 0014 — Categorías exportadas y lista RX3 expandida para v1.3

Aplica después de 0013. Lee las categorías visibles y su orden de las tablas
16/17 de `export.pdb` y los asocia a la sesión temporal del USB. SOURCE deja
la selección en la barra de categorías; terminar de preparar el dispositivo
no abre PLAYLIST. TRACK, PLAYLIST y las agrupaciones de metadatos admitidas
requieren confirmación para entrar, y BACK restaura el nivel anterior. Las
listas finales ocultan la columna intermedia y muestran PREVIEW, TRACK,
ARTIST, BPM y GENRE. MATCHING y FOLDER exportadas muestran un panel
«COMING SOON»; REC queda para una versión futura. El USB permanece en sólo
lectura.

## 0013 — Preparación automática de USB Rekordbox para v1.3

Aplica después de 0001–0012. Inicia la detección de volúmenes y la lectura de
catálogos al arrancar y al conectar un USB, sin depender de SOURCE. Conserva
autorizaciones macOS para unidades desconectadas, prepara cada sesión en segundo
plano, rechaza resultados de conexiones anteriores y muestra el estado real del
dispositivo en la skin. Elimina la vista HTML original de Rekordbox y el mensaje
que pedía reabrir SOURCE. El candidato macOS v1.3 se comprobó con un USB
Rekordbox real; la conexión en caliente sigue pendiente de prueba física.

## 0012 — NauticMixxx 1.2 USB preferences

Apply after 0001–0011. This patch enforces Rekordbox USB operation on startup,
fixes the requested deck and waveform defaults, narrows waveform selection to
BLUE/RGB/3Band, and autoloads the RX3 Inpulse 500 mapping when present. It also
removes Mixxx's duplicate stock Inpulse 500 preset. The portable profile and
controller script live outside this native patch in `profile/` and `controllers/`.


`0001-rx3-waveform-edge-beat-grid.patch` applies to the Mixxx 2.5.6 tag. It adds two legacy-skin properties to both waveform backends:

- `DownbeatColor`: color used every four beats, anchored to the first beatgrid marker/downbeat.
- `BeatTickLength`: logical pixel length of the tick drawn from both waveform edges.

The same patch includes the two macOS ARM64 build fixes required by the official Mixxx 2.5 release dependency environment: explicit static `mpg123` linkage and quoting an application bundle name that contains spaces.

The shipped NauticMixxx build is configured with `AU_EFFECTS=OFF`, `QML=OFF`, `MACOS_BUNDLE=ON`, `MACOS_BUNDLE_NAME="NauticMixxx"`, `BUILD_TESTING=ON` and `CMAKE_BUILD_TYPE=Release`.

`0002-rekordbox-macos-sandbox-usb.patch` adds Rekordbox database discovery for
both `PIONEER` and `.PIONEER`, plus a security-scoped directory picker and
persistent bookmark fallback for sandboxed macOS builds. The packaged app is
also signed with `com.apple.security.files.removable-volumes.read-write`, so a
normally mounted Rekordbox USB is discovered automatically.

`0003-rekordbox-macos-tcc-and-retry.patch` fixes the remaining macOS TCC
boundary: metadata-only discovery of `export.pdb` is not treated as proof that
its bytes are readable. Mixxx asks the user to select the USB root once, keeps
the security-scoped bookmark active, and only marks a device as parsed after a
successful transaction so failed imports can be retried.


## 0004 — RX3 0.12.0 visual canvas

`0004-rx3-reference-scaling-readouts.patch` applies after 0001–0003. All changes are opt-in; skins without the new properties retain their existing display behavior.

- Root `<ReferenceSize>1280,800</ReferenceSize>` scales the live legacy widget tree uniformly and centers the canvas. It rescales QSS lengths and font metrics from immutable reference values to avoid cumulative rounding. The waveform viewer forwards scaling to its renderer so its visible time span stays constant, including OpenGL renderers.
- `<Rx3Format>deck</Rx3Format>` on NumberPos renders `mm:ss.mmm` with smaller milliseconds; `transport` renders remaining `hh:mm:ss`; `bars` follows the actual beat grid and refreshes after analysis/grid changes even while paused.
- `<Rx3Format>bpm</Rx3Format>` on Number/NumberBpm reduces the decimal suffix; `beat-ms` displays the duration of one beat from BPM (floored, as in the supplied reference).
- `<Rx3Badge>true</Rx3Badge>` on HotcueButton paints a small colored badge inside the full native clickable cell. A–H use the fixed RX3 palette `#FF376F`, `#45ACDB`, `#7DC13D`, `#AA72FF`, `#30D26E`, `#E0641B`, `#305AFF`, `#C3AF04`.

### Reconstruct on macOS ARM64

Requirements: Xcode command-line tools, CMake, Ninja, Python 3, Git, curl and unzip. Run from the project root:

```sh
sh scripts/build-mixxx-rx3-macos.sh
```

The script downloads official Mixxx 2.5.6 source and the official 2.5 ARM64 dependency environment, verifies both SHA-256 digests, applies all seventeen patches, builds the app and runs the RX3 tests. It writes a signed bundle to `tmp/mixxx-native-rebuild/stage/NauticMixxx.app`; it does not install or modify controller settings. Use `RX3_BUILD_ROOT` to choose another build/cache directory and `RX3_BUILD_JOBS` to adjust parallelism. Allow roughly 8 GB of free disk space.

## Patch 0009: public product identity

`0009-nauticmixxx-product-branding.patch` changes the application name reported
by the engine to NauticMixxx. The bundle name, icon and 1.0.0 release metadata
are supplied by the build and packaging scripts; Mixxx attribution remains in
About, licenses and source notices.

The recovered working source is currently in `tmp/mixxx-native/mixxx-2.5.6`, with dependencies in `tmp/mixxx-native/buildenv` and build output in `tmp/mixxx-native/build`. The downloadable source archive SHA-256 is `9cfc9025d50d2511767ee52a07b8854f75c581f0585197d043bc219fcf9f9050`; the dependency ZIP SHA-256 is `b76685e77f681baf8fdc5037297b0f16d323a405d09ce276d8844304530278e1`.

Validation covers formatting edge cases, beat-map changes, repeated 1280×800 → 1920×1080 → 1024×640 resizes without widget recreation, and existing beat/cue/button behavior. GUI validation uses an isolated profile with a synthetic 120 BPM track, checks STATUS/BEAT FX, full-cell hot cue clicks, and window maximize/restore. Controller hardware is not exercised by these visual tests.


## 0005 — RX3 0.13.0 playback display state

Apply `0005-rx3-master-loop-visual-state.patch` after 0004. `<Rx3DisplayState>true</Rx3DisplayState>` creates a skin-owned presentation model before parsing widget bindings. It publishes `[RX3Display],master1`, `master2` and `master_bpm`. Playing decks take precedence over paused decks; the current playing master stays selected when the other starts, and stopping it hands off to the other playing deck. An explicit Mixxx sync leader is honored while playing. With no decks playing, the last loaded master remains selected. It never writes transport, sync or BPM controls. Old MASTER is cleared before the new one is set.

`<Rx3Format>loop</Rx3Format>` renders loop sizes including reciprocal fractions. Floating-point validation uses Mixxx's FpClassify wrappers so release fast-math optimization cannot discard NaN checks. Skin bindings use `beatloop_size`/`loop_enabled`, fixed quantize slots, played overview shading and white playheads. Controller mappings are unchanged.

0.13.0 validation: 69 native tests plus GUI checks of two playing decks, master handoff, quantize disappearance with stable CONTINUE position, played shading, solid white cursor, active 2-beat / 1/2-beat loops and inactive blank loop readout. The official-Windows 0.12.0 compatibility ZIP remains a separate, older package and does not include this native model.


## 0006 — RX3 0.15.1 browser and hot cues

`0006-rx3-browser-grid-hotcue.patch` applies after 0001–0005. The new `Rx3Browser` skin node wraps the existing Mixxx library and sidebar. Its original SOURCE supported both the PC collection and Rekordbox devices; patch 0010 deliberately removes the PC source. Tall track rows, stored waveform summaries, artwork, row numbers, TRACK/ARTIST columns, category/folder navigation and search remain available for the selected USB. `[RX3Browser]` event controls connect the Inpulse encoder to this native view. USB TRACK/PLAYLIST retain the selected device. No on-screen LOAD buttons are added.

`Rx3Hotcue` is an opt-in DefaultMark property: A–H waveform badges use the fixed RX3 A–H palette documented above, appear at both waveform edges and leave the signal unobstructed. The STATUS hot-cue cells use the same palette. `Rx3Overview` draws a unipolar overview with paired badges. `Rx3Format=browse` displays remaining mm:ss. Other skins keep their legacy drawing behavior.

Preview reads use a bounded cache of stored analyses without opening cloud audio files during paint. Missing cover art failures are cached only for the RX3 browser. Unanalyzed tracks have no invented waveform preview. Rekordbox's existing backend does not expose the PC library's preview/artwork columns; this patch does not replace its parser or fabricate missing data.

Validation: 74 native regression tests, including paired badge rendering at pixel ratios 1 and 2; 60 mapping tests using the actual MIDI components; 22 display state checks and AUTOLOOP, loop-adjust and Sound Color FX regression scripts. All six patches were applied successfully to a clean official 2.5.6 source archive. The physical controller still needs a hands-on VINYL ON/OFF check. QA discovered the mounted USB but its database import returned a parser exception; USB playlist contents were not verified.

This release needs the patched native runtime. The existing Windows 0.14.0 compatibility ZIP remains separate; it does not receive this native browser. Windows native 0.15.1 has build recipes, but no Windows binary was built or tested on this Mac.

0.15.1 final polish: measured three-band overview colors now match the browser previews (blue bass, orange mids, white highs), edge badges remain fully visible, category icons use separate large icon/small label sizes, INFO shows selected-track metadata, and the footer deck badge keeps its compact width. Two additional pixel tests verify band order and silence.


## 0007 — RX3 0.16.0 navigation and deck states

Apply after 0001–0006. Native BROWSE remembers the logical focus on hide and restores it on open without clearing the current search or track selection. The controller no longer forces the folder tree when reopening; the BEAT GRID hold threshold is 2000 ms, including the release-time fallback.

The RX3 skin opts out of pre/post-roll decorations with `ShowPreroll=false` in both waveform backends, and the shader renderer's marker countdown with `ShowUntilNextMark=false`. Other skins retain their defaults. Assigned RX3 hotcue pads always use black letters; empty pads use white. RX3 Overview paints red “Not Loaded.” for empty decks, leaves a four-reference-pixel gap below the signal, then draws a two-pixel white baseline. Browser decks use a full-height overview beside the time column and a compact BPM box; empty BPM readouts are hidden.

For the XDJ_RX3_Mixxx skin only, windowed startup restores a 1280×800 logical-pixel canvas. Closing in fullscreen persists that state; reopening keeps fullscreen and proportional reference scaling. The normal Mixxx behavior for other skins is unchanged. Physical screen dimensions quoted as 34:21 do not override the explicitly requested 1280×800 pixel canvas (16:10).

Validation: 75 native tests, including dark/bright assigned pad colors and empty lettering; 63 controller tests, including the 1999/2000 ms boundary and reopening without folder-focus writes; existing display, loop and Sound Color FX regressions. Native QA checked browser layout, empty decks, removal of decorative triangles, and fullscreen close/reopen. Startup logs report the reference canvas size.


## 0008 — Safe USB library state restoration

Apply after 0001–0007. Library view state now stores row and column numbers rather than live `QModelIndex` objects. Reopening the same Rekordbox USB can rebuild the source data behind an existing proxy model; cached indexes then retain invalid internal pointers and previously caused an `EXC_BAD_ACCESS` in `QSortFilterProxyModel::parent()` while restoring the selection. The view now validates the active model, reconstructs fresh indexes, skips rows that no longer exist and preserves the current row/column when possible.

Validation includes a regression test that saves a selection, resets and repopulates the source behind a `QSortFilterProxyModel`, then restores the same state key. The RX3 and Rekordbox USB suites continue to pass.

## 0010 — Rekordbox USB-only operation

Apply after 0001–0009. `[Library] UsbOnlyMode=1` suppresses the first-run music
directory chooser, disables automatic and manual local scans, rejects attempts
to add local directories and disables the corresponding preference controls.
The RX3 browser opens on SOURCE, removes SOFTWARE CONTROL and exposes only
detected Rekordbox devices with TRACK and PLAYLIST navigation. The internal
database remains available to the engine for transient state and history, but
is not a navigable music source.

This patch also versions the advanced Rekordbox runtime that previously existed
only in the corresponding-source tree: direct PDB/ANLZ catalog access, imported
waveforms and strict track capability policies. USB-backed tracks may be loaded
and played, but they cannot be persisted into the local collection, exported,
rewritten or passed to local analysis jobs.


## 0011 — RX3 1.1 display geometry and playhead

Apply after 0001–0010. `ReferenceFill=true` makes the live canvas fill its
viewport while fonts and fixed dimensions retain uniform reference scaling.
Flexible waveform/layout regions absorb the remaining width. Without this
opt-in, `ReferenceSize` keeps its original centered aspect ratio behavior.

`PlayPosWidth` specifies a width of 1–4 reference pixels (default 1). Both
waveform backends and overview cursors use it; the RX3 skin selects 2 and
`PlayPosColor=#ff0000`. Resizing preserves the reference width. The skin aligns
the lower waveform edge with the STATUS / BEAT FX panel and leaves a ten-pixel
gap above the mode strip at 1280×800.

The regression suite covers fill at matching and different aspect ratios,
resizes with an unchanged scale factor, widget/control identity, legacy
letterboxing and invalid/missing cursor width values. The patch also carries
an existing test sampling-coordinate correction from the working source so
reconstructed and working tests match.

## 0018 — Audio reconfiguration deadlock

Apply after 0001–0017. Replaces the PortAudio finished callback mutex with a
lock-free atomic completion signal. Blocking secondary streams skip the callback
handshake and use Pa_AbortStream. SoundManager stops the clock device first and
starts it last so its callbacks cannot access secondary streams during teardown
or FIFO initialization.

StreamCompletionTest covers completion before/during wait, timeout, late/repeated
callbacks and reset. SoundReconfigurationHardwareTest.HerculesBoothWithM2Main is
opt-in with NAUTIC_AUDIO_HARDWARE_TEST=1 and requires real M2/Inpulse 500 devices.
Run it with an external process timeout. It alternates booth 1–2 off/on while
headphones 3–4 and M2 main remain configured, using all three synchronization
modes at 44.1 and 48 kHz.

## 0021 — Browser playback state and vector icons

Apply after 0001–0020. Tracks on either main deck are bright green (#01FF02)
with a vector PLAY indicator while playing, then dark green (#008A01) after
60 seconds of elapsed playback in one load, retained for the application session.
Pauses, replacement, preview decks and seek distance do not count. Tracking
continues when the browser is hidden and identities include the USB session.
The state is presentation-only and never mutates USB history or SQL play counts.

The note/H marker and sidebar categories use font-independent vector icons.
ALAC/AAC in M4A is distinguished asynchronously with TagLib audio properties.
The skin uses matching 2 px STATUS tab padding on all sides.

## 0022 — Controller preference teardown after device deletion

Apply after 0001–0021. Retains the actual openChanged connection handles and
disconnects them without dereferencing a fresh device list during teardown.
ControllerManager clears its device list before deleting enumerators, which
own those devices. This addresses the reported macOS 1.7.0 stack in
QObject::disconnect / DlgPrefControllers::destroyControllerWidgets.

## 0023 — Overview position progress

Apply after 0001–0022. The RX3 overview axis is gray ahead of the current
playhead and white behind it, including after a seek back. The rendering
helper is shared by PERFORMANCE and BROWSER. Tests cover start, end, seek,
invalid positions and both standard and Retina pixel ratios.

## 0024 — Animated deck playback badge

Apply after 0001–0023. Opt-in RX3 deck labels paint DECK and the numeral in a
compact fixed layout. Red/orange waves grow through three vector stages and
then disappear. Animation runs only with a loaded playing track and resets on
pause/unload. The approximate cadence is 200 ms per stage (800 ms per cycle),
independent of BPM; Pioneer does not document the exact animation period.
