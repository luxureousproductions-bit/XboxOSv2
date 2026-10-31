// XboxOSv2 – RATabBar.qml
// The tabs across the top of every RetroAchievements page, as on the
// console: plain white labels, the selected one bold with an accent line
// under it. LB / RB move between them (each page handles the keys); a tap
// emits tabClicked. Used by RAHeader (Welcome / Social / Gaming) and the
// game page (Welcome / Progress / Social).

import QtQuick 2.15

Row {
id: bar

    property var tabs: []
    property int current: 0
    signal tabClicked(int index)

    readonly property color cAccent: theme.accent
    // The line is your accent, lifted toward white so it reads on the dark bands.
    readonly property color lineColor: Qt.rgba(cAccent.r + (1 - cAccent.r) * 0.25,
                                               cAccent.g + (1 - cAccent.g) * 0.25,
                                               cAccent.b + (1 - cAccent.b) * 0.25, 1)

    spacing: vpx(34)
    Repeater {
        model: bar.tabs
        delegate: Item {
            readonly property bool on: index === bar.current
            width: label.implicitWidth; height: vpx(34)
            Text {
            id: label
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
                text: modelData
                color: "white"
                opacity: parent.on ? 1 : 0.85
                font.family: parent.on ? titleFont.name : bodyFont.name
                font.pixelSize: fpx(19)
            }
            Rectangle {
                visible: parent.on
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: vpx(3); radius: vpx(1)
                color: bar.lineColor
            }
            TapHandler { onTapped: bar.tabClicked(index) }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
    }
}
