// DJControl_Inpulse_500_script.js
//
// ***************************************************************************
// * Mixxx mapping script file for the Hercules DJControl Inpulse 500.
// * Authors: Ev3nt1ne, DJ Phatso, resetreboot
// *    contributions by Kerrick Staley, Bentheshrubber, ThatOneRuffian
//
//  Version 1.6c: (August 2023) resetreboot
//  * Requires Mixxx >= 2.3.4
//  * Volume meters follow correctly the selected channel
//  * Use the full 14 bits for knobs for more precision
//  * Add effects to the PAD 7 mode
//  * Create decks for four channel mode
//  * Change the behavior of the FX buttons, use them as Channel selector, using the LEDs
//    as indicators of current channel.
//
//
//  * When enabling multichannel, ensure:
//    - Beat matching guide follows correctly the selected channels
//
//  * Move the sampler buttons to the Deck component as well as the new effect buttons
//  * Made the filter knob have a function with filter, effect and filter + effect
//  * Use the Hotcue component for hotcues
//  * Use components and add for the rest of the controls:
//    - Play
//    - Cue
//    - Sync
//    - Volume fader
//    - EQs
//    - PFL
//    - Pad Selectors
//    - Loop PADs
//    - Roll PADs
//    - Beat jump PADs
//    - Tone key PADs
//    - Slicer
//    - Loop pot
//    - In and Out loop
//    - Load button
//    - Vinyl
//    - Slip
//    - Quant
//    - Pitch fader
//    - Jog wheels (Using the new JogWheelBasic component!
//      - Also probably fixed the shift behavior not working properly
//
//  * Added option so the browser knob can behave with out of focus window
//
// * Version 1.5c (Summer 2023)
// * Forum: https://mixxx.discourse.group/t/hercules-djcontrol-inpulse-500/19739
// * Wiki: https://mixxx.org/wiki/doku.php/hercules_djcontrol_inpulse_500
//
//  Version 1.0c:
//  * Hot Cue: implementation of the Color API (Work in progress)
//    - Assigned color directly to pad (XML)
//  * Added DECK LED number - On when playing
//  * Moved Beatjump to Pad mode 3 (Slicer)
//  * Set different color for upper (Sampler 1-4) and lower (Sampler 5-8) sampler pads
//
//  Version 1.0 - Based upon Inpulse 300 v1.2 (official)
//
// TO DO:
//  * Browser knob has a ton of colors to do things!
//  * Vinyl + SHIFT led should reflect brake status
//  * Quant + SHIFT led should reflect key lock status
//  * Add beat jump + SHIFT jumps
//
// ****************************************************************************

var DJCi500 = {}; // eslint-disable-line

///////////////////////////////////////////////////////////////
//                       USER OPTIONS                        //
///////////////////////////////////////////////////////////////

// If you are spinning your set list and you have your Mixxx window out
// of focus and you want to be able to use the browser knob to traverse
// the current crate or playlist, set to true. Especially useful to spin
// when using Twitch, VRChat or Second Life
DJCi500.browserOffFocusMode = false;

// XDJ-RX3-style browser state. A short encoder press confirms an item;
// holding the encoder while turning performs a page jump.
DJCi500.rx3BrowserPressed = false;
DJCi500.rx3BrowserMovedWhilePressed = false;
DJCi500.rx3BrowserHoldTimer = null;
DJCi500.rx3BrowserHoldConsumed = false;
DJCi500.rx3BrowserPressedAt = 0;
DJCi500.rx3BrowserIgnoreUntil = 0;
DJCi500.rx3GridTicksPerStep = 4;
DJCi500.rx3GridRemainders = {};

DJCi500.rx3CancelBrowserTimer = function() {
    if (DJCi500.rx3BrowserHoldTimer !== null) {
        engine.stopTimer(DJCi500.rx3BrowserHoldTimer);
        DJCi500.rx3BrowserHoldTimer = null;
    }
};

DJCi500.rx3GridActive = function() {
    return engine.getValue("[RX3Controller]", "grid_mode") > 0;
};

DJCi500.rx3SetGridMode = function(enabled) {
    engine.setValue("[RX3Controller]", "grid_mode", enabled ? 1 : 0);
    DJCi500.rx3GridRemainders = {};
    if (enabled) {
        for (const deckData of [DJCi500.deckA, DJCi500.deckB]) {
            if (deckData) deckData.loopAdjustMode = null;
        }
        for (let deck = 1; deck <= 4; deck++) {
            if (engine.isScratching(deck)) engine.scratchDisable(deck);
        }
        engine.setValue("[XDJ_RX3]", "search_active", 0);
        engine.setValue("[Skin]", "show_maximized_library", 0);
        engine.setValue("[Tab]", "overview", 0);
        engine.setValue("[Tab]", "overview", 1);
    }
};

DJCi500.rx3BrowserLongPress = function() {
    DJCi500.rx3BrowserHoldTimer = null;
    if (!DJCi500.rx3BrowserPressed || DJCi500.rx3BrowserMovedWhilePressed || DJCi500.rx3BrowserHoldConsumed) return;
    DJCi500.rx3BrowserHoldConsumed = true;
    DJCi500.rx3SetGridMode(!DJCi500.rx3GridActive());
};

DJCi500.rx3AdjustBeatGrid = function(deckData, ticks) {
    if (!DJCi500.rx3GridActive()) return false;
    const group = deckData.currentDeck;
    const deck = script.deckFromGroup(group);
    if (engine.isScratching(deck)) engine.scratchDisable(deck);
    if (!engine.getValue(group, "track_loaded")) {
        DJCi500.rx3GridRemainders[group] = 0;
        return true;
    }
    const total = (DJCi500.rx3GridRemainders[group] || 0) + ticks;
    const steps = Math.trunc(total / DJCi500.rx3GridTicksPerStep);
    DJCi500.rx3GridRemainders[group] = total - steps * DJCi500.rx3GridTicksPerStep;
    if (steps !== 0) engine.setValue(group, "beats_translate_move", steps);
    return true;
};

DJCi500.rx3ToggleVinyl = function(deckData, midiStatus) {
    const deck = script.deckFromGroup(deckData.currentDeck);
    const enabled = !deckData.vinylButtonState[deck - 1];
    deckData.vinylButtonState[deck - 1] = enabled;
    deckData.jogWheel.vinylMode = enabled;
    deckData.jogWheelShift.vinylMode = enabled;
    // Cancel the engine immediately; the default ramp can leave isScratching
    // true after the VINYL lamp goes out (especially with a stationary jog).
    if (!enabled) engine.scratchDisable(deck, false);
    midi.sendShortMsg(midiStatus, 0x03, enabled ? 0x7F : 0x00);
};

// XDJ-RX3 side panel. Page 0 is BEAT FX and page 1 is STATUS / HOT CUES.
// The controls are created by the skin's WidgetStack.
// The hardware display opens on STATUS / HOT CUE, matching the RX3
// performance screen. SHIFT + ASSISTANT can still toggle to BEAT FX.
DJCi500.rx3StatusVisible = true;
DJCi500.rx3SidePanelConnection = null;

// Set initial state for vinyl mode button
DJCi500.initialVinylMode = true;

// Constants
DJCi500.EFFECT_ONLY_MODE = 1;
DJCi500.FILTER_AND_EFFECT_MODE = 2;

// The four central FX buttons emulate the most useful XDJ-RX3 Sound Color FX.
// Presets 1-4 are installed by install-mixxx-rx3-controller-macos.sh.
// REVERB, PING PONG and NOISE use the distance from the knob centre as amount;
// FILTER keeps Mixxx's native bipolar LPF/HPF response around the centre.
DJCi500.rx3SoundColorFx = [
    null,
    {name: "REVERB", preset: 1, centeredAmount: true},
    {name: "PING PONG", preset: 2, centeredAmount: true},
    {name: "NOISE", preset: 3, centeredAmount: true},
    {name: "FILTER", preset: 4, centeredAmount: false},
];
DJCi500.rx3SoundColorFxSelected = 0;
DJCi500.rx3SoundColorFxBlinkOn = false;
DJCi500.rx3SoundColorFxTimer = null;
DJCi500.rx3ColorKnobPositions = {1: 0.5, 2: 0.5};

// The RX3 offers the four standard TEMPO ranges. The Inpulse BEATMATCH GUIDE
// button is otherwise unused by Mixxx, so it cycles this shared range for both
// physical decks.
DJCi500.rx3TempoRanges = [0.06, 0.10, 0.16, 1.0];
DJCi500.rx3TempoRangeIndex = -1;

DJCi500.rx3SoundColorFxAmount = function(normalized) {
    const selected = DJCi500.rx3SoundColorFxSelected;
    if (selected === 0) {
        return normalized;
    }
    return DJCi500.rx3SoundColorFx[selected].centeredAmount ?
        Math.abs(normalized - 0.5) * 2 : normalized;
};

DJCi500.rx3PaintSoundColorFx = function() {
    for (let index = 1; index <= 4; index++) {
        const selected = index === DJCi500.rx3SoundColorFxSelected;
        const illuminated = !selected || DJCi500.rx3SoundColorFxBlinkOn;
        midi.sendShortMsg(0x90, 0x13 + index, illuminated ? 0x7F : 0x00);
    }
};

DJCi500.rx3BlinkSoundColorFx = function() {
    DJCi500.rx3SoundColorFxBlinkOn = !DJCi500.rx3SoundColorFxBlinkOn;
    DJCi500.rx3PaintSoundColorFx();
};

DJCi500.rx3SetSoundColorFxEnabled = function(enabled) {
    for (let deck = 1; deck <= 2; deck++) {
        engine.setValue(`[QuickEffectRack1_[Channel${deck}]]`, "enabled", enabled ? 1 : 0);
    }
};

DJCi500.rx3SoundColorFxKnob = function(deck, normalized) {
    DJCi500.rx3ColorKnobPositions[deck] = normalized;
    if (DJCi500.rx3SoundColorFxSelected === 0) {
        return false;
    }

    const group = `[QuickEffectRack1_[Channel${deck}]]`;
    engine.setValue(group, "super1", DJCi500.rx3SoundColorFxAmount(normalized));
    engine.setValue(group, "enabled", 1);
    return true;
};

DJCi500.rx3SoundColorFxButton = function(_channel, control, value) {
    if (value !== 0x7F) {
        return;
    }

    const selected = control - 0x13;
    if (selected < 1 || selected > 4) {
        return;
    }

    if (DJCi500.rx3SoundColorFxSelected === selected) {
        DJCi500.rx3SoundColorFxSelected = 0;
        DJCi500.rx3SoundColorFxBlinkOn = false;
        DJCi500.rx3SetSoundColorFxEnabled(false);
        DJCi500.rx3PaintSoundColorFx();
        return;
    }

    DJCi500.rx3SoundColorFxSelected = selected;
    const preset = DJCi500.rx3SoundColorFx[selected].preset;
    for (let deck = 1; deck <= 2; deck++) {
        const group = `[QuickEffectRack1_[Channel${deck}]]`;
        engine.setValue(group, "loaded_chain_preset", preset);
        engine.setValue(group, "super1",
            DJCi500.rx3SoundColorFxAmount(DJCi500.rx3ColorKnobPositions[deck]));
        engine.setValue(group, "enabled", 1);
    }
    DJCi500.rx3SoundColorFxBlinkOn = true;
    DJCi500.rx3PaintSoundColorFx();
};

