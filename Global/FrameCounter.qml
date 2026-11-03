// XboxOS-V2
// Frame rate counter (Settings > Appearance > Diagnostics).
//
// Counts the frames the theme actually draws each second and the slowest one.
// "worst" is what you feel as a stutter: at 60 fps a frame has 16.7 ms, so
// anything well past that is a visible hitch.
//
// The theme only draws when something changes, so a still screen reads "idle"
// rather than a low number.

import QtQuick 2.15
import QtQuick.Window 2.15

Rectangle {
id: counter

    property int frames: 0
    property real lastStamp: 0
    property real worstMs: 0
    property int fpsShown: 0
    property real worstShown: 0
    property bool idle: true

    width: label.implicitWidth + vpx(16)
    height: label.implicitHeight + vpx(8)
    radius: vpx(4)
    color: "#CC000000"

    // afterAnimating fires on the UI thread once per frame being produced.
    Connections {
        target: counter.Window.window
        onAfterAnimating: {
            var now = Date.now();
            if (counter.lastStamp > 0) {
                var dt = now - counter.lastStamp;
                // A gap over 250 ms is the screen having been still, not a slow frame.
                if (dt < 250 && dt > counter.worstMs) counter.worstMs = dt;
            }
            counter.lastStamp = now;
            counter.frames++;
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            // This counter's own once-a-second redraw costs a frame or two.
            counter.idle = counter.frames <= 2;
            counter.fpsShown = counter.frames;
            counter.worstShown = counter.worstMs;
            // Into lastrun.log too, so a stutter can be read back later
            // against what the log says was happening. Only while the
            // counter is on, and never for a still screen.
            if (!counter.idle)
                console.log("[perf]", Qt.formatTime(new Date(), "hh:mm:ss"), "fps", counter.frames, "worst", Math.round(counter.worstMs));
            counter.frames = 0;
            counter.worstMs = 0;
        }
    }

    Text {
    id: label
        anchors.centerIn: parent
        color: counter.idle ? "#AAAAAA"
             : (counter.worstShown > 34 ? "#FF6B6B" : (counter.worstShown > 20 ? "#FFD166" : "#7CFC9A"))
        font.pixelSize: vpx(14)
        font.bold: true
        text: counter.idle ? "idle"
            : counter.fpsShown + " fps  ·  worst " + Math.round(counter.worstShown) + " ms"
    }
}
