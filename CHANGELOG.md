# Historial de cambios

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
