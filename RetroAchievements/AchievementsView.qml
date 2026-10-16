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
import QtGraphicalEffects 1.15
import "../Global"
import "../utils.js" as Utils

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

    // Touch/click blocker — these RA pages are shown full-screen over whatever
    // was on screen before; absorb pointer input so taps on empty areas can't
    // fall through to the screen behind. Sits below all page content (declared
    // after this), so the page's own controls still receive input on top.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onPressed: mouse.accepted = true
        onClicked: mouse.accepted = true
        onReleased: mouse.accepted = true
    }

    // ── Header ───────────────────────────────────────────────────────────
    Item {
    id: achievementsHeader

        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(120)   // the header band, same as every other screen

        // Header band: the theme colour; the content surface below is dimmed,
        // and that contrast is the separator — no accent lines.
        Rectangle { anchors.fill: parent; color: theme.main; z: -1 }

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
            sourceSize { width: hrpx(96); height: hrpx(96) }
        }

        // Avatar + username + points + rank + member since
        Row {
            anchors {
                left: raLogo.right; leftMargin: vpx(12)
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(12)

            // Circular avatar (OpacityMask clip) + accent ring
            Item {
                width: vpx(56); height: vpx(56)
                visible: cheevosData.avatarUrl !== ""
                Image {
                id: raOverviewAvatar
                    anchors.fill: parent
                    source: cheevosData.avatarUrl
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    sourceSize { width: hrpx(64); height: hrpx(64) }
                    layer.enabled: true
                    layer.smooth: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: raOverviewAvatar.width; height: raOverviewAvatar.height
                            radius: width / 2
                        }
                    }
                }
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
                    font.pixelSize: fpx(24)
                    font.bold: true
                }
                // Points, alternating with Rank # when RA has one.
                RAStatLine {
                    color: theme.text
                    fontFamily: bodyFont.name
                    pixelSize: fpx(15)
                    opacity: 0.65
                }
                Text {
                    text: cheevosData.memberText
                    color: theme.text
                    font.family: bodyFont.name
                    font.pixelSize: fpx(13)
                    opacity: 0.45
                    visible: cheevosData.memberText !== ""
                }
            }
        }

        // Shared status cluster (clock / battery / wifi) — same component and
        // ShowClock/ShowBattery/ShowWifi settings as every other page.
        StatusCluster {
            anchors.fill: parent
            z: 50
            dark: whiteBackground
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: vpx(1)
            color: theme.text
            opacity: 0.1
        }
    }

    // ── 2. Depth under the header band ────────────────────────────────────
    // A few pixels of soft darkening on the surface just below the band, so
    // the band reads as sitting ON the content rather than beside it. Not an
    // accent line — a shadow. Goes away with dimming Off.
    Rectangle {
        anchors { top: achievementsHeader.bottom; left: parent.left; right: parent.right }
        height: vpx(14)
        z: 4
        visible: gridDimOpacity > 0
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.35) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
        }
    }

    // Content surface: everything below the band sits on the dimmed layer.
    Rectangle {
        anchors { top: achievementsHeader.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        color: "#000000"; opacity: gridDimOpacity; visible: opacity > 0   // no z: order places it above the page fill, below the lists
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
            font.pixelSize: fpx(18)
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
        onCurrentIndexChanged: if (navReady) playNav()

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
            font.pixelSize: fpx(18)
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
                        sourceSize { width: hrpx(96); height: hrpx(96) }
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
                        font.pixelSize: fpx(26)
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
                        font.pixelSize: fpx(13)
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
                        font.pixelSize: fpx(21)
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
                            font.pixelSize: fpx(15)
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
                            font.pixelSize: fpx(14)
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

    // Wheel moves the selection (see Global/WheelNav.qml) — a sibling of the
    // view, never a child: a MouseArea inside a Flickable is reparented into
    // its contentItem and scrolls away with it.
    WheelNav {
        anchors.fill: gameList
        view: gameList
        columns: 1
        active: !librarySearch.open
        onStepped: function(quiet) { if (!quiet) playNav(); }
    }

    // ── Page counter ─────────────────────────────────────────────────────
    // Top right, above the list. It used to sit bottom-right, which left the
    // bottom row crowded once the shared Apps prompt appeared bottom-left on
    // every screen.
    Text {
        visible: cheevosData.raUserName !== "" && cheevosData.raRecentGames.count > 0
        anchors {
            right:  parent.right; rightMargin: globalMargin
            bottom: gameList.top; bottomMargin: vpx(4)
        }
        text: (gameList.currentIndex + 1) + " of " + cheevosData.raRecentGames.count
        color: theme.text
        font.family: bodyFont.name
        font.pixelSize: fpx(20)
        font.bold: true
        opacity: 0.75
    }

    // ── Local help bar (bottom-right) ────────────────────────────────────
    // Right-aligned: the shared button bar puts the Apps prompt bottom-left on
    // every screen, and these used to start there too and overlap it.
    Row {
        z: 5   // above the bottom fade
        anchors {
            right: parent.right; rightMargin: globalMargin
            bottom: parent.bottom; bottomMargin: vpx(10)
        }
        spacing: vpx(20)

        Repeater {
            model: localHelpModel
            // Clickable: a click does what pressing that button does here.
            delegate: Item {
                width: raPrompt.width; height: raPrompt.height
                opacity: raPromptMouse.pressed ? 0.6 : 1
                Row {
                id: raPrompt
                    spacing: vpx(8)
                    Image {
                        source: "../assets/images/controller/"
                                + buttonbar.processButtonArt(button) + ".png"
                        width: vpx(32); height: vpx(32)
                        asynchronous: true
                        sourceSize { width: hrpx(48); height: hrpx(48) }
                    }
                    Text {
                        text: name
                        font.family: subtitleFont.name
                        font.pixelSize: fpx(20)
                        color: theme.text
                        height: vpx(32)
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                MouseArea {
                id: raPromptMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.helpAction(button)
                }
            }
        }
    }

    ListModel {
    id: localHelpModel
        ListElement { name: "Details"; button: "accept"  }
        ListElement { name: "Search";  button: "details" }
        ListElement { name: "Refresh"; button: "filters" }
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
    // While the search overlay is open it owns all input (it has focus), so
    // these only ever run for the recently-played list underneath.
    Keys.onUpPressed: {
        event.accepted = true;
        if (librarySearch.open) return;
        if (gameList.currentIndex > 0) gameList.currentIndex--;
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (librarySearch.open) return;
        if (gameList.currentIndex < cheevosData.raRecentGames.count - 1)
            gameList.currentIndex++;
    }
    // Mouse back button: mirrors B. An open search never gets here —
    // theme.qml's mouseBack() handles it first.
    function mouseBack() {
        previousScreen();
    }

    // Clickable prompts (this page's own row): each does what its button does.
    function helpAction(button) {
        if (librarySearch.open) return;
        if (button === "details") openLibrarySearch("ra");
        else if (button === "accept") { playAccept(); openSelectedGame(); }
        else if (button === "cancel") previousScreen();
        else if (button === "filters") { playAccept(); initialized = false; cheevosData.refreshAll(); }
    }

    Keys.onPressed: {
        // X — open the library search (theme instance, RA mode; it plays
        // the accept sound itself)
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            openLibrarySearch("ra");
            return;
        }
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            playAccept();
            openSelectedGame();
        }
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            previousScreen();
        }
        // Y — refresh
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            playAccept();
            initialized = false;
            cheevosData.refreshAll();
        }
    }

    // ── Library search ────────────────────────────────────────────────────
    // X opens the theme-level search (librarySearch in theme.qml) in RA mode.
    // It used to be a LibrarySearch instance on this page, but this page's
    // Loader unloads once you navigate to a result — the search went with it,
    // so B came back to a fresh page with no results. The theme instance
    // persists, keeps the results, and reopens them on the way back.
    // RAGameEntryView still does the RA game-ID lookup for the chosen game.

    // The last row dissolves under the help bar (same fade as the grids).
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: helpMargin + vpx(120)
        // Below this page's own prompt row (it draws the right-hand prompts
        // itself; only "Apps" comes from the theme's bar above the page).
        z: 1
        opacity: gridFadeOpacity    // part of "Background dimming": Off = no fade
        visible: opacity > 0
        gradient: Gradient {
            GradientStop { position: 0.0;  color: Qt.rgba(theme.main.r, theme.main.g, theme.main.b, 0.0)  }
            GradientStop { position: 0.25; color: Qt.rgba(theme.main.r, theme.main.g, theme.main.b, 0.12) }
            GradientStop { position: 0.5;  color: Qt.rgba(theme.main.r, theme.main.g, theme.main.b, 0.45) }
            GradientStop { position: 0.75; color: Qt.rgba(theme.main.r, theme.main.g, theme.main.b, 0.85) }
            GradientStop { position: 1.0;  color: theme.main }
        }
    }
}