DJCi500.rx3ToggleSlip = function(deckData, value) {
    if (value !== 0x7F) {
        return;
    }
    const group = deckData.currentDeck;
    engine.setValue(group, "slip_enabled",
        engine.getValue(group, "slip_enabled") ? 0 : 1);
};

DJCi500.rx3SyncButton = function(deckData, value, status) {
    if (value !== 0x7F) {
        return;
    }

    const group = deckData.currentDeck;
    const shifted = deckData.isShiftPressed || status === 0x94 || status === 0x95;
    if (shifted) {
        // Pioneer calls keylock "MASTER TEMPO". Keep it independent per deck.
        engine.setValue(group, "keylock", engine.getValue(group, "keylock") ? 0 : 1);
        return;
    }

    const enabled = engine.getValue(group, "sync_enabled") !== 0;
    if (enabled) {
        engine.setValue(group, "sync_enabled", 0);
    } else {
        engine.setValue(group, "beatsync", 1);
        engine.setValue(group, "sync_enabled", 1);
    }
};

DJCi500.rx3TempoRangeButton = function(_channel, _control, value) {
    if (value !== 0x7F) {
        midi.sendShortMsg(0x90, 0x01, 0x00);
        return;
    }

    DJCi500.rx3TempoRangeIndex =
        (DJCi500.rx3TempoRangeIndex + 1) % DJCi500.rx3TempoRanges.length;
    const range = DJCi500.rx3TempoRanges[DJCi500.rx3TempoRangeIndex];
    [DJCi500.deckA, DJCi500.deckB].forEach(function(deckData) {
        if (!deckData) {
            return;
        }
        deckData.pitchRangeId = DJCi500.rx3TempoRangeIndex;
        engine.setValue(deckData.currentDeck, "rateRange", range);
    });
    midi.sendShortMsg(0x90, 0x01, 0x7F);
};

// RX3-inspired fixed pad palettes. Mode 1 approximates the skin's exact A-H
// colors (#FF376F, #45ACDB, #7DC13D, #AA72FF, #30D26E, #E0641B, #305AFF,
// #C3AF04) with the nearest colors supported by the Inpulse 500 firmware.
// Its `off` state is handled separately as white.
DJCi500.rx3PadPalettes = {
    // A pink, B cyan, C lime, D violet, E green, F orange, G blue, H yellow.
    // These are the exact Data2 values documented by Hercules for the pads.
    1: [0x60, 0x1F, 0x5C, 0x63, 0x1C, 0x74, 0x03, 0x7C],
    2: [0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74],
    3: [0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x7F, 0x7F],
    4: [0x60, 0x60, 0x74, 0x74, 0x74, 0x74, 0x60, 0x60],
    5: [0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F],
    6: [0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74, 0x74],
    7: [0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F],
    8: [0x60, 0x60, 0x74, 0x74, 0x74, 0x74, 0x60, 0x60],
};

// XDJ-RX3 Beat Jump / Beat Jump 2 assignments (manual, page 84).
// Signed values are sent through Mixxx's generic beatjump control so an
// active loop is moved by the same amount instead of being deactivated.
DJCi500.rx3BeatJumpPadValues = {
    4: [-1, 1, -2, 2, -4, 4, -8, 8],
    8: [-0.5, 0.5, -2, 2, -4, 4, -16, 16],
};

// SHIFT + one complete jog rotation advances or rewinds roughly 12 seconds.
// This is deliberately faster than frame search while remaining precise
// enough to reach a specific phrase in the track.
DJCi500.rx3FastSeekSecondsPerRevolution = 12;

// Pioneer-style loop IN/OUT adjustment follows the platter at its nominal
// 33 1/3 RPM: one revolution edits roughly 1.8 seconds of audio. Loop points
// are written directly in stereo sample positions, deliberately bypassing
// Mixxx quantize and the beatgrid while adjustment mode is active.
DJCi500.rx3LoopAdjustSecondsPerRevolution = 1.8;

DJCi500.rx3LoopButton = function(deckData, point, value, status) {
    if (value !== 0x7F) {
        return;
    }

    const group = deckData.currentDeck;
    const shifted = status === 0x94 || status === 0x95;
    if (shifted) {
        deckData.loopAdjustMode = null;
        script.triggerControl(group, point === "in" ? "loop_in_goto" : "loop_out_goto");
        return;
    }

    const loopStart = engine.getValue(group, "loop_start_position");
    const loopEnd = engine.getValue(group, "loop_end_position");
    const hasActiveLoop = engine.getValue(group, "loop_enabled") !== 0 &&
        loopStart >= 0 && loopEnd > loopStart;

    if (hasActiveLoop) {
        // Repeated press exits; pressing the other button switches endpoint.
        deckData.loopAdjustMode = deckData.loopAdjustMode === point ? null : point;
        return;
    }

    deckData.loopAdjustMode = null;
    script.triggerControl(group, point === "in" ? "loop_in" : "loop_out");
};

DJCi500.rx3AdjustLoopPoint = function(deckData, tickDelta, wheelResolution) {
    const point = deckData.loopAdjustMode;
    if (point !== "in" && point !== "out") {
        return false;
    }

    const group = deckData.currentDeck;
    const loopStart = engine.getValue(group, "loop_start_position");
    const loopEnd = engine.getValue(group, "loop_end_position");
    if (engine.getValue(group, "loop_enabled") === 0 ||
            loopStart < 0 || loopEnd <= loopStart) {
        deckData.loopAdjustMode = null;
        return false;
    }

    const sampleRate = engine.getValue(group, "track_samplerate");
    if (!(sampleRate > 0) || !(wheelResolution > 0) || !Number.isFinite(tickDelta)) {
        return true;
    }

    // Mixxx loop positions count interleaved stereo samples, hence * 2.
    const rawDelta = tickDelta * sampleRate * 2 *
        DJCi500.rx3LoopAdjustSecondsPerRevolution / wheelResolution;
    const sampleDelta = Math.round(rawDelta / 2) * 2;
    const minimumLoopLength = 2;

    if (point === "in") {
        const newStart = Math.max(0,
            Math.min(loopEnd - minimumLoopLength, loopStart + sampleDelta));
        engine.setValue(group, "loop_start_position", newStart);
    } else {
        const trackSamples = engine.getValue(group, "track_samples");
        const maximumEnd = trackSamples > 0 ? trackSamples : Number.MAX_SAFE_INTEGER;
        const newEnd = Math.min(maximumEnd,
            Math.max(loopStart + minimumLoopLength, loopEnd + sampleDelta));
        engine.setValue(group, "loop_end_position", newEnd);
    }
    return true;
};

// The Inpulse AUTOLOOP encoders use binary-offset relative MIDI values:
// 0x01..0x3F clockwise, 0x41..0x7F counter-clockwise and 0x40 neutral.
// Send complete button pulses so every encoder detent changes beatloop_size,
// including while no loop is active yet.
DJCi500.rx3AutoLoopTurn = function(group, value) {
    if (value === 0x00 || value === 0x40) {
        return;
    }
    script.triggerControl(group, value < 0x40 ? "loop_double" : "loop_halve");
};

DJCi500.rx3TriggerQuantizedLoop = function(group, control) {
    const quantizeWasEnabled = engine.getValue(group, "quantize") !== 0;
    if (!quantizeWasEnabled) {
        engine.setValue(group, "quantize", 1);
    }
    script.triggerControl(group, control);
    if (!quantizeWasEnabled) {
        engine.setValue(group, "quantize", 0);
    }
};

DJCi500.rx3LoopInLongPress = function(deckData, value) {
    if (value !== 0x7F) {
        return;
    }
    deckData.loopAdjustMode = null;
    DJCi500.rx3TriggerQuantizedLoop(deckData.currentDeck, "beatloop_4_activate");
};

DJCi500.rx3AutoLoopPush = function(group, value, status) {
    if (value !== 0x7F) {
        return;
    }

    // Preserve the stock SHIFT shortcut for a fixed four-beat loop. A normal
    // press toggles a beatloop using the size selected by the knob. Enable
    // quantize only for the synchronous trigger so a newly created loop starts
    // at the closest beatgrid line without changing the user's QUANTIZE state.
    const shifted = status === 0x94 || status === 0x95;
    DJCi500.rx3TriggerQuantizedLoop(
        group, shifted ? "beatloop_4_activate" : "beatloop_activate");
};

DJCi500.rx3BeatJumpPadInput = function(deckData, mode, pad, value, status, control) {
    if (value === 0x7F) {
        engine.setValue(
            deckData.currentDeck,
            "beatjump",
            DJCi500.rx3BeatJumpPadValues[mode][pad - 1]
        );
    }
    // Restore the fixed pad color on both press and release.
    midi.sendShortMsg(status, control, DJCi500.rx3PadPalettes[mode][pad - 1]);
};

DJCi500.rx3FastSeek = function(group, tickDelta, wheelResolution) {
    const duration = engine.getValue(group, "duration");
    if (!(duration > 0) || !Number.isFinite(tickDelta)) {
        return;
    }

    const position = engine.getValue(group, "playposition");
    const secondsDelta = tickDelta *
        DJCi500.rx3FastSeekSecondsPerRevolution / wheelResolution;
    const nextPosition = Math.max(0, Math.min(1, position + secondsDelta / duration));
    engine.setValue(group, "playposition", nextPosition);
};

DJCi500.rx3SidePanelChanged = function(value) {
    DJCi500.rx3StatusVisible = (value === 1);
};

DJCi500.rx3ToggleSidePanel = function() {
    DJCi500.rx3StatusVisible = !DJCi500.rx3StatusVisible;
    engine.setValue("[RX3SidePanel]", DJCi500.rx3StatusVisible ? "status" : "beatfx", 1);
};

DJCi500.rx3PulseBrowserControl = function(control, value) {
    engine.setValue("[RX3Browser]", control, value);
    engine.setValue("[RX3Browser]", control, 0);
};

// ASSISTANT is the controller-independent SOURCE command. SHIFT + ASSISTANT
// retains the existing STATUS / BEAT FX shortcut.
DJCi500.rx3AssistantButton = function(_channel, _control, value) {
    if (value !== 0x7F) {
        return;
    }
    const shifted = (DJCi500.deckA && DJCi500.deckA.isShiftPressed) ||
        (DJCi500.deckB && DJCi500.deckB.isShiftPressed);
    if (shifted) {
        DJCi500.rx3ToggleSidePanel();
    } else if (engine.getValue("[RX3Browser]", "enabled")) {
        DJCi500.rx3PulseBrowserControl("source", 1);
    } else {
        DJCi500.rx3OpenBrowse();
    }
};

DJCi500.rx3RefreshPadLeds = function(deckData) {
    const mode = deckData.activePadMode;
    const baseMode = ((mode - 1) % 4) + 1;
    const status = 0x95 + deckData.midiChannel;

    if (mode === 1) {
        // HotcueButton supplies the fixed RX3 marker color when assigned and
        // white when empty.
        for (let i = 1; i <= 8; i++) {
            deckData.hotcueButtons[i].trigger();
        }
        return;
    }

    const colors = DJCi500.rx3PadPalettes[mode];
    for (let i = 0; i < 8; i++) {
        const baseControl = (baseMode - 1) * 0x10 + i;
        const layerControl = (mode - 1) * 0x10 + i;
        // Update both firmware banks. This makes the paired layer work whether
        // it was reached by a repeated mode press or by the controller's legacy
        // SHIFT gesture.
        midi.sendShortMsg(status, baseControl, colors[i]);
        midi.sendShortMsg(status, baseControl + 0x08, colors[i]);
        midi.sendShortMsg(status, layerControl, colors[i]);
        midi.sendShortMsg(status, layerControl + 0x08, colors[i]);
    }
};

