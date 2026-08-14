// XboxOSv2 — ScrollingText
//
// Drop-in replacement for a Text that would otherwise elide. When the content
// is wider than the space available (common at higher UI Scale settings, or
// for long genre strings), it makes ONE slow pass to reveal the rest, then
// settles back at the start. Text that fits is left completely alone — no
// animation, no clipping cost.
//
// The pass re-triggers whenever the text changes, so moving between games
// always shows the new value from the beginning.
//
// Usage mirrors Text:
//   ScrollingText {
//       anchors { left: label.right; right: parent.right; verticalCenter: ... }
//       text: gameData ? gameData.genre : ""
//       font.pixelSize: fpx(16)
//       font.family: subtitleFont.name
//       color: theme.text
//   }

import QtQuick 2.15

Item {
id: root

    property string text: ""
    property alias font: label.font
    property alias color: label.color
    property alias horizontalAlignment: label.horizontalAlignment

    // Tuning
    property int  startDelay: 1200      // pause on the start before moving
    property int  endDelay:   1600      // pause at the end before snapping back
    property real pixelsPerSecond: 40   // slow, readable drift

    implicitHeight: label.implicitHeight
    clip: overflowing

    readonly property bool overflowing: label.implicitWidth > width

    Text {
    id: label

        text: root.text
        // Anchored only vertically — x is animated when it overflows.
        anchors.verticalCenter: parent.verticalCenter
        x: 0
        // Elide only matters before the pass starts; once scrolling we show
        // the full string, so elide is disabled while it's in motion.
        elide: root.overflowing ? Text.ElideNone : Text.ElideRight
        width: root.overflowing ? implicitWidth : root.width
    }

    // One slow pass: hold at the start, drift to reveal the tail, hold, snap
    // back. Restarts from the beginning whenever the text or width changes.
    SequentialAnimation {
    id: pass

        running: false
        PauseAnimation { duration: root.startDelay }
        NumberAnimation {
            target: label
            property: "x"
            to: Math.min(0, root.width - label.implicitWidth)
            duration: Math.max(1, (label.implicitWidth - root.width) / root.pixelsPerSecond * 1000)
            easing.type: Easing.Linear
        }
        PauseAnimation { duration: root.endDelay }
        NumberAnimation {
            target: label
            property: "x"
            to: 0
            duration: 250
            easing.type: Easing.InOutQuad
        }
    }

    function restart() {
        pass.stop();
        label.x = 0;
        if (overflowing && width > 0) pass.start();
    }

    onTextChanged: restart()
    onWidthChanged: restart()
    onOverflowingChanged: restart()
    Component.onCompleted: restart()
}
