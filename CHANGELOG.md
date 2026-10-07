# Historial de cambios

## 1.9.0 — 2026-10-07 (development)

- Continuous one-pixel gray USB browse divider, without left-list scrollbar gaps; preserves navigation through overflowing lists.

- Active deck follows user interaction independently of MASTER, with white selection outlines.
- Two-second PERFORMANCE BROWSER hold activates GRID; the encoder shifts the selected grid, with red full-height downbeats and per-deck GRID tools.
- Centered pad mode dividers, directional BEAT JUMP corner tabs and bold numeric displays except HOT CUE pads.
- Compact STATUS / BEAT FX and MASTER geometry, spaced TEMPO label and green 6% range chip.
- Both fixed deck wave pairs blink together; macOS RX3 opens as a frameless 1280×800 window.

- Immediate USB category previews, stable USB slot labels, RX3 category ordering, and two browse columns.
- Distinct category and content focus for controller and touch navigation.
- Touch search keyboard, empty-query handling and compact results with INFO.
- Artist/album/history previews, RELATED KEY placeholder, and deck-based harmonic/tempo matching.
- Temporary read-only USB folder playback for unexported files.
- Twelve complete track rows and sidebar height fitting; lower deck badge position.

## 1.8.0 — 2026-10-04

- DECK: texto y número compactos, ondas vectoriales animadas solo durante PLAY;
  tres tamaños y un intervalo apagado, ciclo aproximado de 800 ms.

- OVERVIEW: eje gris por delante del PLAYHEAD y blanco hasta su posición actual.
- BPM: MASTER llega al borde derecho con texto centrado; la etiqueta BPM se
  acerca al borde izquierdo en PERFORMANCE y BROWSER.
- BROWSER: texto #01FF02 y triángulo PLAY durante la reproducción en cualquier deck.
- Verde #008A01 después de 60 segundos de reproducción real en la sesión; pausa y saltos no suman el tiempo saltado. Las escuchas breves vuelven a blanco.
- Nota musical vectorial con H solo para lossless, incluyendo distinción ALAC/AAC dentro de M4A.
- Iconos vectoriales de categorías y margen uniforme de 2 px en STATUS / BEAT FX.
- Corrige la desconexión de controladores ya destruidos durante la eliminación diferida de preferencias; vacía la lista de dispositivos antes de eliminarlos.

## 1.7.0 — 2026-10-04

- BLUE, RGB y 3Band se aplican a waveforms principales, overviews de ambos
  modos y previsualizaciones de la biblioteca. Caché de previews por estilo.
- CUE y comienzo del loop usan solo un triángulo blanco de 8 × 7; se eliminan
  las líneas y cajas de estos marcadores y el marcador de fin de loop.
- Conserva la región sombreada del loop y elimina el conteo azul de bars junto
  al playhead.
- Playhead rojo en pausa y blanco en reproducción, con un grosor de 2 en la
  waveform principal y de 2 en los overviews.
- El triángulo de CUE se dibuja por encima del playhead al coincidir.
- HOT CUE en los márgenes exteriores, con altura de downbeat y un pequeño
  tramo del tick visible hacia la waveform; conserva la paleta existente.
- Overview con línea inferior blanca de mayor grosor, separación y playhead
  más grueso. HOT CUE de mayor tamaño, con solapamiento progresivo A → H
  independiente de su orden temporal; los inferiores van en la franja inferior.
- WAVEFORM DIVISIONS en preferencias de Waveforms: TIME SCALE por defecto,
  marcas cada 30 segundos, o PHRASE con los bloques PSSI exportados por Rekordbox.
  Lee PSSI normal/cifrado y lo proyecta sobre PQTZ con el ajuste del decoder.
- Elimina referencias a páginas de controlador retiradas al volver a
  detectarlos, evitando un cierre inesperado al aceptar preferencias.
- Reduce la sensibilidad del borde de la Hercules Inpulse 500 en reproducción
  y amplía la progresión entre giro suave y rápido para dosificar la corrección
  de fase. Mantiene scratch, búsqueda en pausa, SHIFT, loops y beatgrid.
- Sin relación fija entre vueltas y beats. Validación física frente a XDJ/CDJ
  pendiente; pruebas de handlers en decks 1–4 aprobadas.

## 1.6.0 — 2026-10-04

- Consulta una vez al iniciar la última release estable pública de NauticMixxx.
- Aviso en inglés con versión instalada/nueva y Download, Later y Skip this version.
- Descarga manual desde GitHub; omisión persistente para esa versión.
- Consulta asíncrona con límite de cinco segundos; sin conexión o ante errores continúa sin avisos.
- Cancela el aviso si comienza la reproducción o Auto DJ, sin repetir consultas durante la sesión.
- Compara la versión propia del producto, independientemente del motor Mixxx 2.5.6.
- Habilita conexiones salientes en el sandbox macOS sin credenciales de Apple.

## 1.5.1 — 2026-10-03

- Corrige el bloqueo de Core Audio al aplicar cambios de salida de cabina con Hercules y M2.
- Finalización de streams sin mutex; reloj del motor detenido primero e iniciado al final.
- Pruebas de regresión para callback tardío y cambios repetidos de cabina.

