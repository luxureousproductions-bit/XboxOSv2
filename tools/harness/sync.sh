#!/bin/bash
# Copy the repo's theme (every git-tracked file but tools/ and extras/) into the
# harness theme folder, then apply the harness-only instrumentation:
#   - Frame counter always on, logging "[perf] hh:mm:ss fps N worst MS tiles ..."
#     every second (a still screen too: Pegasus redraws continuously under Xvfb)
#   - grid tiles counted (created / destroyed) through probe.js
# Run after every edit, before any harness run. Never commit the patched copy.
. "$(dirname "$0")/env.sh"
mkdir -p "$H"
cd "$REPO" && git ls-files | grep -vE '^(tools|extras)/' | while read -r f; do
    mkdir -p "$H/$(dirname "$f")"; cp "$f" "$H/$f"
done
printf '.pragma library\nvar created = 0, destroyed = 0, loads = 0;\n' > "$H/Global/probe.js"
python3 - "$H" <<'PY'
import sys
H=sys.argv[1]
def patch(rel, pairs):
    p=f"{H}/{rel}"; s=open(p).read()
    for old,new in pairs:
        if old not in s: sys.exit(f"harness patch no longer applies: {rel}: {old[:60]!r}")
        s=s.replace(old,new,1)
    open(p,'w').write(s)
patch("theme.qml", [('        return (settingsStore.get("Frame counter", "No")) === "Yes";',
                     '        return true; // TEST HARNESS')])
patch("Global/FrameCounter.qml", [
    ('import QtQuick.Window 2.15', 'import QtQuick.Window 2.15\nimport "probe.js" as Probe'),
    ('if (dt < 250 && dt > counter.worstMs)', 'if (dt > counter.worstMs)'),
    ('''            if (!counter.idle)
                console.log("[perf]", Qt.formatTime(new Date(), "hh:mm:ss"), "fps", counter.frames, "worst", Math.round(counter.worstMs));''',
     '''            console.log('[perf]', Qt.formatTime(new Date(), 'hh:mm:ss'), 'fps', counter.frames, 'worst', Math.round(counter.worstMs), 'tiles', Probe.created, Probe.destroyed, 'alive', Probe.created-Probe.destroyed, 'arms', Probe.loads);''')])
patch("Global/DynamicGridItem.qml", [
    ('import QtQuick 2.15', 'import QtQuick 2.15\nimport "probe.js" as Probe'),
    ('    Component.onCompleted: takeGame()', '    Component.onCompleted: { takeGame(); Probe.created++; }\n    Component.onDestruction: Probe.destroyed++')])
PY
[ $? -eq 0 ] || exit 1
echo "synced to $H"
