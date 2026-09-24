import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import {fileURLToPath} from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const scriptPath = path.join(root, "controllers",
    "Hercules_DJControl_Inpulse_500_RX3",
    "Hercules-DJControl-Inpulse-500-RX3-script.js");
const mappingPath = path.join(root, "controllers",
    "Hercules_DJControl_Inpulse_500_RX3",
    "Hercules_DJControl_Inpulse_500_RX3.midi.xml");

const triggers = [];
const engineValues = new Map([
    ["[Channel1]|quantize", 0],
    ["[Channel2]|quantize", 1],
]);
const engineSets = [];
const sandbox = {
    console,
    engine: {
        getValue(group, control) {
            return engineValues.get(`${group}|${control}`) ?? 0;
        },
        setValue(group, control, value) {
            engineValues.set(`${group}|${control}`, value);
            engineSets.push({group, control, value});
        },
    },
    midi: {},
    script: {
        triggerControl(group, control) {
            triggers.push({group, control});
        },
    },
    components: {
        Deck: function() {},
    },
};
sandbox.components.Deck.prototype = {};

vm.runInNewContext(fs.readFileSync(scriptPath, "utf8"), sandbox, {filename: scriptPath});
const mapping = sandbox.DJCi500;

mapping.rx3AutoLoopTurn("[Channel1]", 0x01);
mapping.rx3AutoLoopTurn("[Channel1]", 0x3F);
mapping.rx3AutoLoopTurn("[Channel2]", 0x7F);
mapping.rx3AutoLoopTurn("[Channel2]", 0x41);
assert.deepEqual(triggers, [
    {group: "[Channel1]", control: "loop_double"},
    {group: "[Channel1]", control: "loop_double"},
    {group: "[Channel2]", control: "loop_halve"},
    {group: "[Channel2]", control: "loop_halve"},
]);

mapping.rx3AutoLoopTurn("[Channel1]", 0x00);
mapping.rx3AutoLoopTurn("[Channel1]", 0x40);
assert.equal(triggers.length, 4, "neutral encoder values must be ignored");

mapping.rx3AutoLoopPush("[Channel1]", 0x7F, 0x91);
mapping.rx3AutoLoopPush("[Channel2]", 0x7F, 0x92);
mapping.rx3AutoLoopPush("[Channel1]", 0x00, 0x91);
mapping.rx3AutoLoopPush("[Channel1]", 0x7F, 0x94);
mapping.rx3AutoLoopPush("[Channel2]", 0x7F, 0x95);
assert.deepEqual(triggers.slice(4), [
    {group: "[Channel1]", control: "beatloop_activate"},
    {group: "[Channel2]", control: "beatloop_activate"},
    {group: "[Channel1]", control: "beatloop_4_activate"},
    {group: "[Channel2]", control: "beatloop_4_activate"},
]);
assert.deepEqual(engineSets, [
    {group: "[Channel1]", control: "quantize", value: 1},
    {group: "[Channel1]", control: "quantize", value: 0},
    {group: "[Channel1]", control: "quantize", value: 1},
    {group: "[Channel1]", control: "quantize", value: 0},
], "AUTOLOOP must snap to the grid while preserving each deck's QUANTIZE state");

const xml = fs.readFileSync(mappingPath, "utf8");
for (const [status, deck] of [["0xB1", "A"], ["0xB2", "B"]]) {
    assert.match(xml, new RegExp(
        `Deck ${deck} AUTOLOOP turn[\\s\\S]*?<status>${status}<\\/status>[\\s\\S]*?<midino>0x0E<\\/midino>`));
}
for (const [status, deck] of [["0x91", "A"], ["0x92", "B"]]) {
    assert.match(xml, new RegExp(
        `Deck ${deck} AUTOLOOP push[\\s\\S]*?<status>${status}<\\/status>[\\s\\S]*?<midino>0x2C<\\/midino>`));
}

console.log("RX3 AUTOLOOP mapping tests passed");
