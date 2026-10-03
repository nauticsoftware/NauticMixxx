# Plan v1.3: preparación automática de USB Rekordbox

Fecha: 2026-09-30. Estado: implementación candidata en `dev/`; validado el
arranque con USB ya conectado. Falta probar montaje y reconexión físicos.

## Resultado esperado

NauticMixxx detecta y prepara en segundo plano los USB Rekordbox conectados al
iniciar la aplicación y los que se conecten durante su uso. SOURCE presenta los
dispositivos y su estado; abrirlo no inicia ni reinicia la lectura. Seleccionar un
USB preparado permite navegar directamente por TRACK y PLAYLIST.

Si el usuario llega antes de terminar la lectura, se muestra el estado real y el
contenido aparece automáticamente al finalizar, sin volver a SOURCE. El tiempo
físico de lectura depende del pendrive y del tamaño del export; no se promete
disponibilidad instantánea después de conectarlo.

La primera entrega se valida en macOS. El diseño del servicio debe permitir
integrar otros sistemas sin acoplar su funcionamiento a widgets ni a APIs macOS.

## Hallazgos comprobados en el código

- `src/widget/wrx3browser.h`: `showSources()` simula un clic en la raíz Rekordbox
  cada vez que se abre SOURCE. Esa acción dispara descubrimiento y navegación.
- `src/library/rekordbox/rekordboxfeature.cpp`: `activateChild()` descarta la
  selección mientras existe descubrimiento o lectura pendiente. Seleccionar un
  dispositivo recién mostrado puede, por lo tanto, no iniciar su preparación.
- La lectura de `RekordboxUsbSession` comienza al activar un nodo de dispositivo;
  descubrir el volumen por sí solo no prepara su catálogo.
- `chooseSource()` deduce la carga por ausencia de hijos del árbol y arma un
  temporizador de 15 segundos que muestra «USB unavailable. Open SOURCE to retry.»
  sin consultar el resultado de la sesión. Un dispositivo sin playlists también
  puede confundirse con uno pendiente.
- `RekordboxFeature::activate()` cambia explícitamente a `REKORDBOXHOME`, la vista
  HTML «Rekordbox USB (read-only)» que aparece en las capturas.
- `onTracksFound()` cambia el modelo visible al finalizar. Usarlo sin cambios
  para precarga podría desplazar la navegación cuando termine otro USB.
- En macOS, el descubrimiento actual sólo recibe las rutas autorizadas guardadas.
  La recuperación de permisos y el diálogo de selección están dentro de
  `activate()`. Además, se vuelve a guardar únicamente la lista de raíces presentes,
  por lo que una unidad ausente puede perder su entrada de reconocimiento.
- `updateSourceInfo()` deja Songs y Playlists en «—» incluso después de cargar.
- `RekordboxUsbSession::populate()` procesa metadatos ANLZ de cada pista antes de
  publicar el catálogo. Hay que medir este coste en exports grandes.

Estos hallazgos explican mecanismos compatibles con las capturas. Todavía falta
reproducir y medir la secuencia exacta con el pendrive físico del usuario.

## 1. Separar descubrimiento, preparación y navegación

Crear un coordinador de dispositivos en `src/library/rekordbox/`, propiedad de la
biblioteca. Debe arrancar cuando estén listas sus dependencias, independientemente
de que la skin o SOURCE estén visibles.

- Inventario inicial de volúmenes montados y escucha de montaje/desmontaje en
  macOS, con reconciliación al volver del reposo y al recuperar actividad.
- Agrupar avisos repetidos y esperar brevemente a que un montaje esté disponible.
- Comprobar sólo ubicaciones conocidas del export, sin recorrer toda la música.
- Encolar automáticamente la preparación de cada export reconocido y accesible.
- Ejecutar lectura y análisis del catálogo fuera de los hilos de interfaz y audio,
  con concurrencia limitada y prioridad baja.
- Evitar nuevas lecturas de un catálogo válido si no cambió su identidad/export.

SOURCE se suscribe a los cambios del coordinador y conserva únicamente funciones
de selección y navegación. Abrirlo varias veces no genera trabajos adicionales.

