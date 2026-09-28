// Optional browser-only mapping for the Pioneer DDJ-FLX6.
// This file does not implement transport, mixer, jog wheels, or effects.
var NauticFLX6Browser = {};

NauticFLX6Browser.pulse = function(group, key, value) {
    engine.setValue(group, key, value);
    engine.setValue(group, key, 0);
};

NauticFLX6Browser.nativeBrowser = function() {
    return engine.getValue("[RX3Browser]", "enabled") > 0;
};

NauticFLX6Browser.isOpen = function() {
    return Math.round(engine.getValue("[Tab]", "current")) === 1;
};

NauticFLX6Browser.open = function() {
    if (NauticFLX6Browser.isOpen()) return false;
    engine.setValue("[XDJ_RX3]", "search_active", 0);
    NauticFLX6Browser.pulse("[Tab]", "library", 1);
    engine.setValue("[Skin]", "show_maximized_library", 1);
    if (NauticFLX6Browser.nativeBrowser()) {
        NauticFLX6Browser.pulse("[RX3Browser]", "open", 1);
    } else {
        engine.setValue("[Library]", "focused_widget", 2);
    }
    return true;
};

NauticFLX6Browser.view = function(_channel, _control, value) {
    if (value === 0) return;
    if (!NauticFLX6Browser.isOpen()) {
        NauticFLX6Browser.open();
        return;
    }
    engine.setValue("[Skin]", "show_maximized_library", 0);
    NauticFLX6Browser.pulse("[Tab]", "overview", 1);
};

NauticFLX6Browser.source = function(_channel, _control, value) {
    if (value === 0) return;
    NauticFLX6Browser.open();
    if (NauticFLX6Browser.nativeBrowser()) {
        NauticFLX6Browser.pulse("[RX3Browser]", "source", 1);
    } else {
        engine.setValue("[Library]", "focused_widget", 2);
    }
};

NauticFLX6Browser.turn = function(_channel, _control, value) {
    if (value === 0 || !NauticFLX6Browser.isOpen()) return;
    var direction = value > 0x3f ? -1 : 1;
    if (NauticFLX6Browser.nativeBrowser()) {
        NauticFLX6Browser.pulse("[RX3Browser]", "move", direction);
    } else {
        NauticFLX6Browser.pulse("[Library]", direction < 0 ? "MoveUp" : "MoveDown", 1);
    }
};

NauticFLX6Browser.enter = function(_channel, _control, value) {
    if (value === 0 || NauticFLX6Browser.open()) return;
    if (NauticFLX6Browser.nativeBrowser()) {
        NauticFLX6Browser.pulse("[RX3Browser]", "enter", 1);
    } else {
        NauticFLX6Browser.pulse("[Library]", "GoToItem", 1);
    }
};

NauticFLX6Browser.back = function(_channel, _control, value) {
    if (value === 0 || NauticFLX6Browser.open()) return;
    if (NauticFLX6Browser.nativeBrowser()) {
        NauticFLX6Browser.pulse("[RX3Browser]", "back", 1);
    } else {
        NauticFLX6Browser.pulse("[Library]", "MoveLeft", 1);
    }
};
