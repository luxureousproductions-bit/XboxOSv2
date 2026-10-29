// XboxOSv2 – RAFocus.qml
// The theme's Xbox focus frame (Global/FocusFrame.qml: accent ring, see-
// through gap, soft glow that follows Settings › Frame glow) around whatever
// it fills, built only while `on`. The same pattern Settings and the App
// Drawer use, so the RA pages focus like every other screen.

import QtQuick 2.15
import "../Global"

Loader {
    property bool on: false
    property real radius: vpx(4)
    anchors.fill: parent
    active: on
    z: 5
    sourceComponent: Item {
        FocusFrame { anchors.fill: parent; artRadius: radius; glowStrength: tileHaloLive ? 0.45 : 0 }
    }
}
