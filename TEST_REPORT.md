# Informe de validación — NauticMixxx

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
- El candidato de publicación se genera desde una instalación limpia de CMake,
  sin plantilla ni perfil de test. La validación final y Windows se registran
  al completar las respectivas puertas de publicación.
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
