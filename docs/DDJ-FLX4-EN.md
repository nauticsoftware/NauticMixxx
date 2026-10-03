# DDJ-FLX4 browser integration (development preview)

This optional preset extends the complete Mixxx DDJ-FLX4 mapping with NauticMixxx RX3 browser navigation. It retains the existing deck, mixer, pad, effect, and output bindings. Thanks to [muehlauer](https://github.com/muehlauer) for reporting the browse problem and contributing the first adaptation, and to the original Mixxx FLX4 mapping authors.

| DDJ-FLX4 control | Action | MIDI message |
| --- | --- | --- |
| BROWSE, turn | Move the selected browser item | CC `0xB6 0x40` |
| BROWSE, press | Open the browser or enter the selected item | Note `0x96 0x41` |
| SHIFT + BROWSE, press | Go back one browser level | Note `0x96 0x42` |
| SHIFT + LOAD 1 | Open SOURCE | Note `0x96 0x68` |
| SHIFT + LOAD 2 | Toggle browser and performance views | Note `0x96 0x7A` |
| LOAD 1 / LOAD 2 | Load the selected track to the corresponding deck | Notes `0x96 0x46` / `0x96 0x47` |

The messages and button names follow the [official DDJ-FLX4 MIDI message list](https://downloads.support.alphatheta.com/software_info/dj-controllers/DDJ-FLX4/DDJ-FLX4_MIDI_message_List_J1.pdf). The contributed XML had duplicate assignments for BROWSE and LOAD and included FLX6 button labels. This preset uses each input message once. The browser script uses the native RX3 controls when available and Mixxx's library controls otherwise.

The three files in `controllers/Pioneer_DDJ_FLX4_RX3/` belong together: the full preset XML, the original Mixxx FLX4 script, and the RX3 browser script. Select **Pioneer DDJ-FLX4 - NauticMixxx RX3 browser** under **Preferences → Controllers** after installing the preset. Back up your existing controller mapping before replacing it.

This source change is intended for the next test candidate. The published 1.3.0 installers do not contain it. Automated MIDI and browser state checks pass; physical DDJ-FLX4 testing is still required before a release claim.