DJCi500.rx3SetPadMode = function(deckData, mode) {
    deckData.activePadMode = mode;
    const deck = script.deckFromGroup(deckData.currentDeck);
    DJCi500.slicerActive[deck - 1] = (mode === 3);
    // Publish the logical layer to the skin. Each physical deck owns an
    // independent 1-8 stack, matching the two-layer PAD MODE buttons.
    const padModeGroup = deckData.midiChannel === 1 ?
        "[RX3PadModeDeck1]" : "[RX3PadModeDeck2]";
    engine.setValue(padModeGroup, `mode${mode}`, 1);
    DJCi500.rx3RefreshPadLeds(deckData);
};

// All physical pad messages pass through this dispatcher. The controller
// firmware keeps sending the primary bank after an unshifted repeated mode
// press, so the dispatcher redirects that bank to its paired logical layer.
DJCi500.rx3PadInput = function(_channel, control, value, status, _group) {
    const deckData = ((status & 0x0F) === 0x06) ? DJCi500.deckA : DJCi500.deckB;
    if (!deckData) {
        return;
    }

    const physicalMode = Math.floor(control / 0x10) + 1;
    const pad = (control & 0x07) + 1;
    const shiftedPad = (control & 0x08) !== 0;
    const pairedBase = ((deckData.activePadMode - 1) % 4) + 1;
    if (physicalMode > 4 && deckData.activePadMode !== physicalMode) {
        // A firmware SHIFT bank is inert unless its matching selector was
        // accepted by rx3SetPadMode first.
        return;
    }
    const mode = (physicalMode <= 4 && physicalMode === pairedBase) ?
        deckData.activePadMode : physicalMode;
    const targetControl = (mode - 1) * 0x10 + (pad - 1) + (shiftedPad ? 0x08 : 0);

    switch (mode) {
    case 1:
        deckData.hotcueButtons[pad].input(_channel, targetControl, value, status, deckData.currentDeck);
        break;
    case 2:
        (shiftedPad ? deckData.loopShiftButtons[pad] : deckData.loopButtons[pad])
            .input(_channel, targetControl, value, status, deckData.currentDeck);
        break;
    case 3:
        deckData.slicerButtons[pad].input(_channel, targetControl, value, status, deckData.currentDeck);
        break;
    case 4:
        DJCi500.rx3BeatJumpPadInput(deckData, mode, pad, value, status, control);
        break;
    case 5: {
        const pitchPads = [
            deckData.pitchDownTone,
            deckData.pitchDownSemiTone,
            deckData.pitchUpSemiTone,
            deckData.pitchUpTone,
            deckData.pitchSliderReset,
            deckData.pitchSliderDecrease,
            deckData.pitchSliderIncrease,
        ];
        if (pad === 8) {
            if (value === 0x7F) {
                script.toggleControl(deckData.currentDeck, "keylock");
            }
        } else {
            pitchPads[pad - 1].input(_channel, targetControl, value, status, deckData.currentDeck);
        }
        break;
    }
    case 6:
        deckData.rollButtons[pad].input(_channel, targetControl, value, status, deckData.currentDeck);
        break;
    case 7:
        deckData.effectButtons[pad].input(_channel, targetControl, value, status, deckData.currentDeck);
        break;
    case 8:
        DJCi500.rx3BeatJumpPadInput(deckData, mode, pad, value, status, control);
        break;
    }
};

// The three TEMPO LEDs beside each pitch fader must describe that fader,
// never the BPM difference between decks. The old beatmatch comparison also
// divided by zero for an empty deck, which produced the opposite arrows seen
// in the controller photos.
DJCi500.rx3PitchPositionLEDs = function() {
    if (!DJCi500.deckA || !DJCi500.deckB) {
        return;
    }

    const updateDeck = function(deckData, status) {
        const rate = engine.getValue(deckData.currentDeck, "rate");
        const centered = Math.abs(rate) <= 0.0005;
        const towardMinus = !centered && rate < 0;
        const towardPlus = !centered && rate > 0;

        midi.sendShortMsg(status, 0x1E, towardMinus ? 0x7F : 0x00);
        midi.sendShortMsg(status, 0x1F, towardPlus ? 0x7F : 0x00);
        midi.sendShortMsg(status, 0x2C, centered ? 0x7F : 0x00);

        // Phase guide LEDs are independent of the physical pitch position.
        // Leave them neutral here rather than showing stale tempo guidance.
        midi.sendShortMsg(status, 0x1C, 0x00);
        midi.sendShortMsg(status, 0x1D, 0x00);
        midi.sendShortMsg(status, 0x2D, 0x00);
    };

    updateDeck(DJCi500.deckA, 0x91);
    updateDeck(DJCi500.deckB, 0x92);
};

///////////////////////////////////////////////////////////////
//                          SLICER                           //
///////////////////////////////////////////////////////////////
DJCi500.selectedSlicerDomain = [8, 8, 8, 8]; // Length of the Slicer domain

// Slicer storage:
DJCi500.slicerBeatsPassed = [0, 0, 0, 0];
DJCi500.slicerPreviousBeatsPassed = [0, 0, 0, 0];
DJCi500.slicerTimer = [false, false, false, false];
DJCi500.slicerActive = [false, false, false, false];
DJCi500.slicerAlreadyJumped = [false, false, false, false];
DJCi500.slicerButton = [-1, -1, -1, -1];
DJCi500.slicerModes = {
    "contSlice": 0,
    "loopSlice": 1
};
DJCi500.activeSlicerMode = [
    DJCi500.slicerModes.contSlice,
    DJCi500.slicerModes.contSlice,
    DJCi500.slicerModes.contSlice,
    DJCi500.slicerModes.contSlice
];
DJCi500.slicerLoopBeat8 = [0, 0, 0, 0];
///////////////////////

// Master VU Meter callbacks
DJCi500.vuMeterUpdateMaster = function(value, _group, control) {
    // Reserve the red led for peak indicator, this will in turn, make
    // the display more similar (I hope) to what Mixxx VU shows
    value = script.absoluteLinInverse(value, 0.0, 1.0, 0, 124);
    const ctrl = (control === "vu_meter_left") ? 0x40 : 0x41;
    midi.sendShortMsg(0xB0, ctrl, value);
};

DJCi500.vuMeterPeakLeftMaster = function(value, _group, _control) {
    if (value) {
        midi.sendShortMsg(0x90, 0x0A, 0x7F);
    } else {
        midi.sendShortMsg(0x90, 0x0A, 0x00);
    }
};

DJCi500.vuMeterPeakRightMaster = function(value, _group, _control) {
    if (value) {
        midi.sendShortMsg(0x90, 0x0F, 0x7F);
    } else {
        midi.sendShortMsg(0x90, 0x0F, 0x00);
    }
};

// Deck VU Meter callbacks
DJCi500.vuMeterUpdateDeck = function(value, group) {
    // Reserve the red led for peak indicator, this will in turn, make
    // the display more similar (I hope) to what Mixxx VU shows
    value = script.absoluteLinInverse(value, 0.0, 1.0, 0, 125);
    if (DJCi500.deckA.currentDeck === group) {
        midi.sendShortMsg(0xB1, 0x40, value);
    } else if (DJCi500.deckB.currentDeck === group) {
        midi.sendShortMsg(0xB2, 0x40, value);
    }
};

DJCi500.vuMeterPeakDeck = function(value, group, _control) {
    let channel = 0x00;
    if (DJCi500.deckA.currentDeck === group) {
        channel = 0x91;
    } else if (DJCi500.deckB.currentDeck === group) {
        channel = 0x92;
    }

    if (channel > 0x00) {
        if (value) {
            midi.sendShortMsg(channel, 0x39, 0x7F);
        } else {
            midi.sendShortMsg(channel, 0x39, 0x00);
        }
    }
};

DJCi500.numberIndicator = function(value, group, _control) {
    if (DJCi500.deckA.currentDeck === group) {
        midi.sendShortMsg(0x91, 0x30, value);
    } else if (DJCi500.deckB.currentDeck === group) {
        midi.sendShortMsg(0x92, 0x30, value);
    }
};

DJCi500.fxSelIndicator = function(_value, group, _control, _status) {
    if (group === "[EffectRack1_EffectUnit1]") {
        if (DJCi500.deckA.activePadMode === 7) {
            midi.sendShortMsg(0x96, 0x63, 0x7F);
        }
        if (DJCi500.deckB.activePadMode === 7) {
            midi.sendShortMsg(0x97, 0x63, 0x7F);
        }
    } else if (group === "[EffectRack1_EffectUnit2]") {
        if (DJCi500.deckA.activePadMode === 7) {
            midi.sendShortMsg(0x96, 0x67, 0x7F);
        }
        if (DJCi500.deckB.activePadMode === 7) {
            midi.sendShortMsg(0x97, 0x67, 0x7F);
        }
    }
};

DJCi500.fxEnabledIndicator = function(_value, group, _control, _status) {
    const deckA = DJCi500.deckA.currentDeck;
    const deckB = DJCi500.deckB.currentDeck;
    if (group === `[QuickEffectRack1_${deckA}]` && DJCi500.deckA.activePadMode === 7) {
        midi.sendShortMsg(0x96, 0x66, 0x7F);
    } else if (group === `[QuickEffectRack1_${deckB}]` && DJCi500.deckB.activePadMode === 7) {
        midi.sendShortMsg(0x97, 0x66, 0x7F);
    }
};

