# Calibración de waveforms — NauticMixxx 1.2

## Estado

El lector y el render de ANLZ están implementados. Tras la confirmación del usuario, Blue/RGB de detalle recuperan signo y nivel absoluto del audio PCM; sus colores siguen procediendo de Pioneer. **No se ha conseguido una réplica píxel a píxel.** El análisis propio es un experimento reproducible, separado del reproductor: no reemplaza los datos Pioneer ni reactiva el análisis automático de la biblioteca.
Se descartaron las capturas anteriores. Esta evaluación utiliza únicamente los nueve archivos de calibración y las 15 capturas nuevas (01–05, Blue/RGB/3-Band). No se recibieron capturas de 06–09.
## Datos y reproducibilidad

- `manifest.json` pegado por el usuario coincide con el manifiesto local.
- Lectura de `ANLZ0000.DAT`, `.EXT`, `.2EX`; se ignoran `._*` y `ANLZ0001.*`. El USB no se modifica.
- Detalle: PWV3/PWV5/PWV7 a 150 columnas/s. Overview: PWV4 extendido para Blue y RGB; PWV6 para 3-Band. PWAV se conserva como fallback Blue cuando no hay PWV4. No se sustituye el overview por el detalle.
- Modelo ajustado solo con 01–06; archivo congelado antes de leer 07–09.
- SHA-256 del modelo congelado: `bc5683c6e8d96d7e31c8935c09443056161927595129951db91fb802904e25c9`.
- Los hashes de las entradas de entrenamiento y el manifiesto están en [measured-transfer.json](measured-transfer.json).
## Discrepancia documentada en 3-Band

