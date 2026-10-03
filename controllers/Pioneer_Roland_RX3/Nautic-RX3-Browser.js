// Browser actions shared by the full Pioneer and Roland RX3 presets.
// Transport, mixer, jogs, FX and load buttons stay in each original mapper.
var NauticRX3Browser = {};

NauticRX3Browser.pulse = function(group, key, value) {
    engine.setValue(group, key, value);
    engine.setValue(group, key, 0);
};

NauticRX3Browser.nativeBrowser = function() {
    return engine.getValue("[RX3Browser]", "enabled") > 0;
};

NauticRX3Browser.isOpen = function() {
    if (Math.round(engine.getValue("[Tab]", "current")) === 1) return true;
    return !NauticRX3Browser.nativeBrowser() &&
        engine.getValue("[Skin]", "show_maximized_library") > 0;
};

NauticRX3Browser.open = function() {
    if (NauticRX3Browser.isOpen()) return false;
    engine.setValue("[XDJ_RX3]", "search_active", 0);
    NauticRX3Browser.pulse("[Tab]", "library", 1);
    engine.setValue("[Skin]", "show_maximized_library", 1);
    if (NauticRX3Browser.nativeBrowser()) {
        NauticRX3Browser.pulse("[RX3Browser]", "open", 1);
    } else {
        engine.setValue("[Library]", "focused_widget", 2);
    }
    return true;
};

NauticRX3Browser.view = function(_channel, _control, value) {
    if (!value) return;
    if (NauticRX3Browser.open()) return;
    engine.setValue("[Skin]", "show_maximized_library", 0);
    NauticRX3Browser.pulse("[Tab]", "overview", 1);
};

NauticRX3Browser.source = function(_channel, _control, value) {
    if (!value) return;
    NauticRX3Browser.open();
    if (NauticRX3Browser.nativeBrowser()) {
        NauticRX3Browser.pulse("[RX3Browser]", "source", 1);
    } else {
        engine.setValue("[Library]", "focused_widget", 2);
    }
};

NauticRX3Browser.turn = function(_channel, _control, value) {
    if (!value || !NauticRX3Browser.isOpen()) return;
    const direction = value > 0x3f ? -1 : 1;
    if (NauticRX3Browser.nativeBrowser()) {
        NauticRX3Browser.pulse("[RX3Browser]", "move", direction);
    } else {
        NauticRX3Browser.pulse("[Library]",
            direction < 0 ? "MoveUp" : "MoveDown", 1);
    }
};

NauticRX3Browser.enter = function(_channel, _control, value) {
    if (!value || NauticRX3Browser.open()) return;
    if (NauticRX3Browser.nativeBrowser()) {
        NauticRX3Browser.pulse("[RX3Browser]", "enter", 1);
    } else {
        NauticRX3Browser.pulse("[Library]", "GoToItem", 1);
    }
};

NauticRX3Browser.back = function(_channel, _control, value) {
    if (!value || NauticRX3Browser.open()) return;
    if (NauticRX3Browser.nativeBrowser()) {
        NauticRX3Browser.pulse("[RX3Browser]", "back", 1);
    } else {
        NauticRX3Browser.pulse("[Library]", "MoveLeft", 1);
    }
};
