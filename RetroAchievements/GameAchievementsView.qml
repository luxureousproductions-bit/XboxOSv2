// XboxOSv2 – Per-game achievements list
// Shows all achievements for a single game, sorted earned-first.

import QtQuick 2.0
import QtQuick.Layouts 1.11
import "../Global"

FocusScope {
id: root

    anchors.fill: parent

    property int currentIndex: 0

    onActiveFocusChanged: {
        if (activeFocus) {
            currentHelpbarModel = gameAchievementsHelpModel;
            currentIndex = 0;
        }
    }

    // ── Background ───────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: theme.main
    }

    // ── Header ───────────────────────────────────────────────────────────
    Item {
    id: gameAchievementsHeader

        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(75)

        // Game icon
        Item {
        id: gameIconArea

            anchors {
                left: parent.left; leftMargin: globalMargin
                top: parent.top; topMargin: vpx(10)
                bottom: parent.bottom; bottomMargin: vpx(10)
            }
            width: height

            Rectangle {
                anchors.fill: parent
                color:   theme.secondary
                radius:  vpx(4)
                opacity: 0.5
            }
            Image {
                anchors.fill: parent
                source: cheevosData.currentGameDetails.ImageIcon
                        ? "https://media.retroachievements.org" + cheevosData.currentGameDetails.ImageIcon
                        : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
                sourceSize { width: 64; height: 64 }
            }
        }

        // Game title + console
        Column {
            anchors {
                left: gameIconArea.right; leftMargin: vpx(12)
                verticalCenter: parent.verticalCenter
                right: completionArea.left; rightMargin: vpx(10)
            }
            spacing: vpx(2)

            Text {
                text:  cheevosData.currentGameDetails.Title
                color: theme.text
                font.family:    titleFont.name
                font.pixelSize: vpx(22)
                font.bold:      true
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                text:  cheevosData.currentGameDetails.ConsoleName
                color: theme.text
                font.family:    bodyFont.name
                font.pixelSize: vpx(13)
                opacity: 0.65
            }
        }

        // Completion summary (top-right)
        Column {
        id: completionArea

            anchors {
                right: parent.right; rightMargin: globalMargin
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(2)

            Text {
                text: cheevosData.currentGameDetails.NumAchievements > 0
                      ? cheevosData.currentGameDetails.NumAwardedToUser
                        + " / " + cheevosData.currentGameDetails.NumAchievements
                      : ""
                color: theme.text
                font.family:    subtitleFont.name
                font.pixelSize: vpx(16)
                font.bold:      true
                horizontalAlignment: Text.AlignRight
                anchors.right: parent.right
            }
            Text {
                text: cheevosData.currentGameDetails.NumAchievements > 0 ? "achievements" : ""
                color: theme.text
                font.family:    bodyFont.name
                font.pixelSize: vpx(12)
                opacity: 0.6
                horizontalAlignment: Text.AlignRight
                anchors.right: parent.right
            }
        }

        // Completion bar spanning full header bottom
        Item {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: vpx(3)
            visible: cheevosData.currentGameDetails.NumAchievements > 0

            Rectangle {
                anchors.fill: parent
                color:   theme.text
                opacity: 0.1
            }
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: cheevosData.currentGameDetails.NumAchievements > 0
                       ? parent.width * (cheevosData.currentGameDetails.NumAwardedToUser
                                         / cheevosData.currentGameDetails.NumAchievements)
                       : 0
                color: theme.accent
            }
        }
    }

    // ── Achievement list ─────────────────────────────────────────────────
    ListView {
    id: achievementList

        anchors {
            top:    gameAchievementsHeader.bottom; topMargin:    vpx(8)
            bottom: parent.bottom;                bottomMargin: helpMargin + vpx(8)
            left:   parent.left;                  leftMargin:   globalMargin
            right:  parent.right;                 rightMargin:  globalMargin
        }

        model: cheevosData.raGameCheevos
        currentIndex: root.currentIndex
        clip: true

        highlightMoveDuration: 100
        preferredHighlightBegin: height / 2 - vpx(40)
        preferredHighlightEnd:   height / 2 + vpx(40)
        highlightRangeMode: ListView.ApplyRange

        highlight: Rectangle {
            color:   theme.accent
            opacity: 0.25
            radius:  vpx(4)
            width:   achievementList.width
        }

        // Status / empty message
        Text {
            anchors.centerIn: parent
            visible: cheevosData.raGameCheevos.count === 0
            text:    cheevosData.statusText || "No achievements found"
            color:   theme.text
            font.family: bodyFont.name
            font.pixelSize: vpx(18)
            opacity: 0.5
        }

        delegate: Item {
        id: achievementRow

            width:  achievementList.width
            height: vpx(76)

            property bool isSelected: ListView.isCurrentItem && achievementList.focus
            property bool isEarned:   DateEarned > 0

            Row {
                anchors {
                    fill: parent
                    leftMargin:  vpx(8)
                    rightMargin: vpx(8)
                }
                spacing: vpx(12)

                // ── Badge image ──────────────────────────────────────────
                Item {
                    width:  vpx(52)
                    height: vpx(52)
                    anchors.verticalCenter: parent.verticalCenter

                    // Earned: full colour; unearned: dark overlay
                    Rectangle {
                        anchors.fill: parent
                        color:   theme.secondary
                        radius:  vpx(4)
                        opacity: 0.5
                    }
                    Image {
                    id: badgeImg

                        anchors.fill: parent
                        source: BadgeName !== ""
                                ? "https://media.retroachievements.org/Badge/"
                                  + BadgeName + ".png"
                                : ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                        sourceSize { width: 64; height: 64 }
                        opacity: isEarned ? 1.0 : 0.35
                    }

                    // Lock icon overlay for unearned achievements
                    Rectangle {
                        anchors.fill: parent
                        color:        "black"
                        opacity:      isEarned ? 0 : 0.45
                        radius:       vpx(4)
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }

                // ── Title + description ──────────────────────────────────
                Column {
                    width:  parent.width - vpx(52) - vpx(70) - vpx(32)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: vpx(3)

                    Row {
                        spacing: vpx(6)
                        Text {
                            text:  Title
                            color: theme.text
                            font.family:    subtitleFont.name
                            font.pixelSize: vpx(16)
                            font.bold:      true
                            elide: Text.ElideRight
                            width: parent.parent.width - (hardcoreLabel.visible ? hardcoreLabel.width + vpx(6) : 0)
                            opacity: isSelected ? 1.0 : (isEarned ? 0.9 : 0.5)
                        }
                        // "HC" badge for hardcore earned achievements
                        Rectangle {
                        id: hardcoreLabel

                            visible: isEarned && Hardcore
                            width:   vpx(26)
                            height:  vpx(16)
                            radius:  vpx(3)
                            color:   theme.accent
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text:  "HC"
                                color: theme.text
                                font.family:    bodyFont.name
                                font.pixelSize: vpx(10)
                                font.bold:      true
                            }
                        }
                    }

                    Text {
                        text:  Description
                        color: theme.text
                        font.family:    bodyFont.name
                        font.pixelSize: vpx(12)
                        elide: Text.ElideRight
                        width: parent.width
                        opacity: isSelected ? 0.75 : (isEarned ? 0.55 : 0.35)
                    }

                    // Date earned
                    Text {
                        visible: isEarned
                        text: isEarned
                              ? Qt.formatDateTime(new Date(DateEarned), "MMM d, yyyy  h:mm AP")
                              : ""
                        color: theme.accent
                        font.family:    bodyFont.name
                        font.pixelSize: vpx(11)
                        opacity: isSelected ? 1.0 : 0.7
                    }
                }

                // ── Points ───────────────────────────────────────────────
                Column {
                    width: vpx(62)
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text:  Points + ""
                        color: isEarned ? theme.accent : theme.text
                        font.family:    subtitleFont.name
                        font.pixelSize: vpx(20)
                        font.bold:      true
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        opacity: isSelected ? 1.0 : (isEarned ? 0.85 : 0.35)
                    }
                    Text {
                        text:  "pts"
                        color: theme.text
                        font.family:    bodyFont.name
                        font.pixelSize: vpx(11)
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        opacity: isSelected ? 0.7 : 0.35
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
                onEntered: { sfxNav.play(); root.currentIndex = index; }
                onClicked: { sfxNav.play(); root.currentIndex = index; }
            }
        }
    }

    // ── Key handling ─────────────────────────────────────────────────────

    Keys.onUpPressed: {
        event.accepted = true;
        sfxNav.play();
        if (currentIndex > 0) currentIndex--;
    }
    Keys.onDownPressed: {
        event.accepted = true;
        sfxNav.play();
        if (currentIndex < cheevosData.raGameCheevos.count - 1) currentIndex++;
    }
    Keys.onPressed: {
        // Cancel → back to recently-played list
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            previousScreen();
        }
        // Filters → refresh current game
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (cheevosData.currentGameDetails.Title !== "") {
                // re-load whichever game is currently displayed using the stored GameID
                cheevosData.loadGameAchievements(cheevosData.currentGameID);
            }
        }
    }

    // ── Help bar ─────────────────────────────────────────────────────────
    ListModel {
    id: gameAchievementsHelpModel
        ListElement { name: "Back";    button: "cancel"  }
        ListElement { name: "Refresh"; button: "filters" }
    }
}
