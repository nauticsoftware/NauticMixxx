# Plan v1.3: categorías exportadas y navegación del BROWSER

Fecha: 2026-10-01. Estado: implementación principal en el parche 0014;
proveedores especiales y validación física pendientes. Complementa
`PLAN-1.3-USB-AUTODISCOVERY.md` y el parche 0013.

## Estado de la implementación

El parche 0014 ya lee el orden y la visibilidad del menú exportado de las
tablas 16/17, lo conserva por sesión y usa el catálogo temporal para construir
ARTIST, ALBUM, GENRE, KEY, BPM, RATING, YEAR, LABEL, REMIXER, COLOR y DATE
ADDED. TRACK, PLAYLIST, SEARCH e HISTORY tienen rutas propias. SOURCE deja el
foco en categorías; entrar en una lista final oculta la columna intermedia y
activa PREVIEW, TRACK, ARTIST, BPM y GENRE. La lectura real de NAUTICBOY mostró
PLAYLIST → ARTIST → ALBUM → TRACK → KEY → HISTORY → SEARCH → MATCHING → FOLDER →
DATE ADDED. No se impuso el orden de ejemplo.

Por decisión del usuario, MATCHING, FOLDER y REC quedan para versiones futuras.
MATCHING y FOLDER se muestran, cuando están exportadas, con un panel
«COMING SOON». REC no figura en este export y no se añadió como entrada
fija. La lectura de HISTORY reconoce
las tablas 11/12, pero el USB disponible no contiene filas de historial; falta
validarla contra una exportación con sesiones grabadas. Para completar la
paridad física futura harán falta muestras controladas de MATCHING, FOLDER e
HISTORY, y una comprobación en el equipo. El USB habitual no se modifica.

## Resultado acordado

Al elegir un dispositivo en SOURCE, el usuario queda en la selección de
categorías. La preparación automática del USB continúa independientemente
de esa elección; terminar de leerlo no abre ninguna categoría.

Las categorías y su orden proceden del export del dispositivo seleccionado.
El orden ARTIST → ALBUM → TRACK → KEY → PLAYLIST → HISTORY → MATCHING →
FOLDER, con REC según las capacidades confirmadas, es una referencia de uso,
no una lista que deba imponerse sobre la configuración exportada.

Al entrar en una lista final de pistas se conserva la barra de categorías,
se oculta la columna intermedia y la tabla ocupa el espacio liberado:

`CATEGORÍAS | PREVIEW | TRACK | ARTIST | BPM | GENRE`

BPM y GENRE sólo se agregan en este modo expandido. Se interpreta la frase
sobre anchos como GENRE aproximadamente dos veces el ancho de BPM. BPM debe
mostrar cuatro cifras y un punto, por ejemplo `138.1`. TRACK y ARTIST tienen
prioridad para aprovechar el resto del ancho.

## Evidencia revisada

### Código actual

- `src/widget/wrx3browser.h`: `populateCategories()` crea exclusivamente TRACK
  y PLAYLIST y llama a `selectCategory()`. `chooseSource()` fuerza la fila 1.
  `selectCategory()` activa también el primer hijo de una playlist/carpeta.
  Estas tres decisiones explican la entrada automática que se quiere quitar.
- `updateSelectedDevice()` entra en una categoría al finalizar la carga.
  Debe adaptarse para que la precarga de 0013 respete la elección del usuario.
- `showFacet()` consulta la tabla SQL local `library`. Ese camino no sirve
  para las categorías del USB: sus pistas viven en un catálogo temporal.
- `focusTracks()` cambia el foco, pero no oculta el árbol ni la lista de filtros.
  `back()` depende de la visibilidad de esos widgets: habrá que reemplazar
  esa deducción por un estado de navegación explícito.
- `src/widget/wtracktableview.cpp`: `applyRx3Columns()` fija las columnas y
  tamaños actuales; `setStretchLastSection(true)` haría crecer GENRE al añadirlo
  al final. Es necesario asignar el espacio flexible a TRACK y ARTIST.
- `RekordboxRuntimeTrackModel` ya expone género y BPM. `RuntimeTrack` incluye
  artista, álbum, key, rating y color; `rawMetadata` conserva más campos,
  incluidos label, remixer, year y date_added extraídos por el lector PDB.
- Hercules y DDJ-FLX6 usan controles de navegación RX3. El comportamiento debe
  resolverse en el navegador común y verificarse con ambos mappings.

### Documentación y lectura del USB

