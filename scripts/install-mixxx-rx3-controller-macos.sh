#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project=$(CDPATH= cd -- "$script_dir/.." && pwd)
mixxx_data="$HOME/Library/Containers/org.mixxx.mixxx/Data/Library/Application Support/Mixxx"
controller_source="$project/controllers/Hercules_DJControl_Inpulse_500_RX3"
controller_target="$mixxx_data/controllers"
effect_source="$project/effects/chains"
effect_target="$mixxx_data/effects/chains"
effects_config="$mixxx_data/effects.xml"
timestamp=$(date +%Y%m%d-%H%M%S)

if pgrep -f '/Mixxx( RX3)?\.app/Contents/MacOS/' >/dev/null 2>&1; then
  printf '%s\n' 'Cierra Mixxx antes de instalar el mapping y los efectos RX3.' >&2
  exit 1
fi

if [ ! -f "$effects_config" ]; then
  printf 'No se encontró %s. Abre Mixxx una vez y vuelve a ejecutar el instalador.\n' "$effects_config" >&2
  exit 1
fi

mkdir -p "$controller_target" "$effect_target"

for file in \
  Hercules-DJControl-Inpulse-500-RX3-script.js \
  Hercules_DJControl_Inpulse_500_RX3.midi.xml \
  midi-components-0.0.js; do
  if [ -f "$controller_target/$file" ]; then
    cp -p "$controller_target/$file" "$controller_target/$file.backup-$timestamp"
  fi
  cp -p "$controller_source/$file" "$controller_target/$file"
done

for file in 'RX3 REVERB.xml' 'RX3 PING PONG.xml' 'RX3 NOISE.xml' 'RX3 FILTER.xml'; do
  cp -p "$effect_source/$file" "$effect_target/$file"
done
rm -f "$effect_target/RX3 SPACE.xml" "$effect_target/RX3 DUB ECHO.xml"

cp -p "$effects_config" "$effects_config.backup-$timestamp"
/usr/bin/python3 - "$effects_config" <<'PY'
import os
import sys
import xml.etree.ElementTree as ET

config_path = sys.argv[1]
desired = ["RX3 REVERB", "RX3 PING PONG", "RX3 NOISE", "RX3 FILTER"]
legacy = ["RX3 SPACE", "RX3 DUB ECHO"]
tree = ET.parse(config_path)
root = tree.getroot()
preset_list = root.find("QuickEffectPresetList")
if preset_list is None:
    preset_list = ET.SubElement(root, "QuickEffectPresetList")

for child in list(preset_list):
    if child.tag == "ChainPresetName" and child.text in desired + legacy:
        preset_list.remove(child)

for name in reversed(desired):
    node = ET.Element("ChainPresetName")
    node.text = name
    preset_list.insert(0, node)

ET.indent(tree, space=" ")
temporary_path = config_path + ".rx3-tmp"
tree.write(temporary_path, encoding="utf-8", xml_declaration=True)
os.replace(temporary_path, config_path)
PY

printf 'Mapping Hercules RX3 instalado en: %s\n' "$controller_target"
printf 'Sound Color FX instalados en: %s\n' "$effect_target"
printf 'Respaldo de efectos: %s.backup-%s\n' "$effects_config" "$timestamp"
printf '%s\n' 'Abre Mixxx RX3 y vuelve a habilitar el controlador si ya estaba abierto en Preferencias.'
