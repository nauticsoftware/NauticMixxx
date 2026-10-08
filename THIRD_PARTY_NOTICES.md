# Avisos de terceros

## Mixxx

- Proyecto: [Mixxx](https://github.com/mixxxdj/mixxx)
- Versión base: 2.5.6
- Licencia: GNU GPL v2.0 o posterior
- Modificación: veintiocho parches reproducibles en `patches/`

Los binarios incluyen el texto de licencia y los avisos de las bibliotecas que
Mixxx distribuye. El archivo de fuentes correspondiente permite reconstruir la
misma aplicación.

## pioneered-by-ntamas

- Proyecto: `ntamas94/pioneered-by-ntamas`
- Commit integrado: `db9b669f1cb2fa24f9316cfde855e1e2c6643449`
- Licencia: GNU GPL v3

Los XML, QSS e imágenes iniciales de la skin provienen de ese proyecto y fueron
modificados extensamente para NauticMixxx.

## BiteDJ / DeckShark

Se revisaron patrones de estabilidad visual del commit
`39d39434160150890c8276c7cde03e454218cb76`, licenciado bajo GNU GPL v3. No se
incluyen sus marcas ni sus recursos gráficos.

## Hercules

El mapping incluido se basa en el mapping de Mixxx para Hercules DJControl
Inpulse 500 y conserva la licencia y cabeceras originales de sus archivos.

## Pioneer DDJ-FLX4

El preset completo para DDJ-FLX4 conserva el mapping y script original de
Mixxx 2.5.6, con sus autores y licencia GPL. La navegación RX3 adapta el aporte
de [muehlauer al issue #3](https://github.com/nauticsoftware/NauticMixxx/issues/3).

## Pioneer DDJ-400 y DDJ-SX; Roland DJ-505

Los presets RX3 reutilizan los mappings y scripts incluidos en Mixxx 2.5.6,
conservando sus autores y cabeceras de licencia. Solo se adaptaron los mensajes
MIDI de navegación del browser; las demás funciones provienen del mapping base.

## Pioneer DDJ-SX2, DDJ-SX3 y DDJ-WeGO3

Los mappings comunitarios provienen de
[ardje/Mixxx-Pioneer-DDJ-SX3](https://github.com/ardje/Mixxx-Pioneer-DDJ-SX3)
y [matthewryanscott/mixxx-pioneer-ddj-wego3](https://github.com/matthewryanscott/mixxx-pioneer-ddj-wego3).
Ambos repositorios publican licencia MIT. Las copias de las licencias están en
`controllers/Pioneer_Roland_RX3/LICENSE-DDJ-SX2-SX3.txt` y
`controllers/Pioneer_Roland_RX3/LICENSE-DDJ-WeGO3.txt`.
Los XML originales se guardan en `vendor/controller-mappings/` para reproducir
la generación de los presets, incluida la reconstrucción del XML SX3.

## Sparkle

- Project: https://sparkle-project.org/
- Version: 2.10.0
- License: permissive Sparkle license (including bundled component notices).
- Used for macOS signed updates and sandbox-aware installation. No subscription or paid license is required.
- Full license: `vendor/licenses/Sparkle-2.10.0.txt`, also included in the macOS bundle.
- The bundled Updater.app uses the NauticMixxx project icon; the application and framework are signed locally.
