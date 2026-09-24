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

const values = new Map();
const engineCalls = [];
const midiCalls = [];
const engine = {
    setValue(group, control, value) {
        values.set(`${group},${control}`, value);
        engineCalls.push({group, control, value});
    },
    getValue(group, control) {
        return values.get(`${group},${control}`) || 0;
    },
};

function Deck() {}
Deck.prototype = {
    setCurrentDeck() {},
    reconnectComponents() {},
    shift() {},
    unshift() {},
};

const sandbox = {
    console,
    engine,
    midi: {
        sendShortMsg(status, control, value) {
            midiCalls.push({status, control, value});
        },
    },
    script: {},
    components: {Deck},
};

vm.runInNewContext(fs.readFileSync(scriptPath, "utf8"), sandbox, {filename: scriptPath});
const mapping = sandbox.DJCi500;

assert.equal(typeof mapping.deckSelector, "undefined");
assert.equal(mapping.rx3SoundColorFxAmount(0.5), 0.5);
assert.deepEqual(Array.from(mapping.rx3SoundColorFx, fx => fx && fx.name),
    [null, "REVERB", "PING PONG", "NOISE", "FILTER"]);

const chainDirectory = path.join(root, "effects", "chains");
const reverbChain = fs.readFileSync(path.join(chainDirectory, "RX3 REVERB.xml"), "utf8");
const pingPongChain = fs.readFileSync(path.join(chainDirectory, "RX3 PING PONG.xml"), "utf8");
const filterChain = fs.readFileSync(path.join(chainDirectory, "RX3 FILTER.xml"), "utf8");
assert.match(reverbChain, /<Name>RX3 REVERB<\/Name>/);
assert.match(reverbChain, /<Id>org\.mixxx\.effects\.reverb<\/Id>/);
assert.match(pingPongChain, /<Name>RX3 PING PONG<\/Name>/);
assert.match(pingPongChain, /<Id>pingpong_amount<\/Id><Value>1<\/Value>/);
assert.match(filterChain, /<SuperParameterValue>0\.5<\/SuperParameterValue>/);
assert.match(filterChain, /<Id>lpf<\/Id><Value>22050<\/Value><LinkType>LINKED_LEFT<\/LinkType>/);
assert.match(filterChain, /<Id>hpf<\/Id><Value>13<\/Value><LinkType>LINKED_RIGHT<\/LinkType>/);
assert.equal(mapping.rx3SoundColorFx[4].centeredAmount, false);

mapping.rx3SoundColorFxButton(0, 0x14, 0x7F);
assert.equal(mapping.rx3SoundColorFxSelected, 1);
for (let deck = 1; deck <= 2; deck++) {
    const group = `[QuickEffectRack1_[Channel${deck}]]`;
    assert.equal(values.get(`${group},loaded_chain_preset`), 1);
    assert.equal(values.get(`${group},super1`), 0);
    assert.equal(values.get(`${group},enabled`), 1);
}
assert.deepEqual(midiCalls.slice(-4).map(call => [call.control, call.value]),
    [[0x14, 0x7F], [0x15, 0x7F], [0x16, 0x7F], [0x17, 0x7F]]);

mapping.rx3BlinkSoundColorFx();
assert.deepEqual(midiCalls.slice(-4).map(call => [call.control, call.value]),
    [[0x14, 0], [0x15, 0x7F], [0x16, 0x7F], [0x17, 0x7F]],
    "only the selected FX must blink; the other selectors stay illuminated");

assert.equal(mapping.rx3SoundColorFxKnob(1, 0.75), true);
assert.equal(values.get("[QuickEffectRack1_[Channel1]],super1"), 0.5);
assert.equal(values.get("[QuickEffectRack1_[Channel1]],enabled"), 1);

mapping.rx3SoundColorFxButton(0, 0x14, 0x7F);
assert.equal(mapping.rx3SoundColorFxSelected, 0);
for (let deck = 1; deck <= 2; deck++) {
    assert.equal(values.get(`[QuickEffectRack1_[Channel${deck}]],enabled`), 0);
}
assert.equal(mapping.rx3SoundColorFxKnob(1, 0.25), false,
    "an unselected Sound Color FX must release the knob to the normal filter path");
assert.deepEqual(midiCalls.slice(-4).map(call => [call.control, call.value]),
    [[0x14, 0x7F], [0x15, 0x7F], [0x16, 0x7F], [0x17, 0x7F]],
    "all four selectors must remain illuminated while no FX is selected");

mapping.rx3SoundColorFxButton(0, 0x17, 0x7F);
assert.equal(mapping.rx3SoundColorFxSelected, 4);
for (let deck = 1; deck <= 2; deck++) {
    const group = `[QuickEffectRack1_[Channel${deck}]]`;
    assert.equal(values.get(`${group},loaded_chain_preset`), 4);
    assert.equal(values.get(`${group},super1`), deck === 1 ? 0.25 : 0.5);
}

const xml = fs.readFileSync(mappingPath, "utf8");
assert.equal((xml.match(/DJCi500\.rx3SoundColorFxButton/g) || []).length, 4);
assert.equal(xml.includes("DJCi500.deckSelector"), false);
assert.equal(engineCalls.some(call => /Channel[34]/.test(call.group)), false);

console.log("RX3 Sound Color FX mapping tests passed");
