# Validación de NauticMixxx 1.1.0

Fecha: 2026-09-28. Plataforma: macOS ARM64, Qt 6, Mixxx 2.5.6.

## Cambios revisados

- Área cliente de referencia: **1280×800**. La captura completa incluye además
  los 28 píxeles de la barra de título del sistema.
- Ondas: inicio vertical a 56 px, separación de 18 px entre decks; borde
  inferior del segundo deck y de STATUS / BEAT FX en la misma fila (483).
- Separación de 10 px antes de la franja inferior de modos; las tarjetas de
  deck empiezan a 580 px y llegan hasta el margen inferior de 10 px.
- Cursor rojo (`#ff0000`) de dos píxeles de referencia en las ondas principales
  y en el overview de cada deck. Se escala con el resto del display.
- Ventana ampliada y restaurada: el contenido llena el ancho disponible y
  conserva la alineación inferior. Sin bandas externas del escalador.
- STATUS y BEAT FX: misma geometría de ondas y decks al cambiar de página.

## Comprobaciones

- Compilación nativa de la aplicación y `mixxx-test`: correcta.
- Suite de display, escalado, controles, beatgrid, cues y estado de biblioteca:
  **111 pruebas aprobadas, 0 fallidas, 5 omitidas**. Las omitidas requieren
  fixtures opcionales de un USB rekordbox real.
- Los once parches se aplican a las fuentes oficiales de Mixxx 2.5.6, con su
  SHA-256 verificado. Los archivos nativos modificados coinciden byte a byte
  con los reconstruidos a partir de los parches.
- XML de la skin, mapping y efectos: válido.
- Auditoría de metadatos 1.1.0, contrato del instalador Windows y contrato
  USB-only: correctos.
- Pruebas JavaScript de AUTOLOOP, ajuste IN/OUT, Sound Color FX, SLIP, SYNC,
  rango de tempo y LOOP IN largo: aprobadas.
- Preset DDJ-FLX6 opcional: XML válido y dos modos de navegador comprobados
  mediante simulación JavaScript. Falta ensayo físico con ese controlador.

## Evidencia y alcance

Capturas y resultados locales en `build/visual-qa/1.1.0/`:
`status-1280x800.png`, `beat-fx-1280x800.png`, `beat-fx-maximized.png` y
`native-tests.xml`. La app de desarrollo compilada está en
`tmp/v1.1/stage/NauticMixxx.app`.

La revisión visual se realizó con dos pistas sintéticas en un perfil aislado
compatible con el sandbox de macOS. No valida hardware Inpulse 500 ni USB real.
Windows no se compiló en este Mac: la descarga 1.1.0 para Windows distribuye
únicamente la skin y los BAT. El paquete 1.0.0 se conserva como versión anterior.
