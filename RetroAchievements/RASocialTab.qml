// XboxOSv2 – RASocialTab.qml
// The Social tab of the RetroAchievements page: a points leaderboard of
// people. On the band, your rank among the people you follow, who's next
// above you and how far, and your site rank. Below, a rail (Following,
// Followers, Top 10 worldwide) and the ranked list; your own row is in the
// accent and is always in the Following and Followers lists.
//
// Data: cheevosData.followingList / followersList / topTenList
// (CheevosData.loadSocial). Points are hardcore points, as RA ranks them.
// Icons: Fluent UI System Icons (assets/images/fluent, MIT).
//
// Keys: as the Awards tab: Left from the list reaches the rail, where
// Up / Down switch lists straight away, Right goes back.

import QtQuick 2.15
import "../Global"

FocusScope {
id: tab

    property real bandHeight: vpx(269)         // the header band above the rail
    readonly property var railNames: ["Following", "Followers", "Top 10 worldwide"]
    property int railIndex: 0
    property bool railFocus: false

    readonly property string me: cheevosData.raUserName
    function withMe(list) {
        var out = list.slice(0), have = false;
        for (var i = 0; i < out.length; i++) if (out[i].user.toLowerCase() === me.toLowerCase()) have = true;
        if (!have && me !== "") out.push({ user: me, points: cheevosData.hardcorePoints, softcore: cheevosData.softcorePoints, mutual: false, self: true });
        out.sort(function(a, b) { return b.points - a.points; });
        return out;
    }
    readonly property var following: withMe(cheevosData.followingList)
    readonly property var rows: railIndex === 0 ? following
                              : railIndex === 1 ? withMe(cheevosData.followersList)
                              : cheevosData.topTenList
    function isMe(u) { return (u || "").toLowerCase() === me.toLowerCase(); }
    readonly property int myRank: { for (var i = 0; i < following.length; i++) if (isMe(following[i].user)) return i + 1; return 0; }
    readonly property var nextUp: myRank > 1 ? following[myRank - 2] : null

    readonly property color cardColor: whiteBackground ? "#ffffff" : "#2e2e2e"
    readonly property color railSel:   whiteBackground ? "#ffffff" : "#2b2b2b"
    readonly property color cAccent:   theme.accent
    readonly property color mineColor: Qt.rgba(cAccent.r, cAccent.g, cAccent.b, whiteBackground ? 0.16 : 0.24)
    readonly property bool  accentIsLight: (0.299 * cAccent.r + 0.587 * cAccent.g + 0.114 * cAccent.b) > 0.62
    function mixc(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1); }

    onRailIndexChanged: list.currentIndex = 0
    onActiveFocusChanged: if (activeFocus) list.forceActiveFocus()

    // ── On the band: three figures ───────────────────────────────────────
    Row {
        x: vpx(73); y: vpx(100)
        spacing: vpx(70)
        Repeater {
            model: [
                { icon: "people_community", title: "Your rank among people you follow",
                  value: tab.myRank > 0 ? "#" + tab.myRank + " of " + tab.following.length : "—" },
                { icon: "arrow_trending", title: "Next up",
                  value: tab.nextUp ? tab.nextUp.user + "  ·  " + cheevosData.raFmt(tab.nextUp.points - cheevosData.hardcorePoints) + " ahead"
                                    : (tab.myRank === 1 && tab.following.length > 1 ? "You're on top" : "—") },
                { icon: "trophy", title: "Site rank",
                  value: cheevosData.userRank > 0 ? "#" + cheevosData.raFmt(cheevosData.userRank) : "—" }
            ]
            delegate: Row {
                spacing: vpx(12)
                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    width: vpx(56); height: width
                    source: "../assets/images/fluent/" + modelData.icon + ".svg"
                    sourceSize: Qt.size(hrpx(112), hrpx(112))
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: modelData.title; color: "#f5f5f5"; font.family: titleFont.name; font.pixelSize: fpx(16) }
                    Text { text: modelData.value; color: "white"; font.family: bodyFont.name; font.pixelSize: index === 1 ? fpx(20) : fpx(32) }
                }
            }
        }
    }

    // ── Rail ─────────────────────────────────────────────────────────────
    Item {
    id: rail
        anchors { left: parent.left; top: parent.top; topMargin: tab.bandHeight; bottom: parent.bottom }
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
                        font.family: bodyFont.name; font.pixelSize: fpx(17)
                    }
                    TapHandler { onTapped: { tab.railIndex = index; playNav(); } }
                }
            }
        }
    }
    Rectangle {
        anchors { left: rail.right; top: rail.top; bottom: parent.bottom }
        width: vpx(1); color: theme.text; opacity: 0.12
    }

    // ── The list ─────────────────────────────────────────────────────────
    ListView {
    id: list
        anchors { left: rail.right; leftMargin: vpx(31); right: parent.right; rightMargin: vpx(53); top: rail.top; topMargin: vpx(10); bottom: parent.bottom; bottomMargin: helpMargin }
        leftMargin: vpx(14); rightMargin: vpx(14); topMargin: vpx(14); bottomMargin: vpx(14)
        clip: true
        focus: !tab.railFocus
        model: tab.rows
        spacing: vpx(8)
        keyNavigationEnabled: false
        highlightMoveDuration: 120
        preferredHighlightBegin: vpx(14)
        preferredHighlightEnd: height - vpx(14)
        highlightRangeMode: ListView.ApplyRange
        property bool navReady: false
        Component.onCompleted: navReady = true
        onCurrentIndexChanged: if (navReady && tab.activeFocus && !tab.railFocus) playNav()

        Text {
            anchors { top: parent.top; topMargin: vpx(100); horizontalCenter: parent.horizontalCenter }
            // Your own row is always there: "empty" is just you.
            visible: tab.rows.length === 0 || (tab.railIndex < 2 && tab.rows.length === 1)
            text: tab.railIndex === 2 ? "Loading…"
                  : tab.railIndex === 0 ? (cheevosData.followingTotal < 0 ? "Loading…" : "You don't follow anyone yet: follow players on retroachievements.org")
                  : (cheevosData.followersTotal < 0 ? "Loading…" : "No followers yet")
            color: theme.text; opacity: 0.55
            font.family: bodyFont.name; font.pixelSize: fpx(16)
        }

        delegate: Rectangle {
        id: row
            readonly property bool mine: tab.isMe(modelData.user)
            readonly property bool hot: ListView.isCurrentItem && !tab.railFocus && tab.activeFocus
            width: list.width - list.leftMargin - list.rightMargin
            height: vpx(64)
            radius: vpx(4)
            color: mine ? tab.mixc(tab.cardColor, tab.cAccent, whiteBackground ? 0.14 : 0.22) : tab.cardColor
            RAFocus { on: row.hot }
            Rectangle {
                visible: row.mine
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: vpx(4); radius: vpx(2); color: theme.accent
            }
            Text {
            id: rankText
                anchors { left: parent.left; leftMargin: vpx(20); verticalCenter: parent.verticalCenter }
                width: vpx(52)
                text: "#" + (index + 1)
                color: index < 3 ? Qt.lighter(tab.cAccent, whiteBackground ? 1.0 : 1.5) : theme.text
                font.family: titleFont.name; font.pixelSize: fpx(26)
            }
            Image {
            id: av
                anchors { left: rankText.right; leftMargin: vpx(8); verticalCenter: parent.verticalCenter }
                width: vpx(42); height: width
                source: modelData.user ? "https://media.retroachievements.org/UserPic/" + modelData.user + ".png" : ""
                sourceSize: Qt.size(hrpx(84), hrpx(84))
                fillMode: Image.PreserveAspectCrop
                asynchronous: true; smooth: true
            }
            Column {
                anchors { left: av.right; leftMargin: vpx(14); right: ptsCol.left; rightMargin: vpx(12); verticalCenter: parent.verticalCenter }
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: modelData.user + (row.mine ? " (you)" : "")
                    color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(18)
                }
                Text {
                    visible: text !== ""
                    text: row.mine ? "" : tab.railIndex === 0 ? (modelData.mutual ? "Follows you" : "You follow")
                                        : tab.railIndex === 1 ? (modelData.mutual ? "You follow each other" : "Follows you") : ""
                    color: theme.text; opacity: 0.6; font.family: bodyFont.name; font.pixelSize: fpx(13)
                }
            }
            Column {
            id: ptsCol
                anchors { right: parent.right; rightMargin: vpx(20); verticalCenter: parent.verticalCenter }
                Row {
                    anchors.right: parent.right
                    spacing: vpx(6)
                    PointsGlyph { size: vpx(16); fill: whiteBackground ? "#303030" : "#e6e6e6"; textColor: row.color; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: cheevosData.raFmt(modelData.points); color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(20) }
                }
                Text {
                    anchors.right: parent.right
                    text: tab.railIndex === 2 ? cheevosData.raFmt(modelData.retro) + " RetroPoints"
                                              : (modelData.softcore > 0 ? cheevosData.raFmt(modelData.softcore) + " softcore" : "")
                    visible: text !== ""
                    color: theme.text; opacity: 0.6; font.family: bodyFont.name; font.pixelSize: fpx(12)
                }
            }
            TapHandler { onTapped: { tab.railFocus = false; list.currentIndex = index; tab.forceActiveFocus(); } }
        }
    }
    WheelNav {
        anchors.fill: list
        view: list
        columns: 1
        active: tab.visible && !searchOpen
        onStepped: function(quiet) { if (!quiet) playNav(); }
    }

    // ── Keys ─────────────────────────────────────────────────────────────
    Keys.onUpPressed: {
        event.accepted = true;
        if (railFocus) { if (railIndex > 0) { railIndex--; playNav(); } }
        else if (list.currentIndex > 0) list.currentIndex--;
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (railFocus) { if (railIndex < railNames.length - 1) { railIndex++; playNav(); } }
        else if (list.currentIndex < rows.length - 1) list.currentIndex++;
    }
    Keys.onLeftPressed:  { event.accepted = true; if (!railFocus) { railFocus = true; playNav(); } }
    Keys.onRightPressed: { event.accepted = true; if (railFocus && rows.length > 0) { railFocus = false; playNav(); } }
    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (railFocus && rows.length > 0) { railFocus = false; playNav(); }
        }
    }
}
