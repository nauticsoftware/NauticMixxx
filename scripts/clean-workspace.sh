#!/bin/sh
set -eu

nautic_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
app_root=$(CDPATH= cd -- "$nautic_root/.." && pwd)

[ -f "$nautic_root/VERSION" ] && [ -f "$app_root/CMakeLists.txt" ] || {
  printf '%s\n' 'No parece ser la raíz de NauticMixxx/Mixxx.' >&2
  exit 1
}

clean_target() {
  target=$1
  if [ -e "$target" ]; then
    find "$target" -depth -delete
    printf 'Eliminado: %s\n' "$target"
  fi
}

clean_target "$nautic_root/tmp"
clean_target "$nautic_root/build"
clean_target "$nautic_root/.mixxx-validation"
clean_target "$nautic_root/.mixxx-visual-qa"
clean_target "$nautic_root/.mixxx-visual-runtime"
clean_target "$app_root/build"
clean_target "$app_root/stage-v1"

printf '%s\n' 'Workspace NauticMixxx limpio. La release conservada no fue modificada.'
