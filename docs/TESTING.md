# Pruebas de la versión 1.0.0

## Validación automática

```bash
./scripts/validate-release.sh
```

La validación comprueba XML, JavaScript del mapping, versión, identidad,
archivos requeridos y patrones privados. Si existe `mixxx-test`, ejecuta:

```text
LibraryTableViewStateTest.*
Rx3*
RekordboxUsbSessionTest.*
RekordboxRuntimeTrackModelTest.*
```

Las pruebas que dependen de fixtures externos pueden aparecer como omitidas;
un fallo real impide generar la release.

## Matriz manual mínima

- Abrir y cerrar NauticMixxx sin controlador.
- Confirmar nombre e icono en Finder, Dock y menú.
- Verificar logo centrado con ambos decks vacíos y desaparición al cargar uno.
- Cargar, reproducir, pausar y expulsar pistas en ambos decks.
- Abrir SOURCE con ASSISTANT, volver, reabrir y seleccionar el mismo USB con una
  pista reproduciéndose: la app no debe cerrarse.
- Navegar playlists, buscar y cargar usando sólo el Inpulse 500.
- Probar Hot Cues A–H y sus colores en ambos decks y en el controlador.
- Probar loops, IN/OUT ADJUST, VINYL, ZOOM/GRID y Sound Color FX.
- Reiniciar y comprobar que el perfil y la biblioteca siguen intactos.

Publica junto al release el resultado de esta matriz, el sistema operativo, el
modelo de Mac/PC, el firmware del controlador y el hash del paquete probado.