El manual de Rekordbox 7.0.4 sitúa Category en DJ System, en modo EXPORT, y
permite elegir elementos y orden, con configuración por dispositivo. Esto
confirma el comportamiento, aunque la ruta exacta de preferencias varía entre
versiones; no debe asumirse siempre Preferences → View → Category.
[Manual de Rekordbox, páginas 232–233](https://cdn.rekordbox.com/files/20241004105932/rekordbox7.0.4_manual_EN.pdf).

El manual de Pioneer XDJ-RX3 confirma categorías configurables desde Rekordbox,
navegación por niveles y BACK para regresar al nivel anterior. Las cinco
columnas solicitadas se consideran el diseño de NauticMixxx; no se afirma que
sean una reproducción literal de todas las pantallas del hardware.
[Manual del fabricante, copia consultada: páginas 23–24 y 30](https://device.report/m/83455bbb2bd6b5eb462bc53625075fae427997e662a1d9889f68662be425501f).

Se inspeccionó en sólo lectura `/Volumes/NAUTICBOY/PIONEER/rekordbox/export.pdb`:

- Tabla decimal 16 (`0x10`): 27 descriptores, incluyendo ARTIST, ALBUM, TRACK,
  PLAYLIST, FOLDER y MATCHING. No se encontró un descriptor REC en esa tabla.
- Tabla decimal 17 (`0x11`): registros de ocho bytes compatibles con id,
  referencia de contenido, indicadores y posición del menú.
- La lectura preliminar de posiciones no nulas da PLAYLIST, ARTIST, ALBUM,
  TRACK, KEY, HISTORY, SEARCH, MATCHING, FOLDER y DATE ADDED.
- MATCHING contiene indicador `0x02`; no debe descartarse por usar una prueba
  ingenua `flags == 0`, ni declararse compatible sin validar su significado.
- Tabla decimal 18 (`0x12`): otra configuración ordenada, que debe distinguirse
  de las categorías antes de interpretarla como opciones de ordenación.

La implementación de referencia consultada describe los registros de menú y
sus campos. Se usará para contrastar el formato, no como garantía de que todas
las versiones del export o el RX3 se comportan igual.
[Código de referencia del formato](https://github.com/vynulldev/vynull/blob/main/pdb/defaults.go).

Hay un conflicto que resolver: el esquema Kaitai incluido en el repositorio
deja 17/18 como desconocidos, mientras otra documentación histórica asigna
historial a `0x11`/`0x12`. Los registros observados en este USB son de menú.
No se implementará HISTORY interpretando esas tablas por su número sin
comprobar estructura y variante.
[Investigación original de DeviceSQL](https://djl-analysis.deepsymmetry.org/rekordbox-export-analysis/exports.html).

## 1. Confirmar el contrato del export antes de ampliar la interfaz

Crear muestras pequeñas con exportaciones controladas de Rekordbox: cambiar
una categoría por vez, ocultarla, reordenarla y exportar de nuevo. Comparar
los archivos resultantes fuera del USB de uso habitual y registrar versión
de Rekordbox, formato de biblioteca y, para comparación física, firmware RX3.

Confirmar por diferencias el campo de visibilidad, posición, referencias,
indicador especial de MATCHING y la separación Category/Sort/Column. Distinguir
ausencia de configuración, lista explícitamente vacía y archivo inválido.
Validar al menos dos variantes de export disponibles; no prometer soporte
OneLibrary por la sola presencia de `exportLibrary.db`.

Entregable: especificación breve de bytes verificados y fixtures pequeños sin
audio personal. El USB original se mantiene como muestra de lectura.

## 2. Incorporar categorías al catálogo temporal

Añadir un lector acotado de menú junto a `rekordboxdatabase.cpp`, usando los
límites de fila/página ya validados. Construir un modelo con id estable,
etiqueta, orden, indicadores originales, visibilidad y capacidad soportada.

Agregar la configuración al `RuntimeCatalog` durante `RekordboxUsbSession::load()`
y publicarla con la misma sesión/generación del dispositivo. La interfaz no
leerá archivos ni ejecutará SQL para resolver categorías.

Reglas:

- Respetar orden explícito; no ordenar alfabéticamente la barra.
- Una categoría oculta no reaparece por tener pistas o datos asociados.
- Un id desconocido no se interpreta como otra categoría ni rompe el catálogo.
- Si falta configuración, usar un fallback documentado de categorías realmente
  soportadas. Registrar si el menú viene del export o del fallback.
- Configuración dañada puede degradar el menú sin invalidar pistas válidas.
- Cada dispositivo mantiene su propio menú e índices de agrupación.
- Detectar cambios del export en una nueva sesión; no reutilizar configuración
  de otra generación o de otro USB con el mismo nombre.

## 3. Proveer datos reales para cada sección

Actualización de alcance para v1.3: MATCHING, FOLDER y REC quedan aplazadas a
versiones futuras. Sus filas siguientes conservan el análisis técnico para
cuando se retome ese trabajo; no son criterios de aceptación de v1.3.

| Sección | Implementación y condición de aceptación |
| --- | --- |
| ARTIST / ALBUM / GENRE / KEY | Agrupar pistas del USB por identidad y metadatos; conservar ids de artista/álbum para evitar fusionar homónimos. Definir tratamiento de valores ausentes. |
| TRACK | Todas las pistas del USB; al confirmar entra directamente en la tabla expandida. |
| BPM / RATING / YEAR / LABEL / REMIXER / COLOR / DATE ADDED | Índices sobre campos exportados. Preservar valores originales y definir agrupaciones/rangos según evidencia RX3; ordenar numéricamente BPM/año/rating. |
| PLAYLIST | Árbol exportado, carpetas anidadas y orden original de pistas. Resaltar un elemento no equivale a abrirlo. |
| HISTORY | Decodificar el historial realmente exportado y sus referencias. Verificar variantes y orden de reproducción. No generar historial en el USB como efecto de navegar. |
| MATCHING | Identificar las relaciones/criterios exportados y el contexto de pista/deck requerido. No sustituirlo silenciosamente por similitud de BPM o key. |
| FOLDER | Distinguir carpetas físicas de carpetas de playlists. Confinar navegación al USB; inspeccionar sólo la carpeta solicitada, sin escanear todo el audio. Verificar cómo se admiten archivos fuera del catálogo temporal. |
| REC | Verificar si la entrada es fija en el RX3, cuándo aparece y dónde busca grabaciones. Propuesta para v1.3: explorar grabaciones existentes si son compatibles con la política de lectura. Grabar y escribir al USB requiere alcance y diseño propios. |
| SEARCH y otras categorías exportadas | Conectar con búsqueda sobre la sesión o implementar su proveedor específico. Documentar cualquier entrada pendiente de soporte. |

HISTORY requiere datos reales y una prueba de navegación. MATCHING, FOLDER y
REC se consideran pendientes: cuando el export incluya su entrada, se muestra
«COMING SOON» en vez de una lista vacía que aparente funcionamiento.

## 4. Reemplazar la navegación implícita por estados explícitos

Mantener estado por sesión/dispositivo: categoría elegida, pila de niveles,
id seleccionado, posición de scroll, filtro y pista seleccionada. La vista y
el foco se derivan de ese estado; no de si un widget está visible.

| Acción | Resultado |
| --- | --- |
| SOURCE → elegir USB | Mostrar categorías; foco en la barra, sin entrar automáticamente en la primera. |
| Girar encoder o mover selección | Cambiar únicamente el elemento resaltado del nivel actual. |
| Confirmar TRACK | Mostrar lista de pistas expandida. |
| Confirmar PLAYLIST | Mostrar carpetas/playlists en columna intermedia; aún no seleccionar una playlist automáticamente. |
| Confirmar carpeta | Descender un nivel y conservar el anterior en la pila. |
| Confirmar playlist o valor final de filtro | Mostrar sus pistas; ocultar columna intermedia y activar las cinco columnas. |
| BACK desde pistas | Restaurar nivel anterior, columna intermedia si corresponde, selección y scroll. TRACK vuelve directamente a categorías. |
| BACK desde raíz de categoría | Volver a categorías; un siguiente BACK vuelve a SOURCE. |
| Cerrar/reabrir BROWSE | Recuperar la ubicación previa del mismo dispositivo/sesión. |
| Elegir dispositivo desde SOURCE | Iniciar elección de categorías, sin reanudar automáticamente una playlist. |
| Termina precarga | Actualizar disponibilidad. Sólo completar una entrada que el usuario haya confirmado durante la lectura. |
| Desconexión o resultado antiguo | Invalidar navegación de esa generación y evitar mostrar contenido de otro USB. |

Ratón, teclado, encoder y BACK deben enviar las mismas acciones semánticas.
LOAD 1/2 conserva la operación explícita de cargar al deck. No convertir ENTER
en carga como efecto de esta modificación.

## 5. Diseñar dos presentaciones de la tabla

**Selección por niveles:** barra de categorías + columna intermedia de
carpetas/valores + previsualización de pistas cuando corresponda. Mantener
PREVIEW, TRACK y ARTIST como columnas principales de esa previsualización.

**Lista de pistas:** barra de categorías + tabla completa. Retirar árbol/filtros
del espacio del layout; no dejar un contenedor vacío con ancho reservado.
Mostrar exactamente PREVIEW → TRACK → ARTIST → BPM → GENRE.

Crear una política de columnas explícita, por ejemplo `HierarchyPreview` y
`ExpandedTracks`, y pasarla desde el estado de navegación a `WTrackTableView`.
Reaplicarla al cambiar modelo, fuente, tamaño de ventana o panel INFO.

- Ancho BPM: medir `000.0` con la fuente real y añadir padding/cabecera.
  Mostrar un decimal con punto, sin truncar valores válidos; ausente = «—».
- Ancho GENRE: aproximadamente 2 × BPM, con elipsis y texto completo en INFO.
- PREVIEW: ancho acotado y adaptable; evitar que prive a TRACK de espacio.
- TRACK/ARTIST: repartir el ancho restante, inicialmente 55/45, verificando
  títulos largos y fuentes/escalado de pantalla.
- Desactivar el estiramiento automático de la última sección. BPM y GENRE
  quedan al extremo derecho con ancho controlado.
- Evitar columnas residuales, saltos de orden y scroll horizontal. La barra
  de categorías sí debe desplazarse verticalmente, manteniendo visible la
  selección al usar el encoder.
- El ancho visual de BPM no reduce la precisión almacenada ni el beatgrid.

## 6. Cambios previstos y secuencia de entrega

1. Lector de menú verificado + fixtures: `rekordboxdatabase.*` y un módulo
   específico de configuración de navegación si ayuda a separar el formato.
2. Configuración e índices por sesión: `rekordboxruntimecatalog.*`,
   `rekordboxusbsession.*`, `rekordboxfeature.*` y modelo temporal.
3. Estado de navegación independiente de widgets, probado con acciones
   SOURCE/confirmar/BACK/precarga/desconexión.
4. Integración en `wrx3browser.h`: sustituir filas fijas y filtros SQL; separar
   selección de entrada; conservar árbol y scroll al expandir pistas.
5. Política de columnas en `wtracktableview.*`; ajustar estilo de la skin sólo
   donde lo necesite el layout, preservando decks y reproducción.
6. Completar proveedores especiales y contrastarlos con exports/RX3.
7. Revisar mappings Hercules/FLX6 y pruebas existentes; crear el siguiente
   parche reproducible disponible, previsto como 0014 después de 0013.

El análisis puede avanzar con las muestras existentes. Las pruebas que exigen
reexportar categorías o comparar el hardware se harán con un medio de prueba
y una secuencia registrada, sin alterar el export habitual para deducir bytes.

## 7. Pruebas y puerta de aceptación

- Parser: visibles/ocultas/reordenadas, flags especiales, ids desconocidos,
  filas truncadas, referencias inválidas y diferencias Category/Sort/Column.
- Catálogo: dos USB con ids coincidentes no mezclan pistas ni categorías;
  artistas/álbumes homónimos, metadatos vacíos y caracteres Unicode.
- Navegación: SOURCE termina en categorías; mover no entra; confirmar sí;
  carpetas anidadas y BACK conservan selección/scroll.
- Precarga: llegada de datos no roba el foco ni selecciona PLAYLIST; una
  elección explícita pendiente sí se resuelve al finalizar.
- Layout: columna intermedia ocupa cero ancho en pistas; aparecen BPM y GENRE
  sólo en modo expandido; al volver se restaura la presentación anterior.
- Visual: 1280×800, ventana menor y Retina; fuentes reales, títulos largos,
  INFO abierto/cerrado y categorías que exceden la altura disponible.
- Hardware/controlador: encoder, pulsación, BACK, SOURCE y LOAD de Hercules y
  FLX6; sin doble activación por pulsación/liberación.
- USB: reconexión, reexportación con orden distinto, dos unidades, selección
  durante lectura y conservación del contrato de sólo lectura.
- Paridad especial: muestra verificable para HISTORY. MATCHING/FOLDER/REC
  quedan fuera del alcance de v1.3 por decisión posterior del usuario. La
  equivalencia con un RX3 sólo se afirmará para los comportamientos
  contrastados; el formato visual de cinco columnas sigue el pedido del usuario.

Aceptar la entrega cuando elegir el USB deje al usuario en categorías, el
menú coincida con la configuración exportada verificada y todos los caminos
hacia pistas y de regreso produzcan el layout y foco previstos sin afectar
la preparación automática ni cargar una pista accidentalmente.
