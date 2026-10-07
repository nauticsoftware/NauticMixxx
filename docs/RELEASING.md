# Publicar una versión

El código activo vive en `dev/` y los paquetes publicados en `release/`, ambos
en la raíz del workspace. Compilar o empaquetar dentro de `dev/` no publica una
versión. La promoción requiere una orden explícita del mantenedor para actualizar
la versión vigente.

Las notas de versión se escriben exclusivamente en inglés en un único archivo
`RELEASE_NOTES.md`, con el contenido de la versión vigente. No generar
traducciones ni archivos alternativos por idioma. `CHANGELOG.md` conserva el
historial. El empaquetador incluye únicamente `RELEASE_NOTES.md`.

## 1. Validar y generar candidatos

Desde `dev/nautic/`:

```bash
./scripts/validate-release.sh
./scripts/build-mixxx-rx3-macos.sh
python3 scripts/package-release.py \
  --app tmp/mixxx-native-rebuild/stage/NauticMixxx.app \
  --native-test-report tmp/mixxx-native-rebuild/build/rx3-tests.xml
```

El tercer comando genera `build/release-candidate/<versión>/`. Si se necesita
el DMG y está disponible `create-dmg`:

```bash
./scripts/package-macos-dmg.sh build/release-candidate/<versión>
```

El DMG usa el icono canónico y una plantilla de distribución guardada en
`packaging/macos/dmg-layout.dsstore`. Puede generarse sin automatizar Finder.
Si se distribuye con firma ad hoc y sin notarización, indicarlo en las notas
y conservar las instrucciones de primera apertura.

## 2. Revisar

Comprueba que el candidato tenga todos los artefactos prometidos por su
manifiesto, ejecuta `shasum -a 256 -c SHA256SUMS.txt` en esa carpeta y prueba
los ZIP extraídos en una carpeta temporal. Conserva las fuentes correspondientes
mientras distribuyas binarios.

Para una aplicación Windows nativa, ejecutar el workflow **NauticMixxx Windows
x64** sobre la rama candidata con `publish_release=false`. Deben pasar la
compilación, las pruebas nativas y la instalación/desinstalación del EXE.
Descargar el artefacto `nauticmixxx-windows-<run_id>`, incorporar sólo el
instalador a `build/release-candidate/<versión>/` y registrar los resultados
JUnit y la ejecución en `TEST_REPORT.md`. La evidencia de CI se conserva
separada de los archivos públicos de descarga. Actualizar manifiesto y hashes.

`publish_release=true` se reserva para `main` y una release ya existente.
La edición Windows histórica 1.1.0 contiene sólo la skin; las versiones nativas
posteriores incluyen el ejecutable y los parches del motor.

## 3. Promover y comunicar

Tras una solicitud explícita, copia los artefactos aprobados a
`../../../release/<versión>/`, verifica de nuevo manifiesto y checksums e informa
qué archivos y plataforma se actualizaron. Al limpiar versiones obsoletas,
conserva los paquetes, fuentes y evidencia de la versión vigente, además de
las dependencias y carpetas de compilación que todavía utiliza.

Para GitHub, crea el tag y el Release de la versión validada, adjunta los
artefactos aprobados y describe las pruebas físicas pendientes. Nunca incluyas
certificados, claves, perfiles personales, bases SQLite, música ni logs.

La release local vigente está en `../../../release/1.9.0/`. Los paquetes de
versiones locales anteriores fueron eliminados para liberar espacio.
