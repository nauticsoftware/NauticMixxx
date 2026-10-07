const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const here = __dirname;
const source = fs.readFileSync(path.join(here, "../controllers",
    "Hercules_DJControl_Inpulse_500_RX3",
    "Hercules-DJControl-Inpulse-500-RX3-script.js"), "utf8");
const writes = [];
const scratches = new Set();
const ticks = [];
const values = new Map();
const key = (group, control) => `${group}|${control}`;
function Component(options) {
    Object.assign(this, options);
    this.inValueScale = value => value < 64 ? value : value - 128;
}
const sandbox = {
    components: {Deck: function() {}, JogWheelBasic: Component},
    engine: {
        getValue: (group, control) => values.get(key(group, control)) ?? 0,
        setValue: (group, control, value) => {
            if (group === "[RX3Controller]" && control === "active_deck") { values.set(key(group, control), value); return; }
            writes.push({group, control, value});
        },
        isScratching: deck => scratches.has(deck),
        scratchEnable: deck => scratches.add(deck),
        scratchDisable: deck => scratches.delete(deck),
        scratchTick: (deck, value) => ticks.push({deck, value}),
    },
    script: {deckFromGroup: group => Number(group.match(/\d+/)[0])},
};
sandbox.components.Deck.prototype = {};
vm.runInNewContext(source, sandbox);

const shape = sandbox.DJCi500.rx3ShapeJogBend;
assert.equal(shape(0), 0);
assert.equal(shape(1), 0.35);
assert.equal(shape(-1), -0.35);
assert.equal(shape(63), 1.6);
assert.equal(shape(-63), -1.6);
assert.equal(shape(127), 1.6);
assert.equal(shape(-64), -1.6, "MIDI 0x40 has the same limit as 0x3F");
assert.equal(shape(NaN), 0);
assert.equal(shape(Infinity), 0);
assert.equal(shape(-Infinity), 0);
for (let velocity = 2; velocity <= 63; velocity++) {
    assert.ok(shape(velocity) > shape(velocity - 1));
    assert.equal(shape(-velocity), -shape(velocity));
    const previous = 1.9 + 0.5 * Math.log(velocity) / Math.log(63);
    assert.ok(shape(velocity) < previous,
        "the whole MIDI range now requires more movement for a correction");
}
assert.ok(shape(1) < 1.9 / 5,
    "the slowest turn has over five times the previous adjustment travel");
assert.ok(shape(16) / shape(1) > 2,
    "normal turns have a useful range above fine corrections");
sandbox.DJCi500.rx3JogBendSensitivity = 0.5;
assert.equal(shape(1), 0.175);
assert.equal(shape(63), 0.8);
sandbox.DJCi500.rx3JogBendSensitivity = 1;

// Exercise the actual mapping handlers, not a copy of their routing logic.
const mapper = sandbox.DJCi500;
function buildJog(name, deckData, midiChannel) {
    const start = source.indexOf(`    this.${name} = new components.`);
    assert.ok(start >= 0);
    const end = source.indexOf("\n    });", start) + 8;
    sandbox.fixtureDeck = deckData;
    sandbox.fixtureChannel = midiChannel;
    return vm.runInNewContext(`(function(deckData, midiChannel) {
        ${source.slice(start, end)}
        return this.${name};
    }).call({}, fixtureDeck, fixtureChannel)`, sandbox);
}
for (const deck of [1, 2, 3, 4]) {
    const group = `[Channel${deck}]`;
    const deckData = {currentDeck: group, loopAdjustMode: null,
        vinylButtonState: [true, true, true, true]};
    const jog = buildJog("jogWheel", deckData, deck % 2 ? 1 : 2);
    const shiftedJog = buildJog("jogWheelShift", deckData, deck % 2 ? 1 : 2);
    values.set(key(group, "play"), 1);

    // Slow MIDI packets must all contribute, including repeated ones and an
    // immediate reversal. No accumulator threshold should swallow them.
    for (const vinyl of [true, false]) {
        deckData.vinylButtonState[deck - 1] = vinyl;
        writes.length = 0;
        for (const midiValue of [1, 1, 127, 0, 16, 112, 63, 64]) {
            jog.inputWheel(0, 0x09, midiValue, 0xB1, group);
        }
        assert.deepEqual(writes.map(write => write.value),
            [0.35, 0.35, -0.35, 0, shape(16), -shape(16), 1.6, -1.6]);
        assert.ok(writes.every(write => write.group === group && write.control === "jog"));
    }

    // VINYL surface contact still scratches at the original resolution.
    deckData.vinylButtonState[deck - 1] = true;
    writes.length = 0;
    jog.inputTouch(0, 0x08, 127, 0x91, group);
    jog.inputWheel(0, 0x0A, 3, 0xB1, group);
    assert.deepEqual(ticks.at(-1), {deck, value: 3});
    assert.equal(writes.length, 0);
    jog.inputTouch(0, 0x08, 0, 0x81, group);

    values.set(key(group, "play"), 0);
    jog.inputWheel(0, 0x09, 16, 0xB1, group);
    assert.deepEqual(writes.at(-1), {group, control: "jog", value: 16},
        "paused searching retains its own response");

    // GRID jogs select the deck; only BROWSER edits the grid.
    const adjustLoop = mapper.rx3AdjustLoopPoint;
    writes.length = 0;
    values.set(key("[RX3Controller]", "grid_mode"), 1);
    jog.inputWheel(0, 0x09, 4, 0xB1, group);
    shiftedJog.inputWheel(0, 0x09, 4, 0xB4, group);
    assert.equal(writes.length, 0);
    if (deck <= 2) assert.equal(values.get(key("[RX3Controller]", "active_deck")), deck);
    values.set(key("[RX3Controller]", "grid_mode"), 0);
    mapper.rx3AdjustLoopPoint = (data, delta, resolution) => {
        assert.equal(data, deckData);
        assert.equal(delta, -4);
        assert.equal(resolution, 720);
        return true;
    };
    jog.inputWheel(0, 0x09, 124, 0xB1, group);
    assert.equal(writes.length, 0);
    mapper.rx3AdjustLoopPoint = adjustLoop;

    const fastSeek = mapper.rx3FastSeek;
    mapper.rx3FastSeek = (targetGroup, delta, resolution) => {
        assert.equal(targetGroup, group);
        assert.equal(delta, 8);
        assert.equal(resolution, 720);
    };
    shiftedJog.inputWheel(0, 0x09, 8, 0xB4, group);
    assert.equal(writes.length, 0, "SHIFT never goes through the bend curve");
    mapper.rx3FastSeek = fastSeek;
}
console.log("PASS: progressive jog bend, slow/repeated/reverse MIDI and preserved VINYL, pause, SHIFT, grid and loop paths on decks 1–4");
