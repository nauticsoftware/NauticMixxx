# Windows C++ compatibility

- Never use `near` or `far` as identifiers in shared C++ code, including tests. Windows headers define them as macros and MSVC may fail with C2059/C3409.
- Use explicit identifiers such as `nearArtistRow` and `farArtistRow`; do not disable system macros to conceal a collision.
- Preserve the preventive identifier check in `scripts/test-windows-installer-contract.py`. Run it before Windows compilation; the native build script and CI both invoke it.
