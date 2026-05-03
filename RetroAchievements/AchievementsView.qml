// XboxOSv2 – RetroAchievements browser
// Shows the user's recently-played games with per-game achievement progress.
// Selecting a game drills down to GameAchievementsView.
// Layout matches the retromega-sleipnir style with the XboxOSv2 colour scheme:
//   header: avatar + name + points (left)
//   rows: [full-height icon] [title / platform · Played N ago] [N of M right]

import QtQuick 2.0
import "../Global"

FocusScope {
id: root

    anchors.fill: parent

    property bool initialized: false

    // Returns a relative "Played X ago" string from an ISO-8601 LastPlayed string.
    function lastPlayedText(lastPlayed) {
        var ms = Date.parse(lastPlayed);
        if (isNaN(ms)) return "";
        var s = Math.floor((Date.now() - ms) / 1000);
        if (s < 120)  return "Played just now";
        var m = Math.floor(s / 60);
        if (m < 60)   return "Played " + m + " min ago";
        var h = Math.floor(m / 60);
        if (h < 24)   return h === 1 ? "Played 1 hr ago" : "Played " + h + " hrs ago";
        var d = Math.floor(h / 24);
        if (d === 1)  return "Played yesterday";
        if (d < 365)  return "Played " + d + " days ago";
        return Qt.formatDate(new Date(ms), "MMM d, yyyy");
    }

    // ── Lifecycle ────────────────────────────────────────────────────────
    onActiveFocusChanged: {
        if (activeFocus) {
            currentHelpbarModel = null;   // hide global bar; we draw our own bottom-left bar
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
    // Left: RA logo → avatar → username + points
    Item {
    id: achievementsHeader

        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(72)

        Row {
        id: headerRow

            anchors {
                left: parent.left; leftMargin: globalMargin
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(12)

            // RetroAchievements logo
            Image {
                width: vpx(52); height: vpx(52)
                source: "../assets/images/icon_ra.svg"
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
            }

            // User avatar (hidden until logged in)
            Image {
                width: vpx(48); height: vpx(48)
                source: cheevosData.avatarUrl
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                visible: cheevosData.avatarUrl !== ""
            }

            // Username + points
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: vpx(2)
                visible: cheevosData.raUserName !== ""

                Text {
                    text: cheevosData.raUserName
                    color: theme.text
                    font.family: titleFont.name
                    font.pixelSize: vpx(20)
                    font.bold: true
                }
                Text {
                    text: cheevosData.pointsText
                    color: theme.text
                    font.family: bodyFont.name
                    font.pixelSize: vpx(13)
                    opacity: 0.65
                    visible: cheevosData.pointsText !== ""
                }
            }
        }

        // Divider
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
                + "Get your API key at: https://retroachievements.org/settings"
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
        focus: visible

        anchors {
            top:    achievementsHeader.bottom; topMargin:    vpx(4)
            bottom: parent.bottom;            bottomMargin: vpx(50)
            left:   parent.left
            right:  parent.right
        }

        model: cheevosData.raRecentGames
        clip: true

        highlightMoveDuration: 100
        preferredHighlightBegin: vpx(90)
        preferredHighlightEnd:   height - vpx(90)
        highlightRangeMode: ListView.ApplyRange

        // Full-opacity accent highlight – matches the sleipnir solid row style
        highlight: Rectangle {
            color:   theme.accent
            opacity: 0.55
            radius:  vpx(0)
            width:   gameList.width
        }

        // Status / empty message
        Text {
            anchors.centerIn: parent
            visible: cheevosData.raRecentGames.count === 0
            text:    cheevosData.statusText || "No recently played games found"
            color:   theme.text
            font.family: bodyFont.name
            font.pixelSize: vpx(18)
            opacity: 0.5
        }

        delegate: Item {
        id: gameRow

            width:  gameList.width
            height: vpx(90)

            property bool isSelected: ListView.isCurrentItem && gameList.focus

            // ── Row inner layout (Item+anchors so icon fills full height) ─
            Item {
                anchors {
                    fill:        parent
                    leftMargin:  vpx(0)
                    rightMargin: vpx(globalMargin)
                }

                // Game icon – fills full row height (square, left edge)
                Item {
                id: gameIcon

                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: height // square

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

                // Achievement count – right edge, vertically centered
                Column {
                id: countCol

                    anchors {
                        right: parent.right; rightMargin: vpx(0)
                        verticalCenter: parent.verticalCenter
                    }
                    width: vpx(110)

                    Text {
                        text: NumPossibleAchievements > 0
                              ? NumAchieved + " of " + NumPossibleAchievements
                              : "No cheevos"
                        color: theme.text
                        font.family:    titleFont.name
                        font.pixelSize: vpx(17)
                        font.bold:      true
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        opacity: isSelected ? 1.0 : 0.75
                    }
                }

                // Title + platform + "Played N ago"
                Column {
                    anchors {
                        left:  gameIcon.right;  leftMargin:  vpx(14)
                        right: countCol.left;   rightMargin: vpx(10)
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: vpx(6)

                    Text {
                        text: Title
                        color: theme.text
                        font.family:    titleFont.name
                        font.pixelSize: vpx(18)
                        font.bold:      true
                        elide: Text.ElideRight
                        width: parent.width
                        opacity: isSelected ? 1.0 : 0.9
                    }

                    // Platform + last-played on the same line
                    Item {
                        width:  parent.width
                        height: platformText.implicitHeight

                        Text {
                        id: platformText

                            text: ConsoleName
                            color: theme.text
                            font.family:    subtitleFont.name
                            font.pixelSize: vpx(13)
                            font.bold:      true
                            opacity: isSelected ? 0.9 : 0.55
                            elide: Text.ElideRight
                            width: parent.width * 0.5
                        }

                        Text {
                            anchors.right: parent.right
                            text: root.lastPlayedText(LastPlayed)
                            color: theme.text
                            font.family:    bodyFont.name
                            font.pixelSize: vpx(13)
                            opacity: isSelected ? 0.75 : 0.4
                            elide: Text.ElideRight
                            width: parent.width * 0.5
                            horizontalAlignment: Text.AlignRight
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

            // Mouse / touch
            MouseArea {
                anchors.fill: parent
                hoverEnabled: settings.MouseHover === "Yes"
                onEntered: { sfxNav.play(); gameList.currentIndex = index; }
                onClicked: {
                    if (isSelected) openSelectedGame();
                    else { sfxNav.play(); gameList.currentIndex = index; }
                }
            }
        }
    }

    // ── Page counter (bottom-right, above help bar) ───────────────────────
    Text {
        visible: cheevosData.raUserName !== "" && cheevosData.raRecentGames.count > 0
        anchors {
            right:  parent.right; rightMargin: globalMargin
            bottom: parent.bottom; bottomMargin: vpx(10)
        }
        text: (gameList.currentIndex + 1) + " of " + cheevosData.raRecentGames.count
        color: theme.text
        font.family: bodyFont.name
        font.pixelSize: vpx(16)
        font.bold: true
        opacity: 0.75
    }

    // ── Local help bar (bottom-left) ─────────────────────────────────────
    // Drawn directly so it appears on the LEFT, unlike the global bar (right-aligned).
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
                    width: vpx(30); height: vpx(30)
                    asynchronous: true
                }
                Text {
                    text: name
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(16)
                    color: theme.text
                    height: vpx(30)
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    ListModel {
    id: localHelpModel
        ListElement { name: "Details"; button: "accept"  }
        ListElement { name: "Back";    button: "cancel"  }
        ListElement { name: "Refresh"; button: "filters" }
    }

    // ── Navigation helpers ───────────────────────────────────────────────

    function openSelectedGame() {
        if (cheevosData.raRecentGames.count === 0) return;
        var gameID = cheevosData.raRecentGames.get(gameList.currentIndex).GameID;
        cheevosData.loadGameAchievements(gameID);
        gameAchievementsScreen();
    }

    // ── Key handling ─────────────────────────────────────────────────────

    Keys.onUpPressed: {
        event.accepted = true;
        sfxNav.play();
        if (gameList.currentIndex > 0) gameList.currentIndex--;
    }
    Keys.onDownPressed: {
        event.accepted = true;
        sfxNav.play();
        if (gameList.currentIndex < cheevosData.raRecentGames.count - 1) gameList.currentIndex++;
    }
    Keys.onPressed: {
        // Accept → drill into game
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            sfxAccept.play();
            openSelectedGame();
        }
        // Cancel → back
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            previousScreen();
        }
        // Filters → refresh
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            initialized = false;
            cheevosData.refreshAll();
        }
    }

    // ── Help bar ─────────────────────────────────────────────────────────
    // (local left-aligned bar is drawn above; no global model needed)
}