Deep Symmetry describe el orden mid/high/low. Los tonos de este conjunto establecen **low/mid/high** para estos exports: en PWV7 a t=3 s (60 Hz), los bytes son `[127, 6, 0]`; a t=47 s (1 kHz), `[11, 99, 4]`; a t=91 s (10 kHz), `[0, 1, 98]`. El lector usa el orden comprobado con esas señales. PWV5 se interpreta como entero big-endian: RRR GGG BBB HHHHH xx.
Fuente: [Deep Symmetry — Analysis Files](https://djl-analysis.deepsymmetry.org/rekordbox-export-analysis/anlz.html).
## Respuesta medida de frecuencia y nivel

En el barrido 01, los intervalos entre muestras que contienen cambios de banda dominante son:
| Representación | Graves → medios | Medios → agudos |
|---|---:|---:|
| RGB | 181,8–201,9 Hz | 1191,4–1322,5 Hz |
| 3-Band | 248,7–276,1 Hz | 2008,3–2229,4 Hz |
Son cruces de **valores exportados**, no medidas directas de filtros analógicos. La cuantización, normalización y dinámica impiden identificarlos con una frecuencia de corte y un orden de filtro únicos. También cae la respuesta de agudos cerca del extremo superior del barrido.
La blancura de Blue pasa de 0 a 7 a lo largo del barrido: las transiciones observadas en la rejilla de medición están aproximadamente en 120, 148, 182, 202, 249, 307 y 465 Hz. Los datos exactos de las muestras, sin redondear, están en `measured-transfer.json`.
El ajuste logarítmico de la escalera 06 entre −3 y −30 dBFS produjo exponentes efectivos de nivel 1.0140, 1.0260 y 1.9211 para graves, medios y agudos. No demuestran una función de transferencia universal.
### Pendientes efectivas de los valores exportados

Ajuste lineal de 20·log10(valor/pico) frente a log2(frecuencia), sobre el barrido 01 y entre el 8 % y el 50 % del pico de cada banda. Son pendientes del dato cuantizado, no órdenes de filtro identificados.

| Banda | Lado | Intervalo Hz | dB/octava | R² |
|---|---|---:|---:|---:|
| low | falling | 419.3–966.8 | -11.73 | 0.997 |
| mid | rising | 71.0–181.8 | 11.82 | 0.997 |
| mid | falling | 1629.7–4171.7 | -12.07 | 0.997 |
| high | rising | 1629.7–2474.8 | 20.16 | 0.998 |
| high | falling | 10678.3–13158.6 | -33.98 | 0.996 |

[Datos del ajuste](effective-slopes.json). La escasa resolución y el comportamiento dependiente del nivel limitan su interpretación.

## Análisis propio

Se implementó una STFT centrada de 4096 muestras, ventana Hann y salida de 150 columnas/s. Se ajustaron 96 bandas espectrales logarítmicas con coeficientes no negativos para 3-Band, una regresión de componentes normalizados para color/blancura y una regresión de envolvente local para las alturas. El tamaño de ventana y la estructura del modelo son decisiones del experimento; no se presentan como parámetros internos medidos de Pioneer.
El modelo está en [model.json](model.json). Puede analizar otro WAV PCM16 mediante `rekordbox-calibration.py --model model.json --audio pista.wav --output resultado`. El comando genera arrays; no escribe una base de datos ni una caché de la aplicación.
## Validación reservada

MAE por columna, incluyendo silencios. Alturas: 0–31; blancura y RGB: 0–7; bandas: 0–255.
| Archivo | Altura Blue | Blancura | RGB R/G/B | Altura RGB | 3-Band L/M/H |
|---|---:|---:|---|---:|---|
| 07 | 0.247 | 0.281 | 1.446 / 1.095 / 1.842 | 0.395 | 24.107 / 17.680 / 6.966 |
| 08 | 0.234 | 0.181 | 0.138 / 0.257 / 0.122 | 0.407 | 17.197 / 14.611 / 8.298 |
| 09 | 0.200 | 0.841 | 0.564 / 0.221 / 1.045 | 0.257 | 2.978 / 5.691 / 1.667 |

[Resultados completos por segmento](column-validation.json): MAE, RMSE, percentil 95 y fracción de columnas que coinciden tras cuantización, separados por componente.
### Resultado del loop 09

El loop no valida una equivalencia con Pioneer: quedan errores de color y bandas. No se reajustó el modelo sobre él. La revisión del modelo identifica limitaciones estructurales: la ventana fija mezcla ataques con sus alrededores, la regresión de color supone una combinación energética lineal, y seis señales de entrenamiento no identifican de forma única los detectores de envolvente, normalización por pista y tiempos de ataque/caída propietarios. Son hipótesis explicativas, no parámetros Pioneer confirmados.
## Medición de capturas

Se midieron los PNG originales de 2184–2199 píxeles de ancho; no las miniaturas reescaladas del chat. [Mediciones](capture-measurements.json).
- Paleta sólida de detalle 3-Band: graves `#0051E1`, medios `#FFA300`, solapamiento `#B36506`, agudos `#F5EAD6`.
- Overview 3-Band: `#0055E1`, `#FFA600`, `#FFFFFF`.
- En las capturas de calibración anteriores: grid gris `#4C4C4C`, compás blanco, playhead y triángulos `#FF0000`, etiqueta `#007DE1`. El ajuste posterior de la interfaz usa marcas blancas `#D0D0D0` y rojas `#FF0000` solo en los bordes, según las tres referencias nuevas. Playhead: 1 píxel en los originales.
- Grid completo: 114 píxeles de altura. Espaciado medido de pulso: 90,25 px en 01; 89 px en 02; 70,25 px en 05. Combinado con PQTZ: aproximadamente 112,53 px/s.
- En 03/04 no hay grid visible. En 05 la captura recorta la parte inferior del detalle. La familia tipográfica no puede identificarse de forma exacta desde estos PNG.
### Signo y nivel del audio, autorizados por el usuario

Blue/RGB de las capturas tienen oscilaciones con signo. PWV3/PWV5 solo contienen una altura de 5 bits, sin fase. Se incorporó una lectura de PCM para recuperar mínimos y máximos con signo, a 1500 intervalos/s, conservando los canales ANLZ a 150/s. Al reducir se toman extremos, sin suavizado temporal. Los WAV locales usados por el fixture coinciden byte a byte con el USB: [SHA-256](audio-copy-verification.json).

La lectura se hace en el trabajador de carga, antes de iniciar reproducción; se cancela si se cambia de pista o desaparece el origen. No escribe análisis ni caché en el USB o la biblioteca, ni activa ReplayGain/BPM/Key. Añade una lectura completa del archivo al cargar. Si falla o supera el límite de dos horas, se conserva el ANLZ simétrico. La suma estéreo `(L+R)/2` puede cancelar contenido en contrafase; la calibración aportada es L=R. Queda pendiente medir carga y reproducción con varios decks y controlador físico.

La escala absoluta se apoya en los 50 píxeles de altura medidos para PCM pico 0,50119 en 01/05, dentro del grid de 114 px; se usa 50 px por unidad de amplitud desde el eje. [Medición de extremos y gradientes](signed-measurements.json). El ajuste de fase conserva errores de contorno: el PCM y la función de muestreo del producto original todavía no coinciden exactamente. No se aplica un desplazamiento de fase inventado en la aplicación.

El gradiente RGB se midió desde el borde al centro de las columnas. Blue usa colores medidos por código de blancura PWV3: [tabla](blue-gradient-by-whiteness.json). Las capturas de detalle no contienen el código 7; su extremo blanco conserva la especificación solicitada, pero **no está validado visualmente**. La tabla de colores no identifica filtros Pioneer ni reconstruye todos sus gradientes internos.

### Overview extendido

Se corrigió la confusión entre la intensidad legacy de PWAV y la blancura PWV3. El overview Blue de estas capturas se aproxima mediante las energías de PWV4: altura por máximo de bandas y blancura relativa a la energía inferior de sus bytes 0/2. Es un mapeo calibrado, no una fórmula oficial Pioneer. La documentación de [Deep Symmetry sobre el preview](https://djl-analysis.deepsymmetry.org/djl-analysis/track_metadata.html#color-preview-analysis) distingue estas representaciones.

El overview medido tiene 28 píxeles de altura máxima; el margen superior varía con cada recorte. Los colores y cinco posiciones del gradiente se muestrearon por script: [mediciones](preview-gradient-measurements.json). Los tres modos comparten la escala de presentación. La normalización y la composición de 3-Band aún difieren, especialmente a −30 dBFS; no se presenta como equivalencia imperceptible.

## Cambios de interfaz

- Selector único Blue/RGB/3-Band para detalle y overview; 3-Band en una instalación nueva.
- Menú del overview: exactamente dos opciones, fijas o seguir los EQ del mixer.
- Cuenta de pulsos hasta el próximo marcador trasladada bajo la Key del deck; etiqueta de posición compás.beat separada sobre la onda.
- Marcas blancas de pulso solo encima y debajo de la onda desde el primer sonido; las marcas rojas de compás sobresalen dos píxeles hacia fuera. Se eliminaron las líneas verticales completas y los triángulos de compás. El playhead sigue rojo y el overview mantiene su barra de progreso. Los marcadores de cue existentes conservan sus datos importados. No hay referencias A/B nuevas para validarlos píxel a píxel.

## Comparación visual del renderer nativo

Se generaron 30 imágenes usando el decoder C++ y las mismas funciones de geometría y gradientes que el producto. Son pruebas de la geometría y los datos del renderer, **no capturas completas del framebuffer OpenGL de la aplicación**. La rasterización QPainter puede diferir en bordes subpíxel de la GPU.

Se compara la misma ventana temporal con registro por grid PQTZ y comienzo conocido de la señal a los 2 s. El margen horizontal del overview Blue/RGB se registra por el primer sonido conocido a t=2 s, independientemente por captura, sin optimizar SSIM. El registro de una captura recortada no garantiza alineación subpíxel exacta. [Registro y máscaras](registration.json). Se excluyeron líneas de grid/playhead y barras planas de frases de las métricas de onda; no se ha validado píxel a píxel la tipografía, A/B ni el resto de overlays.

SSIM RGB con ventana uniforme 7×7, covarianza poblacional. Mayor es mejor. El histograma usa distancia de variación total por canal (0 = coincidencia). Se informa además MAE de píxeles de señal para evitar que el fondo negro oculte errores.

| Modo | Vista | SSIM medio | Rango SSIM | TV histograma media |
|---|---|---:|---:|---:|
| blue | detail | 0.726 | 0.572–0.973 | 0.110 |
| blue | overview | 0.830 | 0.808–0.845 | 0.238 |
| rgb | detail | 0.829 | 0.601–0.961 | 0.105 |
| rgb | overview | 0.836 | 0.826–0.851 | 0.198 |
| 3band | detail | 0.896 | 0.811–0.941 | 0.024 |
| 3band | overview | 0.717 | 0.513–0.776 | 0.114 |

[Galería lado a lado](comparisons.html) · [Métricas de las 30 comparaciones](visual-validation.json). Cada imagen comparativa contiene referencia, render y diferencia absoluta.

**El resultado no cumple “diferencias imperceptibles”.** 3-Band detalle está más cerca. Quedan la normalización/composición del overview 3-Band, gradientes y cuantización de color, el muestreo/fase de Blue/RGB, la alineación fina y el antialiasing. No se alteró el modelo de análisis propio tras ver los errores de 07–09.

## Ejecutar la evaluación de nuevo

```sh
python3 -m pip install -r scripts/requirements-calibration.txt
python3 scripts/rekordbox-calibration.py --usb /ruta/USB --manifest /ruta/manifest.json --output resultados
python3 scripts/measure-calibration-captures.py referencias.json --output resultados/capture-measurements.json
python3 scripts/measure-signed-waveform.py --data resultados --audio /ruta/audio
python3 scripts/measure-blue-gradient.py --data resultados --usb /ruta/USB
python3 scripts/measure-preview-gradient.py --data resultados
python3 scripts/compare-calibration-renders.py register-previews --data resultados --spec trabajos.json
# Ejecutar el fixture C++ con NAUTIC_CALIBRATION_RENDER_SPEC=trabajos.json

python3 scripts/compare-calibration-renders.py compare --data resultados
```

`referencias.json` enumera archivo 1–5, modo y ruta de cada PNG original.
Los originales fueron adjuntos temporales; se conservaron los recortes de onda
usados en la comparación, sus medidas y los hashes originales. Los recortes
permiten revisar las diferencias sin depender de la duración de esos adjuntos.

El fixture `RekordboxWaveformImporterTest.RenderCalibrationFixtures` se activa
con `NAUTIC_CALIBRATION_RENDER_SPEC` apuntando a un JSON de trabajos. Los demás
tests no necesitan el pendrive. Las bibliotecas Python solo son dependencias
del experimento; no se agregan al motor de audio. La lectura PCM nativa de
extremos con signo es independiente del modelo Python de análisis propio.
