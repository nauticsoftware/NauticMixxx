# Publicar una versión

El código activo vive en `dev/` y los paquetes publicados en `release/`, ambos
en la raíz del workspace. Compilar o empaquetar dentro de `dev/` no publica una
versión. La promoción requiere una orden explícita del mantenedor para actualizar
la versión vigente.

## 1. Validar y generar candidatos

Desde `dev/nautic/`:

```bash
./scripts/validate-release.sh
./scripts/build-mixxx-rx3-macos.sh
python3 scripts/package-release.py
```

El segundo comando genera `build/release-candidate/<versión>/`. Si se necesita
el DMG y está disponible `create-dmg`:

```bash
./scripts/package-macos-dmg.sh build/release-candidate/<versión>
```

Firma y notariza el bundle antes de la distribución pública si dispones de una
cuenta Apple Developer. La firma ad hoc solo sirve para pruebas.

## 2. Revisar

Comprueba que el candidato tenga todos los artefactos prometidos por su
manifiesto, ejecuta `shasum -a 256 -c SHA256SUMS.txt` en esa carpeta y prueba
los ZIP extraídos en una carpeta temporal. Conserva las fuentes correspondientes
mientras distribuyas binarios.

Para una aplicación Windows nativa, el workflow **NauticMixxx Windows x64**
debe completar la compilación y las pruebas nativas. La edición Windows 1.1.0
publicada es sólo skin: debe contener `INSTALL-WINDOWS.bat`,
`UNINSTALL-WINDOWS.bat` y `NauticMixxx-Files/`, y dejar claro que no contiene
`mixxx.exe` ni los parches nativos.

## 3. Promover y comunicar

Tras una solicitud explícita, copia los artefactos aprobados a
`../../../release/<versión>/`, verifica de nuevo manifiesto y checksums e informa
qué archivos y plataforma se actualizaron. No reemplaces la versión anterior
antes de preservar un punto de restauración.

Para GitHub, crea el tag y el Release de la versión validada, adjunta los
artefactos aprobados y describe las pruebas físicas pendientes. Nunca incluyas
certificados, claves, perfiles personales, bases SQLite, música ni logs.

La release local 1.0.0 existente tiene cuatro paquetes y `SHA256SUMS.txt`;
`NauticMixxx-1.0.0-skin.zip` y `release-manifest.json`, que se mencionaban en
documentación anterior, no están en ese directorio. No se deben anunciar como
archivos disponibles hasta generarlos y promoverlos.
