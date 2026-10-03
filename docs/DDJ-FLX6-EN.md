# DDJ-FLX6: open and navigate the NauticMixxx menu

NauticMixxx includes an **optional, browser-only** DDJ-FLX6 MIDI preset. It maps the following physical controls:

| DDJ-FLX6 control | NauticMixxx action | MIDI message |
| --- | --- | --- |
| VIEW | Toggle BROWSE and PERFORMANCE | Note `0x96 0x7A` |
| SHIFT + VIEW | Open the SOURCE list on the native macOS build | Note `0x96 0x68` |
| BROWSE knob, turn | Move the highlighted item up or down | CC `0xB6 0x40` |
| BROWSE knob, press | Open BROWSE, then enter a highlighted source, folder or track list | Note `0x96 0x41` |
| BACK | Go to the previous menu level | Note `0x96 0x65` |
| LOAD 1 / LOAD 2 | Load the highlighted track to deck 1 / deck 2 | Notes `0x96 0x46` / `0x96 0x47` |

The controls and messages come from the [official DDJ-FLX6 hardware diagram](https://downloads.support.alphatheta.com/software_info/dj-controllers/DDJ-FLX6/DDJ-FLX6_HardwareDiagram_rekordbox_E1.pdf) and [MIDI message list](https://downloads.support.alphatheta.com/software_info/dj-controllers/DDJ-FLX6/DDJ-FLX6_MIDI_message_List_J1.pdf). The mapping has been checked in software against NauticMixxx's browser controls; physical DDJ-FLX6 testing remains to be done.

To try the included preset, connect the DDJ-FLX6, open **Preferences → Controllers**, select its MIDI input, enable it, and choose **Pioneer DDJ-FLX6 - NauticMixxx RX3 browser only**. Restart the app if the newly installed preset is not listed yet. The native macOS and Windows installers put the preset in the separate NauticMixxx profile. The installer does not select it automatically.

**This preset maps only the seven browser actions above.** It does not map PLAY/CUE, jog wheels, mixer, pitch, headphones, effects, or LEDs. Selecting it in place of a full DDJ-FLX6 preset leaves those controls unmapped. To keep an existing full FLX6 mapping, add these seven `<control>` entries to its `<controls>` block, add `<file functionprefix="NauticFLX6Browser" filename="Pioneer-DDJ-FLX6-RX3-Browser.js"/>` inside its `<scriptfiles>` block, and keep the JS file beside the full preset. Remove any existing assignments for the same MIDI messages first. See the [Mixxx MIDI mapping format](https://github.com/mixxxdj/mixxx/wiki/MIDI-controller-mapping-file-format) for the XML structure.

Native NauticMixxx 1.3 builds on macOS and Windows support SOURCE and USB-only browsing. When the preset is used with a standard Mixxx skin, VIEW controls Mixxx's maximized library instead. The mapping reads that library state when the NauticMixxx tab control is unavailable, so pressing VIEW again returns to the previous layout without loading a track. The 1.3.1 installers include the updated script. This software fix awaits a physical DDJ-FLX6 retest. If you have a DDJ-FLX6-GT, check its MIDI messages with Mixxx's MIDI logging before using this FLX6 preset; the GT variant has not been verified.
