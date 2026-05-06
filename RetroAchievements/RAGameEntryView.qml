// XboxOSv2 – RetroAchievements game entry point
// When the user taps the RA button on a game this screen is shown briefly:
//   • Checking  – spinner while the console-game list is fetched (first visit per console
//                 only; subsequent visits use an api.memory cache and are instant).
//   • Found     – auto-navigates straight to GameAchievementsView with no extra tap.
//                 "raentryscreen" is NOT pushed to lastState so pressing Back in
//                 GameAchievementsView returns directly to GameView.
//   • Not found – shows the reason and two buttons: "View Overview" / "Go Back".

import QtQuick 2.15
import "../Global"

FocusScope {
id: root

    anchors.fill: parent

    // ── Lifecycle ────────────────────────────────────────────────────────

    // Guards against double-navigation when both the Connections signal and the
    // inline fallback below try to navigate in the same activation cycle.
    property bool hasNavigated: false

    onActiveFocusChanged: {
        if (!activeFocus) return;

        currentHelpbarModel = null;  // this screen draws its own local help bar
        buttonRow.selectedIndex = 0;
        hasNavigated = false;

        // Always (re-)run the lookup when this screen gains focus.
        // lookupGame() resets pendingGameID to -1 immediately, so stale state
        // from a previous visit never causes a spurious early-exit.
        // Cache hits resolve synchronously, so repeated visits for the same
        // console never hit the network after the first fetch.
        if (currentGame)
            cheevosData.lookupGame(
                currentGame.title,
                currentGame.collections.get(0).shortName
            );
        else {
            cheevosData.lookupStatusMsg = "No game selected";
            cheevosData.pendingGameID   = 0;
        }

        // Fallback for synchronous cache hits.  When lookupGame() resolves via
        // the in-memory cache, pendingGameID is already set to a valid game ID
        // by the time we return here.  The Connections handler below may have
        // already fired and set hasNavigated = true; if it did not (rare QML
        // async-Loader focus-timing edge-case) we navigate here instead.
        if (!hasNavigated && cheevosData.pendingGameID > 0) {
            hasNavigated = true;
            cheevosData.loadGameAchievements(cheevosData.pendingGameID);
            gameAchievementsScreenFromEntry();
        }
    }

    // Handles the asynchronous case: pendingGameID is set later (network
    // response) rather than synchronously inside lookupGame().  Also fires for
    // synchronous cache hits; the hasNavigated guard prevents double-navigation.
    Connections {
        target: cheevosData
        onPendingGameIDChanged: {
            if (root.hasNavigated || !root.activeFocus) return;
            if (cheevosData.pendingGameID > 0) {
                root.hasNavigated = true;
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
