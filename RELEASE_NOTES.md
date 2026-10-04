# NauticMixxx 1.5.1 — corrección de bloqueo al cambiar salidas de audio

Corrige el congelamiento al aceptar o aplicar cambios de audio con la M2 como salida principal, DJControl Inpulse 500 canales 3–4 en auriculares y canales 1–2 en cabina.

- El callback de finalización usa una señal atómica sin mutex.
- El reloj del motor se detiene antes de cerrar las salidas secundarias y se inicia después de prepararlas.
- Las salidas secundarias en modo experimental se abortan sin esperar un callback que no existe en streams de audio bloqueantes.
- Se conserva el idioma inglés por defecto para perfiles nuevos y el icono propio de NauticMixxx.

Las pruebas y plataformas disponibles se detallan en TEST_REPORT.md. macOS tiene firma ad hoc y no está notarizado por Apple.

# NauticMixxx 1.5.0 — vista previa pública

- ASSISTANT mantenido 600 ms sale de BROWSE sin cargar pista; pulsación corta abre SOURCE al soltar.
- La app y los perfiles nuevos usan inglés por defecto (`en_US`).

- Ajuste inicial del bend del borde del jog Hercules Inpulse 500: responde a
  giros suaves y limita los desplazamientos rápidos durante reproducción.
- Presets RX3 completos con navegación sin mouse para DDJ-400, DDJ-SX,
  DDJ-SX2, DDJ-SX3, DDJ-WeGO3 y Roland DJ-505, más selección automática por
  modelo. El DDJ-FLX4 conserva su preset completo existente.
- Las pruebas de software del browser y de los XML pasan. La calibración fina
  del jog y los siete controladores nuevos requieren prueba física; esta
  versión todavía no es una publicación.

---

# NauticMixxx 1.4.0 — 2026-10-03

- Corrige en macOS la diferencia entre tiempos Rekordbox y MP3 decodificados
  sin delay por CoreAudio. Grid, cues, hot cues, loops y waveforms comparten
  la coordenada del PCM abierto. La compensación se confirma por archivo y
  decodificador, no por una constante fija.
- En METRONOME, los desfases de unos 25/23 ms se redujeron a menos de 0,6 ms
  de error máximo grid/kick sobre 64 beats a 44,1 y 48 kHz. Ocho seeks al CUE
  devolvieron PCM estable. Los WAV conservan los tiempos originales del export.
- ANLZ conserva su reloj de 150 columnas/s y no estira el padding sobre la
  duración audible. El pendrive permanece en sólo lectura.
- Centra el logo inicial en el ancho completo de la ventana; comprobado en
  tamaño normal y ampliado.
- Conserva el hotfix Inpulse 500 y el mapping DDJ-FLX4 de v1.3.1.
- Entrega aplicaciones nativas macOS Apple Silicon y Windows x64, icono propio,
  fuentes correspondientes y checksums. Windows pasó 93 pruebas nativas
  y la instalación/desinstalación del EXE; cuatro fixtures opcionales omitidos.
  Resultados y límites en TEST_REPORT.md.

La medición MP3 corresponde a CoreAudio en macOS. PQTZ guarda milisegundos
enteros y el WAV de 44,1 kHz ya exporta su primer beat a 999 ms; no se modifica
ese dato. La comparación audible de CUE, la latencia física y las pruebas con
hardware Windows siguen pendientes. FFmpeg 6 no pudo abrir los dos MP3 del
set; esa ruta no cuenta como validación.

macOS usa firma ad hoc sin notarización; el instalador Windows no está firmado.
Al actualizar, el paquete público macOS conserva la ubicación habitual del
perfil. Véase [el informe de timing](docs/BEATGRID-TIMING-1.4.md).

---

# NauticMixxx 1.3.1 — 2026-10-02

Esta revisión corrige un error que podía desactivar el mapeo **Hercules DJControl Inpulse 500** al iniciar. El control de la página lateral se consulta cuando se pulsa el botón, una vez disponible la interfaz. La corrección se probó con un Inpulse 500 conectado en macOS.

Se incorpora el mapeo **DDJ-FLX4** con navegación RX3, validado automáticamente; aún no se ha comprobado con hardware FLX4. Se incluyen paquetes actualizados para macOS Apple Silicon y Windows x64.

