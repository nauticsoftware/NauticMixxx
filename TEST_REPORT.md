# Informe de validación — NauticMixxx 1.2.0

Fecha: 2026-09-29. Base: Mixxx 2.5.6.

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

- El contrato del instalador y empaquetador nativo pasó con un ejecutable de
  prueba; la receta Windows apunta a 1.2.0 y doce parches.
- No se compiló ni ejecutó `mixxx.exe` en Windows desde este Mac.

## Pendiente antes de publicación multiplataforma

- Compilación y prueba nativas Windows mediante el workflow de Windows x64.
- Prueba física del Hercules DJControl Inpulse 500 y de conexión en caliente.
- Prueba de reproducción en tiempo real con el controlador y el USB, incluidos
  beatgrid y marcadores.
- Validación visual de las tres ondas y del color naranja en ambos sistemas.

La opción de cargar en el primer sonido usa un marcador existente. Con análisis
desactivado, una pista USB sin ese marcador carga al inicio.
