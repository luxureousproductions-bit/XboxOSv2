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
// Up/Down move between them, Left/Right inside a row, A presses.

import QtQuick 2.15
import QtGraphicalEffects 1.15
import "../Global"

FocusScope {
id: tab

    // ── Sort / Filter state ──────────────────────────────────────────────
    readonly property var sortNames:   ["Recent", "Completion", "Title", "Unlocked"]
    readonly property var filterNames: ["All", "In progress", "Mastered", "Beaten", "Completed"]
    property int sortIndex:   0
    property int filterIndex: 0
    property var games: []

    readonly property var chips: ["Closest to mastery", "Recently unlocked", "Mastered"]
    function applyChip(i) {
        if (i === 0)      { sortIndex = 1; filterIndex = 1; }   // highest % that isn't done yet
        else if (i === 1) { sortIndex = 0; filterIndex = 0; }
        else              { sortIndex = 0; filterIndex = 2; }
        zone = 2;
    }

    function keep(g) {
        switch (filterNames[filterIndex]) {
        case "In progress": return g.Award !== "mastered" && g.Award !== "completed" && g.Progress < 1;
        case "Mastered":    return g.Award === "mastered";
        case "Beaten":      return g.Award === "beaten-hardcore" || g.Award === "beaten-softcore";
        case "Completed":   return g.Award === "completed";
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
    onActiveFocusChanged: if (activeFocus) list.forceActiveFocus()

    // ── Left rail ────────────────────────────────────────────────────────
    // Followed users joins this rail in its own build.
    Item {
    id: rail
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: vpx(322)
        Rectangle {
            y: vpx(41); width: parent.width; height: vpx(42)
            color: tab.railSel
            Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: vpx(5); color: theme.accent }
            Text {
                anchors { left: parent.left; leftMargin: vpx(74); verticalCenter: parent.verticalCenter }
                text: "Achievements"
                color: theme.text
                font.family: bodyFont.name
                font.pixelSize: fpx(17)
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
        anchors { left: rail.right; leftMargin: vpx(46); right: parent.right; rightMargin: vpx(45); top: parent.top; bottom: parent.bottom }

        Row {
        id: chipRow
            y: vpx(24)
            spacing: vpx(12)
            Repeater {
                model: tab.chips
                delegate: Rectangle {
                    readonly property bool hot: tab.zone === 0 && tab.chipIndex === index && tab.activeFocus
                    width: chipText.implicitWidth + vpx(32); height: vpx(40)
                    color: tab.cardColor
                    border.width: hot ? vpx(3) : 0; border.color: theme.text
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
                readonly property bool hot: tab.zone === 1 && tab.toolIndex === 0 && tab.activeFocus
                width: vpx(390); height: parent.height
                color: tab.cardColor
                border.width: hot ? vpx(3) : 0; border.color: theme.text
                Text {
                    anchors { left: parent.left; leftMargin: vpx(14); verticalCenter: parent.verticalCenter }
                    text: "Sort: " + tab.sortNames[tab.sortIndex]
                    color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(16)
                }
                Text {
                    anchors { right: parent.right; rightMargin: vpx(14); verticalCenter: parent.verticalCenter }
                    text: "›"; rotation: 90
                    color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(22)
                }
                TapHandler { onTapped: { tab.sortIndex = (tab.sortIndex + 1) % tab.sortNames.length; playToggle(); } }
            }
            Rectangle {
                readonly property bool hot: tab.zone === 1 && tab.toolIndex === 1 && tab.activeFocus
                anchors.right: parent.right
                width: filterText.implicitWidth + vpx(32); height: parent.height
                color: tab.cardColor
                border.width: hot ? vpx(3) : 0; border.color: theme.text
                Text {
                id: filterText
                    anchors.centerIn: parent
                    text: "Filter: " + tab.filterNames[tab.filterIndex]
                    color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(16)
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
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: vpx(131); bottom: parent.bottom }
            model: tab.games
            spacing: vpx(10)
            clip: false
            cacheBuffer: vpx(300)
            focus: tab.zone === 2
            highlightMoveDuration: 120
            preferredHighlightBegin: vpx(6)
            preferredHighlightEnd: vpx(140)
            highlightRangeMode: ListView.ApplyRange
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
                readonly property bool mastered: g.Award === "mastered"
                readonly property bool selected: ListView.isCurrentItem && tab.zone === 2 && tab.activeFocus
                readonly property int pct: g.MaxPossible > 0 ? Math.floor(g.NumAwarded * 100 / g.MaxPossible) : 0
                width: list.width; height: vpx(124)

                Rectangle {
                    anchors.fill: parent
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
                Rectangle {
                    anchors.fill: parent; anchors.margins: -vpx(4)
                    visible: card.selected
                    color: "transparent"; border.width: vpx(3); border.color: theme.text
                }
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
                            Text {
                                leftPadding: vpx(18)
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
            active: tab.visible && !searchOpen
            onStepped: function(quiet) { if (!quiet) playNav(); }
        }
    }

    function openGame(i) {
        if (i < 0 || i >= games.length) return;
        playAccept();
        cheevosData.loadGameAchievements(games[i].GameID);
        gameAchievementsScreenFromOverview();
    }

    // ── Keys ─────────────────────────────────────────────────────────────
    // Arrows are always accepted here, so the Recent list underneath never
    // moves (or beeps) while this tab is up.
    Keys.onUpPressed: {
        event.accepted = true;
        if (zone === 2) {
            if (list.currentIndex > 0) list.currentIndex--;
            else { zone = 1; playNav(); }
        } else if (zone === 1) { zone = 0; playNav(); }
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (zone === 0) { zone = 1; playNav(); }
        else if (zone === 1) { if (games.length > 0) { zone = 2; playNav(); } }
        else if (list.currentIndex < games.length - 1) list.currentIndex++;
    }
    Keys.onLeftPressed: {
        event.accepted = true;
        if (zone === 0 && chipIndex > 0) { chipIndex--; playNav(); }
        else if (zone === 1 && toolIndex > 0) { toolIndex--; playNav(); }
    }
    Keys.onRightPressed: {
        event.accepted = true;
        if (zone === 0 && chipIndex < chips.length - 1) { chipIndex++; playNav(); }
        else if (zone === 1 && toolIndex < 1) { toolIndex++; playNav(); }
    }
    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (zone === 0) { playAccept(); applyChip(chipIndex); }
            else if (zone === 1) {
                playToggle();
                if (toolIndex === 0) sortIndex = (sortIndex + 1) % sortNames.length;
                else filterIndex = (filterIndex + 1) % filterNames.length;
            } else openGame(list.currentIndex);
        }
    }
}
