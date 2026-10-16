// XboxOSv2 – RAStatLine.qml
// The RA profile's stats line, alternating like the Xbox profile card:
// "12,345 HC · 1,234 SC · 45,678 true", fading to "Rank #1,234" and back
// every 15 seconds. Without a rank (RA hasn't returned one, or the account
// has none) it simply shows the points line and never rotates.
//
// Used by every RA profile header (overview, game RA page, game entry /
// no-achievements page) and the Home page RA header card. Each host
// passes its own colour/font/size so it matches the line it replaces:
//
//   RAStatLine { color: theme.text; fontFamily: bodyFont.name; pixelSize: fpx(15); opacity: 0.65 }

import QtQuick 2.15

Item {
id: statLine

    property color  color: "white"
    property string fontFamily: ""
    property int    pixelSize: 15
    // How long (ms) each face stays up. 15s: long enough to read and
    // forget about, like the profile card on the console.
    property int    holdMs: 15000

    readonly property bool hasRank: cheevosData.rankText !== ""
    // Which face is up. Only ever true while a rank exists.
    property bool showRank: false
    onHasRankChanged: if (!hasRank) resetFace()

    implicitWidth:  face.implicitWidth
    implicitHeight: face.implicitHeight
    visible: cheevosData.scoreText !== ""

    // Out, swap, beat, in — rather than a crossfade, where the two lines
    // overlap mid-way and read as a blur. Sine easing on both halves so it
    // eases away and settles in. HQ takes a little longer over it.
    readonly property int fadeMs:  hqMode ? 800 : 650
    readonly property int pauseMs: 150

    function resetFace() {
        swap.stop();
        showRank = false;
        face.opacity = 1;
    }

    Text {
    id: face
        text: statLine.showRank ? cheevosData.rankText : cheevosData.scoreText
        color: statLine.color
        font.family: statLine.fontFamily
        font.pixelSize: statLine.pixelSize
    }

    SequentialAnimation {
    id: swap
        NumberAnimation { target: face; property: "opacity"; to: 0; duration: statLine.fadeMs; easing.type: Easing.InOutSine }
        ScriptAction    { script: statLine.showRank = !statLine.showRank }
        PauseAnimation  { duration: statLine.pauseMs }
        NumberAnimation { target: face; property: "opacity"; to: 1; duration: statLine.fadeMs; easing.type: Easing.InOutSine }
    }

    // Only ticks while there's something to alternate, the line is on
    // screen, and the app is in the foreground — no timer churn otherwise.
    // Stopping always lands back on the points, fully visible.
    Timer {
        interval: statLine.holdMs
        repeat: true
        running: statLine.hasRank && statLine.visible && appActive
        onTriggered: swap.restart()
        onRunningChanged: if (!running) statLine.resetFace()
    }
}
