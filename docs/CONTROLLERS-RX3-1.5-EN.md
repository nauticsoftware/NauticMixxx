# Controller behavior in NauticMixxx 1.5

## Hercules DJControl Inpulse 500

| Gesture | Result |
| --- | --- |
| Tap ASSISTANT | Open SOURCE on release |
| Hold ASSISTANT for 600 ms while BROWSE is open | Return to PERFORMANCE without loading a track |
| SHIFT + ASSISTANT | Toggle the side panel once |
| Turn BROWSE | Move the selection |
| Press BROWSE | Enter the selected source/category or open the track table |
| SHIFT + BROWSE | Go back one browser level |
| Hold BROWSE for 2 seconds | Existing GRID operation |
| LOAD 1 / LOAD 2 | Load the selected track into the corresponding deck |

The new ASSISTANT hold lets you check the loaded track's key, BPM and deck
information, then resume browsing. It does not change playback, CUE, SYNC,
loop state or the selected source. Releasing after a hold does not reopen
SOURCE. A short press now acts on release, adding at most the duration of
your tap. A hold started outside BROWSE retains the SOURCE action on release.

Only this controller receives the new jog rim curve. With a playing track,
turning the rim sends a temporary pitch bend; touching the top in VINYL mode
uses the existing scratch path. Pause, SHIFT, beatgrid and loop adjustments
retain their existing paths. See [jog settings and measurement procedure](JOG-CALIBRATION-1.5-EN.md).

## Pioneer and Roland navigation

Full presets are included for all seven models below. The native app selects
an RX3 preset when the MIDI device name contains the model name. If the OS
uses a different port name, choose the matching **RX3** preset manually in
**Preferences > Controllers** and enable it. The skin-only package requires
manual selection in official Mixxx.

| Model | Browse / enter | Back | SOURCE | VIEW / exit BROWSE |
| --- | --- | --- | --- | --- |
| DDJ-400 | Turn / press BROWSE | SHIFT + BROWSE | SHIFT + LOAD 1 | SHIFT + LOAD 2 |
| DDJ-SX | Turn / press BROWSE | BACK | SHIFT + LOAD PREPARE | SHIFT + BACK |
| DDJ-SX2 | Turn / press BROWSE | BACK | SHIFT + LOAD PREPARE | SHIFT + BACK |
| DDJ-SX3 | Turn / press BROWSE | BACK | SHIFT + LOAD PREPARE | SHIFT + BACK |
| DDJ-WeGO3 | Turn / press BROWSE | SHIFT + BROWSE | SHIFT + LOAD 1 | SHIFT + LOAD 2 |
| DDJ-FLX4 | Turn / press BROWSE | SHIFT + BROWSE | SHIFT + LOAD 1 | SHIFT + LOAD 2 |
| Roland DJ-505 | Turn / press BROWSE | BACK | SHIFT + BACK | ADD PREPARE |

Pressing BROWSE in PERFORMANCE first opens BROWSE without selecting or loading
a track. Turn the encoder to navigate. SOURCE opens device/category selection;
BACK moves up one level. VIEW switches between PERFORMANCE and BROWSE and
lets you leave without loading. Normal LOAD buttons retain their deck-loading
actions. In official Mixxx, the adapter uses the available Library controls
instead of the native RX3 browser.

### Reassigned functions

The new bindings replace the original actions at these MIDI addresses.
DDJ-SX SHIFT + LOAD PREPARE no longer toggles AutoDJ; SX2's corresponding
library-maximize action becomes SOURCE. Roland SHIFT + BACK no longer sorts
tracks and ADD PREPARE becomes VIEW. The XML files document every replaced
input. Transport, mixer, pads, effects, jogs and normal LOAD controls keep
their source mappings. Pioneer/Roland jog sensitivity is **not recalibrated**
by the Inpulse change.

| Model | Turn | Enter | Back | SOURCE | VIEW |
| --- | --- | --- | --- | --- | --- |
| DDJ-400 | B6/40 | 96/41 | 96/42 | 96/68 | 96/7A |
| DDJ-SX/SX2/SX3 | B6/40 | 96/41 | 96/65 | 96/68 | 96/66 |
| DDJ-WeGO3 | B6/40 | 96/41 | 96/42 | 96/58 | 96/59 |
| Roland DJ-505 | BF/00 and BF/01 | 9F/06 | 9F/07 | 9F/12 | 9F/1B |

Addresses use hexadecimal status/control notation. DDJ-FLX4 details are in
its [dedicated guide](DDJ-FLX4-EN.md). The optional FLX6 preset remains
[browser-only](DDJ-FLX6-EN.md).

### Validation and limitations

Automated tests check complete XMLs, preserved LOAD/output mappings, script
dependencies, browser navigation, stock-Mixxx fallback and gesture timing.
The seven Pioneer/Roland devices were not connected for physical validation.
Check navigation, loading, LEDs, audio routing and deck selection on your
hardware before using the new preset in a performance.

**SX3 is experimental.** Its community XML contained an incomplete SX3
fragment followed by a complete SX2 XML. The generator overlays the SX3
controls on the SX2 base and retains the common script. Software checks pass;
LEDs, pads and channels still need hardware confirmation. This does not
promise parity with every SX3 hardware feature.

Report your model/firmware, OS, audio buffer, MIDI port name, gesture and
actual/expected result. A MIDI trace is useful if a button is not detected.

## English default

New configurations and installation profiles use `en_US`, independently of
the operating system. An explicitly selected language or command-line locale
continues to take precedence. Future builds retain this default.

## Sources and regeneration

- [Mixxx official controller mappings](https://github.com/mixxxdj/mixxx/tree/main/res/controllers).
- [DDJ-400 MIDI list](https://downloads.support.alphatheta.com/software_info/dj-controllers/DDJ-400/DDJ-400_MIDI_Message_List_E1.pdf).
- [DDJ-SX2 MIDI list](https://downloads.support.alphatheta.com/software_info/dj-controllers/DDJ-SX2/DDJ-SX2_List_of_MIDI_Message_E.pdf).
- [DDJ-SX3 MIDI list](https://downloads.support.alphatheta.com/software_info/dj-controllers/DDJ-SX3/DDJ-SX3_MIDI_Message_List_E1.pdf).
- [DDJ-WeGO3 MIDI list](https://www.pioneerdj.com/-/media/pioneerdj/software-info/controller/ddj-wego3/ddj-wego3_list_of_midi_message_e.pdf).
- [Roland DJ-505 manual](https://static.roland.com/assets/media/pdf/DJ-505_eng02_W.pdf).
- Community bases: [SX2/SX3](https://github.com/ardje/Mixxx-Pioneer-DDJ-SX3), [WeGO3](https://github.com/matthewryanscott/mixxx-pioneer-ddj-wego3).

```sh
python3 scripts/generate-rx3-browser-presets.py
python3 scripts/test-pioneer-roland-presets.py
node scripts/test-pioneer-roland-browser.js
node scripts/test-rx3-browser-exit.js
node scripts/test-rx3-jog-bend.js
```
