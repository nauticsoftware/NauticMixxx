# WAVEFORM DIVISIONS — v1.7

En Preferences → Waveforms → WAVEFORM DIVISIONS, elegir:

- TIME SCALE (predeterminado): divisiones cada 30 segundos del tiempo original
  del track. Las marcas de minuto son algo más anchas y largas.
- PHRASE: franja de bloques de Intro, Verse, Up/Down, Chorus/Drop, Bridge y Outro,
  según el análisis exportado por Rekordbox. El nombre aparece al dejar el mouse
  sobre el bloque. Sin análisis válido, la franja queda vacía y el tooltip indica
  que no hay frases disponibles.

La elección se guarda y se aplica a los overviews de Performance y Browser.
La waveform conserva su estilo BLUE, RGB o 3Band. Los HOT CUE conservan su paleta.

El overview reserva una franja inferior para divisiones, una línea blanca de tres
píxeles lógicos y separación de cuatro píxeles respecto de la waveform. Los HOT CUE
son cuadrados de diez píxeles; los inferiores están sobre la franja. Se dibujan
en orden A → H, de modo que cada letra posterior tapa a la anterior al solaparse,
independientemente de su ubicación temporal. El mouse sigue esa misma prioridad.
El triángulo de CUE permanece en primer plano. El playhead mide dos píxeles
lógicos tanto en el overview como en la waveform principal; conserva rojo detenido /
blanco en reproducción.

PHRASE lee PSSI normal o con máscara XOR, previamente asociado al audio mediante
PPTH. Proyecta los índices de frases sobre el PQTZ original y aplica el ajuste
temporal del decoder. La última frontera puede extrapolar un único beat cuando
PSSI termina inmediatamente después del último beat PQTZ. Los tamaños, índices,
orden de beats y fronteras se validan antes de publicar bloques. Los datos se
comparten con las waveforms importadas del track temporal; no se analiza audio
para generar frases ni se escribe en el USB.

Referencias del formato y la paleta:

- [Crate Digger: PSSI y máscara XOR](https://github.com/Deep-Symmetry/crate-digger/blob/main/src/main/kaitai/rekordbox_anlz.ksy).
- [Descripción de Song Structure](https://djl-analysis.deepsymmetry.org/rekordbox-export-analysis/anlz.html#song-structure-tag).
- [Beat Link: colores por mood, kind y variantes](https://github.com/Deep-Symmetry/beat-link/blob/main/src/main/java/org/deepsymmetry/beatlink/Util.java).

Las pruebas cubren límites de bloques con cambios de tempo y ajuste del decoder,
PSSI normal/cifrado, datos truncados o inválidos, divisiones de 30 segundos,
ausencia de análisis y todas las parejas sucesivas de HOT CUE a densidades 1×/2×.
La prueba opcional MIXXX_REKORDBOX_PHRASE_FIXTURE lee un USB existente sin cambios.