DJCi500.Deck = function(deckNumbers, midiChannel) {
    components.Deck.call(this, deckNumbers);
    // Allow components to access deck variables
    const deckData = this;
    this.midiChannel = midiChannel;
    this.activePadMode = 1;
    this.isShiftPressed = false;
    this.loopAdjustMode = null;

    // For loop and looprolls
    const fractions = ["0.125", "0.25", "0.5", "1", "2", "4", "8", "16"];
    const shiftFractions = ["0.03125", "0.0625", "32", "64", "128", "256", "512", "512"];

    // Brake status for this deck
    this.slowPauseSetState = [false, false, false, false];

    // Vinyl button state
    this.vinylButtonState = [DJCi500.initialVinylMode, DJCi500.initialVinylMode, DJCi500.initialVinylMode, DJCi500.initialVinylMode];

    // Pitch ranges and status
    this.pitchRanges = DJCi500.rx3TempoRanges;
    this.pitchRangeId = 0; // id of the array, one for each deck

    // Effect section components
    this.effectEnabled = false;

    // Make sure the shift button remaps the shift actions
    this.shiftButton = new components.Button({
        midi: [0x90 + midiChannel, 0x04],
        input: function(_channel, _control, value, _status, _group) {
            if (value === 0x7F) {
                deckData.isShiftPressed = true;
                deckData.shift();
            } else {
                deckData.isShiftPressed = false;
                deckData.unshift();
            }

        },
    });

    this.loadButton = new components.Button({
        midi: [0x90 + midiChannel, 0x0D],
        shiftOffset: 3,
        shiftControl: false,
        shiftChannel: true,
        sendShifted: true,
        unshift: function() {
            this.inKey = "LoadSelectedTrack";
        },
        shift: function() {
            this.inKey = "eject";
        },
    });

    // Transport section
    // Play button, for some reason the group is not correct on this one?
    this.playButton = new components.PlayButton({
        midi: [0x90 + midiChannel, 0x07],
        shiftOffset: 3,
        shiftControl: false,
        shiftChannel: true,
        sendShifted: true,
        unshift: function() {
            this.input = function(_channel, _control, value, _status, _group) {
                if (value === 0x7F) {
                    if (engine.getValue(deckData.currentDeck, "play_latched")) {
                        const deck = script.deckFromGroup(deckData.currentDeck);
                        if (deckData.slowPauseSetState[deck - 1]) {
                            engine.brake(deck,
                                1,
                                54);
                        } else {
                            script.toggleControl(deckData.currentDeck, "play");
                        }
                    } else {
                        script.toggleControl(deckData.currentDeck, "play");
                    }
                }
            };
        },
        shift: function() {
            this.input = function(_channel, _control, _value, _status, _group) {
                engine.setValue(deckData.currentDeck, "play_stutter", true);
            };
        },
    });

    this.cueButton = new components.CueButton({
        midi: [0x90 + midiChannel, 0x06],
        shiftOffset: 3,
        shiftControl: false,
        shiftChannel: true,
        sendShifted: true,
        shift: function() {
            this.inKey = "start_play";
        },
    });

    this.syncButton = new components.Button({
        midi: [0x90 + midiChannel, 0x05],
        outKey: "sync_enabled",
        input: function(_channel, _control, value, status, _group) {
            DJCi500.rx3SyncButton(deckData, value, status);
        },
    });

    this.pflButton = new components.Button({
        midi: [0x90 + midiChannel, 0x0C],
        type: components.Button.prototype.types.toggle,
        key: "pfl",
    });

    // Top controls
    // Vinyl button
    this.vinylButton = new components.Button({
        midi: [0x90 + midiChannel, 0x03],
        shiftOffset: 3,
        shiftControl: false,
        shiftChannel: true,
        sendShifted: true,
        unshift: function() {
            this.input = function(_channel, _control, value, status, _group) {
                const pressed = value > 0 && (status & 0xF0) !== 0x80;
                if (pressed && !this.rx3Pressed) {
                    DJCi500.rx3ToggleVinyl(deckData, this.midi[0]);
                }
                this.rx3Pressed = pressed;
            };
        },
        shift: function() {
            this.input = function(channel, control, value, _status, _group) {
                if (value === 0x7F) {
                    const deck = script.deckFromGroup(deckData.currentDeck);
                    deckData.slowPauseSetState[deck - 1] = !deckData.slowPauseSetState[deck - 1];

                }
            };
        }
    });

    // SLIP mode button
    this.slipButton = new components.Button({
        midi: [0x90 + midiChannel, 0x01],
        outKey: "slip_enabled",
        input: function(_channel, _control, value, _status, _group) {
            DJCi500.rx3ToggleSlip(deckData, value);
        },
    });

    // Quant button
    this.quantButton =  new components.Button({
        midi: [0x90 + midiChannel, 0x02],
        type: components.Button.prototype.types.toggle,
        shiftOffset: 3,
        shiftControl: false,
        shiftChannel: true,
        sendShifted: true,
        outKey: "quantize",
        unshift: function() {
            this.inKey = "quantize";
        },
        shift: function() {
            this.inKey = "keylock";
        },
    });

    // Knobs
    this.volume = new components.Pot({
        midi: [0xB0 + midiChannel, 0x00],
        inKey: "volume",
    });

    this.eqKnob = [];
    for (let k = 1; k <= 3; k++) {
        this.eqKnob[k] = new components.Pot({
            midi: [0xB0 + midiChannel, 0x01 + k],
            group: `[EqualizerRack1_${this.currentDeck}_Effect1]`,
            inKey: `parameter${k}`,
        });
    }

    this.gainKnob = new components.Pot({
        midi: [0xB0 + midiChannel, 0x05],
        key: "pregain",
    });

    // Pitch-tempo fader
    this.pitchFader = new components.Pot({
        midi: [0xB0 + midiChannel, 0x08],
        key: "rate",
    });

    // Jog Wheel
    // TODO: Handle with less repeat the shift key for this
    this.jogWheel = new components.JogWheelBasic({
        midi: [0xB0 + midiChannel, 0x0A],
        deck: midiChannel, // Whatever deck this jogwheel controls, in this case we ignore it
        wheelResolution: 720, // How many ticks per revolution the jogwheel has
        alpha: 5/6,
        beta: (5/6)/128,
        rpm: 33 + 1/3,
        group: `[Channel${midiChannel}]`,
        inputWheel: function(_channel, _control, value, _status, _group) {
            const deck = script.deckFromGroup(deckData.currentDeck);
            value = this.inValueScale(value);
            if (DJCi500.rx3AdjustBeatGrid(deckData, value)) return;
            if (DJCi500.rx3AdjustLoopPoint(deckData, value, this.wheelResolution)) {
                return;
            }
            if (engine.isScratching(deck) && deckData.vinylButtonState[deck - 1]) {
                engine.scratchTick(deck, value);
            } else {
                if (engine.isScratching(deck)) engine.scratchDisable(deck, false);
                engine.setValue(`[Channel${deck}]`, "jog", value);
            }
        },
        inputTouch: function(_channel, _control, value, _status, _group) {
            const deck = script.deckFromGroup(deckData.currentDeck);
            if (DJCi500.rx3GridActive() || deckData.loopAdjustMode !== null) {
                if (engine.isScratching(deck)) {
                    engine.scratchDisable(deck);
                }
                return;
            }
            if (!deckData.vinylButtonState[deck - 1]) {
                engine.scratchDisable(deck, false);
                return;
            }
            if (value > 0 && (_status & 0xF0) !== 0x80) {
                engine.scratchEnable(deck,
                    this.wheelResolution,
                    this.rpm,
                    this.alpha,
                    this.beta);
            } else {
                engine.scratchDisable(deck);
            }
        },
    });

    this.jogWheelShift = new components.JogWheelBasic({
        midi: [0xB3 + midiChannel, 0x0A],
        deck: midiChannel, // whatever deck this jogwheel controls, in this case we ignore it
        wheelResolution: 720, // how many ticks per revolution the jogwheel has
        alpha: 5/6,
        beta: (5/6)/128,
        rpm: 33 + 1/3,
        group: `[Channel${midiChannel}]`,
        inputWheel: function(_channel, _control, value, _status, _group) {
            const tickDelta = this.inValueScale(value);
            if (DJCi500.rx3AdjustBeatGrid(deckData, tickDelta)) return;
            DJCi500.rx3FastSeek(deckData.currentDeck, tickDelta, this.wheelResolution);
        },
        inputTouch: function(_channel, _control, _value, _status, _group) {
            const deck = script.deckFromGroup(deckData.currentDeck);
            // SHIFT reserves the jog for fast search, even when Vinyl mode is
            // enabled. Clear any scratch state left by the unshifted surface.
            if (engine.isScratching(deck)) {
                engine.scratchDisable(deck);
            }
        },
    });

    // Loop controls
    this.loopInButton = new components.Button({
        midi: [0x90 + midiChannel, 0x09],
        shiftOffset: 3,
        shiftControl: false,
        shiftChannel: true,
        sendShifted: true,
        outKey: "loop_enabled",    // TODO: Check with loop_in?
        input: function(_channel, _control, value, status, _group) {
            DJCi500.rx3LoopButton(deckData, "in", value, status);
        },
    });

    // The controller firmware emits a dedicated note (0x0B) after LOOP IN is
    // held, so this does not delay or interfere with the normal short press.
    this.loopInLongPressButton = new components.Button({
        midi: [0x90 + midiChannel, 0x0B],
        input: function(_channel, _control, value, _status, _group) {
            DJCi500.rx3LoopInLongPress(deckData, value);
        },
    });

    this.loopOutButton = new components.Button({
        midi: [0x90 + midiChannel, 0x0A],
        shiftOffset: 3,
        shiftControl: false,
        shiftChannel: true,
        sendShifted: true,
        outKey: "loop_enabled",    // TODO: Check with loop_in?
        input: function(_channel, _control, value, status, _group) {
            DJCi500.rx3LoopButton(deckData, "out", value, status);
        },
    });

    // Loop rotary encoder functions
    //
    // Push the rotary encoder
    this.loopEncoderPush = new components.Button({
        midi: [0x90 + midiChannel, 0x2C],
        shiftOffset: 3,
        shiftControl: false,
        shiftChannel: true,
        sendShifted: true,
        input: function(_channel, _control, value, status, _group) {
            DJCi500.rx3AutoLoopPush(deckData.currentDeck, value, status);
        },
    });

    // Loop encoder
    this.loopEncoder = new components.Encoder({
        midi: [0xB0 + midiChannel, 0x0E],
        shiftOffset: 3,
        shiftControl: false,
        shiftChannel: true,
        sendShifted: true,
        input: function(_channel, _control, value, _status, _group) {
            DJCi500.rx3AutoLoopTurn(deckData.currentDeck, value);
        }
    });

    // We only check and attach for slicer mode, but we have all
    // pad buttons here if we need something extra!
    this.padSelectButtons = [];
    for (let i = 1; i <= 8; i++) {
        this.padSelectButtons[i] = new components.Button({
            midi: [0x90 + midiChannel, 0x0F + (i - 1)],
            input: function(_channel, control, value, _status, _group) {
                if (value !== 0x7F) {
                    return;
                }
                const selector = control - 0x0F;
                const baseMode = (selector % 4) + 1;
                let nextMode = baseMode;

                if (selector < 4) {
                    // Repeating the active primary button opens its paired
                    // secondary layer: 1↔5, 2↔6, 3↔7, 4↔8.
                    if (deckData.activePadMode === baseMode) {
                        nextMode = baseMode + 4;
                    }
                } else {
                    // Preserve the firmware SHIFT selectors, but only allow a
                    // secondary layer from its corresponding primary layer.
                    if (deckData.activePadMode !== baseMode) {
                        DJCi500.rx3RefreshPadLeds(deckData);
                        return;
                    }
                    nextMode = baseMode + 4;
                }
                DJCi500.rx3SetPadMode(deckData, nextMode);
            },
        });
    }

    // Hotcue buttons (PAD Mode 1)
    this.hotcueButtons = [];
    for (let i = 1; i <= 8; i++) {
        this.hotcueButtons[i] = new components.HotcueButton({
            midi: [0x95 + midiChannel, 0x00 + (i - 1)],
            number: i,
            shiftOffset: 8,
            shiftControl: true,
            sendShifted: true,
            // Match the skin's fixed A-H marker palette. The Hercules pads
            // cannot reproduce arbitrary RGB values, so these use the exact
            // bright hardware colors from its official MIDI table.
            on: DJCi500.rx3PadPalettes[1][i - 1],
            off: 0x7F,
            output: function(value, group, control) {
                // Do not let a background hot-cue update repaint logical
                // mode 5, which shares the same physical pad bank.
                if (deckData.activePadMode === 1) {
                    components.HotcueButton.prototype.output.call(this, value, group, control);
                }
            },
        });
    };

    // Loop buttons (PAD Mode 2)
    this.loopButtons = [];
    for (let i = 1; i <= 8; i++) {
        this.loopButtons[i] = new components.Button({
            midi: [0x95 + midiChannel, 0x10 + (i - 1)],
            number: i,
            shiftControl: false,
            sendShifted: false,
            on: 0x74,
            off: 0x74,
            outKey: `beatloop_${fractions[i - 1]}_enabled`,
            inKey: `beatloop_${fractions[i - 1]}_toggle`,
        });
    };

    // A bit repeated code, but I want the leds to react accordingly
    this.loopShiftButtons = [];
    for (let i = 1; i <= 8; i++) {
        this.loopShiftButtons[i] = new components.Button({
            midi: [0x95 + midiChannel, 0x10 + (i - 1) + 8],
            number: i,
            shiftControl: false,
            sendShifted: false,
            on: 0x74,
            off: 0x74,
            outKey: `beatloop_${shiftFractions[i - 1]}_enabled`,
            inKey: `beatloop_${shiftFractions[i - 1]}_toggle`,
        });
    };

    // Slicer buttons (PAD Mode 3)
    this.slicerButtons = [];
    for (let i = 1; i <= 8; i++) {
        this.slicerButtons[i] = new components.Button({
            midi: [0x95 + midiChannel, 0x20 + (i - 1)],
            number: i,
            shiftOffset: 8,
            shiftControl: true,
            sendShifted: true,
            input: function(channel, control, value, status, _group) {
                // This is kind of a hack... somehow this is not getting the group correctly!
                DJCi500.slicerButtonFunc(channel, control, value, status, deckData.currentDeck);
            },
        });
    };

    // Pitch buttons (PAD Mode 5)
    this.pitchDownTone = new components.Button({
        midi: [0x95 + midiChannel, 0x40],
        on: 0x7F,
        off: 0x7F,
        input: function(channel, control, value, status, _group) {
            if (value === 0x7F) {
                engine.setValue(deckData.currentDeck, "pitch_down", 1);
                engine.setValue(deckData.currentDeck, "pitch_down", 1);
                midi.sendShortMsg(status, control, this.on);
            } else {
                midi.sendShortMsg(status, control, this.off);
            }
        },
    });

    this.pitchDownSemiTone = new components.Button({
        midi: [0x95 + midiChannel, 0x41],
        on: 0x7F,
        off: 0x7F,
        input: function(channel, control, value, status, _group) {
            if (value === 0x7F) {
                engine.setValue(deckData.currentDeck, "pitch_down", 1);
                midi.sendShortMsg(status, control, this.on);
            } else {
                midi.sendShortMsg(status, control, this.off);
            }
        },
    });

    this.pitchUpSemiTone = new components.Button({
        midi: [0x95 + midiChannel, 0x42],
        on: 0x7F,
        off: 0x7F,
        input: function(channel, control, value, status, _group) {
            if (value === 0x7F) {
                engine.setValue(deckData.currentDeck, "pitch_up", 1);
                midi.sendShortMsg(status, control, this.on);
            } else {
                midi.sendShortMsg(status, control, this.off);
            }
        },
    });

    this.pitchUpTone = new components.Button({
        midi: [0x95 + midiChannel, 0x43],
        on: 0x7F,
        off: 0x7F,
        input: function(channel, control, value, status, _group) {
            if (value === 0x7F) {
                engine.setValue(deckData.currentDeck, "pitch_up", 1);
                engine.setValue(deckData.currentDeck, "pitch_up", 1);
                midi.sendShortMsg(status, control, this.on);
            } else {
                midi.sendShortMsg(status, control, this.off);
            }
        },
    });

    this.pitchSliderIncrease = new components.Button({
        midi: [0x95 + midiChannel, 0x46],
        on: 0x7F,
        off: 0x7F,
        input: function(channel, control, value, status, _group) {
            if (value === 0x7F) {
                deckData.pitchRangeId++;
                if (deckData.pitchRangeId > 6) {
                    deckData.pitchRangeId = 6;
                }
                engine.setValue(deckData.currentDeck, "rateRange", deckData.pitchRanges[deckData.pitchRangeId]);
                midi.sendShortMsg(status, control, this.on); //17 -- 3B
            } else {
                midi.sendShortMsg(status, control, this.off); //3B -- 33
            }
        },
    });

    this.pitchSliderDecrease = new components.Button({
        midi: [0x95 + midiChannel, 0x45],
        on: 0x7F,
        off: 0x7F,
        input: function(channel, control, value, status, _group) {
            if (value === 0x7F) {
                deckData.pitchRangeId = deckData.pitchRangeId - 1;
                if (deckData.pitchRangeId < 0) {
                    deckData.pitchRangeId = 0;
                }
                engine.setValue(deckData.currentDeck, "rateRange", deckData.pitchRanges[deckData.pitchRangeId]);
                midi.sendShortMsg(status, control, this.on); //17 -- 3B
            } else {
                midi.sendShortMsg(status, control, this.off); //3B -- 33
            }
        },
    });

    this.pitchSliderReset = new components.Button({
        midi: [0x95 + midiChannel, 0x44],
        on: 0x7F,
        off: 0x7F,
        input: function(channel, control, value, status, _group) {
            if (value === 0x7F) {
                deckData.pitchRangeId = 0;
                engine.setValue(deckData.currentDeck, "rateRange", deckData.pitchRanges[deckData.pitchRangeId]);
                midi.sendShortMsg(status, control, this.on); //17 -- 3B
            } else {
                midi.sendShortMsg(status, control, this.off); //3B -- 33
            }
        },
    });

    // Beatloop rolls buttons (PAD Mode 6)
    this.rollButtons = [];
    for (let i = 1; i <= 8; i++) {
        this.rollButtons[i] = new components.Button({
            midi: [0x95 + midiChannel, 0x50 + (i - 1)],
            number: i,
            shiftOffset: 8,
            shiftControl: true,
            sendShifted: true,
            on: 0x74,
            off: 0x74,
            key: `beatlooproll_${fractions[i - 1]}_activate`,
        });
    };

    // Effect buttons (PAD Mode 7)
    this.effectButtons = [];
    for (let i = 1; i <= 3; i++) {
        // First top row effects buttons, just the effect, disable HPF/LPF knob
        this.effectButtons[i] = new components.Button({
            midi: [0x95 + midiChannel, 0x60 + (i - 1)],
            number: i,
            shiftOffset: 8,
            shiftControl: true,
            sendShifted: true,
            group: `[EffectRack1_EffectUnit${midiChannel}_Effect${i}]`,
            outKey: "enabled",
            output: function(_value, _group, _control) {
                this.send(0x7F);
            },
            unshift: function() {
                // Normal effect button operation, toggling the effect assigned to it
                this.input = function(channel, control, value, _status, _group) {
                    if (value === 0x7F) {
                        script.toggleControl(this.group, "enabled");
                    }
                };
            },
            shift: function() {
                // Shift button will change the effect to the next in the list
                this.input = function(channel, control, value, _status, _group) {
                    if (value === 0x7F) {
                        engine.setValue(this.group, "effect_selector", +1);
                    }
                };
            }
        });
    };

    // Effect chain selectors
    this.effectButtons[5] = new components.Button({
        midi: [0x95 + midiChannel, 0x64],
        number: 5,
        shiftOffset: 8,
        shiftControl: true,
        sendShifted: true,
        group: `[QuickEffectRack1_[Channel${midiChannel}]]`,
        on: 0x7F,
        off: 0x7F,
        input: function(channel, control, value, status, _group) {
            if (value === 0x7F) {
                engine.setValue(this.group, "chain_preset_selector", -1);
                midi.sendShortMsg(status, control, this.on); //17 -- 3B
            } else {
                midi.sendShortMsg(status, control, this.off); //3B -- 33
            }
        }
    });

    this.effectButtons[6] = new components.Button({
        midi: [0x95 + midiChannel, 0x65],
        number: 6,
        shiftOffset: 8,
        shiftControl: true,
        sendShifted: true,
        group: `[QuickEffectRack1_[Channel${midiChannel}]]`,
        on: 0x7F,
        off: 0x7F,
        input: function(channel, control, value, status, _group) {
            if (value === 0x7F) {
                engine.setValue(this.group, "chain_preset_selector", 1);
                midi.sendShortMsg(status, control, this.on); //17 -- 3B
            } else {
                midi.sendShortMsg(status, control, this.off); //3B -- 33
            }
        }
    });

    // Filter kill switch
    this.effectButtons[7] = new components.Button({
        midi: [0x95 + midiChannel, 0x66],
        number: 4,
        shiftOffset: 8,
        shiftControl: true,
        sendShifted: true,
        group: `[QuickEffectRack1_[Channel${midiChannel}]]`,
        input: function(_channel, _control, value, _status, _group) {
            if (value === 0x7F) {
                script.toggleControl(this.group, "enabled");
            }
        }
    });

    // Set the current channel FX route with the two extra PADs
    this.effectButtons[4] = new components.Button({
        midi: [0x95 + midiChannel, 0x63],
        number: 4,
        shiftOffset: 8,
        shiftControl: true,
        sendShifted: true,
        group: "[EffectRack1_EffectUnit1]",
        input: function(channel, _control, value, _status, _group) {
            if (value === 0x7F) {
                const deckGroup = deckData.currentDeck;
                script.toggleControl(this.group, `group_${deckGroup}_enable`);
            }
        }
    });

    this.effectButtons[8] = new components.Button({
        midi: [0x95 + midiChannel, 0x67],
        number: 8,
        shiftOffset: 8,
        shiftControl: true,
        sendShifted: false,
        group: "[EffectRack1_EffectUnit2]",
        input: function(_channel, _control, value, _status, _group) {
            if (value === 0x7F) {
                const deckGroup = deckData.currentDeck;
                script.toggleControl(this.group, `group_${deckGroup}_enable`);
            }
        }
    });

    // Filter knob is here since it is affected by effects pads
    this.filterKnob = new components.Pot({
        midi: [0xB0 + midiChannel, 0x01],
        number: midiChannel,
        group: `[QuickEffectRack1_[Channel${midiChannel}]]`,
        input: function(channel, control, value, _status, _group) {
            const normalized = script.absoluteNonLin(value, 0.0, 0.5, 1.0, 0, 127);
            if (DJCi500.rx3SoundColorFxKnob(midiChannel, normalized)) {
                // Sound Color FX always owns the COLOR knob while selected.
                return;
            } else if (DJCi500.updateEffectStatus(midiChannel, deckData.currentDeck)) {
                // Move the effects knobs
                engine.setValue(`[EffectRack1_EffectUnit${this.number}]`, "super1", Math.abs(normalized - 0.5)*2);
            } else {
                // Preserve PAD MODE 7's independently enabled QuickEffect behavior.
                const quickEffectGroup = `[QuickEffectRack1_${deckData.currentDeck}]`;
                if (engine.getValue(quickEffectGroup, "enabled")) {
                    engine.setValue(quickEffectGroup, "super1", normalized);
                }
            }
        },
    });

    // As per Mixxx wiki, set the group properties
    this.reconnectComponents(function(c) {
        if (c.group === undefined) {
            c.group = this.currentDeck;
        }
    });
};

