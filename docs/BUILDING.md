# Compilación reproducible

NauticMixxx aplica parches versionados sobre el tag oficial Mixxx 2.5.6. Los
scripts verifican por SHA-256 tanto el código base como las dependencias.

## macOS ARM64

Requisitos: Xcode Command Line Tools, CMake, Ninja, Git y unos 8 GB libres.

```bash
./scripts/build-mixxx-rx3-macos.sh
```

El script descarga las entradas verificadas, aplica `patches/0001` a
`0017`, compila `NauticMixxx.app`, ejecuta las pruebas RX3 y de timing Rekordbox, instala skin y
mapping dentro del bundle, genera el icono y firma de forma ad hoc.

Variables opcionales:

- `RX3_BUILD_ROOT`: caché y carpeta de compilación.
- `RX3_BUILD_JOBS`: paralelismo.
- `NAUTIC_SIGNING_IDENTITY`: identidad Developer ID/Application para firmar.

## Windows x64

Para generar el instalador nativo completo, instala Visual Studio 2022 con C++, Python, Pillow y NSIS; luego ejecuta en PowerShell:

```powershell
./scripts/build-mixxx-rx3-windows.ps1 -WorkRoot C:\nauticmixxx-build -Jobs 4
```

El script descarga fuentes y dependencias verificadas, aplica los parches NauticMixxx, compila, ejecuta la suite RX3 y crea el instalador EXE de la versión indicada en `VERSION`. El workflow público prueba la instalación y desinstalación reales antes de cargarlo en el release. La versión Windows 1.4.0 pasó 93 pruebas nativas, con cuatro fixtures opcionales omitidos, y la validación del instalador en el [workflow público](https://github.com/nauticsoftware/NauticMixxx/actions/runs/37141825488).

## Fuentes correspondientes

`python3 scripts/package-release.py` empaqueta el árbol completo de Mixxx ya
parcheado junto con recetas, skin, mapping, efectos, atribuciones y herramientas
de validación. Esto permite reconstruir el binario publicado sin depender del
árbol de trabajo privado.
