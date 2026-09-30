# Informe de validación — NauticMixxx 1.2.0

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
