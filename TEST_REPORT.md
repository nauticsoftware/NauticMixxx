# Informe de validación — NauticMixxx

## v1.8.0 — browser playback and deck display

- macOS ARM64 Release: 103 native tests passed, 0 failed, 10 optional external
  fixture tests skipped. Public input audit, Windows installer contracts,
  USB-only policy, XML and controller suites passed.
- Badge tests cover three growing vector stages, the blank stage, PLAY restart,
  immediate pause/unload hiding, compact text spacing and DPR 1 / 2.
- Overview progress covers start, end, seeks backward, out-of-range positions
  and NaN. Qt renders verify MASTER reaches the last inner header pixel, centered
  text and left BPM captions.
- Browser playback tests cover the 60-second threshold, pause, replacement,
  duplicate loads, USB session identity and ALAC/AAC distinction.
- 24 patches reproduce the engine changes from Mixxx 2.5.6.
- The badge cadence is approximate (200 ms per stage / 800 ms per cycle); no
  physical Pioneer cadence calibration is claimed. The first-install microphone
  permission crash sequence has not been reproduced after the lifetime fix.
- Windows native CI and public bundle validation are being prepared for this release.


## v1.7.0 — waveforms and overview divisions

- macOS arm64: 99 native tests passed, 0 failed, 9 optional external fixtures
  skipped. Controller, USB-only, XML and installer-input checks passed.
- Seven metadata tests also passed after fixing Windows near/far macro-name
  conflicts in their fixtures.
- Tested PSSI plain/masked data, variable-tempo phrase boundaries, decoder offset,
  malformed/truncated records, 30-second ticks, missing analysis and progressive
  A→H overlap at 1×/2× density. Read actual USB phrase analysis without writes.
- Verified the selector and rendered PHRASE strip with a real USB track in the
  macOS test app; own icon checked inside the bundle and visually in Finder.
- Main playhead reduced to 2 pixels at the maintainer's request, matching the
  overview. The change is in the skin and does not modify the engine binary.
- Twenty source patches reproduce the current engine from official Mixxx 2.5.6.
- Public macOS ZIP/DMG: extracted app passes strict signature verification;
  version 1.7.0, both own icons, English profile and 2 px playheads verified.
  Finder shows the canonical NauticMixxx icon. DMG integrity/mounted bundle and
  all release checksums pass. No isolated test profile is included.
- Public source validation passed in GitHub Actions run 37226813917. Windows
  native build/installer validation passed in 37226814295. No new physical
  XDJ/CDJ jog comparison or Linux v1.7 test.
- Windows x64: 121 native tests passed, 0 failed, 5 optional external
  fixtures skipped. Actual NSIS EXE install/uninstall, application version,
  English profile and controller payload checks passed on windows-2022.
  Target-machine audio/controller/USB hardware validation remains pending.


## v1.6.0 — aviso de actualización al iniciar

- Compilación nativa macOS arm64 Release de la app y mixxx-test completada.
- validate-release.sh: auditoría, contratos de instaladores, USB-only, XML y
  pruebas JavaScript aprobados. Suite nativa: 77 aprobadas, 9 omitidas por
  fixtures externos opcionales; ninguna fallida.
- Las 12 pruebas nuevas (9 StartupUpdateCheckerTest y 3 StartupUpdateDialogTest)
  aprobaron comparación numérica, omisión persistente, los tres botones, petición
  única/asíncrona, timeout, cancelación, red desconectada, HTTP/redirecciones y
  respuestas inválidas o demasiado grandes.
- Los 19 parches aplicaron sobre el tarball oficial Mixxx 2.5.6, cuya SHA-256
  fue verificada; las fuentes nuevas coinciden con este workspace.
- Consulta real HTTPS a GitHub aprobada usando OpenSSL y repetida desde un
  bundle ad hoc con los mismos entitlements de sandbox/red. Devolvió 1.5.1.
- Candidato aislado: build/test-candidate/1.6.0-update-1. Firma ad hoc verificada
  con codesign --verify --deep --strict; permiso network.client comprobado.
