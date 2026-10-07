#!/usr/bin/env node
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(__dirname,
    '../controllers/Hercules_DJControl_Inpulse_500_RX3/Hercules-DJControl-Inpulse-500-RX3-script.js'), 'utf8');

function fixture(native = true) {
    let now = 1000, nextTimer = 1;
    const values = new Map([['[Tab]:current', 1], ['[RX3Browser]:enabled', native ? 1 : 0],
        ['[Skin]:show_maximized_library', 1], ['[Channel1]:play', 1],
        ['[RX3SidePanel]:current', 0]]);
    const writes = [], timers = new Map();
    const engine = {
        getValue(g, k) { return values.get(`${g}:${k}`) || 0; },
        setValue(g, k, v) {
            values.set(`${g}:${k}`, v); writes.push([g, k, v]);
            if (g === '[Tab]' && v === 1 && ['overview', 'library'].includes(k)) {
                values.set('[Tab]:current', k === 'library' ? 1 : 0);
            }
        },
        beginTimer(ms, callback) { const id = nextTimer++; timers.set(id, {at: now + ms, callback}); return id; },
        stopTimer(id) { timers.delete(id); },
        isScratching() { return false; },
    };
    const context = vm.createContext({engine, Date: {now: () => now}, components: {Deck: function() {}}, script: {deckFromGroup: g => Number(g.match(/\d+/)[0])},
        midi: {sendShortMsg() {}}, console});
    vm.runInContext(source, context);
    const m = context.DJCi500;
    m.deckA = {isShiftPressed: false}; m.deckB = {isShiftPressed: false};
    return {m, values, writes, timers, engine,
        press: () => m.rx3AssistantButton(0, 3, 127, 0x90),
        release: (value = 0, status = 0x90) => m.rx3AssistantButton(0, 3, value, status),
        advance(ms, fire = true) {
            now += ms;
            if (fire) for (const [id, timer] of [...timers]) {
                if (timer.at <= now) { timers.delete(id); timer.callback(); }
            }
        }};
}

function browserPress(f) { f.m.rx3BrowserPush(0, 0, 127, 0x90); }
function browserRelease(f) { f.m.rx3BrowserPush(0, 0, 0, 0x80); }
const before = fixture(); before.values.set('[Tab]:current', 0);
browserPress(before); before.advance(1999);
assert.equal(before.engine.getValue('[RX3Controller]', 'grid_mode'), 0);
browserRelease(before);
assert.equal(before.engine.getValue('[RX3Controller]', 'grid_mode'), 0);
const exact = fixture(); exact.values.set('[Tab]:current', 0);
exact.values.set('[RX3Controller]:active_deck', 2);
exact.values.set('[Channel2]:track_loaded', 1);
browserPress(exact); exact.advance(2000);
assert.equal(exact.engine.getValue('[RX3Controller]', 'grid_mode'), 1);
browserRelease(exact);
assert.equal(exact.engine.getValue('[RX3Controller]', 'grid_mode'), 1, 'release must not exit GRID');
exact.writes.length = 0;
exact.m.moveLibrary(0, 0, 1, 0xB0);
assert(exact.writes.some(([g,k,v]) => g === '[Channel2]' && k === 'beats_translate_move' && v === 1));
assert(!exact.writes.some(([g]) => g === '[Channel1]'));
exact.m.moveLibrary(0, 0, 127, 0xB0);
assert(exact.writes.some(([g,k,v]) => g === '[Channel2]' && k === 'beats_translate_move' && v === -1));
exact.m.rx3BrowserIgnoreUntil = 0;
browserPress(exact); browserRelease(exact);
assert.equal(exact.engine.getValue('[RX3Controller]', 'grid_mode'), 0);
const browse = fixture(); browserPress(browse); browse.advance(2000);
assert.equal(browse.engine.getValue('[RX3Controller]', 'grid_mode'), 0, 'long hold is PERFORMANCE-only');
const moved = fixture(); moved.values.set('[Tab]:current', 0);
browserPress(moved); moved.m.rx3BrowserMovedWhilePressed = true; moved.advance(2000);
assert.equal(moved.engine.getValue('[RX3Controller]', 'grid_mode'), 0);
console.log('PASS: GRID exact two-second hold, release, selected-deck encoder routing, direction and cancellation');
