// XboxOSv2 – RAAwardsTab.qml
// The Awards tab of the RetroAchievements page: your trophy case, newest
// first, as tiles. The rail on the left filters by kind, with counts.
// Mastered games keep their Mythic-style frame (RAMythicFrame.qml).
//
// Data: cheevosData.awardsList (CheevosData.loadAwards, RA's visible
// awards). Kinds, from AwardType + AwardDataExtra (1 = hardcore):
//   "Mastery/Completion" 1 -> mastered, 0 -> completed
//   "Game Beaten"        1 -> beaten (hardcore), 0 -> beaten (softcore)
//   anything else (events, site awards) -> other
//
// Focus: the grid; Left from its first column goes to the rail, where
// Up/Down change the filter straight away and Right goes back.

import QtQuick 2.15
import "../Global"

FocusScope {
id: tab

    // Mythic = 100% of a game, RA's Mastered (hardcore) or Completed
    // (softcore), as on the Xbox; each tile still says which.
    readonly property var railNames: ["All awards", "Mythic", "Beaten", "Events & site"]
    property int railIndex: 0
    property bool railFocus: false
    property var counts: [0, 0, 0, 0, 0]
    property var tiles: []

    function kindOf(a) {
        var hc = parseInt(a.AwardDataExtra) === 1;
        if (a.AwardType === "Mastery/Completion") return hc ? "mastered" : "completed";
        if (a.AwardType === "Game Beaten") return hc ? "beaten-hardcore" : "beaten-softcore";
        return "other";
    }
    function railOf(k) {
        return (k === "mastered" || k === "completed") ? 1 : (k === "beaten-hardcore" || k === "beaten-softcore") ? 2 : 3;
    }
    function rebuild() {
        var src = cheevosData.awardsList || [], out = [], c = [src.length, 0, 0, 0];
        for (var i = 0; i < src.length; i++) {
            var a = src[i], k = kindOf(a), r = railOf(k);
            c[r]++;
            if (railIndex === 0 || railIndex === r)
                out.push({ title: a.Title || "", icon: a.ImageIcon || "", kind: k, date: a.AwardedAt || "", gameID: parseInt(a.AwardData) || 0 });
        }
        counts = c;
        tiles = out;
        grid.currentIndex = 0;
    }
    onRailIndexChanged: rebuild()
    Connections {
        target: cheevosData
        onAwardsListChanged: tab.rebuild()
    }
    Component.onCompleted: rebuild()

    function dateText(d) {
        var ms = Date.parse(d);
        return isNaN(ms) ? "" : Qt.formatDate(new Date(ms), "MMM d, yyyy");
    }

    readonly property color cardColor: whiteBackground ? "#ffffff" : "#303030"
    readonly property color railSel:   whiteBackground ? "#ffffff" : "#2b2b2b"
    readonly property color cAccent:   theme.accent
    readonly property bool  accentIsLight: (0.299 * cAccent.r + 0.587 * cAccent.g + 0.114 * cAccent.b) > 0.62
    function mixc(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1); }
    onActiveFocusChanged: if (activeFocus) grid.forceActiveFocus()

    // ── Rail: kinds of award, with counts ────────────────────────────────
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
                    // As in Settings: an accent plate while the rail has focus,
                    // a grey plate with an accent edge while you're in the grid.
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
                        font.family: bodyFont.name; font.pixelSize: fpx(17)
                    }
                    Text {
                        anchors { right: parent.right; rightMargin: vpx(28); verticalCenter: parent.verticalCenter }
                        text: tab.counts[index]
                        color: parent.ink; opacity: parent.hot ? 0.85 : 0.6
                        font.family: bodyFont.name; font.pixelSize: fpx(15)
                    }
                    TapHandler { onTapped: { tab.railIndex = index; playNav(); } }
                }
            }
        }
    }
    Rectangle {
        anchors { left: rail.right; top: parent.top; bottom: parent.bottom }
        width: vpx(1); color: theme.text; opacity: 0.12
    }

    // ── Tiles ────────────────────────────────────────────────────────────
    GridView {
    id: grid
        // Clipped so scrolled tiles don't slide over the header; the inner
        // top padding keeps the focus outline and the frame glow inside it.
        // keyNavigationEnabled off: the tab's Keys do all moves (the grid's
        // own Left jumped to the previous row instead of reaching the rail).
        // Padding on every side = the focus frame's reach, so the clip never
        // cuts it (the left edge of the first column used to be cut off).
        anchors { left: rail.right; leftMargin: vpx(32); right: parent.right; rightMargin: vpx(31); top: parent.top; topMargin: vpx(10); bottom: parent.bottom; bottomMargin: helpMargin }
        leftMargin: vpx(14); rightMargin: vpx(14); bottomMargin: vpx(14)
        clip: true
        topMargin: vpx(14)
        keyNavigationEnabled: false
        readonly property int cols: 3
        cellWidth: Math.floor((width - leftMargin - rightMargin) / cols)
        cellHeight: vpx(214)
        model: tab.tiles
        focus: !tab.railFocus
        cacheBuffer: vpx(220)
        highlightMoveDuration: 120
        preferredHighlightBegin: vpx(14)
        preferredHighlightEnd: vpx(228)
        highlightRangeMode: GridView.ApplyRange
        property bool navReady: false
        Component.onCompleted: navReady = true
        onCurrentIndexChanged: if (navReady && tab.activeFocus) playNav()

        Text {
            anchors { top: parent.top; topMargin: vpx(30); horizontalCenter: parent.horizontalCenter }
            visible: tab.tiles.length === 0
            text: cheevosData.awardsLoaded ? "No awards here yet" : "Loading your awards…"
            color: theme.text; opacity: 0.55
            font.family: bodyFont.name; font.pixelSize: fpx(18)
        }

        delegate: Item {
        id: cell
            readonly property var t: modelData
            readonly property bool selected: GridView.isCurrentItem && !tab.railFocus && tab.activeFocus
            width: grid.cellWidth; height: grid.cellHeight
            Rectangle {
            id: tile
                anchors { fill: parent; rightMargin: vpx(14); bottomMargin: vpx(14) }
                color: tab.cardColor
                radius: vpx(4)
                RAFocus { on: cell.selected }
                RAMythicFrame {
                id: art
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: vpx(14) }
                    width: vpx(110); height: width
                    mastered: t.kind === "mastered" || t.kind === "completed"
                    source: t.icon ? "https://media.retroachievements.org" + t.icon : ""
                }
                Column {
                    anchors { left: parent.left; right: parent.right; leftMargin: vpx(10); rightMargin: vpx(10); top: art.bottom; topMargin: art.mastered ? vpx(16) : vpx(10) }
                    spacing: vpx(2)
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: t.title
                        elide: Text.ElideRight
                        color: theme.text
                        font.family: titleFont.name; font.pixelSize: fpx(15)
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: vpx(5)
                        RAIcon {
                            size: vpx(12)
                            visible: t.kind === "beaten-hardcore" || t.kind === "beaten-softcore"
                            anchors.verticalCenter: parent.verticalCenter
                            source: "../assets/images/fluent/flag.svg"
                            opacity: 0.7
                        }
                        Text {
                            text: (t.kind === "mastered" ? "MASTERED"
                                  : t.kind === "completed" ? "COMPLETED · softcore"
                                  : t.kind === "beaten-hardcore" ? "BEATEN"
                                  : t.kind === "beaten-softcore" ? "BEATEN · softcore" : "AWARD")
                                  + "  ·  " + tab.dateText(t.date)
                            color: (t.kind === "mastered" || t.kind === "completed") ? tab.mixc(tab.cAccent, Qt.rgba(1, 1, 1, 1), whiteBackground ? 0 : 0.5) : theme.text
                            opacity: (t.kind === "mastered" || t.kind === "completed") ? 1 : 0.7
                            font.family: bodyFont.name; font.pixelSize: fpx(12)
                        }
                    }
                }
            }
            TapHandler {
                onTapped: {
                    tab.railFocus = false;
                    if (cell.selected) tab.openTile(index);
                    else { grid.currentIndex = index; tab.forceActiveFocus(); }
                }
            }
        }
    }
    WheelNav {
        anchors.fill: grid
        view: grid
        columns: grid.cols
        active: tab.visible && !searchOpen
        onStepped: function(quiet) { if (!quiet) playNav(); }
    }

    function openTile(i) {
        if (i < 0 || i >= tiles.length || tiles[i].kind === "other" || tiles[i].gameID <= 0) return;
        playAccept();
        cheevosData.loadGameAchievements(tiles[i].gameID);
        gameAchievementsScreenFromOverview();
    }

    // ── Keys ─────────────────────────────────────────────────────────────
    // Arrows are always accepted here, so the Recent list underneath never moves.
    Keys.onUpPressed: {
        event.accepted = true;
        if (railFocus) { if (railIndex > 0) { railIndex--; playNav(); } }
        else if (grid.currentIndex >= grid.cols) grid.currentIndex -= grid.cols;
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (railFocus) { if (railIndex < railNames.length - 1) { railIndex++; playNav(); } }
        else if (grid.currentIndex + grid.cols < tiles.length) grid.currentIndex += grid.cols;
        else if (Math.floor(grid.currentIndex / grid.cols) < Math.floor((tiles.length - 1) / grid.cols)) grid.currentIndex = tiles.length - 1;
    }
    Keys.onLeftPressed: {
        event.accepted = true;
        if (railFocus) return;
        if (grid.currentIndex % grid.cols === 0 || tiles.length === 0) { railFocus = true; playNav(); }
        else grid.currentIndex--;
    }
    Keys.onRightPressed: {
        event.accepted = true;
        if (railFocus) { if (tiles.length > 0) { railFocus = false; playNav(); } }
        else if (grid.currentIndex % grid.cols < grid.cols - 1 && grid.currentIndex < tiles.length - 1) grid.currentIndex++;
    }
    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (railFocus) { if (tiles.length > 0) { railFocus = false; playNav(); } }
            else openTile(grid.currentIndex);
        }
    }
}
