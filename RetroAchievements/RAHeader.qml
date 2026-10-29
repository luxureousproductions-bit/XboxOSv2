// XboxOSv2 – RAHeader.qml
// The top of the RetroAchievements page, after the Xbox Series "Gaming" tab:
// a band in your accent's dark shades with your profile, the tabs and three
// stats (points, achievements, mastered games). Shared by the RA tabs.
//
// Colours: the band mixes Xbox's dark and mid shades of the accent
// (theme.accentDark / theme.accentMid), which is how the console's own
// header reads. Everything on it is light text: the band is always dark.
// The emblems are drawn as SVG from the accent (raEmblems.js: metal,
// facets, glows), rendered once at their size, again only if the accent
// changes.

import QtQuick 2.15
import QtGraphicalEffects 1.15
import "../Global"
import "raEmblems.js" as Emb

Item {
id: header

    property var  tabs: []          // tab names, left to right
    property int  current: 0        // selected tab
    signal tabClicked(int index)

    height: vpx(269)

    // ── Colours ──────────────────────────────────────────────────────────
    readonly property color cAccent: theme.accent
    readonly property color cMid:    theme.accentMid
    readonly property color cDark:   theme.accentDark
    function mixc(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1); }
    function light(c, t)   { return mixc(c, Qt.rgba(1, 1, 1, 1), t); }
    readonly property color band: mixc(cDark, cMid, 0.45)

    // Points milestones: RA has none, so every 5,000 points is one.
    readonly property int pts: cheevosData.hardcorePoints
    readonly property int nextMilestone: (Math.floor(pts / 5000) + 1) * 5000

    Rectangle { anchors.fill: parent; color: header.band }

    // ── Profile, top left ────────────────────────────────────────────────
    Item {
    id: avatar
        x: vpx(69); y: vpx(23)
        width: vpx(48); height: width
        Rectangle { anchors.fill: parent; radius: width / 2; color: header.cDark }
        Image {
        id: avatarImg
            anchors.fill: parent
            source: cheevosData.avatarUrl
            visible: status === Image.Ready
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            sourceSize { width: hrpx(64); height: hrpx(64) }
            layer.enabled: true
            layer.smooth: true
            layer.effect: OpacityMask {
                maskSource: Rectangle { width: avatarImg.width; height: avatarImg.height; radius: width / 2 }
            }
        }
    }
    Column {
        anchors { left: avatar.right; leftMargin: vpx(12); verticalCenter: avatar.verticalCenter }
        spacing: vpx(1)
        Text {
            text: cheevosData.raUserName
            color: "#f2f2f2"
            font.family: bodyFont.name
            font.pixelSize: fpx(18)
        }
        Row {
            spacing: vpx(6)
            PointsGlyph { size: vpx(15); fill: "#c8c8c8"; textColor: header.band; anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: cheevosData.raFmt(header.pts)
                color: "#c8c8c8"
                font.family: bodyFont.name
                font.pixelSize: fpx(15)
            }
        }
    }

    // ── Tabs, centred ────────────────────────────────────────────────────
    Row {
    id: tabRow
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: vpx(21) }
        spacing: vpx(12)
        Repeater {
            model: header.tabs
            delegate: Item {
                readonly property bool on: index === header.current
                width: tabLabel.implicitWidth + vpx(24); height: vpx(32)
                // The selected tab glows softly, as on the console: two
                // translucent halos behind the pill (no blur pass).
                Rectangle {
                    anchors.fill: parent; anchors.margins: -vpx(6)
                    visible: parent.on
                    radius: vpx(9)
                    color: header.light(header.cAccent, 0.5); opacity: 0.16
                }
                Rectangle {
                    anchors.fill: parent; anchors.margins: -vpx(3)
                    visible: parent.on
                    radius: vpx(6)
                    color: header.light(header.cAccent, 0.55); opacity: 0.32
                }
                Rectangle {
                    anchors.fill: parent
                    visible: parent.on
                    radius: vpx(4)
                    color: header.light(header.cAccent, 0.62)
                    border.width: vpx(1); border.color: header.light(header.cAccent, 0.85)
                }
                Text {
                id: tabLabel
                    anchors.centerIn: parent
                    text: modelData
                    color: parent.on ? header.mixc(header.cAccent, Qt.rgba(0, 0, 0, 1), 0.7) : "#ececec"
                    font.family: parent.on ? titleFont.name : bodyFont.name
                    font.pixelSize: fpx(18)
                }
                TapHandler { onTapped: header.tabClicked(index) }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }
    }

    // Clock / battery / wifi: the shared cluster, always light on the band.
    StatusCluster { anchors.fill: parent; z: 50; dark: false }

    // ── Stats ────────────────────────────────────────────────────────────
    // 1. Points, with the next 5,000-point milestone and your rank.
    Image {
    id: statPoints
        x: parent.width * 0.068 - vpx(12); y: vpx(96)
        width: vpx(124); height: width
        sourceSize: Qt.size(hrpx(124), hrpx(124))
        smooth: true
        source: Emb.dataUrl(Emb.medallion(theme.accent, "m"))
    }
    Column {
        anchors { left: statPoints.right; leftMargin: vpx(6); verticalCenter: statPoints.verticalCenter }
        spacing: vpx(2)
        Text { text: "Total Points"; color: "#f5f5f5"; font.family: titleFont.name; font.pixelSize: fpx(17) }
        Row {
            spacing: vpx(6)
            PointsGlyph { size: vpx(18); fill: "#ececec"; textColor: header.band; anchors.verticalCenter: parent.verticalCenter }
            Text { text: cheevosData.raFmt(header.pts); color: "white"; font.family: bodyFont.name; font.pixelSize: fpx(28) }
        }
        Item {
            width: vpx(234); height: vpx(4)
            Rectangle { anchors.fill: parent; color: header.cDark }
            Rectangle { width: parent.width * ((header.pts % 5000) / 5000); height: parent.height; color: "#eeeeee" }
        }
        Text {
            topPadding: vpx(4)
            text: cheevosData.raFmt(header.nextMilestone - header.pts) + " until " + cheevosData.raFmt(header.nextMilestone)
                  + (cheevosData.userRank > 0 ? "  ·  Rank #" + cheevosData.raFmt(cheevosData.userRank) : "")
            color: "#d4ddd4"
            font.family: bodyFont.name
            font.pixelSize: fpx(13)
        }
    }

    // 2. Achievements unlocked, of everything in the games you've played.
    Image {
    id: statAch
        x: parent.width * 0.415 - vpx(18); y: vpx(102)
        width: vpx(120); height: width
        sourceSize: Qt.size(hrpx(120), hrpx(120))
        smooth: true
        source: Emb.dataUrl(Emb.hexgem(theme.accent, "h"))
    }
    Column {
        anchors { left: statAch.right; leftMargin: vpx(4); verticalCenter: statAch.verticalCenter }
        spacing: vpx(2)
        Text { text: "Total Achievements"; color: "#f5f5f5"; font.family: titleFont.name; font.pixelSize: fpx(17) }
        Text {
            text: cheevosData.libraryLoaded ? cheevosData.raFmt(cheevosData.totalAwarded) : "—"
            color: "white"; font.family: bodyFont.name; font.pixelSize: fpx(28)
        }
        Text {
            text: cheevosData.libraryLoaded ? "of " + cheevosData.raFmt(cheevosData.totalPossible) + " in games you've played" : ""
            color: "#d4ddd4"; font.family: bodyFont.name; font.pixelSize: fpx(13)
        }
    }

    // 3. Mythic games: 100% of a game, as on the Xbox. RA splits it into
    //    Mastered (hardcore) and Completed (softcore); both count here.
    Image {
    id: statMastery
        x: parent.width * 0.69 - vpx(12); y: vpx(93)
        width: vpx(150); height: width
        sourceSize: Qt.size(hrpx(150), hrpx(150))
        smooth: true
        source: Emb.dataUrl(Emb.mythic(theme.accent, "y"))
    }
    Column {
        anchors { left: statMastery.right; leftMargin: vpx(0); verticalCenter: statMastery.verticalCenter }
        spacing: vpx(2)
        Text { text: "Mythic Achievements"; color: "#f5f5f5"; font.family: titleFont.name; font.pixelSize: fpx(17) }
        Text {
            text: cheevosData.awardsLoaded ? cheevosData.raFmt(cheevosData.masteredCount + cheevosData.completedCount) : "—"
            color: "white"; font.family: bodyFont.name; font.pixelSize: fpx(28)
        }
        Text {
            text: cheevosData.awardsLoaded
                  ? cheevosData.raFmt(cheevosData.masteredCount) + " in hardcore  ·  " + cheevosData.raFmt(cheevosData.beatenCount) + " beaten"
                  : ""
            color: "#d4ddd4"; font.family: bodyFont.name; font.pixelSize: fpx(13)
        }
    }
}
