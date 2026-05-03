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

    // Shuffled list of game objects that have a video asset
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
        // Fisher-Yates shuffle
        for (var j = withVideos.length - 1; j > 0; j--) {
            var k = Math.floor(Math.random() * (j + 1));
            var tmp = withVideos[j];
            withVideos[j] = withVideos[k];
            withVideos[k] = tmp;
        }
        gameList = withVideos;
    }

    function next() {
        if (gameList.length === 0) return;
        sfxNav.play();
        currentIndex = (currentIndex + 1) % gameList.length;
    }

    function previous() {
        if (gameList.length === 0) return;
        sfxNav.play();
        currentIndex = (currentIndex - 1 + gameList.length) % gameList.length;
    }

    Component.onCompleted: buildList()

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

        // Ensure playback restarts when the source changes (e.g. when navigating)
        onSourceChanged: play()
    }

    // Bottom gradient for text readability
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: vpx(180)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#E0000000" }
        }
    }

    // Top gradient for title bar
    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: vpx(90)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#B0000000" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // "Random" label – top left
    Text {
        anchors { top: parent.top; topMargin: vpx(20); left: parent.left; leftMargin: globalMargin }
        text: "Random"
        color: theme.accent
        font.family: subtitleFont.name
        font.pixelSize: vpx(26)
        font.bold: true
    }

    // Position counter – top right (e.g. "3 / 47")
    Text {
        anchors { top: parent.top; topMargin: vpx(24); right: parent.right; rightMargin: globalMargin }
        text: gameList.length > 0 ? (currentIndex + 1) + " / " + gameList.length : ""
        color: theme.text
        opacity: 0.7
        font.family: subtitleFont.name
        font.pixelSize: vpx(18)
    }

    // Game title – bottom left
    Text {
        anchors {
            bottom: parent.bottom; bottomMargin: vpx(70)
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

    // Collection / platform name – bottom left, below title
    Text {
        anchors {
            bottom: parent.bottom; bottomMargin: vpx(42)
            left: parent.left; leftMargin: globalMargin
        }
        text: currentGame && currentGame.collections.count > 0
              ? currentGame.collections.get(0).name : ""
        color: theme.text
        opacity: 0.7
        font.family: subtitleFont.name
        font.pixelSize: vpx(16)
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

    // Helpbar
    ListModel {
    id: randomHelpModel

        ListElement { name: "Back";     button: "cancel"   }
        ListElement { name: "Launch";   button: "accept"   }
        ListElement { name: "Previous"; button: "prevPage" }
        ListElement { name: "Next";     button: "nextPage" }
    }

    onActiveFocusChanged: {
        if (activeFocus)
            currentHelpbarModel = randomHelpModel;
    }

    // Navigation
    Keys.onLeftPressed:  previous()
    Keys.onRightPressed: next()

    Keys.onPressed: {
        // Accept – go to game details
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (currentGame)
                gameDetails(currentGame);
        }
        // Cancel – return to showcase
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            previousScreen();
        }
        // LT – previous game
        if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            previous();
        }
        // RT – next game
        if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            next();
        }
    }
}
