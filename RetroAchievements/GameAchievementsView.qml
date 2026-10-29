// XboxOSv2 – GameAchievementsView.qml
// One game's achievements, after the Xbox Series game Progress page.
//
//   Hero: your fanart for this game (when you came from its details page),
//         otherwise RA's in-game screenshot, dimmed and fading into the band
//         colour of your accent. Game art + title top left; the "Path to
//         Mythic" card (or the Mythic star once it's 100%); Points,
//         Achievements and Overall progress on the right.
//   Body: rail (Achievements; Stats joins it next), Sort and Filter, and
//         every achievement as a card: wide art (the badge on a soft blow-up
//         of its own colours), name, description, how many players have it,
//         when you unlocked it, points with a diamond when it's rare (<10%).
//
// Keys: Up/Down move; Up from the first card reaches Sort / Filter (A
// changes them). Shortcuts kept from before: Y sort, LB/RB filter, X refresh,
// A on a card launches the game when it's in your library, B back (one press
// to Game details when you came from there, else back to the RA page).

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
    onDisplayListChanged: if (currentIndex >= displayList.length) currentIndex = Math.max(0, displayList.length - 1)

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

    // Your fanart for this game when it's the one Game details was showing.
    readonly property string localArt: {
        if (!currentGame || !det.Title) return "";
        if (cheevosData.normalizeTitle(currentGame.title) !== cheevosData.normalizeTitle(det.Title)) return "";
        return currentGame.assets.background || currentGame.assets.screenshot || "";
    }

    // ── Sort / Filter ────────────────────────────────────────────────────
    readonly property var sortKeys:    ["default", "points", "rarity", "date"]
    readonly property var sortNames:   ["Default", "Points", "Rarity", "Date unlocked"]
    readonly property var filterKeys:  ["all", "earned", "locked", "missable"]
    readonly property var filterNames: ["All", "Unlocked", "Locked", "Missable"]
    function cycleSort(d) {
        var i = sortKeys.indexOf(cheevosData.sortMode); if (i < 0) i = 0;
        cheevosData.sortMode = sortKeys[(i + (d || 1) + sortKeys.length) % sortKeys.length];
        currentIndex = 0;
    }
    function cycleFilter(d) {
        var i = filterKeys.indexOf(cheevosData.filterMode); if (i < 0) i = 0;
        cheevosData.filterMode = filterKeys[(i + d + filterKeys.length) % filterKeys.length];
        currentIndex = 0;
    }

    // Focus zones: 1 Sort/Filter, 2 the list. railFocus: on the rail, where
    // Up/Down switch between Achievements and Stats straight away.
    property int zone: 2
    property int toolIndex: 0
    property bool railFocus: false
    property int railIndex: 0                    // 0 Achievements, 1 Stats
    readonly property var railNames: ["Achievements", "Stats"]
    readonly property bool onStats: railIndex === 1
    readonly property bool accentIsLight: (0.299 * cAccent.r + 0.587 * cAccent.g + 0.114 * cAccent.b) > 0.62

    // Stats: your copy of the game in Pegasus (time played and so on),
    // looked up once per game the first time Stats opens.
    property var localGame: null
    property int localFor: 0
    onOnStatsChanged: if (onStats) prepareStats()
    function prepareStats() {
        var id = cheevosData.currentGameID;
        cheevosData.loadGameRank(id);
        if (localFor === id) return;
        localFor = id;
        var t = det.Title || "";
        if (currentGame && t !== "" && cheevosData.normalizeTitle(currentGame.title) === cheevosData.normalizeTitle(t))
            localGame = currentGame;
        else
            localGame = cheevosData.findLocalGame(t, det.ConsoleName || "");
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

        Rectangle { anchors.fill: parent; color: root.band }
        Image {
            anchors.fill: parent
            source: root.localArt !== "" ? root.localArt
                  : (det.ImageIngame ? "https://media.retroachievements.org" + det.ImageIngame : "")
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            sourceSize: Qt.size(hrpx(640), hrpx(360))
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        // Dimmed at the top, fading into the band colour at the bottom.
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0;  color: Qt.rgba(0.04, 0.04, 0.04, 0.74) }
                GradientStop { position: 0.38; color: Qt.rgba(0.04, 0.04, 0.04, 0.55) }
                GradientStop { position: 0.80; color: Qt.rgba(root.band.r, root.band.g, root.band.b, 0.9) }
                GradientStop { position: 1.0;  color: root.band }
            }
        }

        // Game art + title
        Rectangle {
        id: gameArt
            x: vpx(67); y: vpx(24)
            width: vpx(56); height: width; radius: vpx(4)
            color: Qt.rgba(0, 0, 0, 0.35)
            Image {
                anchors.fill: parent
                source: det.ImageIcon ? "https://media.retroachievements.org" + det.ImageIcon : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true; smooth: true
                sourceSize: Qt.size(hrpx(64), hrpx(64))
            }
        }
        Column {
            anchors { left: gameArt.right; leftMargin: vpx(13); right: parent.right; rightMargin: vpx(200); verticalCenter: gameArt.verticalCenter }
            Text {
                width: parent.width; elide: Text.ElideRight
                text: det.Title || (cheevosData.statusText || "Loading…")
                color: "white"; font.family: titleFont.name; font.pixelSize: fpx(20)
            }
            Text {
                text: det.ConsoleName || ""
                color: "#d0d0d0"; font.family: bodyFont.name; font.pixelSize: fpx(13)
            }
        }
        StatusCluster { anchors.fill: parent; z: 50; dark: false }

        // Path to Mythic / Mythic card
        Item {
        id: mythicCard
            x: vpx(67); y: vpx(112)
            width: vpx(467); height: vpx(113)
            Rectangle { anchors.fill: parent; anchors.margins: -vpx(8); radius: vpx(12); color: root.light(root.cAccent, 0.35); opacity: 0.12 }
            Rectangle { anchors.fill: parent; anchors.margins: -vpx(4); radius: vpx(9);  color: root.light(root.cAccent, 0.35); opacity: 0.25 }
            Rectangle {
                anchors.fill: parent; radius: vpx(6)
                color: Qt.rgba(0, 0, 0, 0.42)
                border.width: vpx(2); border.color: root.light(root.cAccent, 0.3)
            }
            Image {
            id: mythicIcon
                x: vpx(10); anchors.verticalCenter: parent.verticalCenter
                width: vpx(84); height: width
                sourceSize: Qt.size(hrpx(84), hrpx(84))
                smooth: true
                opacity: root.mythic ? 1 : 0.55
                source: Emb.dataUrl(Emb.mythic(theme.accent, "g"))
            }
            Column {
                anchors { left: mythicIcon.right; leftMargin: vpx(10); right: parent.right; rightMargin: vpx(20); verticalCenter: parent.verticalCenter }
                spacing: vpx(3)
                Text {
                    text: root.mythic ? "Mythic" : "Path to Mythic"
                    color: "white"; font.family: titleFont.name; font.pixelSize: fpx(16)
                }
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: root.mythic
                          ? ((det.Award === "mastered" ? "Mastered in hardcore" : det.Award === "completed" ? "Completed in softcore" : "Every achievement unlocked")
                             + (det.AwardDate ? "  ·  " + Qt.formatDate(new Date(Date.parse(det.AwardDate)), "MMM d, yyyy") : ""))
                          : (root.total > 0 ? root.unlocked + " of " + root.total + " achievements  ·  " + (root.total - root.unlocked) + " to go" : "")
                    color: "#dddddd"; font.family: bodyFont.name; font.pixelSize: fpx(13)
                }
                Item {
                    visible: !root.mythic
                    width: parent.width; height: vpx(4)
                    Rectangle { anchors.fill: parent; color: root.cDark }
                    Rectangle { width: parent.width * root.pct / 100; height: parent.height; color: root.light(root.cAccent, 0.4) }
                }
            }
        }

        // Points / Achievements / Overall progress
        Row {
            x: vpx(600); y: vpx(137)
            spacing: vpx(60)
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
        visible: !root.onStats
        anchors { left: rail.right; leftMargin: vpx(31); right: parent.right; rightMargin: vpx(67); top: hero.bottom; topMargin: vpx(23) }
        height: vpx(39)
        Rectangle {
        id: sortBox
            readonly property bool hot: root.zone === 1 && root.toolIndex === 0 && !root.railFocus && root.activeFocus
            width: vpx(280); height: parent.height
            color: root.cardColor; radius: vpx(4)
            RAFocus { on: sortBox.hot }
            Text {
                anchors { left: parent.left; leftMargin: vpx(13); verticalCenter: parent.verticalCenter }
                text: "Sort: " + root.sortNames[Math.max(0, root.sortKeys.indexOf(cheevosData.sortMode))]
                color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(16)
            }
            RAIcon { anchors { right: parent.right; rightMargin: vpx(13); verticalCenter: parent.verticalCenter } source: "../assets/images/fluent/chevron_down.svg" }
            TapHandler { onTapped: { playToggle(); root.cycleSort(1); } }
        }
        Text {
            anchors { left: sortBox.right; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
            text: root.displayList.length + (root.displayList.length === 1 ? " achievement" : " achievements")
            color: theme.text; opacity: 0.6
            font.family: bodyFont.name; font.pixelSize: fpx(15)
        }
        Rectangle {
        id: filterBox
            readonly property bool hot: root.zone === 1 && root.toolIndex === 1 && !root.railFocus && root.activeFocus
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
                    text: "Filter: " + root.filterNames[Math.max(0, root.filterKeys.indexOf(cheevosData.filterMode))]
                    color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(16)
                }
            }
            TapHandler { onTapped: { playToggle(); root.cycleFilter(1); } }
        }
    }

    // ── Achievements ─────────────────────────────────────────────────────
    ListView {
    id: list
        visible: !root.onStats
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
            text: cheevosData.statusText || "Nothing here"
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

            // Wide art: the badge on a soft blow-up of itself. The blow-up is
            // the same image rendered into a 12x7 texture and stretched: one
            // download, one decode, no blur pass.
            Item {
            id: wideArt
                width: vpx(222); height: parent.height
                clip: true
                Image {
                    anchors.fill: parent
                    source: card.badge
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(hrpx(64), hrpx(64))
                    mipmap: true            // the shrink averages, instead of sampling a few pixels (blocks)
                    layer.enabled: true
                    layer.smooth: true
                    layer.textureSize: Qt.size(12, 7)
                }
                Rectangle { anchors.fill: parent; color: "black"; opacity: card.earned ? 0.35 : 0.55 }
                Image {
                    anchors.centerIn: parent
                    width: vpx(84); height: width
                    source: card.badge
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
                    text: card.earned ? "Unlocked " + root.fmtDate(ach.DateEarned) + (ach.Hardcore ? "  ·  hardcore" : "  ·  softcore")
                                      : ("Locked" + (ach.Type === "missable" ? "  ·  missable" : ""))
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
                    if (card.selected) root.launchOwnGame();
                    else { root.zone = 2; root.currentIndex = index; root.forceActiveFocus(); }
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
    Grid {
    id: statsGrid
        visible: root.onStats
        anchors { left: rail.right; leftMargin: vpx(31); right: parent.right; rightMargin: vpx(67); top: hero.bottom; topMargin: vpx(23) }
        columns: 3
        spacing: vpx(10)
        Repeater {
            model: root.onStats ? root.statTiles : []
            delegate: Rectangle {
                width: (statsGrid.width - 2 * statsGrid.spacing) / 3; height: vpx(80)
                radius: vpx(4); color: root.cardColor
                Column {
                    anchors { left: parent.left; leftMargin: vpx(16); right: parent.right; rightMargin: vpx(12); verticalCenter: parent.verticalCenter }
                    spacing: vpx(1)
                    Text { text: modelData[0]; color: theme.text; opacity: 0.7; font.family: bodyFont.name; font.pixelSize: fpx(13) }
                    Text { width: parent.width; elide: Text.ElideRight; text: modelData[1]; color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(22) }
                    // Always there (blank when empty) so every tile's lines sit at the same height.
                    Text { width: parent.width; elide: Text.ElideRight; text: modelData[2] || " "; color: theme.text; opacity: 0.5; font.family: bodyFont.name; font.pixelSize: fpx(11) }
                }
            }
        }
    }

    // ── Local help bar ───────────────────────────────────────────────────
    Row {
        z: 5
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
    ListModel {
    id: localHelpModel
        ListElement { name: "Launch";  button: "accept"  }
        ListElement { name: "Refresh"; button: "details" }
        ListElement { name: "Sort";    button: "filters" }
        ListElement { name: "Back";    button: "cancel"  }
    }

    // ── Keys ─────────────────────────────────────────────────────────────
    Keys.onUpPressed: {
        event.accepted = true;
        if (railFocus) { if (railIndex > 0) { railIndex--; playNav(); } return; }
        if (onStats) return;
        if (zone === 2) {
            if (currentIndex > 0) { currentIndex--; playNav(); }
            else { zone = 1; playNav(); }
        }
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (railFocus) { if (railIndex < railNames.length - 1) { railIndex++; playNav(); } return; }
        if (onStats) return;
        if (zone === 1) { if (displayList.length > 0) { zone = 2; playNav(); } }
        else if (currentIndex < displayList.length - 1) { currentIndex++; playNav(); }
    }
    // Left reaches the rail (from the list, or the first of Sort/Filter);
    // Right leaves it again (Stats has nothing to focus, so it stays).
    Keys.onLeftPressed: {
        event.accepted = true;
        if (railFocus) return;
        if (zone === 1 && toolIndex > 0) { toolIndex--; playNav(); }
        else { railFocus = true; playNav(); }
    }
    Keys.onRightPressed: {
        event.accepted = true;
        if (railFocus) { if (!onStats) { railFocus = false; playNav(); } return; }
        if (zone === 1 && toolIndex < 1) { toolIndex++; playNav(); }
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
        if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; goBack(); }
        if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; playToggle(); cycleFilter(-1); }
        if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; playToggle(); cycleFilter(1); }
        if (api.keys.isFilters(event) && !event.isAutoRepeat)  { event.accepted = true; playToggle(); cycleSort(1); }
        if (api.keys.isDetails(event) && !event.isAutoRepeat)  { event.accepted = true; refresh(); }
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (railFocus) { if (!onStats) { railFocus = false; playNav(); } }
            else if (zone === 1) { playToggle(); if (toolIndex === 0) cycleSort(1); else cycleFilter(1); }
            else launchOwnGame();
        }
    }

    // A — launch the game these achievements belong to, when a matching game
    // exists locally: currentGame if it's the same title (RA was entered from
    // that game or via search), otherwise the library by normalized title.
    function launchOwnGame() {
        var raTitle = cheevosData.currentGameDetails.Title || "";
        var target  = null;
        if (currentGame && raTitle !== ""
            && cheevosData.normalizeTitle(currentGame.title) === cheevosData.normalizeTitle(raTitle))
            target = currentGame;
        if (!target)
            target = cheevosData.findLocalGame(raTitle, cheevosData.currentGameDetails.ConsoleName || "");
        if (target) {
            playAccept();
            launchGameFromRA(target);
        }
    }
    // Clickable prompts: each does what its button does.
    function helpAction(button) {
        if (button === "cancel") goBack();
        else if (button === "filters") { playToggle(); cycleSort(1); }
        else if (button === "details") refresh();
        else if (button === "accept") launchOwnGame();
        else return false;
        return true;
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