# NauticMixxx 1.3.0 — 2026-10-01

## Navegación USB en macOS Apple Silicon y Windows x64

- Detecta y prepara en segundo plano los USB exportados por Rekordbox al iniciar
  la aplicación o conectarlos. SOURCE indica «READING…» y no permite entrar
  hasta que el catálogo, las playlists y las categorías exportadas estén listos.
- Muestra las categorías visibles en el orden exportado por Rekordbox. Dentro
  de PLAYLIST, resaltar una lista previsualiza sus pistas a la derecha; ENTER
  o doble clic abre la tabla completa. Las carpetas previsualizan sus listas.
- La tabla completa conserva PREVIEW, TRACK y ARTIST, y muestra BPM y GENRE
  con texto compacto. MATCHING y FOLDER muestran «COMING SOON».
- Se probó con un USB real: 1133 canciones, 6 playlists y 10 categorías. Pasaron
  40 pruebas dirigidas de catálogo, playlists, base Rekordbox y display. La
  prueba física de conexión en caliente y del controlador sigue pendiente.

El paquete macOS ARM64 está firmado de forma ad hoc y no está notarizado.
El instalador nativo Windows x64 incluye los cambios de navegación USB de 1.3.0
y pasó 78 pruebas nativas más la instalación y desinstalación silenciosa.
La prueba física con controlador y USB en Windows sigue pendiente. El icono
de la aplicación se genera desde `branding/`.

---

# NauticMixxx 1.2.0 — 2026-09-30

## Actualización de waveforms y modo USB

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
- El DMG de macOS muestra únicamente NauticMixxx y el acceso a Aplicaciones;
  las guías de instalación y controladores siguen en el ZIP y las fuentes.
- Modelo experimental entrenado con 01–06 y validado con 07–09, sin activarlo
  automáticamente en el reproductor.
- **La réplica píxel a píxel no está alcanzada.** Véase
  [informe cuantitativo y comparaciones](docs/calibration-v2/REPORT.md).


## Instalador directo para Windows x64

`NauticMixxx-1.2.0-Windows-x64-Setup.exe` instala directamente la aplicación nativa con el mismo icono de macOS, la skin RX3, los mapeos Hercules Inpulse 500 y FLX6 de navegación, los cuatro Sound Color FX y las preferencias portables preestablecidas. No requiere BAT, descomprimir ZIP, instalar Mixxx oficial ni descargar componentes adicionales. El ejecutable, el menú Inicio y la información del producto aparecen como NauticMixxx.

Se instala por usuario con un perfil separado; al desinstalar se conservan la biblioteca y los ajustes personales. Cada PC necesita seleccionar su dispositivo de audio y sus canales. El EXE no está firmado y Windows SmartScreen puede solicitar confirmación. La compilación Windows pasa pruebas nativas y una instalación/desinstalación silenciosa; sigue pendiente la prueba física con controlador y USB Rekordbox.

NauticMixxx inicia en modo USB Rekordbox. El selector de biblioteca local no
aparece y el escaneo, el análisis, ReplayGain y la caché de formas de onda están
desactivados. Pioneer Cue, ±6 % de pitch, carga en el primer sonido cuando existe
ese marcador, tiempo restante, Rubber Band Finer, normalización visual y cuenta
de pulsos hasta el próximo marcador quedan fijados. Las vistas seleccionables son
BLUE, RGB y 3Band; bucles y hot loops nuevos usan `#FF8800`.

El Hercules DJControl Inpulse 500 utiliza el mapeo RX3 personalizado al
detectarse al iniciar. El preset genérico duplicado se retiró. Si NauticMixxx
se inicia sin ningún controlador, reintenta detectarlo periódicamente; el
cambio de dispositivos con otros controladores ya abiertos requiere reinicio.

El marcador «primer sonido» depende de que exista en los metadatos de la pista.
En pistas Rekordbox USB sin ese marcador, Mixxx carga en el inicio: no se analiza
el audio para crearlo. Las pruebas con hardware Inpulse 500 y USB Rekordbox real siguen pendientes.

---

# NauticMixxx 1.1.0 — 2026-09-28

