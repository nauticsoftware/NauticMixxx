# NauticMixxx 1.1.0

English: [installation guide](docs/INSTALLATION-EN.md) · [DDJ-FLX6 menu controls](docs/DDJ-FLX6-EN.md). Windows and macOS installer messages are in English.

![NauticMixxx](branding/NauticMixxx.png)

NauticMixxx es una edición comunitaria y de código abierto de Mixxx 2.5.6,
diseñada para ofrecer un flujo visual de dos decks inspirado en una cabina
XDJ-RX3 y una integración profunda con Hercules DJControl Inpulse 500.

La versión vigente 1.1.0 ajusta la geometría del display a las referencias RX3,
llena el área de la ventana desde un lienzo de 1280×800 y utiliza cursores rojos
de dos píxeles de referencia en la aplicación nativa de macOS. La distribución
de Windows incluye la skin 1.1.0 y scripts de instalación y desinstalación;
no incluye un ejecutable NauticMixxx nuevo.

## Qué incluye

- Interfaz 1280×800 escalable con vistas PERFORMANCE, BROWSE y STATUS.
- Waveforms apiladas, beat grid perimetral, overview y ocho Hot Cues por deck.
- Navegación y carga exclusiva desde USB preparado por rekordbox; el asistente,
  el escaneo y las fuentes de biblioteca musical local están bloqueados.
- Mapping específico para Hercules DJControl Inpulse 500.
- Preset opcional de navegación DDJ-FLX6; no reemplaza un mapping completo.
- Cuatro Sound Color FX y controles de loop adaptados al hardware.
- Pantalla de arranque, icono y estado sin pistas con identidad NauticMixxx.
- Corrección de reapertura de SOURCE/USB durante la reproducción.
- Fuentes, parches, pruebas y checksums para auditar cada release.

## Descargar e instalar

La versión vigente se descarga desde [Releases de NauticMixxx](https://github.com/nauticsoftware/NauticMixxx/releases/tag/v1.1.0):

- `NauticMixxx-1.1.0-macOS-arm64.dmg`
- `NauticMixxx-1.1.0-macOS-arm64.zip`
- `NauticMixxx-1.1.0-Windows-x64-Skin.zip`
- `NauticMixxx-1.1.0-source.tar.gz`
- `SHA256SUMS.txt`

La versión 1.0.0 permanece en la [etiqueta anterior](https://github.com/nauticsoftware/NauticMixxx/tree/v1.0.0).

En macOS, abre el DMG, arrastra **NauticMixxx.app** a Aplicaciones y ábrela.
El ZIP contiene la misma aplicación como descarga alternativa. La
compilación local está firmada de forma ad hoc; una publicación general debe
firmarse y notarizarse con una cuenta Apple Developer. Consulta
[`docs/INSTALLATION.md`](docs/INSTALLATION.md).

El paquete de **skin 1.1.0 para Windows** contiene `INSTALL-WINDOWS.bat`,
`UNINSTALL-WINDOWS.bat` y `NauticMixxx-Files/` en su raíz. Si existe
NauticMixxx 1.0, reutiliza su instalación y actualiza la skin en la misma
carpeta y perfil. Si faltan NauticMixxx y Mixxx, descarga Mixxx oficial 2.5.6;
si sólo está Mixxx, ofrece un perfil paralelo o el perfil habitual. Crea un
solo acceso directo NauticMixxx con el icono del proyecto. El instalador muestra
avance y mensajes en inglés. El desinstalador retira las versiones de carpetas
NauticMixxx y los componentes RX3. No incluye un ejecutable NauticMixxx 1.1:
las funciones que dependen de los parches nativos no estarán en Windows si se
usa Mixxx oficial, y una aplicación NauticMixxx 1.0 conservará su motor 1.0.
Consulta
[`docs/INSTALLATION.md`](docs/INSTALLATION.md) y
[`docs/BUILDING.md`](docs/BUILDING.md).

## Verificar una descarga

```bash
cd /ruta/a/tus/descargas
shasum -a 256 -c SHA256SUMS.txt
```

## Probar la versión vigente

Extrae `NauticMixxx-1.1.0-macOS-arm64.zip` en una carpeta
temporal, conecta el Hercules DJControl Inpulse 500 y sigue
[`docs/HARDWARE_TEST.md`](docs/HARDWARE_TEST.md).

## Desarrollo y release

```bash
./scripts/validate-release.sh
./scripts/build-mixxx-rx3-macos.sh
python3 scripts/package-release.py
```

La compilación nativa de macOS se reproduce con:

```bash
./scripts/build-mixxx-rx3-macos.sh
```

## Estructura del repositorio

- `patches/`: cambios reproducibles aplicados sobre Mixxx 2.5.6.
- `controllers/`, `effects/`, `skins/` y `profile/`: componentes de NauticMixxx.
- `scripts/` y `packaging/`: compilación, distribución y verificación.
- [Releases](https://github.com/nauticsoftware/NauticMixxx/releases): artefactos vigentes, manifiesto y checksums.
- [v1.0.0](https://github.com/nauticsoftware/NauticMixxx/tree/v1.0.0): versión anterior conservada.
- `../../archive/`: espacio reservado para futuros componentes retirados; los anteriores están recuperables desde Git.

Documentación:

- [Instalación](docs/INSTALLATION.md)
- [Compilación reproducible](docs/BUILDING.md)
- [Validación de 1.1](docs/VALIDATION-1.1.md)
- [Prueba física de los seis fixes](docs/HARDWARE_TEST.md)
- [Organización y política de limpieza](docs/WORKSPACE.md)
- [Cómo publicar el release](docs/RELEASING.md)
- [Arquitectura](docs/ARCHITECTURE.md)
- [Cambios](CHANGELOG.md)
- [Contribuir](CONTRIBUTING.md)

## Licencia y marcas

El trabajo de NauticMixxx se publica bajo GNU GPL v3. El motor Mixxx conserva
GNU GPL v2 o posterior y sus avisos. Consulta [LICENSE.md](LICENSE.md) y
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

NauticMixxx no es un producto oficial ni está afiliado a los titulares de las
marcas mencionadas. Consulta [TRADEMARKS.md](TRADEMARKS.md).
