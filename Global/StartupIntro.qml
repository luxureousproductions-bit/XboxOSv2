// XboxOSv2 – startup intro.
// Covers the first moments after Pegasus hands over to the theme (cold start
// only, never when coming back from a game). Plays assets/video/intro.mp4 if
// that file is there, otherwise shows assets/images/intro.jpg (the startup chime plays when the theme appears, as without the intro). It takes no
// focus and needs no input; it fades out on its own.
import QtQuick 2.15
import QtMultimedia 5.15

Item {
id: intro

    signal finished()
    // The fade into Home starts: the theme plays its startup chime here.
    signal revealing()

    property real volume: 1.0
    readonly property int stillMs: 1500     // still image on screen at least this long
    readonly property int maxVideoMs: 8000  // safety cap for a long or stuck video
    readonly property int maxWaitMs: 15000  // never cover the theme longer than this
    // Home is built in the background while the intro shows (theme.qml), so
    // the intro is also the loading screen: it stays until Home is ready.
    property bool homeReady: true
    property bool minShown: false
    onHomeReadyChanged: if (homeReady && minShown) close()

    property bool videoFailed: false
    property bool closing: false

    function close() {
        if (closing) return;
        closing = true;
        revealing();
        fadeOut.start();
    }

    Rectangle { anchors.fill: parent; color: "black" }

    Image {
        anchors.fill: parent
        source: "../assets/images/intro.jpg"
        sourceSize: Qt.size(intro.width, intro.height)
        fillMode: Image.PreserveAspectCrop
        asynchronous: false        // must be there on the very first frame
        visible: intro.videoFailed || video.position <= 0
    }

    Video {
    id: video
        anchors.fill: parent
        source: "../assets/video/intro.mp4"
        fillMode: VideoOutput.PreserveAspectCrop
        autoPlay: true
        volume: intro.volume
        visible: position > 0
        onErrorChanged: if (error !== MediaPlayer.NoError) intro.useStill()
        onStatusChanged: {
            if (status === MediaPlayer.EndOfMedia) { intro.minShown = true; if (intro.homeReady) intro.close(); }
            else if (status === MediaPlayer.InvalidMedia) intro.useStill();
        }
    }

    function useStill() {
        if (videoFailed) return;
        videoFailed = true;
        video.stop();
        stillTimer.start();
    }

    // No video frame within a second (file missing, decoder slow): use the still.
    Timer {
        interval: 1000; running: true
        onTriggered: if (video.position <= 0) intro.useStill()
    }
    Timer {
    id: stillTimer
        interval: intro.stillMs
        onTriggered: { intro.minShown = true; if (intro.homeReady) intro.close(); }
    }
    Timer { interval: intro.maxVideoMs; running: true; onTriggered: if (intro.homeReady) intro.close(); else intro.useStill() }
    Timer { interval: intro.maxWaitMs; running: true; onTriggered: intro.close() }

    NumberAnimation {
    id: fadeOut
        target: intro; property: "opacity"; to: 0; duration: 450
        onFinished: { video.stop(); intro.finished(); }
    }
}
