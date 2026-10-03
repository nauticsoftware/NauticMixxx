#!/usr/bin/env python3
"""Check RX3 navigation overlays preserve each complete controller mapping."""

from collections import Counter
from pathlib import Path
import runpy
import xml.etree.ElementTree as ET


module = runpy.run_path(str(Path(__file__).with_name("generate-rx3-browser-presets.py")))
output = module["OUTPUT"]
address = module["control_address"]
sx3_source = module["sx3_source"]

for model, source, controller_id, bindings in module["MODELS"]:
    baseline = sx3_source() if source is None else ET.parse(source).getroot()
    generated = ET.parse(output / f"{model}-Nautic-RX3.midi.xml").getroot()
    before_controls = baseline.findall("./controller/controls/control")
    before = {address(c): c for c in before_controls if address(c) is not None}
    after_controls = generated.findall("./controller/controls/control")
    after = {address(c): c for c in after_controls if address(c) is not None}
    browser_addresses = {(status, midino) for _, status, midino in bindings}

    assert generated.tag == baseline.tag, model
    assert generated.find("./controller").get("id") == (
        controller_id or baseline.find("./controller").get("id")
    ), model
    assert len(after) == sum(address(c) is not None for c in after_controls), \
        f"Duplicate MIDI input in {model}"
    assert len(after_controls) - len(after) == len(before_controls) - len(before), model
    assert set(after) == set(before) | browser_addresses, model
    for midi, original in before.items():
        if midi not in browser_addresses:
            def fields(element):
                return [(child.tag, (child.text or "").strip(), tuple(child.attrib.items()))
                        for child in element.iter()]
            assert fields(after[midi]) == fields(original), (model, midi)
    assert len(generated.findall("./controller/outputs/output")) == len(
        baseline.findall("./controller/outputs/output")
    ), model
    scripts = [f.get("filename") for f in generated.findall("./controller/scriptfiles/file")]
    assert scripts.count("Nautic-RX3-Browser.js") == 1, model
    assert all((output / script).is_file() or
               (module["NAUTIC"] / "controllers/Hercules_DJControl_Inpulse_500_RX3" / script).is_file()
               for script in scripts), model
    for action, status, midino in bindings:
        control = after[status, midino]
        assert control.findtext("key") == f"NauticRX3Browser.{action}", model
        assert control.findtext("group") == "[Library]", model
    assert any("load" in (c.findtext("key") or "").lower()
               for c in after_controls), f"Deck LOAD buttons lost in {model}"
    print(f"{model}: {len(after_controls)} inputs, navigation and LOAD preserved")
