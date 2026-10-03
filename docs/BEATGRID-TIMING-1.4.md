# Beatgrid y CUE — candidata 1.4.0

Informe técnico de v1.4.0. Mediciones de timing realizadas en macOS ARM64;
la validación del instalador Windows se documenta en TEST_REPORT.md.

## Diagnóstico medido

La playlist METRONOME contiene WAV y MP3 de 128 BPM a 44,1 y 48 kHz,
con 64 beats y el primer kick a 1 segundo. Los WAV originales coinciden
con los 64 samples indicados por sus JSON: error de pico de cero muestras.
Se conservaron copias exactas de los cuatro audios, export.pdb y los doce
ANLZ de estas pistas para repetir la prueba sin depender del montaje del USB.
El manifiesto local registra sus SHA-256.

Los MP3 llevan una cabecera Info/Xing compatible con LAME (Lavc60.31).
Sus 576 muestras de delay del encoder, más las 529 del decodificador,
suman 1105 muestras. CoreAudio entrega PCM sin ese inicio. El export de
Rekordbox mantiene el grid y el CUE en la otra coordenada temporal.

| Archivo | Primer kick PCM (sample) | Grid antes (sample) | Grid corregido (sample) | CUE corregido (sample) | Máximo error grid/kick, 64 beats |
| --- | ---: | ---: | ---: | ---: | ---: |
| MP3 44,1 kHz | 44101 | 45202 | 44098 | 44097,5 | 0,590 ms |
| MP3 48 kHz | 48001 | 49104 | 47999 | 47999 | 0,542 ms |
| WAV 44,1 kHz | 44100 | 44056 | 44056 | 44100 | 1,497 ms |
| WAV 48 kHz | 48000 | 48000 | 48000 | 48000 | 0,500 ms |

El grid original del WAV de 44,1 kHz tiene el primer kick a **999 ms**;
el CUE está a 1000 ms. Esa diferencia ya existe en ANLZ y no se corrige
inventando un desplazamiento para WAV. El MP3 decodificado tiene el pico
una muestra después del WAV por la compresión con pérdida.

## Implementación

- El offset se decide después de abrir el decodificador real, antes de
  proyectar grid, cues, loops y waveforms sobre la pista temporal.
- Se aplica únicamente a MP3 MPEG-1 Layer III con cabecera Info/Xing y tag
  compatible LAME/Lavc/Lavf, cuando CoreAudio confirma la frecuencia nativa
  y la longitud audible esperadas. No usa una constante de 25 ms.
- Los WAV, los exports originales y los decodificadores sin evidencia de
  trimming conservan sus coordenadas. No modifica archivos del pendrive.
- Los cues que quedarían antes del inicio audible se limitan a cero. Los
  loops colapsados se descartan de la proyección, preservando el catálogo.
- ANLZ conserva su reloj de detalle de 150 columnas por segundo; el origen
  acompaña al PCM sin estirar el padding a lo largo de toda la waveform.
- La candidata macOS tiene un identificador de bundle propio y crea su
  perfil aislado desde una plantilla interna, incluso al abrirla desde Finder.

## Validación y límites

La suite de timing terminó con **16 pruebas aprobadas y 3 opcionales
omitidas**, sin fallos. Incluye los cuatro archivos, los 64 beats de cada uno,
ocho seeks repetidos al CUE con PCM estable, cues al inicio, loops y el reloj
de waveform. Los tres casos omitidos requieren otras variables o fixtures;
no son las pruebas de METRONOME, que sí se ejecutaron.
La puerta de compilación RX3 + timing terminó con 31 aprobadas y las
mismas tres opcionales omitidas. Se verificaron el arranque desde Finder,
el perfil aislado, su mapping local, la firma y el icono propio.

Los MP3 se comprobaron con CoreAudio. libsndfile y FFmpeg 6 abren los WAV.
El proveedor FFmpeg 6 incluido en esta compilación no abre estos MP3
(av_seek_frame devuelve Operation not permitted); ese resultado se registra
como proveedor no disponible y no cuenta como validación MP3.
No se verificó la ruta de decodificación de Windows ni otros encoders.

PQTZ expresa los tiempos en milisegundos enteros; esa precisión y la del
export limitan la coincidencia con muestras de audio. PQT2 no contiene una
lista completa de beats con mayor precisión que sustituya a PQTZ.
No se modificaron los fades de CUE ni la latencia de salida. La comparación
audible con Rekordbox usando la misma interfaz, buffer y volumen sigue siendo
la comprobación final del usuario; la prueba de seeks no mide la salida física.

## Repetir la prueba

Desde la raíz del overlay NauticMixxx:

```sh
python3 scripts/test-metronome-timing.py \
  --test-binary /ruta/build/mixxx-test \
  --usb-root /ruta/al/USB-o-snapshot \
  --truth-dir /ruta/METRONOME \
  --output-dir /ruta/informes
```

La carpeta de verdad necesita los WAV y JSON originales. El USB o snapshot
necesita export.pdb, los cuatro audios y sus ANLZ en las rutas originales.
Los resultados se guardan como native-timing.json, native-tests.log,
native-tests.xml y wav-oracle.json.

## Referencias de formato

- [Deep Symmetry: ANLZ y beat grids](https://djl-analysis.deepsymmetry.org/rekordbox-export-analysis/anlz.html).
- [pyrekordbox: PQTZ y PQT2](https://pyrekordbox.readthedocs.io/en/latest/formats/anlz.html).
- [FFmpeg: interpretación del delay LAME y padding](https://github.com/FFmpeg/FFmpeg/blob/master/libavformat/mp3dec.c).
