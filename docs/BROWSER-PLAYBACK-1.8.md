# BROWSER — NauticMixxx 1.8 development

## Pioneer research

The Pioneer XDJ-RX3 Instruction Manual, page 44, says that tracks played for
approximately one minute enter History and their information is displayed in
green. Manufacturer-hosted URLs were inaccessible during this investigation;
the original manufacturer document was read through this mirror:
https://www.manua.ls/pioneer/xdj-rx3/manual?p=44

The manual does not specify pause accumulation, seeking, fader conditions,
or exact RGB values. The following are explicit NauticMixxx implementation
choices, rather than claimed Pioneer internals.

## Behavior

| State | Color | Title icon |
| --- | --- | --- |
| Playing in a main deck | #01FF02 | PLAY triangle |
| Stopped after 60 seconds in a load | #008A01 | Note, plus H if lossless |
| Stopped after a shorter audition | #FFFFFF | Note, plus H if lossless |

60 seconds is measured by a monotonic elapsed clock, not by seek distance.
Pause retains the elapsed time for the same load and adds no time. Replacing
or unloading an unqualified track resets its timer. A qualified track retains
its mark for this application session. Simultaneous copies in two decks do not
add their time together. Preview players, cue-preview and samplers are excluded.
An interval over one second is excluded to avoid counting sleep or a stalled UI.
The state remains active while the browser is closed and follows USB UUID +
Rekordbox track ID, so the same numeric ID on another USB is independent.
No USB history, music metadata, SQL history or Mixxx play counter is rewritten.

## Lossless and icon geometry

WAV, AIFF/AIF, FLAC and ALAC get H. M4A is probed asynchronously using TagLib
audio codec properties; AAC gets no H, ALAC does. PLAY replaces both note and
H until playback stops. Category icons are rendered on a shared 32 × 32 vector
canvas, including ARTIST, ALBUM, TRACK, KEY, PLAYLIST, HISTORY, MATCHING,
FOLDER and REC, with additional exported categories supported.

STATUS / BEAT FX keeps a 50 px outer height: a 1 px border and 2 px inner
padding leave 44 px for the button on all sides.

## Reported permission crash

The supplied 1.7.0 crash report (October 4, 2026, 19:06:57 ART) shows
EXC_BAD_ACCESS at a null address in QObject::disconnect, called by
DlgPrefControllers::destroyControllerWidgets on the GUI thread. It does not
establish that the microphone permission API itself failed. Teardown now
disconnects saved connection handles without touching device objects and
ControllerManager clears the device list before deleting its enumerators.
Exact reproduction of the macOS permission sequence remains a hardware/UI
validation item; automated playback and format tests cover the browser rules.

## Deck badge and overview

The deck badge places DECK directly above its numeral. Three vector waves grow
from small to large, then blink off; a paused or unloaded deck has no waves.
The implementation follows PLAY as requested. The [RX3 instruction manual](https://www.djcenter.ee/images/kasutusjuhendid/Pioneer-XDJ-RX3.pdf)
describes red waves when a deck outputs sound to MASTER, without
specifying a period. The animation uses an approximate 200 ms step and 800 ms
cycle, independent of BPM; this is not a measured hardware cadence.

The overview axis is gray ahead of the current PLAYHEAD and white behind it,
including after a seek backward. MASTER fills the BPM header to the right inner
border with centered text; BPM captions have 1 px left padding in both modes.
