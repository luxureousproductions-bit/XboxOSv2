// XboxOSv2 – AchievementsView.qml
// The RetroAchievements page, after the console's profile: tabs Welcome
// (RAWelcomeTab), Social (RASocialTab) and Gaming (RAGamingTab). Your awards
// (RAAwardsTab) are a page under Social, opened from Social's rail or the
// Welcome buttons; B goes back to Social. Search lives on the Gaming tab.
// From Home it opens on Welcome; coming back from a game's page it keeps
// the tab you were on.

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
                cheevosData.loadSocial();
            }
            // Gaming and Awards tabs: once per session, the first time here.
            if (cheevosData.raUserName !== "" && !cheevosData.libraryLoaded) cheevosData.loadLibrary();
            if (cheevosData.raUserName !== "" && !cheevosData.awardsLoaded)  cheevosData.loadAwards();
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
        onWheel: wheel.accepted = true   // the wheel stops here too, not on the screen behind
        onClicked: mouse.accepted = true
        onReleased: mouse.accepted = true
    }

    // ── Header (Xbox "Gaming" tab style) ─────────────────────────────────
    // The first three are the tabs; Awards (index 3) is a page under Social.
    readonly property var raTabs: ["Welcome", "Social", "Gaming", "Awards"]
    readonly property int tabCount: 3
    property int raTab: raOverviewTab           // theme.qml: Welcome from Home, kept from a game
    onRaTabChanged: raOverviewTab = raTab
    readonly property string tabName: raTabs[raTab]
    onTabNameChanged: updateHelp()
    function tabIndex(name) { return raTabs.indexOf(name); }
    function selectTab(i) {
        if (i < 0 || i >= raTabs.length) return;
        if (i !== raTab) { raTab = i; playNav(); }
    }
    function stepTab(d) {
        var i = (raTab >= tabCount ? 1 : raTab) + d;     // from Awards: as from Social
        if (i < 0 || i >= tabCount) return;
        selectTab(i);
    }
    // Welcome's and Social's buttons: a tab, Awards, or Gaming's search.
    function goTab(name) {
        if (name === "Search") { selectTab(tabIndex("Gaming")); gamingTab.startSearch(); return; }
        selectTab(tabIndex(name));
    }

    // ── Welcome: the whole page, under the tabs ───────────────────────────
    RAWelcomeTab {
    id: welcomeTab
        anchors.fill: parent
        visible: cheevosData.raUserName !== "" && tabName === "Welcome"
        focus: visible
        onGoTab: root.goTab(name)
        onHelpStateChanged: root.updateHelp()
    }

    RAHeader {
    id: achievementsHeader
        anchors { top: parent.top; left: parent.left; right: parent.right }
        visible: cheevosData.raUserName !== ""
        tabs: raTabs.slice(0, tabCount)
        current: raTab >= tabCount ? 1 : raTab           // Awards sits under Social
        mode: tabName === "Welcome" ? "compact" : (tabName === "Social" ? "band" : "stats")
        onTabClicked: selectTab(index)
    }

    // ── 2. Depth under the header band ────────────────────────────────────
    // A few pixels of soft darkening on the surface just below the band, so
    // the band reads as sitting ON the content rather than beside it. Not an
    // accent line — a shadow. Goes away with dimming Off.
    Rectangle {
        anchors { top: achievementsHeader.bottom; left: parent.left; right: parent.right }
        height: vpx(14)
        z: 4
        visible: gridDimOpacity > 0 && tabName !== "Welcome"
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.35) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
        }
    }

    // Content surface: everything below the band sits on the dimmed layer.
    Rectangle {
        anchors { top: achievementsHeader.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        color: "#000000"; opacity: gridDimOpacity * surfaceShade; visible: opacity > 0 && tabName !== "Welcome"   // no z: order places it above the page fill, below the lists
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

    // ── Social tab: a points leaderboard of people (RASocialTab.qml) ─────
    // Full height: its three figures sit on the header band.
    RASocialTab {
    id: socialTab
        anchors.fill: parent
        bandHeight: achievementsHeader.height
        visible: cheevosData.raUserName !== "" && tabName === "Social"
        focus: visible
        onGoTab: root.goTab(name)
    }

    // ── Gaming tab: every game you've played (RAGamingTab.qml) ───────────
    RAGamingTab {
    id: gamingTab
        anchors { top: achievementsHeader.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: cheevosData.raUserName !== "" && tabName === "Gaming"
        focus: visible
        onHelpStateChanged: root.updateHelp()
    }

    // ── Awards tab: your trophy case (RAAwardsTab.qml) ───────────────────
    RAAwardsTab {
    id: awardsTab
        anchors { top: achievementsHeader.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: cheevosData.raUserName !== "" && tabName === "Awards"
        focus: visible
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
            delegate: Row {
                TapHandler { gesturePolicy: TapHandler.WithinBounds; onTapped: helpClick(button) }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
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
        }
    }

    ListModel {
    id: localHelpModel
        ListElement { name: "Select";  button: "accept"  }
        ListElement { name: "Refresh"; button: "filters" }
        ListElement { name: "Back";    button: "cancel"  }
    }

    // The Gaming tab's Leaderboards view and its top-100 pop-up bring their
    // own prompts; everything else uses the page's four.
    function updateHelp() {
        var st = gamingTab.visible ? gamingTab.helpState
               : welcomeTab.visible ? welcomeTab.helpState : "";
        localHelpModel.clear();
        if (st === "keyboard") return;                  // the keyboard shows its own
        if (st === "board") {
            localHelpModel.append({ name: "Top",   button: "prevPage" });
            localHelpModel.append({ name: "You",   button: "nextPage" });
            localHelpModel.append({ name: "Close", button: "cancel" });
            return;
        }
        if (st === "filters" || st === "filtersApply" || st === "menu" || st === "awards") {
            localHelpModel.append({ name: st === "filtersApply" ? "Apply" : (st === "awards" ? "View game" : "Select"), button: "accept" });
            localHelpModel.append({ name: "Close", button: "cancel" });
            return;
        }
        localHelpModel.append({ name: st === "boards" ? "View" : "Select", button: "accept" });
        localHelpModel.append({ name: "Refresh", button: "filters" });
        localHelpModel.append({ name: "Back",    button: "cancel" });
    }

    // ── Key handling ─────────────────────────────────────────────────────
    // Each tab moves its own cursor; arrows that reach here go nowhere.
    Keys.onUpPressed:   event.accepted = true
    Keys.onDownPressed: event.accepted = true
    // Mouse back button: mirrors B. An open search never gets here —
    // theme.qml's mouseBack() handles it first.
    function mouseBack() {
        back();
    }

    // Clickable prompts: each does what its button does.
    function helpAction(button) {
        if (gamingTab.visible && gamingTab.helpAction(button)) return true;
        if (welcomeTab.visible && welcomeTab.helpAction(button)) return true;
        if (button === "accept") return false;
        else if (button === "cancel") back();
        else if (button === "filters") { playAccept(); initialized = false; cheevosData.refreshAll(); }
        else return false;
        return true;
    }

    // B: from Awards back to Social, else out of RA.
    function back() {
        if (tabName === "Awards") { selectTab(tabIndex("Social")); playBack(); }
        else previousScreen();
    }
    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            back();
        }
        // LB / RB — tabs, as on the Xbox
        if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; stepTab(-1); return; }
        if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; stepTab(1);  return; }
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
            GradientStop { position: 0.0;  color: mainA(0.0)  }
            GradientStop { position: 0.25; color: mainA(0.12) }
            GradientStop { position: 0.5;  color: mainA(0.45) }
            GradientStop { position: 0.75; color: mainA(0.85) }
            GradientStop { position: 1.0;  color: theme.main }
        }
    }
}
