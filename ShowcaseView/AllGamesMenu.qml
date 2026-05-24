// AllGamesMenu.qml — All games across all collections
import QtQuick 2.15
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.12
import "../Global"
import "../Lists"
import "../utils.js" as Utils
import SortFilterProxyModel 0.2

FocusScope {
id: root

    property real itemheight: vpx(50)
    property int  skipnum: 10

    // ── Data ──────────────────────────────────────────────────────────────
    ListAllGames {
    id: listAllGames
        max: api.allGames.count
    }

    // ── Sort / filter state ───────────────────────────────────────────────
    property string sortField:   "sortBy"        // sortBy|lastPlayed|rating|releaseYear|favorite
    property int    sortDir:     Qt.AscendingOrder
    property bool   filterOpen:  false
    property int    filterRow:   0
    property string nameFilter:  ""
    property bool   searchActive: false

    function activateSearch() { searchActive = true; }
    function closeSearch() {
        if (!searchActive) return;
        Qt.inputMethod.hide();        // hide while the TextInput still exists
        filterPanel.forceActiveFocus(); // move focus off the TextInput
        searchActive = false;          // now destroy the native input
    }

    // If the system dismisses the keyboard (e.g. hardware/controller back),
    // close the search cleanly so no orphaned native input box remains
    Connections {
        target: Qt.inputMethod
        onVisibleChanged: {
            if (!Qt.inputMethod.visible && searchActive) {
                filterPanel.forceActiveFocus();
                searchActive = false;
            }
        }
    }

    property var sortFields: [
        { key: "sortBy",      label: "Title" },
        { key: "lastPlayed",  label: "Last Played" },
        { key: "rating",      label: "Rating" },
        { key: "releaseYear", label: "Release Date" },
        { key: "favorite",    label: "Favorites" }
    ]

    function selectSort(field) {
        if (sortField === field) {
            sortDir = (sortDir === Qt.AscendingOrder) ? Qt.DescendingOrder : Qt.AscendingOrder;
        } else {
            sortField = field;
            // sensible default direction per field
            sortDir = (field === "lastPlayed" || field === "rating" || field === "favorite")
                      ? Qt.DescendingOrder : Qt.AscendingOrder;
        }
        gamelist.currentIndex = 0;
    }

    // ── Display model ─────────────────────────────────────────────────────
    SortFilterProxyModel {
    id: displayModel
        sourceModel: listAllGames.games
        sorters: RoleSorter {
            roleName:  sortField
            sortOrder: sortDir
        }
        filters: RegExpFilter {
            roleName: "title"
            pattern: nameFilter
            caseSensitivity: Qt.CaseInsensitive
            enabled: nameFilter !== ""
        }
    }

    function getCurrentGame(idx) {
        return listAllGames.currentGame(displayModel.mapToSource(idx));
    }

    // Jump to the first game of the next / previous letter group
    function jumpToNextLetter() {
        if (gamelist.count === 0) return;
        var cur = gamelist.currentIndex;
        var curE = cur >= 0 ? displayModel.get(cur) : null;
        var curLtr = curE ? (curE.title || "").charAt(0).toUpperCase() : "";
        for (var i = cur + 1; i < gamelist.count; i++) {
            var e = displayModel.get(i);
            if (e && (e.title || "").charAt(0).toUpperCase() !== curLtr) { gamelist.currentIndex = i; return; }
        }
        gamelist.currentIndex = 0;
    }
    function jumpToPrevLetter() {
        if (gamelist.count === 0) return;
        var cur = gamelist.currentIndex;
        if (cur <= 0) { gamelist.currentIndex = gamelist.count - 1; return; }
        var prevE = displayModel.get(cur - 1);
        var prevLtr = prevE ? (prevE.title || "").charAt(0).toUpperCase() : "";
        for (var i = cur - 2; i >= 0; i--) {
            var e = displayModel.get(i);
            if (e && (e.title || "").charAt(0).toUpperCase() !== prevLtr) { gamelist.currentIndex = i + 1; return; }
        }
        gamelist.currentIndex = 0;
    }

    Component.onCompleted: {
        currentHelpbarModel     = allGamesHelpModel;
        currentCustomCollection = listAllGames.collection;
        // Populate the box art + metadata immediately (before any scroll)
        if (displayModel.count > 0) {
            currentGameIndex = 0;
            currentGame = getCurrentGame(0);
        }
    }

    // Vertical accent line dividing the text list from the game details
    Rectangle {
    id: vDivider
        anchors {
            left: gamelist.right; leftMargin: globalMargin / 2
            top: header.bottom; topMargin: globalMargin
            bottom: parent.bottom; bottomMargin: globalMargin + helpMargin
        }
        width: vpx(2)
        color: theme.accent
    }

    // ── Box art (top of right side) — identical logic to GameView ─────────
    Image {
    id: boxArt
        anchors {
            top: header.bottom; topMargin: globalMargin
            left: gamelist.right; leftMargin: globalMargin
            right: parent.right; rightMargin: globalMargin
            bottom: metaPanel.top; bottomMargin: vpx(14)
        }
        asynchronous: true
        source: currentGame ? Utils.boxArt(currentGame, settings.BoxArtStyle) : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    // ── Metadata panel (bottom of right side) ─────────────────────────────
    Item {
    id: metaPanel
        anchors {
            left: gamelist.right; leftMargin: globalMargin
            right: parent.right; rightMargin: globalMargin
            bottom: parent.bottom; bottomMargin: globalMargin + helpMargin
        }
        height: vpx(150)
        visible: currentGame ? true : false

        // Accent line above the metadata
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: vpx(2); color: theme.accent
        }

        Row {
            anchors { top: parent.top; topMargin: vpx(16); left: parent.left; right: parent.right; bottom: parent.bottom }
            spacing: vpx(30)

            // Left column
            Column {
                width: (parent.width - vpx(30)) / 2
                spacing: vpx(11)

                Column {
                    width: parent.width; spacing: vpx(1)
                    Text { text: "Publisher"; color: theme.accent; font.family: subtitleFont.name; font.pixelSize: vpx(13); font.bold: true }
                    Text { width: parent.width; text: currentGame && currentGame.publisher ? currentGame.publisher : "—"; color: theme.text; font.family: subtitleFont.name; font.pixelSize: vpx(17); elide: Text.ElideRight }
                }
                Column {
                    width: parent.width; spacing: vpx(1)
                    Text { text: "Developer"; color: theme.accent; font.family: subtitleFont.name; font.pixelSize: vpx(13); font.bold: true }
                    Text { width: parent.width; text: currentGame && currentGame.developer ? currentGame.developer : "—"; color: theme.text; font.family: subtitleFont.name; font.pixelSize: vpx(17); elide: Text.ElideRight }
                }
                Column {
                    width: parent.width; spacing: vpx(1)
                    Text { text: "Released"; color: theme.accent; font.family: subtitleFont.name; font.pixelSize: vpx(13); font.bold: true }
                    Text { width: parent.width; text: currentGame && currentGame.releaseYear > 0 ? currentGame.releaseYear : "—"; color: theme.text; font.family: subtitleFont.name; font.pixelSize: vpx(17); elide: Text.ElideRight }
                }
            }

            // Right column
            Column {
                width: (parent.width - vpx(30)) / 2
                spacing: vpx(11)

                Column {
                    width: parent.width; spacing: vpx(1)
                    Text { text: "Genre"; color: theme.accent; font.family: subtitleFont.name; font.pixelSize: vpx(13); font.bold: true }
                    Text { width: parent.width; text: currentGame && currentGame.genre ? currentGame.genre : "—"; color: theme.text; font.family: subtitleFont.name; font.pixelSize: vpx(17); elide: Text.ElideRight }
                }
                Column {
                    width: parent.width; spacing: vpx(1)
                    Text { text: "Players"; color: theme.accent; font.family: subtitleFont.name; font.pixelSize: vpx(13); font.bold: true }
                    Text { width: parent.width; text: currentGame && currentGame.players > 0 ? currentGame.players + "P" : "—"; color: theme.text; font.family: subtitleFont.name; font.pixelSize: vpx(17); elide: Text.ElideRight }
                }
                Column {
                    width: parent.width; spacing: vpx(1)
                    Text { text: "Rating"; color: theme.accent; font.family: subtitleFont.name; font.pixelSize: vpx(13); font.bold: true }
                    Text { width: parent.width; text: currentGame && currentGame.rating > 0 ? Math.round(currentGame.rating * 100) + "%" : "—"; color: theme.text; font.family: subtitleFont.name; font.pixelSize: vpx(17); elide: Text.ElideRight }
                }
            }
        }
    }

    // ── Custom header (library icon + nav buttons) ────────────────────────
    Item {
    id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(75)

        Rectangle { anchors.fill: parent; color: theme.main }

        // Accent line under the header
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: vpx(2); color: theme.accent
        }

        Image {
        id: libIcon
            source: "../assets/images/gamesandapps.png"
            anchors { left: parent.left; leftMargin: globalMargin; verticalCenter: parent.verticalCenter }
            height: vpx(40); width: vpx(40)
            fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
        }
        Text {
            anchors { left: libIcon.right; leftMargin: vpx(10); verticalCenter: parent.verticalCenter }
            text: "My Games & Apps"
            color: theme.text; font.family: titleFont.name; font.pixelSize: vpx(22); font.bold: true
        }
        Text {
            anchors { left: parent.left; leftMargin: globalMargin; bottom: parent.bottom; bottomMargin: vpx(6) }
            text: displayModel.count + " games"
            color: theme.text; opacity: 0.7; font.family: subtitleFont.name; font.pixelSize: vpx(14)
        }

        // Nav buttons (home / discover / achievements / settings)
        Rectangle {
        id: homebutton
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -vpx(81) }
            color: focus ? theme.accent : "transparent"; opacity: focus ? 1 : 0.6
            Keys.onDownPressed:  gamelist.focus = true;
            Keys.onRightPressed: discoverbutton.focus = true;
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; showcaseScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; gamelist.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: showcaseScreen(); }
            Canvas {
                anchors { fill: parent; margins: vpx(7) }
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset();
                    var w = width, h = height;
                    ctx.fillStyle = "white";
                    ctx.globalAlpha = homebutton.focus ? 1.0 : 0.85;
                    // roof
                    ctx.beginPath();
                    ctx.moveTo(w*0.5, h*0.05);
                    ctx.lineTo(w*0.95, h*0.5);
                    ctx.lineTo(w*0.05, h*0.5);
                    ctx.closePath(); ctx.fill();
                    // body
                    ctx.fillRect(w*0.18, h*0.5, w*0.64, h*0.42);
                    // door cutout
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
            Keys.onDownPressed:  gamelist.focus = true;
            Keys.onLeftPressed:  homebutton.focus = true;
            Keys.onRightPressed: achievementsbutton.focus = true;
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; discoverScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; gamelist.focus = true; }
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
            Keys.onDownPressed:  gamelist.focus = true;
            Keys.onLeftPressed:  discoverbutton.focus = true;
            Keys.onRightPressed: settingsbutton.focus = true;
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; achievementsScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; gamelist.focus = true; }
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
            Keys.onDownPressed: gamelist.focus = true;
            Keys.onLeftPressed: achievementsbutton.focus = true;
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; settingsScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; gamelist.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: settingsScreen(); }
            Image {
                anchors { fill: parent; margins: vpx(10) }
                source: "../assets/images/settingsicon.svg"
                fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
            }
        }
    }

    // ── Game list ─────────────────────────────────────────────────────────
    ListView {
    id: gamelist
        focus: true
        currentIndex: currentGameIndex

        onCurrentIndexChanged: {
            if (currentIndex !== -1) {
                currentGameIndex = currentIndex;
                currentGame = getCurrentGame(currentIndex);
            }
        }

        Keys.onUpPressed: {
            event.accepted = true;
            if (currentIndex !== 0) currentIndex--;
            else homebutton.focus = true;
        }

        anchors {
            top: header.bottom; topMargin: globalMargin
            bottom: parent.bottom; bottomMargin: globalMargin
            left: parent.left
        }
        width: vpx(400)
        spacing: vpx(0); orientation: ListView.Vertical
        preferredHighlightBegin: gamelist.height / 2 - itemheight
        preferredHighlightEnd:   gamelist.height / 2
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 100
        clip: true

        model: displayModel

        delegate: Component {
            Item {
                width: ListView.view.width
                height: itemheight
                property bool selected: ListView.isCurrentItem

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right; rightMargin: vpx(20)
                        top: parent.top; topMargin: vpx(4)
                        bottom: parent.bottom; bottomMargin: vpx(4)
                    }
                    radius: vpx(6)
                    color: theme.accent
                    visible: selected
                }
                Text {
                    text: modelData.title
                    height: parent.height
                    anchors {
                        left: parent.left; leftMargin: vpx(20)
                        right: parent.right; rightMargin: vpx(30)
                    }
                    color: selected ? "white" : theme.text
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(20)
                    font.bold: selected
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    opacity: selected ? 1 : 0.35
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { if (selected) gameDetails(currentGame); else gamelist.currentIndex = index; }
                }
            }
        }
    }

    // ── Sorting & Filters overlay ─────────────────────────────────────────
    Rectangle {
    id: filterPanel
        visible: filterOpen; z: 30
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.78)

        MouseArea { anchors.fill: parent; onClicked: { if (searchActive) Qt.inputMethod.hide(); searchActive = false; filterOpen = false; gamelist.focus = true; } }

        Rectangle {
            anchors.centerIn: parent
            width: vpx(460)
            height: titleTxt.height + fieldCol.height + vpx(60)
            radius: vpx(10)
            color: Qt.rgba(0.10, 0.10, 0.10, 0.98)
            border.color: theme.accent; border.width: 2

            Text {
            id: titleTxt
                text: "Sorting & Filters"
                color: theme.text
                font.family: titleFont.name; font.pixelSize: vpx(24); font.bold: true
                anchors { top: parent.top; topMargin: vpx(18); left: parent.left; leftMargin: vpx(24) }
            }

            Column {
            id: fieldCol
                anchors { top: titleTxt.bottom; topMargin: vpx(14); left: parent.left; right: parent.right; leftMargin: vpx(16); rightMargin: vpx(16) }
                spacing: vpx(4)

                // Name search row (row 0)
                Rectangle {
                    width: parent.width; height: vpx(52); radius: vpx(6)
                    property bool onRow: filterRow === 0
                    color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"

                    Text {
                        anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: "🔍"; font.pixelSize: vpx(15); width: vpx(22)
                        color: theme.text; opacity: onRow ? 1 : 0.6
                    }
                    Text {
                        visible: !searchActive
                        anchors { left: parent.left; leftMargin: vpx(46); right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: nameFilter === "" ? "Name: (no filter)" : "Name: " + nameFilter
                        color: onRow ? theme.accent : theme.text
                        opacity: onRow ? 1 : 0.85
                        elide: Text.ElideRight
                        font.family: subtitleFont.name; font.pixelSize: vpx(20); font.bold: onRow
                    }
                    // Native TextInput, only alive while actively typing (Android-safe)
                    Loader {
                    id: searchLoader
                        active: searchActive
                        asynchronous: false
                        anchors { left: parent.left; leftMargin: vpx(46); right: parent.right; rightMargin: vpx(16); top: parent.top; bottom: parent.bottom }
                        onLoaded: { if (item) { item.forceActiveFocus(); item.selectAll(); } }
                        sourceComponent: Component {
                            TextInput {
                                verticalAlignment: Text.AlignVCenter
                                color: theme.accent
                                font.family: subtitleFont.name; font.pixelSize: vpx(20); font.bold: true
                                clip: true
                                text: nameFilter
                                selectionColor: theme.accent
                                selectedTextColor: "white"
                                onTextEdited: { nameFilter = text; gamelist.currentIndex = 0; }
                                onActiveFocusChanged: { if (!activeFocus) Qt.inputMethod.hide(); }
                                Keys.onReturnPressed: { event.accepted = true; closeSearch(); }
                                Keys.onEnterPressed:  { event.accepted = true; closeSearch(); }
                                Keys.onPressed: {
                                    if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; closeSearch(); }
                                }
                            }
                        }
                    }
                    MouseArea { anchors.fill: parent; onClicked: { filterRow = 0; activateSearch(); } }
                }

                Repeater {
                    model: sortFields
                    Rectangle {
                        width: parent.width; height: vpx(52); radius: vpx(6)
                        property bool active: sortField === modelData.key
                        property bool onRow:  filterRow === index + 1
                        color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"

                        Text {
                            anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                            text: active ? (sortDir === Qt.AscendingOrder ? "▲" : "▼") : "  "
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
                        MouseArea { anchors.fill: parent; onClicked: { filterRow = index + 1; selectSort(modelData.key); } }
                    }
                }
            }

            Text {
                anchors { bottom: parent.bottom; bottomMargin: vpx(14); horizontalCenter: parent.horizontalCenter }
                text: "▲▼ navigate    A toggle/select    B close"
                color: theme.text; opacity: 0.4
                font.family: subtitleFont.name; font.pixelSize: vpx(13)
            }
        }

        Keys.onUpPressed:   { if (!searchActive && filterRow > 0) filterRow--; }
        Keys.onDownPressed: { if (!searchActive && filterRow < sortFields.length) filterRow++; }
        Keys.onPressed: {
            if (searchActive) return;
            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true;
                if (filterRow === 0) activateSearch();
                else selectSort(sortFields[filterRow - 1].key);
            }
            if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                event.accepted = true; filterOpen = false; gamelist.focus = true;
            }
            if (api.keys.isDetails(event) && !event.isAutoRepeat) {
                event.accepted = true; filterOpen = false; gamelist.focus = true;
            }
        }
    }

    // ── Input ─────────────────────────────────────────────────────────────
    Keys.onDownPressed: {
        if (!filterOpen && gamelist.focus) {
            if (gamelist.currentIndex !== gamelist.count - 1) gamelist.currentIndex++;
            else gamelist.currentIndex = 0;
        }
    }
    Keys.onLeftPressed: {
        if (!filterOpen && gamelist.focus)
            gamelist.currentIndex = Math.max(0, gamelist.currentIndex - skipnum);
    }
    Keys.onRightPressed: {
        if (!filterOpen && gamelist.focus)
            gamelist.currentIndex = Math.min(gamelist.count - 1, gamelist.currentIndex + skipnum);
    }

    Keys.onPressed: {
        // A — view details
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamelist.focus) gameDetails(currentGame);
        }
        // B — back
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamelist.focus) previousScreen();
        }
        // X — open Sorting & Filters
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamelist.focus) {
                var fi = sortFields.map(function(f){ return f.key; }).indexOf(sortField);
                filterRow = fi >= 0 ? fi + 1 : 0;
                filterOpen = true;
                searchActive = false;
                filterPanel.forceActiveFocus();
            }
        }
        // Y — settings
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamelist.focus) settingsScreen();
        }
        // LT — previous letter group
        if (api.keys.isPageUp(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamelist.focus) jumpToPrevLetter();
        }
        // RT — next letter group
        if (api.keys.isPageDown(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamelist.focus) jumpToNextLetter();
        }
    }

    // ── Helpbar: A View details, X Filters, Y Settings, B Back ────────────
    ListModel {
        id: allGamesHelpModel
        ListElement { name: "Back";         button: "cancel"  }
        ListElement { name: "Settings";     button: "filters" }
        ListElement { name: "Filters";      button: "details" }
        ListElement { name: "View details"; button: "accept"  }
    }

    onFocusChanged: {
        if (focus) {
            currentHelpbarModel     = allGamesHelpModel;
            currentCustomCollection = listAllGames.collection;
        }
    }
}
