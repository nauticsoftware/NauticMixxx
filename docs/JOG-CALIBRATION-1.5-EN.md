# Inpulse 500 progressive jog rim calibration

October 4, 2026 test adjustment for NauticMixxx 1.6.0.

## What changes

The initial v1.5 curve gave almost the same bend output to slow and fast
rim turns (1.9–2.4). This test adjustment reduces gain across the range and
provides more room for small phase corrections, progressively increasing
response as the rim turns faster:

```
jog = sign × sensitivity × [slow + (fast − slow) × ((magnitude − 1) / 62)^curve]
```

Magnitude is clamped to 1–63. Inpulse RX3 mapping defaults:

```
rx3JogBendSlow = 0.35
rx3JogBendFast = 1.6
rx3JogBendCurve = 0.75
rx3JogBendSensitivity = 1.0
```

| MIDI magnitude | Initial v1.5 output | Test output |
| ---: | ---: | ---: |
| 1 | 1.90 | 0.35 |
| 4 | 2.07 | 0.48 |
| 16 | 2.23 | 0.78 |
| 63 | 2.40 | 1.60 |

The slowest message has 82% less gain and the fastest has 33% less gain.
Every nonzero message contributes, without an added MIDI dead zone or integer
rounding. The reported 1.5–2 revolutions was a feel reference, not a fixed
requirement or a published Pioneer specification. No beat-per-revolution rule
or BPM-dependent gain is imposed. These values are an Inpulse calibration
hypothesis, not a measured or copied XDJ/CDJ firmware curve.

Output is not a fixed pitch percentage or displacement per revolution:
message frequency, audio buffer size and Mixxx smoothing still affect the
result. This adjustment does not change the engine filter or recover motion
for which the controller sends no MIDI message.

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
   for a small phase correction without scratching or stopping playback. Try
   repeated minimal movements and an immediate direction reversal; record any
   remaining lack of audible response.
3. Try approximately half a turn, then faster movements. Check the phase
   correction and return to fader tempo after release. Compare with a real
   XDJ/CDJ using the same track, tempo, angle and approximate turning speed.
4. Verify top-surface scratching independently, plus paused and SHIFT seeking.
5. Record firmware, audio buffer, slow/fast MIDI traces and phase displacement
   in milliseconds. Adjust `rx3JogBendSlow` for slow-turn response;
   `rx3JogBendFast` for fast-turn overshoot. Use `rx3JogBendSensitivity` (for
   example 0.8 or 1.2) to scale both together. Restart the mapping after editing.

Automated tests exercise the actual handlers on decks 1–4 with VINYL on/off,
slow repeated messages and direction reversal. They also verify scratching,
paused search, SHIFT and grid/loop priority. They do not measure mechanical resistance, MIDI resolution or
physical audible response.

## Sources

- [Hercules Inpulse 500 MIDI commands](https://ts.hercules.com/download/sound/manuals/DJC_Inpulse500/DJControlInpulse500_MIDI_Commands.pdf).
- [XDJ-RX3 hardware diagram](https://downloads.support.alphatheta.com/software_info/all-in-one-dj-systems/XDJ-RX3/XDJ-RX3_HardwareDiagram_rekordbox_E1.pdf).
- [AlphaTheta jog-wheel operation](https://downloads.support.alphatheta.com/manuals/all-in-one-dj-systems/XDJ-AZ/html/en/000COV_en/Using_the_jog_wheel/Using_the_jog_wheel.htm?rhtocid=_12).
- Official Mixxx scripts: [DDJ-400](https://github.com/mixxxdj/mixxx/blob/main/res/controllers/Pioneer-DDJ-400-script.js), [DDJ-SX](https://github.com/mixxxdj/mixxx/blob/main/res/controllers/Pioneer-DDJ-SX-scripts.js), [DDJ-FLX4](https://github.com/mixxxdj/mixxx/blob/main/res/controllers/Pioneer-DDJ-FLX4-script.js).
