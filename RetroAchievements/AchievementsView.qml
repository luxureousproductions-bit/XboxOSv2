// XboxOSv2 – AchievementsView.qml
// Recently-played games with per-game achievement progress.
// Selecting a game drills down to GameAchievementsView.
//
// Enhancements over v1:
//   • Progress bar on every game row (visual fill, not just "N of M" text)
//   • Completion % badge on the right side of each row
//   • Extended profile header: rank + member-since + true points
//   • Shared RAStatusBar (no duplicate clock/battery timers)
//   • cacheBuffer on ListView for smoother Android scrolling
//   • sourceSize on all network images

import QtQuick 2.15
import QtGraphicalEffects 1.15
import "../Global"
import "../utils.js" as Utils

FocusScope {
id: root

    anchors.fill: parent

    property bool initialized: false

    // ── Relative time helpers ─────────────────────────────────────────────
    function lastPlayedText(lastPlayed) {
        var ms = Date.parse(lastPlayed);
        if (isNaN(ms)) return "";
        var s = Math.floor((Date.now() - ms) / 1000);
        if (s < 120)  return "Just now";
        var m = Math.floor(s / 60);
        if (m < 60)   return m + " min ago";
        var h = Math.floor(m / 60);
        if (h < 24)   return h === 1 ? "1 hr ago" : h + " hrs ago";
        var d = Math.floor(h / 24);
        if (d === 1)  return "Yesterday";
        if (d < 365)  return d + " days ago";
        return Qt.formatDate(new Date(ms), "MMM d, yyyy");
    }

    // ── Lifecycle ────────────────────────────────────────────────────────
    onActiveFocusChanged: {
        if (activeFocus) {
            currentHelpbarModel = null;
            cheevosData.reload();
            if (!initialized && cheevosData.raUserName !== "") {
                initialized = true;
                cheevosData.loadUserProfile();
                cheevosData.loadRecentGames();
            }
        }
    }

    // ── Background ───────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: theme.main
    }

    // Touch/click blocker — these RA pages are shown full-screen over whatever
    // was on screen before; absorb pointer input so taps on empty areas can't
    // fall through to the screen behind. Sits below all page content (declared
    // after this), so the page's own controls still receive input on top.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onPressed: mouse.accepted = true
        onClicked: mouse.accepted = true
        onReleased: mouse.accepted = true
    }

    // ── Header ───────────────────────────────────────────────────────────
    Item {
    id: achievementsHeader

        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(110)

        // RA logo
        Image {
        id: raLogo
            anchors {
                left: parent.left; leftMargin: vpx(5)
                top: parent.top; bottom: parent.bottom
                topMargin: vpx(4); bottomMargin: vpx(4)
            }
            width: height
            source: "../assets/images/icon_ra.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            sourceSize { width: 96; height: 96 }
        }

        // Avatar + username + points + rank + member since
        Row {
            anchors {
                left: raLogo.right; leftMargin: vpx(12)
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(12)

            // Circular avatar (OpacityMask clip) + accent ring
            Item {
                width: vpx(56); height: vpx(56)
                visible: cheevosData.avatarUrl !== ""
                Image {
                id: raOverviewAvatar
                    anchors.fill: parent
                    source: cheevosData.avatarUrl
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    sourceSize { width: 64; height: 64 }
                    layer.enabled: true
                    layer.smooth: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: raOverviewAvatar.width; height: raOverviewAvatar.height
                            radius: width / 2
                        }
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: theme.accent
                    border.width: vpx(2)
                    radius: width / 2
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: vpx(2)
                visible: cheevosData.raUserName !== ""

                Text {
                    text: cheevosData.raUserName
                    color: theme.text
                    font.family: titleFont.name
                    font.pixelSize: fpx(24)
                    font.bold: true
                }
                Text {
                    text: cheevosData.pointsText
                    color: theme.text
                    font.family: bodyFont.name
                    font.pixelSize: fpx(15)
                    opacity: 0.65
                    visible: cheevosData.raUserName !== ""
                }
                Text {
                    text: cheevosData.memberText
                    color: theme.text
                    font.family: bodyFont.name
                    font.pixelSize: fpx(13)
                    opacity: 0.45
                    visible: cheevosData.memberText !== ""
                }
            }
        }

        // Shared status cluster (clock / battery / wifi) — same component and
        // ShowClock/ShowBattery/ShowWifi settings as every other page.
        StatusCluster {
            anchors.fill: parent
            z: 50
            dark: whiteBackground
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: vpx(1)
            color: theme.text
            opacity: 0.1
        }
    }

    // ── No-credentials placeholder ───────────────────────────────────────
    Item {
        anchors {
            top: achievementsHeader.bottom; bottom: parent.bottom
            left: parent.left; right: parent.right
        }
        visible: cheevosData.raUserName === ""

        Text {
            anchors.centerIn: parent
            text: "Retro Achievements not configured.\n\n"
                + "Go to  Settings → Retro Achievements\n"
                + "and enter your RA username and API key.\n\n"
                + "Get your API key at: retroachievements.org/settings"
            color: theme.text
            font.family: bodyFont.name
            font.pixelSize: fpx(18)
            opacity: 0.5
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }

    // ── Recently-played game list ────────────────────────────────────────
    ListView {
    id: gameList

        visible: cheevosData.raUserName !== ""
        focus:   visible

        anchors {
            top:    achievementsHeader.bottom; topMargin:    vpx(4)
            bottom: parent.bottom;            bottomMargin: vpx(56)
            left:   parent.left
            right:  parent.right
        }

        model:       cheevosData.raRecentGames
        currentIndex: 0
        clip:         true
        cacheBuffer:  vpx(300)   // pre-render ~3 off-screen rows for smooth Android scrolling

        // Nav sound fires on ANY index change (keyboard up/down, mouse hover/click).
        // The focused ListView consumes Up/Down internally, so the root Keys handlers
        // never see them — hooking the index change is the reliable place for the sound.
        property bool navReady: false
        Component.onCompleted: navReady = true
        onCurrentIndexChanged: if (navReady) playNav()

        highlightMoveDuration: 100
        preferredHighlightBegin: vpx(96)
        preferredHighlightEnd:   height - vpx(96)
        highlightRangeMode: ListView.ApplyRange

        highlight: Rectangle {
            color:   theme.accent
            opacity: 0.45
            width:   gameList.width
        }

        // Empty / loading state
        Text {
            anchors.centerIn: parent
            visible: cheevosData.raRecentGames.count === 0
            text:    cheevosData.statusText || "No recently played games"
            color:   theme.text
            font.family: bodyFont.name
            font.pixelSize: fpx(18)
            opacity: 0.5
        }

        delegate: Item {
        id: gameRow

            width:  gameList.width
            height: vpx(100)

            property bool isSelected: ListView.isCurrentItem && gameList.focus

            // ── Row inner layout ─────────────────────────────────────────
            Item {
                anchors {
                    fill:        parent
                    rightMargin: vpx(globalMargin)
                }

                // Game icon — square, left edge, full row height
                Item {
                id: gameIcon
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: height

                    Rectangle {
                        anchors.fill: parent
                        color:   theme.secondary
                        opacity: 0.4
                    }
                    Image {
                        anchors.fill: parent
                        source: ImageIcon
                                ? "https://media.retroachievements.org" + ImageIcon
                                : ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                        sourceSize { width: 96; height: 96 }
                    }
                }

                // Completion % badge — right edge
                Column {
                id: countCol
                    anchors {
                        right: parent.right; rightMargin: vpx(0)
                        verticalCenter: parent.verticalCenter
                    }
                    width: vpx(90)
                    spacing: vpx(2)

                    // Large % number
                    Text {
                        property int pct: NumPossibleAchievements > 0
                                          ? Math.floor(NumAchieved * 100 / NumPossibleAchievements)
                                          : 0
                        text: NumPossibleAchievements > 0 ? pct + "%" : "—"
                        color: {
                            if (NumPossibleAchievements === 0) return theme.text;
                            var p = Math.floor(NumAchieved * 100 / NumPossibleAchievements);
                            if (p >= 100) return "#FFD700";   // gold — mastered
                            if (p >= 50)  return theme.accent; // accent — decent progress
                            return theme.text;
                        }
                        font.family:    titleFont.name
                        font.pixelSize: fpx(26)
                        font.bold:      true
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        opacity: isSelected ? 1.0 : 0.8
                    }

                    // "N of M" sub-label
                    Text {
                        text: NumPossibleAchievements > 0
                              ? NumAchieved + " of " + NumPossibleAchievements
                              : "No cheevos"
                        color: theme.text
                        font.family:    bodyFont.name
                        font.pixelSize: fpx(13)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        opacity: isSelected ? 0.75 : 0.45
                    }
                }

                // Title + platform + last-played + progress bar
                Column {
                    anchors {
                        left:  gameIcon.right; leftMargin:  vpx(14)
                        right: countCol.left;  rightMargin: vpx(10)
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: vpx(5)

                    Text {
                        text: Title
                        color: theme.text
                        font.family:    titleFont.name
                        font.pixelSize: fpx(21)
                        font.bold:      true
                        elide: Text.ElideRight
                        width: parent.width
                        opacity: isSelected ? 1.0 : 0.9
                    }

                    // Platform · Last played (same line)
                    Item {
                        width:  parent.width
                        height: platformLbl.implicitHeight

                        Text {
                        id: platformLbl
                            text: ConsoleName
                            color: theme.text
                            font.family:    subtitleFont.name
                            font.pixelSize: fpx(15)
                            font.bold:      true
                            opacity: isSelected ? 0.9 : 0.55
                            elide: Text.ElideRight
                            width: parent.width * 0.55
                        }

                        Text {
                            anchors.right: parent.right
                            text: root.lastPlayedText(LastPlayed)
                            color: theme.text
                            font.family:    bodyFont.name
                            font.pixelSize: fpx(14)
                            opacity: isSelected ? 0.75 : 0.4
                            elide: Text.ElideRight
                            width: parent.width * 0.45
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    // Progress bar
                    Item {
                        width:  parent.width
                        height: vpx(5)
                        visible: NumPossibleAchievements > 0

                        Rectangle {
                            anchors.fill: parent
                            color:        theme.text
                            opacity:      0.15
                            radius:       vpx(2)
                        }
                        Rectangle {
                            width: {
                                var p = Progress || 0;  // pre-computed 0.0–1.0
                                return parent.width * p;
                            }
                            height: parent.height
                            color: {
                                var p = Progress || 0;
                                if (p >= 1.0) return "#FFD700";   // mastered — gold
                                if (p >= 0.5) return theme.accent;
                                return theme.accent;
                            }
                            radius: vpx(2)
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // Row divider
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height:  vpx(1)
                color:   theme.text
                opacity: 0.08
            }

            // Touch
            MouseArea {
                anchors.fill: parent
                hoverEnabled: settings.MouseHover === "Yes"
                onEntered: { gameList.currentIndex = index; }
                onClicked: {
                    if (isSelected) openSelectedGame();
                    else { gameList.currentIndex = index; }
                }
            }
        }
    }

    // ── Page counter ─────────────────────────────────────────────────────
    Text {
        visible: cheevosData.raUserName !== "" && cheevosData.raRecentGames.count > 0
        anchors {
            right:  parent.right; rightMargin: globalMargin
            bottom: parent.bottom; bottomMargin: vpx(10)
        }
        text: (gameList.currentIndex + 1) + " of " + cheevosData.raRecentGames.count
        color: theme.text
        font.family: bodyFont.name
        font.pixelSize: fpx(20)
        font.bold: true
        opacity: 0.75
    }

    // ── Local help bar (bottom-left) ─────────────────────────────────────
    Row {
        anchors {
            left: parent.left; leftMargin: globalMargin
            bottom: parent.bottom; bottomMargin: vpx(10)
        }
        spacing: vpx(20)

        Repeater {
            model: localHelpModel
            delegate: Row {
                spacing: vpx(8)
                Image {
                    source: "../assets/images/controller/"
                            + buttonbar.processButtonArt(button) + ".png"
                    width: vpx(32); height: vpx(32)
                    asynchronous: true
                    sourceSize { width: 48; height: 48 }
                }
                Text {
                    text: name
                    font.family: subtitleFont.name
                    font.pixelSize: fpx(20)
                    color: theme.text
                    height: vpx(32)
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    ListModel {
    id: localHelpModel
        ListElement { name: "Details"; button: "accept"  }
        ListElement { name: "Search";  button: "filters" }
        ListElement { name: "Refresh"; button: "details" }
        ListElement { name: "Back";    button: "cancel"  }
    }

    // ── Navigation helpers ───────────────────────────────────────────────
    function openSelectedGame() {
        if (cheevosData.raRecentGames.count === 0) return;
        var gameID = cheevosData.raRecentGames.get(gameList.currentIndex).GameID;
        cheevosData.loadGameAchievements(gameID);
        gameAchievementsScreenFromOverview();
    }

    // ── Key handling ─────────────────────────────────────────────────────
    // While the search overlay is open it owns all input (it has focus), so
    // these only ever run for the recently-played list underneath.
    Keys.onUpPressed: {
        event.accepted = true;
        if (searchOverlay.open) return;
        if (gameList.currentIndex > 0) gameList.currentIndex--;
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (searchOverlay.open) return;
        if (gameList.currentIndex < cheevosData.raRecentGames.count - 1)
            gameList.currentIndex++;
    }
    Keys.onPressed: {
        // Y — open the library search
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            playAccept();
            searchOverlay.openSearch();
            return;
        }
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            playAccept();
            openSelectedGame();
        }
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            previousScreen();
        }
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            playAccept();
            initialized = false;
            cheevosData.refreshAll();
        }
    }

    // ── Library search overlay ────────────────────────────────────────────
    // Searches the LOCAL Pegasus library, then hands the chosen game to the
    // existing RA pipeline: set currentGame -> raEntryScreen(). RAGameEntryView
    // already resolves the RA game ID (console map + cached GetGameList +
    // normalized title match) and navigates on to the achievements page, so
    // nothing about that lookup is duplicated here.
    FocusScope {
    id: searchOverlay

        property bool open: false
        anchors.fill: parent
        visible: open
        focus: open
        z: 200

        property string query: ""
        property var results: []

        // Clears the query and results and returns to the keyboard.
        function resetSearch() {
            showingResults = false;
            query = "";
            results = [];
            totalMatches = 0;
            resultList.currentIndex = 0;
            keyRow.row = 0;
            keyRow.col = 0;
        }

        function openSearch() {
            buildSearchIndex();
            resetSearch();
            open = true;
            forceActiveFocus();
        }
        function closeSearch() {
            open = false;
            root.forceActiveFocus();
        }

        // Matching runs on CheevosData's normalized form (drops articles,
        // bracketed regions, punctuation), so "zelda 3" finds
        // "The Legend of Zelda III (USA)" and "mario bros" ignores hyphens.
        // Exact-prefix hits sort above mid-string hits.
        property int totalMatches: 0

        // Normalizing every title costs several regex passes each, so on a
        // multi-thousand game library doing it per keystroke is far too slow.
        // Build the normalized index once per session instead.
        property var searchIndex: []
        function buildSearchIndex() {
            if (searchIndex.length > 0) return;
            var idx = [];
            for (var i = 0; i < api.allGames.count; i++) {
                var g = api.allGames.get(i);
                idx.push({ game: g, norm: cheevosData.normalizeTitle(g.title || "") });
            }
            searchIndex = idx;
        }

        // Type a query, press Search (Y or the on-screen key), then browse the
        // committed results list.
        property bool showingResults: false      // on the results list, not the keyboard

        // Real RA progress for a local game, when it's in the recently-played
        // cache. Costs nothing — anything not there simply shows no bar, since
        // fetching per result would mean an API call per row.
        function raProgressFor(g) {
            if (!g) return null;
            var n = cheevosData.normalizeTitle(g.title || "");
            for (var i = 0; i < cheevosData.raRecentGames.count; i++) {
                var e = cheevosData.raRecentGames.get(i);
                if (cheevosData.normalizeTitle(e.Title) === n) return e;
            }
            return null;
        }

        function commitSearch() {
            runSearch();
            if (results.length > 0) {
                showingResults = true;
                resultList.currentIndex = 0;
            }
        }

        function runSearch() {
            var raw = query.toLowerCase().trim();
            if (raw === "") { results = []; totalMatches = 0; return; }
            var q = cheevosData.normalizeTitle(raw);
            if (q === "") q = raw;

            var starts = [];
            var contains = [];
            for (var i = 0; i < searchIndex.length; i++) {
                var at = searchIndex[i].norm.indexOf(q);
                if (at === 0)      starts.push(searchIndex[i].game);
                else if (at > 0)   contains.push(searchIndex[i].game);
            }
            var out = starts.concat(contains);
            totalMatches = out.length;
            results = out.slice(0, 80);
            resultList.currentIndex = 0;
        }
        onQueryChanged: showingResults = false

        // Chosen game -> existing RA lookup pipeline.
        function chooseResult() {
            if (results.length === 0) return;
            var g = results[resultList.currentIndex];
            if (!g) return;
            playAccept();
            currentGame = g;
            closeSearch();
            raEntryScreenFromSearch();
        }

        // Full-bleed blocker so touches never reach the list underneath.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed:  mouse.accepted = true
            onClicked:  mouse.accepted = true
            onReleased: mouse.accepted = true
        }
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.92)
        }

        Text {
            id: searchTitle
            anchors { top: parent.top; topMargin: vpx(28); horizontalCenter: parent.horizontalCenter }
            text: "SEARCH LIBRARY"
            color: "white"
            font.family: titleFont.name
            font.pixelSize: fpx(26)
            font.bold: true
        }

        // Query box
        Rectangle {
            id: queryBox
            anchors { top: searchTitle.bottom; topMargin: vpx(14); horizontalCenter: parent.horizontalCenter }
            width: parent.width * 0.6
            height: vpx(44)
            color: Qt.rgba(1, 1, 1, 0.10)
            border.width: vpx(2)
            border.color: theme.accent
            Text {
                anchors { left: parent.left; leftMargin: vpx(10); verticalCenter: parent.verticalCenter }
                text: searchOverlay.query === "" ? "Type to search..." : searchOverlay.query
                color: searchOverlay.query === "" ? Qt.rgba(1, 1, 1, 0.4) : "white"
                font.family: subtitleFont.name
                font.pixelSize: fpx(20)
            }
        }

        // Results
        ListView {
            id: resultList
            anchors {
                top: queryBox.bottom; topMargin: vpx(14)
                left: parent.left; leftMargin: vpx(60)
                right: parent.right; rightMargin: vpx(60)
            }
            // Results Page devotes the screen to the list once committed;
            // Instant keeps it compact above the keyboard.
            visible: searchOverlay.showingResults
            height: searchOverlay.showingResults
                    ? parent.height - y - vpx(60)
                    : 0
            clip: true
            model: searchOverlay.results
            currentIndex: 0
            delegate: Rectangle {
                width: resultList.width
                height: searchOverlay.showingResults ? vpx(76) : vpx(58)
                color: ListView.isCurrentItem ? theme.accent : Qt.rgba(1, 1, 1, 0.04)

                // Box art thumbnail — falls back through the same asset order
                // the tiles use, so a game without boxFront still shows art.
                property var raProg: searchOverlay.showingResults
                                     ? searchOverlay.raProgressFor(modelData) : null

                Rectangle {
                    id: thumbFrame
                    anchors { left: parent.left; leftMargin: vpx(8); verticalCenter: parent.verticalCenter }
                    width:  searchOverlay.showingResults ? vpx(60) : vpx(44)
                    height: width
                    color: Qt.rgba(0, 0, 0, 0.35)
                    Image {
                        anchors.fill: parent
                        anchors.margins: vpx(2)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true; smooth: true
                        source: {
                            if (!modelData) return "";
                            var a = modelData.assets;
                            return a.boxFront || a.background
                                || ((a.screenshots && a.screenshots.length) ? a.screenshots[0] : "") || "";
                        }
                    }
                }

                Column {
                    anchors {
                        left: thumbFrame.right; leftMargin: vpx(10)
                        right: sysBadge.left;   rightMargin: vpx(8)
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: vpx(3)

                    Text {
                        width: parent.width
                        text: modelData ? modelData.title : ""
                        color: "white"
                        font.family: subtitleFont.name
                        font.pixelSize: fpx(19)
                        elide: Text.ElideRight
                    }
                    // Achievement progress, but only for games already in the
                    // RA history cache — everything else stays blank rather
                    // than triggering a lookup per row.
                    Text {
                        width: parent.width
                        visible: searchOverlay.showingResults
                        text: {
                            var p = parent.parent.raProg;
                            if (!p) return "";
                            if (p.NumPossibleAchievements > 0)
                                return p.NumAchieved + " of " + p.NumPossibleAchievements + " achievements  ("
                                       + Math.floor(p.NumAchieved * 100 / p.NumPossibleAchievements) + "%)";
                            return "";
                        }
                        color: theme.accent
                        font.family: subtitleFont.name
                        font.pixelSize: fpx(15)
                        elide: Text.ElideRight
                    }
                }

                // System badge — the platform logo, which also disambiguates
                // the same title appearing on multiple systems.
                Image {
                    id: sysBadge
                    anchors { right: parent.right; rightMargin: vpx(10); verticalCenter: parent.verticalCenter }
                    height: vpx(46)
                    width: vpx(116)
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignRight
                    asynchronous: true; smooth: true
                    opacity: 0.85
                    source: (modelData && modelData.collections.count > 0)
                            ? "../assets/images/logospng/"
                              + Utils.processPlatformName(modelData.collections.get(0).shortName) + ".png"
                            : ""
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: { resultList.currentIndex = index; searchOverlay.chooseResult(); }
                }
            }
        }

        Text {
            anchors { left: queryBox.right; leftMargin: vpx(12); verticalCenter: queryBox.verticalCenter }
            visible: searchOverlay.showingResults && searchOverlay.totalMatches > 0
            text: searchOverlay.totalMatches
                  + (searchOverlay.totalMatches === 1 ? " game" : " games")
                  + (searchOverlay.totalMatches > searchOverlay.results.length ? " (showing 80)" : "")
            color: Qt.rgba(1, 1, 1, 0.6)
            font.family: subtitleFont.name
            font.pixelSize: fpx(17)
        }

        Text {
            anchors { top: resultList.top; horizontalCenter: parent.horizontalCenter }
            visible: searchOverlay.showingResults && searchOverlay.results.length === 0
            text: "No games found"
            color: Qt.rgba(1, 1, 1, 0.5)
            font.family: subtitleFont.name
            font.pixelSize: fpx(19)
        }

        // On-screen keyboard — controller-first, same idea as the All Games
        // filter panel: a grid of keys navigated with the d-pad.
        // Accent frame around the keyboard — same treatment as the theme's
        // other on-screen keyboards.
        Rectangle {
            anchors.fill: keyRow
            anchors.margins: -vpx(12)
            visible: keyRow.visible
            color: Qt.rgba(0, 0, 0, 0.35)
            radius: vpx(10)
            border.color: theme.accent
            border.width: vpx(3)
            antialiasing: true
        }

        Column {
        id: keyRow

            visible: !searchOverlay.showingResults
            // Row index == rows.length addresses the SEARCH key below the grid.
            readonly property int searchRow: rows.length
            property int row: 0
            property int col: 0
            // Three pages. Arrays (not strings) so multi-character keys like
            // SPACE and the page switches can share the grid.
            property int page: 0        // 0 letters, 1 symbols, 2 accents
            readonly property var pages: [
                [ ["A","B","C","D","E","F","G","H","I","J"],
                  ["K","L","M","N","O","P","Q","R","S","T"],
                  ["U","V","W","X","Y","Z","0","1","2","3"],
                  ["4","5","6","7","8","9","SPACE","DEL","&12","áé"] ],

                [ ["!","?",".",",",":",";","'","\"","-","_"],
                  ["(",")","[","]","{","}","<",">","/","\\"],
                  ["@","#","$","%","&","*","+","=","~","|"],
                  ["^","`","°","·","¡","¿","SPACE","DEL","ABC","áé"] ],

                [ ["À","Á","Â","Ã","Ä","Å","Æ","Ç","È","É"],
                  ["Ê","Ë","Ì","Í","Î","Ï","Ñ","Ò","Ó","Ô"],
                  ["Õ","Ö","Ø","Ù","Ú","Û","Ü","Ý","ß","Œ"],
                  ["á","é","í","ó","ú","ñ","SPACE","DEL","ABC","&12"] ]
            ]
            readonly property var rows: pages[page]

            // Type a key, or act on it when it's a command.
            function press(k) {
                if (k === "ABC")   { page = 0; clampCol(); return; }
                if (k === "&12")   { page = 1; clampCol(); return; }
                if (k === "áé")    { page = 2; clampCol(); return; }
                if (k === "SPACE") { searchOverlay.query += " "; return; }
                if (k === "DEL")   { searchOverlay.query = searchOverlay.query.slice(0, -1); return; }
                searchOverlay.query += k;
            }
            // Keep the cursor inside the row after a page switch.
            function clampCol() {
                var len = rows[row].length;
                if (col > len - 1) col = len - 1;
            }

            anchors {
                top: resultList.bottom; topMargin: vpx(16)
                horizontalCenter: parent.horizontalCenter
            }
            spacing: vpx(6)

            Repeater {
                model: keyRow.rows.length
                Row {
                    property int rowIndex: index
                    spacing: vpx(6)
                    Repeater {
                        model: keyRow.rows[rowIndex].length
                        Rectangle {
                            property string key: keyRow.rows[rowIndex][index]
                            property bool isCmd: key.length > 1
                            width: vpx(42); height: vpx(38)
                            color: (keyRow.row === rowIndex && keyRow.col === index)
                                   ? theme.accent : Qt.rgba(1, 1, 1, 0.08)
                            Text {
                                anchors.centerIn: parent
                                text: key === "SPACE" ? "\u2423"
                                      : (key === "DEL" ? "\u232B" : key)
                                color: "white"
                                font.family: subtitleFont.name
                                // Page-switch labels are 3 chars wide, so drop
                                // their size to fit the same key cell.
                                font.pixelSize: (isCmd && key !== "SPACE" && key !== "DEL") ? fpx(13) : fpx(19)
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    keyRow.row = rowIndex; keyRow.col = index;
                                    keyRow.press(key);
                                }
                            }
                        }
                    }
                }
            }

            // SEARCH key — full-width row beneath the grid. Y does the same
            // thing; this just makes it discoverable and touch-friendly.
            Rectangle {
                width: (vpx(42) * 10) + (vpx(6) * 9)     // spans the grid exactly
                height: vpx(38)
                color: (keyRow.row === keyRow.searchRow) ? theme.accent : Qt.rgba(1, 1, 1, 0.08)
                border.color: theme.accent
                border.width: (keyRow.row === keyRow.searchRow) ? 0 : vpx(2)
                Text {
                    anchors.centerIn: parent
                    text: "SEARCH"
                    color: "white"
                    font.family: subtitleFont.name
                    font.pixelSize: fpx(19)
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { keyRow.row = keyRow.searchRow; searchOverlay.commitSearch(); }
                }
            }
        }

        // Local help bar for the overlay
        Row {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: vpx(12) }
            spacing: vpx(20)
            Repeater {
                // Three prompt sets: Results Page list, Results Page keyboard,
                // and Instant. Keeps the hints honest per mode.
                model: searchOverlay.showingResults
                       ? [ { n: "Open",   b: "accept" },
                           { n: "Back",   b: "cancel" } ]
                       : [ { n: "Type",   b: "accept"  },
                           { n: "Search", b: "filters" },
                           { n: "Delete", b: "details" },
                           { n: "Close",  b: "cancel"  } ]
                delegate: Row {
                    spacing: vpx(8)
                    Image {
                        source: "../assets/images/controller/" + buttonbar.processButtonArt(modelData.b) + ".png"
                        width: vpx(30); height: vpx(30)
                        asynchronous: true
                        sourceSize { width: 48; height: 48 }
                    }
                    Text {
                        text: modelData.n
                        font.family: subtitleFont.name
                        font.pixelSize: fpx(18)
                        color: "white"
                        height: vpx(30)
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }


        // On the Results Page the d-pad drives the list; otherwise the keyboard.
        Keys.onUpPressed: {
            event.accepted = true;
            if (showingResults) {
                if (resultList.currentIndex > 0) resultList.currentIndex--;
                return;
            }
            if (keyRow.row > 0) keyRow.row--;
        }
        Keys.onDownPressed: {
            event.accepted = true;
            if (showingResults) {
                if (resultList.currentIndex < results.length - 1) resultList.currentIndex++;
                return;
            }
            if (keyRow.row < keyRow.searchRow) keyRow.row++;
        }
        Keys.onLeftPressed: {
            event.accepted = true;
            if (showingResults) return;
            if (keyRow.row === keyRow.searchRow) return;      // single full-width key
            if (keyRow.col > 0) keyRow.col--;
        }
        Keys.onRightPressed: {
            event.accepted = true;
            if (showingResults) return;
            if (keyRow.row === keyRow.searchRow) return;      // single full-width key
            if (keyRow.col < keyRow.rows[keyRow.row].length - 1) keyRow.col++;
        }
        Keys.onPressed: {
            if (event.isAutoRepeat) return;

            // ── Results Page: the list has its own, simpler mapping ──
            if (showingResults) {
                if (api.keys.isAccept(event)) {            // open highlighted game
                    event.accepted = true;
                    searchOverlay.chooseResult();
                    return;
                }
                if (api.keys.isCancel(event)) {            // back to a blank keyboard
                    event.accepted = true;
                    searchOverlay.resetSearch();
                    return;
                }
                return;
            }

            // A — type the highlighted character
            if (api.keys.isAccept(event)) {
                event.accepted = true;
                if (keyRow.row === keyRow.searchRow) searchOverlay.commitSearch();
                else keyRow.press(keyRow.rows[keyRow.row][keyRow.col]);
                return;
            }
            // Y — run the search (same as the on-screen SEARCH key)
            if (api.keys.isFilters(event)) {
                event.accepted = true;
                searchOverlay.commitSearch();
                return;
            }
            // X — backspace
            if (api.keys.isDetails(event)) {
                event.accepted = true;
                searchOverlay.query = searchOverlay.query.slice(0, -1);
                return;
            }
            // LB / RB — move through the results without leaving the keyboard
            if (api.keys.isPrevPage(event)) {
                event.accepted = true;
                if (resultList.currentIndex > 0) resultList.currentIndex--;
                return;
            }
            if (api.keys.isNextPage(event)) {
                event.accepted = true;
                if (resultList.currentIndex < searchOverlay.results.length - 1) resultList.currentIndex++;
                return;
            }
            // B — close
            if (api.keys.isCancel(event)) {
                event.accepted = true;
                searchOverlay.closeSearch();
            }
        }
    }
}
