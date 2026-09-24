# Prueba física — Hercules DJControl Inpulse 500

Esta matriz valida los seis fixes incluidos en el mapper vigente. Usa solamente
`release/1.0.0/NauticMixxx-1.0.0-macOS-arm64/NauticMixxx.app`; no mezcles el ensayo con otra instalación de
Mixxx o con un mapping copiado anteriormente al perfil del usuario.

## Preparación

1. Cierra Mixxx y cualquier NauticMixxx que esté abierto.
2. Conecta el Inpulse 500 directamente al Mac.
3. Ejecuta `release/1.0.0/CONFIGURAR-Y-ABRIR.command`.
   No debe aparecer ningún selector de carpeta Música. Si macOS solicita acceso,
   autoriza exclusivamente la raíz del USB Rekordbox conectado.
4. En Preferencias → Controladores verifica que el equipo esté habilitado con
   **Hercules DJControl Inpulse 500 - XDJ-RX3 Browse**; no debería decir
   **No Mapping**.
5. Carga una pista analizada con beatgrid correcto en cada deck.
6. Pulsa SOURCE: sólo debe aparecer el USB Rekordbox. No debe existir
   **SOFTWARE CONTROL** ni una colección musical local.

## Matriz de aceptación

1. **SLIP, decks 1 y 2.** Activa SLIP, reproduce y haz scratch durante varios
   segundos. Al soltar el jog, la pista debe continuar desde la posición que
   habría alcanzado sin el scratch. El LED debe reflejar el estado activado.
2. **Sound Color FX.** Al iniciar, los cuatro selectores deben quedar encendidos.
   Selecciona cada FX: sólo el elegido debe parpadear. Mueve COLOR en ambos decks;
   el efecto debe responder inmediatamente durante todo el recorrido. Al volver a
   pulsarlo, los cuatro LEDs deben quedar fijos y COLOR debe recuperar el filtro.
3. **LOOP IN largo.** Mantén pulsado IN hasta que el controlador emita la acción
   de pulsación larga. Debe activarse un loop cuantizado de cuatro beats. Un toque
   corto debe conservar el comportamiento normal de punto IN.
4. **SYNC.** Pulsa SYNC en cada deck. El LED debe encenderse mientras ese deck
   permanezca sincronizado y apagarse al desactivarlo.
5. **Rango de tempo.** Pulsa BEATMATCH GUIDE repetidamente. El rango de ambos
   pitch debe recorrer ±6 %, ±10 %, ±16 % y WIDE, regresando luego a ±6 %.
6. **MASTER TEMPO.** Pulsa SHIFT + SYNC en cada deck. Debe alternar Keylock /
   Master Tempo sólo en ese deck, sin activar ni desactivar SYNC.

## Cierre

Repite los puntos 1–6 tras cerrar y volver a abrir la aplicación. Si todos pasan,
anota firmware del controlador, versión de macOS y salida de audio en
`../TEST_REPORT.md` antes de considerar la build validada físicamente.
