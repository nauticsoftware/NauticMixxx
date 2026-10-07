# NauticMixxx 1.9 performance GRID

The active deck follows deck control input from MIDI, keyboard, mouse and
synthesized touch. Control-owner confirmations and transport feedback do not
select decks. The selected deck is independent of playback MASTER and uses
white outlines around its waveform info and track card. Deck widgets also
select on touch/mouse press. Inpulse jog/touch paths explicitly select even
when no transport control is sent.

In PERFORMANCE, hold Inpulse BROWSER for 2000 ms to toggle GRID. A short press
exits GRID. Rotation while held cancels the long-press action. In BROWSE the
same hold does not activate GRID. The on-screen GRID button toggles this state.
The encoder shifts the selected loaded track by 5 ms per MIDI step through the
existing engine grid-translation control. During GRID, jog movement selects
a deck without moving its transport or grid. Outside GRID its normal behavior
is retained. Only red downbeat ticks extend across the selected waveform;
white beat ticks and the other deck retain their normal edge geometry.

The selected deck's pad strip becomes GRID tools. Snap Grid (CUE) moves the
closest beat to the track's main CUE, without seeking the transport. Shift Grid
indicates the active encoder tool. The two 1/2 buttons translate earlier/later
by half a beat using the tempo near the current position. Reset restores the
entry snapshot for that track in this GRID session. Changing tracks captures a
new snapshot; changing deck does not overwrite an existing snapshot. Existing
USB temporary-track policies prevent importing, persistence and metadata export.

Both fixed deck wave pairs blink together with a 400 ms on/off approximation,
restart on PLAY and disappear immediately on pause or unload. This is not a
measured hardware cadence. The 6% pitch chip uses the user's #18FC00 reference.

macOS RX3 starts as a fixed 1280×800 frameless window. Cmd+Q and the native
application menu remain available for quitting/preferences/fullscreen commands.

Validation artifacts: build/test-candidate/1.9.0-performance-qa. Hardware audio,
controller and touchscreen verification must be done on the target system.
