# Informe de validación — NauticMixxx 1.1.0

Fecha: 2026-09-28. Base: Mixxx 2.5.6.

## macOS ARM64

- Aplicación nativa 1.1.0 compilada, firmada de forma ad hoc y verificada con
  `codesign --verify --deep --strict`.
- Display y controles: **111 pruebas aprobadas, 0 fallidas, 5 omitidas**. Las
  omitidas requieren fixtures externos de USB rekordbox.
- Once parches aplicados al código oficial con hash verificado; las fuentes
  resultantes coinciden con los cambios nativos incluidos en el proyecto.
- Capturas de 1280×800 y pantalla maximizada revisadas. La prueba se hizo con
  pistas sintéticas en un perfil aislado.
- XML de skin, mapping y efectos, y pruebas JavaScript de controles: correctos.
- Preset DDJ-FLX6 validado con mensajes MIDI documentados y pruebas simuladas
  de navegación tanto nativa RX3 como estándar Mixxx. Hardware FLX6 pendiente.
- Instalador macOS, configurador del perfil y documentación de acceso en inglés.

## Windows x64

- El paquete 1.1.0 distribuye **skin y BAT**, sin un ejecutable nativo nuevo.
- Contrato del ZIP, archivos y hashes SHA-256: correcto.
- Instalador: **20 comprobaciones aprobadas**, incluida la detección de
  NauticMixxx 1.0 y la validación del payload.
- Desinstalador: **16 comprobaciones aprobadas**, incluida la eliminación de
  varias versiones simuladas y la conservación del perfil compartido de Mixxx.
- Los scripts PowerShell se analizaron sintácticamente. La instalación y
  desinstalación reales en Windows, MIDI y audio requieren prueba en un equipo
  Windows.

## Alcance

No se probó físicamente el Hercules DJControl Inpulse 500 ni un USB rekordbox
real en esta validación. La firma ad hoc de macOS no sustituye una firma
Developer ID ni la notarización de Apple.
