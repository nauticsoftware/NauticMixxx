[English controller guide](CONTROLLERS-RX3-1.5-EN.md)

# Navegación RX3 sin mouse: Pioneer y Roland (v1.5)

Presets completos para DDJ-400, DDJ-SX, DDJ-SX2, DDJ-SX3, DDJ-WeGO3 y
Roland DJ-505. El DDJ-FLX4 conserva su preset RX3 completo anterior. La app
selecciona el preset por el modelo en el nombre del puerto MIDI en el build
nativo. En un paquete de solo skin o si el sistema usa otro nombre, se puede
elegir manualmente en Preferencias > Controladores.

| Modelo | Girar / entrar | Volver | SOURCE | VIEW |
| --- | --- | --- | --- | --- |
| DDJ-400 | BROWSE / pulsar BROWSE | SHIFT + BROWSE | SHIFT + LOAD 1 | SHIFT + LOAD 2 |
| DDJ-SX, SX2 y SX3 | BROWSE / pulsar BROWSE | BACK | SHIFT + LOAD PREPARE | SHIFT + BACK |
| DDJ-WeGO3 | BROWSE / pulsar BROWSE | SHIFT + BROWSE | SHIFT + LOAD 1 | SHIFT + LOAD 2 |
| DDJ-FLX4 | BROWSE / pulsar BROWSE | SHIFT + BROWSE | SHIFT + LOAD 1 | SHIFT + LOAD 2 |
| Roland DJ-505 | BROWSE / pulsar BROWSE | BACK | SHIFT + BACK | ADD PREPARE |

Pulsar BROWSE desde PERFORMANCE abre el browser; esa primera pulsación no
selecciona ni carga una pista. Girar BROWSE recorre la lista. SOURCE abre la
selección de dispositivos y categorías. BACK vuelve un nivel. VIEW alterna
entre PERFORMANCE y BROWSE. Los botones LOAD normales conservan la carga del
deck correspondiente. En una skin estándar de Mixxx, estas acciones usan los
controles de la biblioteca disponibles allí.

Los presets adaptan únicamente los mensajes MIDI necesarios para navegar.
En DDJ-SX, SHIFT + LOAD PREPARE deja de activar AutoDJ; en SX2 cambia la función
anterior de maximizar la biblioteca; en Roland DJ-505, SHIFT + BACK deja de
ordenar canciones y ADD PREPARE pasa a VIEW. Consulte los XML para los demás
mensajes reasignados.

Las combinaciones DDJ-400 y DDJ-WeGO3 se cotejaron con las listas MIDI
[DDJ-400](https://downloads.support.alphatheta.com/software_info/dj-controllers/DDJ-400/DDJ-400_MIDI_Message_List_E1.pdf)
y [DDJ-WeGO3](https://www.pioneerdj.com/-/media/pioneerdj/software-info/controller/ddj-wego3/ddj-wego3_list_of_midi_message_e.pdf).
También se consultaron las listas de [DDJ-SX2](https://downloads.support.alphatheta.com/software_info/dj-controllers/DDJ-SX2/DDJ-SX2_List_of_MIDI_Message_E.pdf)
y [DDJ-SX3](https://www.pioneerdj.com/-/media/pioneerdj/software-info/controller/ddj-sx3/ddj-sx3_midi_message_list_e1.pdf).
Los nombres físicos del DJ-505 se cotejaron con su
[manual](https://static.roland.com/assets/media/pdf/DJ-505_eng02_W.pdf).

El XML comunitario SX3 contenía un fragmento SX3 incompleto seguido de un XML
SX2 completo. El generador aplica los controles propios de SX3 sobre la base
SX2 y conserva su script común. Esto se verificó en software, pero requiere
comprobación física de LEDs, pads y canales. Ninguno de estos siete equipos
estuvo conectado para una prueba física de la navegación nueva; confirmar
mensajes MIDI y comportamiento antes de usar el preset en una actuación.

Para regenerar y validar:

```sh
python3 scripts/generate-rx3-browser-presets.py
python3 scripts/test-pioneer-roland-presets.py
node scripts/test-pioneer-roland-browser.js
```

## Hercules Inpulse 500 y salida del browser

Mantener ASSISTANT durante 600 ms desde BROWSE vuelve a PERFORMANCE sin cargar
pista. Una pulsación corta abre SOURCE al soltar; SHIFT + ASSISTANT conserva
el panel lateral. El encoder mantenido 2 segundos conserva GRID. La app y
los perfiles nuevos usan inglés por defecto (`en_US`).
