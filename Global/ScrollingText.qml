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
    clip: true

    readonly property bool overflowing: label.implicitWidth > width

    Text {
    id: label

        text: root.text
        // Anchored only vertically — x is animated when the text overflows.
        anchors.verticalCenter: parent.verticalCenter
        x: 0
        // Always laid out at natural width and simply clipped by the parent.
        // Previously elide/width were bound to `overflowing`, so the text was
        // re-measured every time that flag flipped — feeding the same timing
        // race that made scrolling intermittent.
        width: implicitWidth
        elide: Text.ElideNone
    }

    // One slow pass: hold at the start, drift to reveal the tail, hold, snap
    // back. `to` and `duration` are SET IN restart() rather than bound: as
    // declarative bindings they were read at the moment the animation started,
    // which is often before the font has finished loading and implicitWidth is
    // final — giving a 1 ms duration (an instant jump) or no movement at all.
    // That timing race is why scrolling worked only sometimes.
    SequentialAnimation {
    id: pass

        running: false
        PauseAnimation { duration: root.startDelay }
        NumberAnimation {
            id: drift
            target: label
            property: "x"
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

    // Coalesces the several change signals that fire while a delegate is being
    // set up (text, width, font metrics) into ONE start, once things settle.
    Timer {
        id: settle
        interval: 120
        repeat: false
        onTriggered: root.beginPass()
    }

    function restart() {
        pass.stop();
        label.x = 0;
        settle.restart();
    }

    function beginPass() {
        pass.stop();
        label.x = 0;
        var over = label.implicitWidth - root.width;
        if (over <= 0 || root.width <= 0 || root.text === "") return;
        drift.to = -over;
        drift.duration = Math.max(400, over / root.pixelsPerSecond * 1000);
        pass.start();
    }

    onTextChanged: restart()
    onWidthChanged: restart()
    // Fires when the font finishes loading or the string is re-measured, which
    // is the moment the old binding-based version usually missed.
    Connections {
        target: label
        onImplicitWidthChanged: root.restart()
    }
    Component.onCompleted: restart()
}
