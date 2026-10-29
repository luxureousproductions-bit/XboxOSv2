// XboxOS-V2
// The face of a nav button (Home, Library and Game details headers), as on the
// Xbox: at rest a faint round pill with an OUTLINE icon; focused, it grows a
// little and becomes a near-black disc with the FILLED icon, inside a thin
// accent ring with a hair of gap between them. The ring glows only while
// Frame glow is on (tileHaloLive).
//
// Fills its button. The button keeps its keys, mouse area and label; it just
// sets focused / icon / iconFilled here.

import QtQuick 2.15
import QtGraphicalEffects 1.15

Item {
id: pill
    anchors.fill: parent

    property bool focused: false
    property string icon: ""
    property string iconFilled: ""        // "" = the same icon both ways
    property real iconSize: Math.round(width * 2 / 3)
    property bool light: false            // light page background: light pill, black icon

    readonly property real ringW: Math.max(1.5, vpx(2.2))
    readonly property real gap: Math.max(1.5, vpx(2))

    scale: focused ? 1.3 : 1
    Behavior on scale { NumberAnimation { duration: animMs(120); easing.type: Easing.OutCubic } }

    // Pill at rest, disc when focused (inset by the ring and the gap).
    Rectangle {
        z: 1
        anchors.fill: parent
        anchors.margins: pill.focused ? pill.ringW + pill.gap : 0
        radius: width / 2
        color: pill.focused
               ? (pill.light ? Qt.rgba(1, 1, 1, 0.92) : Qt.rgba(0.04, 0.04, 0.04, 0.9))
               : (pill.light ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0.16, 0.16, 0.16, 0.42))
    }

    // Accent ring. The glow is a layer on the ring alone, made only while
    // focused with Frame glow on, so at most one exists at a time.
    Rectangle {
        anchors.fill: parent
        visible: pill.focused
        radius: width / 2
        color: "transparent"
        border.width: pill.ringW
        border.color: theme.accent
        layer.enabled: visible && tileHaloLive
        layer.effect: Glow {
            cached: true
            transparentBorder: true
            radius: 8; samples: 17; spread: 0.25
            color: accentA(0.9)
        }
    }

    // The hair of gap between ring and disc: a dark band over the ring's
    // inner glow, so the gap reads cleanly (Xbox).
    Rectangle {
        anchors.fill: parent
        anchors.margins: pill.ringW
        visible: pill.focused
        radius: width / 2
        color: "transparent"
        border.width: pill.gap
        border.color: pill.light ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.75)
    }

    // Both icons stay loaded and swap by visibility: swapping one Image's
    // source on focus would reload it, and an async reload shows a blank frame.
    Image {
        z: 2
        anchors.centerIn: parent
        width: pill.iconSize; height: pill.iconSize
        sourceSize: Qt.size(Math.round(pill.iconSize * 2), Math.round(pill.iconSize * 2))
        source: pill.icon
        visible: !(pill.focused && pill.iconFilled !== "")
        opacity: pill.focused ? 1 : 0.9
        fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
        layer.enabled: pill.light
        layer.effect: ColorOverlay { color: "black" }
    }
    Image {
        z: 2
        anchors.centerIn: parent
        width: pill.iconSize; height: pill.iconSize
        sourceSize: Qt.size(Math.round(pill.iconSize * 2), Math.round(pill.iconSize * 2))
        source: pill.iconFilled
        visible: pill.focused && pill.iconFilled !== ""
        fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
        layer.enabled: pill.light
        layer.effect: ColorOverlay { color: "black" }
    }
}
