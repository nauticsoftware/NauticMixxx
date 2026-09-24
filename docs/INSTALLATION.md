# Instalar NauticMixxx 1.0.0

## macOS Apple Silicon

Requisitos: macOS 11 o posterior y un Mac con chip Apple Silicon.

1. Descarga `NauticMixxx-1.0.0-macOS-arm64.dmg` y `SHA256SUMS.txt`.
2. Verifica el archivo: `shasum -a 256 -c SHA256SUMS.txt`.
3. Abre el DMG y arrastra **NauticMixxx.app** a Aplicaciones.
4. El ZIP alternativo incluye `CONFIGURAR-Y-ABRIR.command`, que instala el perfil
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

La versión nativa se obtiene como artefacto del workflow **NauticMixxx Windows
x64**. Extrae por completo el ZIP y ejecuta `INSTALL-WINDOWS.cmd`. El instalador
crea un perfil independiente y respalda la configuración existente antes de
copiar skin, mapping y efectos.

No presentes como estable un ZIP de Windows hasta que el workflow termine con
las pruebas nativas en verde.

## Sólo la skin

`NauticMixxx-1.0.0-skin.zip` sirve para inspección o para Mixxx compatible. La
experiencia completa requiere la app parcheada: la skin sola no incorpora el
navegador RX3, el escalado nativo ni las correcciones del motor.

## Desinstalar

Elimina `NauticMixxx.app`. Los ajustes y la biblioteca permanecen en el perfil
de Mixxx para evitar pérdida de datos. Elimínalos sólo después de respaldarlos y
únicamente si ya no los necesitas.
