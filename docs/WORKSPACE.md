# Organización del workspace

## Fuentes de verdad

- `controllers/`: mapper vigente del Inpulse 500.
- `skins/`, `effects/` y `patches/`: personalizaciones
  reproducibles de NauticMixxx.
- `../`: fuente nativa parcheada de Mixxx.
- `packaging/`, `scripts/` y `tests/`: soporte propio de compilación y distribución.
- `../../../release/1.0.0/`: única release publicada conservada en el workspace.
- `../../../archive/`: espacio reservado para futuros componentes retirados. Los históricos están en Git.

## Política de retención

Se conserva una sola versión completa en `../../../release/`. Los directorios `tmp/`,
`build/`, las carpetas `build*` de la raíz Mixxx y las carpetas de QA son
salidas reconstruibles y no forman parte de la fuente de verdad.

Antes de publicar un cambio incremental:

```bash
./scripts/validate-release.sh
./scripts/build-mixxx-rx3-macos.sh
python3 scripts/package-release.py --output build/release-candidate/<version-nueva>
```

No crees copias `before-*` dentro del proyecto. Para recuperar una versión usa
el paquete de fuentes de la release anterior o control de versiones.

Solo después de una orden explícita de promoción se copian artefactos validados
a `../../../release/<version-nueva>/` y se actualizan manifiesto y checksums.

Si ya no se necesita la caché de compilación, se pueden retirar las salidas
reconstruibles con:

```bash
./scripts/clean-workspace.sh
```

El script conserva las fuentes y la release vigente; elimina cachés, builds y
salidas de QA de NauticMixxx.