## 1.5.0 — vista previa pública

- ASSISTANT mantenido 600 ms sale de BROWSE sin cargar pista; pulsación corta abre SOURCE al soltar.
- La app y los perfiles nuevos usan inglés por defecto (`en_US`).

- Añade presets completos RX3 para Pioneer DDJ-400, DDJ-SX, DDJ-SX2,
  DDJ-SX3, DDJ-WeGO3 y Roland DJ-505. Integra selección automática por
  modelo y navegación de USB, categorías y pistas sin mouse. El DDJ-FLX4
  conserva su preset completo. Guía y límites en
  `docs/CONTROLLERS-RX3-1.5.md`.
- Inicia la calibración del borde de los jog wheels del Hercules DJControl
  Inpulse 500. En reproducción, la nueva curva refuerza los giros lentos y
  limita los rápidos; scratch, búsqueda en pausa y SHIFT mantienen sus rutas.
  Parámetros, fundamento y ensayo físico pendiente en
  `docs/JOG-CALIBRATION-1.5.md`.

## 1.4.0 — 2026-10-03

- Corrige la diferencia entre los tiempos de MP3 exportados por Rekordbox y
  el audio que CoreAudio entrega sin delay del encoder. La compensación depende
  del archivo y del decodificador abierto; se aplica a grid, cues y loops.
- Las waveforms ANLZ conservan su reloj de 150 columnas/s y comparten el origen
  temporal del audio, sin estirar el padding sobre la duración decodificada.
- Mantiene los tiempos del export y los WAV intactos; los cues anteriores al
  inicio decodificado se limitan a cero y los loops sin audio se descartan
  únicamente de la proyección temporal.
- Validación con la playlist METRONOME, WAV/MP3 a 44,1 y 48 kHz, 64 beats y
  ocho seeks repetidos al CUE. Detalles en docs/BEATGRID-TIMING-1.4.md.
- Las candidatas macOS de test arrancan con un perfil propio desde Finder o
  el lanzador, con mapeos resueltos dentro de su sandbox.
- Centra el logo inicial en el ancho completo de la ventana, compensando
  el espacio del panel BEAT FX también al escalar la skin.

## 1.3.1 — 2026-10-02

- Corrige el fallo al iniciar el mapeo Hercules DJControl Inpulse 500 cuando el control de la página lateral aún no existe. El botón consulta el estado actual al pulsarlo.
- Incluye el mapeo DDJ-FLX4 con navegación RX3 aportado por la comunidad y validado por pruebas automáticas; pendiente de prueba física.
- Actualiza los paquetes nativos macOS y Windows, preservando el icono propio de NauticMixxx.

## 1.3.0 — 2026-10-01

- El USB Rekordbox se detecta y prepara en segundo plano al iniciar la app o
  conectar el dispositivo, sin depender de abrir SOURCE.
- SOURCE conserva la selección durante la lectura y muestra el contenido al
  terminar. El estado proviene de la sesión real, sin el plazo artificial de
  15 segundos ni la página HTML original de Rekordbox.
- Las conexiones nuevas requieren conceder acceso a macOS una vez cuando el
  sistema no dispone de una autorización previa.
- SOURCE muestra primero las categorías visibles y su orden exportado en el USB.
  Resaltar una categoría o carpeta no abre su contenido; ENTER lo confirma y
  BACK regresa al nivel anterior.
- SOURCE mantiene el dispositivo en espera hasta que el catálogo, las playlists
  y las categorías estén listos. No permite entrar durante la lectura ni
  presenta las dos categorías provisionales.
- Al resaltar una playlist se ven sus pistas en el panel derecho, sin entrar
  ni cargar una pista. Las carpetas muestran sus playlists hijas. ENTER o doble
  clic abre la playlist y conserva la tabla completa actual.
- Las listas finales ocultan la columna intermedia y muestran PREVIEW, TRACK,
  ARTIST, BPM y GENRE. ARTIST, ALBUM y otros filtros se resuelven desde el
  catálogo temporal, sin recurrir a la biblioteca local.
- La revisión de prueba r2 calcula el ancho de BPM con la misma fuente que
  dibuja sus valores y asigna a GENRE el doble de ese ancho. Ambas columnas
  muestran una fuente normal más compacta y con menos espacio entre letras.
- HISTORY tiene lector de índices propio. MATCHING y FOLDER conservan su
  entrada exportada y muestran COMING SOON. REC queda reservado para una
  versión futura y no aparece si el USB no lo exporta.
- Parches nativos 0013–0014; arranque con el USB NAUTICBOY ya conectado y
  lectura real del menú comprobados en macOS. Conexión en caliente, historial
  con datos y comparación física con RX3 siguen pendientes.
- El icono canónico está en `branding/`; se retiró su copia antigua dentro de
  `packaging/` y los scripts de publicación dejaron de depender de ella.
- El instalador nativo Windows x64 1.3.0 pasó 78 pruebas y una instalación
  y desinstalación silenciosa en el runner público. Usa el icono canónico de
  `branding/`. Las pruebas físicas con controlador y USB en Windows siguen
  pendientes.

