// XboxOSv2 – RAHeader.qml
// The top of the RetroAchievements page, after the Xbox Series "Gaming" tab:
// a band in your accent's dark shades with your profile, the tabs and three
// stats (points, achievements, mastered games). Shared by the RA tabs.
//
// Colours: the band mixes Xbox's dark and mid shades of the accent
// (theme.accentDark / theme.accentMid), which is how the console's own
// header reads. Everything on it is light text: the band is always dark.
// The emblems are flat white SVGs (assets/images/ra) tinted with
// ColorOverlay; layers are static textures, redrawn only when the accent
// changes.

import QtQuick 2.15
import QtGraphicalEffects 1.15
import "../Global"

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
                Rectangle {
                    anchors.fill: parent
                    visible: parent.on
                    radius: vpx(4)
                    color: header.light(header.cAccent, 0.62)
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
    Item {
    id: statPoints
        x: parent.width * 0.068; y: vpx(108)
        width: vpx(100); height: width
        Rectangle { anchors.fill: parent; radius: width / 2; color: header.light(header.cAccent, 0.45) }
        Rectangle { anchors.centerIn: parent; width: parent.width * 0.82; height: width; radius: width / 2; color: header.cDark }
        Rectangle { anchors.centerIn: parent; width: parent.width * 0.54; height: width; radius: width / 2; color: header.cAccent }
        Text {
            anchors.centerIn: parent
            text: "P"
            color: header.light(header.cAccent, 0.7)
            font.family: titleFont.name
            font.pixelSize: fpx(30)
        }
    }
    Column {
        anchors { left: statPoints.right; leftMargin: vpx(18); verticalCenter: statPoints.verticalCenter }
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
    Item {
    id: statAch
        x: parent.width * 0.415; y: vpx(118)
        width: vpx(80); height: vpx(88)
        Image {
            anchors.fill: parent
            source: "../assets/images/ra/ra_hex.svg"
            sourceSize: Qt.size(hrpx(96), hrpx(106))
            smooth: true
            layer.enabled: true
            layer.effect: ColorOverlay { color: header.light(header.cAccent, 0.45) }
        }
        Image {
            anchors.centerIn: parent
            width: parent.width * 0.93; height: parent.height * 0.93
            source: "../assets/images/ra/ra_hex.svg"
            sourceSize: Qt.size(hrpx(96), hrpx(106))
            smooth: true
            layer.enabled: true
            layer.effect: ColorOverlay { color: header.cDark }
        }
        Image {
            anchors.centerIn: parent
            width: vpx(40); height: width
            source: "../assets/images/trophy_fill.svg"
            sourceSize: Qt.size(hrpx(48), hrpx(48))
            smooth: true
        }
    }
    Column {
        anchors { left: statAch.right; leftMargin: vpx(20); verticalCenter: statAch.verticalCenter }
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

    // 3. Mastered games: RA's 100% in hardcore, Xbox's Mythic.
    Item {
    id: statMastery
        x: parent.width * 0.69; y: vpx(106)
        width: vpx(124); height: width
        Image {
            anchors.fill: parent
            source: "../assets/images/ra/ra_star.svg"
            sourceSize: Qt.size(hrpx(128), hrpx(128))
            smooth: true
            layer.enabled: true
            layer.effect: ColorOverlay { color: header.light(header.cAccent, 0.55) }
        }
        Image {
            anchors.centerIn: parent
            width: parent.width * 0.54; height: width
            source: "../assets/images/ra/ra_star.svg"
            sourceSize: Qt.size(hrpx(72), hrpx(72))
            smooth: true
            layer.enabled: true
            layer.effect: ColorOverlay { color: header.cDark }
        }
        Image {
            anchors.centerIn: parent
            width: parent.width * 0.26; height: width
            source: "../assets/images/ra/ra_star.svg"
            sourceSize: Qt.size(hrpx(40), hrpx(40))
            smooth: true
            layer.enabled: true
            layer.effect: ColorOverlay { color: header.light(header.cAccent, 0.75) }
        }
    }
    Column {
        anchors { left: statMastery.right; leftMargin: vpx(14); verticalCenter: statMastery.verticalCenter }
        spacing: vpx(2)
        Text { text: "Mastered Games"; color: "#f5f5f5"; font.family: titleFont.name; font.pixelSize: fpx(17) }
        Text {
            text: cheevosData.awardsLoaded ? cheevosData.raFmt(cheevosData.masteredCount) : "—"
            color: "white"; font.family: bodyFont.name; font.pixelSize: fpx(28)
        }
        Text {
            text: cheevosData.awardsLoaded
                  ? cheevosData.raFmt(cheevosData.beatenCount) + " beaten  ·  " + cheevosData.raFmt(cheevosData.completedCount) + " completed"
                  : ""
            color: "#d4ddd4"; font.family: bodyFont.name; font.pixelSize: fpx(13)
        }
    }
}
