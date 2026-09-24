NAUTICMIXXX 1.0.0 + HERCULES INPULSE 500
Windows 10 (1809 o posterior) / 11, Intel/AMD de 64 bits

INSTALAR EN CADA LAPTOP
1. Extrae todo el ZIP en una carpeta. No ejecutes archivos dentro del ZIP.
2. Cierra Mixxx y haz doble clic en INSTALL-WINDOWS.cmd. Es el unico archivo
   que necesitas ejecutar.
3. El instalador comprueba el paquete, detecta las instalaciones de Mixxx y
   consulta cual es la ultima version estable disponible.
4. Si encuentra Mixxx, elige:
   - P: instalacion paralela (recomendada). Conserva Mixxx intacto.
   - R: reemplazo avanzado. Selecciona la instalacion y escribe REEMPLAZAR.
   - C: cancelar sin hacer cambios.
5. Si falta el driver ASIO Hercules, el instalador ofrece descargarlo de forma
   opcional y con respuesta predeterminada No. No lo instales si usas otro
   controlador o dispositivo de audio.
6. Usa el acceso directo NauticMixxx del escritorio o del menu Inicio.

El ZIP contiene la aplicacion nativa NauticMixxx completa, no solamente la
skin. Incluye los cambios del motor, el navegador USB, mapping, efectos y skin.
El ejecutable y los accesos directos usan el icono NauticMixxx suministrado por
el proyecto, no el icono original de Mixxx. No hace falta instalar Mixxx oficial
ni compilar en la laptop.

INSTALACION PARALELA (RECOMENDADA)
NauticMixxx se instala en:
%LOCALAPPDATA%\Programs\NauticMixxx\1.0.0

Usa un perfil independiente:
%LOCALAPPDATA%\Mixxx-RX3

Si existe un perfil Mixxx 2.5.6 o anterior, se copia una vez al perfil RX3
para conservar biblioteca y ajustes. El original no se modifica. Un perfil
posterior a la base 2.5.6 no se migra hacia atras: NauticMixxx crea uno limpio.

REEMPLAZO AVANZADO
Esta opcion sustituye los archivos de la instalacion de Mixxx elegida, pero
mantiene el perfil NauticMixxx separado. Antes de borrar nada, el instalador:
- verifica que la ruta pertenezca a una instalacion detectada;
- solicita la confirmacion literal REEMPLAZAR;
- copia y verifica el ejecutable en un respaldo completo;
- respalda el perfil del usuario;
- solicita permisos de administrador solamente si la ruta los requiere.

No permite reemplazar una version de Mixxx posterior a la base incluida. En ese
caso usa el modo paralelo. Los respaldos de aplicaciones quedan en:
%LOCALAPPDATA%\NauticMixxx-Backups\Applications

Los respaldos de perfiles quedan en:
%LOCALAPPDATA%\Mixxx-XDJ-RX3-Backups

AUDIO: HACER UNA VEZ EN CADA LAPTOP
En Preferencias > Hardware de sonido elige la API, dispositivo y canales que
correspondan a tu hardware. Para Hercules Inpulse 500 puedes usar ASIO,
Principal 1-2 y Auriculares 3-4. Para otros controladores consulta su manual.

CONTROLES Y PANTALLA
- Mapping: Hercules DJControl Inpulse 500 - XDJ-RX3 Browse.
- Si instalas sin conectar el controlador, seleccionalo en Preferencias >
  Controladores despues de conectarlo, o repite INSTALL-WINDOWS.cmd.
- SHIFT + ASSISTANT: STATUS / BEAT FX.
- MASTER exclusivo naranja, con transferencia al detener el deck master.
- Loop lateral dinamico, fracciones, overview RX3 y cursor blanco.
- Lienzo 1280 x 800 con escalado proporcional.
- Compases, milisegundos, hot cues y grilla de la version nativa.

NO INCLUYE LA MUSICA DEL MAC
Importa las pistas desde los discos o USB de la laptop. El paquete no contiene
contrasenas, rutas personales, bases de datos, musica ni dispositivos del Mac.

COMPILACION Y PRUEBAS
El ZIP incluye resultados de pruebas, hashes, fuentes correspondientes y receta
de compilacion. Es una compilacion comunitaria personalizada, no una publicacion
oficial del equipo Mixxx. Verifica PLAY/CUE, jogs, loop, pitch, MASTER y
preescucha en cada laptop antes de usarla en una sesion.

FUENTES OFICIALES
https://github.com/mixxxdj/mixxx/tree/2.5.6
https://github.com/mixxxdj/mixxx/wiki/Compiling-On-Windows
https://support.hercules.com/es/product/djcontrolinpulse500-es/
