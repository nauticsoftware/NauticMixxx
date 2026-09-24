// Presentation-only bridge for the RX3 skin on official Mixxx 2.5.6.
// The skin manifest creates these controls. Never write audio/transport/sync.
var RX3WindowsDisplay = {};
RX3WindowsDisplay.group = '[RX3WindowsDisplay]';
RX3WindowsDisplay.selected = -1;
RX3WindowsDisplay.connections = [];
RX3WindowsDisplay.timer = 0;
RX3WindowsDisplay.loopSizes = [0.0078125, 0.015625, 0.03125, 0.0625, 0.125,
    0.25, 0.5, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512];
RX3WindowsDisplay.write = function(key, value) {
    if (engine.getValue(RX3WindowsDisplay.group, key) !== value) {
        engine.setValue(RX3WindowsDisplay.group, key, value);
    }
};
RX3WindowsDisplay.refresh = function() {
    var loaded = [], playing = [], leader = -1, i, group;
    for (i = 0; i < 2; i++) {
        group = '[Channel' + (i + 1) + ']';
        loaded[i] = engine.getValue(group, 'track_loaded') > 0;
        playing[i] = loaded[i] && engine.getValue(group, 'play') > 0;
        if (playing[i] && engine.getValue(group, 'sync_leader') > 0 && leader < 0) leader = i;
    }
    var next = RX3WindowsDisplay.selected;
    if (leader >= 0) next = leader;
    else if (next < 0 || !playing[next]) {
        if (playing[0]) next = 0;
        else if (playing[1]) next = 1;
        else if (next < 0 || !loaded[next]) next = loaded[0] ? 0 : (loaded[1] ? 1 : -1);
    }
    // Clear the previous display before enabling the new one.
    if (next !== RX3WindowsDisplay.selected) {
        RX3WindowsDisplay.write('master1', 0);
        RX3WindowsDisplay.write('master2', 0);
        RX3WindowsDisplay.selected = next;
    }
    for (i = 0; i < 2; i++) {
        RX3WindowsDisplay.write('master' + (i + 1), i === next ? 1 : 0);
        group = '[Channel' + (i + 1) + ']';
        var size = engine.getValue(group, 'beatloop_size');
        var loopState = 0;
        for (var n = 0; n < RX3WindowsDisplay.loopSizes.length; n++) {
            if (Math.abs(size - RX3WindowsDisplay.loopSizes[n]) < 0.000001) loopState = n + 1;
        }
        RX3WindowsDisplay.write('loop_state' + (i + 1), loopState);
    }
    var bpm = next >= 0 ? engine.getValue('[Channel' + (next + 1) + ']', 'visual_bpm') : 0;
    if (!isFinite(bpm) || bpm < 0) bpm = 0;
    RX3WindowsDisplay.write('master_bpm', bpm);
    RX3WindowsDisplay.write('beat_ms', bpm > 0 ? Math.floor(60000 / bpm) : 0);
};
RX3WindowsDisplay.init = function() {
    RX3WindowsDisplay.selected = -1;
    var keys = ['track_loaded', 'play', 'sync_leader', 'visual_bpm', 'beatloop_size'];
    for (var deck = 1; deck <= 2; deck++) {
        for (var k = 0; k < keys.length; k++) {
            RX3WindowsDisplay.connections.push(engine.makeConnection('[Channel' + deck + ']', keys[k], RX3WindowsDisplay.refresh));
        }
    }
    RX3WindowsDisplay.refresh();
    // Restore display controls after a skin reload while the controller stays on.
    RX3WindowsDisplay.timer = engine.beginTimer(250, RX3WindowsDisplay.refresh);
};
RX3WindowsDisplay.shutdown = function() {
    if (RX3WindowsDisplay.timer) engine.stopTimer(RX3WindowsDisplay.timer);
    RX3WindowsDisplay.timer = 0;
    RX3WindowsDisplay.connections.forEach(function(c) { c.disconnect(); });
    RX3WindowsDisplay.connections = [];
    ['master1', 'master2', 'master_bpm', 'beat_ms', 'loop_state1', 'loop_state2'].forEach(function(key) {
        RX3WindowsDisplay.write(key, 0);
    });
    RX3WindowsDisplay.selected = -1;
};
