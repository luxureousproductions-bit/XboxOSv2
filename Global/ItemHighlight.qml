// gameOS theme
// Copyright (C) 2018-2020 Seth Powell 
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

import QtQuick 2.15
import QtGraphicalEffects 1.15
import QtMultimedia 5.15

Item {
id: root

    property var game
    property bool selected
    property bool boxArt
    property bool playVideo: (settings.AllowThumbVideo === "Yes") && !boxArt

    onGameChanged: {
        if (playVideo && selected && playbackActive) beginPreview();
        else unloadPreview();
    }

    // Stops the preview when its screen stops being current.
    //
    // Assignable, not readonly: HorizontalCollection sets it explicitly (it is
    // Showcase-only), while GridViewMenu instantiates this without setting it
    // and relies on the default below. The default covers both hosts, so an
    // unset caller still behaves correctly.
    // Which screen this instance lives on, set by its host. A shared list of
    // screens cannot work here: the same component is used by the Showcase,
    // the grid and GameView, so "any of those three is active" left a Showcase
    // preview running while GameView was on top. It has to compare against
    // its OWN screen.
    //
    // Defaults to empty, which keeps playing — a host that forgets to set it
    // loses the gating but nothing breaks or fails to load.
    property string ownScreen: ""

    // Reports to the coordinator whenever this preview is actually loaded.
    // Derived from the Loader's own state rather than the six places that set
    // it, so it cannot drift from what's really on screen. Showcase only: the
    // featured box is the only thing that yields, and it lives there.
    readonly property bool previewLoaded: videoPreviewLoader.sourceComponent !== undefined
    onPreviewLoadedChanged: {
        if (ownScreen !== "showcasescreen") return;
        showcaseRowPreviews += previewLoaded ? 1 : -1;
    }
    // If destroyed while loaded, release the count so the box isn't left paused.
    Component.onDestruction: {
        if (ownScreen === "showcasescreen" && previewLoaded) showcaseRowPreviews -= 1;
    }
    property bool playbackActive: ownScreen === "" || playbackOwner === ownScreen

    // True once the reveal delay has elapsed. The Video is created earlier
    // (to warm the decoder) but only starts when this is set.
    property bool armed: false

    // How long a tile must stay highlighted before its preview plays, and how
    // far ahead of that the decoder starts warming. Warming is deliberately
    // NOT from t=0: the featured box yields while a preview is loaded, so an
    // early warm-up would freeze it for the whole wait. One second is ample
    // for the decoder to reach ready, and keeps the box's pause short.
    property int previewDelay:  2500
    property int previewWarmup: 1000
    function unloadPreview() {
        armed = false;
        rowPreviewPlaying = false;
        videoPreviewLoader.sourceComponent = undefined;
        warmupDelay.stop();
        videoDelay.stop();
    }
    // Start warming immediately; the delay now only gates the reveal.
    function beginPreview() {
        armed = false;
        warmupDelay.restart();
        videoDelay.restart();
    }
    onPlaybackActiveChanged: {
        if (!playbackActive) unloadPreview();
        else if (playVideo && selected) beginPreview();
    }

    onSelectedChanged: {
        if (selected && playVideo && playbackActive) beginPreview();
        else unloadPreview();
    }

    // Timer to show the video
    Timer {
    id: videoDelay

        interval: root.previewDelay
        onTriggered: {
            // Re-check at fire time: the owner can change during the delay
            // (drawer closing hands the Showcase back before the target screen
            // takes over). If it did, drop the warmed decoder rather than arm.
            if (!playbackActive || !selected) { unloadPreview(); return; }
            armed = true;
        }
    }

    // Creates the Video (autoPlay off) shortly before the reveal so the
    // decoder is ready when videoDelay arms it.
    Timer {
    id: warmupDelay

        interval: Math.max(0, root.previewDelay - root.previewWarmup)
        onTriggered: {
            if (!playbackActive || !selected) return;
            if (game && game.assets.videos.length)
                videoPreviewLoader.sourceComponent = videoPreviewWrapper;
        }
    }

    Timer {
    id: stopvideo

        interval: 1000
        onTriggered: unloadPreview()
    }

    // NOTE: Video Preview
    Component {
    id: videoPreviewWrapper

        Video {
        id: videocomponent

            anchors.fill: parent
            anchors.margins: vpx(2)   // Meets the selection frame's INNER edge exactly:
                                      // the frame overhangs -3 and is 5 wide, so its inner
                                      // edge sits +2 in. The video's square corners are then
                                      // hidden beneath the ring — no gap, and no masking of
                                      // the VideoOutput (which renders black on weak GPUs).
            source: game.assets.videoList.length ? game.assets.videoList[0] : ""
            fillMode: VideoOutput.PreserveAspectCrop
            muted: settings.AllowThumbVideoAudio === "No" || !root.playbackActive
            loops: MediaPlayer.Infinite

            // Preload: created at the START of the reveal delay with autoPlay
            // off, so the hardware decoder initialises during the wait. play()
            // then fires once both the delay has elapsed AND the media reports
            // ready — audio and video start together instead of audio leading
            // while the first frame is still being decoded.
            autoPlay: false
            readonly property bool ready: status === MediaPlayer.Loaded
                                       || status === MediaPlayer.Buffered
            readonly property bool go: root.armed && ready && root.playbackActive
            onGoChanged: if (go && playbackState !== MediaPlayer.PlayingState) play()
            onReadyChanged: if (go && playbackState !== MediaPlayer.PlayingState) play()

            // Invisible until playing; a loaded-but-idle VideoOutput paints
            // black. Snaps to opaque rather than fading: this sits UNDER the
            // tile art, so it's hidden anyway until the art fades. Fading it
            // in at the same time as the art faded out left a midpoint where
            // neither was opaque and the Showcase background showed through.
            opacity: playbackState === MediaPlayer.PlayingState ? 1 : 0

            // Report "on screen" only once frames are actually flowing, not on
            // PlayingState — that fires before the first frame is painted, and
            // fading the art then exposed a blank video for a beat. Position
            // advancing is the reliable sign that decode output has started.
            readonly property bool framesFlowing:
                playbackState === MediaPlayer.PlayingState && position > 0
            onFramesFlowingChanged: rowPreviewPlaying = framesFlowing
        }

    }

    DropShadow {
    id: outershadow

        anchors.fill: videocontainer
        horizontalOffset: 0
        verticalOffset: 0
        radius: 20.0
        samples: 11
        color: "#000000"
        source: videocontainer
        opacity: selected ? 0.5 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
        z: -5
    }

    Item {
    id: videocontainer

        anchors.fill: parent

        // NOTE: do NOT wrap this in a layer/OpacityMask to round the corners.
        // A Video/VideoOutput with PreserveAspectCrop is cropped on the GPU, and
        // rendering it through a layer FBO breaks that fill — the clip falls back
        // to its native aspect and shows thin pillarbox bars. Keep it unlayered.

        // Video
        Loader {
        id: videoPreviewLoader

            asynchronous: true
            anchors { fill: parent }
        }
    }
}