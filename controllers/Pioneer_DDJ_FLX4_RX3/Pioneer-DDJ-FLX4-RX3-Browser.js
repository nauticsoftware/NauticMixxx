// DDJ-FLX4 RX3 browser navigation adapted from muehlauer's GitHub issue #3 contribution.
// This file does not implement transport, mixer, jog wheels, or effects.
var NauticFLX4Browser = {};

NauticFLX4Browser.pulse = function(group, key, value) {
    engine.setValue(group, key, value);
    engine.setValue(group, key, 0);
};

NauticFLX4Browser.nativeBrowser = function() {
    return engine.getValue("[RX3Browser]", "enabled") > 0;
};

NauticFLX4Browser.isOpen = function() {
    if (Math.round(engine.getValue("[Tab]", "current")) === 1) return true;
    // Stock Mixxx skins do not have NauticMixxx's [Tab] page.
    return !NauticFLX4Browser.nativeBrowser() &&
            engine.getValue("[Skin]", "show_maximized_library") > 0;
};

NauticFLX4Browser.open = function() {
    if (NauticFLX4Browser.isOpen()) return false;
    engine.setValue("[XDJ_RX3]", "search_active", 0);
    NauticFLX4Browser.pulse("[Tab]", "library", 1);
    engine.setValue("[Skin]", "show_maximized_library", 1);
    if (NauticFLX4Browser.nativeBrowser()) {
        NauticFLX4Browser.pulse("[RX3Browser]", "open", 1);
    } else {
        engine.setValue("[Library]", "focused_widget", 2);
    }
    return true;
};

NauticFLX4Browser.view = function(_channel, _control, value) {
    if (value === 0) return;
    if (!NauticFLX4Browser.isOpen()) {
        NauticFLX4Browser.open();
        return;
    }
    engine.setValue("[Skin]", "show_maximized_library", 0);
    NauticFLX4Browser.pulse("[Tab]", "overview", 1);
};

NauticFLX4Browser.source = function(_channel, _control, value) {
    if (value === 0) return;
    NauticFLX4Browser.open();
    if (NauticFLX4Browser.nativeBrowser()) {
        NauticFLX4Browser.pulse("[RX3Browser]", "source", 1);
    } else {
        engine.setValue("[Library]", "focused_widget", 2);
    }
};

NauticFLX4Browser.turn = function(_channel, _control, value) {
    if (value === 0 || !NauticFLX4Browser.isOpen()) return;
    var direction = value > 0x3f ? -1 : 1;
    if (NauticFLX4Browser.nativeBrowser()) {
        NauticFLX4Browser.pulse("[RX3Browser]", "move", direction);
    } else {
        NauticFLX4Browser.pulse("[Library]", direction < 0 ? "MoveUp" : "MoveDown", 1);
    }
};

NauticFLX4Browser.enter = function(_channel, _control, value) {
    if (value === 0 || NauticFLX4Browser.open()) return;
    if (NauticFLX4Browser.nativeBrowser()) {
        NauticFLX4Browser.pulse("[RX3Browser]", "enter", 1);
    } else {
        NauticFLX4Browser.pulse("[Library]", "GoToItem", 1);
    }
};

NauticFLX4Browser.back = function(_channel, _control, value) {
    if (value === 0 || NauticFLX4Browser.open()) return;
    if (NauticFLX4Browser.nativeBrowser()) {
        NauticFLX4Browser.pulse("[RX3Browser]", "back", 1);
    } else {
        NauticFLX4Browser.pulse("[Library]", "MoveLeft", 1);
    }
};
