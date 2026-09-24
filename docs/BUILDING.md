# Compilación reproducible

NauticMixxx aplica parches versionados sobre el tag oficial Mixxx 2.5.6. Los
scripts verifican por SHA-256 tanto el código base como las dependencias.

## macOS ARM64

Requisitos: Xcode Command Line Tools, CMake, Ninja, Git y unos 8 GB libres.

```bash
./scripts/build-mixxx-rx3-macos.sh
```

El script descarga las entradas verificadas, aplica `patches/0001` a
`0010`, compila `NauticMixxx.app`, ejecuta las pruebas RX3, instala skin y
mapping dentro del bundle, genera el icono y firma de forma ad hoc.

Variables opcionales:

- `RX3_BUILD_ROOT`: caché y carpeta de compilación.
- `RX3_BUILD_JOBS`: paralelismo.
- `NAUTIC_SIGNING_IDENTITY`: identidad Developer ID/Application para firmar.

## Windows x64

Ejecuta en PowerShell de Visual Studio 2022:

```powershell
./scripts/build-mixxx-rx3-windows.ps1 -WorkRoot C:\nauticmixxx-build -Jobs 4
```

También puede ejecutarse manualmente desde GitHub Actions. El workflow genera
el runtime, ejecuta la suite RX3 y sólo entonces llama al empaquetador.

## Fuentes correspondientes

`python3 scripts/package-release.py` empaqueta el árbol completo de Mixxx ya
parcheado junto con recetas, skin, mapping, efectos, atribuciones y herramientas
de validación. Esto permite reconstruir el binario publicado sin depender del
árbol de trabajo privado.