## Actualización de waveforms — candidata de calibración

- Blue/RGB recuperan signo y nivel real del PCM durante la carga; conservan el
  color ANLZ y no escriben caché ni activan análisis automático de la biblioteca.
- Overview extendido Blue/RGB con gradientes y altura medidos en las capturas.

- Datos independientes PWV3/PWV5/PWV7 y PWAV/PWV4/PWV6; RGB big-endian,
  blancura Blue conservada y orden 3-Band validado con tonos conocidos.
- Detalle y overview comparten el estilo. El segundo selector permite fijar
  las ondas o seguir los EQ del mixer. 3-Band es el valor inicial.
- Contador hasta el marcador bajo la Key, separado de la posición compás.beat.
- Marcas de pulsos blancas únicamente encima y debajo de la onda desde el
  primer sonido; las rojas de compás sobresalen dos píxeles hacia fuera.
- Modelo experimental entrenado con 01–06 y validado con 07–09, sin activarlo
  automáticamente en el reproductor.
- **La réplica píxel a píxel no está alcanzada.** Véase
  [informe cuantitativo y comparaciones](docs/calibration-v2/REPORT.md).


## 1.2.0 — 2026-09-28

- Política USB Rekordbox aplicada desde el primer arranque en macOS y Windows:
  sin selector de biblioteca local, escaneo, análisis, ReplayGain ni caché de
  formas de onda.
- Pioneer Cue, pitch ±6 %, primer sonido, tiempo restante, motor Rubber Band
  Finer, normalización visual y cuenta de pulsos hasta el próximo marcador.
- Tres vistas de onda: BLUE, RGB y 3Band. Los bucles y hot loops nuevos usan
  naranja `#FF8800`.
- Selección automática del mapeo RX3 de Hercules DJControl Inpulse 500 al
  detectarlo al inicio; retirado el preset genérico duplicado.
- Parche nativo 0012 y recetas de compilación de ambas plataformas actualizadas.

## 1.1.0 — 2026-09-28

- Lienzo de referencia de 1280×800 que ocupa toda el área cliente y adapta las
  ondas al tamaño de la ventana, manteniendo el escalado uniforme del texto.
- Proporciones medidas sobre las referencias RX3: cabecera, información lateral,
  separación entre ondas, franja de modos y tarjetas inferiores.
- Cuadrícula inferior alineada con el borde de STATUS / BEAT FX; el espacio
  flexible del panel lateral queda encima de ZOOM / GRID.
- Cursor rojo de dos píxeles de referencia en ondas, overviews y BROWSE,
  compatible con los renderizadores clásicos y OpenGL.
- Parche 0011 reproducible y metadatos de compilación derivados de VERSION.
- Paquete Windows reorganizado con BAT de instalación y desinstalación junto a una carpeta de archivos;
  el instalador informa el avance, muestra mensajes en inglés y valida que el
  ejecutable y los once parches correspondan a 1.1.0.
- Edición Windows de sólo skin: descarga Mixxx oficial 2.5.6 si falta, ofrece
  perfil paralelo o actualización del perfil habitual, respalda la skin 1.0+
  existente y no distribuye un ejecutable propio.
- El instalador Windows detecta la aplicación NauticMixxx 1.0,
  actualiza la skin de su carpeta y perfil sin descargar otro Mixxx, y crea un
  único acceso directo NauticMixxx con el icono propio.
- El desinstalador localiza todas las versiones en las carpetas NauticMixxx,
  elimina el perfil independiente, accesos y cachés; en el perfil compartido
  retira sólo los componentes RX3.
- Mensajes de instalación y configuración macOS en inglés, guía de instalación
  en inglés y acceso `CONFIGURE-AND-OPEN.command`.
- Preset opcional DDJ-FLX6 para VIEW, SOURCE, BROWSE, BACK y LOAD 1/2, con
  guía inglesa. No sustituye el mapping completo del controlador.

## 1.0.0 — 2026-09-22

Primera versión estable pública de NauticMixxx.

### Incluye

- Identidad completa NauticMixxx: nombre de aplicación, icono, arranque y logo.
- Interfaz de dos decks, PERFORMANCE/BROWSE/STATUS y escalado proporcional.
- Mapping Hercules DJControl Inpulse 500 con ocho Hot Cues a color.
- Lectura de USB rekordbox y navegación sin ratón.
- Beat grid, waveforms, loops, BPM MASTER, Quantize y Sound Color FX.
- Corrección del cierre al volver a seleccionar el mismo USB desde ASSISTANT.
- Seis correcciones del mapping Inpulse 500: SLIP, Sound Color FX, LOOP IN largo,
  LED SYNC, rango de tempo y MASTER TEMPO por deck.
- Nueve parches reproducibles sobre Mixxx 2.5.6.
- Paquetes, manifiesto, checksums y auditoría de release.

### Plataformas

- macOS 11 o posterior, Apple Silicon: binario probado localmente.
- Windows 10 1809 o posterior, x64: receta CI disponible; el binario debe
  construirse y validarse en GitHub Actions antes de adjuntarlo al release.
