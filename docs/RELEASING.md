# Publicar una versión

## 1. Validar

```bash
./scripts/validate-release.sh
python3 scripts/package-release.py
```

En macOS, firma y notariza el bundle si dispones de una cuenta Apple Developer.
Sin esa cuenta, la firma ad hoc permite publicar una build comunitaria, siempre
que las notas indiquen claramente que no está notarizada y expliquen el flujo
**Ajustes del Sistema → Privacidad y seguridad → Abrir igualmente**. La firma
ad hoc no elimina la advertencia de Gatekeeper.

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
`NauticMixxx-1.0.0-Windows-x64.zip` y comprueba su `.sha256`; el ZIP debe contener
`INSTALL-WINDOWS.cmd` en la raíz. No publiques un ZIP creado con Mixxx stock ni
uno que contenga sólo la skin.

## 3. GitHub

1. Sube únicamente los fuentes admitidos por `.gitignore`.
2. Crea el tag anotado `v1.0.0`.
3. Crea un GitHub Release titulado `NauticMixxx 1.0.0`.
4. Copia el contenido de `RELEASE_NOTES.md`.
5. Adjunta únicamente el DMG y ZIP de macOS, el ZIP de Windows, las fuentes
   correspondientes y un único `SHA256SUMS.txt` normalizado con esos cuatro
   artefactos. No adjuntes el `.sha256` lateral de Windows ni archivos de una
   compilación anterior.
6. Documenta el hardware realmente validado y las combinaciones pendientes.
   Usa prerelease para builds experimentales o incompletas, no sólo por carecer
   de notarización de Apple.

Nunca subas certificados, claves, perfiles personales, bases SQLite, música o
logs. Conserva `NauticMixxx-1.0.0-source.tar.gz` mientras distribuyas binarios.
