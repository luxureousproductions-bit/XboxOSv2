// XboxOSv2 – RAWelcomeTab.qml
// The Welcome tab of the RetroAchievements page, after the console's
// profile Welcome: your name and points, your username big, what you're
// playing and your motto, rank / following / followers / member since, a
// strip of your latest awards, your avatar in the middle, and a column of
// buttons on the right. It's what the RA page opens on from Home and the
// App Drawer (a game's own page still opens straight to its progress).
//
// The page is your accent, from bright to dark, under a dark top strip
// for the tabs. Icons: Fluent UI System Icons (assets/images/fluent, MIT).
//
// Keys: Left / Right between the awards strip and the buttons, Up / Down
// in the buttons, A does it.

import QtQuick 2.15
import QtGraphicalEffects 1.15
import "raEmblems.js" as Emb

FocusScope {
id: tab

    signal goTab(string name)

    property bool inButtons: false
    property int button: 0
    readonly property var buttons: [
        { label: "Recently played", icon: "history",         value: "" },
        { label: "Awards",          icon: "ribbon",          value: cheevosData.awardsLoaded ? cheevosData.raFmt(cheevosData.awardsList.length) : "" },
        { label: "Search games",    icon: "search",          value: "" },
        { label: "Refresh",         icon: "arrow_clockwise", value: "" },
        { label: "RA settings",     icon: "settings",        value: "" }
    ]
    // The six newest awards (awardsList is newest first).
    readonly property var latest: {
        var src = cheevosData.awardsList || [], out = [];
        for (var i = 0; i < src.length && out.length < 6; i++) {
            var a = src[i];
            if (a.AwardType !== "Mastery/Completion" && a.AwardType !== "Game Beaten") continue;
            out.push({ icon: a.ImageIcon || "", mythic: a.AwardType === "Mastery/Completion" });
        }
        return out;
    }

    readonly property color cAccent: theme.accent
    readonly property color cMid:    theme.accentMid
    readonly property color cDark:   theme.accentDark

    function press() {
        playAccept();
        if (!inButtons) { goTab("Awards"); return; }
        switch (button) {
        case 0: goTab("Gaming"); break;
        case 1: goTab("Awards"); break;
        case 2: openLibrarySearch("ra"); break;
        case 3: cheevosData.refreshAll(); break;
        case 4: settingsScreen(); break;
        }
    }
    function sinceText(d) {
        var ms = Date.parse((d || "").replace(" ", "T"));
        return isNaN(ms) ? "" : Qt.formatDate(new Date(ms), "MMM yyyy");
    }

    // ── The page: your accent, bright to dark ────────────────────────────
    LinearGradient {
        anchors.fill: parent
        start: Qt.point(0, 0)
        end: Qt.point(width, height * 0.6)
        gradient: Gradient {
            GradientStop { position: 0.0;  color: tab.cAccent }
            GradientStop { position: 0.35; color: tab.cMid }
            GradientStop { position: 1.0;  color: tab.cDark }
        }
    }
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: parent.height * 0.3
        gradient: Gradient {
            GradientStop { position: 0.0; color: mainA(0.0) }
            GradientStop { position: 1.0; color: theme.main }
        }
    }

    // ── You ──────────────────────────────────────────────────────────────
    Column {
    id: you
        x: parent.width * 0.073; y: parent.height * 0.27
        width: parent.width * 0.4
        spacing: vpx(2)
        Row {
            spacing: vpx(14)
            Text { text: cheevosData.raUserName; color: "white"; font.family: bodyFont.name; font.pixelSize: fpx(22) }
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: vpx(6)
                PointsGlyph { size: vpx(22); fill: "white"; textColor: tab.cMid; anchors.verticalCenter: parent.verticalCenter }
                Text { text: cheevosData.raFmt(cheevosData.hardcorePoints); color: "white"; font.family: bodyFont.name; font.pixelSize: fpx(21) }
            }
        }
        Text {
            width: parent.width; elide: Text.ElideRight
            text: cheevosData.raUserName
            color: "white"; font.family: titleFont.name; font.pixelSize: fpx(70)
        }
        Text {
            width: parent.width; elide: Text.ElideRight
            text: cheevosData.richPresence
            visible: text !== ""
            color: "#ededed"; font.family: bodyFont.name; font.pixelSize: fpx(17)
        }
        Text {
            width: parent.width; elide: Text.ElideRight
            text: cheevosData.motto !== "" ? "“" + cheevosData.motto + "”" : ""
            visible: text !== ""
            color: "#dcdcdc"; font.family: bodyFont.name; font.pixelSize: fpx(15); font.italic: true
        }
        Item { width: 1; height: vpx(16) }
        Row {
            spacing: vpx(36)
            Repeater {
                model: [
                    [cheevosData.userRank > 0 ? "#" + cheevosData.raFmt(cheevosData.userRank) : "—", "Rank"],
                    [cheevosData.followingTotal >= 0 ? cheevosData.raFmt(cheevosData.followingTotal) : "—", "Following"],
                    [cheevosData.followersTotal >= 0 ? cheevosData.raFmt(cheevosData.followersTotal) : "—", "Followers"],
                    [tab.sinceText(cheevosData.memberSince) || "—", "Member since"]
                ]
                delegate: Column {
                    Text { text: modelData[0]; color: "white"; font.family: bodyFont.name; font.pixelSize: fpx(28) }
                    Text { text: modelData[1]; color: "#e2e2e2"; font.family: bodyFont.name; font.pixelSize: fpx(16) }
                }
            }
        }
        Item { width: 1; height: vpx(18) }
        // Latest awards
        Rectangle {
        id: strip
            readonly property bool hot: !tab.inButtons && tab.activeFocus
            width: stripRow.width + vpx(32); height: vpx(92)
            radius: vpx(6)
            color: Qt.rgba(1, 1, 1, 0.08)
            RAFocus { on: strip.hot; radius: vpx(6) }
            Row {
            id: stripRow
                anchors.centerIn: parent
                spacing: vpx(14)
                Repeater {
                    model: tab.latest
                    delegate: Item {
                        width: vpx(64); height: width
                        Image {
                            anchors.fill: parent
                            source: modelData.icon ? "https://media.retroachievements.org" + modelData.icon : ""
                            sourceSize: Qt.size(hrpx(96), hrpx(96))
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true; smooth: true
                        }
                        Rectangle {
                            visible: modelData.mythic
                            anchors.fill: parent
                            color: "transparent"
                            border.width: vpx(2); border.color: Qt.lighter(tab.cAccent, 1.4)
                        }
                        Image {
                            visible: modelData.mythic
                            anchors { right: parent.right; top: parent.top; margins: -vpx(9) }
                            width: vpx(26); height: width
                            sourceSize: Qt.size(hrpx(52), hrpx(52))
                            source: modelData.mythic ? Emb.dataUrl(Emb.mythic(theme.accent, "s")) : ""
                        }
                    }
                }
                Text {
                    visible: tab.latest.length === 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: cheevosData.awardsLoaded ? "No awards yet" : "Loading your awards…"
                    color: "#e0e0e0"; font.family: bodyFont.name; font.pixelSize: fpx(15)
                }
            }
            TapHandler { onTapped: { tab.inButtons = false; tab.forceActiveFocus(); tab.press(); } }
        }
        Text {
            topPadding: vpx(6)
            text: "Latest awards"
            color: "#d8d8d8"; font.family: bodyFont.name; font.pixelSize: fpx(13)
        }
    }

    // ── Avatar ───────────────────────────────────────────────────────────
    Item {
    id: avatar
        width: vpx(220); height: width
        x: parent.width * 0.545 - width / 2; y: parent.height * 0.305
        Rectangle { anchors.fill: parent; anchors.margins: -vpx(4); radius: width / 2; color: Qt.rgba(1, 1, 1, 0.12) }
        Rectangle { anchors.fill: parent; radius: width / 2; color: "#0d0d0d" }
        Image {
        id: avatarImg
            anchors.fill: parent
            source: cheevosData.avatarUrl
            sourceSize: Qt.size(hrpx(256), hrpx(256))
            fillMode: Image.PreserveAspectCrop
            asynchronous: true; smooth: true
            visible: false
        }
        OpacityMask {
            anchors.fill: parent
            source: avatarImg
            visible: avatarImg.status === Image.Ready
            maskSource: Rectangle { width: avatar.width; height: avatar.height; radius: width / 2 }
        }
    }

    // ── Buttons ──────────────────────────────────────────────────────────
    Column {
        x: parent.width * 0.724; y: parent.height * 0.324
        width: parent.width * 0.208
        spacing: vpx(8)
        Repeater {
            model: tab.buttons
            delegate: Rectangle {
                readonly property bool hot: tab.inButtons && tab.button === index && tab.activeFocus
                width: parent.width; height: vpx(44)
                radius: vpx(3)
                color: Qt.rgba(0.16, 0.16, 0.18, 0.85)
                RAFocus { on: parent.hot }
                RAIcon {
                id: bIcon
                    anchors { left: parent.left; leftMargin: vpx(14); verticalCenter: parent.verticalCenter }
                    size: vpx(20)
                    layer.enabled: false            // always light: the buttons are dark on any background
                    source: "../assets/images/fluent/" + modelData.icon + ".svg"
                }
                Text {
                    anchors { left: bIcon.right; leftMargin: vpx(12); right: bValue.left; rightMargin: vpx(8); verticalCenter: parent.verticalCenter }
                    elide: Text.ElideRight
                    text: modelData.label
                    color: "white"; font.family: bodyFont.name; font.pixelSize: fpx(17)
                }
                Text {
                id: bValue
                    anchors { right: parent.right; rightMargin: vpx(14); verticalCenter: parent.verticalCenter }
                    text: modelData.value
                    color: "#d0d0d0"; font.family: bodyFont.name; font.pixelSize: fpx(16)
                }
                TapHandler { onTapped: { tab.inButtons = true; tab.button = index; tab.forceActiveFocus(); tab.press(); } }
            }
        }
    }

    // ── Keys ─────────────────────────────────────────────────────────────
    Keys.onUpPressed:    { event.accepted = true; if (inButtons && button > 0) { button--; playNav(); } }
    Keys.onDownPressed:  { event.accepted = true; if (inButtons && button < buttons.length - 1) { button++; playNav(); } }
    Keys.onLeftPressed:  { event.accepted = true; if (inButtons) { inButtons = false; playNav(); } }
    Keys.onRightPressed: { event.accepted = true; if (!inButtons) { inButtons = true; playNav(); } }
    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; press(); }
    }
    // Clickable prompts (the page's help bar).
    function helpAction(b) {
        if (b === "accept") { press(); return true; }
        return false;
    }
}
