// XboxOSv2 – GameAchievementsView.qml
// One game's achievements, after the Xbox Series game Progress page.
//
//   Hero: the game's fanart at 50% over near-black; a 100% (Mythic) game
//         sits on your accent band and fades into it. Box art and title top
//         left, the Mythic Achievement card under them (a locked wreath with
//         progress, or the Mythic star once it's 100%), then Points /
//         Achievements / Overall progress and Launch game.
//   Body: rail (Achievements, Stats), Sort and Filter, and every achievement
//         as a card: the badge at full card height, name, description, how
//         many players have it, when you unlocked it, points with a diamond
//         when it's rare (<10%).
//
// Keys: Up/Down move; Up from the first card reaches Sort / Filter (A
// changes the sort, or opens the Filters pop-up, RAFilterDialog.qml), Up
// again Launch game. Shortcuts kept from before: Y sort,
// LB/RB filter, X refresh, B back (one press to Game details when you came
// from there, else back to the RA page).

import QtQuick 2.15
import QtGraphicalEffects 1.15
import "../Global"
import "raEmblems.js" as Emb

FocusScope {
id: root

    anchors.fill: parent

    // The list's own index: one value for keys, wheel and taps alike.
    property alias currentIndex: list.currentIndex
    property var displayList: cheevosData.filteredCheevos
    readonly property var det: cheevosData.currentGameDetails
    onDisplayListChanged: {
        if (currentIndex >= displayList.length) currentIndex = Math.max(0, displayList.length - 1);
        updateHelp();      // "Details" appears once there's something to open
    }

    // ── Colours ──────────────────────────────────────────────────────────
    readonly property color cAccent: theme.accent
    readonly property color cMid:    theme.accentMid
    readonly property color cDark:   theme.accentDark
    function mixc(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1); }
    function light(c, t)   { return mixc(c, Qt.rgba(1, 1, 1, 1), t); }
    readonly property color band: mixc(cDark, cMid, 0.45)
    readonly property color cardColor: whiteBackground ? "#ffffff" : "#2e2e2e"
    readonly property color railSel:   whiteBackground ? "#ffffff" : "#2b2b2b"

    // ── Numbers for the hero ─────────────────────────────────────────────
    readonly property int  unlocked: det.NumAwardedToUser || 0
    readonly property int  total:    det.NumAchievements || 0
    readonly property int  pct:      total > 0 ? Math.floor(unlocked * 100 / total) : 0
    readonly property bool mythic:   det.Award === "mastered" || det.Award === "completed" || (total > 0 && unlocked >= total)
    function fmtDate(ts) { return ts > 0 ? Qt.formatDate(new Date(ts), "MMM d, yyyy") : ""; }

    // Your fanart and box art for this game, when it's in your library.
    readonly property string localArt: localGame ? (localGame.assets.background || localGame.assets.screenshot || "") : ""
    readonly property string boxArt: {
        if (localGame && localGame.assets.boxFront) return localGame.assets.boxFront;
        if (det.ImageBoxArt) return "https://media.retroachievements.org" + det.ImageBoxArt;
        return det.ImageIcon ? "https://media.retroachievements.org" + det.ImageIcon : "";
    }

    // ── Sort / Filter ────────────────────────────────────────────────────
    readonly property var sortKeys:    ["default", "points", "rarity", "date"]
    readonly property var sortNames:   ["Default", "Points", "Rarity", "Date unlocked"]
    // The toolbar as on the Gaming tab: the sort (a drop-down), its
    // direction, then "Filter applied" (only when one is on) and Filter.
    readonly property bool filtered: cheevosData.filterMode !== "all" || cheevosData.typeFilter !== "all" || cheevosData.setFilter !== "all"
    readonly property int sortIndex: Math.max(0, sortKeys.indexOf(cheevosData.sortMode))
    property bool sortMenuOpen: false
    property int sortMenuIndex: 0
    onSortMenuOpenChanged: updateHelp()
    function openSortMenu() { sortMenuIndex = sortIndex; sortMenuOpen = true; playAccept(); updateHelp(); }
    function pickSort() {
        sortMenuOpen = false; playAccept();
        if (sortMenuIndex !== sortIndex) { cheevosData.sortMode = sortKeys[sortMenuIndex]; currentIndex = 0; }
    }
    function pressTool() {
        if (toolIndex === 0) openSortMenu();
        else if (toolIndex === 1) { cheevosData.sortReverse = !cheevosData.sortReverse; currentIndex = 0; playToggle(); }
        else openFilters();
    }
    readonly property bool filtersOpen: filterDlg.visible
    function openFilters() { filterDlg.open(); updateHelp(); }
    function cycleSort(d) {
        var i = sortKeys.indexOf(cheevosData.sortMode); if (i < 0) i = 0;
        cheevosData.sortMode = sortKeys[(i + (d || 1) + sortKeys.length) % sortKeys.length];
        currentIndex = 0;
    }
    // Tabs across the top, as on the console: this page is Progress, with
    // Welcome to its left and Social to its right (LB / RB, or a tap). They
    // go to those tabs of the RA overview.
    readonly property var pageTabs: ["Welcome", "Progress", "Social"]
    function goTab(i) {
        if (i === 1) return;
        raOverviewTab = (i === 0) ? 0 : 1;      // the overview's Welcome / Social
        achievementsScreenFromGame();
    }

    // Focus zones: 0 Launch game, 1 Sort/Filter, 2 the list. railFocus: on
    // the rail, where Up/Down switch between Achievements and Stats.
    property int zone: 2
    onZoneChanged: updateHelp()
    readonly property bool popupOpen: filterDlg.visible || matchPicker.visible || detail.visible || sortMenuOpen
    // The game of yours this page was opened for: from its Game details, or
    // picked in RA Search (both go through the RA lookup with currentGame).
    readonly property var raFromDetailsGame: ((raFromDetails || raSearchReturn) && currentGame) ? currentGame : null
    onRailFocusChanged: updateHelp()
    property int toolIndex: 0
    property bool railFocus: false
    property int railIndex: 0                    // 0 Achievements, 1 Stats
    readonly property var railNames: ["Achievements", "Stats"]
    readonly property bool isList:   railIndex === 0
    readonly property bool onStats:  railIndex === 1
    // Zone 3: the Stats tiles (viewIndex is the focused one; two columns).
    // Leaderboards live on the overview's Gaming tab (RAGamingTab.qml).
    property int viewIndex: 0
    readonly property int viewCount: onStats ? statTiles.length : 0
    readonly property int viewCols: 2
    // Leaving the rail to the right: into the list or the tiles
    // (an empty view keeps you on the rail).
    function enterView() {
        // Back into the list: zone 3 (the Stats tiles) is hidden there, so
        // staying on it left nothing on screen focused.
        if (isList) { railFocus = false; if (zone === 3) zone = 2; return; }
        if (viewCount === 0) return;
        railFocus = false;
        zone = 3;
        viewIndex = 0;
    }
    readonly property bool accentIsLight: (0.299 * cAccent.r + 0.587 * cAccent.g + 0.114 * cAccent.b) > 0.62

    // Your copy of the game in Pegasus: box art, fanart, the Launch button
    // and the Pegasus stats. Looked up once per game, when its details load
    // (currentGame when it's the same title, else the library by title).
    property var localGame: null
    property string localFor: ""
    onDetChanged: resolveLocal()
    Component.onCompleted: { resolveLocal(); updateHelp(); }
    function resolveLocal(force) {
        var t = det.Title || "";
        var id = cheevosData.currentGameID;
        var key = id + "|" + t + "|" + (det.ConsoleName || "");
        if (key === localFor && !force) return;
        localFor = key;
        if (t === "") { localGame = null; return; }
        // currentGame first when it's this RA game: paired with it, or the
        // same title and not paired with something else.
        var cp = currentGame ? cheevosData.pairedId(currentGame) : 0;
        if (currentGame && (cp === id || (cp === 0 && cheevosData.titleKey(currentGame.title) === cheevosData.titleKey(t))))
            localGame = currentGame;
        else
            localGame = cheevosData.findLocalGame(t, det.ConsoleName || "", id);
    }
    // railIndex itself, not onStats: that binding may not have
    // caught up yet when this handler runs (it read the OLD view, so nothing
    // loaded). Focus moves a tick later, once they have.
    onRailIndexChanged: {
        viewIndex = 0;
        if (railIndex === 1) cheevosData.loadGameRank(cheevosData.currentGameID);
        Qt.callLater(function() { if (!root.railFocus) root.enterView(); root.updateHelp(); });
    }
    function playTimeText(sec) {
        if (!sec || sec <= 0) return "0 m";
        var h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60);
        return h > 0 ? h + " h " + m + " m" : m + " m";
    }

    onActiveFocusChanged: {
        if (activeFocus) {
            currentHelpbarModel = null;
            currentIndex = 0;
            zone = 2;
            railFocus = false;
            railIndex = 0;
        }
    }

    // ── Page fill and pointer blocker ────────────────────────────────────
    Rectangle { anchors.fill: parent; color: theme.main }
    // These RA pages sit over whatever was on screen before: absorb pointer
    // input so taps on empty areas don't reach the screen behind.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onPressed: mouse.accepted = true
        onWheel: wheel.accepted = true
        onClicked: mouse.accepted = true
        onReleased: mouse.accepted = true
    }

    // ── Hero ─────────────────────────────────────────────────────────────
    Item {
    id: hero
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(270)
        clip: true

        // Near-black, with the fanart at 50% over it (60% on a Mythic game,
        // where the accent band and fade sit under and over it). A 100% game (Mythic)
        // sits on the accent band instead and fades into it at the bottom.
        Rectangle { anchors.fill: parent; color: root.mythic ? root.band : "#141414" }
        Image {
            anchors.fill: parent
            source: root.localArt !== "" ? root.localArt
                  : (det.ImageIngame ? "https://media.retroachievements.org" + det.ImageIngame : "")
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            sourceSize: Qt.size(hrpx(640), hrpx(360))
            opacity: status === Image.Ready ? (root.mythic ? 0.6 : 0.5) : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        Rectangle {
            anchors.fill: parent
            visible: root.mythic
            gradient: Gradient {
                GradientStop { position: 0.0;  color: Qt.rgba(root.band.r, root.band.g, root.band.b, 0.0) }
                GradientStop { position: 0.55; color: Qt.rgba(root.band.r, root.band.g, root.band.b, 0.25) }
                GradientStop { position: 1.0;  color: root.band }
            }
        }

        // Box art, small at the top left (as the console's game icon), with
        // the title beside it: yours when the game is in your library, else
        // RA's; as wide as its own shape makes it.
        Item {
        id: gameArt
            x: vpx(67); y: vpx(16)
            height: vpx(62)
            width: boxImg.status === Image.Ready && boxImg.implicitHeight > 0
                   ? Math.min(vpx(110), Math.round(height * boxImg.implicitWidth / boxImg.implicitHeight)) : vpx(46)
            Image {
            id: boxImg
                anchors.fill: parent
                source: root.boxArt
                fillMode: Image.PreserveAspectFit
                asynchronous: true; smooth: true; mipmap: true
                sourceSize: Qt.size(hrpx(128), hrpx(128))
            }
            Rectangle {
                visible: boxImg.status !== Image.Ready
                anchors.fill: parent
                radius: vpx(4); color: Qt.rgba(1, 1, 1, 0.08)
            }
        }
        Column {
            anchors { left: gameArt.right; leftMargin: vpx(14); right: pageTabBar.left; rightMargin: vpx(30); verticalCenter: gameArt.verticalCenter }
            Text {
                width: parent.width; elide: Text.ElideRight
                text: det.Title || (cheevosData.statusText || "Loading…")
                color: "white"; font.family: titleFont.name; font.pixelSize: fpx(19)
            }
            Text {
                text: det.ConsoleName || ""
                color: "#d0d0d0"; font.family: bodyFont.name; font.pixelSize: fpx(13)
            }
        }
        RATabBar {
        id: pageTabBar
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: vpx(22) }
            tabs: root.pageTabs
            current: 1
            onTabClicked: root.goTab(index)
        }
        StatusCluster { anchors.fill: parent; z: 50; dark: false }

        // Mythic Achievement card, as on the console: the locked wreath and
        // progress until the game is 100%, then the Mythic star and when.
        Item {
        id: mythicCard
            x: vpx(67); y: vpx(124)
            width: vpx(467); height: vpx(113)
            Rectangle { anchors.fill: parent; anchors.margins: -vpx(8); radius: vpx(12); color: root.light(root.cAccent, 0.35); opacity: root.mythic ? 0.12 : 0.05 }
            Rectangle { anchors.fill: parent; anchors.margins: -vpx(4); radius: vpx(9);  color: root.light(root.cAccent, 0.35); opacity: root.mythic ? 0.25 : 0.1 }
            Rectangle {
                anchors.fill: parent; radius: vpx(6)
                color: Qt.rgba(0, 0, 0, 0.42)
                border.width: vpx(2); border.color: root.mythic ? root.light(root.cAccent, 0.3) : Qt.rgba(1, 1, 1, 0.22)
            }
            Image {
            id: mythicIcon
                x: vpx(10); anchors.verticalCenter: parent.verticalCenter
                width: vpx(88); height: width
                sourceSize: Qt.size(hrpx(88), hrpx(88))
                smooth: true
                source: root.mythic ? Emb.dataUrl(Emb.mythic(theme.accent, "g")) : Emb.dataUrl(Emb.mythicLocked(theme.accent, "q"))
            }
            Column {
                anchors { left: mythicIcon.right; leftMargin: vpx(12); right: parent.right; rightMargin: vpx(20); verticalCenter: parent.verticalCenter }
                spacing: vpx(4)
                Text {
                    text: "Mythic Achievement"
                    color: "white"; font.family: titleFont.name; font.pixelSize: fpx(16)
                }
                Text {
                    visible: root.mythic
                    width: parent.width; elide: Text.ElideRight
                    text: (det.Award === "mastered" ? "Mastered in hardcore" : det.Award === "completed" ? "Completed in softcore" : "Every achievement unlocked")
                          + (det.AwardDate ? "  ·  " + Qt.formatDate(new Date(Date.parse(det.AwardDate)), "MMM d, yyyy") : "")
                    color: "#dddddd"; font.family: bodyFont.name; font.pixelSize: fpx(13)
                }
                // Locked: trophy count on the left, percent on the right, bar.
                Item {
                    visible: !root.mythic
                    width: parent.width; height: vpx(26)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: vpx(6)
                        Image {
                            width: vpx(18); height: width; anchors.verticalCenter: parent.verticalCenter
                            source: "../assets/images/trophy_outline.svg"; sourceSize: Qt.size(hrpx(24), hrpx(24))
                        }
                        Text { text: root.unlocked + "/" + root.total; color: "white"; font.family: bodyFont.name; font.pixelSize: fpx(20) }
                    }
                    Text {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        text: root.pct + "%"; color: "white"; font.family: bodyFont.name; font.pixelSize: fpx(20)
                    }
                }
                Item {
                    visible: !root.mythic
                    width: parent.width; height: vpx(4)
                    Rectangle { anchors.fill: parent; color: Qt.rgba(1, 1, 1, 0.18) }
                    Rectangle { width: parent.width * root.pct / 100; height: parent.height; color: root.light(root.cAccent, 0.2) }
                }
            }
        }

        // Points / Achievements / Overall progress
        Row {
        id: heroStats
            x: mythicCard.x + mythicCard.width + vpx(60); y: mythicCard.y
            spacing: vpx(56)
            Column {
                Text { text: "Points"; color: "white"; font.family: titleFont.name; font.pixelSize: fpx(15) }
                Row {
                    spacing: vpx(6)
                    PointsGlyph { size: vpx(18); fill: "#ececec"; textColor: root.band; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: (det.ScoreAchieved || 0) + "/" + (det.PossibleScore || 0); color: "white"; font.family: bodyFont.name; font.pixelSize: fpx(26) }
                }
            }
            Column {
                Text { text: "Achievements"; color: "white"; font.family: titleFont.name; font.pixelSize: fpx(15) }
                Row {
                    spacing: vpx(6)
                    Image {
                        width: vpx(22); height: width; anchors.verticalCenter: parent.verticalCenter
                        source: "../assets/images/trophy_outline.svg"; sourceSize: Qt.size(hrpx(28), hrpx(28))
                    }
                    Text { text: root.unlocked + "/" + root.total; color: "white"; font.family: bodyFont.name; font.pixelSize: fpx(26) }
                }
            }
            Column {
                Text { text: "Overall progress"; color: "white"; font.family: titleFont.name; font.pixelSize: fpx(15) }
                Text { text: root.pct + "%"; color: "white"; font.family: bodyFont.name; font.pixelSize: fpx(26) }
            }
        }
    }

    // ── Rail ─────────────────────────────────────────────────────────────
    Item {
    id: rail
        anchors { left: parent.left; top: hero.bottom; bottom: parent.bottom }
        width: vpx(322)
        Column {
            y: vpx(33); width: parent.width
            Repeater {
                model: root.railNames
                // As in Settings: an accent plate while the rail has focus, a
                // grey plate with an accent edge otherwise.
                delegate: Rectangle {
                    readonly property bool on: index === root.railIndex
                    readonly property bool hot: on && root.railFocus && root.activeFocus
                    readonly property color ink: hot ? (root.accentIsLight ? "#111111" : "white") : theme.text
                    width: rail.width; height: vpx(42)
                    color: hot ? theme.accent : (on ? root.railSel : "transparent")
                    Rectangle {
                        visible: parent.on && !parent.hot
                        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                        width: vpx(5); color: theme.accent
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: vpx(97); verticalCenter: parent.verticalCenter }
                        text: modelData
                        color: parent.ink; opacity: parent.on ? 1 : 0.8
                        font.family: bodyFont.name; font.pixelSize: fpx(17)
                    }
                    TapHandler { onTapped: { root.railIndex = index; playNav(); } }
                }
            }
        }
    }
    Rectangle {
        anchors { left: rail.right; top: hero.bottom; bottom: parent.bottom }
        width: vpx(1); color: theme.text; opacity: 0.12
    }

    // ── Sort and Filter ──────────────────────────────────────────────────
    Item {
    id: toolRow
        visible: root.isList
        z: root.sortMenuOpen ? 6 : 0      // the drop-down hangs over the list
        anchors { left: rail.right; leftMargin: vpx(31); right: parent.right; rightMargin: vpx(67); top: hero.bottom; topMargin: vpx(23) }
        height: vpx(39)
        Rectangle {
        id: sortBox
            readonly property bool hot: root.zone === 1 && root.toolIndex === 0 && !root.railFocus && root.activeFocus && !root.sortMenuOpen
            width: vpx(280); height: parent.height
            color: root.cardColor; radius: vpx(4)
            RAFocus { on: sortBox.hot }
            Text {
                anchors { left: parent.left; leftMargin: vpx(13); verticalCenter: parent.verticalCenter }
                text: root.sortNames[root.sortIndex]
                color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(16)
            }
            RAIcon { anchors { right: parent.right; rightMargin: vpx(13); verticalCenter: parent.verticalCenter } source: "../assets/images/fluent/chevron_down.svg" }
            TapHandler { onTapped: { root.zone = 1; root.toolIndex = 0; root.railFocus = false; root.forceActiveFocus(); root.openSortMenu(); } }
        }
        Rectangle {
        id: dirBtn
            readonly property bool hot: root.zone === 1 && root.toolIndex === 1 && !root.railFocus && root.activeFocus
            anchors { left: sortBox.right; leftMargin: vpx(10) }
            width: parent.height; height: parent.height
            color: root.cardColor; radius: vpx(4)
            RAFocus { on: dirBtn.hot }
            RAIcon {
                anchors.centerIn: parent
                size: vpx(20)
                source: "../assets/images/fluent/" + (cheevosData.sortReverse ? "arrow_sort_up" : "arrow_sort_down") + ".svg"
            }
            TapHandler { onTapped: { root.zone = 1; root.toolIndex = 1; root.railFocus = false; root.forceActiveFocus(); root.pressTool(); } }
        }
        Text {
            anchors { left: dirBtn.right; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
            text: root.displayList.length + (root.displayList.length === 1 ? " achievement" : " achievements")
            color: theme.text; opacity: 0.6
            font.family: bodyFont.name; font.pixelSize: fpx(15)
        }
        Rectangle {
        id: filterBox
            readonly property bool hot: root.zone === 1 && root.toolIndex === 2 && !root.railFocus && root.activeFocus
            anchors.right: parent.right
            width: filterRow.implicitWidth + vpx(30); height: parent.height
            color: root.cardColor; radius: vpx(4)
            RAFocus { on: filterBox.hot }
            Row {
            id: filterRow
                anchors.centerIn: parent
                spacing: vpx(8)
                RAIcon { source: "../assets/images/fluent/filter.svg"; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: "Filter"
                    color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(16)
                }
            }
            TapHandler { onTapped: { root.zone = 1; root.toolIndex = 2; root.railFocus = false; root.forceActiveFocus(); root.openFilters(); } }
        }
        Text {
            visible: root.filtered
            anchors { right: filterBox.left; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
            text: "Filter applied"
            color: theme.text; opacity: 0.6
            font.family: bodyFont.name; font.pixelSize: fpx(16)
        }
        RASortMenu {
            visible: root.sortMenuOpen
            x: sortBox.x; y: sortBox.height + vpx(4)
            width: sortBox.width
            names: root.sortNames
            current: root.sortIndex
            index: root.sortMenuIndex
            hasFocus: root.activeFocus
            onPicked: { root.sortMenuIndex = i; root.pickSort(); }
        }
    }

    // ── Achievements ─────────────────────────────────────────────────────
    ListView {
    id: list
        visible: root.isList
        // Padding = the focus frame's reach, so the clip never cuts it; the
        // focused card stays in the top slot; the list ends above the prompts.
        anchors { left: rail.right; leftMargin: vpx(17); right: parent.right; rightMargin: vpx(53); top: toolRow.bottom; topMargin: vpx(0); bottom: parent.bottom; bottomMargin: helpMargin }
        leftMargin: vpx(14); rightMargin: vpx(14); topMargin: vpx(14); bottomMargin: vpx(14)
        clip: true
        model: root.displayList
        spacing: vpx(14)
        keyNavigationEnabled: false
        cacheBuffer: vpx(300)
        highlightMoveDuration: 120
        preferredHighlightBegin: vpx(14)
        preferredHighlightEnd: vpx(14) + vpx(125)
        highlightRangeMode: ListView.StrictlyEnforceRange

        Text {
            anchors { top: parent.top; topMargin: vpx(30); horizontalCenter: parent.horizontalCenter }
            visible: root.displayList.length === 0
            text: cheevosData.setFilter === "unofficial" && cheevosData.unofficialState === 1 ? "Loading unofficial achievements\u2026"
                : cheevosData.setFilter === "unofficial" && cheevosData.unofficialCount === 0 ? "No unofficial achievements for this game"
                : cheevosData.setFilter === "subsets" && cheevosData.subsetNames.length === 0 ? "No subsets for this game"
                : cheevosData.statusText !== "" ? cheevosData.statusText
                : "Nothing matches these filters"
            color: theme.text; opacity: 0.55
            font.family: bodyFont.name; font.pixelSize: fpx(18)
        }

        delegate: Item {
        id: card
            readonly property var ach: modelData
            readonly property bool earned: ach.DateEarned > 0
            readonly property bool rare: ach.Rarity > 0 && ach.Rarity < 10
            readonly property bool selected: index === root.currentIndex && root.zone === 2 && !root.railFocus && root.activeFocus
            readonly property string badge: ach.BadgeName !== ""
                ? "https://media.retroachievements.org/Badge/" + ach.BadgeName + (earned ? "" : "_lock") + ".png" : ""
            width: list.width - vpx(28); height: vpx(125)

            Rectangle { anchors.fill: parent; radius: vpx(4); color: root.cardColor }
            RAFocus { on: card.selected }

            // The badge, clear and as big as the card: RA badges are square,
            // so it fills the card's height (a wide picture would need art RA
            // doesn't have). Locked ones are RA's grey version, with a lock.
            Item {
            id: wideArt
                width: parent.height; height: parent.height
                Image {
                    anchors.fill: parent
                    source: card.badge
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true; smooth: true
                    sourceSize: Qt.size(hrpx(64), hrpx(64))
                }
                Image {
                    visible: !card.earned
                    anchors { right: parent.right; bottom: parent.bottom; margins: vpx(8) }
                    width: vpx(18); height: width
                    source: "../assets/images/fluent/lock.svg"; sourceSize: Qt.size(hrpx(24), hrpx(24))
                }
            }

            Column {
                anchors { left: wideArt.right; leftMargin: vpx(17); right: parent.right; rightMargin: vpx(90); top: parent.top; topMargin: vpx(11) }
                spacing: vpx(2)
                opacity: card.earned ? 1 : 0.8
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: ach.Title
                    color: theme.text; font.family: titleFont.name; font.pixelSize: fpx(17)
                }
                Text {
                    width: parent.width; elide: Text.ElideRight; maximumLineCount: 1
                    text: ach.Description
                    color: theme.text; opacity: 0.85; font.family: bodyFont.name; font.pixelSize: fpx(14)
                }
                Text {
                    topPadding: vpx(4)
                    text: ach.Rarity > 0 ? ach.Rarity + "% of players unlocked this" + (card.rare ? "  ·  rare" : "") : ""
                    color: theme.text; opacity: 0.55; font.family: bodyFont.name; font.pixelSize: fpx(13)
                }
                Text {
                    text: (card.earned ? "Unlocked " + root.fmtDate(ach.DateEarned) + (ach.Hardcore ? "  ·  hardcore" : "  ·  softcore")
                                       : ("Locked" + (ach.Type === "missable" ? "  ·  missable" : "")))
                          + (ach.Set === "Unofficial" ? "  ·  unofficial" : ach.Set ? "  ·  " + ach.Set + " subset" : "")
                    color: theme.text; opacity: 0.85; font.family: bodyFont.name; font.pixelSize: fpx(13)
                }
            }
            Row {
                anchors { right: parent.right; rightMargin: vpx(17); top: parent.top; topMargin: vpx(13) }
                spacing: vpx(6)
                RAIcon { visible: card.rare; size: vpx(16); source: "../assets/images/fluent/diamond.svg"; anchors.verticalCenter: parent.verticalCenter }
                PointsGlyph { size: vpx(15); fill: whiteBackground ? "#303030" : "#e6e6e6"; textColor: root.cardColor; anchors.verticalCenter: parent.verticalCenter }
                Text { text: ach.Points; color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(16) }
            }
            Rectangle {
                anchors { left: wideArt.right; leftMargin: vpx(17); right: parent.right; rightMargin: vpx(17); bottom: parent.bottom; bottomMargin: vpx(10) }
                height: vpx(3)
                color: card.earned ? root.light(root.cAccent, whiteBackground ? 0 : 0.15) : (whiteBackground ? "#d8d8d8" : "#3e3e3e")
            }
            TapHandler {
                onTapped: {
                    if (card.selected) { root.openDetail(); return; }
                    root.zone = 2; root.railFocus = false; root.currentIndex = index; root.forceActiveFocus();
                }
            }
        }
    }
    WheelNav {
        anchors.fill: list
        view: list
        columns: 1
        active: !searchOpen
        onStepped: function(quiet) { if (!quiet) playNav(); }
    }

    // ── Stats ────────────────────────────────────────────────────────────
    // Tiles with what RA and Pegasus know about you and this game. Pegasus
    // tiles need the game in your library; RA's rank is fetched on opening.
    readonly property var statTiles: {
        var lg = localGame, d = det, out = [];
        var dateOf = function(s) { var ms = Date.parse(s); return isNaN(ms) ? "" : Qt.formatDate(new Date(ms), "MMM d, yyyy"); };
        out.push(["Time played",    lg ? playTimeText(lg.playTime) : "\u2014", lg ? "from Pegasus" : "not in your library"]);
        out.push(["Times launched", lg ? String(lg.playCount || 0) : "\u2014", lg ? "from Pegasus" : ""]);
        out.push(["Last played",    (lg && lg.lastPlayed && !isNaN(lg.lastPlayed.getTime()) && lg.lastPlayed.getTime() > 0) ? Qt.formatDate(lg.lastPlayed, "MMM d, yyyy") : "\u2014", lg ? "from Pegasus" : ""]);
        out.push(["Points", (d.ScoreAchieved || 0) + " / " + (d.PossibleScore || 0), "hardcore " + (d.PointsHardcore || 0) + "  \u00B7  softcore " + (d.PointsSoftcore || 0)]);
        out.push(["RetroPoints", cheevosData.raFmt(d.TrueRatioEarned || 0), "weighted by rarity"]);
        out.push(["Unlocked in hardcore", (d.NumAwardedToUserHardcore || 0) + " / " + (d.NumAchievements || 0), ""]);
        out.push(["Rarest unlock", d.RarestPct > 0 ? d.RarestPct + "%" : "\u2014", d.RarestTitle || ""]);
        out.push(["First unlock", d.FirstUnlock > 0 ? fmtDate(d.FirstUnlock) : "\u2014", ""]);
        out.push(["Latest unlock", d.LatestUnlock > 0 ? fmtDate(d.LatestUnlock) : "\u2014", ""]);
        var aw = d.Award === "mastered" ? "Mastered" : d.Award === "completed" ? "Completed" : d.Award === "beaten-hardcore" ? "Beaten"
               : d.Award === "beaten-softcore" ? "Beaten \u00B7 softcore" : "None yet";
        out.push(["Award", aw, d.AwardDate ? dateOf(d.AwardDate) : ""]);
        out.push(["Players", cheevosData.raFmt(d.Players || 0), cheevosData.raFmt(d.PlayersHardcore || 0) + " in hardcore"]);
        out.push(["Your rank", cheevosData.gameRank > 0 ? "#" + cheevosData.raFmt(cheevosData.gameRank) : (cheevosData.gameRank < 0 ? "\u2026" : "\u2014"), "of this game's players"]);
        return out;
    }
    // Two columns of big tiles, as on the console's Stats view. Right from
    // the rail reaches them; they scroll with the cursor.
    GridView {
    id: statsView
        visible: root.onStats
        anchors { left: rail.right; leftMargin: vpx(17); right: parent.right; rightMargin: vpx(53); top: hero.bottom; topMargin: vpx(9); bottom: parent.bottom; bottomMargin: helpMargin }
        leftMargin: vpx(14); rightMargin: vpx(14); topMargin: vpx(14); bottomMargin: vpx(14)
        clip: true
        interactive: true
        keyNavigationEnabled: false
        model: root.onStats ? root.statTiles : []
        cellWidth: Math.floor((width - leftMargin - rightMargin) / 2)
        cellHeight: vpx(146)
        currentIndex: root.onStats ? root.viewIndex : -1
        highlightMoveDuration: 120
        preferredHighlightBegin: vpx(14)
        preferredHighlightEnd: height - vpx(14)
        highlightRangeMode: GridView.ApplyRange
        delegate: Item {
            width: statsView.cellWidth; height: statsView.cellHeight
            Rectangle {
                anchors { fill: parent; rightMargin: vpx(14); bottomMargin: vpx(14) }
                radius: vpx(4); color: root.cardColor
                RAFocus { on: index === root.viewIndex && root.zone === 3 && !root.railFocus && root.activeFocus && !root.popupOpen }
                Column {
                    anchors { left: parent.left; leftMargin: vpx(24); right: parent.right; rightMargin: vpx(18); verticalCenter: parent.verticalCenter }
                    spacing: vpx(4)
                    Text { width: parent.width; elide: Text.ElideRight; text: modelData[0]; color: theme.text; font.family: titleFont.name; font.pixelSize: fpx(18) }
                    Text { width: parent.width; elide: Text.ElideRight; text: modelData[1]; color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(38) }
                    // Always there (blank when empty) so every tile's lines sit at the same height.
                    Text { width: parent.width; elide: Text.ElideRight; text: modelData[2] || " "; color: theme.text; opacity: 0.75; font.family: bodyFont.name; font.pixelSize: fpx(16) }
                }
            }
            TapHandler { onTapped: { root.railFocus = false; root.zone = 3; root.viewIndex = index; root.forceActiveFocus(); } }
        }
    }

    // ── Local help bar ───────────────────────────────────────────────────
    Row {
        z: 110       // above the Filters pop-up's dim, so its prompts show
        anchors { right: parent.right; rightMargin: globalMargin; bottom: parent.bottom; bottomMargin: vpx(10) }
        spacing: vpx(16)
        Repeater {
            model: localHelpModel
            delegate: Row {
                TapHandler { gesturePolicy: TapHandler.WithinBounds; onTapped: helpClick(button) }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                spacing: vpx(6)
                Image {
                    source: "../assets/images/controller/" + buttonbar.processButtonArt(button) + ".png"
                    width: vpx(32); height: vpx(32)
                    asynchronous: true
                    sourceSize { width: hrpx(48); height: hrpx(48) }
                }
                Text {
                    text: name
                    font.family: subtitleFont.name; font.pixelSize: fpx(19)
                    color: theme.text
                    height: vpx(32); verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
    // A shows only where it does something: Launch on the button, Change on
    // Sort, Filters on Filter, Select on the rail. In the Filters pop-up:
    // Select / Apply and Close.
    ListModel { id: localHelpModel }
    function updateHelp() {
        localHelpModel.clear();
        if (matchPicker.visible) {
            localHelpModel.append({ name: matchPicker.onSearch ? "Search" : "Select", button: "accept" });
            localHelpModel.append({ name: "Search", button: "filters" });
            localHelpModel.append({ name: "Close",  button: "cancel" });
            return;
        }
        if (detail.visible) {
            localHelpModel.append({ name: detail.inList ? "Buttons" : "Select", button: "accept" });
            localHelpModel.append({ name: "Previous", button: "prevPage" });
            localHelpModel.append({ name: "Next",     button: "nextPage" });
            localHelpModel.append({ name: "Close",    button: "cancel" });
            return;
        }
        if (sortMenuOpen) {
            localHelpModel.append({ name: "Select", button: "accept" });
            localHelpModel.append({ name: "Close",  button: "cancel" });
            return;
        }
        if (filtersOpen) {
            localHelpModel.append({ name: filterDlg.col === filterDlg.applyCol ? "Apply" : "Select", button: "accept" });
            localHelpModel.append({ name: "Close", button: "cancel" });
            return;
        }
        var a = railFocus ? "Select"
              : zone === 1 ? (toolIndex === 1 ? "Reverse" : toolIndex === 2 ? "Filters" : "Select")
              : (zone === 2 && displayList.length > 0) ? "Details" : "";
        if (a !== "") localHelpModel.append({ name: a, button: "accept" });
        localHelpModel.append({ name: "Refresh", button: "details" });
        localHelpModel.append({ name: "Sort",    button: "filters" });
        localHelpModel.append({ name: "Back",    button: "cancel" });
    }
    onToolIndexChanged: updateHelp()
    onViewIndexChanged: updateHelp()
    onLocalGameChanged: updateHelp()

    // ── Keys ─────────────────────────────────────────────────────────────
    Keys.onUpPressed: {
        event.accepted = true;
        if (sortMenuOpen) { if (sortMenuIndex > 0) { sortMenuIndex--; playNav(); } return; }
        if (railFocus) { if (railIndex > 0) { railIndex--; playNav(); } return; }
        if (!isList) {
            if (zone === 3) {
                if (viewIndex - viewCols >= 0) { viewIndex -= viewCols; playNav(); }
            }
            return;
        }
        if (zone === 2) {
            if (currentIndex > 0) { currentIndex--; playNav(); }
            else { zone = 1; playNav(); }
        }
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (sortMenuOpen) { if (sortMenuIndex < sortNames.length - 1) { sortMenuIndex++; playNav(); } return; }
        if (railFocus) { if (railIndex < railNames.length - 1) { railIndex++; playNav(); } return; }
        if (!isList) {
            if (zone === 3) {
                if (viewIndex + viewCols < viewCount) { viewIndex += viewCols; playNav(); }
                else if (Math.floor(viewIndex / viewCols) < Math.floor((viewCount - 1) / viewCols)) { viewIndex = viewCount - 1; playNav(); }
            }
            return;
        }
        if (zone === 1) { if (displayList.length > 0) { zone = 2; playNav(); } }
        else if (currentIndex < displayList.length - 1) { currentIndex++; playNav(); }
    }
    // Left reaches the rail (from the list, the button, the first of
    // Sort/Filter, or the left column of tiles); Right leaves it again: into
    // the list, the cards or the tiles (or the Launch button when empty).
    Keys.onLeftPressed: {
        event.accepted = true;
        if (railFocus || sortMenuOpen) return;
        if (zone === 3 && viewCols > 1 && viewIndex % viewCols > 0) { viewIndex--; playNav(); }
        else if (zone === 1 && toolIndex > 0) { toolIndex--; playNav(); }
        else { railFocus = true; playNav(); }
    }
    Keys.onRightPressed: {
        event.accepted = true;
        if (sortMenuOpen) return;
        if (railFocus) { if (isList || viewCount > 0) { enterView(); playNav(); } return; }
        if (zone === 3) { if (viewCols > 1 && viewIndex % viewCols < viewCols - 1 && viewIndex < viewCount - 1) { viewIndex++; playNav(); } }
        else if (zone === 1 && toolIndex < 2) { toolIndex++; playNav(); }
    }

    // B / mouse back. Opened from Game details (the RA button): straight back
    // to the details page. Opened from the RA overview: back to the overview,
    // and a second B leaves RA.
    function goBack() {
        if (raFromDetails) previousScreen();
        else achievementsScreenFromGame();
    }
    function mouseBack() { goBack(); }

    function refresh() {
        playAccept();
        if (cheevosData.currentGameDetails.Title !== "")
            cheevosData.loadGameAchievements(cheevosData.currentGameID);
    }

    Keys.onPressed: {
        // The sort drop-down: A picks, B closes, nothing else.
        if (sortMenuOpen) {
            event.accepted = true;
            if (event.isAutoRepeat) return;
            if (api.keys.isAccept(event)) pickSort();
            else if (api.keys.isCancel(event)) { sortMenuOpen = false; playBack(); }
            return;
        }
        if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; goBack(); }
        if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; goTab(0); }
        if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; goTab(2); }
        if (api.keys.isFilters(event) && !event.isAutoRepeat)  { event.accepted = true; playToggle(); cycleSort(1); }
        if (api.keys.isDetails(event) && !event.isAutoRepeat)  { event.accepted = true; refresh(); }
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (railFocus) { if (isList || viewCount > 0) { enterView(); playNav(); } }
            else if (zone === 1) pressTool();
            else if (zone === 2) openDetail();
        }
    }

    // Launch game: your copy in Pegasus (resolveLocal), when there is one.
    function launchOwnGame() {
        if (!localGame) return;
        playAccept();
        launchGameFromRA(localGame);
    }
    function launchOrFind() { if (localGame) launchOwnGame(); else openLibraryPicker(); }
    // Change match: opened from your game's details, pick the right RA game
    // for it; otherwise pick which of your games this RA game is.
    function changeMatch() { if (raFromDetailsGame) openRaPicker(raFromDetailsGame); else openLibraryPicker(); }

    // ── Match picker ─────────────────────────────────────────────────────
    property string pickerMode: ""               // "library" | "ra"
    property var pickerGame: null                // "ra": the game of yours being matched
    function openLibraryPicker() {
        var t = det.Title || "";
        pickerMode = "library"; pickerGame = null;
        matchPicker.open("Find in your library", "Which of your games is " + t + " (" + (det.ConsoleName || "") + ")?", t);
        updateHelp();
        // Your games on this RA console (all of them if none map to it).
        var cid = det.ConsoleID || 0, mine = [], all = [];
        for (var i = 0; i < api.allGames.count; i++) {
            var g = api.allGames.get(i), sys = "", onConsole = false;
            for (var c = 0; c < g.collections.count; c++) {
                var col = g.collections.get(c);
                if (c === 0) sys = col.name || col.shortName || "";
                if (cid > 0 && cheevosData.consoleMappings[(col.shortName || "").toLowerCase()] === cid) { onConsole = true; sys = col.name || col.shortName; }
            }
            var it = cheevosData.pickItem(g.title || "", sys, i);
            all.push(it);
            if (onConsole) mine.push(it);
        }
        matchPicker.setItems(mine.length > 0 ? mine : all);
    }
    function openRaPicker(g) {
        pickerMode = "ra"; pickerGame = g;
        var sn = (g.collections.count > 0) ? (g.collections.get(0).shortName || "").toLowerCase() : "";
        var cid = cheevosData.consoleMappings[sn] || det.ConsoleID || 0;
        matchPicker.open("Match to RetroAchievements", "Which RetroAchievements game is " + g.title + "?", g.title);
        updateHelp();
        if (!cid) { matchPicker.setItems([]); return; }
        cheevosData.withList(cid, function(list) {
            if (!matchPicker.visible || pickerMode !== "ra") return;
            var out = [];
            for (var i = 0; i < list.length; i++)
                out.push(cheevosData.pickItem(list[i].Title, list[i].NumAchievements + " achievements", list[i].ID));
            matchPicker.setItems(out);
        });
    }
    function applyPick(value) {
        if (pickerMode === "library") {
            var g = api.allGames.get(value);
            cheevosData.setPair(g, cheevosData.currentGameID);
            resolveLocal(true);
        } else if (pickerMode === "ra" && pickerGame) {
            cheevosData.setPair(pickerGame, value);
            if (value !== cheevosData.currentGameID) {
                cheevosData.loadGameAchievements(value);
                currentIndex = 0;
            }
            resolveLocal(true);
        }
    }
    // Clickable prompts: each does what its button does.
    function helpAction(button) {
        if (sortMenuOpen) {
            if (button === "accept") pickSort();
            else if (button === "cancel") { sortMenuOpen = false; playBack(); }
            return true;
        }
        if (detail.visible) {
            if (button === "accept") detail.press();
            else if (button === "prevPage") detail.step(-1);
            else if (button === "nextPage") detail.step(1);
            else if (button === "cancel") detail.close();
            return true;
        }
        if (matchPicker.visible) {
            if (button === "accept") matchPicker.pick();
            else if (button === "filters") { matchPicker.onSearch = true; matchPicker.openKeyboard(); }
            else if (button === "cancel") matchPicker.close();
            return true;
        }
        if (filtersOpen) {
            if (button === "accept") filterDlg.accept();
            else if (button === "cancel") filterDlg.close(false);
            return true;
        }
        if (button === "cancel") goBack();
        else if (button === "filters") { playToggle(); cycleSort(1); }
        else if (button === "details") refresh();
        else if (button === "accept") {
            if (railFocus) enterView();
            else if (zone === 1) pressTool();
            else if (zone === 2) openDetail();
        }
        else return false;
        return true;
    }

    // A on an achievement: the pop-up with Launch game and Change match.
    RAAchievementDetail {
    id: detail
        host: root
        onClosed: { detail.focus = false; root.forceActiveFocus(); root.updateHelp(); }
        onInListChanged: root.updateHelp()
    }
    function openDetail() {
        if (displayList.length === 0) return;
        detail.open();
        updateHelp();
    }

    RAMatchPicker {
    id: matchPicker
        onChosen: root.applyPick(value)
        // Hand focus back: a hidden pop-up stays the page's focused child
        // (and keeps the keys) unless it lets go.
        onClosed: { matchPicker.focus = false; root.forceActiveFocus(); root.updateHelp(); }
        onOnSearchChanged: root.updateHelp()
    }

    RAFilterDialog {
    id: filterDlg
        onClosed: { filterDlg.focus = false; root.forceActiveFocus(); root.updateHelp(); }
        onColChanged: root.updateHelp()
    }

    // The last card dissolves under the help bar (same fade as the grids).
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: helpMargin + vpx(40)
        z: 1
        opacity: gridFadeOpacity
        visible: opacity > 0
        gradient: Gradient {
            GradientStop { position: 0.0;  color: mainA(0.0)  }
            GradientStop { position: 0.5;  color: mainA(0.6) }
            GradientStop { position: 1.0;  color: theme.main }
        }
    }
}
