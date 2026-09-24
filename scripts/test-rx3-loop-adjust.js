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

const values = new Map([
    ["[Channel1]|loop_enabled", 1],
    ["[Channel1]|loop_start_position", 10000],
    ["[Channel1]|loop_end_position", 20000],
    ["[Channel1]|track_samplerate", 1000],
    ["[Channel1]|track_samples", 30000],
]);
const sets = [];
const triggers = [];
const sandbox = {
    console,
    engine: {
        getValue(group, control) {
            return values.get(`${group}|${control}`) ?? 0;
        },
        setValue(group, control, value) {
            values.set(`${group}|${control}`, value);
            sets.push({group, control, value});
        },
    },
    midi: {},
    script: {
        triggerControl(group, control) {
            triggers.push({group, control});
        },
    },
    components: {Deck: function() {}},
};
sandbox.components.Deck.prototype = {};
vm.runInNewContext(fs.readFileSync(scriptPath, "utf8"), sandbox, {filename: scriptPath});
const mapping = sandbox.DJCi500;
const deck = {currentDeck: "[Channel1]", loopAdjustMode: null};

mapping.rx3LoopButton(deck, "in", 0x7F, 0x91);
assert.equal(deck.loopAdjustMode, "in");
assert.equal(mapping.rx3AdjustLoopPoint(deck, 10, 720), true);
assert.equal(values.get("[Channel1]|loop_start_position"), 10050);

mapping.rx3LoopButton(deck, "out", 0x7F, 0x91);
assert.equal(deck.loopAdjustMode, "out");
assert.equal(mapping.rx3AdjustLoopPoint(deck, 20, 720), true);
assert.equal(values.get("[Channel1]|loop_end_position"), 20100);

mapping.rx3AdjustLoopPoint(deck, -10000, 720);
assert.equal(values.get("[Channel1]|loop_end_position"), 10052,
    "loop out must not cross loop in");
mapping.rx3AdjustLoopPoint(deck, 10000, 720);
assert.equal(values.get("[Channel1]|loop_end_position"), 30000,
    "loop out must not exceed track length");

mapping.rx3LoopButton(deck, "out", 0x7F, 0x91);
assert.equal(deck.loopAdjustMode, null);
assert.equal(mapping.rx3AdjustLoopPoint(deck, 1, 720), false);

values.set("[Channel1]|loop_enabled", 0);
mapping.rx3LoopButton(deck, "in", 0x7F, 0x91);
mapping.rx3LoopButton(deck, "out", 0x7F, 0x91);
mapping.rx3LoopButton(deck, "in", 0x7F, 0x94);
mapping.rx3LoopButton(deck, "out", 0x7F, 0x94);
assert.deepEqual(triggers, [
    {group: "[Channel1]", control: "loop_in"},
    {group: "[Channel1]", control: "loop_out"},
    {group: "[Channel1]", control: "loop_in_goto"},
    {group: "[Channel1]", control: "loop_out_goto"},
]);

assert.ok(sets.every(({control}) => control !== "quantize"),
    "manual loop adjustment must never change QUANTIZE");

console.log("RX3 Pioneer-style loop IN/OUT adjustment tests passed");
