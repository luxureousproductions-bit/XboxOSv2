// XboxOSv2 – RAMythicFrame.qml
// Game art in the frame a mastered game gets (RA's 100% in hardcore), after
// the Xbox Series "Mythic" frame: a light accent rim with a soft glow, a dark
// inner line and a star seal on the bottom edge. Original shapes in your
// accent colour, not Xbox's artwork. Without `mastered` it's the plain art.
//
// Cost: flat rectangles plus one tinted SVG; the glow is two translucent
// rectangles, not a blur.

import QtQuick 2.15
import QtGraphicalEffects 1.15

Item {
id: frame

    property string source: ""
    property bool   mastered: false
    readonly property color cAccent: theme.accent
    function mixc(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1); }
    function light(t) { return mixc(cAccent, Qt.rgba(1, 1, 1, 1), t); }

    // Glow: two soft halos behind the rim.
    Rectangle {
        visible: frame.mastered
        anchors.fill: parent; anchors.margins: -vpx(9)
        radius: vpx(10); color: frame.light(0.35); opacity: 0.18
    }
    Rectangle {
        visible: frame.mastered
        anchors.fill: parent; anchors.margins: -vpx(6)
        radius: vpx(8); color: frame.light(0.35); opacity: 0.35
    }
    // Rim, then a thin dark line inside it.
    Rectangle {
        visible: frame.mastered
        anchors.fill: parent; anchors.margins: -vpx(4)
        radius: vpx(7); color: frame.light(0.55)
    }
    Rectangle {
        anchors.fill: parent; anchors.margins: frame.mastered ? -vpx(1.5) : 0
        radius: vpx(5); color: frame.mastered ? frame.mixc(frame.cAccent, Qt.rgba(0, 0, 0, 1), 0.4) : (whiteBackground ? "#d6d6d6" : "#2a2a2a")
    }
    Image {
    id: art
        anchors.fill: parent
        source: frame.source
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        sourceSize { width: hrpx(128); height: hrpx(128) }
    }
    // Seal on the bottom edge.
    Image {
        visible: frame.mastered
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.bottom }
        width: parent.width * 0.26; height: width
        source: "../assets/images/ra/ra_star.svg"
        sourceSize: Qt.size(hrpx(48), hrpx(48))
        smooth: true
        layer.enabled: frame.mastered
        layer.effect: ColorOverlay { color: frame.light(0.75) }
    }
}
