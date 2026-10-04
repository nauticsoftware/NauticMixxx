# Aviso de actualizaciones — NauticMixxx 1.6

La función se incorpora en 1.6.0. Las versiones anteriores necesitan instalar
manualmente una versión con el comprobador para poder recibir futuros avisos.

Al completar el inicio, NauticMixxx consulta una sola vez por HTTPS:
`https://api.github.com/repos/nauticsoftware/NauticMixxx/releases/latest`.
No requiere credenciales de Apple ni tokens de GitHub. Solo envía una petición
HTTP con User-Agent de producto/versión; no envía biblioteca, perfil ni datos de
controladores. GitHub recibe los datos habituales de una conexión, incluida la IP.

Se compara la versión del producto con el tag X.Y.Z o vX.Y.Z de la release
estable pública. No se notifican borradores, prereleases, versiones iguales o
anteriores. Publicar solo un tag o subir un commit no genera un aviso: se debe
publicar una release estable y marcarla como la última en GitHub.

El aviso se muestra en inglés, con versión instalada y nueva:

- **Download** abre la página de esa release en el navegador para instalar manualmente.
- **Later**, Escape o cerrar la ventana pospone el aviso hasta el próximo inicio.
- **Skip this version** guarda la versión omitida en el perfil. Una versión posterior vuelve a avisar.

La app no descarga ni instala paquetes automáticamente. No cambia la firma o
notarización macOS y no evita los avisos de Gatekeeper de una app sin Developer ID.

La consulta no bloquea la interfaz ni el audio. Se cancela al transcurrir cinco
segundos, al empezar a reproducir en cualquier deck/sampler/preview o al activar
Auto DJ. El aviso se descarta si hay un diálogo modal abierto; no se guarda para
mostrarlo durante la sesión. Si la reproducción comienza con el aviso abierto,
este se cierra. Los errores de red/HTTP, la falta de internet y las respuestas
inválidas se ignoran sin alertas adicionales ni reintentos.

El perfil usa este grupo (las claves ausentes conservan los valores por defecto):

```ini
[NauticUpdates]
CheckOnStartup 1
SkippedVersion
```

Para deshabilitar la consulta, cerrar la app y poner `CheckOnStartup 0` en
`mixxx.cfg`. Para volver a ofrecer una versión omitida, quitar `SkippedVersion`.
Cada perfil, incluidos los candidatos aislados, conserva sus preferencias.

Las builds reconstruidas pasan `-DNAUTICMIX_VERSION` desde el archivo `VERSION`.
El sandbox macOS necesita `com.apple.security.network.client=true`, incluido en
los entitlements del proyecto. Nunca se incorporan claves secretas al ejecutable.

Pruebas: `QT_QPA_PLATFORM=offscreen ./mixxx-test --gtest_filter='StartupUpdateCheckerTest.*'`.
