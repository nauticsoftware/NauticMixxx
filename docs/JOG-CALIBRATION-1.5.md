# Jog wheels — calibración inicial para v1.5

## Diagnóstico

El Hercules DJControl Inpulse 500 envía el giro del borde en CC `09` y el de
scratch en CC `0A`. El byte de giro codifica **sentido y velocidad**: `01` a
`3F` en sentido horario, `7F` a `40` en sentido antihorario. No son cuadros de
audio ni grados absolutos de giro. El mapeo anterior convertía el byte con
`inValueScale()` y enviaba el resultado `-64..63` directamente a `[ChannelN],jog`.
Por eso los valores bajos se perdían en el suavizado y los altos generaban
correcciones difíciles de dosificar.

Mixxx aplica a `jog` una ganancia de `0.1` y un promedio móvil de 25 buffers
durante la reproducción. En pausa usa, además, un multiplicador de `18` para
búsqueda. La v1.5 aplica una curva únicamente al borde **mientras la pista
reproduce**; conserva la búsqueda en pausa, el scratch de la superficie, SHIFT,
el ajuste de loops y el ajuste del beatgrid.

## Seteo inicial implementado

`jog = signo × sensibilidad × [1.9 + 0.5 × ln(magnitud) / ln(63)]`, con magnitud limitada a
`1..63`. Los extremos configurables están en el mapper como
`rx3JogBendSlow = 1.9` y `rx3JogBendFast = 2.4`. El multiplicador general
`rx3JogBendSensitivity = 1.0` permite ajustar ambos sin tocar scratch ni SHIFT.

| Valor MIDI del borde | Antes: valor a Mixxx | v1.5: valor a Mixxx |
| ---: | ---: | ---: |
| 1 | 1 | 1.90 |
| 4 | 4 | 2.07 |
| 16 | 16 | 2.23 |
| 63 | 63 | 2.40 |

Esto aumenta la respuesta del giro muy lento y limita de forma fuerte los
giros rápidos. La cifra no representa un porcentaje fijo de pitch bend ni una
distancia fija por vuelta: la salida real depende de la frecuencia de mensajes
MIDI, el tamaño del buffer de audio y el filtro del motor de Mixxx.

## Contraste con los mapeos de Pioneer en Mixxx

| Mapeo oficial | Giro del borde durante reproducción | Ajuste expuesto |
| --- | --- | --- |
| DDJ-400 | `(valor − 64) × 0.8` hacia `jog` | `bendScale` |
| DDJ-FLX4 | `(valor − 64) × 0.8` hacia `jog` | `bendScale` |
| DDJ-SX | `(valor − 64) / 5 × sensibilidad` hacia `jog` | `jogwheelSensitivity`, predeterminado `1`; SHIFT tiene otro multiplicador |

Los tres separan scratch del bend. El DDJ-SX es una buena referencia para
exponer una sensibilidad editable, pero sus divisores no se pueden trasladar
directamente al Inpulse: Pioneer centra estos mensajes en `0x40`, mientras el
Inpulse entrega `01..3F` / `7F..40` como intensidad y sentido. El Roland DJ-505
confirma la misma separación de funciones, sin aportar una cifra universal.
La variante comunitaria DDJ-400 de cuatro decks cambia la selección de decks,
no es una calibración física para el Inpulse. El issue de FLX4 `#12747` trata
de salidas MIDI de samplers inválidas, no de sensibilidad del jog.

En XDJ/CDJ, con VINYL activo, el borde sigue haciendo pitch bend temporal y
la superficie superior hace scratch; `JOG FEEL/ADJUST` cambia la resistencia
física. AlphaTheta no publica una curva de pitch bend del borde que permita
copiar un valor numérico exacto. Tampoco corresponde usar la cifra de búsqueda
por vuelta con la pista pausada como calibración del pitch bend al reproducir.

## Validación física pendiente

1. Cargar dos copias de una pista a 120 BPM con beatgrid correcto. Desactivar
   SYNC y SLIP, igualar el tempo con el fader y activar VINYL.
2. En ambos decks, mover solo el borde unos 15–20 grados lentamente. Debe
   aparecer una corrección audible y de fase, sin detener la reproducción ni
   entrar en scratch. Repetir en ambos sentidos.
3. Girar el borde cerca de media vuelta a velocidad normal. La pista no debe
   saltar ni adelantar un beat completo; al soltarlo debe volver al tempo del
   fader. Repetir con giros rápidos y comparar con una XDJ/CDJ real usando la
   misma pista, BPM y ángulo de giro.
4. Tocar y girar la parte superior: comprobar que scratch sigue independiente.
   Con la pista pausada y con SHIFT, comprobar que la búsqueda anterior sigue.
5. Registrar modelo/firmware, latencia de audio, valores MIDI durante un giro
   lento y uno rápido, y el desfasaje en milisegundos antes/después. Ajustar
   `rx3JogBendSlow` si el primer giro aún no corrige; ajustar
   `rx3JogBendFast` si el giro rápido aún se pasa. Si ambos comportamientos
   necesitan subir o bajar en la misma proporción, usar
   `rx3JogBendSensitivity` (por ejemplo `0.8` o `1.2`).

La prueba automática comprueba la curva y su simetría. La equivalencia física
con Pioneer requiere la comparación de los pasos 1–5; no está validada aquí.

## Fuentes

- [Hercules, comandos MIDI del DJControl Inpulse 500](https://ts.hercules.com/download/sound/manuals/DJC_Inpulse500/DJControlInpulse500_MIDI_Commands.pdf).
- [AlphaTheta, diagrama de hardware XDJ-RX3 para rekordbox](https://downloads.support.alphatheta.com/software_info/all-in-one-dj-systems/XDJ-RX3/XDJ-RX3_HardwareDiagram_rekordbox_E1.pdf).
- [AlphaTheta, uso del jog wheel de XDJ-AZ](https://downloads.support.alphatheta.com/manuals/all-in-one-dj-systems/XDJ-AZ/html/en/000COV_en/Using_the_jog_wheel/Using_the_jog_wheel.htm?rhtocid=_12).
- [Mixxx, mapeo oficial DDJ-400](https://github.com/mixxxdj/mixxx/blob/main/res/controllers/Pioneer-DDJ-400-script.js).
- [Mixxx, mapeo oficial DDJ-SX](https://github.com/mixxxdj/mixxx/blob/main/res/controllers/Pioneer-DDJ-SX-scripts.js).
- [Mixxx, mapeo oficial DDJ-FLX4](https://github.com/mixxxdj/mixxx/blob/main/res/controllers/Pioneer-DDJ-FLX4-script.js).
