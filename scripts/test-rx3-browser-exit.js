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
    const context = vm.createContext({engine, Date: {now: () => now}, components: {Deck: function() {}},
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

for (const native of [true, false]) {
    const f = fixture(native);
    f.press(); f.press(); assert.equal(f.timers.size, 1, 'duplicate Note On has one timer');
    f.advance(599); assert.equal(f.values.get('[Tab]:current'), 1, 'no exit before 600 ms');
    f.advance(1); assert.equal(f.values.get('[Tab]:current'), 0, 'hold exits to PERFORMANCE');
    f.release(64, 0x80); assert.equal(f.values.get('[Tab]:current'), 0, 'Note Off velocity never reopens');
    assert.equal(f.values.get('[Channel1]:play'), 1, 'playback continues');
    assert(!f.writes.some(([g, k]) => g.startsWith('[Channel') || k === 'source' || k === 'enter'),
        'exit must not load, select, alter transport, or navigate SOURCE');
    assert.equal(f.timers.size, 0);

    f.engine.setValue('[Tab]', 'library', 1); f.writes.length = 0;
    f.press(); f.advance(150); f.release();
    assert.equal(f.timers.size, 0, 'short press cancels pending exit');
    if (native) assert(f.writes.some(([g, k, v]) => g === '[RX3Browser]' && k === 'source' && v === 1));
    assert.equal(f.values.get('[Tab]:current'), 1);

    f.press(); f.advance(600, false); f.release();
    assert.equal(f.values.get('[Tab]:current'), 0, 'release fallback handles delayed timer');
    f.press(); f.advance(1000); f.release();
    if (!native) assert.equal(f.values.get('[Tab]:current'), 1, 'ASSISTANT still opens from PERFORMANCE');
}

const shifted = fixture();
shifted.m.deckB.isShiftPressed = true;
shifted.press(); shifted.press(); shifted.advance(1000); shifted.release();
assert.equal(shifted.timers.size, 0, 'SHIFT shortcut never schedules exit');
assert.equal(shifted.values.get('[Tab]:current'), 1);
assert.equal(shifted.writes.filter(([g, k]) => g === '[RX3SidePanel]' && k === 'beatfx').length, 1);
assert(!shifted.writes.some(([g, k]) => g === '[RX3Browser]' && k === 'source'));

const stopped = fixture(); stopped.press(); stopped.m.shutdown(); stopped.advance(2000);
assert.equal(stopped.timers.size, 0, 'shutdown cancels timer');
assert.equal(stopped.values.get('[Tab]:current'), 1, 'shutdown cannot execute a delayed exit');
console.log('Inpulse ASSISTANT: short SOURCE, 600 ms exit, SHIFT, Note Off and timer cleanup passed');