- Bundle 1.6.0 y perfil en inglés comprobados. Icono del bundle idéntico al
  generado desde el PNG obligatorio; icono propio confirmado visualmente en Finder.
- Arranque real del candidato hasta la interfaz RX3 aprobado; app cerrada al
  terminar. El acceso al USB se canceló durante esta prueba de arranque.
- Vista previa del aviso en build/test-candidate/1.6.0-update-1 usa la versión
  futura simulada 1.7.0; no se publicó una release durante esa prueba.
- Windows x64: compilación nativa con los 19 parches completada; 107 pruebas
  aprobadas, 4 fixtures externos opcionales omitidos y ninguna fallida. Las
  12 pruebas del aviso aprobaron también en Windows. Instalación/desinstalación
  silenciosa del EXE real aprobada, conservando el perfil del usuario.
  [Evidencia CI](https://github.com/nauticsoftware/NauticMixxx/actions/runs/37176160896).
- EXE descargado de CI y extraído: hash del ejecutable y de los 19 parches
  coinciden con el registro de compilación. Perfil en inglés, Qt Network,
  backend OpenSSL y siete tamaños del icono propio dentro del ejecutable comprobados.
- Paquetes públicos macOS ZIP/DMG: firma estricta, versión 1.6.0, ambos iconos,
  perfil en inglés, permiso de red y ausencia de perfil aislado verificados.
  Icono público confirmado en Finder; integridad del DMG y acceso a Aplicaciones
  aprobados. Las fuentes distribuidas incluyen el comprobador y el helper de branding.
- Auditoría y suite del repositorio público aprobadas también en GitHub Actions.
  [Evidencia](https://github.com/nauticsoftware/NauticMixxx/actions/runs/37176160735).
- Linux: receta actualizada; no se compiló v1.6 en esta sesión. No se hizo
  una nueva prueba física de audio.

## v1.5.1 — audio reconfiguration hotfix

- Captured v1.5.0 freezing on Core Audio shutdown: the main thread waited in
  AudioUnitReset while the finished callback waited for a mutex. Music kept
  running on the M2 clock device.
- Native macOS Release build passed 65 tests; 9 optional external fixtures
  were skipped. The stream completion regression tests passed, including
  timeout, late/repeated notification and reset.
- Real MOTU M2 and Hercules DJControl Inpulse 500: 24 reconfigurations passed
  in 11.259 seconds. M2 main 1–2 and Hercules headphones 3–4 remained assigned;
  Hercules booth 1–2 alternated off/on across synchronization modes 0, 1 and 2
  at 48 and 44.1 kHz. Audio callbacks ran with silence; audible output levels
  and musical continuity were not measured.
- Windows x64 compiled and passed 95 native tests (4 optional fixtures skipped), plus EXE installation and
  uninstallation checks. [CI evidence](https://github.com/nauticsoftware/NauticMixxx/actions/runs/37164223488).
- Installed macOS v1.5.1 accepted the reported configuration via OK and
  returned to the main window. Removing and restoring booth via Apply also
  completed without freezing. Reopening preferences confirmed all three
  assignments, and quitting/restarting the app succeeded with booth saved.
- After a later Mac restart, both v1.5.0 and v1.5.1 encountered a separate
  Core Audio wait in AudioDeviceCreateIOProcID during device opening.
  Reconnecting the M2 and Hercules cleared that condition before GUI validation.
- New profiles keep en_US. The canonical NauticMixxx icon was generated and
  verified in the bundle and visually in Finder. macOS uses ad-hoc signing;
  Apple notarization is not included.

## v1.5.0 — release validation

### Linux extension — 3 October 2026

- Ubuntu 24.04 x86_64 and ARM64 compiled natively with all 17 patches,
  portable CPU optimization and precompiled headers disabled. Each target
  passed 30 native RX3/timing tests; four optional USB/calibration fixtures
  were skipped. [Ubuntu evidence](https://github.com/nauticsoftware/NauticMixxx/actions/runs/37158960601).
- Debian 12 ARM64 compiled in a native Bookworm container with GCC 12.2.
  The same 30 native tests passed and four optional fixtures were skipped.
  [Debian evidence](https://github.com/nauticsoftware/NauticMixxx/actions/runs/37159816188).
- All three targets passed controller browser/jog/exit tests, isolated
  English-profile and user-data preservation checks, ELF architecture and
  project icon checksum checks, desktop entry validation, and RX3 GUI startup
  under virtual X11/Mesa. No physical Pi GPU or audio/controller was tested.
- Fixed the missing `track/track.h` dependency exposed by building without
  precompiled headers. The Debian controller test also works on Node 18.
- The manual workflows use free standard public runners. Artifact uploads and
  caches are disabled by default; optional test packages consume the account's
  storage allowance and expire after one day.
- [Linux / Raspberry Pi build and hardware test guide](docs/LINUX-RASPBERRY-PI.md).

### Original macOS/Windows release builds

- Jog curve tests: slow/fast bounds, both directions and unchanged scratch,
  pause, SHIFT, loop and beatgrid paths pass.
- ASSISTANT gesture tests: native and stock browser, 599/600 ms threshold,
  duplicate presses, Note Off velocity, delayed timers, SHIFT and shutdown
  cleanup pass; exiting does not load a track or alter transport.
- Seven Pioneer/Roland preset checks preserve source controls, LOAD, outputs
  and dependencies. Browser adapter tests cover native and stock Mixxx.
- MIDI button names checked against official DDJ-400, WeGO3, SX2/SX3 lists
  and Roland DJ-505 documentation. SX3 remains experimental.
- Fresh macOS ARM64 build: 63 native tests passed, nine optional external
  fixtures skipped, zero failures. App startup and menus verified in English.
- macOS bundle icon matches the canonical NauticMixxx icon byte-for-byte;
  Finder preview shows the project icon. Strict signature verification passes.
- Windows x64: all 17 patches built; 93 native tests passed, four optional
  fixtures skipped, zero failures. The real EXE installed and uninstalled
  successfully, preserved the user profile and included the new controller
  presets and `Locale en_US`.
  [Public build evidence](https://github.com/nauticsoftware/NauticMixxx/actions/runs/37148615639).
- Physical Pioneer/Roland navigation and Inpulse-to-XDJ/CDJ equivalence have
  not been measured.

## v1.4.0 — timing de Rekordbox y logo

- Compilación nativa macOS ARM64 con los quince parches. El binario coincide
  con la candidata r4 verificada por UUID.
- METRONOME: los 64 kicks de ambos WAV coinciden con el JSON a cero muestras.
  Los cuatro audios y sus PDB/ANLZ reales se probaron desde una copia exacta
  del export; se conservaron SHA-256 en el diagnóstico local.
- CoreAudio: error máximo MP3 grid/kick de 0,590 ms a 44,1 kHz y 0,542 ms a
  48 kHz. Se comprobaron 64 beats y ocho seeks por archivo. WAV 48 kHz:
  0,500 ms; WAV 44,1 kHz: 1,497 ms, conservando su primer beat exportado a
  999 ms y CUE a 1000 ms. Datos en docs/BEATGRID-TIMING-1.4.md.
- Suite de timing: 16 aprobadas, tres fixtures opcionales omitidos. La puerta
  RX3 + timing: 31 aprobadas y las mismas tres omitidas, sin fallos.
- Logo inicial centrado en ventanas de 1280 y 2560 píxeles de ancho.
  Icono canónico verificado en el bundle y Finder; firma estricta correcta.
- Publicación macOS: instalación limpia de CMake, sin plantilla ni perfil de
  test; 63 pruebas nativas aprobadas, nueve fixtures externos opcionales
  omitidos, cero fallos. Seis suites JavaScript de controladores, contrato USB,
  XML y preset FLX4 aprobados. DMG con integridad y firma estricta verificadas.
- Windows x64: los quince parches compilaron en `windows-2022`; 93 pruebas
  nativas aprobadas, cuatro fixtures externos opcionales omitidos, cero fallos.
  Instalación y desinstalación del EXE real correctas, conservando el perfil.
  Las siete imágenes del icono del instalador y de la app coinciden exactamente
  con el ICO generado desde el PNG canónico.
  [Ejecución pública](https://github.com/nauticsoftware/NauticMixxx/actions/runs/37141825488).
- Los MP3 se midieron con CoreAudio. FFmpeg 6 no abrió estos MP3. No se midió
  salida física de CUE ni latencia; no hay comparación física de Windows.

## v1.3.1 — mapeos de controladores

- En macOS, el Inpulse 500 conectado inició con el mapeo RX3 activo y sin la excepción `trigger` del arranque. La prueba utilizó un perfil aislado.
- El estado de la página lateral se consulta al pulsar el botón; las pruebas cubren los dos sentidos del cambio y un cambio previo desde la pantalla.
- El preset DDJ-FLX4 conserva sus entradas MIDI originales y añade los controles RX3 de navegación. Las pruebas de JavaScript, XML y bindings pasaron; aún falta una prueba con hardware FLX4.
- El paquete macOS 1.3.1 pasó la verificación estricta de firma, versión, mapeo Inpulse incluido e icono NauticMixxx. La validación de Windows x64 requiere el workflow nativo de GitHub Actions.

## v1.3.0 — navegador USB

- `mixxx` y `mixxx-test` compilan en macOS ARM64 con el parche 0014.
- 36 pruebas dirigidas de DeviceSQL, playlists y catálogo temporal aprobadas;
  una leyó en sólo lectura el `export.pdb` real de NAUTICBOY y confirmó las diez
  categorías visibles y su orden exportado.
- Los 14 parches se aplicaron secuencialmente sobre la fuente oficial 2.5.6
  con `git apply --whitespace=error`; auditoría pública 1.3.0 correcta.
- Una inspección visual de la compilación de prueba detectó la barra de
  categorías centrada cuando era el único widget visible y una señal que podía
  volver a mostrar la tabla antes de confirmar categoría. Ambos caminos se
  corrigieron y recompilaron. El usuario confirmó que la prueba funciona, pero
  sus capturas mostraron BPM elidido y GENRE demasiado estrecho.
- La revisión `test-candidate/1.3.0-r2` corrige el cálculo del ancho de BPM con
  la fuente real de la celda, compacta BPM y GENRE y conserva GENRE al doble de
  ancho. Compilación nativa y 34 pruebas dirigidas aprobadas. La app firmada
  arrancó con perfil independiente. El icono del bundle y el que devuelve
  macOS para Finder coinciden con el icono propio de la última release candidate.
  La verificación visual de las nuevas columnas quedó pendiente porque macOS
  estaba bloqueado durante la inspección.
- La revisión `test-candidate/1.3.0-r3` mantiene SOURCE durante la lectura y
  sólo permite entrar cuando la sesión, el catálogo y el menú exportado están
  listos. Con el USB real, SOURCE mostró «READING…» y después Ready (1133
  canciones, 6 playlists). La interacción con la app comprobó la vista previa de
  CALIBRATION_WAVEFORM (9 temas), _HOUSE (4 playlists) y NAUTICtracks (18
  temas), y que ENTER abre la tabla completa de NAUTICtracks. Se recompiló la
  unidad del navegador, se enlazaron la app y `mixxx-test`, pasaron 40 pruebas
  dirigidas, la auditoría pública 1.3.0 y la firma del bundle. Finder devolvió
  el icono propio de NauticMixxx. Las capturas automáticas de la ventana
  permanecieron desactualizadas tras la primera pantalla; la comprobación del
  contenido se hizo con el árbol de accesibilidad de la app en ejecución.
- MATCHING, FOLDER y REC están aplazadas por decisión del usuario. HISTORY se
  probó con filas sintéticas; el USB disponible no contiene historial real.

### Windows x64 — v1.3.0

- Los 14 parches compilaron con CMake/Ninja y Visual Studio 2022 en el runner
  público `windows-2022`. Pasaron 78 pruebas nativas RX3/beatgrid/cue, sin fallas.
- NSIS generó `NauticMixxx-1.3.0-Windows-x64-Setup.exe` con el icono oficial
  derivado de `branding/`. Las siete resoluciones incrustadas en el EXE coinciden
  byte por byte con el `.ico` generado desde el PNG canónico. El instalador y la
  aplicación instalada se identifican como NauticMixxx.
- La instalación y desinstalación silenciosa verificaron ejecutable, skin, perfil,
  preferencias USB, controladores y efectos; se conservó el perfil personal.
- [Ejecución pública](https://github.com/nauticsoftware/NauticMixxx/actions/runs/36953168670).
  Siguen pendientes las pruebas físicas del controlador y USB en Windows.

## v1.2.0 — 2026-09-30

Fecha: 2026-09-30. Base: Mixxx 2.5.6.

## macOS ARM64

- Compilación nativa incremental de `mixxx` y `mixxx-test`: correcta.
- `validate-release.sh`: 60 pruebas nativas aprobadas, 0 fallidas y 5 omitidas
  por requerir fixtures opcionales (incluidos exports externos específicos).
- 2 pruebas adicionales de integración aprobadas sobre el USB real del usuario:
  asociación ANLZ/pista y lectura de ondas del navegador.
- 12 pruebas del importador/render, incluida polaridad PCM, cancelación y
  resampling de pistas largas, geometría de marcas y comienzo audible, aprobadas.
- 30 renders del decoder C++ y la geometría compartida comparados con las
  capturas de calibración. [Resultados y límites](docs/calibration-v2/REPORT.md).
- El análisis propio fue validado por columna y segmento con 07–09; no alcanza
  equivalencia Pioneer y permanece separado del reproductor.
- XML de skin, controlador y efectos válido; pruebas JavaScript de AUTOLOOP,
  ajuste de bucle, Sound Color FX, SLIP, SYNC y pitch ±6 % aprobadas.
- Parche 0012 verificado con `git apply --check` sobre la fuente 2.5.6 ya
  parcheada con 0001–0011.
- Bundle instalado en un directorio de staging y verificado por CMake.
- La app empaquetada arrancó con Cocoa y perfil separado, permaneció activa
  durante 12 segundos y se cerró al terminar la prueba. Este smoke no verifica
  reproducción física ni equivalencia del framebuffer OpenGL con las capturas.

## Windows x64

- Compilación nativa CMake/Ninja con Visual Studio 2022 y las doce modificaciones NauticMixxx: correcta en el runner público `windows-2022`.
- 78 pruebas nativas RX3/beatgrid/cue aprobadas, 0 fallidas. Una prueba de paleta se ajustó para verificar el color configurado sin depender de un píxel cubierto por el texto según la fuente de Windows.
- NSIS generó `NauticMixxx-1.2.0-Windows-x64-Setup.exe`. La información del instalador y de la aplicación instalada identifica el producto como NauticMixxx; el ejecutable es `NauticMixxx.exe`.
- El instalador se ejecutó en silencio en Windows y se verificaron skin RX3, 3-Band, USB-only, análisis y ReplayGain desactivados, controlador, cadenas de efectos y orden de Sound Color FX. La desinstalación eliminó el programa y conservó el perfil.
- Ejecución pública: https://github.com/nauticsoftware/NauticMixxx/actions/runs/36776360837

## Validaciones físicas pendientes

- Hercules DJControl Inpulse 500 y conexión en caliente.
- Reproducción en tiempo real con el controlador y USB Rekordbox, incluidos beatgrid y marcadores.
- Comparación visual y OpenGL de Blue, RGB y 3-Band en Windows.

La opción de cargar en el primer sonido usa un marcador existente. Con análisis
desactivado, una pista USB sin ese marcador carga al inicio.
