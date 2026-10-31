// XboxOSv2 – RAGamingTab.qml
// The Gaming tab of the RetroAchievements page, after the Xbox Series
// achievements page: a left rail, quick buttons, Sort and Filter, and every
// game you've played as a card with its progress. Mastered games (RA's 100%
// in hardcore) wear the Mythic-style frame (RAMythicFrame.qml).
//
// Data: cheevosData.raLibrary (CheevosData.loadLibrary). The list is a JS
// array rebuilt only when the library, Sort or Filter changes, never per row.
//
// Toolbar, as on the console: the sort (a drop-down), its direction, then on
// the right "Filter applied" (only when a filter is on), Filter (a pop-up:
// RAFilterDialog with this tab's columns) and Search, which slides a search
// bar out over the right of the toolbar with the on-screen keyboard; the
// list narrows to matching titles as you type.
//
// Focus, top to bottom: quick buttons -> the toolbar -> the game list.
// Up/Down move between them, Left/Right inside a row, A presses. Left from
// the start of a row reaches the rail (Achievements / Leaderboards), where
// Up/Down switch views and Right goes back.
//
// Leaderboards: your games (most recent first); A on one lists its
// leaderboards with the #1 and your entry, A on a leaderboard opens its top
// 100 (RALeaderboardPanel), B steps back out.

import QtQuick 2.15
import QtGraphicalEffects 1.15
import "../Global"

