# Instalar NauticMixxx 1.1.0

## macOS Apple Silicon

Requisitos: macOS 11 o posterior y un Mac con chip Apple Silicon.

1. Descarga `NauticMixxx-1.1.0-macOS-arm64.dmg` y `SHA256SUMS.txt`.
2. Verifica el archivo: `shasum -a 256 -c SHA256SUMS.txt`.
3. Abre el DMG y arrastra **NauticMixxx.app** a Aplicaciones.
4. El ZIP alternativo incluye `CONFIGURE-AND-OPEN.command`, que instala el perfil
   RX3 y asigna automáticamente el Inpulse 500 antes de abrir la app.
5. También puedes usar `install-nauticmixxx-macos.sh`; el instalador aplica el
   perfil y conserva como máximo una versión previa.
6. Si macOS advierte que es una build comunitaria sin notarizar, usa clic derecho
   → **Abrir** en la primera ejecución.

NauticMixxx no debe abrir el selector de carpeta musical: el asistente, el
escaneo y el alta de directorios de la biblioteca local están bloqueados. Si
aparece una ventana ubicada en Música, estás ejecutando una build anterior.
La única selección de carpeta permitida es una autorización de macOS sobre la
raíz del propio USB Rekordbox cuando el sistema operativo la exige.

El perfil deja asignado **Hercules DJControl Inpulse 500 - XDJ-RX3 Browse** y
mantiene el mapping en la carpeta de usuario, por lo que mover o reemplazar el
`.app` no rompe la asignación. No modifica dispositivos de audio ni grabaciones.
El motor conserva una base interna para estado e historial, pero no la expone
como fuente musical ni escanea directorios locales.

La aplicación conserva el identificador de datos de Mixxx para mantener el
acceso al perfil y al sandbox usados por el motor base. Antes de probar una
versión nueva, realiza una copia de seguridad de:

`~/Library/Containers/org.mixxx.mixxx/Data/Library/Application Support/NauticMixxx`

El perfil NauticMixxx es independiente del perfil Mixxx existente. La app abre
la interfaz NauticMixxx por defecto en una instalación nueva.

NauticMixxx abre el USB Rekordbox en modo de lectura y no modifica su música.
La primera selección del dispositivo puede provocar una solicitud de permiso
de macOS; selecciona la raíz del USB, nunca una carpeta de Música local.

## Windows x64

Para instalar la **skin 1.1.0**, extrae
`release/1.1.0/NauticMixxx-1.1.0-Windows-x64-Skin.zip` y ejecuta
únicamente `INSTALL-WINDOWS.bat`. Mantén `NauticMixxx-Files/` junto al BAT. El
instalador está íntegramente en inglés, muestra el avance y detecta tanto
NauticMixxx 1.0 como Mixxx oficial. Si encuentra NauticMixxx 1.0 actualiza la
skin en sus carpetas existentes; si no encuentra ninguno, descarga Mixxx desde
la fuente oficial. Para Mixxx oficial ofrece un perfil paralelo o la
actualización de la skin en el perfil habitual. Reconoce versiones 1.0+
de la skin, crea respaldos y evita instalar 1.1 sobre una versión posterior.
El acceso directo se llama NauticMixxx, usa el icono del proyecto y sustituye
los accesos directos antiguos del escritorio, conservándolos como respaldo.
Esta edición no distribuye `mixxx.exe`; las funciones nativas personalizadas
requieren la aplicación NauticMixxx completa.

Para quitar las versiones instaladas en las carpetas propias de NauticMixxx en Windows, cierra la aplicación
y ejecuta `UNINSTALL-WINDOWS.bat` del mismo ZIP. El BAT muestra las carpetas
detectadas y exige escribir `UNINSTALL`. Elimina las instalaciones propias,
el perfil independiente, accesos directos, respaldos y cachés. Si la skin se
instaló en el perfil habitual de Mixxx, retira sus componentes RX3 y conserva
la biblioteca, Mixxx oficial y el controlador Hercules instalado por separado.

La siguiente descripción corresponde al ZIP **nativo 1.0.0** anterior:

La versión nativa se obtiene como artefacto del workflow **NauticMixxx Windows
x64**. Extrae por completo el ZIP y ejecuta únicamente `INSTALL-WINDOWS.cmd`.
El paquete ya contiene la aplicación modificada, la skin, el mapping, efectos,
fuentes y resultados de prueba; no descarga ni parchea una instalación oficial.

El instalador valida los hashes, detecta las instalaciones de Mixxx y consulta
la última versión estable disponible. Si encuentra Mixxx ofrece:

- **Paralelo (recomendado):** instala en
  `%LOCALAPPDATA%\Programs\NauticMixxx\1.0.0` y usa el perfil independiente
  `%LOCALAPPDATA%\Mixxx-RX3`; la instalación oficial queda intacta.
- **Reemplazo avanzado:** permite elegir una instalación detectada, exige
  escribir `REEMPLAZAR`, respalda primero la aplicación y el perfil, y solicita
  permisos de administrador sólo cuando la ruta los necesita. Nunca reemplaza
  una versión posterior a la base Mixxx 2.5.6.

Si no detecta el driver ASIO de Hercules, el asistente ofrece descargarlo como
opción separada y con respuesta predeterminada **No**. No es necesario para
usuarios de otros controladores o interfaces. Los respaldos de aplicaciones se guardan en
`%LOCALAPPDATA%\NauticMixxx-Backups\Applications` y los de perfiles en
`%LOCALAPPDATA%\Mixxx-XDJ-RX3-Backups`.

No presentes como estable un ZIP de Windows hasta que el workflow termine con
la validación del instalador y las pruebas nativas en verde.

## Sólo la skin

La skin activa está en `../skins/XDJ_RX3_Mixxx/` desde esta documentación. El
empaquetador puede crear `NauticMixxx-1.0.0-skin.zip` como candidato, pero ese
ZIP no se encuentra en `release/1.0.0/` actualmente. La experiencia completa
requiere la app parcheada: la skin sola no incorpora el navegador RX3, el
escalado nativo ni las correcciones del motor.

## Desinstalar

Elimina `NauticMixxx.app`. Los ajustes y la biblioteca permanecen en el perfil
de Mixxx para evitar pérdida de datos. Elimínalos sólo después de respaldarlos y
únicamente si ya no los necesitas.