// Give the custom Deck all the methods of the generic deck
DJCi500.Deck.prototype = Object.create(components.Deck.prototype);
DJCi500.Deck.prototype.constructor = DJCi500.Deck;

// INIT for the controller and decks
DJCi500.init = function() {
    DJCi500.rx3SetGridMode(false);
    // Take care of the status of the crossfader status
    DJCi500.crossfaderEnabled = true;
    DJCi500.xFaderScratch = false;

    // Connect the VUMeters
    engine.makeConnection("[Channel1]", "vu_meter", DJCi500.vuMeterUpdateDeck);
    engine.getValue("[Channel1]", "vu_meter");
    engine.makeConnection("[Channel2]", "vu_meter", DJCi500.vuMeterUpdateDeck);
    engine.getValue("[Channel2]", "vu_meter");
    engine.makeConnection("[Channel3]", "vu_meter", DJCi500.vuMeterUpdateDeck);
    engine.getValue("[Channel3]", "vu_meter");
    engine.makeConnection("[Channel4]", "vu_meter", DJCi500.vuMeterUpdateDeck);
    engine.getValue("[Channel4]", "vu_meter");

    // Deck VU meters peak indicators
    engine.makeConnection("[Channel1]", "peak_indicator", DJCi500.vuMeterPeakDeck);
    engine.makeConnection("[Channel2]", "peak_indicator", DJCi500.vuMeterPeakDeck);
    engine.makeConnection("[Channel3]", "peak_indicator", DJCi500.vuMeterPeakDeck);
    engine.makeConnection("[Channel4]", "peak_indicator", DJCi500.vuMeterPeakDeck);

    // Connect number leds
    engine.makeConnection("[Channel1]", "play_indicator", DJCi500.numberIndicator);
    engine.getValue("[Channel1]", "play_indicator");
    engine.makeConnection("[Channel2]", "play_indicator", DJCi500.numberIndicator);
    engine.getValue("[Channel2]", "play_indicator");
    engine.makeConnection("[Channel3]", "play_indicator", DJCi500.numberIndicator);
    engine.getValue("[Channel3]", "play_indicator");
    engine.makeConnection("[Channel4]", "play_indicator", DJCi500.numberIndicator);
    engine.getValue("[Channel4]", "play_indicator");

    // Connect Master VU meter
    engine.makeConnection("[Main]", "vu_meter_left", DJCi500.vuMeterUpdateMaster);
    engine.makeConnection("[Main]", "vu_meter_right", DJCi500.vuMeterUpdateMaster);
    engine.makeConnection("[Main]", "peak_indicator_left", DJCi500.vuMeterPeakLeftMaster);
    engine.makeConnection("[Main]", "peak_indicator_right", DJCi500.vuMeterPeakRightMaster);

    engine.getValue("[Main]", "vu_meter_left");
    engine.getValue("[Main]", "vu_meter_right");

    // Connect the FX selection leds
    engine.makeConnection("[EffectRack1_EffectUnit1]", "group_[Channel1]_enable", DJCi500.fxSelIndicator);
    engine.makeConnection("[EffectRack1_EffectUnit2]", "group_[Channel1]_enable", DJCi500.fxSelIndicator);
    engine.makeConnection("[EffectRack1_EffectUnit1]", "group_[Channel2]_enable", DJCi500.fxSelIndicator);
    engine.makeConnection("[EffectRack1_EffectUnit2]", "group_[Channel2]_enable", DJCi500.fxSelIndicator);
    engine.makeConnection("[EffectRack1_EffectUnit1]", "group_[Channel3]_enable", DJCi500.fxSelIndicator);
    engine.makeConnection("[EffectRack1_EffectUnit2]", "group_[Channel3]_enable", DJCi500.fxSelIndicator);
    engine.makeConnection("[EffectRack1_EffectUnit1]", "group_[Channel4]_enable", DJCi500.fxSelIndicator);
    engine.makeConnection("[EffectRack1_EffectUnit2]", "group_[Channel4]_enable", DJCi500.fxSelIndicator);

    engine.makeConnection("[QuickEffectRack1_[Channel1]]", "enabled", DJCi500.fxEnabledIndicator);
    engine.makeConnection("[QuickEffectRack1_[Channel2]]", "enabled", DJCi500.fxEnabledIndicator);
    engine.makeConnection("[QuickEffectRack1_[Channel3]]", "enabled", DJCi500.fxEnabledIndicator);
    engine.makeConnection("[QuickEffectRack1_[Channel4]]", "enabled", DJCi500.fxEnabledIndicator);

    // Connect the slicer beats
    DJCi500.slicerBeat1 = engine.makeConnection("[Channel1]", "beat_active", DJCi500.slicerBeatActive);
    DJCi500.slicerBeat2 = engine.makeConnection("[Channel2]", "beat_active", DJCi500.slicerBeatActive);
    //var controlsToFunctions = {'beat_active': 'DJCi500.slicerBeatActive'};
    //script.bindConnections('[Channel1]', controlsToFunctions, true);

    // Ask the controller to send all current knob/slider values over MIDI, which will update
    // the corresponding GUI controls in MIXXX.
    midi.sendShortMsg(0xB0, 0x7F, 0x7F);

    // Turn on lights:
    for (let i = 0; i < 2; i++) {
        // PAD 5 key and tempo range controls are white.
        for (let pad = 0; pad < 8; pad++) {
            midi.sendShortMsg(0x96+i, 0x40+pad, 0x7F);
        }

        // PAD 7 is all white; PAD 8 follows the requested RX3 jump palette.
        for (let pad = 0; pad < 8; pad++) {
            midi.sendShortMsg(0x96+i, 0x60+pad, 0x7F);
            midi.sendShortMsg(0x96+i, 0x70+pad, DJCi500.rx3PadPalettes[8][pad]);
            midi.sendShortMsg(0x96+i, 0x78+pad, DJCi500.rx3PadPalettes[8][pad]);
        }
    }

    DJCi500.tempoTimer = engine.beginTimer(250, DJCi500.rx3PitchPositionLEDs);

    // Create the deck objects
    DJCi500.deckA = new DJCi500.Deck([1, 3], 1);
    DJCi500.deckB = new DJCi500.Deck([2, 4], 2);
    DJCi500.deckA.setCurrentDeck("[Channel1]");
    DJCi500.deckB.setCurrentDeck("[Channel2]");

    // Start with Sound Color FX off. A selected button blinks, matching the
    // XDJ-RX3, and always targets the visible Deck 1 / Deck 2 pair.
    DJCi500.rx3SoundColorFxSelected = 0;
    DJCi500.rx3SoundColorFxBlinkOn = false;
    DJCi500.rx3SetSoundColorFxEnabled(false);
    DJCi500.rx3PaintSoundColorFx();
    DJCi500.rx3SoundColorFxTimer = engine.beginTimer(
        400, DJCi500.rx3BlinkSoundColorFx);

    DJCi500.rx3SidePanelConnection = engine.makeConnection(
        "[RX3SidePanel]", "current", DJCi500.rx3SidePanelChanged);
    DJCi500.rx3SidePanelConnection.trigger();
    engine.setValue("[RX3SidePanel]", "status", 1);
    DJCi500.rx3SetPadMode(DJCi500.deckA, 1);
    DJCi500.rx3SetPadMode(DJCi500.deckB, 1);
    // PortMidi is still opening during the first synchronous LED messages.
    // Repaint every RX3 state after it is ready so no lamp depends on that race.
    engine.beginTimer(500, function() {
        midi.sendShortMsg(0x91, 0x03, DJCi500.initialVinylMode ? 0x7F : 0x00);
        midi.sendShortMsg(0x92, 0x03, DJCi500.initialVinylMode ? 0x7F : 0x00);
        midi.sendShortMsg(0x90, 0x05, 0x10);
        DJCi500.rx3PaintSoundColorFx();
        DJCi500.deckA.syncButton.trigger();
        DJCi500.deckB.syncButton.trigger();
        DJCi500.deckA.slipButton.trigger();
        DJCi500.deckB.slipButton.trigger();
        DJCi500.rx3RefreshPadLeds(DJCi500.deckA);
        DJCi500.rx3RefreshPadLeds(DJCi500.deckB);
    }, true);

    // Update the fx rack selection
    DJCi500.fxSelIndicator(0, "[EffectRack1_EffectUnit1]", 0, 0);
    DJCi500.fxSelIndicator(0, "[EffectRack1_EffectUnit2]", 0, 0);

    DJCi500.fxEnabledIndicator(0, "[QuickEffectRack1_[Channel1]]", 0, 0);
    DJCi500.fxEnabledIndicator(0, "[QuickEffectRack1_[Channel2]]", 0, 0);
};

