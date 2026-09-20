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

    // Touch/click blocker — full-screen page shown over the previous screen;
    // absorb pointer input so taps on empty areas can't fall through to it.
    // z:-100 keeps it behind all page content (z>=0) but in front of the
    // screen behind, so the page's own controls receive input first.
    MouseArea {
        anchors.fill: parent
        z: -100
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onPressed: mouse.accepted = true
        onClicked: mouse.accepted = true
        onReleased: mouse.accepted = true
    }
    function gameActivated() {
        storedCollectionGameIndex = gamegrid.currentIndex
        // Same rule as everywhere: imports launch, added apps follow the
        // setting, games open details.
        activateGame(list.currentGame(gamegrid.currentIndex), true);
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
    function activateSearch() {
        searchMode = "Title";
        searchActive = true;
        filterKb.page = 0;
        filterKb.shifted = false;
        filterKb.row = 0;
        filterKb.col = 0;
        filterKb.forceActiveFocus();
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
        var want = (genreSelected.length > 0) ? genreSelected[0] : "All";
        var idx = genreOptions.indexOf(want);
        genrePickerIndex = idx >= 0 ? idx : 0;
        genrePickerOpen = true;
    }
    function toggleGenre(g) {
        if (g === "All") { genreSelected = []; gamegrid.currentIndex = 0; sortedGames = null; return; }
        var arr = genreSelected.slice();
        var idx = arr.indexOf(g);
        if (idx >= 0) arr.splice(idx, 1);
        else           arr.push(g);
        genreSelected = arr;
        gamegrid.currentIndex = 0;
        sortedGames = null;
    }

    // Alphabetical letter-jump through the genre picker (mirrors the game grid)
    function genreJumpLetter(dir) {
        if (genreOptions.length < 2) return;
        var cur = genrePickerIndex;
        var curL = (genreOptions[cur] || "").charAt(0).toUpperCase();
        if (dir > 0) {
            var i = cur + 1;
            while (i < genreOptions.length && (genreOptions[i] || "").charAt(0).toUpperCase() === curL) i++;
            genrePickerIndex = (i < genreOptions.length) ? i : genreOptions.length - 1;
        } else {
            var j = cur - 1;
            while (j > 0 && (genreOptions[j] || "").charAt(0).toUpperCase() === curL) j--;
            if (j >= 0) {
                var pL = (genreOptions[j] || "").charAt(0).toUpperCase();
                while (j > 0 && (genreOptions[j-1] || "").charAt(0).toUpperCase() === pL) j--;
                genrePickerIndex = j;
            }
        }
    }

    // Reset every filter/sort back to defaults
    function clearAllFilters() {
        searchTerm    = "";
        searchMode    = "Title";
        genreSelected = [];
        showFavs      = false;
        sortByIndex   = 0;
        orderBy       = Qt.AscendingOrder;
        gamegrid.currentIndex = 0;
        sortedGames   = null;
    }

    // Resolve a controller action to its glyph file (assets/images/controller/<hex>.png)
    function fpBtnArt(action) {
        var bm;
        if      (action === "accept")   bm = api.keys.accept;
        else if (action === "cancel")   bm = api.keys.cancel;
        else if (action === "filters")  bm = api.keys.filters;
        else if (action === "details")  bm = api.keys.details;
        else if (action === "pageUp")   bm = api.keys.pageUp;
        else if (action === "pageDown") bm = api.keys.pageDown;
        else                            bm = api.keys.accept;
        for (var i = 0; i < bm.length; i++) {
            if (bm[i].name().includes("Gamepad")) {
                var v = bm[i].key.toString(16);
                return v.substring(v.length - 1, v.length);
            }
        }
        return "0";
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
    // ── Per-system tile settings ─────────────────────────────────────────
    // With the master switch on, a system can carry its own five values,
    // stored as "<shortName> - <row>". A system with "Use theme settings"
    // (the default) reads the global Platform page values. Everything below
    // reads through these resolvers, never the settings directly.
    readonly property string sysKey: list.collection ? (list.collection.shortName || "") : ""
    property int sysEpoch: 0                     // bump to re-read after an overlay change
    readonly property bool perSystemOn: settings.PerSystemTiles === "Yes"
    function sysOverride() {
        var e = sysEpoch;                        // dependency for re-evaluation
        return perSystemOn && sysKey !== "" && api.memory.has(sysKey + " - Use theme settings")
               && api.memory.get(sysKey + " - Use theme settings") === "No";
    }
    function sysPref(row, globalValue) {
        var e = sysEpoch;
        if (!sysOverride()) return globalValue;
        var k = sysKey + " - " + row;
        return api.memory.has(k) ? api.memory.get(k) : globalValue;
    }
    readonly property string tileShape:   sysPref("Tile shape",        settings.GridThumbnail)
    readonly property string tileRatio:   sysPref("Tile ratio",        settings.GridRatio)
    readonly property string tileArt:     sysPref("Tile art",          settings.GridArt)
    readonly property string tileLogo:    sysPref("Show logo on tile", settings.GridGameLogo)
    readonly property string tileColumns: sysPref("Tiles per row",     settings.GridColumns)
    readonly property string tileTitles:  sysPref("Game tile titles",  gameTitleMode)

    property bool showBoxes: tileShape === "Box Art" || tileShape === "3D Box"   // both are box tiles

    // Mouse back button: mirrors B, in the same priority order.
    function mouseBack() {
        if (sysPanelOpen)     { playBack(); sysPanelOpen = false; gamegrid.focus = true; return; }
        if (searchActive)     { searchActive = false; filterPanel.forceActiveFocus(); return; }
        if (genrePickerOpen)  { genrePickerOpen = false; filterPanel.forceActiveFocus(); return; }
        if (filterOpen)       { playBack(); filterOpen = false; gamegrid.focus = true; return; }
        if (!gamegrid.focus)  { gamegrid.focus = true; return; }   // header -> grid
        previousScreen();
    }

    // ── Fast-scroll detection (same rule as the All Games grid) ────────────
    // Two moves inside 180ms = racing. While it holds: tile animations off,
    // the highlight snaps, no look-ahead rows, and (per the Fast scroll art
    // setting) new tiles hold their art until the scroll stops.
    property bool fastScrolling: false
    property double lastNavMs: 0
    Timer { id: fastScrollRelease; interval: 200; onTriggered: fastScrolling = false }
    function noteGridNav() {
        var now = Date.now();
        if (now - lastNavMs < 180) fastScrolling = true;
        lastNavMs = now;
        fastScrollRelease.restart();
    }
    property int numColumns: parseInt(tileColumns) || 6
    property int titleMargin: tileTitles === "Always" ? vpx(30) : 0

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
            font.pixelSize: fpx(200)
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
            color: theme.text; font.family: titleFont.name; font.pixelSize: fpx(30); font.bold: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            visible: platformlogo.status !== Image.Ready
            MouseArea { anchors.fill: parent; onClicked: previousScreen(); }
        }
        Text {
            anchors { left: parent.left; leftMargin: globalMargin; top: platformlogo.bottom; topMargin: vpx(2) }
            text: list.games.count + " games"
            color: theme.text; opacity: 0.7; font.family: subtitleFont.name; font.pixelSize: fpx(17)
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
            Image {
                anchors.centerIn: parent
                width: vpx(24); height: vpx(24)
                sourceSize: Qt.size(vpx(24), vpx(24))
                source: "../assets/images/icon_home.svg"
                layer.enabled: whiteBackground
                layer.effect: ColorOverlay { color: "black" }
                fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
                opacity: homebutton.focus ? 1 : 0.7
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
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; discoverScreen(list.collection); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); gamegrid.currentIndex = 0; gamegrid.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: discoverScreen(list.collection); }
            Image {
                anchors { fill: parent; margins: vpx(6) }
                source: "../assets/images/icon_discover.svg"
                // Rasterised above display size so it stays sharp on a TV.
                sourceSize { width: Math.round(width * 2); height: Math.round(height * 2) }
                layer.enabled: whiteBackground
                layer.effect: ColorOverlay { color: "black" }
                fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
                opacity: discoverbutton.focus ? 1.0 : 0.85
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
            Image {
                anchors.centerIn: parent
                width: vpx(24); height: vpx(24)
                sourceSize: Qt.size(vpx(24), vpx(24))
                source: "../assets/images/trophy.svg"
                layer.enabled: whiteBackground
                layer.effect: ColorOverlay { color: "black" }
                fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
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
                anchors.centerIn: parent
                width: vpx(24); height: vpx(24)
                sourceSize: Qt.size(vpx(24), vpx(24))
                source: "../assets/images/settingsicon.svg"
                layer.enabled: whiteBackground
                layer.effect: ColorOverlay { color: "black" }
                fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
            }
        }

        // Nav button labels — shown only when the button is highlighted
        Text {
            text: "Home"
            anchors { top: homebutton.bottom; topMargin: vpx(3); horizontalCenter: homebutton.horizontalCenter }
            color: whiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: fpx(11); font.bold: true
            opacity: homebutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "Discover"
            anchors { top: discoverbutton.bottom; topMargin: vpx(3); horizontalCenter: discoverbutton.horizontalCenter }
            color: whiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: fpx(11); font.bold: true
            opacity: discoverbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "RetroAchievements"
            anchors { top: achievementsbutton.bottom; topMargin: vpx(3); horizontalCenter: achievementsbutton.horizontalCenter }
            color: whiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: fpx(11); font.bold: true
            opacity: achievementsbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "Settings"
            anchors { top: settingsbutton.bottom; topMargin: vpx(3); horizontalCenter: settingsbutton.horizontalCenter }
            color: whiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: fpx(11); font.bold: true
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

            property real savedCellHeight: {
                var gridRatio = parseFloat(tileRatio) || 0.66;
                if (tileShape == "Tall") {
                    return cellWidth / gridRatio;
                } else if (tileShape == "Square") {
                    return cellWidth;
                } else {
                    return cellWidth * gridRatio;
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
            // Box Art: the box's own proportions, scaled by the ratio row so it
            // is adjustable — at the default 0.66 this is exactly the height it
            // has always been; other values scale from there.
            // Box Art: a FIXED box proportion (1.4 tall) scaled by the ratio row,
            // the same scheme the All Games grid uses. It used to MEASURE a real
            // box from the collection (cellHeightRatio, from fakebox) — but that
            // image reloads asynchronously on every platform change, so the grid
            // laid out with the previous system's proportion and then jumped
            // when the new one landed: misaligned rows, half-scrolled pages,
            // wrong restore position. A constant can't do that. Boxes of other
            // shapes are aspect-fit inside the cell, never distorted.
            cellHeight: ((showBoxes) ? cellWidth * 1.4 * ((parseFloat(tileRatio) || 0.66) / 0.66)
                                     : savedCellHeight) + titleMargin
            preferredHighlightBegin: vpx(0)
            preferredHighlightEnd: gamegrid.height - helpMargin - vpx(40)
            highlightRangeMode: GridView.ApplyRange
            highlightMoveDuration: fastScrolling ? 0 : 200   // snap while racing
            highlight: highlightcomponent
            keyNavigationWraps: false
            // Paint margin covers the halo bleed only; two whole rows painted
            // off-screen was wasted work on every scroll step.
            displayMarginBeginning: cellHeight * 0.15
            displayMarginEnd: cellHeight * 0.15
            cacheBuffer: fastScrolling ? 0 : cellHeight * (hqMode ? 1.0 : 0.5)   // no look-ahead while racing

            model: list.games
            delegate: (showBoxes) ? boxartdelegate : dynamicDelegate

            Component {
            id: boxartdelegate

                BoxArtGridItem {
                    selected: GridView.isCurrentItem && gamegrid.focus
                    gameData: modelData
                    reduceMotion: fastScrolling
                    deferArt: fastScrolling
                    titleMode: tileTitles
                    artStyle: tileShape

                    width:      GridView.view.cellWidth
                    height:     GridView.view.cellHeight - titleMargin

                    onActivate: {
                        if (selected)
                            gameActivated();
                        else
                            gamegrid.currentIndex = index; gamegrid.focus = true; gamegrid.focus = true;
                    }
                    onHighlighted: {
                        gamegrid.currentIndex = index; gamegrid.focus = true;
                    }
                }
            }

            Component {
            id: dynamicDelegate

                DynamicGridItem {
                ownScreen: "softwaregridscreen"
                id: dynamicdelegatecontainer
                reduceMotion: fastScrolling
                deferArt: fastScrolling

                    selected: GridView.isCurrentItem && gamegrid.focus
                    artMode: tileArt
                titleMode: tileTitles
                    showLogo: tileLogo === "Yes"

                    width:      GridView.view.cellWidth
                    height:     GridView.view.cellHeight - titleMargin

                    onActivated: {
                        if (selected)
                            gameActivated();
                        else
                            gamegrid.currentIndex = index; gamegrid.focus = true; gamegrid.focus = true;
                    }
                    onHighlighted: {
                        gamegrid.currentIndex = index; gamegrid.focus = true;
                    }
                }
            }

            Component {
            id: highlightcomponent

                ItemHighlight {
                // Stops this grid's preview when the grid isn't the screen showing.
                ownScreen: "softwaregridscreen"
                    width: gamegrid.cellWidth
                    height: gamegrid.cellHeight
                    game: list.currentGame(gamegrid.currentIndex)
                    selected: gamegrid.focus
                    boxArt: showBoxes
                }
            }

            Keys.onUpPressed: {
                playNav(); noteGridNav();
                if (currentIndex < numColumns) {
                    homebutton.focus = true;
                    gamegrid.currentIndex = -1;
                } else {
                    moveCurrentIndexUp();
                }
            }
            Keys.onDownPressed: {
                playNav(); noteGridNav();
                // From the last row, wrap to the FIRST row in the same column
                // rather than dead-ending. The last row is often partial, so
                // "last row" means anything with no full row beneath it.
                var lastRowStart = Math.floor((count - 1) / numColumns) * numColumns;
                if (currentIndex >= lastRowStart) {
                    currentIndex = currentIndex % numColumns;
                } else {
                    moveCurrentIndexDown();
                }
            }
            Keys.onLeftPressed: {
                playNav(); noteGridNav();
                // Wrap to the last tile when on the very first one (Up still
                // reaches the nav buttons).
                if (currentIndex === 0) currentIndex = count - 1;
                else moveCurrentIndexLeft();
            }
            Keys.onRightPressed: {
                playNav(); noteGridNav();
                // Wrap to the first tile from the very last one.
                if (currentIndex === count - 1) currentIndex = 0;
                else moveCurrentIndexRight();
            }
        }

        // Mouse wheel moves the SELECTION, not just the view — the grid drives
        // its highlight from currentIndex, so scrolling content alone made the
        // view drift and snap back on the next key press. A sibling of the
        // grid, never a child: a MouseArea inside a Flickable is reparented
        // into its contentItem and scrolls away with it.
        WheelNav {
            anchors.fill: gamegrid
            view: gamegrid
            columns: numColumns
            active: !filterOpen && !sysPanelOpen
            onStepped: function() { playNav(); noteGridNav(); }
        }

    }

    // ── Sorting & Filters overlay (same keyboard filters as All Games) ────
    // ── Per-system tile settings overlay ─────────────────────────────────
    // Y opens this (when the master switch is on). Six rows: "Use theme
    // settings", then the same five the Platform page has. Changes apply as
    // you make them and only touch this system. B closes; Y from here goes
    // on to the full theme settings.
    property bool sysPanelOpen: false
    property int  sysRow: 0
    readonly property var sysRows: [
        { key: "Use theme settings", label: "Use theme settings", opts: ["Yes", "No"],                       dflt: "Yes" },
        { key: "Tile shape",         label: "Tile shape",         opts: ["Wide","Tall","Square","Box Art","3D Box"], dflt: settings.GridThumbnail },
        { key: "Tile ratio",         label: "Tile ratio",         opts: ratioOpts,                          dflt: settings.GridRatio },
        { key: "Tile art",           label: "Tile art",           opts: ["Fanart","Screenshot","Boxfront"], dflt: settings.GridArt },
        { key: "Show logo on tile",  label: "Show logo on tile",  opts: ["Yes","No"],                       dflt: settings.GridGameLogo },
        { key: "Tiles per row",      label: "Tiles per row",      opts: ["3","4","5","6","7","8"],          dflt: settings.GridColumns },
        { key: "Game tile titles",   label: "Game tile titles",   opts: ["On focus","Always","Never"],      dflt: gameTitleMode }
    ]
    readonly property var ratioOpts: {
        var a = [];
        for (var i = 66; i <= 99; i++) a.push("0." + i);
        for (var j = 25; j <= 65; j++) a.push("0." + j);
        return a;
    }
    function sysValue(row) {
        var r = sysRows[row], k = sysKey + " - " + r.key;
        return api.memory.has(k) ? api.memory.get(k) : String(r.dflt);
    }
    function sysRowDisabled(row) {
        if (row === 0) return false;
        if (sysValue(0) === "Yes") return true;                        // following the theme
        var shape = sysValue(1);
        if ((row === 3 || row === 4) && (shape === "Box Art" || shape === "3D Box")) return true;
        if (row === 2 && shape === "Square") return true;
        return false;
    }
    function sysCycle(row, dir) {
        if (sysRowDisabled(row)) return;
        var r = sysRows[row], opts = r.opts, cur = sysValue(row);
        var i = opts.indexOf(cur); if (i < 0) i = 0;
        var v = opts[(i + dir + opts.length) % opts.length];
        api.memory.set(sysKey + " - " + r.key, v);
        // Same rule as the Settings page: box-front art turns the logo off.
        if (r.key === "Tile art" && v === "Boxfront") api.memory.set(sysKey + " - Show logo on tile", "No");
        sysEpoch++;
        playNav();
    }
    function sysStep(dir) {
        var n = sysRows.length, i = sysRow, tries = 0;
        do { i = (i + dir + n) % n; tries++; } while (sysRowDisabled(i) && i !== 0 && tries < n);
        sysRow = i; playNav();
    }

    Rectangle {
    id: sysPanel
        visible: sysPanelOpen; z: 31
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.78)
        focus: sysPanelOpen
        MouseArea { anchors.fill: parent; onClicked: { sysPanelOpen = false; gamegrid.focus = true; } }

        Rectangle {
            anchors.centerIn: parent
            width: vpx(720); height: vpx(616)
            radius: vpx(14)
            color: "#1E1E20"; border.color: theme.accent; border.width: vpx(2)
            MouseArea { anchors.fill: parent; }   // swallow clicks inside

            Text {
                anchors { left: parent.left; leftMargin: vpx(36); top: parent.top; topMargin: vpx(28) }
                text: list.collection ? list.collection.name : ""
                color: "white"; font.family: titleFont.name; font.pixelSize: vpx(28); font.bold: true
            }
            Text {
                anchors { left: parent.left; leftMargin: vpx(36); top: parent.top; topMargin: vpx(68) }
                text: "Tile settings for this system"
                color: "#A0A0A0"; font.family: subtitleFont.name; font.pixelSize: vpx(15)
            }
            Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: vpx(104); leftMargin: vpx(36); rightMargin: vpx(36) } height: vpx(2); color: "#3C3C40" }

            Column {
                anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: vpx(124); leftMargin: vpx(24); rightMargin: vpx(24) }
                spacing: vpx(6)
                Repeater {
                    model: sysRows.length
                    delegate: Rectangle {
                        width: parent.width; height: vpx(52)
                        radius: vpx(8)
                        readonly property bool cur: index === sysRow
                        readonly property bool dis: { var e = sysEpoch; return sysRowDisabled(index); }
                        color: cur ? "#2A2A2E" : "transparent"
                        border.color: cur ? theme.accent : "transparent"; border.width: vpx(3)
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(12); verticalCenter: parent.verticalCenter }
                            text: sysRows[index].label
                            color: dis ? "#6E6E6E" : "white"; font.family: subtitleFont.name; font.pixelSize: vpx(20)
                        }
                        Text {
                            anchors { right: parent.right; rightMargin: vpx(12); verticalCenter: parent.verticalCenter }
                            text: { var e = sysEpoch; return "<  " + sysValue(index) + "  >"; }
                            color: dis ? "#646464" : "#D7D7D7"; font.family: subtitleFont.name; font.pixelSize: vpx(20)
                        }
                        // a divider under the first row
                        Rectangle { visible: index === 0; anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: -vpx(4) } height: vpx(1); color: "#3C3C40" }
                    }
                }
            }

            Text {
                anchors { left: parent.left; leftMargin: vpx(36); bottom: parent.bottom; bottomMargin: vpx(52) }
                text: "Changes apply as you make them. Only this system is affected."
                color: "#8C8C8C"; font.family: subtitleFont.name; font.pixelSize: vpx(14)
            }
            Row {
                anchors { right: parent.right; rightMargin: vpx(36); bottom: parent.bottom; bottomMargin: vpx(18) }
                spacing: vpx(22)
                Row { spacing: vpx(6)
                    Image { anchors.verticalCenter: parent.verticalCenter; width: vpx(20); height: vpx(20); source: "../assets/images/controller/" + Utils.processButtonArt("filters") + ".png"; sourceSize { width: 40; height: 40 } }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Theme settings"; color: "#D2D2D2"; font.family: subtitleFont.name; font.pixelSize: vpx(16) } }
                Row { spacing: vpx(6)
                    Image { anchors.verticalCenter: parent.verticalCenter; width: vpx(20); height: vpx(20); source: "../assets/images/controller/" + Utils.processButtonArt("cancel") + ".png"; sourceSize { width: 40; height: 40 } }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Back"; color: "#D2D2D2"; font.family: subtitleFont.name; font.pixelSize: vpx(16) } }
            }
        }

        Keys.onPressed: {
            if (api.keys.isCancel(event) && !event.isAutoRepeat)  { event.accepted = true; playBack(); sysPanelOpen = false; gamegrid.focus = true; return; }
            if (api.keys.isFilters(event) && !event.isAutoRepeat) { event.accepted = true; sysPanelOpen = false; settingsScreen(); return; }
            if (api.keys.isAccept(event) && !event.isAutoRepeat)  { event.accepted = true; sysCycle(sysRow, 1); return; }
        }
        Keys.onUpPressed:    sysStep(-1)
        Keys.onDownPressed:  sysStep(1)
        Keys.onLeftPressed:  sysCycle(sysRow, -1)
        Keys.onRightPressed: sysCycle(sysRow, 1)
    }

    Rectangle {
    id: filterPanel
        visible: filterOpen; z: 30
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.78)

        MouseArea { anchors.fill: parent; onClicked: { searchActive = false; filterOpen = false; gamegrid.focus = true; } }

        // Shared on-screen keyboard — same presentation as the RA search:
        // title and text field up top, keys below, its own help prompts.
        VirtualKeyboard {
        id: filterKb

            anchors.centerIn: parent
            z: 60
            visible: searchActive
            focus: searchActive
            title: "Filter by Title"
            text: searchTerm

            onTextEdited: {
                searchTerm = newText;
                gamegrid.currentIndex = 0;
                sortedGames = null;
            }
            // Focus MUST go back to the panel here — leaving it on a hidden
            // keyboard is what froze input on the way out.
            onAccepted:  { searchActive = false; filterPanel.forceActiveFocus(); }
            onCancelled: { searchActive = false; filterPanel.forceActiveFocus(); }
        }

        Rectangle {
            visible: !searchActive        // keyboard takes over the screen while typing
            anchors.centerIn: parent
            width: vpx(500)
            height: titleTxt.height + fieldCol.height + vpx(60)
            radius: vpx(10)
            color: Qt.rgba(0.10, 0.10, 0.10, 0.98)
            border.color: theme.accent; border.width: 2

            Text {
            id: titleTxt
                text: "Filters"
                color: "white"
                font.family: titleFont.name; font.pixelSize: fpx(24); font.bold: true
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
                        text: "\uD83D\uDD0D"; font.pixelSize: fpx(15); width: vpx(22)
                        color: "white"; opacity: onRow ? 1 : 0.6
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: vpx(46); right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: searchActive
                              ? (searchTerm === "" ? "Type a name\u2026" : searchTerm)
                              : (searchTerm === "" ? "Name: (no filter)" : "Name: " + searchTerm)
                        color: "white"
                        opacity: onRow ? 1 : 0.85
                        elide: Text.ElideRight
                        font.family: subtitleFont.name; font.pixelSize: fpx(20); font.bold: onRow
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
                        text: "\u2630"; font.pixelSize: fpx(15); width: vpx(22)
                        color: "white"; opacity: onRow ? 1 : 0.6
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: vpx(46); right: gvArrow.left; rightMargin: vpx(8); verticalCenter: parent.verticalCenter }
                        text: genreSelected.length === 0 ? "Genre: All"
                             : genreSelected.length === 1 ? "Genre: " + genreSelected[0]
                             : "Genre: " + genreSelected.length + " selected"
                        color: "white"
                        opacity: onRow ? 1 : 0.85
                        elide: Text.ElideRight
                        font.family: subtitleFont.name; font.pixelSize: fpx(20); font.bold: onRow
                    }
                    Text {
                        id: gvArrow
                        anchors { right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: "\u25B8"; color: "white"
                        opacity: onRow ? 1 : 0.6; font.pixelSize: fpx(18)
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
                        property bool isSel: modelData === "All" ? genreSelected.length === 0
                                                                 : genreSelected.indexOf(modelData) >= 0
                        color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                            text: isSel ? "\u2713" : "  "
                            color: "white"; font.pixelSize: fpx(15); font.bold: true; width: vpx(22)
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(46); right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                            text: modelData
                            color: "white"
                            opacity: onRow ? 1 : 0.85
                            elide: Text.ElideRight
                            font.family: subtitleFont.name; font.pixelSize: fpx(19); font.bold: onRow || isSel
                        }
                        MouseArea { anchors.fill: parent; onClicked: { genrePickerIndex = index; toggleGenre(modelData); } }
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
                                color: "white"; font.pixelSize: fpx(16); font.bold: true
                                width: vpx(22)
                            }
                            Text {
                                anchors { left: parent.left; leftMargin: vpx(46); verticalCenter: parent.verticalCenter }
                                text: modelData.label
                                color: "white"
                                opacity: active ? 1 : 0.85
                                font.family: subtitleFont.name; font.pixelSize: fpx(20); font.bold: active
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
                            color: "white"; font.pixelSize: fpx(16); font.bold: true
                            width: vpx(22)
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(46); verticalCenter: parent.verticalCenter }
                            text: "Favorites only"
                            color: "white"
                            opacity: showFavs ? 1 : 0.85
                            font.family: subtitleFont.name; font.pixelSize: fpx(20); font.bold: showFavs
                        }
                        MouseArea { anchors.fill: parent; onClicked: { filterRow = sortFields.length + 2; showFavs = !showFavs; gamegrid.currentIndex = 0; sortedGames = null; } }
                    }
                }

            }

            // Button-icon hint bar — swaps prompts per context (search / genre / sort)
            Row {
                visible: !searchActive     // the keyboard draws its own prompts
                anchors { bottom: parent.bottom; bottomMargin: vpx(12); right: parent.right; rightMargin: vpx(20) }
                spacing: vpx(22)

                Repeater {
                    model: searchActive   ? [ {a:"accept",t:"Type"}, {a:"details",t:"Delete"}, {a:"filters",t:"Done"}, {a:"cancel",t:"Close"} ]
                         : genrePickerOpen ? [ {a:"accept",t:"Toggle"}, {a:"cancel",t:"Done"} ]
                         :                   [ {a:"accept",t:"Select"}, {a:"details",t:"Clear all"}, {a:"cancel",t:"Close"} ]
                    delegate: Row {
                        spacing: vpx(7)
                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            source: "../assets/images/controller/" + fpBtnArt(modelData.a) + ".png"
                            width: vpx(26); height: vpx(26)
                            asynchronous: true; smooth: true
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.t
                            color: "white"; opacity: 0.55
                            font.family: subtitleFont.name; font.pixelSize: fpx(15)
                        }
                    }
                }
            }
        }

        Keys.onUpPressed: {
            playNav();
            if (searchActive) { }
            else if (genrePickerOpen) { if (genrePickerIndex > 0) genrePickerIndex--; }
            else if (filterRow > 0) filterRow--;
        }
        Keys.onDownPressed: {
            playNav();
            if (searchActive) { }
            else if (genrePickerOpen) { if (genrePickerIndex < genreOptions.length - 1) genrePickerIndex++; }
            else if (filterRow < sortFields.length + 2) filterRow++;
        }
        Keys.onLeftPressed: {
            playNav();
            if (searchActive) { }
            else if (genrePickerOpen) genrePickerIndex = Math.max(0, genrePickerIndex - 10);
        }
        Keys.onRightPressed: {
            playNav();
            if (searchActive) { }
            else if (genrePickerOpen) genrePickerIndex = Math.min(genreOptions.length - 1, genrePickerIndex + 10);
        }
        Keys.onPressed: {
            // While searching the VirtualKeyboard holds focus and handles its
            // own input, so nothing here should run.
            if (searchActive) return;
            if (genrePickerOpen) {
                if (api.keys.isPageDown(event) && !event.isAutoRepeat) { event.accepted = true; playToggle(); genreJumpLetter(1);  return; }
                if (api.keys.isPageUp(event)   && !event.isAutoRepeat) { event.accepted = true; playToggle(); genreJumpLetter(-1); return; }
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; playAccept(); toggleGenre(genreOptions[genrePickerIndex]); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); genrePickerOpen = false; }
                if (api.keys.isDetails(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); genrePickerOpen = false; }
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
                event.accepted = true; playToggle(); clearAllFilters();
            }
        }
    }

    Keys.onReleased: {
        if (filterOpen || sysPanelOpen) return;
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
        if (filterOpen || sysPanelOpen) return;

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
            if (perSystemOn && sysKey !== "") { playAccept(); sysRow = 0; sysPanelOpen = true; sysPanel.forceActiveFocus(); }
            else settingsScreen();
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

        // LB/RB in "Nav Bar" mode: step along the header icons instead.
        if ((api.keys.isNextPage(event) || api.keys.isPrevPage(event)) && !event.isAutoRepeat
            && settings.PlatformShoulderButtons === "Nav Bar") {
            event.accepted = true;
            navBarStep(api.keys.isNextPage(event) ? 1 : -1);
            return;
        }

        // Next collection (RB)
        if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            // Play the sfx BEFORE the heavy model rebuild below; the helper does stop()+play()
            // so rapid cycling always restarts the sound instead of dropping the retrigger.
            playTabRight();
            var ni = sortedColl.indexOf(currentCollectionIndex);
            ni = (ni < 0) ? 0 : (ni + 1) % sortedColl.length;
            currentCollectionIndex = sortedColl[ni];

            gamegrid.currentIndex = 0;
            sortedGames = null;
            return;
        }

        // Previous collection (LB)
        if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            playTabLeft();
            var pi = sortedColl.indexOf(currentCollectionIndex);
            pi = (pi < 0) ? 0 : (pi - 1 + sortedColl.length) % sortedColl.length;
            currentCollectionIndex = sortedColl[pi];

            gamegrid.currentIndex = 0;
            sortedGames = null;
            return;
        }
    }

    // Steps focus along the header icons. From the grid, RB lands on the
    // first icon and LB on the last; among the icons it wraps. Down from any
    // icon returns to the grid (the icons already handle that).
    function navBarStep(dir) {
        var items = [homebutton, discoverbutton, achievementsbutton, settingsbutton];
        var cur = -1;
        for (var i = 0; i < items.length; i++) if (items[i].activeFocus) { cur = i; break; }
        var next;
        if (cur < 0) next = (dir > 0) ? 0 : items.length - 1;
        else         next = (cur + dir + items.length) % items.length;
        playNav();
        gamegrid.currentIndex = -1;
        items[next].focus = true;
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

    // Status cluster (clock / battery / wifi) — same component and
    // ShowClock/ShowBattery/ShowWifi settings as the home page.
    StatusCluster {
        anchors.fill: parent
        z: 50
        dark: whiteBackground
    }
}
