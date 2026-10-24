// XboxOSv2 – the one place theme settings are read and written.
//
// Pegasus rewrites the WHOLE settings file on every api.memory.set, on the UI
// thread. Settings rows wrote two keys per left/right press (value + Index),
// so holding a direction to scroll through options meant dozens of full-file
// rewrites. Here, writes go to a pending map that reads see straight away,
// and are written to disk once input settles (and before anything that
// could end the session: launching, leaving Settings, Pegasus going to the
// background, the theme unloading).
//
// get(key) falls back to `defaults` (theme.qml's settingDefaults, the
// schema), so every screen agrees on what an unset setting means.
import QtQuick 2.15

QtObject {
id: store

    property var defaults: ({})
    // Bumped on every change, and again when pending writes reach disk.
    // theme.qml's settingsEpoch is an alias of this.
    property int epoch: 0

    // Never reassigned (see flush), so reading it creates no live dependency.
    property var _pending: ({})
    property bool _dirty: false

    function has(key) {
        return _pending.hasOwnProperty(key) || api.memory.has(key);
    }

    function get(key, fallback) {
        if (_pending.hasOwnProperty(key)) return _pending[key];
        if (api.memory.has(key)) return api.memory.get(key);
        return fallback !== undefined ? fallback : defaults[key];
    }

    function set(key, value) {
        if (!_pending.hasOwnProperty(key) && api.memory.has(key) && api.memory.get(key) === value)
            return;                      // unchanged: no write at all
        _pending[key] = value;
        _dirty = true;
        _flushTimer.restart();
        epoch++;
    }

    function unset(key) {
        delete _pending[key];
        if (api.memory.has(key)) api.memory.unset(key);
        epoch++;
    }

    function flush() {
        if (!_dirty) return;
        _dirty = false;
        _flushTimer.stop();
        // Emptied in place, never reassigned: the theme's `settings` object
        // reads through get(), and a reassignment would notify it and
        // rebuild every settings.* binding in the theme.
        var keys = Object.keys(_pending);
        for (var i = 0; i < keys.length; i++) {
            api.memory.set(keys[i], _pending[keys[i]]);
            delete _pending[keys[i]];
        }
        epoch++;
    }

    property Timer _flushTimer: Timer {
        interval: 500
        onTriggered: store.flush()
    }

    Component.onDestruction: flush()
}