// Crossfader control, set the curve
DJCi500.crossfaderSetCurve = function(channel, control, value, _status, _group) {
    switch (value) {
    case 0x00:
        // Mix
        script.crossfaderCurve(0, 0, 127);
        DJCi500.xFaderScratch = false;
        break;
    case 0x7F:
        // Scratch
        script.crossfaderCurve(127, 0, 127);
        DJCi500.xFaderScratch = true;
        break;
    }
};

// Crossfader enable or disable
DJCi500.crossfaderEnable = function(channel, control, value, _status, _group) {
    if (value) {
        DJCi500.crossfaderEnabled = true;
    } else {
        DJCi500.crossfaderEnabled = false;
        engine.setValue("[Master]", "crossfader", 0);    // Set the crossfader in the middle
    }
};

// Crossfader function
DJCi500.crossfader = function(channel, control, value, status, group) {
    if (DJCi500.crossfaderEnabled) {
        // Eventine's crossfader scratch mode
        if (DJCi500.xFaderScratch) {
            let result = 0;
            if (value <= 0) {
                result = -1;
            } else if (value >= 127) {
                result = 1;
            } else {
                result = Math.tan((value-64)*Math.PI/2/63)/32;
            }
            engine.setValue(group, "crossfader", result);
        } else {
            engine.setParameter(group, "crossfader", script.absoluteLin(value, 0, 1, 0, 127));
        }
    }
};

// Open this skin's BROWSE tab and resume its existing navigation context. The skin's
// WidgetStack uses page 1 for the library (0 = performance, 2 = sampler).
DJCi500.rx3OpenBrowse = function() {
    const browseWasClosed = Math.round(engine.getValue("[Tab]", "current")) !== 1;
    if (browseWasClosed) {
        // Every entry into BROWSE starts with the search field collapsed. It
        // can only take focus after the user explicitly clicks the skin's
        // magnifier button.
        engine.setValue("[XDJ_RX3]", "search_active", 0);
        // Momentary library controls must be low before focus moves to the
        // folder tree. A stale GoToItem=1 otherwise replays the encoder press
        // as soon as BROWSE becomes visible and closes/opens the current node.
        engine.setValue("[Library]", "GoToItem", 0);
        engine.setValue("[Library]", "MoveLeft", 0);
        engine.setValue("[Library]", "MoveRight", 0);
        // Force a rising edge even if the BROWSE tab was selected previously.
        engine.setValue("[Tab]", "library", 0);
        engine.setValue("[Tab]", "library", 1);
        engine.setValue("[Skin]", "show_maximized_library", 1);
        if (engine.getValue("[RX3Browser]", "enabled")) {
            engine.setValue("[RX3Browser]", "open", 1);
        } else {
            engine.setValue("[Library]", "focused_widget", 3);
        }
    } else if (!engine.getValue("[RX3Browser]", "enabled")) {
        const focusedWidget = Math.round(engine.getValue("[Library]", "focused_widget"));
        if (focusedWidget !== 2 && focusedWidget !== 3 && focusedWidget !== 4) {
            engine.setValue("[Library]", "focused_widget", 2);
        }
    }
    return browseWasClosed;
};

