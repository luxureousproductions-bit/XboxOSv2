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

import QtQuick 2.3
import QtMultimedia 5.9
import "../Global"
import "../utils.js" as Utils

FocusScope {
id: root

    anchors.fill: parent

    // Whether the info overlay (title + logo) is visible
    property bool showInfo: true

    // List of games with video assets; populated on first load
    property var gameList: []
    property int currentIndex: 0
    property var currentGame: (gameList.length > 0 && currentIndex < gameList.length)
                              ? gameList[currentIndex] : null

    function buildList() {
        var allGames = api.allGames.toVarArray();
        var withVideos = [];
        for (var i = 0; i < allGames.length; i++) {
            if (allGames[i].assets.video)
                withVideos.push(allGames[i]);
        }
        gameList = withVideos;
    }

    // Pick a random game different from the current one
    function randomJump() {
        if (gameList.length === 0) return;
        sfxNav.play();
        if (gameList.length === 1) return;
        var newIndex;
        do {
            newIndex = Math.floor(Math.random() * gameList.length);
        } while (newIndex === currentIndex);
        currentIndex = newIndex;
    }

    Component.onCompleted: {
        buildList();
        // Start on a random game
        if (gameList.length > 0)
            currentIndex = Math.floor(Math.random() * gameList.length);
    }

    // Black background
    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    // Fullscreen video player
    Video {
    id: videoPlayer

        anchors.fill: parent
        source: currentGame ? currentGame.assets.video : ""
        fillMode: VideoOutput.PreserveAspectCrop
        muted: false
        loops: MediaPlayer.Infinite
        autoPlay: true

        // Restart playback whenever the source changes
        onSourceChanged: play()
    }

    // Bottom gradient for text readability
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: vpx(180)
        visible: showInfo
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#E0000000" }
        }
    }

    // Info overlay: game title + system logo
    Item {
    id: infoOverlay

        visible: showInfo
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: vpx(110)

        // Game title
        Text {
        id: gameTitle

            anchors {
                bottom: systemLogo.top; bottomMargin: vpx(4)
                left: parent.left; leftMargin: globalMargin
                right: parent.right; rightMargin: globalMargin
            }
            text: currentGame ? currentGame.title : ""
            color: theme.text
            font.family: subtitleFont.name
            font.pixelSize: vpx(30)
            font.bold: true
            style: Text.Outline
            styleColor: "#80000000"
            elide: Text.ElideRight
        }

        // System logo image (shortName-based)
        Image {
        id: systemLogo

            property string shortName: currentGame && currentGame.collections.count > 0
                                       ? currentGame.collections.get(0).shortName : ""

            anchors {
                bottom: parent.bottom; bottomMargin: vpx(55)
                left: parent.left; leftMargin: globalMargin
            }
            height: vpx(30)
            width: vpx(120)
            source: shortName !== ""
                    ? "../assets/images/logospng/" + Utils.processPlatformName(shortName) + ".png"
                    : ""
            sourceSize { width: 240; height: 60 }
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            visible: status !== Image.Error && shortName !== ""
            horizontalAlignment: Image.AlignLeft
        }

        // Fallback: collection name as text when logo image is unavailable
        Text {
        id: systemName

            anchors {
                bottom: parent.bottom; bottomMargin: vpx(55)
                left: parent.left; leftMargin: globalMargin
            }
            text: currentGame && currentGame.collections.count > 0
                  ? currentGame.collections.get(0).name : ""
            color: theme.text
            opacity: 0.7
            font.family: subtitleFont.name
            font.pixelSize: vpx(16)
            visible: systemLogo.status === Image.Error || systemLogo.shortName === ""
        }
    }

    // "No videos available" fallback message
    Text {
        visible: gameList.length === 0
        anchors.centerIn: parent
        text: "No game videos found.\nAdd videos to your game library to use Random mode."
        color: theme.text
        opacity: 0.7
        font.family: subtitleFont.name
        font.pixelSize: vpx(20)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        width: parent.width * 0.7
    }

    // Helpbar: A Launch | X Hide | B Back  (RightToLeft → B rightmost, A leftmost)
    ListModel {
    id: randomHelpModel

        ListElement { name: "Back";   button: "cancel"  }
        ListElement { name: "Hide";   button: "details" }
        ListElement { name: "Launch"; button: "accept"  }
    }

    onActiveFocusChanged: {
        if (activeFocus)
            currentHelpbarModel = randomHelpModel;
    }

    // Navigation: left/right and LT/RT all jump to a random game
    Keys.onLeftPressed:  randomJump()
    Keys.onRightPressed: randomJump()

    Keys.onPressed: {
        // Accept – launch the game directly
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (currentGame)
                launchGame(currentGame);
        }
        // Cancel – return to showcase
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            previousScreen();
        }
        // Details (X) – toggle info overlay
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            showInfo = !showInfo;
        }
        // LT or RT – random jump
        if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            randomJump();
        }
        if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            randomJump();
        }
    }
}
