NAUTICMIXXX 1.0.0 + HERCULES INPULSE 500
Windows 10 (1809 o posterior) / 11, Intel/AMD de 64 bits

INSTALAR EN CADA LAPTOP
1. Extrae todo el ZIP en una carpeta. No ejecutes archivos dentro del ZIP.
2. Si falta el driver Hercules ASIO, ejecuta DRIVER-HERCULES.cmd y sigue
   el asistente oficial. Para este paso necesitas Internet.
3. Conecta el Hercules, cierra Mixxx y haz doble clic en INSTALL-WINDOWS.cmd.
4. Si es la primera instalacion, el programa se abre para crear el perfil.
   Cierralo cuando termine de abrir y pulsa ENTER en el instalador.
5. Usa el acceso directo "NauticMixxx" del escritorio o del menu Inicio.

Este paquete incluye la aplicacion nativa RX3 completa. No necesitas instalar
Mixxx oficial ni compilar nada en la laptop. El instalador comprueba los archivos
antes de copiarlos y no requiere permisos de administrador para instalar RX3.

AUDIO: HACER UNA VEZ EN CADA LAPTOP
Preferencias > Hardware de sonido:
- API: ASIO.
- Principal: Hercules Inpulse 500, canales 1-2.
- Auriculares: Hercules Inpulse 500, canales 3-4.
Aplica los cambios. Si ya habia audio configurado en Windows, se conserva.
Los identificadores CoreAudio del Mac no se pueden transferir a Windows.

CONTROLES Y PANTALLA
- Mapping: "Hercules DJControl Inpulse 500 - XDJ-RX3 Browse".
- Si instalas sin conectar el controlador, seleccionalo en Preferencias >
  Controladores despues de conectarlo, o repite INSTALL-WINDOWS.cmd.
- SHIFT + ASSISTANT: STATUS / BEAT FX.
- MASTER exclusivo naranja, con transferencia cuando se detiene el deck master.
- QUANTIZE y 1 se ocultan juntos; CONTINUE no se desplaza.
- Loop lateral dinamico, con fracciones; oculto al desactivar el loop.
- Overview con tramo reproducido oscuro y cursor blanco.
- Lienzo 1280 x 800, escalado proporcional automatico al redimensionar.
- Compases, milisegundos, hot cues y grilla RX3 de la version nativa.

PERFILES Y RESPALDO
La aplicacion se instala bajo %LOCALAPPDATA%\Programs\Mixxx-RX3.
Su perfil es %LOCALAPPDATA%\Mixxx-RX3. Usa siempre el acceso directo NauticMixxx.
Si existe el perfil de Mixxx oficial, se copia una vez al perfil RX3 para
conservar su biblioteca, audio y ajustes de Windows. El original permanece.
Las modificaciones posteriores a las bibliotecas de ambos programas son
independientes. No se migra un perfil oficial posterior a Mixxx 2.5.6.
Las actualizaciones de RX3 respaldan su perfil antes de modificarlo.
Los respaldos estan en %LOCALAPPDATA%\Mixxx-XDJ-RX3-Backups.
El instalador muestra el respaldo concreto y el registro de diagnostico.
Para restaurar: cierra Mixxx, renombra %LOCALAPPDATA%\Mixxx-RX3 y copia el
contenido del respaldo adecuado a una nueva carpeta con ese nombre.

NO INCLUYE LA MUSICA DEL MAC
Importa las pistas de la laptop o de tus discos. Se incluye tu mapping y el
perfil portable, pero no contrasenas, rutas personales ni dispositivos del Mac.

COMPILACION Y PRUEBAS
Se incluyen resultado de pruebas, hashes y fuentes modificados bajo source.
La compilacion es personalizada, no una publicacion oficial del equipo Mixxx.
Verifica PLAY/CUE, jogs, loop, pitch, MASTER y preescucha en cada laptop antes
de usarla en una sesion. El paquete no sustituye esa prueba de hardware.

FUENTES OFICIALES
https://github.com/mixxxdj/mixxx/tree/2.5.6
https://github.com/mixxxdj/mixxx/wiki/Compiling-On-Windows
https://support.hercules.com/es/product/djcontrolinpulse500-es/
