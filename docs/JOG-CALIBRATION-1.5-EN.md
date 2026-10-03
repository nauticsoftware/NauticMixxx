# Inpulse 500 jog rim settings in v1.5

## What changes

The previous playing-track rim path sent MIDI magnitude directly to Mixxx's
`jog` control. Very slow movements produced little response, while faster
movements could overcorrect. v1.5 introduces a compressed curve on this path:

```
jog = sign × sensitivity × [slow + (fast − slow) × ln(magnitude) / ln(63)]
```

Magnitude is clamped to 1–63. Defaults in the Inpulse RX3 script:

```
rx3JogBendSlow = 1.9
rx3JogBendFast = 2.4
rx3JogBendSensitivity = 1.0
```

| MIDI magnitude | Previous output | v1.5 output |
| ---: | ---: | ---: |
| 1 | 1 | 1.90 |
| 4 | 4 | 2.07 |
| 16 | 16 | 2.23 |
| 63 | 63 | 2.40 |

This strengthens individual slow-turn messages and limits individual fast-turn
messages. The output is not a fixed pitch percentage or displacement per
revolution: message frequency and the Mixxx engine affect the result. It cannot
recover motion for which the controller sends no MIDI message.

Scratch on the top surface, paused seeking, SHIFT searching, loops and grid
adjustments retain their existing paths. This change applies only to Hercules
DJControl Inpulse 500, not to the added Pioneer/Roland presets.

## Comparison with Pioneer

The official Mixxx DDJ-400 and FLX4 scripts use `(value − 64) × 0.8` for jog
bend. DDJ-SX uses `(value − 64) / 5 × jogwheelSensitivity`, with a separate
SHIFT multiplier. They separate scratching from rim bending, but their
numerical scales cannot be copied directly: these Pioneer messages are
centered at `0x40`; Inpulse encodes direction and intensity differently.

With VINYL active on XDJ/CDJ, the rim provides temporary pitch bend and the
top surface provides scratching. JOG FEEL/ADJUST controls physical resistance.
There is no published universal rim-bend curve that establishes numerical
parity with a CDJ/XDJ. Paused search distance per revolution is a different
measurement from playing-track pitch bend.

These settings are a software-tested starting point. Physical equivalence to
Pioneer is **not validated**.

## Physical calibration procedure

1. Load two copies of a 120 BPM track with a correct beatgrid. Disable SYNC
   and SLIP, match tempo with the faders and enable VINYL.
2. Move only the rim slowly through 15–20 degrees in both directions. Check
   for a useful phase correction without scratching or stopping playback.
3. Try approximately half a turn, then faster movements. Check the phase
   correction and return to fader tempo after release. Compare with a real
   XDJ/CDJ using the same track, tempo, angle and approximate turning speed.
4. Verify top-surface scratching independently, plus paused and SHIFT seeking.
5. Record firmware, audio buffer, slow/fast MIDI traces and phase displacement
   in milliseconds. Adjust `rx3JogBendSlow` for slow-turn response;
   `rx3JogBendFast` for fast-turn overshoot. Use `rx3JogBendSensitivity` (for
   example 0.8 or 1.2) to scale both together. Restart the mapping after editing.

Automated tests verify the curve, direction symmetry and preserved alternate
jog paths. They do not measure mechanical resistance, MIDI resolution or
physical audible response.

## Sources

- [Hercules Inpulse 500 MIDI commands](https://ts.hercules.com/download/sound/manuals/DJC_Inpulse500/DJControlInpulse500_MIDI_Commands.pdf).
- [XDJ-RX3 hardware diagram](https://downloads.support.alphatheta.com/software_info/all-in-one-dj-systems/XDJ-RX3/XDJ-RX3_HardwareDiagram_rekordbox_E1.pdf).
- [AlphaTheta jog-wheel operation](https://downloads.support.alphatheta.com/manuals/all-in-one-dj-systems/XDJ-AZ/html/en/000COV_en/Using_the_jog_wheel/Using_the_jog_wheel.htm?rhtocid=_12).
- Official Mixxx scripts: [DDJ-400](https://github.com/mixxxdj/mixxx/blob/main/res/controllers/Pioneer-DDJ-400-script.js), [DDJ-SX](https://github.com/mixxxdj/mixxx/blob/main/res/controllers/Pioneer-DDJ-SX-scripts.js), [DDJ-FLX4](https://github.com/mixxxdj/mixxx/blob/main/res/controllers/Pioneer-DDJ-FLX4-script.js).
