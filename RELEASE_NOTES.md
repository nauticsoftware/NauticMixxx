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
