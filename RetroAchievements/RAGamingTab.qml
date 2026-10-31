// XboxOSv2 – RAGamingTab.qml
// The Gaming tab of the RetroAchievements page, after the Xbox Series
// achievements page: a left rail, quick buttons, Sort and Filter, and every
// game you've played as a card with its progress. Mastered games (RA's 100%
// in hardcore) wear the Mythic-style frame (RAMythicFrame.qml).
//
// Data: cheevosData.raLibrary (CheevosData.loadLibrary). The list is a JS
// array rebuilt only when the library, Sort or Filter changes, never per row.
//
// Focus, top to bottom: quick buttons -> Sort/Filter -> the game list.
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
    readonly property var sortNames:   ["Recent", "Completion", "Title", "Unlocked"]
    readonly property var filterNames: ["All", "In progress", "Mythic", "Beaten"]
    property int sortIndex:   0
    property int filterIndex: 0
    property var games: []

    readonly property var chips: ["Closest to mastery", "Recently unlocked", "Mythic"]
    // Mythic, as on the Xbox, is 100% of a game's achievements: RA's
    // Mastered (hardcore) or Completed (softcore). The card label still
    // says which.
    function isMythic(g) { return g.Award === "mastered" || g.Award === "completed"; }
    function applyChip(i) {
        if (i === 0)      { sortIndex = 1; filterIndex = 1; }   // highest % that isn't done yet
        else if (i === 1) { sortIndex = 0; filterIndex = 0; }
        else              { sortIndex = 0; filterIndex = 2; }
        zone = 2;
    }

    function keep(g) {
        switch (filterNames[filterIndex]) {
        case "In progress": return !isMythic(g) && g.Progress < 1;
        case "Mythic":      return isMythic(g);
        case "Beaten":      return g.Award === "beaten-hardcore" || g.Award === "beaten-softcore";
        default:            return true;
        }
    }
    function rebuild() {
        var m = cheevosData.raLibrary, out = [];
        for (var i = 0; i < m.count; i++) { var g = m.get(i); if (keep(g)) out.push(g); }
        var s = sortNames[sortIndex];
        if (s === "Completion")    out.sort(function(a, b) { return b.Progress - a.Progress || b.NumAwarded - a.NumAwarded; });
        else if (s === "Title")    out.sort(function(a, b) { return String(a.Title).localeCompare(String(b.Title)); });
        else if (s === "Unlocked") out.sort(function(a, b) { return b.NumAwarded - a.NumAwarded; });
        else                       out.sort(function(a, b) { return String(b.LastUnlock).localeCompare(String(a.LastUnlock)); });
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
        : (railIndex === 1 && !railFocus) ? (lbLevel === 1 ? "boards" : "games") : ""
    function helpAction(b) {
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
    onSortIndexChanged:   rebuild()
    onFilterIndexChanged: rebuild()
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
    property int toolIndex: 0     // 0 Sort, 1 Filter
    readonly property var railNames: ["Achievements", "Leaderboards"]
    property int railIndex: 0
    property bool railFocus: false
    readonly property bool accentIsLight: (0.299 * cAccent.r + 0.587 * cAccent.g + 0.114 * cAccent.b) > 0.62
    onActiveFocusChanged: if (activeFocus && !boardPanel.visible) list.forceActiveFocus()

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
            Rectangle {
            id: sortBox
                readonly property bool hot: tab.zone === 1 && tab.toolIndex === 0 && tab.activeFocus && !tab.railFocus
                width: vpx(390); height: parent.height
                color: tab.cardColor
                radius: vpx(4)
                RAFocus { on: sortBox.hot }
                Text {
                    anchors { left: parent.left; leftMargin: vpx(14); verticalCenter: parent.verticalCenter }
                    text: "Sort: " + tab.sortNames[tab.sortIndex]
                    color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(16)
                }
                RAIcon {
                    anchors { right: parent.right; rightMargin: vpx(14); verticalCenter: parent.verticalCenter }
                    source: "../assets/images/fluent/chevron_down.svg"
                }
                TapHandler { onTapped: { tab.sortIndex = (tab.sortIndex + 1) % tab.sortNames.length; playToggle(); } }
            }
            Rectangle {
                readonly property bool hot: tab.zone === 1 && tab.toolIndex === 1 && tab.activeFocus && !tab.railFocus
                anchors.right: parent.right
            id: filterBox
                width: filterRow.implicitWidth + vpx(32); height: parent.height
                color: tab.cardColor
                radius: vpx(4)
                RAFocus { on: filterBox.hot }
                Row {
                id: filterRow
                    anchors.centerIn: parent
                    spacing: vpx(8)
                    RAIcon { source: "../assets/images/fluent/filter.svg"; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: "Filter: " + tab.filterNames[tab.filterIndex]
                        color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(16)
                    }
                }
                TapHandler { onTapped: { tab.filterIndex = (tab.filterIndex + 1) % tab.filterNames.length; playToggle(); } }
            }
            Text {
                anchors { left: sortBox.right; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                text: tab.games.length + (tab.games.length === 1 ? " game" : " games")
                color: theme.text; opacity: 0.6
                font.family: bodyFont.name; font.pixelSize: fpx(15)
            }
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
                readonly property bool selected: ListView.isCurrentItem && tab.zone === 2 && tab.activeFocus && !tab.railFocus
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

    // A leaderboard's top 100.
    RALeaderboardPanel {
    id: boardPanel
        onClosed: { boardPanel.focus = false; tab.forceActiveFocus(); }
    }

    function openGame(i) {
        if (i < 0 || i >= games.length) return;
        playAccept();
        cheevosData.loadGameAchievements(games[i].GameID);
        gameAchievementsScreenFromOverview();
    }

    // ── Keys ─────────────────────────────────────────────────────────────
    // Arrows are always accepted here, so nothing underneath moves (or
    // beeps) while this tab is up. The top-100 pop-up takes its own keys.
    function lbStep(d) {
        if (lbLevel === 0) { var g = lbGameIndex + d; if (g >= 0 && g < lbGames.length) { lbGameIndex = g; playNav(); } }
        else { var b = lbBoardIndex + d; if (b >= 0 && b < lbBoards.length) { lbBoardIndex = b; playNav(); } }
    }
    Keys.onUpPressed: {
        event.accepted = true;
        if (railFocus) { if (railIndex > 0) { railIndex--; playNav(); } }
        else if (railIndex === 1) lbStep(-1);
        else if (zone === 2) {
            if (list.currentIndex > 0) list.currentIndex--;
            else { zone = 1; playNav(); }
        } else if (zone === 1) { zone = 0; playNav(); }
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (railFocus) { if (railIndex < railNames.length - 1) { railIndex++; playNav(); } }
        else if (railIndex === 1) lbStep(1);
        else if (zone === 0) { zone = 1; playNav(); }
        else if (zone === 1) { if (games.length > 0) { zone = 2; playNav(); } }
        else if (list.currentIndex < games.length - 1) list.currentIndex++;
    }
    Keys.onLeftPressed: {
        event.accepted = true;
        if (railFocus) return;
        if (railIndex === 0 && zone === 0 && chipIndex > 0) { chipIndex--; playNav(); }
        else if (railIndex === 0 && zone === 1 && toolIndex > 0) { toolIndex--; playNav(); }
        else { railFocus = true; playNav(); }
    }
    Keys.onRightPressed: {
        event.accepted = true;
        if (railFocus) { railFocus = false; playNav(); }
        else if (railIndex === 0 && zone === 0 && chipIndex < chips.length - 1) { chipIndex++; playNav(); }
        else if (railIndex === 0 && zone === 1 && toolIndex < 1) { toolIndex++; playNav(); }
    }
    Keys.onPressed: {
        if (event.isAutoRepeat) return;
        if (api.keys.isCancel(event) && !railFocus && railIndex === 1 && lbLevel === 1) {
            event.accepted = true; lbBack(); return;
        }
        if (api.keys.isAccept(event)) {
            event.accepted = true;
            if (railFocus) { railFocus = false; playNav(); }
            else if (railIndex === 1) { if (lbLevel === 0) openLbGame(); else openBoard(); }
            else if (zone === 0) { playAccept(); applyChip(chipIndex); }
            else if (zone === 1) {
                playToggle();
                if (toolIndex === 0) sortIndex = (sortIndex + 1) % sortNames.length;
                else filterIndex = (filterIndex + 1) % filterNames.length;
            } else openGame(list.currentIndex);
        }
    }
}
