# Arquitectura

NauticMixxx se divide en cuatro capas:

1. **Motor:** Mixxx 2.5.6 con diez parches en `patches/`; el último
   impone el contrato USB-only y bloquea la biblioteca musical local.
2. **Interfaz:** `skins/XDJ_RX3_Mixxx`; el nombre interno se conserva para
   compatibilidad de perfiles y la identidad visible es NauticMixxx.
3. **Hardware:** mapping en `controllers/` y cuatro cadenas de efectos en
   `effects/`.
4. **Distribución:** scripts en `scripts/`, entitlements en `packaging/macos/`
   y recetas de instalación de Windows en `packaging/windows/`.

La raíz de `mixxx-app/` es la fuente correspondiente
parcheada usada para el binario local. Las modificaciones mantenibles se
registran además como parches para poder aplicarlas sobre el tag limpio.