English: [installation guide](docs/INSTALLATION-EN.md) and [DDJ-FLX6 menu mapping](docs/DDJ-FLX6-EN.md). The macOS and Windows installers display English messages. The optional FLX6 browser preset has been checked in software; physical controller testing is pending.

Ajustes visuales del display RX3 sobre Mixxx 2.5.6:

- Uso completo del área cliente de la ventana, con referencia 1280×800.
- Alineación del borde inferior del beatgrid con STATUS / BEAT FX.
- Espacios revisados entre cabecera, ondas, panel lateral y controles inferiores.
- Línea de reproducción roja de dos píxeles de referencia, también en BROWSE.

La descarga macOS ARM64 incluye la aplicación nativa compilada con el parche
0011 y la skin 1.1.0. Está firmada de forma ad hoc y puede mostrar la advertencia
de macOS propia de una aplicación sin notarizar.

La descarga Windows `NauticMixxx-1.1.0-Windows-x64-Skin.zip` incluye la skin,
el mapping Inpulse 500 y dos BAT: instalación y desinstalación. Detecta
NauticMixxx 1.0 y actualiza su skin en la misma carpeta; si no existe Mixxx,
descarga la versión oficial 2.5.6. Esta edición no incluye un ejecutable nativo
1.1 para Windows. Por ello, el cursor nativo de dos píxeles, el llenado
automático de la ventana y las funciones del motor requieren una futura build
nativa de Windows. La aplicación NauticMixxx 1.0 conserva su motor 1.0.

Los artefactos 1.0.0 permanecen disponibles como versión anterior. Los hashes
de todos los archivos de 1.1.0 están en `release/1.1.0/SHA256SUMS.txt`.

---

# NauticMixxx 1.0.0

Primera versión estable pública de NauticMixxx, basada en Mixxx 2.5.6.

## Destacado

- Interfaz completa de dos decks con PERFORMANCE, BROWSE y STATUS.
- Navegación de USB rekordbox y control sin ratón con Inpulse 500.
- Ocho Hot Cues con colores coincidentes en pantalla y controlador.
- Loops, ajuste IN/OUT, waveforms, beat grid, BPM MASTER y Sound Color FX.
- Identidad NauticMixxx en bundle, icono, arranque y estados vacíos.
- Corrección del crash al reabrir ASSISTANT y volver a elegir el mismo USB.
- SLIP real por deck, con LED enlazado al estado de Mixxx.
- Cuatro Sound Color FX seleccionables en tiempo real desde el knob COLOR.
- LOOP IN mantenido para crear un loop cuantizado de cuatro beats.
- LED SYNC persistente, selección de rango de tempo con BEATMATCH GUIDE y
  MASTER TEMPO por deck mediante SHIFT + SYNC.
- Perfil RX3 reproducible en macOS: asignación automática del Inpulse 500,
  colores rekordbox, waveform RGB y playhead desplazado hacia la izquierda.
- Modo USB-only estricto: elimina el asistente de carpeta musical, bloquea el
  escaneo y el alta de bibliotecas locales y muestra sólo dispositivos USB
  Rekordbox en SOURCE.

## Descargas

- macOS ARM64 (recomendado): `NauticMixxx-1.0.0-macOS-arm64.dmg`
- macOS ARM64: `NauticMixxx-1.0.0-macOS-arm64.zip`
- Windows 10/11 x64: `NauticMixxx-1.0.0-Windows-x64.zip`
- Skin: `NauticMixxx-1.0.0-skin.zip`
- Fuentes correspondientes: `NauticMixxx-1.0.0-source.tar.gz`

Verifica siempre `SHA256SUMS.txt`. La build macOS firmada de forma ad hoc está
destinada a testing; para distribución sin advertencias debe usarse una build
Developer ID notarizada.

En Windows, extrae todo el ZIP y ejecuta `INSTALL-WINDOWS.cmd`. El instalador
comprueba los archivos, detecta Mixxx y consulta la última versión estable. La
opción recomendada instala NauticMixxx en paralelo con un perfil independiente;
el reemplazo avanzado exige escribir `REEMPLAZAR` y crea respaldos completos.

NauticMixxx es independiente y no está afiliado ni respaldado por los
propietarios de las marcas de hardware o software compatibles.
