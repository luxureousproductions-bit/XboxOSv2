// XboxOSv2 – LibrarySearch.qml
// Shared library search overlay: on-screen keyboard, query box, committed
// results page (box art, RA progress, system badge, LT/RT letter jumps).
// Lifted from AchievementsView so the RA page and the global search (Home
// nav + App Drawer) run the same code. The host owns navigation:
//
//   LibrarySearch {
//       id: search
//       anchors.fill: parent
//       onChosen: { /* go somewhere with `game` */ }
//       onClosed: { /* hand focus back */ }
//   }
//   search.openSearch();

import QtQuick 2.15
import "../utils.js" as Utils

FocusScope {
id: searchOverlay

    // ── Host interface ────────────────────────────────────────────────────
    // The host decides what a chosen game means (RA page vs Game Details)
    // and where focus goes on close; this component never navigates itself.
    signal chosen(var game)
    signal closed()
    property string title: "SEARCH LIBRARY"
    // Gates the idle index build so it only runs while the host wants it
    // (the RA page binds this to its own visibility).
    property bool warmup: true

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
        noMatch = false;
        query = "";
        results = [];
        resultProg = [];
        totalMatches = 0;
        resultList.currentIndex = 0;
        kb.page = 0;        // back to the letters page
        kb.row = 1;         // home on 'q', as the Xbox keyboard does
        kb.col = 0;
        kb.caret = 0;
        kb.shifted = false;
    }

    function openSearch() {
        buildSearchIndex();
        open = true;
        resetSearch();
        forceActiveFocus();
    }
    function closeSearch() {
        open = false;
        closed();
    }
    // Re-show the last committed results with the query and highlighted row
    // intact (B from Game Details lands here). closeSearch() never clears
    // results, so they're still in place; with nothing to show it falls back
    // to a fresh search.
    function reopenResults() {
        if (results.length === 0) { openSearch(); return; }
        open = true;
        showingResults = true;
        forceActiveFocus();
        resultList.positionViewAtIndex(resultList.currentIndex, ListView.Center);
        if (hqFadeIn) resultsIntro.restart();
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
    // Built in idle-time slices after the page loads (indexWarmup below),
    // so the first X press no longer stalls on ~4k regex normalizations.
    // buildSearchIndex() just finishes whatever slices are still left.
    property var indexBuf: []
    property int indexPos: 0
    property bool indexReady: false
    function indexSlice(n) {
        var total = api.allGames.count;
        var end = Math.min(total, indexPos + n);
        for (var i = indexPos; i < end; i++) {
            var g = api.allGames.get(i);
            indexBuf.push({ game: g, norm: cheevosData.normalizeTitle(g.title || "") });
        }
        indexPos = end;
        if (indexPos >= total) {
            searchIndex = indexBuf;
            indexReady = true;
        }
    }
    function buildSearchIndex() {
        if (indexReady) return;
        indexSlice(api.allGames.count);
    }
    Timer {
        id: indexWarmup
        interval: 16
        repeat: true
        running: !searchOverlay.indexReady && searchOverlay.warmup
        // Titles normalized per 16ms tick: smaller bites in base so a busy
        // frame on the weaker SoC never stretches into a visible hitch.
        onTriggered: searchOverlay.indexSlice(hqMode ? 250 : 120)
    }

    // RA progress for the committed results, resolved once per search
    // (one normalize per recent-game entry) instead of per delegate.
    property var resultProg: []
    property bool noMatch: false             // last commit found nothing

    // Type a query, press Search (Y or the on-screen key), then browse the
    // committed results list.
    property bool showingResults: false      // on the results list, not the keyboard

    // Real RA progress for a local game, when it's in the recently-played
    // cache. Costs nothing — anything not there simply shows no bar, since
    // fetching per result would mean an API call per row.
    function recentProgressMap() {
        var map = {};
        for (var i = 0; i < cheevosData.raRecentGames.count; i++) {
            var e = cheevosData.raRecentGames.get(i);
            var k = cheevosData.normalizeTitle(e.Title);
            if (k !== "" && !map[k]) map[k] = e;
        }
        return map;
    }

    function commitSearch() {
        playAccept();
        runSearch();
        if (results.length > 0) {
            noMatch = false;
            resultList.currentIndex = 0;
            showingResults = true;
            resultList.positionViewAtBeginning();
            if (hqFadeIn) resultsIntro.restart();
        } else {
            noMatch = query.trim() !== "";
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
            if (at === 0)      starts.push(searchIndex[i]);
            else if (at > 0)   contains.push(searchIndex[i]);
        }
        var out = starts.concat(contains);
        totalMatches = out.length;
        out = out.slice(0, 80);
        // Progress first, then results: the delegates read resultProg by
        // index, so it must be in place before the model swaps.
        var map = recentProgressMap();
        var games = [], prog = [];
        for (var j = 0; j < out.length; j++) {
            games.push(out[j].game);
            prog.push(map[out[j].norm] || null);
        }
        resultProg = prog;
        results = games;
        resultList.currentIndex = 0;
    }
    onQueryChanged: { showingResults = false; noMatch = false; }

    // Chosen game -> host. Close first (host takes focus back), then hand
    // over the game: same order the inline RA version used.
    function chooseResult() {
        if (results.length === 0) return;
        var g = results[resultList.currentIndex];
        if (!g) return;
        playAccept();
        closeSearch();
        chosen(g);
    }

    // Full-bleed blocker so touches never reach the list underneath.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onWheel: wheel.accepted = true
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
        text: searchOverlay.title
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
        // Caret — the keyboard owns the insertion point, so LB/RB movement
        // shows up here. TextMetrics is not an Item, hence the id refs.
        TextMetrics {
            id: queryCaretMetrics
            font.family: subtitleFont.name
            font.pixelSize: fpx(20)
            // TextMetrics ignores TRAILING whitespace, so "Mario " and
            // "Mario" measured the same width and the caret appeared not to
            // move when space was pressed. Substitute a glyph of comparable
            // width for measurement only; the box still shows the real text.
            text: {
                var upto = searchOverlay.query.slice(0, kb.caret);
                var trimmed = upto.replace(/ +$/, "");
                var spaces = upto.length - trimmed.length;
                return trimmed + "n".repeat(spaces);
            }
        }
        Rectangle {
            width: vpx(2)
            height: queryBox.height * 0.55
            color: theme.accent
            anchors.verticalCenter: parent.verticalCenter
            x: vpx(10) + Math.min(queryBox.width - vpx(20), queryCaretMetrics.width)
            visible: searchOverlay.query !== "" && !searchOverlay.showingResults
        }
    }

    // Results
    ListView {
        id: resultList
        // One hook covers d-pad steps, Left/Right page jumps and the
        // LT/RT letter jumps, the same way the games list does it above.
        onCurrentIndexChanged: if (searchOverlay.showingResults) playNav()
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
        // Sliding highlight + kept-off-the-edge scrolling, same feel as
        // the RA recently-played list. Off-screen rows kept built follow
        // the theme's tile cache: 2 in base, 4 in HQ.
        cacheBuffer: vpx(76) * hqCacheTiles
        highlightMoveDuration: 80
        highlightResizeDuration: 0
        preferredHighlightBegin: vpx(76)
        preferredHighlightEnd:   Math.max(vpx(152), height - vpx(76))
        highlightRangeMode: ListView.ApplyRange
        highlight: Rectangle {
            width: resultList.width
            color: theme.accent
        }
        // Entry motion for the results page: a short fade + rise, so the
        // commit reads as a response rather than a hard cut. HQ only
        // (hqFadeIn); base shows the list immediately.
        transform: Translate { id: resultsShift; y: 0 }
        ParallelAnimation {
            id: resultsIntro
            NumberAnimation { target: resultList;  property: "opacity"; from: 0; to: 1; duration: 130; easing.type: Easing.OutCubic }
            NumberAnimation { target: resultsShift; property: "y"; from: vpx(14); to: 0; duration: 130; easing.type: Easing.OutCubic }
        }
        delegate: Rectangle {
            width: resultList.width
            height: searchOverlay.showingResults ? vpx(76) : vpx(58)
            // Current row is painted by the sliding highlight underneath.
            color: ListView.isCurrentItem ? "transparent" : Qt.rgba(1, 1, 1, 0.04)

            // Box art thumbnail — falls back through the same asset order
            // the tiles use, so a game without boxFront still shows art.
            property var raProg: searchOverlay.resultProg[index] || null

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
                    // Decode at thumbnail size, not full box-art size —
                    // the main cost of building a page of rows. Same rule as
                    // tile art: display size x hqTileDecodeScale (1.25 / 1.5).
                    sourceSize {
                        width:  Math.round(vpx(60) * hqTileDecodeScale)
                        height: Math.round(vpx(60) * hqTileDecodeScale)
                    }
                    // HQ dissolves art in on load; base shows it as it lands.
                    opacity: hqFadeIn ? (status === Image.Ready ? 1 : 0) : 1
                    Behavior on opacity { enabled: hqFadeIn; NumberAnimation { duration: 180 } }
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
                sourceSize {
                    width:  Math.round(vpx(116) * hqTileDecodeScale)
                    height: Math.round(vpx(46)  * hqTileDecodeScale)
                }
                opacity: 0.85
                source: (modelData && modelData.collections.count > 0)
                        ? systemLogoSource(modelData.collections.get(0)) : ""
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
        // Search on a query with no hits used to do nothing at all (the
        // results page only opens for >0 hits); say so above the keyboard.
        visible: searchOverlay.noMatch && !searchOverlay.showingResults
        text: "No games found"
        color: Qt.rgba(1, 1, 1, 0.5)
        font.family: subtitleFont.name
        font.pixelSize: fpx(19)
    }

    // On-screen keyboard — controller-first, same idea as the All Games
    // filter panel: a grid of keys navigated with the d-pad.
    // ── Keyboard: shared component ───────────────────────────────────
    // Replaces the old inline key grid. The overlay still owns `query`;
    // the keyboard edits a copy and reports back via onTextEdited.
    VirtualKeyboard {
    id: kb

        // Component sizes itself; anchor it bottom-centre like the Xbox
        // keyboard rather than filling the overlay.
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: vpx(70)
        }
        visible: !searchOverlay.showingResults
        focus: !searchOverlay.showingResults
        // The overlay already draws SEARCH LIBRARY + the query box above,
        // so the keyboard must not draw its own or they appear twice.
        title: ""
        showTextField: false
        text: searchOverlay.query

        // textEdited carries the new string — the overlay owns `query`.
        onTextEdited:  searchOverlay.query = newText
        onAccepted:    searchOverlay.commitSearch()
        onCancelled:   searchOverlay.closeSearch()
    }

    // Results-page help prompts. The keyboard draws its own while typing.
    Row {
        visible: searchOverlay.showingResults
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: vpx(12) }
        spacing: vpx(20)
        Repeater {
            model: [ { n: "Open", b: "accept" },
                     { n: "Back", b: "cancel" } ]
            delegate: Row {
                TapHandler { gesturePolicy: TapHandler.WithinBounds; onTapped: helpClick(modelData.b) }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                spacing: vpx(8)
                Image {
                    source: "../assets/images/controller/" + buttonbar.processButtonArt(modelData.b) + ".png"
                    width: vpx(30); height: vpx(30)
                    asynchronous: true
                    sourceSize { width: hrpx(48); height: hrpx(48) }
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

    // Results list navigation. While typing, the keyboard has focus and
    // handles its own input, so these only run on the results page.
    Keys.onUpPressed: {
        event.accepted = true;
        if (showingResults && resultList.currentIndex > 0) resultList.currentIndex--;
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (showingResults && resultList.currentIndex < results.length - 1) resultList.currentIndex++;
    }
    // ── Fast travel through a long result list ───────────────────────
    // Left/Right page by 10; RT/LT jump to the next/previous letter group.
    // Non-alphabetic titles all collapse into one "#" bucket so a run of
    // numbered games is a single stop rather than one per digit.
    function letterGroup(title) {
        var c = (title || "").charAt(0).toUpperCase();
        return (c >= "A" && c <= "Z") ? c : "#";
    }
    function jumpLetter(dir) {
        var n = results.length;
        if (n === 0) return;
        var cur = resultList.currentIndex;
        var curLtr = letterGroup(results[cur] ? results[cur].title : "");
        if (dir > 0) {
            for (var i = cur + 1; i < n; i++) {
                if (letterGroup(results[i].title) !== curLtr) { resultList.currentIndex = i; return; }
            }
            resultList.currentIndex = 0;                 // wrap to the top
        } else {
            if (cur <= 0) { resultList.currentIndex = n - 1; return; }
            var prevLtr = letterGroup(results[cur - 1].title);
            for (var j = cur - 2; j >= 0; j--) {
                if (letterGroup(results[j].title) !== prevLtr) { resultList.currentIndex = j + 1; return; }
            }
            resultList.currentIndex = 0;
        }
    }

    Keys.onLeftPressed: {
        event.accepted = true;
        if (!showingResults) return;
        resultList.currentIndex = Math.max(0, resultList.currentIndex - 10);
    }
    Keys.onRightPressed: {
        event.accepted = true;
        if (!showingResults) return;
        resultList.currentIndex = Math.min(results.length - 1, resultList.currentIndex + 10);
    }

    // Clickable prompts: the search is modal, so it claims every button.
    function helpAction(button) {
        if (!showingResults) { if (button === "cancel") { playBack(); searchOverlay.closeSearch(); } return true; }
        if (button === "accept") searchOverlay.chooseResult();
        else if (button === "cancel") { playBack(); searchOverlay.resetSearch(); }
        return true;
    }

    Keys.onPressed: {
        if (event.isAutoRepeat) return;
        if (!showingResults) return;
        if (api.keys.isAccept(event)) {            // open highlighted game
            event.accepted = true;
            searchOverlay.chooseResult();
            return;
        }
        if (api.keys.isNextPage(event)) {          // RT — next letter
            event.accepted = true;
            playToggle();
            searchOverlay.jumpLetter(1);
            return;
        }
        if (api.keys.isPrevPage(event)) {          // LT — previous letter
            event.accepted = true;
            playToggle();
            searchOverlay.jumpLetter(-1);
            return;
        }
        if (api.keys.isCancel(event)) {            // back to a blank keyboard
            event.accepted = true;
            playBack();
            searchOverlay.resetSearch();
            return;
        }
    }
}
