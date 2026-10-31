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
    // "stats": the band with the three emblems (Gaming, Awards)
    // "band":  the band alone; the tab draws its own figures on it (Social)
    // "compact": just the tabs over the page (Welcome draws its own page)
    property string mode: "stats"
    signal tabClicked(int index)

    height: mode === "compact" ? vpx(80) : vpx(269)

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

    Rectangle { anchors.fill: parent; color: header.mode === "compact" ? Qt.rgba(0, 0, 0, 0.25) : header.band }

    // ── Profile, top left ────────────────────────────────────────────────
    Item {
    id: avatar
        visible: header.mode !== "compact"   // Welcome shows you big instead
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
        visible: avatar.visible
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

    // ── Tabs, centred (RATabBar: the accent line under the selected one) ──
    RATabBar {
    id: tabRow
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: vpx(22) }
        tabs: header.tabs
        current: header.current
        onTabClicked: header.tabClicked(index)
    }

    // Clock / battery / wifi: the shared cluster, always light on the band.
    StatusCluster { anchors.fill: parent; z: 50; dark: false }

    // ── Stats ── (only in "stats" mode)
    Item {
        anchors.fill: parent
        visible: header.mode === "stats"

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
}