// Rotary selector press: open BROWSE first, then toggle navigation focus.
// Folder tree -> selected folder / track list -> folder tree. The action is
// performed on release so press+turn can still page-jump.
DJCi500.rx3BrowserPush = function(_channel, _control, value, _status, _group) {
    if (value > 0 && (_status & 0xF0) !== 0x80) {
        if (DJCi500.rx3BrowserPressed || Date.now() < DJCi500.rx3BrowserIgnoreUntil) {
            return;
        }
        DJCi500.rx3BrowserPressed = true;
        DJCi500.rx3BrowserMovedWhilePressed = false;
        DJCi500.rx3BrowserHoldConsumed = false;
        DJCi500.rx3BrowserPressedAt = Date.now();
        DJCi500.rx3BrowserHoldTimer = engine.beginTimer(2000, DJCi500.rx3BrowserLongPress, true);
        return;
    }

    if (!DJCi500.rx3BrowserPressed) {
        return;
    }
    DJCi500.rx3CancelBrowserTimer();
    if (Date.now() - DJCi500.rx3BrowserPressedAt >= 2000) DJCi500.rx3BrowserLongPress();
    DJCi500.rx3BrowserPressed = false;
    DJCi500.rx3BrowserIgnoreUntil = Date.now() + 350;

    if (DJCi500.rx3BrowserHoldConsumed || DJCi500.rx3BrowserMovedWhilePressed) {
        DJCi500.rx3BrowserHoldConsumed = false;
        DJCi500.rx3BrowserMovedWhilePressed = false;
        return;
    }

    if (DJCi500.rx3GridActive()) {
        DJCi500.rx3SetGridMode(false);
        return;
    }
    if (DJCi500.rx3OpenBrowse()) return;
    if (engine.getValue("[RX3Browser]", "enabled")) {
        DJCi500.rx3PulseBrowserControl("enter", 1);
        return;
    }

    const focusedWidget = Math.round(engine.getValue("[Library]", "focused_widget"));
    if (focusedWidget === 2) {
        script.triggerControl("[Library]", "GoToItem");
    } else if (focusedWidget === 3) {
        engine.setValue("[Library]", "focused_widget", 2);
    } else if (focusedWidget === 4) {
        engine.setValue("[Library]", "show_track_menu", 0);
        engine.setValue("[Library]", "focused_widget", 2);
    } else {
        engine.setValue("[Library]", "focused_widget", 2);
    }
};

// SHIFT + rotary selector press acts as the RX3 BACK button.
DJCi500.rx3BrowserBack = function(_channel, _control, value, _status, _group) {
    if (value === 0 || (_status & 0xF0) === 0x80) {
        return;
    }
    DJCi500.rx3CancelBrowserTimer();
    DJCi500.rx3BrowserPressed = false;
    DJCi500.rx3SetGridMode(false);
    DJCi500.rx3OpenBrowse();
    if (engine.getValue("[RX3Browser]", "enabled")) {
        DJCi500.rx3PulseBrowserControl("back", 1);
        return;
    }
    const focusedWidget = Math.round(engine.getValue("[Library]", "focused_widget"));
    if (focusedWidget === 4) {
        engine.setValue("[Library]", "show_track_menu", 0);
        engine.setValue("[Library]", "focused_widget", 3);
    } else if (focusedWidget === 3) {
        engine.setValue("[Library]", "focused_widget", 2);
    } else {
        script.triggerControl("[Library]", "MoveLeft");
    }
};

// Return from the dedicated BROWSE page to the RX3 performance/waveform page.
DJCi500.rx3ShowPerformance = function() {
    engine.setValue("[XDJ_RX3]", "search_active", 0);
    engine.setValue("[Skin]", "show_maximized_library", 0);
    // Force a rising edge so this also works after PERFORMANCE was selected
    // previously and its custom skin control is still at 1.
    engine.setValue("[Tab]", "overview", 0);
    engine.setValue("[Tab]", "overview", 1);
    DJCi500.rx3BrowserPressed = false;
    DJCi500.rx3BrowserMovedWhilePressed = false;
    DJCi500.rx3BrowserHoldConsumed = false;
    DJCi500.rx3CancelBrowserTimer();
    DJCi500.rx3BrowserIgnoreUntil = 0;
};

// LOAD 1 / LOAD 2 retain the stock target-deck behavior, including deck-layer
// selection (1/3 on the left, 2/4 on the right). Rx3DisplayState changes to
// PERFORMANCE only after track_loaded confirms that the load succeeded.
DJCi500.rx3LoadTrack = function(_channel, _control, value, status, group) {
    let targetDeck = group;
    if (status === 0x91 && DJCi500.deckA) {
        targetDeck = DJCi500.deckA.currentDeck;
    } else if (status === 0x92 && DJCi500.deckB) {
        targetDeck = DJCi500.deckB.currentDeck;
    }

    engine.setValue(targetDeck, "LoadSelectedTrack", value > 0 ? 1 : 0);
};

// Context-sensitive browser encoder:
// - PERFORMANCE: zoom both visible deck waveforms without opening BROWSE.
// - BROWSE: preserve the RX3-style library navigation behavior.
// Pressing the encoder remains the only way a normal turn can enter BROWSE.
DJCi500.moveLibrary = function(channel, control, value, _status, _group) {
    const movingUp = value > 0x3F;
    const browseIsOpen = Math.round(engine.getValue("[Tab]", "current")) === 1;

    if (DJCi500.rx3BrowserPressed) {
        DJCi500.rx3BrowserMovedWhilePressed = true;
        DJCi500.rx3CancelBrowserTimer();
    }
    if (DJCi500.rx3GridActive()) return;

    if (!browseIsOpen) {
        // The encoder sends values below 0x40 clockwise and above 0x3f
        // counter-clockwise. Use the requested inverted zoom direction while
        // keeping both waveforms at the same level, like the shared RX3 display.
        const zoomControl = movingUp ? "waveform_zoom_up" : "waveform_zoom_down";
        script.triggerControl("[Channel1]", zoomControl);
        script.triggerControl("[Channel2]", zoomControl);
        return;
    }

    if (engine.getValue("[RX3Browser]", "enabled")) {
        DJCi500.rx3PulseBrowserControl(
            "move", (movingUp ? -1 : 1) * (DJCi500.rx3BrowserPressed ? 12 : 1));
        return;
    }

    if (DJCi500.rx3BrowserPressed) {
        DJCi500.rx3BrowserMovedWhilePressed = true;
        engine.setValue("[Library]", movingUp ? "ScrollUp" : "ScrollDown", 1);
        return;
    }

    if (value > 0x3F) {
        if (DJCi500.browserOffFocusMode) {
            engine.setValue("[Playlist]", "SelectTrackKnob", -1);
        } else {
            engine.setValue("[Library]", "MoveUp", 1);
        }
    } else {
        if (DJCi500.browserOffFocusMode) {
            engine.setValue("[Playlist]", "SelectTrackKnob", 1);
        } else {
            engine.setValue("[Library]", "MoveDown", 1);
        }
    }
};

DJCi500.spinbackButton = function(channel, control, value, status, group) {
    const deck = script.deckFromGroup(group);
    engine.spinback(deck, value > 0, 2.5); // use default starting rate of -10 but decrease speed more quickly
};

// Update the Tempo and phase sync leds
DJCi500.tempoLEDs = function() {
    // Current active decks
    const deckA = DJCi500.deckA.currentDeck;
    const deckB = DJCi500.deckB.currentDeck;

    // Tempo:
    const tempo1 = engine.getValue(deckA, "bpm");
    const tempo2 = engine.getValue(deckB, "bpm");
    let diff = tempo1 - tempo2;

    // Check double tempo:
    let doubleTempo = 0;
    if (diff > 0) {
        if ((tempo1 / tempo2) > 1.5) {
            doubleTempo = 1;
            diff = tempo1 / 2 - tempo2;
        }
    } else {
        if ((tempo2 / tempo1) > 1.5) {
            doubleTempo = 1;
            diff = tempo1 - tempo2 / 2;
        }
    }

    if (diff < -0.25) {
        // Deck1
        midi.sendShortMsg(0x91, 0x1E, 0x0);
        midi.sendShortMsg(0x91, 0x1F, 0x7F);
        midi.sendShortMsg(0x91, 0x2C, 0x0);
        // Deck2
        midi.sendShortMsg(0x92, 0x1F, 0x0);
        midi.sendShortMsg(0x92, 0x1E, 0x7F);
        midi.sendShortMsg(0x92, 0x2C, 0x0);

        // clear beatalign leds
        // Deck1
        midi.sendShortMsg(0x91, 0x1C, 0x0);
        midi.sendShortMsg(0x91, 0x1D, 0x0);
        midi.sendShortMsg(0x91, 0x2D, 0x0);
        // Deck2
        midi.sendShortMsg(0x92, 0x1C, 0x0);
        midi.sendShortMsg(0x92, 0x1D, 0x0);
        midi.sendShortMsg(0x92, 0x2D, 0x0);
    } else if (diff > 0.25) {
        // Deck1
        midi.sendShortMsg(0x91, 0x1F, 0x0);
        midi.sendShortMsg(0x91, 0x1E, 0x7F);
        midi.sendShortMsg(0x91, 0x2C, 0x0);
        // Deck2
        midi.sendShortMsg(0x92, 0x1E, 0x0);
        midi.sendShortMsg(0x92, 0x1F, 0x7F);
        midi.sendShortMsg(0x92, 0x2C, 0x0);

        // clear beatalign leds
        // Deck1
        midi.sendShortMsg(0x91, 0x1C, 0x0);
        midi.sendShortMsg(0x91, 0x1D, 0x0);
        midi.sendShortMsg(0x91, 0x2D, 0x0);
        // Deck2
        midi.sendShortMsg(0x92, 0x1C, 0x0);
        midi.sendShortMsg(0x92, 0x1D, 0x0);
        midi.sendShortMsg(0x92, 0x2D, 0x0);
    } else {
        // Deck1
        midi.sendShortMsg(0x91, 0x1E, 0x0);
        midi.sendShortMsg(0x91, 0x1F, 0x0);
        midi.sendShortMsg(0x91, 0x2C, 0x7F);
        // Deck2
        midi.sendShortMsg(0x92, 0x1E, 0x0);
        midi.sendShortMsg(0x92, 0x1F, 0x0);
        midi.sendShortMsg(0x92, 0x2C, 0x7F);

        // Do beat alignment only if the tracks are already on Tempo
        // and only if they are playing
        if (engine.getValue(deckA, "play_latched") && engine.getValue(deckB, "play_latched")) {
            let beat1 = engine.getValue(deckA, "beat_distance");
            let beat2 = engine.getValue(deckB, "beat_distance");
            if (doubleTempo) {
                if (tempo1 > tempo2) {
                    if (beat2 > 0.5) {
                        beat2 -= 0.5;
                    }
                    beat2 *= 2;
                } else { //tempo2 >(=) tempo1
                    if (beat1 > 0.5) {
                        beat1 -= 0.5;
                    }
                    beat1 *= 2;
                }
            }
            diff = beat1 - beat2;
            if (diff < 0) {
                diff = 1+diff;
            }
            if ((diff < 0.02) || (diff > 1-0.02)) {
                // Deck1
                midi.sendShortMsg(0x91, 0x1C, 0x0);
                midi.sendShortMsg(0x91, 0x1D, 0x0);
                midi.sendShortMsg(0x91, 0x2D, 0x7F);
                //Deck2
                midi.sendShortMsg(0x92, 0x1C, 0x0);
                midi.sendShortMsg(0x92, 0x1D, 0x0);
                midi.sendShortMsg(0x92, 0x2D, 0x7F);
            } else if (diff < 0.5) {
                // Deck1
                midi.sendShortMsg(0x91, 0x1C, 0x0);
                midi.sendShortMsg(0x91, 0x1D, 0x7F);
                midi.sendShortMsg(0x91, 0x2D, 0x0);
                // Deck2
                midi.sendShortMsg(0x92, 0x1D, 0x0);
                midi.sendShortMsg(0x92, 0x1C, 0x7F);
                midi.sendShortMsg(0x91, 0x2D, 0x0);
            } else {
                // Deck1
                midi.sendShortMsg(0x91, 0x1D, 0x0);
                midi.sendShortMsg(0x91, 0x1C, 0x7F);
                midi.sendShortMsg(0x91, 0x2D, 0x0);
                // Deck2
                midi.sendShortMsg(0x92, 0x1C, 0x0);
                midi.sendShortMsg(0x92, 0x1D, 0x7F);
                midi.sendShortMsg(0x92, 0x2D, 0x0);
            }
        // if playing
        } else {
            // Deck1
            midi.sendShortMsg(0x91, 0x1C, 0x0);
            midi.sendShortMsg(0x91, 0x1D, 0x0);
            midi.sendShortMsg(0x91, 0x2D, 0x0);
            // Deck2
            midi.sendShortMsg(0x92, 0x1C, 0x0);
            midi.sendShortMsg(0x92, 0x1D, 0x0);
            midi.sendShortMsg(0x92, 0x2D, 0x0);
        }
    }// else tempo
};

