// XboxOSv2 – AchievementsView.qml
// Recently-played games with per-game achievement progress.
// Selecting a game drills down to GameAchievementsView.
//
// Enhancements over v1:
//   • Progress bar on every game row (visual fill, not just "N of M" text)
//   • Completion % badge on the right side of each row
//   • Extended profile header: rank + member-since + true points
//   • Shared RAStatusBar (no duplicate clock/battery timers)
//   • cacheBuffer on ListView for smoother Android scrolling
//   • sourceSize on all network images

import QtQuick 2.15
import "../Global"

FocusScope {
id: root

    anchors.fill: parent

    property bool initialized: false

    // ── Relative time helpers ─────────────────────────────────────────────
    function lastPlayedText(lastPlayed) {
        var ms = Date.parse(lastPlayed);
        if (isNaN(ms)) return "";
        var s = Math.floor((Date.now() - ms) / 1000);
        if (s < 120)  return "Just now";
        var m = Math.floor(s / 60);
        if (m < 60)   return m + " min ago";
        var h = Math.floor(m / 60);
        if (h < 24)   return h === 1 ? "1 hr ago" : h + " hrs ago";
        var d = Math.floor(h / 24);
        if (d === 1)  return "Yesterday";
        if (d < 365)  return d + " days ago";
        return Qt.formatDate(new Date(ms), "MMM d, yyyy");
    }

    // ── Lifecycle ────────────────────────────────────────────────────────
    onActiveFocusChanged: {
        if (activeFocus) {
            currentHelpbarModel = null;
            cheevosData.reload();
            if (!initialized && cheevosData.raUserName !== "") {
                initialized = true;
                cheevosData.loadUserProfile();
                cheevosData.loadRecentGames();
            }
        }
    }

    // ── Background ───────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: theme.main
    }

    // ── Header ───────────────────────────────────────────────────────────
    Item {
    id: achievementsHeader

        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(110)

        // RA logo
        Image {
        id: raLogo
            anchors {
                left: parent.left; leftMargin: vpx(5)
                top: parent.top; bottom: parent.bottom
                topMargin: vpx(4); bottomMargin: vpx(4)
            }
            width: height
            source: "../assets/images/icon_ra.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            sourceSize { width: 96; height: 96 }
        }

        // Avatar + username + points + rank + member since
        Row {
            anchors {
                left: raLogo.right; leftMargin: vpx(12)
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(12)

            Image {
                width: vpx(56); height: vpx(56)
                source: cheevosData.avatarUrl
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                sourceSize { width: 64; height: 64 }
                visible: cheevosData.avatarUrl !== ""
                // Clip to circle
                layer.enabled: true
                layer.effect: null
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: theme.accent
                    border.width: vpx(2)
                    radius: width / 2
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: vpx(2)
                visible: cheevosData.raUserName !== ""

                Text {
                    text: cheevosData.raUserName
                    color: theme.text
                    font.family: titleFont.name
                    font.pixelSize: vpx(24)
                    font.bold: true
                }
                Text {
                    text: cheevosData.pointsText
                    color: theme.text
                    font.family: bodyFont.name
                    font.pixelSize: vpx(15)
                    opacity: 0.65
                    visible: cheevosData.raUserName !== ""
                }
                Text {
                    text: cheevosData.memberText
                    color: theme.text
                    font.family: bodyFont.name
                    font.pixelSize: vpx(13)
                    opacity: 0.45
                    visible: cheevosData.memberText !== ""
                }
            }
        }

        // Shared status bar — clock + battery (no duplicate timers)
        RAStatusBar {
            anchors {
                right: parent.right; rightMargin: vpx(10)
                verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: vpx(1)
            color: theme.text
            opacity: 0.1
        }
    }

    // ── No-credentials placeholder ───────────────────────────────────────
    Item {
        anchors {
            top: achievementsHeader.bottom; bottom: parent.bottom
            left: parent.left; right: parent.right
        }
        visible: cheevosData.raUserName === ""

        Text {
            anchors.centerIn: parent
            text: "Retro Achievements not configured.\n\n"
                + "Go to  Settings → Retro Achievements\n"
                + "and enter your RA username and API key.\n\n"
                + "Get your API key at: retroachievements.org/settings"
            color: theme.text
            font.family: bodyFont.name
            font.pixelSize: vpx(18)
            opacity: 0.5
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }

    // ── Recently-played game list ────────────────────────────────────────
    ListView {
    id: gameList

        visible: cheevosData.raUserName !== ""
        focus:   visible

        anchors {
            top:    achievementsHeader.bottom; topMargin:    vpx(4)
            bottom: parent.bottom;            bottomMargin: vpx(56)
            left:   parent.left
            right:  parent.right
        }

        model:       cheevosData.raRecentGames
        currentIndex: 0
        clip:         true
        cacheBuffer:  vpx(300)   // pre-render ~3 off-screen rows for smooth Android scrolling

        // Nav sound fires on ANY index change (keyboard up/down, mouse hover/click).
        // The focused ListView consumes Up/Down internally, so the root Keys handlers
        // never see them — hooking the index change is the reliable place for the sound.
        property bool navReady: false
        Component.onCompleted: navReady = true
        onCurrentIndexChanged: if (navReady) sfxNav.play()

        highlightMoveDuration: 100
        preferredHighlightBegin: vpx(96)
        preferredHighlightEnd:   height - vpx(96)
        highlightRangeMode: ListView.ApplyRange

        highlight: Rectangle {
            color:   theme.accent
            opacity: 0.45
            width:   gameList.width
        }

        // Empty / loading state
        Text {
            anchors.centerIn: parent
            visible: cheevosData.raRecentGames.count === 0
            text:    cheevosData.statusText || "No recently played games"
            color:   theme.text
            font.family: bodyFont.name
            font.pixelSize: vpx(18)
            opacity: 0.5
        }

        delegate: Item {
        id: gameRow

            width:  gameList.width
            height: vpx(100)

            property bool isSelected: ListView.isCurrentItem && gameList.focus

            // ── Row inner layout ─────────────────────────────────────────
            Item {
                anchors {
                    fill:        parent
                    rightMargin: vpx(globalMargin)
                }

                // Game icon — square, left edge, full row height
                Item {
                id: gameIcon
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: height

                    Rectangle {
                        anchors.fill: parent
                        color:   theme.secondary
                        opacity: 0.4
                    }
                    Image {
                        anchors.fill: parent
                        source: ImageIcon
                                ? "https://media.retroachievements.org" + ImageIcon
                                : ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                        sourceSize { width: 96; height: 96 }
                    }
                }

                // Completion % badge — right edge
                Column {
                id: countCol
                    anchors {
                        right: parent.right; rightMargin: vpx(0)
                        verticalCenter: parent.verticalCenter
                    }
                    width: vpx(90)
                    spacing: vpx(2)

                    // Large % number
                    Text {
                        property int pct: NumPossibleAchievements > 0
                                          ? Math.floor(NumAchieved * 100 / NumPossibleAchievements)
                                          : 0
                        text: NumPossibleAchievements > 0 ? pct + "%" : "—"
                        color: {
                            if (NumPossibleAchievements === 0) return theme.text;
                            var p = Math.floor(NumAchieved * 100 / NumPossibleAchievements);
                            if (p >= 100) return "#FFD700";   // gold — mastered
                            if (p >= 50)  return theme.accent; // accent — decent progress
                            return theme.text;
                        }
                        font.family:    titleFont.name
                        font.pixelSize: vpx(26)
                        font.bold:      true
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        opacity: isSelected ? 1.0 : 0.8
                    }

                    // "N of M" sub-label
                    Text {
                        text: NumPossibleAchievements > 0
                              ? NumAchieved + " of " + NumPossibleAchievements
                              : "No cheevos"
                        color: theme.text
                        font.family:    bodyFont.name
                        font.pixelSize: vpx(13)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        opacity: isSelected ? 0.75 : 0.45
                    }
                }

                // Title + platform + last-played + progress bar
                Column {
                    anchors {
                        left:  gameIcon.right; leftMargin:  vpx(14)
                        right: countCol.left;  rightMargin: vpx(10)
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: vpx(5)

                    Text {
                        text: Title
                        color: theme.text
                        font.family:    titleFont.name
                        font.pixelSize: vpx(21)
                        font.bold:      true
                        elide: Text.ElideRight
                        width: parent.width
                        opacity: isSelected ? 1.0 : 0.9
                    }

                    // Platform · Last played (same line)
                    Item {
                        width:  parent.width
                        height: platformLbl.implicitHeight

                        Text {
                        id: platformLbl
                            text: ConsoleName
                            color: theme.text
                            font.family:    subtitleFont.name
                            font.pixelSize: vpx(15)
                            font.bold:      true
                            opacity: isSelected ? 0.9 : 0.55
                            elide: Text.ElideRight
                            width: parent.width * 0.55
                        }

                        Text {
                            anchors.right: parent.right
                            text: root.lastPlayedText(LastPlayed)
                            color: theme.text
                            font.family:    bodyFont.name
                            font.pixelSize: vpx(14)
                            opacity: isSelected ? 0.75 : 0.4
                            elide: Text.ElideRight
                            width: parent.width * 0.45
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    // Progress bar
                    Item {
                        width:  parent.width
                        height: vpx(5)
                        visible: NumPossibleAchievements > 0

                        Rectangle {
                            anchors.fill: parent
                            color:        theme.text
                            opacity:      0.15
                            radius:       vpx(2)
                        }
                        Rectangle {
                            width: {
                                var p = Progress || 0;  // pre-computed 0.0–1.0
                                return parent.width * p;
                            }
                            height: parent.height
                            color: {
                                var p = Progress || 0;
                                if (p >= 1.0) return "#FFD700";   // mastered — gold
                                if (p >= 0.5) return theme.accent;
                                return theme.accent;
                            }
                            radius: vpx(2)
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // Row divider
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height:  vpx(1)
                color:   theme.text
                opacity: 0.08
            }

            // Touch
            MouseArea {
                anchors.fill: parent
                hoverEnabled: settings.MouseHover === "Yes"
                onEntered: { gameList.currentIndex = index; }
                onClicked: {
                    if (isSelected) openSelectedGame();
                    else { gameList.currentIndex = index; }
                }
            }
        }
    }

    // ── Page counter ─────────────────────────────────────────────────────
    Text {
        visible: cheevosData.raUserName !== "" && cheevosData.raRecentGames.count > 0
        anchors {
            right:  parent.right; rightMargin: globalMargin
            bottom: parent.bottom; bottomMargin: vpx(10)
        }
        text: (gameList.currentIndex + 1) + " of " + cheevosData.raRecentGames.count
        color: theme.text
        font.family: bodyFont.name
        font.pixelSize: vpx(20)
        font.bold: true
        opacity: 0.75
    }

    // ── Local help bar (bottom-left) ─────────────────────────────────────
    Row {
        anchors {
            left: parent.left; leftMargin: globalMargin
            bottom: parent.bottom; bottomMargin: vpx(10)
        }
        spacing: vpx(20)

        Repeater {
            model: localHelpModel
            delegate: Row {
                spacing: vpx(8)
                Image {
                    source: "../assets/images/controller/"
                            + buttonbar.processButtonArt(button) + ".png"
                    width: vpx(32); height: vpx(32)
                    asynchronous: true
                    sourceSize { width: 48; height: 48 }
                }
                Text {
                    text: name
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(20)
                    color: theme.text
                    height: vpx(32)
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    ListModel {
    id: localHelpModel
        ListElement { name: "Details"; button: "accept"  }
        ListElement { name: "Refresh"; button: "details" }
        ListElement { name: "Back";    button: "cancel"  }
    }

    // ── Navigation helpers ───────────────────────────────────────────────
    function openSelectedGame() {
        if (cheevosData.raRecentGames.count === 0) return;
        var gameID = cheevosData.raRecentGames.get(gameList.currentIndex).GameID;
        cheevosData.loadGameAchievements(gameID);
        gameAchievementsScreenFromOverview();
    }

    // ── Key handling ─────────────────────────────────────────────────────
    Keys.onUpPressed: {
        event.accepted = true;
        if (gameList.currentIndex > 0) gameList.currentIndex--;
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (gameList.currentIndex < cheevosData.raRecentGames.count - 1)
            gameList.currentIndex++;
    }
    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            sfxAccept.play();
            openSelectedGame();
        }
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            previousScreen();
        }
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            sfxAccept.play();
            initialized = false;
            cheevosData.refreshAll();
        }
    }
}
