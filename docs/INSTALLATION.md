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

El código, los parches y la receta de compilación nativa 1.2.0 están preparados. **El ejecutable Windows 1.2.0 aún no se ha compilado ni probado en Windows.** No uses el paquete de skin sobre Mixxx oficial como sustituto de la aplicación nativa para las restricciones USB, análisis y preferencias fijas.

En un entorno Windows x64 con Visual Studio 2022, el workflow `NauticMixxx Windows x64` o `scripts/build-mixxx-rx3-windows.ps1` compila, prueba y empaqueta la edición nativa. Distribuye ese ZIP sólo después de que termine correctamente y se pruebe con hardware y un USB Rekordbox real.

## Desinstalar en macOS

Elimina `NauticMixxx.app`. Los ajustes permanecen en el perfil para evitar pérdida de datos; elimínalos sólo después de respaldarlos si ya no los necesitas.
