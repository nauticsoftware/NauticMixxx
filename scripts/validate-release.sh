#!/bin/sh
set -eu

project=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project"

printf '%s\n' '1/6 Metadatos y datos privados'
python3 scripts/release-audit.py

printf '%s\n' '2/6 Contrato del instalador de Windows'
python3 scripts/test-windows-installer-contract.py

printf '%s\n' '3/6 Contrato de lectura exclusiva desde USB Rekordbox'
if [ -f ../src/coreservices.cpp ] || [ -f tmp/mixxx-native-rebuild/mixxx-2.5.6/src/coreservices.cpp ]; then
  python3 scripts/test-rx3-usb-only.py
else
  printf '%s\n' 'Fuentes parcheadas no disponibles; ejecuta primero el build reproducible.'
fi

printf '%s\n' '4/6 XML de skin, mapping y efectos'
find skins/XDJ_RX3_Mixxx controllers/Hercules_DJControl_Inpulse_500_RX3 controllers/Pioneer_DDJ_FLX4_RX3 controllers/Pioneer_DDJ_FLX6_RX3 effects \
  -type f -name '*.xml' -exec xmllint --noout {} +

printf '%s\n' '5/6 JavaScript del controlador'
node --check controllers/Hercules_DJControl_Inpulse_500_RX3/Hercules-DJControl-Inpulse-500-RX3-script.js
node scripts/test-rx3-autoloop.js
node scripts/test-rx3-loop-adjust.js
node scripts/test-rx3-sound-color-fx.js
node scripts/test-rx3-transport-controls.js
node scripts/test-flx6-browser.js
node scripts/test-flx4-browser.js
python3 scripts/test-flx4-preset.py

printf '%s\n' '6/6 Pruebas nativas'
native_test=../build/mixxx-test
native_test_dir=../build
if [ ! -x "$native_test" ] && [ -x tmp/mixxx-native-rebuild/build/mixxx-test ]; then
  native_test=tmp/mixxx-native-rebuild/build/mixxx-test
  native_test_dir=tmp/mixxx-native-rebuild/build
fi
if [ ! -x "$native_test" ] && [ -x tmp/v1.1/build/mixxx-test ]; then
  native_test=tmp/v1.1/build/mixxx-test
  native_test_dir=tmp/v1.1/build
fi
if [ -x "$native_test" ]; then
  resource_path=$(CDPATH= cd -- "$project/../res" && pwd)
  (cd "$native_test_dir" && QT_QPA_PLATFORM=offscreen ./mixxx-test \
    --resource-path "$resource_path" \
    --gtest_output="xml:${NAUTIC_NATIVE_TEST_REPORT:-rx3-release-tests.xml}" \
    --gtest_filter='LibraryTableViewStateTest.*:Rx3*:RekordboxDecoderTimingTest.*:RekordboxUsbSessionAudioTest.*:RekordboxWaveformImporterTest.*:RekordboxUsbSessionTest.*:RekordboxRuntimeTrackModelTest.*:TrackCapabilityPolicyTest.*')
else
  printf '%s\n' 'mixxx-test no está compilado; reconstruye la app para ejecutar la suite nativa.'
fi

printf 'Fuentes NauticMixxx %s validadas; comprueba el bundle de esta versión antes de empaquetar.\n' "$(cat VERSION)"
