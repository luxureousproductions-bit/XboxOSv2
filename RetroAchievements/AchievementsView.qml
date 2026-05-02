// XboxOSv2 – RetroAchievements browser
// Shows the user's recently-played games with per-game achievement progress.
// Selecting a game drills down to GameAchievementsView.

import QtQuick 2.0
import QtQuick.Layouts 1.11
import "../Global"

FocusScope {
id: root

    anchors.fill: parent

    property bool initialized: false

    // ── Lifecycle ────────────────────────────────────────────────────────
    onActiveFocusChanged: {
        if (activeFocus) {
            currentHelpbarModel = achievementsHelpModel;
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
        height: vpx(75)

        Text {
            anchors {
                left: parent.left; leftMargin: globalMargin
                verticalCenter: parent.verticalCenter
            }
            text: "Retro Achievements"
            color: theme.text
            font.family: titleFont.name
            font.pixelSize: vpx(28)
            font.bold: true
        }

        // User avatar + name + points (top-right)
        Row {
            anchors {
                right: parent.right; rightMargin: globalMargin
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(10)
            visible: cheevosData.raUserName !== ""

            Image {
                width: vpx(44); height: vpx(44)
                source: cheevosData.avatarUrl
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                visible: cheevosData.avatarUrl !== ""
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: cheevosData.raUserName
                    color: theme.text
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(16)
                    font.bold: true
                }
                Text {
                    text: cheevosData.pointsText
                    color: theme.text
                    font.family: bodyFont.name
                    font.pixelSize: vpx(13)
                    opacity: 0.7
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
            top:    achievementsHeader.bottom; topMargin:    vpx(10)
            bottom: parent.bottom;            bottomMargin: helpMargin + vpx(10)
            left:   parent.left;              leftMargin:   globalMargin
            right:  parent.right;             rightMargin:  globalMargin
        }

        model: cheevosData.raRecentGames
        clip: true

        highlightMoveDuration: 100
        preferredHighlightBegin: height / 2 - vpx(45)
        preferredHighlightEnd:   height / 2 + vpx(45)
        highlightRangeMode: ListView.ApplyRange

        highlight: Rectangle {
            color:   theme.accent
            opacity: 0.25
            radius:  vpx(4)
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
            height: vpx(80)

            property bool isSelected: ListView.isCurrentItem && gameList.focus

            Row {
                anchors {
                    fill: parent
                    leftMargin:  vpx(8)
                    rightMargin: vpx(8)
                }
                spacing: vpx(12)

                // ── Game icon ────────────────────────────────────────────
                Item {
                    width:  vpx(56)
                    height: vpx(56)
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        color:   theme.secondary
                        radius:  vpx(4)
                        opacity: 0.5
                    }
                    Image {
                        anchors.fill: parent
                        source: ImageIcon ? "https://media.retroachievements.org" + ImageIcon : ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                        sourceSize { width: 64; height: 64 }
                    }
                }

                // ── Title + console + progress bar ───────────────────────
                Column {
                    width:  parent.width - vpx(56) - vpx(120) - vpx(32)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: vpx(4)

                    Text {
                        text:  Title
                        color: theme.text
                        font.family:    subtitleFont.name
                        font.pixelSize: vpx(17)
                        font.bold:      true
                        elide: Text.ElideRight
                        width: parent.width
                        opacity: isSelected ? 1.0 : 0.85
                    }
                    Text {
                        text:  ConsoleName
                        color: theme.text
                        font.family:    bodyFont.name
                        font.pixelSize: vpx(13)
                        opacity: isSelected ? 0.8 : 0.5
                    }

                    // Progress bar (only shown for games that have achievements)
                    Item {
                        width:   parent.width
                        height:  vpx(6)
                        visible: NumPossibleAchievements > 0

                        Rectangle {
                            anchors.fill: parent
                            color:   theme.text
                            opacity: 0.15
                            radius:  height / 2
                        }
                        Rectangle {
                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                            width:   NumPossibleAchievements > 0
                                     ? parent.width * (NumAchieved / NumPossibleAchievements)
                                     : 0
                            color:   theme.accent
                            radius:  height / 2
                        }
                    }
                }

                // ── Completion counts ────────────────────────────────────
                Column {
                    width: vpx(112)
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: NumPossibleAchievements > 0
                              ? NumAchieved + " / " + NumPossibleAchievements
                              : "No cheevos"
                        color: theme.text
                        font.family:    subtitleFont.name
                        font.pixelSize: vpx(15)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        opacity: isSelected ? 1.0 : 0.7
                    }
                    Text {
                        text: NumPossibleAchievements > 0
                              ? ScoreAchieved + " / " + PossibleScore + " pts"
                              : ""
                        color: theme.text
                        font.family:    bodyFont.name
                        font.pixelSize: vpx(12)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        opacity: isSelected ? 0.75 : 0.45
                    }
                }
            }

            // Row divider
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height:  vpx(1)
                color:   theme.text
                opacity: 0.06
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
    ListModel {
    id: achievementsHelpModel
        ListElement { name: "Back";    button: "cancel"  }
        ListElement { name: "Details"; button: "accept"  }
        ListElement { name: "Refresh"; button: "filters" }
    }
}
