#!/usr/bin/env node
// Verify browser-only FLX6 callbacks without requiring physical hardware.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const source = fs.readFileSync(path.join(__dirname, '../controllers/Pioneer_DDJ_FLX6_RX3/Pioneer-DDJ-FLX6-RX3-Browser.js'), 'utf8');

function mapping(native) {
    const values = new Map([
        ['[RX3Browser]:enabled', native ? 1 : 0],
        ['[Tab]:current', 0],
        ['[Skin]:show_maximized_library', 0],
    ]);
    const writes = [];
    const engine = {
        getValue(group, key) { return values.get(`${group}:${key}`) || 0; },
        setValue(group, key, value) {
            writes.push([group, key, value]);
            values.set(`${group}:${key}`, value);
            // A stock Mixxx skin has no NauticMixxx tab stack: its library
            // maximization control changes, but [Tab],current stays at zero.
            if (native && group === '[Tab]' && key === 'library' && value === 1) values.set('[Tab]:current', 1);
            if (native && group === '[Tab]' && key === 'overview' && value === 1) values.set('[Tab]:current', 0);
        },
    };
    const context = vm.createContext({engine});
    vm.runInContext(source, context);
    return {m: context.NauticFLX6Browser, values, writes};
}

for (const native of [false, true]) {
    const {m, values, writes} = mapping(native);
    m.turn(0, 0, 1);
    assert.equal(writes.length, 0, 'turn must not leave performance');
    m.enter(0, 0, 127);
    assert.equal(values.get('[Skin]:show_maximized_library'), 1, 'encoder opens browser');
    assert.equal(values.get('[Tab]:current'), native ? 1 : 0,
        'stock Mixxx does not provide the NauticMixxx tab state');
    assert.equal(writes.some(([g, k]) => k === 'GoToItem' || k === 'enter'), false,
        'first press must not also select an item');
    m.turn(0, 0, 1);
    m.turn(0, 0, 127);
    const moveGroup = native ? '[RX3Browser]' : '[Library]';
    assert.equal(writes.some(([g, k, v]) => g === moveGroup &&
        (native ? k === 'move' && v === 1 : k === 'MoveDown' && v === 1)), true);
    assert.equal(writes.some(([g, k, v]) => g === moveGroup &&
        (native ? k === 'move' && v === -1 : k === 'MoveUp' && v === 1)), true);
    m.enter(0, 0, 127);
    assert.equal(writes.some(([g, k, v]) => g === moveGroup &&
        k === (native ? 'enter' : 'GoToItem') && v === 1), true);
    m.back(0, 0, 127);
    assert.equal(writes.some(([g, k, v]) => g === moveGroup &&
        k === (native ? 'back' : 'MoveLeft') && v === 1), true);
    m.source(0, 0, 127);
    assert.equal(writes.some(([g, k, v]) => g === (native ? '[RX3Browser]' : '[Library]') &&
        k === (native ? 'source' : 'focused_widget') && v === (native ? 1 : 2)), true);
    m.view(0, 0, 0);
    assert.equal(values.get('[Skin]:show_maximized_library'), 1,
        'releasing VIEW must not close the browser');
    m.view(0, 0, 127);
    assert.equal(values.get('[Skin]:show_maximized_library'), 0,
        'VIEW returns to performance without loading a track');
    assert.equal(values.get('[Tab]:current'), 0, 'native tab returns to performance');
    m.view(0, 0, 0);
    assert.equal(values.get('[Skin]:show_maximized_library'), 0,
        'releasing VIEW must not reopen the browser');
    m.view(0, 0, 127);
    assert.equal(values.get('[Skin]:show_maximized_library'), 1, 'VIEW reopens browser');
}
process.stdout.write('DDJ-FLX6 browser mapping: 2 modes passed\n');
