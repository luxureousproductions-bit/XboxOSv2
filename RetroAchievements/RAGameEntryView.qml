// XboxOSv2 – RetroAchievements game entry point
// When the user taps the RA button on a game this screen is shown briefly:
//   • Checking  – spinner while the console-game list is fetched (first visit per console
//                 only; subsequent visits use an api.memory cache and are instant).
//   • Found     – auto-navigates straight to GameAchievementsView with no extra tap.
//                 "raentryscreen" is NOT pushed to lastState so pressing Back in
//                 GameAchievementsView returns directly to GameView.
//   • Not found – shows the reason and two buttons: "View Overview" / "Go Back".

import QtQuick 2.0
import "../Global"

FocusScope {
id: root

    anchors.fill: parent

    // ── Lifecycle ────────────────────────────────────────────────────────
    onActiveFocusChanged: {
        if (!activeFocus) return;

        currentHelpbarModel = entryHelpModel;
        buttonRow.selectedIndex = 0;

        // Safety: if a previous lookup already found the game, skip back rather
        // than looping (should not normally occur given the navigation design).
        if (cheevosData.pendingGameID > 0) {
            previousScreen();
            return;
        }

        if (currentGame)
            cheevosData.lookupGame(
                currentGame.title,
                currentGame.collections.get(0).shortName
            );
        else {
            cheevosData.lookupStatusMsg = "No game selected";
            cheevosData.pendingGameID   = 0;
        }
    }

    // Watch for lookup completion; auto-navigate when a match is found.
    // Uses gameAchievementsScreenFromEntry() which deliberately does NOT push
    // "raentryscreen" onto lastState so Back in GameAchievementsView skips
    // straight back to GameView.
    Connections {
        target: cheevosData
        onPendingGameIDChanged: {
            if (root.activeFocus && cheevosData.pendingGameID > 0) {
                cheevosData.loadGameAchievements(cheevosData.pendingGameID);
                gameAchievementsScreenFromEntry();
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
    id: entryHeader

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

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: vpx(1)
            color: theme.text
            opacity: 0.1
        }
    }

    // ── Body ─────────────────────────────────────────────────────────────
    Item {
        anchors {
            top:    entryHeader.bottom
            bottom: parent.bottom; bottomMargin: helpMargin
            left:   parent.left
            right:  parent.right
        }

        // Game title + platform context
        Column {
        id: gameInfo

            anchors {
                top: parent.top; topMargin: vpx(50)
                horizontalCenter: parent.horizontalCenter
            }
            spacing: vpx(6)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:  currentGame ? currentGame.title : ""
                color: theme.text
                font.family:    subtitleFont.name
                font.pixelSize: vpx(22)
                font.bold: true
                opacity: 0.9
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:  currentGame ? currentGame.collections.get(0).name : ""
                color: theme.text
                font.family:    bodyFont.name
                font.pixelSize: vpx(14)
                opacity: 0.5
            }
        }

        // ── Checking spinner ─────────────────────────────────────────────
        Text {
        id: checkingLabel

            anchors {
                top: gameInfo.bottom; topMargin: vpx(50)
                horizontalCenter: parent.horizontalCenter
            }
            visible: cheevosData.lookupInProgress
            text:  "Checking Retro Achievements..."
            color: theme.text
            font.family:    bodyFont.name
            font.pixelSize: vpx(18)
            opacity: 0.6

            SequentialAnimation on opacity {
                running:  cheevosData.lookupInProgress
                loops:    Animation.Infinite
                NumberAnimation { to: 0.2; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.6; duration: 600; easing.type: Easing.InOutSine }
            }
        }

        // ── Not-found area ───────────────────────────────────────────────
        Column {
        id: notFoundArea

            anchors {
                top: gameInfo.bottom; topMargin: vpx(50)
                horizontalCenter: parent.horizontalCenter
            }
            spacing: vpx(32)
            visible: !cheevosData.lookupInProgress && cheevosData.pendingGameID === 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: cheevosData.lookupStatusMsg !== ""
                      ? cheevosData.lookupStatusMsg
                      : "No Retro Achievements available for this game"
                color: theme.text
                font.family:    bodyFont.name
                font.pixelSize: vpx(18)
                opacity: 0.6
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                width: vpx(520)
            }

            // Action buttons
            Row {
            id: buttonRow

                anchors.horizontalCenter: parent.horizontalCenter
                spacing: vpx(20)

                property int selectedIndex: 0

                // "View Overview" ─────────────────────────────────────────
                Rectangle {
                id: btnOverview

                    width: vpx(210); height: vpx(54)
                    radius: height / 2
                    color:        buttonRow.selectedIndex === 0 ? theme.accent : "transparent"
                    border.width: buttonRow.selectedIndex === 0 ? 0 : vpx(2)
                    border.color: theme.text
                    opacity:      buttonRow.selectedIndex === 0 ? 1.0 : 0.35

                    Behavior on opacity { NumberAnimation { duration: 100 } }
                    Behavior on color   { ColorAnimation  { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text:  "View Overview"
                        color: theme.text
                        font.family:    subtitleFont.name
                        font.pixelSize: vpx(16)
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: settings.MouseHover === "Yes"
                        onEntered: { sfxNav.play(); buttonRow.selectedIndex = 0; }
                        onClicked: { sfxAccept.play(); activateSelected(); }
                    }
                }

                // "Go Back" ───────────────────────────────────────────────
                Rectangle {
                id: btnBack

                    width: vpx(165); height: vpx(54)
                    radius: height / 2
                    color:        buttonRow.selectedIndex === 1 ? theme.accent : "transparent"
                    border.width: buttonRow.selectedIndex === 1 ? 0 : vpx(2)
                    border.color: theme.text
                    opacity:      buttonRow.selectedIndex === 1 ? 1.0 : 0.35

                    Behavior on opacity { NumberAnimation { duration: 100 } }
                    Behavior on color   { ColorAnimation  { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text:  "Go Back"
                        color: theme.text
                        font.family:    subtitleFont.name
                        font.pixelSize: vpx(16)
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: settings.MouseHover === "Yes"
                        onEntered: { sfxNav.play(); buttonRow.selectedIndex = 1; }
                        onClicked: { sfxAccept.play(); activateSelected(); }
                    }
                }
            }
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    function activateSelected() {
        if (buttonRow.selectedIndex === 0)
            achievementsScreen();
        else
            previousScreen();
    }

    // ── Key handling ─────────────────────────────────────────────────────

    Keys.onLeftPressed: {
        event.accepted = true;
        if (!cheevosData.lookupInProgress && cheevosData.pendingGameID === 0
                && buttonRow.selectedIndex > 0) {
            sfxNav.play();
            buttonRow.selectedIndex--;
        }
    }
    Keys.onRightPressed: {
        event.accepted = true;
        if (!cheevosData.lookupInProgress && cheevosData.pendingGameID === 0
                && buttonRow.selectedIndex < 1) {
            sfxNav.play();
            buttonRow.selectedIndex++;
        }
    }
    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!cheevosData.lookupInProgress && cheevosData.pendingGameID === 0) {
                sfxAccept.play();
                activateSelected();
            }
        }
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            previousScreen();
        }
    }

    // ── Help bar ─────────────────────────────────────────────────────────
    ListModel {
    id: entryHelpModel
        ListElement { name: "Back";   button: "cancel" }
        ListElement { name: "Select"; button: "accept" }
    }
}
