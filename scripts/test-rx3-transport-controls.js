import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import {fileURLToPath} from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const controllerDir = path.join(root, "controllers",
    "Hercules_DJControl_Inpulse_500_RX3");
const scriptPath = path.join(controllerDir,
    "Hercules-DJControl-Inpulse-500-RX3-script.js");
const mappingPath = path.join(controllerDir,
    "Hercules_DJControl_Inpulse_500_RX3.midi.xml");

const values = new Map();
const sets = [];
const triggers = [];
const midiCalls = [];
const key = (group, control) => `${group}|${control}`;
const sandbox = {
    console,
    engine: {
        getValue(group, control) {
            return values.get(key(group, control)) ?? 0;
        },
        setValue(group, control, value) {
            values.set(key(group, control), value);
            sets.push({group, control, value});
        },
    },
    midi: {
        sendShortMsg(status, control, value) {
            midiCalls.push({status, control, value});
        },
    },
    script: {
        triggerControl(group, control) {
            triggers.push({group, control});
        },
    },
    components: {Deck: function() {}},
};
sandbox.components.Deck.prototype = {};

const source = fs.readFileSync(scriptPath, "utf8");
vm.runInNewContext(source, sandbox, {filename: scriptPath});
const mapping = sandbox.DJCi500;
const deckA = {currentDeck: "[Channel1]", isShiftPressed: false, loopAdjustMode: "in"};
const deckB = {currentDeck: "[Channel2]", isShiftPressed: false, loopAdjustMode: null};
mapping.deckA = deckA;
mapping.deckB = deckB;

mapping.rx3ToggleSlip(deckA, 0x7F);
assert.equal(values.get(key("[Channel1]", "slip_enabled")), 1);
mapping.rx3ToggleSlip(deckA, 0x00);
assert.equal(values.get(key("[Channel1]", "slip_enabled")), 1,
    "SLIP release must not toggle the state a second time");
mapping.rx3ToggleSlip(deckA, 0x7F);
assert.equal(values.get(key("[Channel1]", "slip_enabled")), 0);

mapping.rx3SyncButton(deckA, 0x7F, 0x91);
assert.equal(values.get(key("[Channel1]", "beatsync")), 1);
assert.equal(values.get(key("[Channel1]", "sync_enabled")), 1);
mapping.rx3SyncButton(deckA, 0x7F, 0x91);
assert.equal(values.get(key("[Channel1]", "sync_enabled")), 0);

mapping.rx3SyncButton(deckA, 0x7F, 0x94);
mapping.rx3SyncButton(deckB, 0x7F, 0x95);
assert.equal(values.get(key("[Channel1]", "keylock")), 1);
assert.equal(values.get(key("[Channel2]", "keylock")), 1);
assert.equal(values.get(key("[Channel2]", "sync_enabled")), undefined,
    "SHIFT + SYNC must not alter SYNC on the other deck");

for (const expected of [0.06, 0.10, 0.16, 1.0, 0.06]) {
    mapping.rx3TempoRangeButton(0, 0x01, 0x7F);
    assert.equal(values.get(key("[Channel1]", "rateRange")), expected);
    assert.equal(values.get(key("[Channel2]", "rateRange")), expected);
    mapping.rx3TempoRangeButton(0, 0x01, 0x00);
}
assert.deepEqual(midiCalls.slice(-2), [
    {status: 0x90, control: 0x01, value: 0x7F},
    {status: 0x90, control: 0x01, value: 0x00},
]);

values.set(key("[Channel1]", "quantize"), 0);
mapping.rx3LoopInLongPress(deckA, 0x7F);
assert.equal(deckA.loopAdjustMode, null);
assert.deepEqual(triggers, [
    {group: "[Channel1]", control: "beatloop_4_activate"},
]);
assert.deepEqual(sets.slice(-2), [
    {group: "[Channel1]", control: "quantize", value: 1},
    {group: "[Channel1]", control: "quantize", value: 0},
]);

const xml = fs.readFileSync(mappingPath, "utf8");
assert.equal((xml.match(/loopInLongPressButton\.input/g) || []).length, 2);
assert.match(xml, /BEATMATCH GUIDE:[\s\S]*?<status>0x90<\/status>[\s\S]*?<midino>0x01<\/midino>/);
assert.equal((xml.match(/toggle Master Tempo \(keylock\)/g) || []).length, 2);
assert.match(source,
    /this\.syncButton = new components\.Button\([\s\S]*?outKey: "sync_enabled"/,
    "the SYNC LED must be connected to each deck's persistent sync state");
assert.match(source,
    /this\.slipButton = new components\.Button\([\s\S]*?outKey: "slip_enabled"/,
    "the SLIP LED must follow Mixxx's real slip state");
assert.match(source,
    /engine\.beginTimer\(500,[\s\S]*?deckA\.syncButton\.trigger\(\)[\s\S]*?deckB\.syncButton\.trigger\(\)[\s\S]*?deckA\.slipButton\.trigger\(\)[\s\S]*?deckB\.slipButton\.trigger\(\)/,
    "SYNC and SLIP LEDs must be repainted after PortMidi finishes opening");

console.log("RX3 SLIP, SYNC, tempo range and long LOOP IN tests passed");