FocusScope {
id: tab

    // ── Sort / Filter state ──────────────────────────────────────────────
    readonly property var sortNames:   ["Last played", "Completion", "Title", "Achievements unlocked"]
    property int sortIndex:   0
    // Descending: newest / highest / Z-A / most first. Each sort starts in
    // its natural direction (Title A-Z, the rest descending).
    property bool descending: true
    // Filters (the pop-up's columns): status and mode.
    readonly property var filterColumns: [
        { title: "Status", keys: ["all", "progress", "mythic", "beaten", "unbeaten"],
          names: ["All", "In progress", "Mythic", "Beaten", "Not beaten"] },
        { title: "Mode", keys: ["all", "hardcore", "softcore"],
          names: ["All", "Hardcore", "Softcore only"] }
    ]
    property var filters: ["all", "all"]
    readonly property bool filtered: filters[0] !== "all" || filters[1] !== "all"
    property string query: ""
    property var games: []

    readonly property var chips: ["Closest to mastery", "Recently unlocked", "Mythic"]
    // Mythic, as on the Xbox, is 100% of a game's achievements: RA's
    // Mastered (hardcore) or Completed (softcore). The card label still
    // says which.
    function isMythic(g) { return g.Award === "mastered" || g.Award === "completed"; }
    function applyChip(i) {
        if (i === 0)      { setSort(1); filters = ["progress", "all"]; }   // highest % that isn't done yet
        else if (i === 1) { setSort(0); filters = ["all", "all"]; }
        else              { setSort(0); filters = ["mythic", "all"]; }
        zone = 2;
    }
    function setSort(i) { sortIndex = i; descending = sortNames[i] !== "Title"; }

    function isBeaten(g) { return g.Award === "beaten-hardcore" || g.Award === "beaten-softcore" || isMythic(g); }
    function keep(g, q) {
        switch (filters[0]) {
        case "progress": if (isMythic(g) || g.Progress >= 1) return false; break;
        case "mythic":   if (!isMythic(g)) return false; break;
        case "beaten":   if (!isBeaten(g)) return false; break;
        case "unbeaten": if (isBeaten(g)) return false; break;
        }
        if (filters[1] === "hardcore" && !(g.NumAwardedHardcore > 0)) return false;
        if (filters[1] === "softcore" && g.NumAwardedHardcore > 0) return false;
        return q === "" || cheevosData.titleKey(g.Title).indexOf(q) >= 0;
    }
    function rebuild() {
        var m = cheevosData.raLibrary, out = [], q = query !== "" ? cheevosData.titleKey(query) : "";
        for (var i = 0; i < m.count; i++) { var g = m.get(i); if (keep(g, q)) out.push(g); }
        // Written descending; ascending is the same comparison turned round.
        var d = descending ? 1 : -1, cmp;
        switch (sortIndex) {
        case 1:  cmp = function(a, b) { return b.Progress - a.Progress || b.NumAwarded - a.NumAwarded; }; break;
        case 2:  cmp = function(a, b) { return String(b.Title).localeCompare(String(a.Title)); }; break;
        case 3:  cmp = function(a, b) { return b.NumAwarded - a.NumAwarded; }; break;
        default: cmp = function(a, b) { return String(b.LastUnlock).localeCompare(String(a.LastUnlock)); };
        }
        out.sort(function(a, b) { return d * cmp(a, b); });
        games = out;
        list.currentIndex = 0;
        // Leaderboards: every game, most recent first.
        var all = [];
        for (var j = 0; j < m.count; j++) all.push(m.get(j));
        all.sort(function(a, b) { return String(b.LastUnlock).localeCompare(String(a.LastUnlock)); });
        lbGames = all;
    }

    // ── Leaderboards state ───────────────────────────────────────────────
    property var lbGames: []
    property int lbLevel: 0        // 0 your games, 1 the picked game's leaderboards
    property var lbGame: null
    property int lbGameIndex: 0
    property int lbBoardIndex: 0
    readonly property var lbBoards: lbGame && cheevosData.leaderboardsFor === parseInt(lbGame.GameID) ? cheevosData.leaderboards : []
    function openLbGame() {
        if (lbGameIndex < 0 || lbGameIndex >= lbGames.length) return;
        playAccept();
        lbGame = lbGames[lbGameIndex];
        lbBoardIndex = 0;
        cheevosData.loadLeaderboards(parseInt(lbGame.GameID));
        lbLevel = 1;
    }
    function openBoard() {
        if (lbBoardIndex < 0 || lbBoardIndex >= lbBoards.length) return;
        boardPanel.open(lbBoards[lbBoardIndex]);
    }
    function lbBack() { lbLevel = 0; playBack(); }
    // For the page's help bar (AchievementsView): "board" while the top 100
    // is open, "boards" on a game's leaderboards, "games" on the game list.
    readonly property string helpState: boardPanel.visible ? "board"
        : filterDlg.visible ? (filterDlg.col === filterDlg.applyCol ? "filtersApply" : "filters")
        : sortMenuOpen ? "menu" : searching ? "keyboard"
        : (railIndex === 1 && !railFocus) ? (lbLevel === 1 ? "boards" : "games") : ""
    function helpAction(b) {
        if (filterDlg.visible) {
            if (b === "accept") filterDlg.accept(); else if (b === "cancel") filterDlg.close(false);
            return true;
        }
        if (sortMenuOpen) {
            if (b === "accept") pickSort(); else if (b === "cancel") { sortMenuOpen = false; playBack(); }
            return true;
        }
        if (searching) return true;
        if (boardPanel.visible) {
            if (b === "cancel") boardPanel.close();
            return true;
        }
        if (railIndex === 1 && !railFocus) {
            if (b === "cancel" && lbLevel === 1) { lbBack(); return true; }
            if (b === "accept") { if (lbLevel === 0) openLbGame(); else openBoard(); return true; }
        }
        return false;
    }
    onSortIndexChanged:  rebuild()
    onDescendingChanged: rebuild()
    onFiltersChanged:    rebuild()
    onQueryChanged:      rebuild()
    Connections {
        target: cheevosData
        onLibraryLoadedChanged: if (cheevosData.libraryLoaded) tab.rebuild()
    }
    Component.onCompleted: if (cheevosData.libraryLoaded) rebuild()

    // ── Colours (cards follow the background: dark on Dark, white on Light)
    readonly property color cardColor: whiteBackground ? "#ffffff" : "#303030"
    readonly property color railSel:   whiteBackground ? "#ffffff" : "#2b2b2b"
    readonly property color cAccent:   theme.accent
    function mixc(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1); }

    // ── Focus zones ──────────────────────────────────────────────────────
    property int zone: 2          // 0 quick buttons, 1 Sort/Filter, 2 list
    property int chipIndex: 0
    property int toolIndex: 0     // 0 Sort, 1 direction, 2 Filter, 3 Search
    readonly property int toolCount: 4
    // The sort drop-down (opened from the sort box).
    property bool sortMenuOpen: false
    property int sortMenuIndex: 0
    function openSortMenu() { sortMenuIndex = sortIndex; sortMenuOpen = true; playAccept(); }
    function pickSort() { sortMenuOpen = false; playAccept(); if (sortMenuIndex !== sortIndex) setSort(sortMenuIndex); }
    // Search: the bar slides out while the keyboard is up.
    property bool searching: false
    function openSearch() { searching = true; playAccept(); }
    function closeSearch() { searching = false; tab.forceActiveFocus(); }
    // From Welcome's "Search games": straight into the search bar.
    function startSearch() {
        railIndex = 0; railFocus = false; zone = 1; toolIndex = 3;
        Qt.callLater(openSearch);
    }
    function openFilters() { filterDlg.open(filters); }
    function pressTool() {
        if (toolIndex === 0) openSortMenu();
        else if (toolIndex === 1) { descending = !descending; playToggle(); }
        else if (toolIndex === 2) openFilters();
        else openSearch();
    }
    readonly property var railNames: ["Achievements", "Leaderboards"]
    property int railIndex: 0
    property bool railFocus: false
    readonly property bool accentIsLight: (0.299 * cAccent.r + 0.587 * cAccent.g + 0.114 * cAccent.b) > 0.62
    readonly property bool popupOpen: boardPanel.visible || filterDlg.visible || searching
    onActiveFocusChanged: if (activeFocus && !popupOpen) list.forceActiveFocus()

    // ── Left rail ────────────────────────────────────────────────────────
    Item {
    id: rail
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: vpx(322)
        Column {
            y: vpx(41); width: parent.width
            Repeater {
                model: tab.railNames
                delegate: Rectangle {
                    readonly property bool on: index === tab.railIndex
                    readonly property bool hot: on && tab.railFocus && tab.activeFocus
                    width: rail.width; height: vpx(42)
                    color: hot ? theme.accent : (on ? tab.railSel : "transparent")
                    readonly property color ink: hot ? (tab.accentIsLight ? "#111111" : "white") : theme.text
                    Rectangle {
                        visible: parent.on && !parent.hot
                        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                        width: vpx(5); color: theme.accent
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: vpx(74); verticalCenter: parent.verticalCenter }
                        text: modelData
                        color: parent.ink; opacity: parent.on ? 1 : 0.8
                        font.family: bodyFont.name
                        font.pixelSize: fpx(17)
                    }
                    TapHandler { onTapped: { tab.railIndex = index; tab.railFocus = true; tab.forceActiveFocus(); playNav(); } }
                }
            }
        }
    }
    Rectangle {
        anchors { left: rail.right; top: parent.top; bottom: parent.bottom }
        width: vpx(1); color: theme.text; opacity: 0.12
    }

    // ── Quick buttons, Sort and Filter ───────────────────────────────────
    Item {
    id: content
        visible: tab.railIndex === 0
        anchors { left: rail.right; leftMargin: vpx(46); right: parent.right; rightMargin: vpx(45); top: parent.top; bottom: parent.bottom }

        Row {
        id: chipRow
            y: vpx(24)
            spacing: vpx(12)
            Repeater {
                model: tab.chips
                delegate: Rectangle {
                    readonly property bool hot: tab.zone === 0 && tab.chipIndex === index && tab.activeFocus && !tab.railFocus
                    width: chipText.implicitWidth + vpx(32); height: vpx(40)
                    color: tab.cardColor
                    radius: vpx(4)
                    RAFocus { on: parent.hot }
                    Text {
                    id: chipText
                        anchors.centerIn: parent
                        text: modelData
                        color: theme.text
                        font.family: bodyFont.name
                        font.pixelSize: fpx(16)
                    }
                    TapHandler { onTapped: { tab.chipIndex = index; tab.applyChip(index); playAccept(); } }
                }
            }
        }

        Item {
        id: toolRow
            anchors { left: parent.left; right: parent.right }
            y: vpx(77); height: vpx(42)
            // The sort: a drop-down of the four orders.
            Rectangle {
            id: sortBox
                readonly property bool hot: tab.zone === 1 && tab.toolIndex === 0 && tab.activeFocus && !tab.railFocus && !tab.sortMenuOpen
                width: vpx(330); height: parent.height
                color: tab.cardColor
                radius: vpx(4)
                RAFocus { on: sortBox.hot }
                Text {
                    anchors { left: parent.left; leftMargin: vpx(14); right: sortChevron.left; rightMargin: vpx(8); verticalCenter: parent.verticalCenter }
                    elide: Text.ElideRight
                    text: tab.sortNames[tab.sortIndex]
                    color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(16)
                }
                RAIcon {
                id: sortChevron
                    anchors { right: parent.right; rightMargin: vpx(14); verticalCenter: parent.verticalCenter }
                    source: "../assets/images/fluent/chevron_down.svg"
                }
                TapHandler { onTapped: { tab.zone = 1; tab.toolIndex = 0; tab.forceActiveFocus(); tab.openSortMenu(); } }
            }
            // Its direction.
            Rectangle {
            id: dirBtn
                readonly property bool hot: tab.zone === 1 && tab.toolIndex === 1 && tab.activeFocus && !tab.railFocus
                anchors { left: sortBox.right; leftMargin: vpx(10) }
                width: parent.height; height: parent.height
                color: tab.cardColor
                radius: vpx(4)
                RAFocus { on: dirBtn.hot }
                RAIcon {
                    anchors.centerIn: parent
                    size: vpx(20)
                    source: "../assets/images/fluent/" + (tab.descending ? "arrow_sort_down" : "arrow_sort_up") + ".svg"
                }
                TapHandler { onTapped: { tab.zone = 1; tab.toolIndex = 1; tab.forceActiveFocus(); tab.descending = !tab.descending; playToggle(); } }
            }
            Text {
                anchors { left: dirBtn.right; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                text: tab.games.length + (tab.games.length === 1 ? " game" : " games")
                      + (tab.query !== "" ? "  \u00B7  \u201C" + tab.query + "\u201D" : "")
                color: theme.text; opacity: 0.6
                font.family: bodyFont.name; font.pixelSize: fpx(15)
            }
            // Right: [Filter applied] [Filter] [Search]
            Text {
                visible: tab.filtered
                anchors { right: filterBox.left; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                text: "Filter applied"
                color: theme.text; opacity: 0.6
                font.family: bodyFont.name; font.pixelSize: fpx(16)
            }
            Rectangle {
            id: filterBox
                readonly property bool hot: tab.zone === 1 && tab.toolIndex === 2 && tab.activeFocus && !tab.railFocus
                anchors { right: searchBtn.left; rightMargin: vpx(10) }
                width: filterRow.implicitWidth + vpx(32); height: parent.height
                color: tab.cardColor
                radius: vpx(4)
                RAFocus { on: filterBox.hot }
                Row {
                id: filterRow
                    anchors.centerIn: parent
                    spacing: vpx(8)
                    RAIcon { source: "../assets/images/fluent/filter.svg"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Filter"; color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(16) }
                }
                TapHandler { onTapped: { tab.zone = 1; tab.toolIndex = 2; tab.forceActiveFocus(); tab.openFilters(); } }
            }
            Rectangle {
            id: searchBtn
                readonly property bool hot: tab.zone === 1 && tab.toolIndex === 3 && tab.activeFocus && !tab.railFocus && !tab.searching
                anchors.right: parent.right
                width: parent.height; height: parent.height
                color: tab.searching ? theme.accent : tab.cardColor
                radius: vpx(4)
                RAFocus { on: searchBtn.hot }
                RAIcon { anchors.centerIn: parent; size: vpx(20); source: "../assets/images/fluent/search.svg" }
                // A dot while a search narrows the list.
                Rectangle {
                    visible: tab.query !== "" && !tab.searching
                    anchors { right: parent.right; top: parent.top; margins: vpx(6) }
                    width: vpx(8); height: width; radius: width / 2
                    color: theme.accent
                }
                TapHandler { onTapped: { tab.zone = 1; tab.toolIndex = 3; tab.forceActiveFocus(); tab.openSearch(); } }
            }
            // The search bar slides out of the Search button, over Filter.
            Rectangle {
            id: searchBar
                anchors { right: searchBtn.left; rightMargin: vpx(10); verticalCenter: parent.verticalCenter }
                height: parent.height
                width: tab.searching ? vpx(440) : 0
                Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                visible: width > 0
                clip: true
                radius: vpx(3)
                color: "white"
                border.width: vpx(3); border.color: theme.accent
                Text {
                    anchors { left: parent.left; leftMargin: vpx(18); right: parent.right; rightMargin: vpx(12); verticalCenter: parent.verticalCenter }
                    elide: Text.ElideLeft
                    text: tab.query !== "" ? tab.query : "Search games"
                    color: tab.query !== "" ? "#111111" : "#6b6b6b"
                    font.family: bodyFont.name; font.pixelSize: fpx(17)
                }
            }
        }

        // The sort drop-down, under the sort box.
        RASortMenu {
        id: sortMenu
            visible: tab.sortMenuOpen
            x: sortBox.x; y: toolRow.y + toolRow.height + vpx(4)
            width: sortBox.width
            names: tab.sortNames
            current: tab.sortIndex
            index: tab.sortMenuIndex
            hasFocus: tab.activeFocus
            onPicked: { tab.sortMenuIndex = i; tab.pickSort(); }
        }

        // ── The games ────────────────────────────────────────────────────
        ListView {
        id: list
            // Clipped so scrolled cards don't slide over Sort/Filter; the
            // padding keeps the focus outline and the frame glow inside.
            // The tab's Keys do all moves (keyNavigationEnabled off).
            // Padding = the focus frame's reach (gap + ring + glow), so the
            // clip never cuts it; the list ends above the button prompts.
            anchors { left: parent.left; leftMargin: -vpx(14); right: parent.right; rightMargin: -vpx(14); top: parent.top; topMargin: vpx(117); bottom: parent.bottom; bottomMargin: helpMargin }
            leftMargin: vpx(14); rightMargin: vpx(14); topMargin: vpx(14); bottomMargin: vpx(14)
            model: tab.games
            spacing: vpx(14)          // = the top padding, so no sliver of the card above shows
            clip: true
            keyNavigationEnabled: false
            cacheBuffer: vpx(300)
            focus: tab.zone === 2
            highlightMoveDuration: 120
            // The focused card sits in the top slot while scrolling, so the
            // card above is always fully out of view (no sliver in the padding).
            preferredHighlightBegin: vpx(14)
            preferredHighlightEnd: vpx(14) + vpx(124)
            highlightRangeMode: ListView.StrictlyEnforceRange
            property bool navReady: false
            Component.onCompleted: navReady = true
            onCurrentIndexChanged: if (navReady && tab.activeFocus) playNav()

            Text {
                anchors { top: parent.top; topMargin: vpx(30); horizontalCenter: parent.horizontalCenter }
                visible: tab.games.length === 0
                text: cheevosData.libraryLoading ? "Loading your games…"
                    : (cheevosData.libraryLoaded ? "No games here" : (cheevosData.statusText || "No games yet"))
                color: theme.text; opacity: 0.55
                font.family: bodyFont.name; font.pixelSize: fpx(18)
            }

            delegate: Item {
            id: card
                readonly property var g: modelData
                readonly property bool mastered: tab.isMythic(g)     // the Mythic look
                readonly property bool selected: ListView.isCurrentItem && tab.zone === 2 && tab.activeFocus && !tab.railFocus && !tab.popupOpen
                readonly property int pct: g.MaxPossible > 0 ? Math.floor(g.NumAwarded * 100 / g.MaxPossible) : 0
                width: list.width - vpx(28); height: vpx(124)

                Rectangle {
                    anchors.fill: parent
                    radius: vpx(4)
                    color: tab.cardColor
                    // A mastered card warms toward your accent on the right, as on the Xbox.
                    gradient: card.mastered ? masteredGrad : null
                    Gradient {
                    id: masteredGrad
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: tab.cardColor }
                        GradientStop { position: 1.0; color: tab.mixc(tab.cardColor, tab.cAccent, 0.22) }
                    }
                }
                RAFocus { on: card.selected }
                RAMythicFrame {
                id: artBox
                    x: vpx(5); anchors.verticalCenter: parent.verticalCenter
                    width: vpx(114); height: width
                    mastered: card.mastered
                    source: g.ImageIcon ? "https://media.retroachievements.org" + g.ImageIcon : ""
                }
                Column {
                    anchors { left: artBox.right; leftMargin: vpx(22); right: parent.right; rightMargin: vpx(22); verticalCenter: parent.verticalCenter }
                    spacing: vpx(3)
                    Text {
                        width: parent.width
                        text: g.Title
                        elide: Text.ElideRight
                        color: theme.text
                        font.family: titleFont.name; font.pixelSize: fpx(19)
                    }
                    Text {
                        text: g.ConsoleName
                        color: theme.text; opacity: 0.6
                        font.family: bodyFont.name; font.pixelSize: fpx(13)
                    }
                    Item {
                        width: parent.width; height: vpx(38)
                        Row {
                            anchors.bottom: parent.bottom; anchors.bottomMargin: vpx(4)
                            spacing: vpx(8)
                            Image {
                                width: vpx(18); height: width
                                anchors.verticalCenter: parent.verticalCenter
                                source: "../assets/images/trophy_outline.svg"
                                sourceSize: Qt.size(hrpx(24), hrpx(24))
                                layer.enabled: whiteBackground
                                layer.effect: ColorOverlay { color: theme.text }
                            }
                            Text {
                                text: g.NumAwarded + "/" + g.MaxPossible
                                color: theme.text
                                font.family: bodyFont.name; font.pixelSize: fpx(16)
                            }
                            Item { width: vpx(10); height: 1; visible: g.Award === "beaten-hardcore" || g.Award === "beaten-softcore" }
                            RAIcon {
                                size: vpx(14)
                                visible: g.Award === "beaten-hardcore" || g.Award === "beaten-softcore"
                                anchors.verticalCenter: parent.verticalCenter
                                source: "../assets/images/fluent/flag.svg"
                                opacity: 0.7
                            }
                            Text {
                                leftPadding: (g.Award === "beaten-hardcore" || g.Award === "beaten-softcore") ? 0 : vpx(18)
                                visible: g.Award !== ""
                                text: g.Award === "mastered" ? "MASTERED"
                                    : g.Award === "completed" ? "COMPLETED"
                                    : g.Award === "beaten-hardcore" ? "BEATEN" : "BEATEN · SOFTCORE"
                                color: card.mastered ? tab.mixc(tab.cAccent, Qt.rgba(1, 1, 1, 1), whiteBackground ? 0 : 0.5) : theme.text
                                opacity: card.mastered ? 1 : 0.7
                                font.family: titleFont.name; font.pixelSize: fpx(13)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        Text {
                            anchors { right: parent.right; bottom: parent.bottom }
                            text: card.pct + "%"
                            color: theme.text
                            font.family: bodyFont.name; font.pixelSize: fpx(32)
                        }
                    }
                    Item {
                        width: parent.width; height: vpx(4)
                        Rectangle { anchors.fill: parent; color: theme.text; opacity: 0.15 }
                        Rectangle {
                            width: parent.width * Math.min(1, card.pct / 100); height: parent.height
                            color: tab.mixc(tab.cAccent, Qt.rgba(1, 1, 1, 1), whiteBackground ? 0 : 0.25)
                        }
                    }
                }
                TapHandler {
                    onTapped: {
                        if (card.selected) tab.openGame(index);
                        else { tab.zone = 2; list.currentIndex = index; tab.forceActiveFocus(); }
                    }
                }
            }
        }
        WheelNav {
            anchors.fill: list
            view: list
            columns: 1
            active: tab.visible && content.visible && !searchOpen
            onStepped: function(quiet) { if (!quiet) playNav(); }
        }
    }

    // ── Leaderboards ─────────────────────────────────────────────────────
    Item {
    id: lbView
        visible: tab.railIndex === 1
        anchors { left: rail.right; leftMargin: vpx(46); right: parent.right; rightMargin: vpx(45); top: parent.top; bottom: parent.bottom }

        // Heading: what's listed, and on a game its art and title.
        Item {
        id: lbHead
            anchors { left: parent.left; right: parent.right }
            y: vpx(24); height: vpx(78)
            Image {
            id: lbHeadArt
                visible: tab.lbLevel === 1
                width: visible ? vpx(64) : 0; height: vpx(64)
                anchors.verticalCenter: parent.verticalCenter
                source: tab.lbGame && tab.lbGame.ImageIcon ? "https://media.retroachievements.org" + tab.lbGame.ImageIcon : ""
                sourceSize: Qt.size(hrpx(96), hrpx(96))
                asynchronous: true; smooth: false
            }
            Column {
                anchors { left: lbHeadArt.right; leftMargin: tab.lbLevel === 1 ? vpx(18) : 0; right: parent.right; verticalCenter: parent.verticalCenter }
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: tab.lbLevel === 1 && tab.lbGame ? tab.lbGame.Title : "Leaderboards"
                    color: theme.text; font.family: titleFont.name; font.pixelSize: fpx(22)
                }
                Text {
                    text: tab.lbLevel === 1
                          ? (cheevosData.leaderboardsState === 1 ? (tab.lbGame ? tab.lbGame.ConsoleName : "")
                             : tab.lbBoards.length + (tab.lbBoards.length === 1 ? " leaderboard" : " leaderboards") + (tab.lbGame ? "  \u00B7  " + tab.lbGame.ConsoleName : ""))
                          : "Pick a game to see its leaderboards"
                    color: theme.text; opacity: 0.6
                    font.family: bodyFont.name; font.pixelSize: fpx(15)
                }
            }
        }

        // Your games
        ListView {
        id: lbGameList
            visible: tab.lbLevel === 0
            anchors { left: parent.left; leftMargin: -vpx(14); right: parent.right; rightMargin: -vpx(14); top: parent.top; topMargin: vpx(110); bottom: parent.bottom; bottomMargin: helpMargin }
            leftMargin: vpx(14); rightMargin: vpx(14); topMargin: vpx(14); bottomMargin: vpx(14)
            clip: true
            model: tab.lbGames
            spacing: vpx(10)
            keyNavigationEnabled: false
            currentIndex: tab.lbGameIndex
            highlightMoveDuration: 120
            preferredHighlightBegin: vpx(14)
            preferredHighlightEnd: height - vpx(14)
            highlightRangeMode: ListView.ApplyRange
            Text {
                anchors { top: parent.top; topMargin: vpx(30); horizontalCenter: parent.horizontalCenter }
                visible: tab.lbGames.length === 0
                text: cheevosData.libraryLoading ? "Loading your games\u2026" : "No games yet"
                color: theme.text; opacity: 0.55
                font.family: bodyFont.name; font.pixelSize: fpx(18)
            }
            delegate: Rectangle {
            id: lbGameCard
                readonly property bool hot: index === tab.lbGameIndex && !tab.railFocus && tab.activeFocus && !boardPanel.visible
                width: lbGameList.width - lbGameList.leftMargin - lbGameList.rightMargin
                height: vpx(84)
                radius: vpx(4); color: tab.cardColor
                RAFocus { on: lbGameCard.hot }
                Image {
                id: lbIcon
                    x: vpx(5); anchors.verticalCenter: parent.verticalCenter
                    width: vpx(74); height: width
                    source: modelData.ImageIcon ? "https://media.retroachievements.org" + modelData.ImageIcon : ""
                    sourceSize: Qt.size(hrpx(96), hrpx(96))
                    asynchronous: true; smooth: false
                }
                Column {
                    anchors { left: lbIcon.right; leftMargin: vpx(20); right: lbChev.left; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                    Text { width: parent.width; elide: Text.ElideRight; text: modelData.Title; color: theme.text; font.family: titleFont.name; font.pixelSize: fpx(18) }
                    Text { text: modelData.ConsoleName; color: theme.text; opacity: 0.6; font.family: bodyFont.name; font.pixelSize: fpx(13) }
                }
                RAIcon {
                id: lbChev
                    anchors { right: parent.right; rightMargin: vpx(22); verticalCenter: parent.verticalCenter }
                    size: vpx(26)
                    source: "../assets/images/fluent/data_bar_vertical.svg"
                    opacity: 0.7
                }
                TapHandler {
                    onTapped: {
                        tab.railFocus = false; tab.forceActiveFocus();
                        if (tab.lbGameIndex === index) tab.openLbGame(); else { tab.lbGameIndex = index; playNav(); }
                    }
                }
            }
        }

        // The picked game's leaderboards: the #1 and your entry.
        ListView {
        id: lbBoardList
            visible: tab.lbLevel === 1
            anchors { left: parent.left; leftMargin: -vpx(14); right: parent.right; rightMargin: -vpx(14); top: parent.top; topMargin: vpx(110); bottom: parent.bottom; bottomMargin: helpMargin }
            leftMargin: vpx(14); rightMargin: vpx(14); topMargin: vpx(14); bottomMargin: vpx(14)
            clip: true
            model: tab.lbBoards
            spacing: vpx(12)
            keyNavigationEnabled: false
            currentIndex: tab.lbBoardIndex
            highlightMoveDuration: 120
            preferredHighlightBegin: vpx(14)
            preferredHighlightEnd: height - vpx(14)
            highlightRangeMode: ListView.ApplyRange
            Text {
                anchors { top: parent.top; topMargin: vpx(30); horizontalCenter: parent.horizontalCenter }
                visible: tab.lbBoards.length === 0
                text: cheevosData.leaderboardsState === 1 ? "Loading leaderboards\u2026" : "This game has no leaderboards"
                color: theme.text; opacity: 0.55
                font.family: bodyFont.name; font.pixelSize: fpx(18)
            }
            delegate: Rectangle {
            id: boardCard
                readonly property var lb: modelData
                readonly property bool hot: index === tab.lbBoardIndex && !tab.railFocus && tab.activeFocus && !boardPanel.visible
                width: lbBoardList.width - lbBoardList.leftMargin - lbBoardList.rightMargin
                height: vpx(100)
                radius: vpx(4); color: tab.cardColor
                RAFocus { on: boardCard.hot }
                Rectangle {
                id: boardIcon
                    anchors { left: parent.left; leftMargin: vpx(20); verticalCenter: parent.verticalCenter }
                    width: vpx(64); height: width; radius: width / 2
                    color: whiteBackground ? "#ececec" : "#3c3c3c"
                    RAIcon { anchors.centerIn: parent; size: vpx(36); source: "../assets/images/fluent/data_bar_vertical.svg" }
                }
                Column {
                    anchors { left: boardIcon.right; leftMargin: vpx(18); right: mineCol.left; rightMargin: vpx(18); verticalCenter: parent.verticalCenter }
                    spacing: vpx(2)
                    Text { width: parent.width; elide: Text.ElideRight; text: lb.title; color: theme.text; font.family: titleFont.name; font.pixelSize: fpx(18) }
                    Text { width: parent.width; elide: Text.ElideRight; text: lb.description; color: theme.text; opacity: 0.85; font.family: bodyFont.name; font.pixelSize: fpx(14) }
                    Text {
                        width: parent.width; elide: Text.ElideRight; topPadding: vpx(4)
                        text: lb.topUser !== "" ? "#1  " + lb.topUser + "  \u00B7  " + lb.topScore : "No entries yet"
                        color: theme.text; opacity: 0.55; font.family: bodyFont.name; font.pixelSize: fpx(13)
                    }
                }
                Column {
                id: mineCol
                    anchors { right: parent.right; rightMargin: vpx(22); verticalCenter: parent.verticalCenter }
                    width: vpx(170)
                    Text { width: parent.width; horizontalAlignment: Text.AlignRight; text: "You"; color: theme.text; opacity: 0.7; font.family: bodyFont.name; font.pixelSize: fpx(13) }
                    Text { width: parent.width; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft; text: lb.myScore !== "" ? lb.myScore : "\u2014"; color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(24) }
                    Text {
                        width: parent.width; horizontalAlignment: Text.AlignRight
                        text: lb.myRank > 0 ? "Rank #" + cheevosData.raFmt(lb.myRank) : "No entry yet"
                        color: tab.mixc(tab.cAccent, Qt.rgba(1, 1, 1, 1), whiteBackground ? 0 : 0.4)
                        font.family: bodyFont.name; font.pixelSize: fpx(13)
                    }
                }
                TapHandler {
                    onTapped: {
                        tab.railFocus = false; tab.forceActiveFocus();
                        if (tab.lbBoardIndex === index) tab.openBoard(); else { tab.lbBoardIndex = index; playNav(); }
                    }
                }
            }
        }
        WheelNav {
            anchors.fill: tab.lbLevel === 0 ? lbGameList : lbBoardList
            view: tab.lbLevel === 0 ? lbGameList : lbBoardList
            columns: 1
            active: tab.visible && lbView.visible && !boardPanel.visible && !searchOpen
            onStepped: function(quiet) {
                if (tab.lbLevel === 0) tab.lbGameIndex = lbGameList.currentIndex; else tab.lbBoardIndex = lbBoardList.currentIndex;
                if (!quiet) playNav();
            }
        }
    }

    // Filters pop-up: this tab's columns (status, mode).
    RAFilterDialog {
    id: filterDlg
        gamePage: false
        columns: tab.filterColumns
        onApplied: tab.filters = picks
        onClosed: { filterDlg.focus = false; tab.forceActiveFocus(); }
    }

    // Search: the on-screen keyboard under the bar; the list narrows as you
    // type. Accept or B puts it away and keeps the search.
    Loader {
    id: kbLoader
        active: tab.searching
        focus: tab.searching
        z: 30
        // Under the toolbar, so the search bar stays in view above it.
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: content.y + vpx(127) }
        onLoaded: item.forceActiveFocus()
        sourceComponent: Component {
            VirtualKeyboard {
                text: tab.query
                showTextField: false
                onTextEdited: tab.query = newText
                onAccepted: tab.closeSearch()
                onCancelled: tab.closeSearch()
            }
        }
    }

    // A leaderboard's top 100.
    RALeaderboardPanel {
    id: boardPanel
        onClosed: { boardPanel.focus = false; tab.forceActiveFocus(); }
    }

    function openGame(i) {
        if (i < 0 || i >= games.length) return;
        playAccept();
        cheevosData.loadGameAchievements(games[i].GameID);
        raOpenProgress();
    }

    // ── Keys ─────────────────────────────────────────────────────────────
    // Arrows are always accepted here, so nothing underneath moves (or
    // beeps) while this tab is up. The pop-ups and the keyboard take their
    // own keys; the sort drop-down is driven from here.
    function lbStep(d) {
        if (lbLevel === 0) { var g = lbGameIndex + d; if (g >= 0 && g < lbGames.length) { lbGameIndex = g; playNav(); } }
        else { var b = lbBoardIndex + d; if (b >= 0 && b < lbBoards.length) { lbBoardIndex = b; playNav(); } }
    }
    Keys.onUpPressed: {
        event.accepted = true;
        if (sortMenuOpen) { if (sortMenuIndex > 0) { sortMenuIndex--; playNav(); } }
        else if (railFocus) { if (railIndex > 0) { railIndex--; playNav(); } }
        else if (railIndex === 1) lbStep(-1);
        else if (zone === 2) {
            if (list.currentIndex > 0) list.currentIndex--;
            else { zone = 1; playNav(); }
        } else if (zone === 1) { zone = 0; playNav(); }
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (sortMenuOpen) { if (sortMenuIndex < sortNames.length - 1) { sortMenuIndex++; playNav(); } }
        else if (railFocus) { if (railIndex < railNames.length - 1) { railIndex++; playNav(); } }
        else if (railIndex === 1) lbStep(1);
        else if (zone === 0) { zone = 1; playNav(); }
        else if (zone === 1) { if (games.length > 0) { zone = 2; playNav(); } }
        else if (list.currentIndex < games.length - 1) list.currentIndex++;
    }
    Keys.onLeftPressed: {
        event.accepted = true;
        if (railFocus || sortMenuOpen) return;
        if (railIndex === 0 && zone === 0 && chipIndex > 0) { chipIndex--; playNav(); }
        else if (railIndex === 0 && zone === 1 && toolIndex > 0) { toolIndex--; playNav(); }
        else { railFocus = true; playNav(); }
    }
    Keys.onRightPressed: {
        event.accepted = true;
        if (sortMenuOpen) return;
        if (railFocus) { railFocus = false; playNav(); }
        else if (railIndex === 0 && zone === 0 && chipIndex < chips.length - 1) { chipIndex++; playNav(); }
        else if (railIndex === 0 && zone === 1 && toolIndex < toolCount - 1) { toolIndex++; playNav(); }
    }
    Keys.onPressed: {
        if (event.isAutoRepeat) return;
        if (api.keys.isCancel(event)) {
            if (sortMenuOpen) { event.accepted = true; sortMenuOpen = false; playBack(); return; }
            if (!railFocus && railIndex === 1 && lbLevel === 1) { event.accepted = true; lbBack(); return; }
            return;
        }
        if (sortMenuOpen && (api.keys.isPrevPage(event) || api.keys.isNextPage(event))) { event.accepted = true; return; }
        if (api.keys.isAccept(event)) {
            event.accepted = true;
            if (sortMenuOpen) pickSort();
            else if (railFocus) { railFocus = false; playNav(); }
            else if (railIndex === 1) { if (lbLevel === 0) openLbGame(); else openBoard(); }
            else if (zone === 0) { playAccept(); applyChip(chipIndex); }
            else if (zone === 1) pressTool();
            else openGame(list.currentIndex);
        }
    }
}
