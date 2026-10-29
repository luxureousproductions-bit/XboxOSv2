// XboxOSv2 – PointsGlyph.qml
// The small "P in a circle" that sits beside RetroAchievements point totals,
// where the Xbox puts its Gamerscore mark. Plain shapes: no image to load.

import QtQuick 2.15

Rectangle {
    property real  size: vpx(16)
    property color fill: "#dddddd"
    property color textColor: "#202020"

    width: size; height: size; radius: size / 2
    color: fill
    Text {
        anchors.centerIn: parent
        text: "P"
        color: parent.textColor
        font.family: titleFont.name
        font.pixelSize: parent.size * 0.68
    }
}
