# Compilación reproducible

NauticMixxx aplica parches versionados sobre el tag oficial Mixxx 2.5.6. Los
scripts verifican por SHA-256 tanto el código base como las dependencias.

## macOS ARM64

Requisitos: Xcode Command Line Tools, CMake, Ninja, Git y unos 8 GB libres.

```bash
./scripts/build-mixxx-rx3-macos.sh
```

El script descarga las entradas verificadas, aplica `patches/0001` a
`0011`, compila `NauticMixxx.app`, ejecuta las pruebas RX3, instala skin y
mapping dentro del bundle, genera el icono y firma de forma ad hoc.

Variables opcionales:

- `RX3_BUILD_ROOT`: caché y carpeta de compilación.
- `RX3_BUILD_JOBS`: paralelismo.
- `NAUTIC_SIGNING_IDENTITY`: identidad Developer ID/Application para firmar.

## Windows x64

Para distribuir sólo la skin con un instalador BAT que descarga Mixxx oficial
si hace falta:

```bash
python3 scripts/package-rx3-windows-skin.py
python3 scripts/test-windows-skin-package.py
```

El empaquetador deja un candidato en `build/test-candidate/1.1.0/`. La
distribución vigente está en `../../../release/1.1.0/` y contiene los BAT de
instalación y desinstalación más una carpeta de archivos. No incluye
`mixxx.exe` ni requiere compilar C++.

Para una aplicación NauticMixxx nativa completa (proyecto aparte), ejecuta en
PowerShell de Visual Studio 2022:

```powershell
./scripts/build-mixxx-rx3-windows.ps1 -WorkRoot C:\nauticmixxx-build -Jobs 4
```

También puede ejecutarse manualmente desde GitHub Actions. El workflow genera
el runtime, ejecuta la suite RX3 y sólo entonces llama al empaquetador nativo.
Ese ZIP también contiene `INSTALL-WINDOWS.bat` y `NauticMixxx-Files/`, pero
requiere un entorno Windows x64 para generar `mixxx.exe`. El empaquetador nativo
rechaza un runtime 1.0.0 o parches que no correspondan a 1.1.0.

## Fuentes correspondientes

`python3 scripts/package-release.py` empaqueta el árbol completo de Mixxx ya
parcheado junto con recetas, skin, mapping, efectos, atribuciones y herramientas
de validación. Esto permite reconstruir el binario publicado sin depender del
árbol de trabajo privado.