## 2. Representar el estado real de cada dispositivo

El coordinador mantiene estados explícitos: detectado, necesita acceso,
preparando, listo, error y desconectado. Publica cambios de estado, catálogo y
contadores mediante señales hacia la interfaz.

- Usar identidad de volumen y generación de conexión, además de la huella del
  export, para distinguir desconexiones/reconexiones incluso en la misma ruta.
- Una tarea antigua no puede publicar resultados sobre una conexión nueva.
- La selección durante la preparación queda pendiente y se resuelve al terminar.
- Sólo el dispositivo actualmente seleccionado puede actualizar la tabla visible.
- No deducir disponibilidad por cantidad de playlists: un export válido sin
  playlists o vacío tiene un estado explícito y una presentación correcta.
- Reintentar automáticamente fallos transitorios de montaje/acceso con espera
  creciente y límite. Un export corrupto o no soportado requiere un mensaje
  concreto, no un ciclo permanente de reintentos.
- Conservar sesiones preparadas en memoria mientras la conexión sea válida.
  Una caché persistente de catálogos no es requisito de esta primera entrega.

## 3. Resolver el acceso a USB en macOS

Separar la detección de volúmenes de la autorización para leerlos. Revisar el
comportamiento de privacidad con el mismo identificador, firma y configuración
de distribución que usa la app real.

- Reutilizar las autorizaciones y bookmarks existentes donde correspondan.
- Mantener los tokens activos durante la vida de la sesión; una búsqueda no debe
  liberar el acceso de una unidad que ya está en uso.
- Conservar autorizaciones de unidades ausentes y resolver reconexiones/cambios
  de punto de montaje sin depender únicamente de una ruta guardada.
- Evitar lecturas indiscriminadas de volúmenes no autorizados: el código actual
  documenta posibles bloqueos bajo la privacidad de macOS.
- Si el sistema exige una autorización inicial, presentar una acción clara para
  concederla. Al concederla, continuar automáticamente la preparación pendiente.
  Abrir SOURCE nunca debe convertirse en una sucesión de diálogos o reintentos.

La automatización debe funcionar por completo con unidades accesibles; no debe
prometer eludir una denegación real de permisos del sistema.

## 4. Corregir la presentación de SOURCE, TRACK y PLAYLIST

En `wrx3browser.h`, reemplazar el temporizador de 15 segundos y las deducciones
basadas en filas por el estado del coordinador.

- SOURCE muestra las unidades detectadas y un indicador discreto de preparación.
- Songs y Playlists toman sus valores del catálogo preparado y se actualizan solos.
- Si se selecciona una unidad lista, mostrar directamente su contenido.
- Si sigue preparándose, conservar la selección y cambiar al contenido cuando
  esté listo. Al abrir PLAYLIST, seleccionar la primera playlist navegable;
  contemplar carpetas y el caso sin playlists, sin mostrar HTML intermedio.
- Mostrar únicamente estados útiles: preparando, sin USB, export vacío,
  necesita acceso o error concreto.
- Eliminar del flujo NauticMixxx la vista HTML `REKORDBOXHOME` y el texto que pide
  volver a abrir SOURCE. Separar las señales de refresco de las de navegación.
- Mantener la selección mediante identidad de dispositivo/playlist; no conservar
  índices de modelos que hayan sido reemplazados.

## 5. Medir tiempos y proteger la reproducción

Registrar duración de detección, permisos, lectura PDB, lectura ANLZ y publicación
del modelo. Medir consumo de memoria y respuesta de la interfaz mientras otro
deck reproduce audio.

La primera implementación reutiliza el lector existente. Si la lectura ANLZ de
todas las pistas domina el tiempo hasta navegar, dividir la preparación en un
catálogo básico navegable y enriquecimiento diferido, sin exponer pistas como
listas para cargar antes de resolver los datos que necesitan sus cues y beatgrid.
Esta decisión requiere mediciones y pruebas del contrato de catálogo inmutable.

Al desconectar, invalidar la sesión y cancelar o descartar tareas pendientes.
Comprobar también el cierre de la app durante una lectura para evitar esperas
indefinidas. La precarga no debe escribir en el USB ni importar o analizar audio.

