#!/bin/sh
set -eu

project=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project"

printf '%s\n' '1/5 Metadatos y datos privados'
python3 scripts/release-audit.py

printf '%s\n' '2/5 Contrato de lectura exclusiva desde USB Rekordbox'
if [ -f ../src/coreservices.cpp ] || [ -f tmp/mixxx-native-rebuild/mixxx-2.5.6/src/coreservices.cpp ]; then
  python3 scripts/test-rx3-usb-only.py
else
  printf '%s\n' 'Fuentes parcheadas no disponibles; ejecuta primero el build reproducible.'
fi

printf '%s\n' '3/5 XML de skin, mapping y efectos'
find skins/XDJ_RX3_Mixxx controllers/Hercules_DJControl_Inpulse_500_RX3 effects \
  -type f -name '*.xml' -exec xmllint --noout {} +

printf '%s\n' '4/5 JavaScript del controlador'
node --check controllers/Hercules_DJControl_Inpulse_500_RX3/Hercules-DJControl-Inpulse-500-RX3-script.js
node scripts/test-rx3-autoloop.js
node scripts/test-rx3-loop-adjust.js
node scripts/test-rx3-sound-color-fx.js
node scripts/test-rx3-transport-controls.js

printf '%s\n' '5/5 Pruebas nativas'
native_test=../build/mixxx-test
native_test_dir=../build
if [ ! -x "$native_test" ] && [ -x tmp/mixxx-native-rebuild/build/mixxx-test ]; then
  native_test=tmp/mixxx-native-rebuild/build/mixxx-test
  native_test_dir=tmp/mixxx-native-rebuild/build
fi
if [ -x "$native_test" ]; then
  (cd "$native_test_dir" && QT_QPA_PLATFORM=offscreen ./mixxx-test \
    --gtest_filter='LibraryTableViewStateTest.*:Rx3*:RekordboxUsbSessionTest.*:RekordboxRuntimeTrackModelTest.*:TrackCapabilityPolicyTest.*')
else
  printf '%s\n' 'mixxx-test no está compilado; se omitió la suite nativa local.'
fi

printf 'NauticMixxx %s listo para empaquetar.\n' "$(cat VERSION)"
