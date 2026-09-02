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
        videoPreviewLoader.sourceComponent = undefined;
        if (playVideo && selected) {
            videoDelay.restart();
        }
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
    property bool playbackActive: (ownScreen === "" || activeScreen === ownScreen) && appActive
    onPlaybackActiveChanged: {
        if (!playbackActive) {
            videoPreviewLoader.sourceComponent = undefined;
            videoDelay.stop();
        } else if (playVideo && selected) {
            videoDelay.restart();
        }
    }

    onSelectedChanged: {
        if (selected) {
            videoPreviewLoader.sourceComponent = undefined;
            if (playVideo) videoDelay.restart();
        } else {
            videoPreviewLoader.sourceComponent = undefined;
            videoDelay.stop();
        }
    }

    // Timer to show the video
    Timer {
    id: videoDelay

        interval: 600
        onTriggered: {
            if (game && game.assets.videos.length) {
                videoPreviewLoader.sourceComponent = videoPreviewWrapper;
            }
        }
    }

    Timer {
    id: stopvideo

        interval: 1000
        onTriggered: {
            videoPreviewLoader.sourceComponent = undefined;
            videoDelay.stop();
        }
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
            muted: settings.AllowThumbVideoAudio === "No"
            loops: MediaPlayer.Infinite
            autoPlay: true

            //onPlaying: videocomponent.seek(5000)
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