## 6. Pruebas y criterios de aceptación

Agregar pruebas del coordinador con inventario de volúmenes, permisos y lector
simulados para reproducir carreras sin depender de un USB físico.

| Escenario | Resultado requerido |
| --- | --- |
| USB presente al arrancar; SOURCE permanece cerrado | La preparación empieza y termina en segundo plano. |
| USB conectado con la app abierta | Aparece y se prepara sin abrir SOURCE. |
| Selección durante descubrimiento o lectura | Se conserva y muestra contenido automáticamente al finalizar. |
| Lectura válida que tarda más de 15 segundos | Continúa preparando; no anuncia indisponibilidad por tiempo transcurrido. |
| Reabrir SOURCE repetidamente | No relanza el parser ni duplica sesiones, carpetas o pistas. |
| Dos USB, finalización fuera de orden | No cambia el USB, playlist o pista que está usando el usuario. |
| Desconexión/reconexión durante carga, incluso en la misma ruta | Se descartan resultados antiguos y se prepara la conexión nueva. |
| USB vacío, sin playlists, corrupto o con formato no soportado | Estado y mensaje específicos, sin falso estado de carga permanente. |
| Permiso concedido, denegado o pendiente | Flujo recuperable; al concederlo continúa sin repetir SOURCE. |
| Reinicio, reposo y reconexión de un USB autorizado | Recupera acceso cuando sigue siendo válido. |
| Navegación y carga de pistas durante precarga | Interfaz receptiva y reproducción sin regresiones atribuibles a la precarga. |
| Cierre durante lectura | Cancelación/cierre controlado, sin publicación posterior de resultados. |

Validar visualmente que nunca aparece `REKORDBOXHOME` en el navegador NauticMixxx,
que desaparece el mensaje de reabrir SOURCE y que los contadores se completan.
Ejecutar las suites existentes RX3, Rekordbox y protección de USB de sólo lectura.

La aceptación final requiere probar en macOS con el USB NAUTICBOY de las capturas,
un export grande y una segunda unidad, tanto con arranque en frío como con
conexión en caliente. Registrar los tiempos observados; no fijar cifras antes
de medir hardware real.

## Orden de entrega

1. Reproducción y mediciones de la versión base.
2. Coordinador, estados, eventos de volúmenes y gestión de permisos.
3. Preparación automática y protección frente a tareas obsoletas.
4. Integración de SOURCE/TRACK/PLAYLIST y eliminación del HTML intermedio.
5. Pruebas automáticas, validación visual y sesión con hardware real.
6. Incorporación a los parches reproducibles, documentación y candidato v1.3.

La implementación actual usa `RekordboxFeature` como coordinador, prepara una
sesión a la vez y reutiliza los lectores existentes. El parche reproducible es
`patches/0013-rx3-usb-autodiscovery.patch`. La compilación macOS de `mixxx` y
`mixxx-test` pasó. `validate-release.sh` pasó con 59 pruebas nativas aprobadas y
6 fixtures opcionales omitidas. La prueba de lectura ANLZ del USB NAUTICBOY
montado pasó en aproximadamente 31 segundos; incluye comprobaciones de todas
las pistas y no representa sólo el tiempo de preparación inicial.

En una ejecución visual del bundle macOS con perfil de prueba aislado y la
autorización USB existente, el catálogo comenzó a prepararse antes de abrir
SOURCE. Tras la lectura aparecieron automáticamente las playlists y sus pistas.
SOURCE informó «Ready», 1133 canciones y 6 playlists; no aparecieron el HTML
original de Mixxx ni el mensaje de volver a abrir SOURCE. El botón «BROWSE TEST»
se agregó sólo a la copia temporal del bundle para abrir la vista sin un
controlador físico; no forma parte de la skin del repositorio.

Quedan por medir la latencia real desde montaje hasta catálogo listo, el flujo
de permiso inicial de macOS y el comportamiento de conexión y reconexión en
caliente con el bundle v1.3. La publicación/promoción de v1.3 se gestiona
después de esas validaciones, conforme al proceso del repositorio.
