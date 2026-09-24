# Publicar una versión

## 1. Validar

```bash
./scripts/validate-release.sh
python3 scripts/package-release.py
```

En macOS, firma y notariza el bundle antes del empaquetado público si dispones
de una cuenta Apple Developer. Una firma ad hoc es válida para pruebas, pero no
elimina la advertencia de Gatekeeper.

## 2. Revisar los artefactos

En `release/1.0.0/` deben existir el ZIP macOS, la skin, las fuentes completas,
el DMG, el manifiesto y los checksums. Genera el DMG después del resto de los
artefactos para incorporarlo al manifiesto:

```bash
./scripts/package-macos-dmg.sh release/1.0.0
```

Ejecuta de nuevo:

```bash
cd release/1.0.0
shasum -a 256 -c SHA256SUMS.txt
```

Extrae los ZIP en una carpeta temporal y abre la app desde ese contenido, no
desde el árbol de compilación.

Ejecuta el workflow **NauticMixxx Windows x64** y espera que terminen en verde
la validación sintáctica del instalador y las pruebas nativas. Descarga y revisa
`NauticMixxx-1.0.0-Windows-x64.zip` y su `.sha256`; el ZIP debe contener
`INSTALL-WINDOWS.cmd` en la raíz. No publiques un ZIP creado con Mixxx stock ni
uno que contenga sólo la skin.

## 3. GitHub

1. Sube únicamente los fuentes admitidos por `.gitignore`.
2. Crea el tag anotado `v1.0.0`.
3. Crea un GitHub Release titulado `NauticMixxx 1.0.0`.
4. Copia el contenido de `RELEASE_NOTES.md`.
5. Adjunta todos los archivos de `release/1.0.0/`, excepto carpetas temporales,
   y añade el ZIP de Windows validado junto con su checksum.
6. Marca como prerelease cualquier build no probada en hardware real.

Nunca subas certificados, claves, perfiles personales, bases SQLite, música o
logs. Conserva `NauticMixxx-1.0.0-source.tar.gz` mientras distribuyas binarios.