// After a channel change, make sure we read the current status
DJCi500.updateDeckStatus = function(group) {
    const playing = engine.getValue(group, "play_indicator");
    const volume = script.absoluteLinInverse(engine.getValue(group, "vu_meter"), 0.0, 1.0, 0, 127);

    // Update the vinyl button
    let vinylState = false;
    const deckIndex = script.deckFromGroup(group) - 1;
    const channel = ((group === "[Channel1]") || (group === "[Channel3]")) ? 1 : 2;
    if (channel === 1) {
        vinylState = DJCi500.deckA.vinylButtonState[deckIndex];
    } else {
        vinylState = DJCi500.deckB.vinylButtonState[deckIndex];
    }
    midi.sendShortMsg(0x90 + channel, 0x03, (vinylState) ? 0x7F : 0x00);
    midi.sendShortMsg(0xB0 + channel, 0x40, volume);
    midi.sendShortMsg(0x90 + channel, 0x30, playing ? 0x7F : 0x00);

    // Update the fx rack selection
    DJCi500.fxSelIndicator(0, "[EffectRack1_EffectUnit1]", 0, 0);
    DJCi500.fxSelIndicator(0, "[EffectRack1_EffectUnit2]", 0, 0);

    DJCi500.fxEnabledIndicator(0, `[QuickEffectRack1_${group}]`, 0, 0);

    // Slicer
    switch (group) {
    case "[Channel1]":
        DJCi500.slicerBeat1.disconnect();
        DJCi500.slicerBeat1 = engine.makeConnection("[Channel1]", "beat_active", DJCi500.slicerBeatActive);
        DJCi500.slicerBeat1.trigger();
        break;
    case "[Channel2]":
        DJCi500.slicerBeat2.disconnect();
        DJCi500.slicerBeat2 = engine.makeConnection("[Channel2]", "beat_active", DJCi500.slicerBeatActive);
        DJCi500.slicerBeat2.trigger();
        break;
    case "[Channel3]":
        DJCi500.slicerBeat1.disconnect();
        DJCi500.slicerBeat1 = engine.makeConnection("[Channel3]", "beat_active", DJCi500.slicerBeatActive);
        DJCi500.slicerBeat1.trigger();
        break;
    case "[Channel4]":
        DJCi500.slicerBeat2.disconnect();
        DJCi500.slicerBeat2 = engine.makeConnection("[Channel4]", "beat_active", DJCi500.slicerBeatActive);
        DJCi500.slicerBeat2.trigger();
        break;
    };
};

DJCi500.updateEffectStatus = function(midiChannel, _channel) {
    let status = false;
    for (let i = 1; i <= 3; i++) {
        status = status || engine.getValue(`[EffectRack1_EffectUnit${midiChannel}_Effect${i}]`, "enabled");
    }
    return status;
    // return engine.getValue("[EffectRack1_EffectUnit" + midiChannel + "]", "group_[Channel" + channel + "]_enable");
};

///////////////////////////////////////////////////////////////
//                          SLICER                           //
///////////////////////////////////////////////////////////////
DJCi500.slicerButtonFunc = function(channel, control, value, status, group) {
    const index = control - 0x20;
    const deck = script.deckFromGroup(group) - 1;
    const domain = DJCi500.selectedSlicerDomain[deck];
    const passedTime = engine.getValue(group, "beat_distance");
    const loopEnabled = engine.getValue(group, "loop_enabled");

    let beatsToJump = 0;

    if (value) {
        DJCi500.slicerButton[deck] = index;
        // Maybe I need to update this (seems sometimes it does not work.)
        // DJCi500.slicerBeatsPassed[deck] = Math.floor((playposition * duration) * (bpm / 60.0));
        beatsToJump = (index * (domain / 8)) - ((DJCi500.slicerBeatsPassed[deck] % domain));
        beatsToJump -= passedTime;

        // activate the one-shot timer for the slip end.
        if (!DJCi500.slicerTimer[deck]) {
            DJCi500.slicerTimer[deck] = true;
            let timerMs = (1-passedTime)*60.0/engine.getValue(group, "bpm")*1000;

            // quality of life fix for not-precise hands or beatgrid
            // also good fix for really small timerMs values.
            if ((passedTime >= 0.8) &&
                //this is because while looping doing this thing on beat 8 break the flow.
                ((!loopEnabled) || (DJCi500.slicerBeatsPassed[deck] % domain) !== (domain-1))) {
                timerMs += 60.0/engine.getValue(group, "bpm")*1000;
            }

            engine.beginTimer(timerMs,
                // "DJCi500.slicerTimerCallback("+group+")", true);
                function() {
                    // need to do this otherwise loop does not work on beat 8 because of slip.
                    if ((engine.getValue(group, "loop_enabled") === true)) {
                        // on the wiki it says it returns an integer, but I tested and instead seems a Real value:
                        // But it does not work cuz the value does not relate to beat. they are samples.
                        // var endLoop = engine.getValue(group, "loop_end_position");
                        engine.setValue(group, "reloop_toggle", true); //false
                        engine.setValue(group, "slip_enabled", false);
                        // Aleatory behavior, probably because the slip does not always have completed before "returning"
                        // so I need to introduce a timer waiting the slip function to be completely resolved
                        engine.beginTimer(2, function() {
                            engine.setValue(group, "reloop_toggle", true);
                        },
                        true);
                    } else {
                        engine.setValue(group, "slip_enabled", false);
                    }
                    DJCi500.slicerTimer[deck] = false;
                    DJCi500.slicerButton[deck] = -1;
                },
                true);
        }

        engine.setValue(group, "slip_enabled", true);

        // Because of Mixxx beatjump implementation, we need to deactivate the loop before jumping
        // also there is no "lopp_deactivate" and loop_activate false does not work.
        if (loopEnabled) {
            engine.setValue(group, "reloop_toggle", true);
        }
        engine.setValue(group, "beatjump", beatsToJump);
        // This sadly does not work.
        // engine.setValue(group, "loop_move", -beatsToJump);
        if (loopEnabled) {
            engine.setValue(group, "reloop_toggle", true);
        }
        midi.sendShortMsg((0x96+(deck % 2)), 0x20+index,
            DJCi500.rx3PadPalettes[3][index]);
    } // if value
};

// This below is connected to beat_active
DJCi500.slicerBeatActive = function(value, group, _control) {
    // This slicer implementation will work for constant beatgrids only!
    const deck = script.deckFromGroup(group) - 1;
    const channel = deck % 2;

    const bpm = engine.getValue(group, "file_bpm"),
        playposition = engine.getValue(group, "playposition"),
        duration = engine.getValue(group, "duration"),
        domain = DJCi500.selectedSlicerDomain[deck];

    let slicerPosInSection = 0;

    if (engine.getValue(group, "beat_closest") === engine.getValue(group, "beat_next")) {
        return;
    }

    DJCi500.slicerBeatsPassed[deck] = Math.floor((playposition * duration) * (bpm / 60.0));

    if (DJCi500.slicerActive[deck]) {
        slicerPosInSection = Math.floor((DJCi500.slicerBeatsPassed[deck] % domain) / (domain / 8));
        // PAD Led control:
        if (DJCi500.slicerButton[deck] !== slicerPosInSection) {
            for (let i = 0; i < 8; i++) {
                // Keep pads 1-6 blue and 7-8 truly white at every phase.
                midi.sendShortMsg((0x96+channel), 0x20+i,
                    DJCi500.rx3PadPalettes[3][i]);
            }
        } else {
            const pressed = DJCi500.slicerButton[deck];
            midi.sendShortMsg((0x96+channel), 0x20+pressed,
                DJCi500.rx3PadPalettes[3][pressed]);
        }
    } else {
        DJCi500.slicerAlreadyJumped[deck] = false;
        DJCi500.slicerPreviousBeatsPassed[deck] = 0;
    }
};

DJCi500.shutdown = function() {
    DJCi500.rx3CancelBrowserTimer();
    DJCi500.rx3BrowserPressed = false;
    DJCi500.rx3SetGridMode(false);
    // Cleanup
    if (DJCi500.tempoTimer) {
        engine.stopTimer(DJCi500.tempoTimer);
    }
    if (DJCi500.rx3SoundColorFxTimer) {
        engine.stopTimer(DJCi500.rx3SoundColorFxTimer);
    }
    if (DJCi500.rx3SidePanelConnection) {
        DJCi500.rx3SidePanelConnection.disconnect();
    }
    midi.sendShortMsg(0x90, 0x05, 0x00); // Turn browser led off
    DJCi500.rx3SoundColorFxSelected = 0;
    DJCi500.rx3SoundColorFxBlinkOn = false;
    for (let index = 1; index <= 4; index++) {
        midi.sendShortMsg(0x90, 0x13 + index, 0x00);
    }
    midi.sendShortMsg(0xB0, 0x7F, 0x7E);

};
