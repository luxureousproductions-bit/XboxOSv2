// XboxOSv2 – RAAchievementDetail.qml
// A on an achievement: the console's achievement pop-up. Over a blurred,
// dimmed copy of the game's art:
//   left    the badge, big
//   middle  the game, the achievement (points, a diamond when rare), its
//           description, locked / unlocked and when, how many players have
//           it, its type, then Launch game (Find in your library when it
//           isn't matched) and Change match
//   right   the game's tracker: points and achievements rings, the Mythic
//           card, and the achievement list; moving in it changes the
//           middle card
//
// Keys: Up/Down move in the column you're in, Left/Right switch columns,
// LB/RB previous / next achievement, A on a button does it, B closes.
// Icons: Fluent UI System Icons (assets/images/fluent, MIT).

import QtQuick 2.15
import QtGraphicalEffects 1.15
import "raEmblems.js" as Emb

FocusScope {
id: pop

    anchors.fill: parent
    visible: false
    z: 100

    property var host: null                    // GameAchievementsView
    readonly property var list: host ? host.displayList : []
    readonly property int index: host ? host.currentIndex : 0
    readonly property var ach: (index >= 0 && index < list.length) ? list[index] : null
    readonly property bool earned: ach !== null && ach.DateEarned > 0
    readonly property bool rare: ach !== null && ach.Rarity > 0 && ach.Rarity < 10
    property bool inList: false                // focus: false = buttons, true = the list
    property int button: 0                     // 0 Launch / Find, 1 Change match
    readonly property bool canChange: host !== null && (host.localGame !== null || host.raFromDetailsGame !== null)

    signal closed()

    readonly property color cardColor:  whiteBackground ? "#f4f4f4" : "#262626"
    readonly property color panelColor: whiteBackground ? "#ffffff" : "#2b2b2b"
    readonly property color trackColor: whiteBackground ? "#d6d6d6" : "#4a4a4a"
    readonly property color fillColor:  host ? host.light(host.cAccent, whiteBackground ? 0 : 0.2) : "white"

    function open() {
        inList = false; button = 0;
        visible = true;
        forceActiveFocus();
        tracker.positionViewAtIndex(index, ListView.Center);
        playAccept();
    }
    function close() { visible = false; playBack(); closed(); }
    function step(d) {
        var i = index + d;
        if (i < 0 || i >= list.length) return;
        host.currentIndex = i;
        playNav();
    }
    function press() {
        if (inList) { inList = false; playNav(); return; }
        if (button === 1) { visible = false; closed(); host.changeMatch(); }
        else if (host.localGame) { host.launchOwnGame(); }
        else { visible = false; closed(); host.launchOrFind(); }
    }
    function typeText(a) {
        if (!a) return "";
        var t = a.Type === "progression" ? "Progression  ·  needed to beat the game"
              : a.Type === "win_condition" ? "Win condition  ·  beats the game"
              : a.Type === "missable" ? "Missable  ·  can be missed for good" : "";
        var set = a.Set === "Unofficial" ? "Unofficial" : (a.Set ? a.Set + " subset" : "");
        return t !== "" && set !== "" ? t + "  ·  " + set : (t || set);
    }

    // ── Backdrop: the game's art, blurred by decoding it tiny ────────────
    Rectangle { anchors.fill: parent; color: "#111111" }
    Image {
        anchors.fill: parent
        source: host ? (host.localArt !== "" ? host.localArt
                        : (host.det.ImageIngame ? "https://media.retroachievements.org" + host.det.ImageIngame : "")) : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(48, 27)
        smooth: true; mipmap: false
        asynchronous: true
        opacity: 0.6
    }
    Rectangle { anchors.fill: parent; color: "black"; opacity: 0.45 }
    MouseArea { anchors.fill: parent; onClicked: pop.close() }

    // ── Left: the badge ──────────────────────────────────────────────────
    Image {
        x: (card.x - width) / 2; anchors.verticalCenter: card.verticalCenter
        width: Math.min(vpx(300), card.x - vpx(60)); height: width
        source: pop.ach && pop.ach.BadgeName ? "https://media.retroachievements.org/Badge/" + pop.ach.BadgeName + (pop.earned ? "" : "_lock") + ".png" : ""
        sourceSize: Qt.size(hrpx(64), hrpx(64))
        smooth: true; asynchronous: true
        fillMode: Image.PreserveAspectFit
    }

    // ── Middle: the achievement ──────────────────────────────────────────
    Rectangle {
    id: card
        x: parent.width * 0.307; y: parent.height * 0.185
        width: vpx(373); height: parent.height * 0.705
        radius: vpx(6)
        color: pop.cardColor
        MouseArea { anchors.fill: parent }

        Column {
            x: vpx(22); y: vpx(20)
            width: parent.width - vpx(44)
            spacing: vpx(10)

            Row {
                spacing: vpx(12)
                width: parent.width
                Image {
                id: gameIcon
                    width: vpx(46); height: width
                    source: host ? host.boxArt : ""
                    sourceSize: Qt.size(hrpx(92), hrpx(92))
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true; smooth: true
                }
                Text {
                    width: parent.width - gameIcon.width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    text: host ? (host.det.Title || "") : ""
                    elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap
                    color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(16)
                }
            }
            Item {
                width: parent.width; height: achTitle.height
                Text {
                id: achTitle
                    anchors { left: parent.left; right: pts.left; rightMargin: vpx(10) }
                    text: pop.ach ? pop.ach.Title : ""
                    wrapMode: Text.WordWrap
                    color: theme.text; font.family: titleFont.name; font.pixelSize: fpx(20)
                }
                Row {
                id: pts
                    anchors { right: parent.right; top: parent.top; topMargin: vpx(3) }
                    spacing: vpx(6)
                    RAIcon { visible: pop.rare; size: vpx(16); source: "../assets/images/fluent/diamond.svg"; anchors.verticalCenter: parent.verticalCenter }
                    PointsGlyph { size: vpx(16); fill: whiteBackground ? "#303030" : "#e6e6e6"; textColor: pop.cardColor; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: pop.ach ? pop.ach.Points : ""; color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(18) }
                }
            }
            Text {
                width: parent.width
                text: pop.ach ? pop.ach.Description : ""
                wrapMode: Text.WordWrap
                color: theme.text; opacity: 0.85; font.family: bodyFont.name; font.pixelSize: fpx(16)
            }
            Row {
                topPadding: vpx(6)
                spacing: vpx(8)
                RAIcon {
                    size: vpx(18); anchors.verticalCenter: parent.verticalCenter
                    source: pop.earned ? "../assets/images/fluent/checkmark_circle.svg" : "../assets/images/fluent/lock.svg"
                }
                Text {
                    text: pop.earned ? "Unlocked " + host.fmtDate(pop.ach.DateEarned) + (pop.ach.Hardcore ? "  ·  hardcore" : "  ·  softcore")
                                     : "Locked"
                    color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(15)
                }
            }
            Rectangle {
                width: parent.width; height: vpx(3); color: pop.trackColor
                Rectangle { width: pop.earned ? parent.width : 0; height: parent.height; color: pop.fillColor }
            }
            Text {
                topPadding: vpx(4)
                text: pop.ach && pop.ach.Rarity > 0 ? pop.ach.Rarity + "% of players unlocked this" + (pop.rare ? "  ·  rare" : "") : ""
                color: theme.text; opacity: 0.75; font.family: bodyFont.name; font.pixelSize: fpx(15)
            }
            Row {
                visible: pop.typeText(pop.ach) !== ""
                spacing: vpx(8)
                RAIcon { size: vpx(18); source: "../assets/images/fluent/flag.svg"; anchors.verticalCenter: parent.verticalCenter }
                Text { text: pop.typeText(pop.ach); color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(15) }
            }
            Rectangle { width: parent.width; height: vpx(1); color: theme.text; opacity: 0.15 }

            // Buttons
            Repeater {
                model: pop.canChange ? 2 : 1
                delegate: Rectangle {
                    readonly property bool hot: !pop.inList && pop.button === index && pop.activeFocus
                    width: parent.width; height: vpx(46)
                    radius: vpx(4)
                    color: hot ? (whiteBackground ? "#e6e6e6" : "#3c3c3c") : "transparent"
                    RAFocus { on: parent.hot }
                    Row {
                        anchors { left: parent.left; leftMargin: vpx(14); verticalCenter: parent.verticalCenter }
                        spacing: vpx(12)
                        RAIcon {
                            size: vpx(22); anchors.verticalCenter: parent.verticalCenter
                            source: index === 1 ? "../assets/images/fluent/link.svg"
                                  : (host && host.localGame ? "../assets/images/fluent/games.svg" : "../assets/images/fluent/search.svg")
                        }
                        Text {
                            text: index === 1 ? "Change match" : (host && host.localGame ? "Launch game" : "Find in your library")
                            color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(18)
                        }
                    }
                    TapHandler { onTapped: { pop.inList = false; pop.button = index; pop.press(); } }
                }
            }
        }
    }

    // ── Right: the tracker ───────────────────────────────────────────────
    Rectangle {
    id: panel
        x: parent.width * 0.657; y: parent.height * 0.054
        // Stops above the button prompts (the console runs it to the edge,
        // but here the prompts sit at the bottom).
        width: parent.width * 0.281; height: parent.height - y - helpMargin
        radius: vpx(7)
        color: pop.panelColor
        MouseArea { anchors.fill: parent }

        Column {
        id: head
            x: vpx(22); y: vpx(22)
            width: parent.width - vpx(44)
            spacing: vpx(14)
            Column {
                Text { text: "Achievements"; color: theme.text; font.family: titleFont.name; font.pixelSize: fpx(26) }
                Text { width: head.width; elide: Text.ElideRight; text: host ? (host.det.Title || "") : ""; color: theme.text; opacity: 0.7; font.family: bodyFont.name; font.pixelSize: fpx(15) }
            }
            // Points and achievements, as rings.
            Row {
                spacing: vpx(28)
                Repeater {
                    model: 2
                    delegate: Row {
                    id: ringRow
                        spacing: vpx(12)
                        readonly property real frac: index === 0
                            ? (host && host.det.PossibleScore > 0 ? host.det.ScoreAchieved / host.det.PossibleScore : 0)
                            : (host && host.total > 0 ? host.unlocked / host.total : 0)
                        Item {
                            width: vpx(50); height: width
                            Rectangle { id: ringShape; anchors.fill: parent; radius: width / 2; visible: false }
                            ConicalGradient {
                                anchors.fill: parent
                                source: ringShape
                                angle: 0
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: pop.fillColor }
                                    GradientStop { position: Math.max(0.0001, Math.min(0.9999, ringRow.frac)); color: pop.fillColor }
                                    GradientStop { position: Math.min(1, ringRow.frac + 0.0001); color: pop.trackColor }
                                    GradientStop { position: 1.0; color: pop.trackColor }
                                }
                            }
                            Rectangle {
                                anchors { fill: parent; margins: vpx(5) }
                                radius: width / 2; color: pop.panelColor
                                PointsGlyph {
                                    visible: index === 0; anchors.centerIn: parent; size: vpx(18)
                                    fill: whiteBackground ? "#303030" : "#e6e6e6"; textColor: pop.panelColor
                                }
                                Image {
                                    visible: index === 1; anchors.centerIn: parent
                                    width: vpx(20); height: width
                                    source: "../assets/images/trophy_outline.svg"; sourceSize: Qt.size(hrpx(40), hrpx(40))
                                    layer.enabled: whiteBackground
                                    layer.effect: ColorOverlay { color: theme.text }
                                }
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: index === 0 ? (host ? (host.det.ScoreAchieved || 0) + "/" + (host.det.PossibleScore || 0) : "")
                                              : (host ? host.unlocked + "/" + host.total : "")
                            color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(19)
                        }
                    }
                }
            }
            // Mythic
            Row {
                spacing: vpx(12)
                width: head.width
                Image {
                id: myth
                    width: vpx(56); height: width
                    sourceSize: Qt.size(hrpx(112), hrpx(112))
                    source: host ? (host.mythic ? Emb.dataUrl(Emb.mythic(theme.accent, "d")) : Emb.dataUrl(Emb.mythicLocked(theme.accent, "e"))) : ""
                }
                Column {
                    width: head.width - myth.width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: vpx(4)
                    Text { text: "Mythic Achievement"; color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(17) }
                    Item {
                        width: parent.width; height: vpx(18)
                        Text { text: host ? host.unlocked + "/" + host.total : ""; color: theme.text; opacity: 0.8; font.family: bodyFont.name; font.pixelSize: fpx(14) }
                        Text { anchors.right: parent.right; text: host ? host.pct + "%" : ""; color: theme.text; opacity: 0.8; font.family: bodyFont.name; font.pixelSize: fpx(14) }
                    }
                    Rectangle {
                        width: parent.width; height: vpx(3); color: pop.trackColor
                        Rectangle { width: parent.width * (host ? host.pct : 0) / 100; height: parent.height; color: pop.fillColor }
                    }
                }
            }
        }

        ListView {
        id: tracker
            anchors { left: parent.left; right: parent.right; top: head.bottom; topMargin: vpx(10); bottom: parent.bottom; bottomMargin: vpx(14) }
            leftMargin: vpx(14); rightMargin: vpx(14); topMargin: vpx(8); bottomMargin: vpx(8)
            clip: true
            model: pop.visible ? pop.list : []
            currentIndex: pop.index
            keyNavigationEnabled: false
            highlightMoveDuration: 120
            preferredHighlightBegin: height * 0.3
            preferredHighlightEnd: height * 0.7
            highlightRangeMode: ListView.ApplyRange
            delegate: Item {
                readonly property bool cur: index === pop.index
                width: tracker.width - tracker.leftMargin - tracker.rightMargin
                height: vpx(54)
                Rectangle {
                    anchors.fill: parent
                    radius: vpx(4)
                    color: parent.cur ? (whiteBackground ? "#ececec" : "#363636") : "transparent"
                    RAFocus { on: parent.parent.cur && pop.inList && pop.activeFocus }
                }
                Text {
                    anchors { left: parent.left; leftMargin: vpx(8); right: listPts.left; rightMargin: vpx(8); top: parent.top; topMargin: vpx(10) }
                    elide: Text.ElideRight
                    text: modelData.Title
                    color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(17)
                }
                Row {
                id: listPts
                    anchors { right: parent.right; rightMargin: vpx(8); top: parent.top; topMargin: vpx(11) }
                    spacing: vpx(5)
                    RAIcon { visible: modelData.Rarity > 0 && modelData.Rarity < 10; size: vpx(14); source: "../assets/images/fluent/diamond.svg"; anchors.verticalCenter: parent.verticalCenter }
                    PointsGlyph { size: vpx(14); fill: whiteBackground ? "#303030" : "#e6e6e6"; textColor: pop.panelColor; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: modelData.Points; color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(15) }
                }
                Rectangle {
                    anchors { left: parent.left; leftMargin: vpx(8); right: parent.right; rightMargin: vpx(8); bottom: parent.bottom; bottomMargin: vpx(8) }
                    height: vpx(3); color: pop.trackColor
                    Rectangle { width: modelData.DateEarned > 0 ? parent.width : 0; height: parent.height; color: pop.fillColor }
                }
                TapHandler { onTapped: { host.currentIndex = index; pop.inList = true; playNav(); } }
            }
        }
    }

    // ── Keys ─────────────────────────────────────────────────────────────
    Keys.onUpPressed: {
        event.accepted = true;
        if (inList) step(-1);
        else if (button > 0) { button--; playNav(); }
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (inList) step(1);
        else if (button < (canChange ? 1 : 0)) { button++; playNav(); }
    }
    Keys.onLeftPressed:  { event.accepted = true; if (inList) { inList = false; playNav(); } }
    Keys.onRightPressed: { event.accepted = true; if (!inList) { inList = true; playNav(); } }
    Keys.onPressed: {
        if (event.isAutoRepeat && !api.keys.isPrevPage(event) && !api.keys.isNextPage(event)) { event.accepted = true; return; }
        if (api.keys.isCancel(event)) close();
        else if (api.keys.isAccept(event)) press();
        else if (api.keys.isPrevPage(event)) step(-1);
        else if (api.keys.isNextPage(event)) step(1);
        event.accepted = true;
    }
}
