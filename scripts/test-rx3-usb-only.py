#!/usr/bin/env python3
"""Static regression checks for the NauticMixxx Rekordbox USB-only contract."""

from __future__ import annotations

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
APP_ROOT = ROOT.parent
REBUILD_SOURCE = ROOT / "tmp/mixxx-native-rebuild/mixxx-2.5.6"
SOURCE = APP_ROOT if (APP_ROOT / "src/coreservices.cpp").is_file() else REBUILD_SOURCE


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def read_source(relative: str) -> str:
    return (SOURCE / relative).read_text(encoding="utf-8")


def require(condition: bool, message: str, errors: list[str]) -> None:
    if not condition:
        errors.append(message)


def main() -> int:
    errors: list[str] = []
    profile = read("profile/XDJ_RX3_Mixxx.profile.cfg")
    core = read_source("src/coreservices.cpp")
    manager = read_source("src/library/trackcollectionmanager.cpp")
    library = read_source("src/library/library.cpp")
    preferences = read_source("src/preferences/dialog/dlgpreflibrary.cpp")
    browser = read_source("src/widget/wrx3browser.h")

    require("UsbOnlyMode 1" in profile, "el perfil no activa UsbOnlyMode", errors)
    require(
        "if (!usbOnlyMode &&\n            m_pTrackCollectionManager->internalCollection()->loadRootDirs().isEmpty())"
        in core,
        "el selector inicial de carpeta no está protegido por UsbOnlyMode",
        errors,
    )
    require(
        "if (!usbOnlyMode &&\n            (rescan || musicDirAdded ||"
        in core,
        "el escaneo de arranque no está protegido por UsbOnlyMode",
        errors,
    )
    require(
        manager.count("kUsbOnlyModeConfigKey") >= 2,
        "el gestor no bloquea tanto el escaneo como el alta de carpetas",
        errors,
    )
    require(
        "DirectoryDAO::AddResult::InvalidOrMissingDirectory" in manager,
        "el alta de carpetas locales no se rechaza",
        errors,
    )
    require(
        "bool Library::requestAddDir" in library
        and "kUsbOnlyModeConfigKey" in library,
        "la API de biblioteca no rechaza carpetas locales",
        errors,
    )
    require(
        "pushButton_add_dir->setEnabled(!usbOnlyMode);" in preferences
        and preferences.count("kUsbOnlyModeConfigKey") >= 4,
        "preferencias no deshabilita y protege todas las acciones de carpetas",
        errors,
    )
    require(
        'QTimer::singleShot(0, this, [this]{ showSources(); refreshTable(); });'
        in browser,
        "el navegador RX3 no arranca en SOURCE",
        errors,
    )
    require(
        'QString source="INSERT REKORDBOX USB";' in browser,
        "SOURCE no muestra el estado de espera de USB Rekordbox",
        errors,
    )
    require(
        "SOFTWARE CONTROL" not in browser,
        "SOURCE todavía expone la biblioteca local SOFTWARE CONTROL",
        errors,
    )
    require(
        'QString("♪\\nTRACK")' in browser and 'QString("♫\\nPLAYLIST")' in browser,
        "faltan las únicas dos categorías permitidas para el USB",
        errors,
    )

    if errors:
        print("USB-ONLY: FALLÓ", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("USB-ONLY: 10/10 controles OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
