# Instalar NauticMixxx 1.2.0

## macOS Apple Silicon

Requisitos: macOS 11 o posterior y un Mac con chip Apple Silicon.

1. Copia `NauticMixxx-1.2.0-macOS-arm64.dmg` y `SHA256SUMS.txt` en la misma carpeta. Calcula `shasum -a 256 NauticMixxx-1.2.0-macOS-arm64.dmg` y compara el resultado con la línea del DMG en `SHA256SUMS.txt`.
2. Abre el DMG y arrastra **NauticMixxx.app** a Aplicaciones. La alternativa ZIP contiene la misma aplicación y `CONFIGURE-AND-OPEN.command` para preparar el perfil y abrirla.
3. Si macOS advierte que es una build comunitaria firmada de forma ad hoc, haz clic derecho en la aplicación y elige **Abrir**.
4. En **Preferencias → Hardware de sonido**, elige la salida de audio y, si corresponde, la entrada de micrófono.

La aplicación navega las unidades USB exportadas por Rekordbox. No pide una carpeta de música local ni escanea una biblioteca local. macOS puede pedir permiso para acceder a la raíz del USB. El perfil se guarda aparte en `~/Library/Containers/org.mixxx.mixxx/Data/Library/Application Support/NauticMixxx`; haz una copia antes de reemplazar una versión anterior.

El Inpulse 500 usa automáticamente el mapeo RX3 personalizado al detectarse. Conectar un controlador cuando ya hay otro activo puede requerir reiniciar la aplicación. Prueba audio, CUE, jog wheels y loops antes de usarlo en directo.

La opción **primer sonido** requiere que el marcador ya exista en los metadatos. En una pista USB sin ese marcador, la carga comienza al principio porque NauticMixxx 1.2 no analiza el audio para generarlo.

## Windows x64

Descarga directamente [NauticMixxx-1.2.0-Windows-x64-Setup.exe](https://github.com/nauticsoftware/NauticMixxx/releases/download/v1.2.0/NauticMixxx-1.2.0-Windows-x64-Setup.exe) y ejecútalo en Windows 10/11 x64. El instalador NSIS incluye el programa nativo; no necesita un BAT, descomprimir un ZIP ni instalar Mixxx oficial.

La aplicación queda en `%LOCALAPPDATA%\Programs\NauticMixxx` y utiliza un perfil propio en `%LOCALAPPDATA%\NauticMixxx`. El instalador aplica las mismas preferencias portables de la edición Mac: skin RX3, 3-Band, USB Rekordbox, análisis y ReplayGain desactivados, Pioneer Cue, tempo ±6 %, mapeo Hercules Inpulse 500, mapeo opcional FLX6 y cuatro Sound Color FX. Conserva los datos personales y hace una copia de la configuración anterior al actualizarla. Selecciona el dispositivo de audio y sus canales en la PC Windows.

El menú Inicio y el escritorio abren `NauticMixxx.exe`. Desinstala desde Ajustes de Windows; el perfil personal permanece para evitar pérdida de datos. El EXE no está firmado, por lo que SmartScreen puede pedir confirmación. Prueba el controlador y el USB antes de usarlo en vivo.

## Desinstalar en macOS

Elimina `NauticMixxx.app`. Los ajustes permanecen en el perfil para evitar pérdida de datos; elimínalos sólo después de respaldarlos si ya no los necesitas.
