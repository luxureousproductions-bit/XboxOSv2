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
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "../Global"
import "../Lists"
import "../utils.js" as Utils

FocusScope {
id: root
    function gameActivated() {
        storedCollectionGameIndex = gamegrid.currentIndex
        gameDetails(list.currentGame(gamegrid.currentIndex));
    }

    property var sortedGames;
    property bool isLeftTriggerPressed: false;
    property bool isRightTriggerPressed: false;

    // ── Sorting & Filters overlay state ───────────────────────────────────
    // Drives the GLOBAL searchTerm / sortByIndex / orderBy / showFavs that the
    // proxy inside ListCollectionGames already filters & sorts on — so the
    // grid itself stays untouched. Fully controller-driven, no native IME.
    property bool filterOpen:   false
    property bool searchActive: false
    property int  filterRow:    0
    property bool genrePickerOpen:  false
    property var  genreOptions:     []
    property int  genrePickerIndex: 0
    property var  sortFields: [
        { label: "Title",       idx: 0 },
        { label: "Last Played", idx: 1 },
        { label: "Most Played", idx: 2 },
        { label: "Rating",      idx: 3 }
    ]
    property bool kbSpecial: false
    property var kbMain: [
        "A","B","C","D","E","F","G","H","I","J",
        "K","L","M","N","O","P","Q","R","S","T",
        "U","V","W","X","Y","Z","-","'",".",":",
        "0","1","2","3","4","5","6","7","8","9",
        "áé","SPACE","DEL","CLR","OK"
    ]
    property var kbSpec: [
        "À","Á","Â","Ã","Ä","Å","Æ","Ç","È","É",
        "Ê","Ë","Ì","Í","Î","Ï","Ñ","Ò","Ó","Ô",
        "Õ","Ö","Ø","Ù","Ú","Û","Ü","Ý","ß","°",
        "&","!","?","@","#","%","+","=",",",";",
        "ABC","SPACE","DEL","CLR","OK"
    ]
    property var keyboardKeys: kbSpecial ? kbSpec : kbMain
    property int keyCols:  10
    property int keyIndex: 0

    function activateSearch() { searchMode = "Title"; keyIndex = 0; kbSpecial = false; searchActive = true; }
    function pressKey(k) {
        if (k === "áé")  { kbSpecial = true;  return; }
        if (k === "ABC") { kbSpecial = false; return; }
        if (k === "SPACE")    searchTerm += " ";
        else if (k === "DEL") searchTerm = searchTerm.slice(0, -1);
        else if (k === "CLR") searchTerm = "";
        else if (k === "OK")  searchActive = false;
        else                  searchTerm += k;
        gamegrid.currentIndex = 0;
        sortedGames = null;
    }
    function selectSort(idx) {
        if (sortByIndex === idx) {
            orderBy = (orderBy === Qt.AscendingOrder) ? Qt.DescendingOrder : Qt.AscendingOrder;
        } else {
            sortByIndex = idx;
            orderBy = (idx === 0) ? Qt.AscendingOrder : Qt.DescendingOrder;
        }
        gamegrid.currentIndex = 0;
        sortedGames = null;
    }

    // genreToPattern() is global (theme.qml). Genres are collected from the
    // full (unfiltered) collection and rebuilt each time the picker opens.
    function buildGenreOptions() {
        var set = {};
        var src = list.collection.games;
        var n = src.count;
        for (var i = 0; i < n; i++) {
            var g = src.get(i);
            if (!g || !g.genre) continue;
            var parts = g.genre.split(",");
            for (var j = 0; j < parts.length; j++) {
                var t = parts[j].trim();
                if (t.length) set[t] = true;
            }
        }
        var arr = Object.keys(set).sort(function(a,b){ return a.toLowerCase().localeCompare(b.toLowerCase()); });
        arr.unshift("All");
        genreOptions = arr;
    }
    function openGenrePicker() {
        buildGenreOptions();
        var want = (genreFilter === "") ? "All" : genreFilter;
        var idx = genreOptions.indexOf(want);
        genrePickerIndex = idx >= 0 ? idx : 0;
        genrePickerOpen = true;
    }
    function selectGenre(g) {
        genreFilter = (g === "All") ? "" : g;
        gamegrid.currentIndex = 0;
        sortedGames = null;
        genrePickerOpen = false;
    }

    function nextChar(c, modifier) {
        const firstAlpha = 97;
        const lastAlpha = 122;

        var charCode = c.charCodeAt(0) + modifier;

        if (modifier > 0) { // Scroll down
            if (charCode < firstAlpha || isNaN(charCode)) {
                return 'a';
            }
            if (charCode > lastAlpha) {
                return '';
            }
        } else { // Scroll up
            if (charCode == firstAlpha - 1) {
                return '';
            }
            if (charCode < firstAlpha || charCode > lastAlpha || isNaN(charCode)) {
                return 'z';
            }
        }

        return String.fromCharCode(charCode);
    }

    function navigateToNextLetter(modifier) {
        if (isRightTriggerPressed || isLeftTriggerPressed) {
            return false;
        }

        if (sortByFilter[sortByIndex].toLowerCase() != "title") {
            return false;
        }

        var currentIndex = gamegrid.currentIndex;
        if (currentIndex == -1) {
            gamegrid.currentIndex = 0;
        }
        else {
            // NOTE: We should be using the scroll proxy here, but this is significantly faster.
            if (sortedGames == null) {
                sortedGames = list.collection.games.toVarArray().map(g => g.title.toLowerCase()).sort((a, b) => a.localeCompare(b));
            }

            var currentGameTitle = sortedGames[currentIndex];
            var currentLetter = currentGameTitle.toLowerCase().charAt(0);

            const firstAlpha = 97;
            const lastAlpha = 122;

            if (currentLetter.charCodeAt(0) < firstAlpha || currentLetter.charCodeAt(0) > lastAlpha) {
                currentLetter = '';
            }

            var nextIndex = currentIndex;
            var nextLetter = currentLetter;

            do {
                do {
                    nextLetter = nextChar(nextLetter, modifier);

                    if (currentLetter == nextLetter) {
                        break;
                    }

                    if (nextLetter == '') {
                        if (sortedGames.some(g => g.toLowerCase().charCodeAt(0) < firstAlpha || g.toLowerCase().charCodeAt(0) > lastAlpha)) {
                            break;
                        }
                    }
                    else if (sortedGames.some(g => g.charAt(0) == nextLetter)) {
                        break;
                    }
                } while (true)

                nextIndex = sortedGames.findIndex(g => g.toLowerCase().localeCompare(nextLetter) >= 0);
            } while(nextIndex === -1)

            gamegrid.currentIndex = nextIndex;

            nextLetter = sortedGames[nextIndex].toLowerCase().charAt(0);
            var nextLetterCharCode = nextLetter.charCodeAt(0);
            if (nextLetterCharCode < firstAlpha || nextLetterCharCode > lastAlpha) {
                nextLetter = '#';
            }

            navigationLetterOpacityAnimator.running = false
            navigationLetter.text = nextLetter.toUpperCase();
            navigationOverlay.opacity = 0.8;
            navigationLetterOpacityAnimator.running = true
        }

        gamegrid.focus = true;
        // stop() first so rapid letter-jumping always restarts the sound (Qt SoundEffect
        // otherwise drops a play() that arrives while the previous one is still playing).
        playToggle();

        return true;
    }

    ListCollectionGames { id: list; }

    // Load settings
    property bool showBoxes: settings.GridThumbnail === "Box Art" || settings.GridThumbnail === "3D Box"
    property int numColumns: settings.GridColumns ? settings.GridColumns : 6
    property int titleMargin: settings.AlwaysShowTitles === "Yes" ? vpx(30) : 0

    GridSpacer {
    id: fakebox

        width: vpx(100); height: vpx(100)
        games: list.games
    }

    Rectangle {
    id: navigationOverlay
        anchors.fill: parent;
        color: theme.main
        opacity: 0
        z: 10

        Text {
        id: navigationLetter
            antialiasing: true
            renderType: Text.NativeRendering
            font.hintingPreference: Font.PreferNoHinting
            font.family: titleFont.name
            font.capitalization: Font.AllUppercase
            font.pixelSize: vpx(200)
            color: "white"
            anchors.centerIn: parent
        }

        SequentialAnimation {
        id: navigationLetterOpacityAnimator
            PauseAnimation { duration: 500 }
            OpacityAnimator {

                target: navigationOverlay
                from: navigationOverlay.opacity
                to: 0;
                duration: 500
            }
        }
    }

    // ── Custom header (collection name + centered nav buttons) ────────────
    Item {
    id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(75)
        z: 5

        Rectangle { anchors.fill: parent; color: theme.main }

        // Platform logo (top-left); falls back to the collection name if missing
        Image {
        id: platformlogo
            anchors { top: parent.top; topMargin: vpx(8); left: parent.left; leftMargin: globalMargin }
            height: vpx(50)
            fillMode: Image.PreserveAspectFit
            source: list.collection ? "../assets/images/logospng/" + Utils.processPlatformName(list.collection.shortName) + ".png" : ""
            smooth: true
            asynchronous: false
            cache: true
            visible: status === Image.Ready
            MouseArea { anchors.fill: parent; onClicked: previousScreen(); }
        }
        Text {
        id: platformtitle
            anchors { top: parent.top; topMargin: vpx(8); left: parent.left; leftMargin: globalMargin; right: homebutton.left; rightMargin: vpx(20) }
            height: vpx(50)
            text: list.collection ? list.collection.name : ""
            color: theme.text; font.family: titleFont.name; font.pixelSize: vpx(30); font.bold: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            visible: platformlogo.status !== Image.Ready
            MouseArea { anchors.fill: parent; onClicked: previousScreen(); }
        }
        Text {
            anchors { left: parent.left; leftMargin: globalMargin; top: platformlogo.bottom; topMargin: vpx(2) }
            text: list.games.count + " games"
            color: theme.text; opacity: 0.7; font.family: subtitleFont.name; font.pixelSize: vpx(17)
            visible: settings.GameCounter !== "No"
        }

        // Nav buttons (home / discover / achievements / settings)
        Rectangle {
        id: homebutton
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -vpx(81) }
            color: focus ? theme.accent : "transparent"; opacity: focus ? 1 : 0.6
            Keys.onDownPressed:  { playNav(); gamegrid.currentIndex = 0; gamegrid.focus = true; }
            Keys.onRightPressed: { playNav(); discoverbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; showcaseScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); gamegrid.currentIndex = 0; gamegrid.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: showcaseScreen(); }
            Canvas {
                anchors { fill: parent; margins: vpx(7) }
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset();
                    var w = width, h = height;
                    ctx.fillStyle = "white";
                    ctx.globalAlpha = homebutton.focus ? 1.0 : 0.85;
                    ctx.beginPath();
                    ctx.moveTo(w*0.5, h*0.05);
                    ctx.lineTo(w*0.95, h*0.5);
                    ctx.lineTo(w*0.05, h*0.5);
                    ctx.closePath(); ctx.fill();
                    ctx.fillRect(w*0.18, h*0.5, w*0.64, h*0.42);
                    ctx.clearRect(w*0.42, h*0.62, w*0.16, h*0.30);
                }
                Connections { target: homebutton; onFocusChanged: parent.requestPaint() }
            }
        }

        Rectangle {
        id: discoverbutton
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -vpx(27) }
            color: focus ? theme.accent : "transparent"; opacity: focus ? 1 : 0.6
            Keys.onDownPressed:  { playNav(); gamegrid.currentIndex = 0; gamegrid.focus = true; }
            Keys.onLeftPressed:  { playNav(); homebutton.focus = true; }
            Keys.onRightPressed: { playNav(); achievementsbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; discoverScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); gamegrid.currentIndex = 0; gamegrid.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: discoverScreen(); }
            Canvas {
                anchors { fill: parent; margins: vpx(6) }
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset();
                    var cx = width/2, cy = height/2, r = Math.min(cx,cy)-1;
                    ctx.globalAlpha = discoverbutton.focus ? 1.0 : 0.85;
                    ctx.strokeStyle = "white"; ctx.lineWidth = 1.5;
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2); ctx.stroke();
                    ctx.fillStyle = "white";
                    ctx.beginPath(); ctx.moveTo(cx, cy-r*0.65); ctx.lineTo(cx+r*0.30, cy+r*0.10); ctx.lineTo(cx, cy+r*0.20); ctx.lineTo(cx-r*0.30, cy+r*0.10); ctx.closePath(); ctx.fill();
                    ctx.globalAlpha = 0.35;
                    ctx.beginPath(); ctx.moveTo(cx, cy+r*0.65); ctx.lineTo(cx-r*0.30, cy-r*0.10); ctx.lineTo(cx, cy-r*0.20); ctx.lineTo(cx+r*0.30, cy-r*0.10); ctx.closePath(); ctx.fill();
                }
                Connections { target: discoverbutton; onFocusChanged: parent.requestPaint() }
            }
        }

        Rectangle {
        id: achievementsbutton
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: vpx(27) }
            color: focus ? theme.accent : "transparent"; opacity: focus ? 1 : 0.6
            Keys.onDownPressed:  { playNav(); gamegrid.currentIndex = 0; gamegrid.focus = true; }
            Keys.onLeftPressed:  { playNav(); discoverbutton.focus = true; }
            Keys.onRightPressed: { playNav(); settingsbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; achievementsScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); gamegrid.currentIndex = 0; gamegrid.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: achievementsScreen(); }
            Text {
                anchors.centerIn: parent
                text: "🏆"; font.pixelSize: vpx(18)
                opacity: achievementsbutton.focus ? 1 : 0.7
            }
        }

        Rectangle {
        id: settingsbutton
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: vpx(81) }
            color: focus ? theme.accent : "transparent"; opacity: focus ? 1 : 0.6
            Keys.onDownPressed: { playNav(); gamegrid.currentIndex = 0; gamegrid.focus = true; }
            Keys.onLeftPressed: { playNav(); achievementsbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; settingsScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); gamegrid.currentIndex = 0; gamegrid.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: settingsScreen(); }
            Image {
                anchors { fill: parent; margins: vpx(10) }
                source: "../assets/images/settingsicon.svg"
                fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
            }
        }

        // Nav button labels — shown only when the button is highlighted
        Text {
            text: "Home"
            anchors { top: homebutton.bottom; topMargin: vpx(3); horizontalCenter: homebutton.horizontalCenter }
            color: "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: vpx(11); font.bold: true
            opacity: homebutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "Discover"
            anchors { top: discoverbutton.bottom; topMargin: vpx(3); horizontalCenter: discoverbutton.horizontalCenter }
            color: "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: vpx(11); font.bold: true
            opacity: discoverbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "RetroAchievements"
            anchors { top: achievementsbutton.bottom; topMargin: vpx(3); horizontalCenter: achievementsbutton.horizontalCenter }
            color: "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: vpx(11); font.bold: true
            opacity: achievementsbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "Settings"
            anchors { top: settingsbutton.bottom; topMargin: vpx(3); horizontalCenter: settingsbutton.horizontalCenter }
            color: "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: vpx(11); font.bold: true
            opacity: settingsbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
    }

    Item {
    id: gridContainer

        anchors {
            top: header.bottom; topMargin: globalMargin
            left: parent.left; leftMargin: globalMargin
            right: parent.right; rightMargin: globalMargin
            bottom: parent.bottom; bottomMargin: globalMargin
        }

        GridView {
        id: gamegrid

            property real cellHeightRatio: fakebox.paintedHeight / fakebox.paintedWidth
            property real savedCellHeight: {
                if (settings.GridThumbnail == "Tall") {
                    return cellWidth / settings.TallRatio;
                } else if (settings.GridThumbnail == "Square") {
                    return cellWidth;
                } else {
                    return cellWidth * settings.WideRatio;
                }
            }
            property var sourceThumbnail: showBoxes ? "BoxArtGridItem.qml" : "../Global/DynamicGridItem.qml"

            Component.onCompleted: {
                currentIndex = storedCollectionGameIndex;
                positionViewAtIndex(currentIndex, ListView.Visible);
            }

            populate: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 200 }
            }

            anchors {
                top: parent.top; left: parent.left; right: parent.right;
                bottom: parent.bottom; bottomMargin: helpMargin + vpx(40)
            }
            cellWidth: width / numColumns
            cellHeight: ((showBoxes) ? cellWidth * cellHeightRatio : savedCellHeight) + titleMargin
            preferredHighlightBegin: vpx(0)
            preferredHighlightEnd: gamegrid.height - helpMargin - vpx(40)
            highlightRangeMode: GridView.ApplyRange
            highlightMoveDuration: 200
            highlight: highlightcomponent
            keyNavigationWraps: false
            displayMarginBeginning: cellHeight * 2
            displayMarginEnd: cellHeight * 2

            model: list.games
            delegate: (showBoxes) ? boxartdelegate : dynamicDelegate

            Component {
            id: boxartdelegate

                BoxArtGridItem {
                    selected: GridView.isCurrentItem && root.focus
                    gameData: modelData
                    artStyle: settings.GridThumbnail

                    width:      GridView.view.cellWidth
                    height:     GridView.view.cellHeight - titleMargin

                    onActivate: {
                        if (selected)
                            gameActivated();
                        else
                            gamegrid.currentIndex = index;
                    }
                    onHighlighted: {
                        gamegrid.currentIndex = index;
                    }
                }
            }

            Component {
            id: dynamicDelegate

                DynamicGridItem {
                id: dynamicdelegatecontainer

                    selected: GridView.isCurrentItem && root.focus

                    width:      GridView.view.cellWidth
                    height:     GridView.view.cellHeight - titleMargin

                    onActivated: {
                        if (selected)
                            gameActivated();
                        else
                            gamegrid.currentIndex = index;
                    }
                    onHighlighted: {
                        gamegrid.currentIndex = index;
                    }
                }
            }

            Component {
            id: highlightcomponent

                ItemHighlight {
                    width: gamegrid.cellWidth
                    height: gamegrid.cellHeight
                    game: list.currentGame(gamegrid.currentIndex)
                    selected: gamegrid.focus
                    boxArt: showBoxes
                }
            }

            Keys.onUpPressed: {
                playNav();
                if (currentIndex < numColumns) {
                    homebutton.focus = true;
                    gamegrid.currentIndex = -1;
                } else {
                    moveCurrentIndexUp();
                }
            }
            Keys.onDownPressed:     { playNav(); moveCurrentIndexDown() }
            Keys.onLeftPressed:     { playNav(); moveCurrentIndexLeft() }
            Keys.onRightPressed:    { playNav(); moveCurrentIndexRight() }
        }

    }

    // ── Sorting & Filters overlay (same keyboard filters as All Games) ────
    Rectangle {
    id: filterPanel
        visible: filterOpen; z: 30
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.78)

        MouseArea { anchors.fill: parent; onClicked: { searchActive = false; filterOpen = false; gamegrid.focus = true; } }

        Rectangle {
            anchors.centerIn: parent
            width: vpx(500)
            height: titleTxt.height + fieldCol.height + vpx(60)
            radius: vpx(10)
            color: Qt.rgba(0.10, 0.10, 0.10, 0.98)
            border.color: theme.accent; border.width: 2

            Text {
            id: titleTxt
                text: "Filters"
                color: theme.text
                font.family: titleFont.name; font.pixelSize: vpx(24); font.bold: true
                anchors { top: parent.top; topMargin: vpx(18); left: parent.left; leftMargin: vpx(24) }
            }

            Column {
            id: fieldCol
                anchors { top: titleTxt.bottom; topMargin: vpx(14); left: parent.left; right: parent.right; leftMargin: vpx(16); rightMargin: vpx(16) }
                spacing: vpx(6)

                // Name row — shows the current search text
                Rectangle {
                    visible: !genrePickerOpen
                    width: parent.width; height: vpx(52); radius: vpx(6)
                    property bool onRow: filterRow === 0 || searchActive
                    color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"

                    Text {
                        anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: "\uD83D\uDD0D"; font.pixelSize: vpx(15); width: vpx(22)
                        color: theme.text; opacity: onRow ? 1 : 0.6
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: vpx(46); right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: searchActive
                              ? (searchTerm === "" ? "Type a name\u2026" : searchTerm)
                              : (searchTerm === "" ? "Name: (no filter)" : "Name: " + searchTerm)
                        color: onRow ? theme.accent : theme.text
                        opacity: onRow ? 1 : 0.85
                        elide: Text.ElideRight
                        font.family: subtitleFont.name; font.pixelSize: vpx(20); font.bold: onRow
                    }
                    MouseArea { anchors.fill: parent; onClicked: { filterRow = 0; activateSearch(); } }
                }

                // Genre row — opens the genre picker
                Rectangle {
                    visible: !searchActive && !genrePickerOpen
                    width: parent.width; height: vpx(52); radius: vpx(6)
                    property bool onRow: filterRow === 1
                    color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"

                    Text {
                        anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: "\u2630"; font.pixelSize: vpx(15); width: vpx(22)
                        color: theme.text; opacity: onRow ? 1 : 0.6
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: vpx(46); right: gvArrow.left; rightMargin: vpx(8); verticalCenter: parent.verticalCenter }
                        text: genreFilter === "" ? "Genre: All" : "Genre: " + genreFilter
                        color: onRow ? theme.accent : theme.text
                        opacity: onRow ? 1 : 0.85
                        elide: Text.ElideRight
                        font.family: subtitleFont.name; font.pixelSize: vpx(20); font.bold: onRow
                    }
                    Text {
                        id: gvArrow
                        anchors { right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: "\u25B8"; color: onRow ? theme.accent : theme.text
                        opacity: onRow ? 1 : 0.6; font.pixelSize: vpx(18)
                    }
                    MouseArea { anchors.fill: parent; onClicked: { filterRow = 1; openGenrePicker(); } }
                }

                // Genre picker (scrollable list of available genres)
                ListView {
                    visible: genrePickerOpen
                    width: parent.width
                    height: vpx(300)
                    clip: true
                    model: genreOptions
                    currentIndex: genrePickerIndex
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    delegate: Rectangle {
                        width: ListView.view.width; height: vpx(42); radius: vpx(4)
                        property bool onRow: index === genrePickerIndex
                        property bool isSel: modelData === (genreFilter === "" ? "All" : genreFilter)
                        color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                            text: isSel ? "\u2713" : "  "
                            color: theme.accent; font.pixelSize: vpx(15); font.bold: true; width: vpx(22)
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(46); right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                            text: modelData
                            color: (onRow || isSel) ? theme.accent : theme.text
                            opacity: onRow ? 1 : 0.85
                            elide: Text.ElideRight
                            font.family: subtitleFont.name; font.pixelSize: vpx(19); font.bold: onRow || isSel
                        }
                        MouseArea { anchors.fill: parent; onClicked: { genrePickerIndex = index; selectGenre(modelData); } }
                    }
                }

                // Sort fields + favorites (shown when neither keyboard nor genre picker is open)
                Column {
                    visible: !searchActive && !genrePickerOpen
                    width: parent.width
                    spacing: vpx(6)

                    Repeater {
                        model: sortFields
                        Rectangle {
                            width: parent.width; height: vpx(46); radius: vpx(6)
                            property bool active: sortByIndex === modelData.idx
                            property bool onRow:  filterRow === index + 2
                            color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"

                            Text {
                                anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                                text: active ? (orderBy === Qt.AscendingOrder ? "\u25B2" : "\u25BC") : "  "
                                color: theme.accent; font.pixelSize: vpx(16); font.bold: true
                                width: vpx(22)
                            }
                            Text {
                                anchors { left: parent.left; leftMargin: vpx(46); verticalCenter: parent.verticalCenter }
                                text: modelData.label
                                color: active ? theme.accent : theme.text
                                opacity: active ? 1 : 0.85
                                font.family: subtitleFont.name; font.pixelSize: vpx(20); font.bold: active
                            }
                            MouseArea { anchors.fill: parent; onClicked: { filterRow = index + 2; selectSort(modelData.idx); } }
                        }
                    }

                    // Favorites-only toggle
                    Rectangle {
                        width: parent.width; height: vpx(46); radius: vpx(6)
                        property bool onRow: filterRow === sortFields.length + 2
                        color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"

                        Text {
                            anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                            text: showFavs ? "\u2713" : "  "
                            color: theme.accent; font.pixelSize: vpx(16); font.bold: true
                            width: vpx(22)
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(46); verticalCenter: parent.verticalCenter }
                            text: "Favorites only"
                            color: showFavs ? theme.accent : theme.text
                            opacity: showFavs ? 1 : 0.85
                            font.family: subtitleFont.name; font.pixelSize: vpx(20); font.bold: showFavs
                        }
                        MouseArea { anchors.fill: parent; onClicked: { filterRow = sortFields.length + 2; showFavs = !showFavs; gamegrid.currentIndex = 0; sortedGames = null; } }
                    }
                }

                // On-screen keyboard (shown when searching)
                Grid {
                    visible: searchActive
                    columns: keyCols
                    spacing: vpx(4)
                    width: parent.width

                    Repeater {
                        model: keyboardKeys
                        Rectangle {
                            width: (fieldCol.width - (keyCols - 1) * vpx(4)) / keyCols
                            height: vpx(42); radius: vpx(4)
                            property bool sel: keyIndex === index
                            property bool wide: modelData.length > 1 && modelData !== "SPACE" && modelData !== "DEL"
                            color: sel ? theme.accent : Qt.rgba(1,1,1,0.08)
                            Text {
                                anchors.centerIn: parent
                                text: modelData === "SPACE" ? "\u2423" : (modelData === "DEL" ? "\u232B" : modelData)
                                color: sel ? "white" : theme.text
                                font.family: subtitleFont.name
                                font.pixelSize: wide ? vpx(12) : vpx(17)
                                font.bold: sel
                            }
                            MouseArea { anchors.fill: parent; onClicked: { keyIndex = index; pressKey(modelData); } }
                        }
                    }
                }
            }

            Text {
                anchors { bottom: parent.bottom; bottomMargin: vpx(14); horizontalCenter: parent.horizontalCenter }
                text: searchActive    ? "\u25B2\u25BC\u25C0\u25B6 keys    A type    B done"
                     : genrePickerOpen ? "\u25B2\u25BC navigate    A choose genre    B back"
                                       : "\u25B2\u25BC navigate    A select    B close"
                color: theme.text; opacity: 0.4
                font.family: subtitleFont.name; font.pixelSize: vpx(13)
            }
        }

        Keys.onUpPressed: {
            playNav();
            if (searchActive) { if (keyIndex >= keyCols) keyIndex -= keyCols; }
            else if (genrePickerOpen) { if (genrePickerIndex > 0) genrePickerIndex--; }
            else if (filterRow > 0) filterRow--;
        }
        Keys.onDownPressed: {
            playNav();
            if (searchActive) { var ni = keyIndex + keyCols; if (ni < keyboardKeys.length) keyIndex = ni; else keyIndex = keyboardKeys.length - 1; }
            else if (genrePickerOpen) { if (genrePickerIndex < genreOptions.length - 1) genrePickerIndex++; }
            else if (filterRow < sortFields.length + 2) filterRow++;
        }
        Keys.onLeftPressed: {
            playNav();
            if (searchActive && (keyIndex % keyCols) !== 0) keyIndex--;
        }
        Keys.onRightPressed: {
            playNav();
            if (searchActive && (keyIndex % keyCols) !== (keyCols - 1) && keyIndex < keyboardKeys.length - 1) keyIndex++;
        }
        Keys.onPressed: {
            if (searchActive) {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; playAccept(); pressKey(keyboardKeys[keyIndex]); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); searchActive = false; }
                if (api.keys.isDetails(event) && !event.isAutoRepeat) { event.accepted = true; playAccept(); searchActive = false; }
                return;
            }
            if (genrePickerOpen) {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; playAccept(); selectGenre(genreOptions[genrePickerIndex]); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); genrePickerOpen = false; }
                if (api.keys.isDetails(event) && !event.isAutoRepeat) { event.accepted = true; playAccept(); genrePickerOpen = false; }
                return;
            }
            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true; playAccept();
                if (filterRow === 0) activateSearch();
                else if (filterRow === 1) openGenrePicker();
                else if (filterRow <= sortFields.length + 1) selectSort(sortFields[filterRow - 2].idx);
                else { showFavs = !showFavs; gamegrid.currentIndex = 0; sortedGames = null; }
            }
            if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                event.accepted = true; playBack(); filterOpen = false; gamegrid.focus = true;
            }
            if (api.keys.isDetails(event) && !event.isAutoRepeat) {
                event.accepted = true; playAccept(); filterOpen = false; gamegrid.focus = true;
            }
        }
    }

    Keys.onReleased: {
        if (filterOpen) return;
        // Scroll Down
        if (api.keys.isPageDown(event) && !event.isAutoRepeat) {
            event.accepted = true;
            isRightTriggerPressed = false;
            return;
        }
        // Scroll Up
        if (api.keys.isPageUp(event) && !event.isAutoRepeat) {
            event.accepted = true;
            isLeftTriggerPressed = false;
            return;
        }
    }

    Keys.onPressed: {
        if (filterOpen) return;

        // Accept
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (gamegrid.focus) {
                gameActivated();              // plays sfxAccept via gameDetails()
            } else {
                playAccept();             // only the refocus path needs its own sound
                gamegrid.currentIndex = 0;
                gamegrid.focus = true;
            }
            return;
        }

        // Back
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (gamegrid.focus) {
                previousScreen();             // plays its own sfxBack
            } else {
                playBack();               // only the refocus path needs its own sound
                gamegrid.focus = true;
            }
            return;
        }

        // Filters (X) — open the Sorting & Filters overlay
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            playAccept();
            filterRow = (sortByIndex >= 0 && sortByIndex < sortFields.length) ? sortByIndex + 2 : 0;
            searchActive = false;
            genrePickerOpen = false;
            filterOpen = true;
            filterPanel.forceActiveFocus();
            return;
        }

        // Settings (Y)
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            settingsScreen();
            return;
        }

        // Scroll Down (RT) — next letter
        if (api.keys.isPageDown(event) && !event.isAutoRepeat) {
            event.accepted = true;
            isRightTriggerPressed = navigateToNextLetter(+1) ? true : isRightTriggerPressed;
            return;
        }

        // Scroll Up (LT) — previous letter
        if (api.keys.isPageUp(event) && !event.isAutoRepeat) {
            event.accepted = true;
            isLeftTriggerPressed = navigateToNextLetter(-1) ? true : isLeftTriggerPressed;
            return;
        }

        // Next collection (RB)
        if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            // Play the sfx BEFORE the heavy model rebuild below; the helper does stop()+play()
            // so rapid cycling always restarts the sound instead of dropping the retrigger.
            playTabRight();
            if (currentCollectionIndex < api.collections.count-1)
                currentCollectionIndex++;
            else
                currentCollectionIndex = 0;

            gamegrid.currentIndex = 0;
            sortedGames = null;
            return;
        }

        // Previous collection (LB)
        if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            playTabLeft();
            if (currentCollectionIndex > 0)
                currentCollectionIndex--;
            else
                currentCollectionIndex = api.collections.count-1;

            gamegrid.currentIndex = 0;
            sortedGames = null;
            return;
        }
    }

    // ── Helpbar: A View details, X Filters, Y Settings, B Back ────────────
    ListModel {
        id: gridviewHelpModel

        ListElement { name: "Back";         button: "cancel"  }
        ListElement { name: "Settings";     button: "filters" }
        ListElement { name: "Filters";      button: "details" }
        ListElement { name: "View details"; button: "accept"  }
    }

    onFocusChanged: {
        if (focus) {
            currentHelpbarModel = gridviewHelpModel;
            gamegrid.focus = true;
        }
    }
}
