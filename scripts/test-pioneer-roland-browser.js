#!/usr/bin/env node
// Exercise the shared RX3 browser adapter in native and stock Mixxx modes.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const source = fs.readFileSync(path.join(__dirname,
    '../controllers/Pioneer_Roland_RX3/Nautic-RX3-Browser.js'), 'utf8');

function setup(native) {
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
            if (native && group === '[Tab]' && key === 'library' && value === 1) {
                values.set('[Tab]:current', 1);
            }
            if (native && group === '[Tab]' && key === 'overview' && value === 1) {
                values.set('[Tab]:current', 0);
            }
        },
    };
    const context = vm.createContext({engine});
    vm.runInContext(source, context);
    return {browser: context.NauticRX3Browser, values, writes};
}

for (const native of [false, true]) {
    const {browser, values, writes} = setup(native);
    browser.turn(0, 0, 1);
    assert.equal(writes.length, 0, 'turn while closed must not alter the deck');
    browser.enter(0, 0, 127);
    assert.equal(values.get('[Skin]:show_maximized_library'), 1);
    assert.equal(writes.some(([, key]) => key === 'enter' || key === 'GoToItem'), false,
        'opening press must not also select');
    const group = native ? '[RX3Browser]' : '[Library]';
    browser.turn(0, 0, 1);
    browser.turn(0, 0, 127);
    assert(writes.some(([g, k, v]) => g === group &&
        (native ? k === 'move' && v === 1 : k === 'MoveDown' && v === 1)));
    assert(writes.some(([g, k, v]) => g === group &&
        (native ? k === 'move' && v === -1 : k === 'MoveUp' && v === 1)));
    browser.enter(0, 0, 127);
    browser.back(0, 0, 127);
    assert(writes.some(([g, k, v]) => g === group &&
        k === (native ? 'enter' : 'GoToItem') && v === 1));
    assert(writes.some(([g, k, v]) => g === group &&
        k === (native ? 'back' : 'MoveLeft') && v === 1));
    browser.source(0, 0, 127);
    assert(writes.some(([g, k, v]) => g === group &&
        k === (native ? 'source' : 'focused_widget') && v === (native ? 1 : 2)));
    browser.view(0, 0, 0);
    assert.equal(values.get('[Skin]:show_maximized_library'), 1);
    browser.view(0, 0, 127);
    assert.equal(values.get('[Skin]:show_maximized_library'), 0);
    browser.view(0, 0, 127);
    assert.equal(values.get('[Skin]:show_maximized_library'), 1);
}
console.log('Pioneer/Roland browser: native and stock modes passed');
