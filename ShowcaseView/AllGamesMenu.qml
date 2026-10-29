// AllGamesMenu.qml — All games across all collections
import QtQuick 2.15
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.12
import QtMultimedia 5.15
import QtQuick.Window 2.15   // Window.window: frame pacing for held-key scrolling
import "../Global"
import "../Lists"
import "../utils.js" as Utils
import SortFilterProxyModel 0.2

FocusScope {
id: root

    // Touch/click blocker — full-screen page shown over the previous screen;
    // absorb pointer input so taps on empty areas can't fall through to it.
    // z:-100 keeps it behind all page content (z>=0) but in front of the
    // screen behind, so the page's own controls receive input first.
    MouseArea {
        anchors.fill: parent
        z: -100
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onPressed: mouse.accepted = true
        onWheel: wheel.accepted = true   // the wheel stops here too, not on the screen behind
        onClicked: mouse.accepted = true
        onReleased: mouse.accepted = true
    }

    property real itemheight: vpx(50)

    // ── Grid layout ───────────────────────────────────────────────────────
    // The same menu, laid out as tiles. Both views bind to displayModel and
    // share currentGameIndex, so currentGame — and everything derived from it
    // (audio, video preview, imported-app handling, the helpbar) — is
    // unchanged. Only the layout differs; there is no second screen.
    // All Games and the systems each have their own View (Settings >
    // Library); a system can also have its own (Y on that system).
    readonly property bool gridMode: lvView === "Grid"
    // The header buttons hand focus back to "the games". That used to be
    // gamelist unconditionally — in grid mode that focused the hidden list,
    // so the grid never received input.
    // Mouse back button: mirrors B, in the same priority order.
    // Clickable prompts (theme.qml helpClick). Panels and tiles answer
    // first; this is the page itself, mirroring its key handler. B is
    // left to mouseBack(), which mirrors it.
    function helpAction(button) {
        if (filterOpen || listPanelOpen || searchActive) return false;
        if (button === "accept") {
            if (!gamesFocused) {
                if (homebutton.activeFocus) showcaseScreen();
                else if (discoverbutton.activeFocus) discoverScreen(scopedColl);
                else if (achievementsbutton.activeFocus) achievementsScreen();
                else if (settingsbutton.activeFocus) settingsScreen();
                return true;
            }
            if (!currentGame) return true;
            if (gridMode) activateCurrent(); else activateGame(currentGame, false);
            return true;
        }
        if (!gamesFocused) return false;
        if (button === "details") { openFilters(); return true; }
        if (button === "filters") { playAccept(); listRow = 0; listPanelOpen = true; listPanel.forceActiveFocus(); return true; }
        return false;
    }

    function mouseBack() {
        if (listPanelOpen)   { playBack(); listPanelOpen = false; focusGames(); return; }
        if (searchActive)    { searchActive = false; filterPanel.forceActiveFocus(); return; }
        if (genrePickerOpen) { genrePickerOpen = false; filterPanel.forceActiveFocus(); return; }
        if (filterOpen)      { playBack(); filterOpen = false; focusGames(); return; }
        if (!gamesFocused)   { focusGames(); return; }     // header -> games
        previousScreen();
    }

    function openFilters() {
        playAccept();
        var fi = sortFields.map(function(f){ return f.key; }).indexOf(sortField);
        filterRow = fi >= 0 ? fi + 2 : 0;
        filterOpen = true;
        searchActive = false;
        genrePickerOpen = false;
        filterPanel.forceActiveFocus();
    }

    function focusGames() {
        if (gridMode) gamegrid.focus = true; else gamelist.focus = true;
        refreshHelpbar();   // the bar for the games, not the header buttons
    }
    // "Are the games focused?" — whichever view is showing. Every button
    // handler tests this, so none can be left checking the hidden list.
    readonly property bool gamesFocused: gridMode ? gamegrid.focus : gamelist.focus
    // A on a grid tile. openGame() honours "Added App Launch": imports and
    // apps set to Instant launch straight away, everything else opens details.
    function activateCurrent() {
        if (filterOpen || !currentGame) return;
        activateGame(currentGame, true);       // grid: games open details
    }
    // ── Fast-scroll detection ─────────────────────────────────────────────
    // Two cursor moves inside 180ms means the user is racing, not browsing.
    // While that holds, the grid skips work the user scrolls straight past:
    // tile animations, the highlight's slide, and look-ahead rows. It
    // releases 200ms after the last move, so single presses never trigger it
    // and nothing at rest is affected, in either mode.
    property bool fastScrolling: false
    property double lastNavMs: 0
    Timer {
    id: fastScrollRelease
        interval: 200
        onTriggered: root.fastScrolling = false
    }
    // Held-key pacing. A held direction sends repeat presses at a fixed rate.
    // When a device can't draw each step that fast (the Odin 1's 845), the
    // repeats queued up and were then all carried out one after another: the
    // grid crawled, froze, and kept scrolling for many seconds after release.
    // Now a REPEAT press is skipped while the previous step hasn't reached the
    // screen yet, so the queue never forms: scrolling runs as fast as the
    // device can draw and stops on release. A fresh press is never skipped.
    property bool stepPending: false
    Connections {
        target: root.Window.window
        onFrameSwapped: root.stepPending = false
    }
    // Safety: a step that changes nothing on screen produces no new frame.
    Timer {
    id: stepPendingSafety
        interval: 250
        onTriggered: root.stepPending = false
    }
    function gridRepeatBlocked(event) {
        // A held key is racing by definition, skipped repeat or not. Racing was
        // only detected from steps under 180ms apart, and on a slow device the
        // pacing can space steps wider, which would drop the grid out of its
        // light racing mode (art held back, no halo) into loading every step.
        if (event.isAutoRepeat) { fastScrolling = true; noteGridNav(); }
        if (event.isAutoRepeat && stepPending) return true;
        stepPending = true;
        stepPendingSafety.restart();
        return false;
    }
    function noteGridNav() {
        var now = Date.now();
        if (now - lastNavMs < 180) fastScrolling = true;
        lastNavMs = now;
        fastScrollRelease.restart();
    }

    // The view currently showing the games; the letter jumps drive this.
    readonly property var gamesView: gridMode ? gamegrid : gamelist

    // ── Library: one screen for All Games AND a single system ─────────────
    // Opening a system from Home lands here scoped to it. Scoped, the tiles
    // follow Settings > Library > Tiles - System view, with that system's own
    // overrides on top when Per-system overrides is on. The All view uses
    // Tiles - All view.
    readonly property bool scoped: systemIndex >= 0
    readonly property var  scopedColl: scoped ? api.collections.get(systemIndex) : null
    readonly property string sysKey: scopedColl ? (scopedColl.shortName || "") : ""
    // ── Library settings: All Games, Systems, and each system ─────────────
    // All Games has its own rows; Systems is the default for every system;
    // a system can follow Systems or have its own ("<shortName> - <row>",
    // switched by "<shortName> - Use theme settings": Yes = follow).
    // Every value is live (listEpoch / settingsEpoch), so the Y panel and
    // Settings apply as they're changed.
    function sysOwn() {
        var e = listEpoch;
        return scoped && sysKey !== ""
               && settingsStore.get(sysKey + " - Use theme settings", "Yes") === "No";
    }
    // The value a system uses for a row: its own when it has its own,
    // otherwise what Systems uses.
    function sysPref(row, systemsValue) {
        var e = listEpoch;
        return sysOwn() ? settingsStore.get(sysKey + " - " + row, systemsValue) : systemsValue;
    }
    // All Games
    readonly property string allView:     lv("All Games View",           settings.AllGamesView)
    readonly property string allStyle:    lv("AllGames Tile Style",      settings.AllGamesTileStyle)
    readonly property string allRatio:    lv("AllGames Tile Ratio",      settings.AllGamesTileRatio)
    readonly property string allArt:      lv("AllGames Tile Art",        settings.AllGamesTileArt)
    readonly property string allLogo:     lv("AllGames Tile Logo",       settings.AllGamesTileLogo)
    readonly property string allColumns:  lv("AllGames Items per row",   settings.AllGamesColumns)
    readonly property string allTitles:   lv("AllGames Tile titles")
    readonly property string allPreview:  lv("AllGames Video preview")
    readonly property string allSound:    lv("All games menu video audio")
    readonly property string allGridHide: lv("AllGames Grid hide logo on video")
    readonly property string allListHide: lv("AllGames List hide on video")
    // Systems (the default for every system)
    readonly property string sysView:     lv("Systems View")
    readonly property string sysStyle:    lv("Grid Thumbnail",           settings.GridThumbnail)
    readonly property string sysRatio:    lv("Grid Ratio",               settings.GridRatio)
    readonly property string sysArt:      lv("Grid art",                 settings.GridArt)
    readonly property string sysTileLogo: lv("Grid Game Logo",           settings.GridGameLogo)
    readonly property string sysColumns:  lv("Number of columns",        settings.GridColumns)
    readonly property string sysTitles:   lv("Systems Tile titles")
    // What this page is showing uses
    readonly property string lvView:      scoped ? sysPref("View",              sysView)    : allView
    readonly property string tileStyle:   scoped ? sysPref("Tile shape",        sysStyle)   : allStyle
    readonly property string tileRatioStr:scoped ? sysPref("Tile ratio",        sysRatio)   : allRatio
    readonly property string tileArt:     scoped ? sysPref("Tile art",          sysArt)     : allArt
    readonly property string tileLogo:    scoped ? sysPref("Show logo on tile", sysTileLogo): allLogo
    readonly property string tileColumns: scoped ? sysPref("Tiles per row",     sysColumns) : allColumns
    readonly property string tileTitles:  scoped ? sysPref("Game tile titles",  sysTitles)  : allTitles
    // Previews are one Library-wide choice (Settings › Previews & sound):
    // All Games and every system alike, nothing per system.
    readonly property string lvVideo:     gatePreview(allPreview)
    readonly property string lvSound:     gateSound(allSound)
    // Under a playing preview the art always fades. Grid: also the logo?
    // List: the box art, the logo, both or neither (the screenshot always).
    readonly property bool   gridHideLogo: allGridHide === "Yes"
    readonly property string listHide:     allListHide

    // The scope the theme asked for (Home system tile, Library button,
    // return from a game). -2 = nothing pending.
    readonly property int scopeSerial: libraryScopeSerial
    onScopeSerialChanged: applyPendingScope()
    function applyPendingScope() {
        if (libraryScopePending === -2) {
            // Nothing asked for: show what the Library was showing (this
            // screen is rebuilt on every return from Game details).
            if (libraryScope !== systemIndex) applyScope(libraryScope);
            return;
        }
        var want = libraryScopePending;
        libraryScopePending = -2;
        applyScope(want);
    }
    // Rebuilds the grid's tiles on a scope change. Recycled tiles (reuseItems)
    // kept the previous system's cell size when the tiles-per-row differed,
    // and overlapped the new layout for a moment.
    // The grid rebinds a moment later, after the proxy has re-sorted the
    // new system (its sort is queued); rebinding in the same event showed
    // the games in file order.
    property bool gridFlushing: false
    function flushGrid() { gridFlushing = true; gridFlushTimer.restart(); }
    Timer {
    id: gridFlushTimer
        interval: 60
        onTriggered: { gridFlushing = false; gamegrid.forceLayout(); }
    }
    function applyScope(collIdx) {
        if (systemOptions.length === 0) buildSystemOptions();
        var opt = { name: "ALL", index: -1 };
        for (var i = 0; i < systemOptions.length; i++)
            if (systemOptions[i].index === collIdx) { opt = systemOptions[i]; break; }
        selectSystem(opt);
        // The new scope may flip List/Grid (per-system View); the incoming
        // view's focus binding and the outgoing one's can leave neither
        // focused, so hand focus to whichever is showing once that settles.
        if (focus) Qt.callLater(focusGames);
    }
    // LB/RB on a scoped view: previous / next system in Home's order.
    function cycleScope(dir) {
        if (sortedColl.length === 0) return;
        var i = sortedColl.indexOf(systemIndex);
        i = (i < 0) ? 0 : (i + dir + sortedColl.length) % sortedColl.length;
        if (dir > 0) playTabRight(); else playTabLeft();
        currentCollectionIndex = sortedColl[i];
        applyScope(sortedColl[i]);
    }

    readonly property int  gridColumns: parseInt(tileColumns) || 5
    readonly property bool gridBoxArt: tileStyle === "Box Art" || tileStyle === "3D Box"
    // Like the Platform grid: when titles are Always, each cell grows so the
    // box-art title beneath the art has somewhere to sit.
    readonly property real gridTitleMargin: tileTitles === "Always" ? vpx(30) : 0
    readonly property real gridCellW: gamegrid.width / gridColumns
    readonly property real gridCellH: {
        var r = parseFloat(tileRatioStr) || 0.66;
        var w = gridCellW;
        var h;
        if      (tileStyle === "Tall")    h = w / r;
        else if (tileStyle === "Square")  h = w;
        // Box Art: a typical box proportion (1.4 tall) scaled by the ratio, the
        // same scheme the Platform grid uses — 0.66 is the neutral value.
        else if (gridBoxArt)              h = w * 1.4 * (r / 0.66);   // Box Art and 3D Box
        else                              h = w * r;    // Wide
        return h + gridTitleMargin;
    }
    property int  skipnum: 10

    // ── Data ──────────────────────────────────────────────────────────────
    ListAllGames {
    id: listAllGames
        max: api.allGames.count
        hideRows: libraryHideRows       // Pegasus copies of your own entries
    }

    // Restores the stored list selection once after a (re)load
    property bool _restoredIndex: false
    // Full release date as mm/dd/yyyy when month+day are known; falls back to
    // just the year (most retro metadata only has a year), or "—" if unknown.
    function fmtReleaseDate(g) {
        if (!g || g.releaseYear <= 0) return "\u2014";
        var m = g.releaseMonth, d = g.releaseDay;
        if (m > 0 && d > 0)
            return ("0" + m).slice(-2) + "/" + ("0" + d).slice(-2) + "/" + g.releaseYear;
        return "" + g.releaseYear;
    }

    // Last played as mm/dd/yyyy, or "Never" if the game has no play history.
    function fmtLastPlayed(g) {
        if (!g || !g.lastPlayed || isNaN(g.lastPlayed.getTime())) return "Never";
        var d = g.lastPlayed;
        return ("0" + (d.getMonth() + 1)).slice(-2) + "/" + ("0" + d.getDate()).slice(-2) + "/" + d.getFullYear();
    }

    function restoreSelection() {
        if (_restoredIndex || displayModel.count <= 0) return;
        _restoredIndex = true;
        var idx = storedAllGamesIndex;
        if (idx < 0) idx = 0;
        if (idx > displayModel.count - 1) idx = displayModel.count - 1;
        gamesView.currentIndex = idx;      // whichever view is showing
        currentGameIndex = idx;
        currentGame = getCurrentGame(idx);
        restoreViewTimer.restart();   // scroll the view to center on it (deferred)
    }

    // Center the list view on the current row by setting contentY directly.
    // (positionViewAtIndex is unreliable right after a reload — the view geometry
    //  isn't ready yet, so it clamps to the top until the user scrolls.)
    function centerListOnCurrent() {
        var n = gamesView.count;
        if (n <= 0 || gamelist.height <= 0) { restoreViewTimer.restart(); return; }
        var i = gamesView.currentIndex < 0 ? 0 : gamesView.currentIndex;
        // Re-assert the current index so the highlight realizes on the visible row
        // (a delegate scrolled into view via contentY won't refresh isCurrentItem
        //  until the current item changes again).
        gamesView.currentIndex = -1;
        gamesView.currentIndex = i;
        // Center the view on the current row
        var target = i * itemheight - (gamelist.height - itemheight) / 2;
        var maxY = Math.max(0, n * itemheight - gamelist.height);
        gamelist.contentY = Math.max(0, Math.min(target, maxY));
    }

    Timer {
    id: restoreViewTimer
        interval: 110; repeat: false
        onTriggered: centerListOnCurrent()
    }

    // ── Sort / filter state ───────────────────────────────────────────────
    // ── Live list-view settings ──────────────────────────────────────────
    // The Y panel writes these keys directly; the theme's settings object
    // only re-reads on reload, so the list reads them here with an epoch.
    property int listEpoch: 0
    function lv(key, fallback) { var e = listEpoch; return settingsStore.get(key, fallback); }
    readonly property string lvBlur:      lv("AllGames Blur Background",       settings.AllGamesBlurBackground)
    readonly property string lvScanlines: lv("AllGames Show scanlines",        settings.AllGamesScanlines)

    property string sortField:   "sortBy"        // sortBy|lastPlayed|rating|releaseYear|favorite
    property int    sortDir:     Qt.AscendingOrder
    property bool   filterOpen:  false
    property int    filterRow:   0
    property string nameFilter:   ""
    property bool   searchActive: false   // on-screen keyboard open
    property bool   favsOnly:     false   // Favorites-only toggle (like platform pages)

    // Genre filter — multi-select (empty array = All)
    property var    genreSelected:    []   // list of selected genre strings
    property bool   genrePickerOpen:  false
    property var    genreOptions:     []   // ["All", ...] built lazily & cached
    property int    genrePickerIndex: 0

    // System/platform filter — single-select; switches the proxy's source model
    property string systemFilter:      ""   // display name ("" = All systems)
    property int    systemIndex:       -1   // api.collections index (-1 = All)
    property bool   systemPickerOpen:  false
    property var    systemOptions:     []   // [{name, index}, ...] built lazily
    property int    systemPickerIndex: 0

    // ── Imported apps ──
    // Apps imported by Pegasus get their icon and nothing else: no screenshot,
    // no 3D box, no logo. They have no such art, and the composite looks broken
    // when two of its three layers are missing.
    //
    // Detected by file path — Pegasus writes imported entries as
    // "android:<package>" — so a ROM or a hand-written .app entry can't match,
    // even sitting in the same collection.
    property bool appIsImported: {
        if (!settledGame || !settledGame.files || settledGame.files.count < 1) return false;
        var p = settledGame.files.get(0).path || "";
        return p.indexOf("android:") === 0;
    }
    property string appIconArt: {
        if (!settledGame || !settledGame.assets) return "";
        var a = settledGame.assets;
        return a.boxFront || a.logo || a.poster || a.banner || "";
    }
    readonly property bool appIconMode: appIsImported && appIconArt !== ""

    // ── Game preview art (miximage-style composite) ──
    // Backdrop = fanart (falls back to a screenshot); framed square = a screenshot.
    property string artBackdrop: {
        if (appIconMode) return appIconArt;
        if (!settledGame) return "";
        var f = Utils.fanArt(settledGame);
        if (f) return f;
        var s2 = settledGame.assets.screenshotList;
        return (s2 && s2.length) ? s2[0] : "";
    }
    property string artScreenshot: {
        if (appIconMode) return appIconArt;
        if (!settledGame) return "";
        var ss = settledGame.assets.screenshotList;
        if (ss && ss.length) return ss[0];
        return Utils.fanArt(settledGame) || "";
    }
    // Both empty in icon mode: each Image hides itself on a non-Ready status.
    property string artLogo: appIconMode ? ""
        : (settledGame ? (Utils.logo(settledGame) || settledGame.assets.logo || "") : "")
    property string artBoxSource: {
        if (appIconMode) return "";
        if (!settledGame) return "";
        var three = Utils.get3dBoxArt(settledGame);
        if (three) return three;                       // 3D box
        return settledGame.assets.boxFront || "";      // 2D fallback
    }
    // SNES & N64 3D box scans are stored landscape — rotate them upright (tall) so
    // they match their miximages. Detected the same way the old scale-down was.
    // A 3D box render wider than it is tall is stood on its side — decided
    // from the image's own proportions, the same rule the box tile uses, so
    // it covers every wide system rather than a named list (this used to
    // match "snes" / "n64" in the collection name). 2D art is never rotated.
    function is3dPath(path) {
        return Utils.is3dFor(settledGame, path);   // Pegasus X list first, then file name
    }
    // Decided from a tiny hidden probe of the same file, NOT from artBoxImg:
    // that image decodes at its own width/height, which swap with this flag,
    // so reading its proportions fed a reload loop (flip -> resize -> reload
    // -> status drops -> flip back). The probe's size never changes.
    Image {
    id: boxProbe
        visible: false
        asynchronous: true
        source: artBoxSource
        sourceSize: Qt.size(hrpx(64), hrpx(64))
    }
    property bool boxRotated: is3dPath(artBoxSource.toString())
                              && boxProbe.status === Image.Ready
                              && boxProbe.implicitWidth > boxProbe.implicitHeight
    property real boxScale: 1.0   // full size (the old SNES/N64 0.88 shrink removed)

    // ── Video preview (plays inside the screenshot frame after a brief rest) ──
    property string videoSource: (currentGame && currentGame.assets && currentGame.assets.videos && currentGame.assets.videos.length > 0) ? currentGame.assets.videos[0] : ""
    property bool   videoArmed:      false
    property bool   videoPlaying:    previewVideo.playbackState === MediaPlayer.PlayingState
    property bool   hideBoxForVideo:  videoPlaying && (listHide === "Box art" || listHide === "Both")
    property bool   hideLogoForVideo: videoPlaying && (listHide === "Logo"    || listHide === "Both")
    Timer {
    id: videoDebounce
        interval: hqAllGamesVideoMs; repeat: false   // HQ: preview starts sooner
        onTriggered: videoArmed = true
    }

    // Heavy preview art (backdrop/screenshot/box/logo) only swaps once the cursor
    // settles, so flicking the list doesn't decode four images on every step.
    // Metadata text stays bound to currentGame (instant); video has its own debounce.
    property var settledGame: null
    // The game the header's system logo follows. While racing it holds still
    // (the logo used to load and decode a different system's PNG on every
    // step) and catches up the moment the race ends.
    // (currentGame lives in theme.qml, so no handler on it here: the game is
    // captured when a race starts, and the binding returns to currentGame
    // when it ends.)
    property var logoHeld: null
    onFastScrollingChanged: {
        if (fastScrolling) logoHeld = currentGame;
        else artDebounce.restart();   // the race is over: let the art catch up
    }
    readonly property var logoGame: fastScrolling ? logoHeld : currentGame
    // While racing, the header logo and the list's preview art still move,
    // just not on every step: they follow the cursor four times a second.
    // At most four decodes per quarter second, instead of a frozen preview
    // for the whole hold (which read as the list being less lively).
    Timer {
        interval: 250; repeat: true
        running: root.fastScrolling
        onTriggered: {
            root.logoHeld = currentGame;
            if (!gridMode) settledGame = currentGame;
        }
    }
    Timer {
    id: artDebounce
        interval: hqAllGamesArtMs; repeat: false      // HQ: art follows the cursor more closely
        // Not while racing: with a slow step the 60 ms rest elapsed between
        // steps and the four preview images were decoded for every row the
        // cursor flew past. They swap once when the race ends.
        onTriggered: if (!fastScrolling) settledGame = currentGame
    }

    function activateSearch() {
        searchActive = true;
        filterKb.page = 0;
        filterKb.shifted = false;
        filterKb.row = 0;
        filterKb.col = 0;
        filterKb.forceActiveFocus();
    }

    property var sortFields: [
        { key: "sortBy",      label: "Title" },
        { key: "lastPlayed",  label: "Last Played" },
        { key: "rating",      label: "Rating" },
        { key: "releaseYear", label: "Release Date" }
    ]

    function selectSort(field) {
        if (sortField === field) {
            sortDir = (sortDir === Qt.AscendingOrder) ? Qt.DescendingOrder : Qt.AscendingOrder;
        } else {
            sortField = field;
            // sensible default direction per field
            sortDir = (field === "lastPlayed" || field === "rating" || field === "favorite")
                      ? Qt.DescendingOrder : Qt.AscendingOrder;
        }
        gamesView.currentIndex = 0;
    }

    // Turn a selected genre into a regex matching it as a whole comma-token
    function genresToPattern(arr) {
        if (!arr || arr.length === 0) return "";
        var parts = [];
        for (var i = 0; i < arr.length; i++)
            parts.push(arr[i].replace(/[.*+?^${}()|[\]\\]/g, "\\$&"));
        return "(^|,\\s*)(" + parts.join("|") + ")(\\s*,|$)";
    }
    // Collect every genre present (comma-split), cached after first build
    function buildGenreOptions() {
        var set = {};
        var n = api.allGames.count;
        for (var i = 0; i < n; i++) {
            var g = api.allGames.get(i);
            if (!g || !g.genre) continue;
            var parts = g.genre.split(",");
            for (var j = 0; j < parts.length; j++) {
                var t = parts[j].trim();
                if (t.length) set[t] = true;
            }
        }
        var arr = Object.keys(set).sort(function(a,b){ return a.toLowerCase().localeCompare(b.toLowerCase()); });
        arr.unshift("All");
        genreOptions = arr;
    }
    function openGenrePicker() {
        if (genreOptions.length === 0) buildGenreOptions();
        var want = (genreSelected.length > 0) ? genreSelected[0] : "All";
        var idx = genreOptions.indexOf(want);
        genrePickerIndex = idx >= 0 ? idx : 0;
        genrePickerOpen = true;
    }
    // Alphabetical letter-jump through the genre picker (mirrors the game list)
    function genreJumpLetter(dir) {
        if (genreOptions.length < 2) return;
        var cur = genrePickerIndex;
        var curL = (genreOptions[cur] || "").charAt(0).toUpperCase();
        if (dir > 0) {
            var i = cur + 1;
            while (i < genreOptions.length && (genreOptions[i] || "").charAt(0).toUpperCase() === curL) i++;
            genrePickerIndex = (i < genreOptions.length) ? i : genreOptions.length - 1;
        } else {
            var j = cur - 1;
            while (j > 0 && (genreOptions[j] || "").charAt(0).toUpperCase() === curL) j--;
            if (j >= 0) {
                var pL = (genreOptions[j] || "").charAt(0).toUpperCase();
                while (j > 0 && (genreOptions[j-1] || "").charAt(0).toUpperCase() === pL) j--;
                genrePickerIndex = j;
            }
        }
    }

    function toggleGenre(g) {
        if (g === "All") { genreSelected = []; gamesView.currentIndex = 0; return; }
        var arr = genreSelected.slice();
        var idx = arr.indexOf(g);
        if (idx >= 0) arr.splice(idx, 1);
        else           arr.push(g);
        genreSelected = arr;            // reassign so bindings re-evaluate
        gamesView.currentIndex = 0;
    }

    // ── System picker ─────────────────────────────────────────────────
    function buildSystemOptions() {
        var arr = [];
        for (var i = 0; i < api.collections.count; i++) {
            var c = api.collections.get(i);
            var nm = (c.name && c.name.length) ? c.name : c.shortName;
            arr.push({ name: (nm || "").toUpperCase(), index: i });
        }
        // Alphabetical by (already-uppercased) display name
        arr.sort(function(a, b) { return (a.name < b.name) ? -1 : ((a.name > b.name) ? 1 : 0); });
        arr.unshift({ name: "ALL", index: -1 });   // keep "All" pinned to the top
        systemOptions = arr;
    }
    function openSystemPicker() {
        if (systemOptions.length === 0) buildSystemOptions();
        var sel = 0;
        for (var i = 0; i < systemOptions.length; i++)
            if (systemOptions[i].index === systemIndex) { sel = i; break; }
        systemPickerIndex = sel;
        systemPickerOpen = true;
    }
    function selectSystem(opt) {
        systemFilter = (opt.index < 0) ? "" : opt.name;
        if (opt.index !== systemIndex) flushGrid();
        systemIndex  = opt.index;
        libraryScope = opt.index;
        gamesView.currentIndex = 0;
        systemPickerOpen = false;
    }
    // Alphabetical letter-jump through the system picker
    function systemJumpLetter(dir) {
        if (systemOptions.length < 2) return;
        var cur = systemPickerIndex;
        var curL = (systemOptions[cur].name || "").charAt(0).toUpperCase();
        if (dir > 0) {
            var i = cur + 1;
            while (i < systemOptions.length && (systemOptions[i].name || "").charAt(0).toUpperCase() === curL) i++;
            systemPickerIndex = (i < systemOptions.length) ? i : systemOptions.length - 1;
        } else {
            var j = cur - 1;
            while (j > 0 && (systemOptions[j].name || "").charAt(0).toUpperCase() === curL) j--;
            if (j >= 0) {
                var pL = (systemOptions[j].name || "").charAt(0).toUpperCase();
                while (j > 0 && (systemOptions[j-1].name || "").charAt(0).toUpperCase() === pL) j--;
                systemPickerIndex = j;
            }
        }
    }

    // Resolve a controller action to its glyph file (assets/images/controller/<hex>.png),
    // matching how ButtonHelpBar maps buttons. Uses if/else (no switch) per QML build quirk.
    function fpBtnArt(action) {
        var bm;
        if      (action === "accept")   bm = api.keys.accept;
        else if (action === "cancel")   bm = api.keys.cancel;
        else if (action === "filters")  bm = api.keys.filters;
        else if (action === "details")  bm = api.keys.details;
        else if (action === "pageUp")   bm = api.keys.pageUp;
        else if (action === "pageDown") bm = api.keys.pageDown;
        else                            bm = api.keys.accept;
        for (var i = 0; i < bm.length; i++) {
            if (bm[i].name().includes("Gamepad")) {
                var v = bm[i].key.toString(16);
                return v.substring(v.length - 1, v.length);
            }
        }
        return "0";
    }

    // Reset every filter/sort back to defaults
    function clearAllFilters() {
        nameFilter  = "";
        genreSelected = [];
        favsOnly    = false;
        systemFilter = "";
        systemIndex  = -1;
        sortField   = "sortBy";
        sortDir     = Qt.AscendingOrder;
        gamesView.currentIndex = 0;
    }

    // ── Display model ─────────────────────────────────────────────────────
    SortFilterProxyModel {
    id: displayModel
        // All systems -> full all-games list; a chosen system -> that collection's games
        sourceModel: systemIndex < 0 ? listAllGames.games : api.collections.get(systemIndex).games
        // By title: A to Z ignoring upper/lower case (see ListCollectionGames)
        sorters: [
            StringSorter {
                roleName: sortField
                caseSensitivity: Qt.CaseInsensitive
                sortOrder: sortDir
                enabled: sortField === "sortBy" || sortField === "title"
            },
            RoleSorter {
                roleName:  sortField
                sortOrder: sortDir
                enabled: sortField !== "sortBy" && sortField !== "title"
            }
        ]
        filters: [
            RegExpFilter {
                roleName: "title"
                pattern: nameFilter
                caseSensitivity: Qt.CaseInsensitive
                enabled: nameFilter !== ""
            },
            RegExpFilter {
                roleName: "genre"
                pattern: genresToPattern(genreSelected)
                caseSensitivity: Qt.CaseInsensitive
                enabled: genreSelected.length > 0
            },
            ValueFilter {
                roleName: "favorite"
                value: true
                enabled: favsOnly
            },
            // An Android system chosen: leave out duplicate Pegasus imports
            // and anything hidden from the library (theme.qml androidHideRows
            // — rows in that collection's own list, which is the source here).
            // All systems is handled inside listAllGames instead.
            ExpressionFilter {
                enabled: Object.keys(systemHideRows).length > 0
                expression: systemHideRows[index] !== true
            }
        ]
    }
    readonly property var systemHideRows: hideRowsForCollection(systemIndex)

    function getCurrentGame(idx) {
        var srcIdx = displayModel.mapToSource(idx);
        if (systemIndex < 0) return listAllGames.currentGame(srcIdx);
        return api.collections.get(systemIndex).games.get(srcIdx);
    }

    // Group key for letter jumping. Every non-alphabetic leading character
    // (digits, brackets, symbols) collapses into a single "#" bucket, matching
    // GridView — otherwise "1943" -> "2048" counted as a letter change and RT
    // stepped through numbers one at a time instead of reaching A.
    function letterGroup(title) {
        var c = (title || "").charAt(0).toUpperCase();
        return (c >= "A" && c <= "Z") ? c : "#";
    }

    // Jump to the first game of the next / previous letter group
    // Lands on an index and, in grid mode, flashes its letter.
    function jumpLand(i) {
        gamesView.currentIndex = i;
        var e = displayModel.get(i);
        if (e) showJumpLetter(e.title);
    }
    function jumpToNextLetter() {
        if (gamesView.count === 0) return;
        var cur = gamesView.currentIndex;
        var curE = cur >= 0 ? displayModel.get(cur) : null;
        var curLtr = curE ? letterGroup(curE.title) : "";
        for (var i = cur + 1; i < gamesView.count; i++) {
            var e = displayModel.get(i);
            if (e && letterGroup(e.title) !== curLtr) { jumpLand(i); return; }
        }
        jumpLand(0);
    }
    function jumpToPrevLetter() {
        if (gamesView.count === 0) return;
        var cur = gamesView.currentIndex;
        if (cur <= 0) { jumpLand(gamesView.count - 1); return; }
        var prevE = displayModel.get(cur - 1);
        var prevLtr = prevE ? letterGroup(prevE.title) : "";
        for (var i = cur - 2; i >= 0; i--) {
            var e = displayModel.get(i);
            if (e && letterGroup(e.title) !== prevLtr) { jumpLand(i + 1); return; }
        }
        jumpLand(0);
    }

    Component.onCompleted: {
        applyPendingScope();    // Home system tile / Library button / return from a game
        // Grid mode's bar reads "Select" (A opens details); it used to start
        // on the list bar ("Launch") whatever the view.
        currentHelpbarModel     = gridMode ? allGamesGridHelpModel : allGamesHelpModel;
        // (A write to the never-declared currentCustomCollection used to sit
        // here; it threw, so nothing below it ever ran.)
        restoreSelection();   // restore the row we were on (if the model is ready)
        settledGame = currentGame;   // show the persisted game's art right away
    }

    // Vertical accent line dividing the text list from the game details

    // ── Game preview (miximage-style): darkened fanart backdrop + framed
    //    square screenshot, with the 3D box overlapping its bottom-left and
    //    the logo straddling its top edge. Border hugs just the screenshot.
    // Preview panel plate, under the fanart. No outline: the panel's edges are
    // the header band, the list column and the page edge.
    Rectangle {
        visible: !gridMode
        anchors.fill: boxArt
        color: "#000000"; opacity: 0.22
        z: -1
    }

    Item {
    id: boxArt
        visible: !gridMode
        anchors {
            // Flush: the list column's edge, the header band, and the page edge.
            top: header.bottom
            left: listSurface.right
            right: parent.right
            bottom: metaPanel.top; bottomMargin: vpx(14)
        }
        clip: true

        // Square screenshot side, sized to the area (leaves room for logo/box overhang)
        property real shotSide: Math.min(height * 0.74, width * 0.56)

        // Darkened fanart backdrop (full-bleed, no border)
        Image {
        id: bgArtImg
            anchors.fill: parent
            asynchronous: true
            sourceSize: Qt.size(width, height)
            source: artBackdrop
            fillMode: Image.PreserveAspectCrop
            smooth: true
            visible: status === Image.Ready && lvBlur !== "Yes"
            opacity: 0.55
        }
        // Blurred backdrop variant (only built when the setting is on)
        Loader {
        id: bgBlurLoader
            anchors.fill: parent
            active: lvBlur === "Yes" && artBackdrop !== ""
            readonly property Item blurSrc: bgArtImg
            sourceComponent: Component {
                FastBlur {
                    cached: true   // static: blur once, not every frame
                    // Big desktop screens: blur at 1080p size and scale up (1 on Android).
                    width: parent.width / hiResScale
                    height: parent.height / hiResScale
                    scale: hiResScale
                    transformOrigin: Item.TopLeft
                    source: bgBlurLoader.blurSrc
                    radius: 64
                    opacity: 0.55
                }
            }
        }
        Rectangle {
            anchors.fill: parent
            color: (bgArtImg.visible || bgBlurLoader.active) ? Qt.rgba(0, 0, 0, 0.45)
                                    : accentA(0.06)
        }

        // Framed square screenshot (shifted slightly right to leave room for the box)
        Item {
        id: shotFrame
            width:  boxArt.shotSide
            height: boxArt.shotSide
            anchors.centerIn: parent
            // The offset exists to leave room for the 3D box overhanging the
            // left. In icon mode there's no box, so it centres properly.
            anchors.horizontalCenterOffset: appIconMode ? 0 : vpx(28)

            Image {
            id: artScreenshotImg
                anchors.fill: parent
                asynchronous: true
                sourceSize: Qt.size(width, height)
                source: artScreenshot
                fillMode: Image.PreserveAspectCrop   // crop to a clean square
                smooth: true
                // Decoded and shown: the screenshot is up.
                readonly property bool shown: status === Image.Ready && !appIconMode
                // Drawn by artShotFx below (rounded in one shader pass, no
                // offscreen layer + mask per settle); shown directly only if
                // the shader can't run.
                visible: shown && artShotFx.failed
            }
            RoundedArt {
            id: artShotFx
                anchors.fill: artScreenshotImg
                source: artScreenshotImg
                crop: true
                radius: vpx(10)
                visible: artScreenshotImg.shown && !failed
            }

            // Imported app icon, filling the square.
            //
            // The image is oversized INSIDE a fixed-size wrapper rather than
            // scaled: `scale` on a layered Image transforms the already-masked
            // result, so the rounded edge scales up too and the icon spills
            // past the frame. Oversizing within a masked wrapper keeps the clip
            // at the frame's real bounds.
            // Imported app: the icon fills the whole panel (rounded) on a shadow
            // plate — the same shadow the tile and launch screen use, flat in
            // base and blurred in HQ. No blur backdrop (the list already has
            // one behind the page) and no accent frame for imports.
            Rectangle {
                visible: appIconWrap.visible
                anchors { fill: appIconWrap; leftMargin: vpx(3); topMargin: vpx(10) }
                radius: appIconWrap.cornerRadius
                color: "#000000"; opacity: hqMode ? 0.55 : 0.35
                layer.enabled: hqMode
                layer.effect: FastBlur { radius: 32; transparentBorder: true; cached: true }
            }
            Item {
            id: appIconWrap

                anchors.fill: parent
                visible: appIconMode && appIconImg.status === Image.Ready
                // Same proportion as the grid tile's appRound (18% of the
                // shorter side), so the two icon styles match instead of the
                // panel looking squarer at its larger size.
                readonly property real cornerRadius: Math.min(width, height) * 0.18
                layer.enabled: visible
                layer.smooth: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle { width: appIconWrap.width; height: appIconWrap.height; radius: appIconWrap.cornerRadius }
                }
                Rectangle { anchors.fill: parent; color: "#2E2E2E" }   // backs transparent corners
                Image {
                id: appIconImg
                    anchors.centerIn: parent
                    // Icons are a circle on a transparent square; blown past the
                    // frame so the visible art fills the rounded panel.
                    width:  parent.width  * 1.45
                    height: parent.height * 1.45
                    source: appIconMode ? artScreenshot : ""
                    sourceSize { width: hrpx(hqMode ? 768 : 512); height: hrpx(hqMode ? 768 : 512) }
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                }
            }
            Rectangle {   // fallback fill when no screenshot (games only — apps have the icon treatment)
                anchors.fill: parent
                visible: !artScreenshotImg.shown && !appIconMode
                radius: vpx(10)
                color: accentA(0.14)
            }
            // Video preview — plays over the screenshot once armed (after resting)
            Video {
            id: previewVideo
                // Stop before the player is destroyed (screen change, row rebuild, or
                // Pegasus unloading the theme to launch a game): destroying a playing
                // video is what the Windows media backend crashes on.
                Component.onDestruction: stop()
                onErrorChanged: reportVideoError(previewVideo)   // logged; see videoUnsupported in theme.qml
                anchors.fill: parent
                anchors.margins: vpx(3)   // inset so the square video corners stay inside the
                                          // rounded screenshot; corners then show the backdrop
                                          // (transparent) without ever masking the video itself
                // HQ: the source is set as soon as the art settles (warm), so
                // the decoder initialises during the rest; play() fires only
                // once the rest has elapsed AND the media is ready — audio and
                // video start together. OFF keeps the original: source on arm,
                // autoPlay, audio a beat ahead of the first frame.
                // Warm only once the cursor has rested (art debounce fired on
                // THIS game), not on every move — otherwise fast scrolling
                // would open and close a decoder per row.
                readonly property bool warm: hqAllGamesWarm && settledGame === currentGame && !root.fastScrolling
                source: (lvVideo !== "No" && (videoArmed || warm) && !root.fastScrolling
                         && videoSource !== "" && playbackOwner === "allgamesscreen" && !gridMode)
                        ? videoSource : ""
                fillMode: VideoOutput.PreserveAspectCrop
                muted: lvSound !== "Yes"
                loops: MediaPlayer.Infinite
                autoPlay: !hqAllGamesWarm
                readonly property bool ready: status === MediaPlayer.Loaded
                                           || status === MediaPlayer.Buffered
                readonly property bool go: hqAllGamesWarm && videoArmed && ready
                                        && playbackOwner === "allgamesscreen"
                onGoChanged:    if (go && playbackState !== MediaPlayer.PlayingState) play()
                onReadyChanged: if (go && playbackState !== MediaPlayer.PlayingState) play()
                // Already invisible until playing, so a warmed-but-idle player
                // never paints black over the screenshot.
                visible: playbackState === MediaPlayer.PlayingState
                // No layer/OpacityMask here: rendering a VideoOutput through an FBO+mask
                // shows audio-only (black frame) on some low-end Android GPUs. Square
                // corners on the playing video are the safe, universal choice.
            }
            // Scanlines overlay (optional)
            Image {
            id: scanlinesOverlay
                anchors.fill: parent
                source: lvScanlines === "Yes" ? "../assets/images/scanlines_v3.png" : ""
                asynchronous: true
                opacity: 0.2
                visible: lvScanlines === "Yes"
                layer.enabled: visible   // no dormant offscreen layer when off
                layer.smooth: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle { width: scanlinesOverlay.width; height: scanlinesOverlay.height; radius: vpx(10) }
                }
            }
            Rectangle {   // border around JUST the screenshot — games only.
                // Imported apps show as the tile does: backdrop + icon, no frame.
                visible: !appIconMode
                anchors.fill: parent
                color: "transparent"
                radius: vpx(10)
                border.color: theme.accent
                border.width: vpx(3)
                antialiasing: true
            }
        }

        // 3D box (2D fallback) — straddles the screenshot's bottom-left corner
        Image {
        id: artBoxImg
            // For rotated systems the pre-rotation box is laid out landscape (w/h
            // swapped) so that after the 90° turn it lands in the same tall footprint.
            width:  boxRotated ? shotFrame.height * 0.66 * boxScale : shotFrame.width  * 0.58 * boxScale
            height: boxRotated ? shotFrame.width  * 0.58 * boxScale : shotFrame.height * 0.66 * boxScale
            anchors {
                horizontalCenter: shotFrame.left
                bottom: shotFrame.bottom; bottomMargin: vpx(2)
            }
            rotation: boxRotated ? 90 : 0       // 90 deg clockwise -> SNES/N64 stand tall
            transformOrigin: Item.Center
            asynchronous: true
            sourceSize: Qt.size(width, height)
            source: artBoxSource
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            // Rotated boxes center vertically (-> horizontal centering once turned),
            // so they sit centered on the screenshot's left edge. Upright boxes keep
            // sitting on the bottom as before.
            verticalAlignment: boxRotated ? Image.AlignVCenter : Image.AlignBottom
            smooth: true
            visible: status === Image.Ready
            opacity: hideBoxForVideo ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }
        }

        // Game logo — sits around the screenshot's top-right corner (right-aligned,
        // vertically straddling the top edge: part above, part on the screenshot)
        Image {
        id: artLogoImg
            width:  shotFrame.width * 0.58
            height: shotFrame.height * 0.34
            anchors {
                right: shotFrame.right; rightMargin: -vpx(6)
                verticalCenter: shotFrame.top
                verticalCenterOffset: vpx(8)
            }
            asynchronous: true
            sourceSize: Qt.size(width, height)
            source: artLogo
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignRight
            verticalAlignment: Image.AlignVCenter
            smooth: true
            visible: status === Image.Ready
            opacity: hideLogoForVideo ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }
        }
    }

    // ── Metadata panel (bottom of right side) ─────────────────────────────
    Item {
    id: metaPanel
        anchors {
            left: gamelist.right; leftMargin: globalMargin
            right: parent.right; rightMargin: globalMargin
            bottom: parent.bottom; bottomMargin: globalMargin + helpMargin
        }
        height: vpx(64)    // one row now; the preview takes the rest
        // Hidden in grid mode (no preview panel) and when nothing is selected.
        visible: !gridMode && currentGame ? true : false

        // One line: Genre | Last Played | Rating. The preview above grows into
        // the space the other two rows used to take. Genre is the only one
        // that can run long, so it takes whatever is left; Last Played
        // ("mm/dd/yyyy" or "Never") and Rating (at most "10.0") sit in fixed
        // compact columns on the right.
        RowLayout {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            height: vpx(42); spacing: vpx(18)
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                Text { id: agGenreLabel
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "Genre: "; font.pixelSize: fpx(17); font.family: subtitleFont.name; font.bold: true; color: theme.accent
                }
                ScrollingText {
                    anchors { left: agGenreLabel.right; right: parent.right; verticalCenter: parent.verticalCenter }
                    text: currentGame && currentGame.genre ? currentGame.genre : "\u2014"
                    font.pixelSize: fpx(17); font.family: subtitleFont.name; color: theme.text
                }
            }
            Rectangle { width: vpx(2); height: vpx(26); color: Qt.rgba(1,1,1,0.18); Layout.alignment: Qt.AlignVCenter }
            Item {
                Layout.preferredWidth: vpx(236); Layout.fillHeight: true
                Text { id: agLastLabel
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "Last Played: "; font.pixelSize: fpx(17); font.family: subtitleFont.name; font.bold: true; color: theme.accent
                }
                ScrollingText {
                    anchors { left: agLastLabel.right; right: parent.right; verticalCenter: parent.verticalCenter }
                    text: fmtLastPlayed(currentGame)
                    font.pixelSize: fpx(17); font.family: subtitleFont.name; color: theme.text
                }
            }
            Rectangle { width: vpx(2); height: vpx(26); color: Qt.rgba(1,1,1,0.18); Layout.alignment: Qt.AlignVCenter }
            Item {
                Layout.preferredWidth: vpx(126); Layout.fillHeight: true
                Text { id: agRatingLabel
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "Rating: "; font.pixelSize: fpx(17); font.family: subtitleFont.name; font.bold: true; color: theme.accent
                }
                ScrollingText {
                    anchors { left: agRatingLabel.right; right: parent.right; verticalCenter: parent.verticalCenter }
                    text: currentGame && currentGame.rating > 0 ? (currentGame.rating * 10).toFixed(1) : "\u2014"
                    font.pixelSize: fpx(17); font.family: subtitleFont.name; color: theme.text
                }
            }
        }
    }

    // ── Custom header (library icon + nav buttons) ────────────────────────
    Item {
    id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(120)   // the band: tall enough that the counter sits inside it
        // Above the grid: the grid is unclipped so its halo can bleed, which
        // also lets rows scrolling up paint over this bar unless it sits higher.
        z: 5

        // Extends down to the accent line, which hangs below this bar's box.
        // Otherwise grid rows scrolling up showed in the gap between the two.
        Rectangle { anchors.fill: parent; color: theme.main }

        // Icon + title (top row) — matches the platform page's clean header rhythm
        // System logo of the highlighted game, top-left, at the Platform page's
        // size and position — the two headers now match. Falls back to the
        // system's name as text when there's no logo image.
        Image {
        id: sysLogo
            anchors { top: parent.top; topMargin: vpx(8); left: parent.left; leftMargin: globalMargin }
            height: vpx(50)
            fillMode: Image.PreserveAspectFit
            source: (logoGame && logoGame.collections.count > 0)
                    ? systemLogoSource(logoGame.collections.get(0))
                    : ""
            visible: status === Image.Ready
            // Decoded at the height it's shown (x2 for sharpness), not the
            // PNG's full size; it was decoded and uploaded full size each time.
            sourceSize.height: Math.round(height * 2)
            smooth: true; asynchronous: true; cache: true
        }
        Text {
            anchors { left: parent.left; leftMargin: globalMargin; top: parent.top; topMargin: vpx(14) }
            // Only once the image has actually FAILED (or there is no image to
            // load). `!sysLogo.visible` also covered the Loading state, so the
            // name flashed for a frame and the logo popped in over it.
            visible: sysLogo.status === Image.Error || sysLogo.source == ""
            text: (logoGame && logoGame.collections.count > 0) ? logoGame.collections.get(0).name : "My Games & Apps"
            color: theme.text; font.family: titleFont.name; font.pixelSize: fpx(24); font.bold: true
        }
        // Game counter: low in the band but clear of its edge, so it survives
        // the UI Scale setting.
        Text {
            anchors { left: parent.left; leftMargin: globalMargin; bottom: parent.bottom; bottomMargin: vpx(14) }
            text: {
                var group = function(n) { var t = String(n), o = ""; while (t.length > 3) { o = "," + t.slice(-3) + o; t = t.slice(0, -3); } return t + o; };
                var n = displayModel.count;
                // A scoped system is the page, not a filter
                var filtered = (nameFilter !== "") || favsOnly || (genreSelected && genreSelected.length > 0);
                var asc = (sortDir === Qt.AscendingOrder);
                var dir;
                switch (sortField) { case "favorite": dir = ""; break; default: dir = asc ? "Ascending" : "Descending"; }
                var sortName = "Title";
                for (var i = 0; i < sortFields.length; i++) if (sortFields[i].key === sortField) sortName = sortFields[i].label;
                return group(n) + " games \u00B7 " + (filtered ? "Filtered" : (sortName + (dir ? " " + dir : "")));
            }
            color: theme.text; opacity: 0.7; font.family: subtitleFont.name; font.pixelSize: fpx(15)
            visible: settings.GameCounter !== "No"   // "Show game count", as on the Platform page
        }

        // Nav buttons (home / discover / achievements / settings)
        Rectangle {
        id: homebutton
            color: "transparent"
            NavPill { focused: homebutton.focus; light: whiteBackground; icon: "../assets/images/icon_home.svg"; iconFilled: "../assets/images/icon_home_fill.svg" }
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -vpx(81) }
            Keys.onDownPressed:  { playNav(); focusGames(); }
            Keys.onRightPressed: { playNav(); discoverbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; showcaseScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); focusGames(); }
                if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); discoverbutton.focus = true; }
                if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); settingsbutton.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: showcaseScreen(); }
        }

        Rectangle {
        id: discoverbutton
            color: "transparent"
            NavPill { focused: discoverbutton.focus; light: whiteBackground; icon: "../assets/images/icon_discover.svg" }
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -vpx(27) }
            Keys.onDownPressed:  { playNav(); focusGames(); }
            Keys.onLeftPressed:  { playNav(); homebutton.focus = true; }
            Keys.onRightPressed: { playNav(); achievementsbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; discoverScreen(scopedColl); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); focusGames(); }
                if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); achievementsbutton.focus = true; }
                if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); homebutton.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: discoverScreen(scopedColl); }
        }

        Rectangle {
        id: achievementsbutton
            color: "transparent"
            NavPill { focused: achievementsbutton.focus; light: whiteBackground; icon: "../assets/images/trophy_outline.svg"; iconFilled: "../assets/images/trophy_fill.svg" }
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: vpx(27) }
            Keys.onDownPressed:  { playNav(); focusGames(); }
            Keys.onLeftPressed:  { playNav(); discoverbutton.focus = true; }
            Keys.onRightPressed: { playNav(); settingsbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; achievementsScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); focusGames(); }
                if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); settingsbutton.focus = true; }
                if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); discoverbutton.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: achievementsScreen(); }
        }

        Rectangle {
        id: settingsbutton
            color: "transparent"
            NavPill { focused: settingsbutton.focus; light: whiteBackground; icon: "../assets/images/settingsicon.svg"; iconFilled: "../assets/images/settingsicon_fill.svg" }
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: vpx(81) }
            Keys.onDownPressed: { playNav(); focusGames(); }
            Keys.onLeftPressed: { playNav(); achievementsbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; settingsScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); focusGames(); }
                if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); homebutton.focus = true; }
                if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); achievementsbutton.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: settingsScreen(); }
        }

        // Nav button labels — shown only when the button is highlighted
        Text {
            text: "Home"
            anchors { top: homebutton.bottom; topMargin: vpx(8); horizontalCenter: homebutton.horizontalCenter }
            color: whiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: fpx(11); font.bold: true
            opacity: homebutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "Discover"
            anchors { top: discoverbutton.bottom; topMargin: vpx(8); horizontalCenter: discoverbutton.horizontalCenter }
            color: whiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: fpx(11); font.bold: true
            opacity: discoverbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "RetroAchievements"
            anchors { top: achievementsbutton.bottom; topMargin: vpx(8); horizontalCenter: achievementsbutton.horizontalCenter }
            color: whiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: fpx(11); font.bold: true
            opacity: achievementsbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "Settings"
            anchors { top: settingsbutton.bottom; topMargin: vpx(8); horizontalCenter: settingsbutton.horizontalCenter }
            color: whiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: fpx(11); font.bold: true
            opacity: settingsbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
    }

    // ── 1. The last row dissolves under the help bar ──────────────────────
    // A fade in the page colour over the bottom of the grid, beneath the
    // prompts, so the cut-off row melts away instead of being chopped by
    // "Apps" and "Launch" sitting on tile art.
    Rectangle {
        anchors { left: parent.left; bottom: parent.bottom }
        // Grid: the whole width, under the tiles. List: just the list column,
        // so the fade doesn't wash over the preview card and info line.
        width: gridMode ? parent.width : listSurface.width
        height: helpMargin + vpx(120)
        z: 6
        opacity: gridFadeOpacity    // part of "Background dimming": Off = no fade
        visible: opacity > 0
        gradient: Gradient {
            // Eased: several stops so the fade starts imperceptibly and only
            // becomes solid under the prompts themselves.
            GradientStop { position: 0.0;  color: Qt.rgba(theme.main.r, theme.main.g, theme.main.b, 0.0)  }
            GradientStop { position: 0.25; color: Qt.rgba(theme.main.r, theme.main.g, theme.main.b, 0.12) }
            GradientStop { position: 0.5;  color: Qt.rgba(theme.main.r, theme.main.g, theme.main.b, 0.45) }
            GradientStop { position: 0.75; color: Qt.rgba(theme.main.r, theme.main.g, theme.main.b, 0.85) }
            GradientStop { position: 1.0;  color: theme.main }
        }
    }

    // ── 2. Depth under the header band ────────────────────────────────────
    // A few pixels of soft darkening on the surface just below the band, so
    // the band reads as sitting ON the content rather than beside it. Not an
    // accent line — a shadow. Goes away with dimming Off.
    Rectangle {
        anchors { top: header.bottom; left: parent.left; right: parent.right }
        height: vpx(14)
        z: 4
        visible: gridDimOpacity > 0
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.35) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
        }
    }

    // ── Content surface ───────────────────────────────────────────────────
    // Everything below the header band sits on the dimmed surface; the band/
    // surface contrast is the separator (no accent lines). The list column
    // gets a slightly deeper surface of its own so the two regions read as
    // two things. Flat rectangles: no texture, no shader.
    Rectangle {
        anchors { top: header.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        // z: -1 is REQUIRED here: the preview block is declared before the
        // header, so by order alone this surface would paint over it (the
        // dimmed preview you saw). This file has no root-level fill, so
        // sending the surface to the bottom is safe. (The RA pages differ —
        // they have a root fill, so there order is used instead.)
        color: "#000000"; opacity: gridDimOpacity; visible: opacity > 0; z: -1
    }
    Rectangle {
    id: listSurface
        visible: !gridMode
        anchors { top: header.bottom; left: parent.left; bottom: parent.bottom }
        // Ends in the gap before the preview card (which reaches vpx(10) left
        // of the preview), so the two surfaces never overlap.
        // Fixed, NOT derived from the list: the list now takes ITS width from
        // this surface (so the highlight spans the column), and deriving this
        // from the list made a loop that collapsed both to zero.
        width: vpx(400) + globalMargin - vpx(16)
        color: "#000000"; opacity: 0.16; z: -1
    }

    // ── Game list ─────────────────────────────────────────────────────────
    ListView {
    id: gamelist
        visible: !gridMode
        focus: !gridMode
        currentIndex: currentGameIndex
        // HQ: keep a few rows built past each edge so fast scrolling doesn't
        // build delegates on the fly. 0 (the default) leaves the list as it
        // was, so HQ off changes nothing here.
        cacheBuffer: itemheight * hqAllGamesCacheRows

        onCurrentIndexChanged: {
            if (currentIndex !== -1) {
                currentGameIndex = currentIndex;
                currentGame = getCurrentGame(currentIndex);
                storedAllGamesIndex = currentIndex;   // persist across screen reloads
                root.videoArmed = false;              // stop video while navigating
                videoDebounce.restart();              // re-arm after resting on a game
                artDebounce.restart();                // swap preview art after resting
            }
        }
        // The proxy model populates asynchronously; when it first fills,
        // restore the previously-selected row (so returning from game details
        // lands back on the same game) — then keep the current row in sync.
        onCountChanged: {
            if (count > 0) {
                if (!root._restoredIndex) { root.restoreSelection(); }
                else {
                    if (currentIndex < 0) currentIndex = 0;
                    currentGame = getCurrentGame(currentIndex < 0 ? 0 : currentIndex);
                }
                settledGame = currentGame;   // initial/restore: show art immediately
            }
        }

        Keys.onUpPressed: {
            event.accepted = true;
            if (gridRepeatBlocked(event)) return;   // same frame pacing as the grid
            playNav(); noteGridNav();
            if (currentIndex !== 0) currentIndex--;
            else homebutton.focus = true;
        }
        // Down/Left/Right handled here (not at root) because a focused vertical
        // ListView consumes Down internally before the root handler can fire —
        // which is why the nav sound was intermittent. accepted=true stops the
        // built-in navigation from double-moving.
        Keys.onDownPressed: {
            event.accepted = true;
            if (gridRepeatBlocked(event)) return;   // same frame pacing as the grid
            playNav(); noteGridNav();
            if (currentIndex !== count - 1) currentIndex++;
            else currentIndex = 0;
        }
        Keys.onLeftPressed: {
            event.accepted = true;
            if (gridRepeatBlocked(event)) return;   // same frame pacing as the grid
            playNav(); noteGridNav();
            // Page up by skipnum, but wrap to the END of the list when already
            // sitting on the first game (Up still reaches the nav buttons).
            if (currentIndex === 0) currentIndex = count - 1;
            else currentIndex = Math.max(0, currentIndex - skipnum);
        }
        Keys.onRightPressed: {
            event.accepted = true;
            if (gridRepeatBlocked(event)) return;   // same frame pacing as the grid
            playNav(); noteGridNav();
            currentIndex = Math.min(count - 1, currentIndex + skipnum);
        }

        // Column bounds: the top edge is the header band, the bottom sits just
        // above the help bar, so no row is ever half-visible under either.
        // (It used to run to the page bottom, beneath the prompts. The list's
        // existing clip: true, below, does the clipping.)
        anchors {
            top: header.bottom
            bottom: parent.bottom; bottomMargin: helpMargin + vpx(6)
            left: parent.left
        }
        width: listSurface.width
        spacing: vpx(0); orientation: ListView.Vertical
        preferredHighlightBegin: gamelist.height / 2 - itemheight
        preferredHighlightEnd:   gamelist.height / 2
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: animMs(100)
        clip: true

        model: displayModel

        delegate: Component {
            Item {
                width: ListView.view.width
                height: itemheight
                property bool selected: ListView.isCurrentItem && gamelist.activeFocus

                // Runs the full column width so it meets the preview art
                // (anchored to listSurface.right), rounded on both ends.
                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top; topMargin: vpx(4)
                        bottom: parent.bottom; bottomMargin: vpx(4)
                    }
                    radius: vpx(6)
                    color: theme.accent
                    visible: selected
                }
                Item {
                    id: titleClip
                    height: parent.height
                    anchors {
                        left: parent.left; leftMargin: vpx(20)
                        right: parent.right; rightMargin: vpx(30)
                    }
                    clip: true
                    // Measures the full title at the selected font size, independently of
                    // the visible Text. implicitWidth gets clamped to the elided width once
                    // ElideRight has been active, which made the marquee stop short.
                    TextMetrics {
                        id: titleMetrics
                        font.family: subtitleFont.name
                        font.pixelSize: fpx(25)
                        font.bold: true
                        text: modelData.title
                    }
                    Text {
                        id: titleText
                        text: modelData.title
                        height: titleClip.height
                        color: selected ? "white" : theme.text
                        font.family: subtitleFont.name
                        font.pixelSize: selected ? fpx(25) : fpx(19)
                        font.bold: selected
                        verticalAlignment: Text.AlignVCenter
                        opacity: selected ? 1 : 0.28
                        Behavior on font.pixelSize { NumberAnimation { duration: 90 } }
                        // Only the highlighted row scrolls, and only when it overflows.
                        property real overflow: titleMetrics.width - titleClip.width
                        property bool marquee: selected && overflow > 0
                        elide: marquee ? Text.ElideNone : Text.ElideRight
                        width: marquee ? titleMetrics.width : titleClip.width
                        x: 0
                        onMarqueeChanged: if (!marquee) x = 0
                        SequentialAnimation on x {
                            running: titleText.marquee
                            loops: Animation.Infinite
                            PauseAnimation { duration: 1100 }
                            NumberAnimation {
                                to: -(titleText.overflow + vpx(6))
                                duration: Math.max(600, (titleText.overflow + vpx(6)) * 11)
                                easing.type: Easing.InOutSine
                            }
                            PauseAnimation { duration: 1300 }
                            NumberAnimation { to: 0; duration: 550; easing.type: Easing.InOutSine }
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { if (selected) gameDetails(currentGame); else gamelist.currentIndex = index; }
                }
            }
        }
    }

    // Wheel moves the selection in list mode too.
    WheelNav {
        anchors.fill: gamelist
        view: gamelist
        columns: 1
        active: !gridMode && !filterOpen
        onStepped: function(quiet) { if (!quiet) playNav(); }
    }

    // ── Letter jump overlay ───────────────────────────────────────────────
    // The platform grid's: the target letter, large, over a theme-coloured
    // wash that holds half a second then fades. Grid mode only — the list has
    // its preview panel and never showed one.
    Rectangle {
    id: navigationOverlay
        anchors.fill: parent
        color: theme.main
        opacity: 0
        z: 20
        Text {
        id: navigationLetter
            antialiasing: true
            renderType: Text.NativeRendering
            font.hintingPreference: Font.PreferNoHinting
            font.family: titleFont.name
            font.capitalization: Font.AllUppercase
            font.pixelSize: fpx(200)
            color: "white"
            anchors.centerIn: parent
        }
        SequentialAnimation {
        id: navigationLetterOpacityAnimator
            PauseAnimation { duration: 500 }
            OpacityAnimator { target: navigationOverlay; from: navigationOverlay.opacity; to: 0; duration: hqMode ? 400 : 500 }
        }
    }
    function showJumpLetter(title) {
        if (!gridMode) return;
        var ch = letterGroup(title);
        navigationLetterOpacityAnimator.running = false;
        navigationLetter.text = (ch === "#" ? "#" : ch.toUpperCase());
        navigationOverlay.opacity = 0.8;
        navigationLetterOpacityAnimator.running = true;
    }

    // ── Grid view ─────────────────────────────────────────────────────────
    // Full page: no preview panel. Same model and index as the list above.
    // A ListView of rows (Global/RowGrid), not a GridView: Qt 5.15's GridView
    // never recycles tiles, so a held D-pad built and destroyed a row of them
    // per step. Rows recycle; their tiles only rebind. currentIndex and
    // count are still the flat GAME index and count.
    RowGrid {
    id: gamegrid

        visible: gridMode
        focus: gridMode
        anchors {
            top: header.bottom; topMargin: globalMargin
            left: parent.left; leftMargin: globalMargin
            right: parent.right; rightMargin: globalMargin
            bottom: parent.bottom; bottomMargin: globalMargin + helpMargin
        }
        model: (gridMode && !gridFlushing) ? displayModel : 0
        resolve: getCurrentGame
        currentIndex: currentGameIndex
        columns: gridColumns
        cellWidth:  gridCellW
        cellHeight: gridCellH
        titleMargin: gridTitleMargin
        // Tiles fade in when the page opens, as on the Platform grid. HQ a
        // little longer and eased; base matches the Platform grid exactly.
        populateDuration: hqMode ? 260 : 200
        populateEasing: hqMode ? Easing.OutQuad : Easing.Linear
        // Look-ahead rows, built in the background a few per frame. Tiles
        // born mid-race hold off loading their art (deferArt), so keeping
        // the look-ahead costs no decoding.
        cacheBuffer: gridCellH * (hqMode ? 1.0 : 0.5)
        highlightMoveDuration: root.fastScrolling ? 0 : animMs(200)   // snap while racing; matches the Platform grid at rest

        // Video previews live in the highlight, exactly as on the platform
        // grid. Follows the All Games video setting and the coordinator.
        highlightItem: Component {
            ItemHighlight {
                ownScreen: "allgamesscreen"
                width: gamegrid.cellWidth
                height: gamegrid.cellHeight - gridTitleMargin   // the tile's own height
                game: currentGame
                selected: gamegrid.focus
                boxArt: gridBoxArt
                playVideo: lvVideo !== "No" && !boxArt
                racing: root.fastScrolling
                allowAudio: lvSound === "Yes"   // Library sound (Settings › Previews & sound)
            }
        }

        // Everything the list does on an index change. currentGame is NOT
        // derived from the index — the list assigns it here — so the grid must
        // too, or the highlight video, the system logo and the audio all stay
        // frozen on whatever game the list last set.
        onCurrentIndexChanged: {
            if (currentIndex !== -1) {
                currentGameIndex = currentIndex;
                currentGame = getCurrentGame(currentIndex);
                storedAllGamesIndex = currentIndex;
                root.videoArmed = false;
                videoDebounce.restart();
                artDebounce.restart();
            }
        }

        // Two tile components, swapped by tile style — the same structure the
        // Platform grid used. Each is created by the row's Repeater: `index`
        // is the COLUMN, `parent` the row (parent.rowIndex); the flat index
        // and the game come from those. The tile is not the view's delegate
        // any more, so nothing here uses GridView attached properties.
        tile: gridBoxArt ? boxTileDelegate : dynamicTileDelegate

        Component {
        id: boxTileDelegate
            BoxArtGridItem {
                readonly property int flatIndex: (parent ? parent.rowIndex : 0) * gridColumns + index
                x: index * gridCellW
                width:  gridCellW
                height: gridCellH - gridTitleMargin
                gameData: gamegrid.gameAt(flatIndex)
                // A row's last cells past the end of the games are empty.
                visible: !!gameData
                selected: flatIndex === gamegrid.currentIndex && gamegrid.focus
                reduceMotion: root.fastScrolling
                deferArt: root.fastScrolling
                onScreen: parent ? parent.onScreen === true : true
                columns: gridColumns
                artStyle: tileStyle
                titleMode: tileTitles
                // The tile's own Keys handler consumes A (when it has focus)
                // and emits this; the page's Keys.onPressed covers the rest.
                onActivate: {
                    if (selected) activateCurrent();
                    else          gamegrid.currentIndex = flatIndex;   // mouse/touch on another tile
                }
                // Mouse hover (Settings > General > Enable mouse hover) moves
                // the selection, as on Home. The tile played its nav sound but
                // the Library never listened, so hover did nothing here.
                onHighlighted: if (!selected) gamegrid.currentIndex = flatIndex
            }
        }
        Component {
        id: dynamicTileDelegate
            DynamicGridItem {
                readonly property int flatIndex: (parent ? parent.rowIndex : 0) * gridColumns + index
                x: index * gridCellW
                width:  gridCellW
                height: gridCellH - gridTitleMargin
                gameData: gamegrid.gameAt(flatIndex)
                visible: !!gameData
                selected: flatIndex === gamegrid.currentIndex && gamegrid.focus
                titleMode: tileTitles
                artMode: tileArt
                showLogo: tileLogo === "Yes"
                playVideo: gameData ? (gameData.assets.videoList.length
                           && lvVideo !== "No") : false
                hideLogoOnVideo: gridHideLogo
                ownScreen: "allgamesscreen"
                reduceMotion: root.fastScrolling
                deferArt: root.fastScrolling
                onScreen: parent ? parent.onScreen === true : true
                titleWhilePending: true
                onActivated: {
                    if (selected) activateCurrent();
                    else          gamegrid.currentIndex = flatIndex;
                }
                onHighlighted: if (!selected) gamegrid.currentIndex = flatIndex   // mouse hover
            }
        }

        // Up/Down move a row; Left/Right a tile. Left at the row start and
        // right at its end wrap, matching the list's behaviour.
        // Up: a row up, or into the header from the top row. Down from the
        // last row wraps to the same column on the first row. Left/Right wrap
        // end-to-end. All mirror the platform grid's feel.
        Keys.onUpPressed: {
            if (gridRepeatBlocked(event)) { event.accepted = true; return; }
            playNav(); noteGridNav();
            if (currentIndex - gridColumns >= 0) currentIndex -= gridColumns;
            else homebutton.focus = true;
        }
        Keys.onDownPressed: {
            if (count === 0) return;
            if (gridRepeatBlocked(event)) { event.accepted = true; return; }
            playNav(); noteGridNav();
            // Same rule as the Platform grid: "last row" is anything with no
            // full row beneath it (the last row is often partial). From there
            // wrap to the first row in the same column; otherwise step down.
            var lastRowStart = Math.floor((count - 1) / gridColumns) * gridColumns;
            if (currentIndex >= lastRowStart) currentIndex = currentIndex % gridColumns;
            else currentIndex = Math.min(count - 1, currentIndex + gridColumns);
        }
        Keys.onLeftPressed: {
            if (count === 0) return;
            if (gridRepeatBlocked(event)) { event.accepted = true; return; }
            playNav(); noteGridNav();
            currentIndex = (currentIndex > 0) ? currentIndex - 1 : count - 1;
        }
        Keys.onRightPressed: {
            if (count === 0) return;
            if (gridRepeatBlocked(event)) { event.accepted = true; return; }
            playNav(); noteGridNav();
            currentIndex = (currentIndex < count - 1) ? currentIndex + 1 : 0;
        }
    }

    // Wheel moves the selection (see WheelNav) — a sibling of the grid.
    WheelNav {
        anchors.fill: gamegrid
        view: gamegrid
        columns: gridColumns
        active: gridMode && !filterOpen
        onStepped: function(quiet) { if (!quiet) playNav(); noteGridNav(); }
    }

    // ── Sorting & Filters overlay ─────────────────────────────────────────
    // ── Quick settings panel (Y in list or grid mode) ────────────────────
    // The same idea as the Platform page's per-system panel: this page's rows
    // from Settings, changed on the fly. One panel, two row sets — the list
    // rows or the grid rows, whichever mode is showing. Y again goes on to the
    // full theme settings; B closes.
    //
    // `order` is the row's option string EXACTLY as the Settings page declares
    // it. The Settings page draws a row from "<key>Index" (not from the
    // value), so the index has to be written in ITS order, not the panel's —
    // that was the "panel says Yes, Settings says No" bug: the four "No,Yes"
    // rows were being indexed as "Yes,No".
    property bool listPanelOpen: false
    property int  listRow: 0
    // Rows for the panel. `order` is the option string exactly as the Settings
    // page declares the row (it draws from "<key>Index"); null = no Settings row.
    readonly property var tileShapes: ["Wide","Tall","Square","Box Art","3D Box"]
    readonly property var listRows: [
        { key: "All Games View",              label: "View",               opts: ["List","Grid"], order: "List,Grid", dflt: allView },
        { key: "AllGames Blur Background",    label: "Blurred background", opts: ["Yes","No"], order: "No,Yes", dflt: settings.AllGamesBlurBackground, group: "List view" },
        { key: "AllGames Show scanlines",     label: "Scanlines",          opts: ["Yes","No"], order: "No,Yes", dflt: settings.AllGamesScanlines }
    ]
    // Settings stores the ratio list in a jumbled order (0.66–0.99 first,
    // then 0.25–0.65); the panel steps through it in numeric order and the
    // index lookup below maps back into Settings' order.
    readonly property string ratioOrder: "0.66,0.67,0.68,0.69,0.70,0.71,0.72,0.73,0.74,0.75,0.76,0.77,0.78,0.79,0.80,0.81,0.82,0.83,0.84,0.85,0.86,0.87,0.88,0.89,0.90,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,0.99,0.25,0.26,0.27,0.28,0.29,0.30,0.31,0.32,0.33,0.34,0.35,0.36,0.37,0.38,0.39,0.40,0.41,0.42,0.43,0.44,0.45,0.46,0.47,0.48,0.49,0.50,0.51,0.52,0.53,0.54,0.55,0.56,0.57,0.58,0.59,0.60,0.61,0.62,0.63,0.64,0.65"
    readonly property var ratioOpts: { var a = []; for (var i = 25; i <= 99; i++) a.push("0." + i); return a; }
    readonly property var gridRows: [
        { key: "All Games View",          label: "View",          opts: ["List","Grid"], order: "List,Grid", dflt: allView },
        { key: "AllGames Tile Style",     label: "Tile shape",    opts: tileShapes, order: "Wide,Tall,Square,Box Art,3D Box", dflt: allStyle },
        { key: "AllGames Tile Ratio",     label: "Tile ratio",    opts: ratioOpts, order: ratioOrder, dflt: allRatio },
        { key: "AllGames Items per row",  label: "Tiles per row", opts: ["3","4","5","6","7","8"], order: "3,4,5,6,7,8", dflt: allColumns },
        { key: "AllGames Tile Art",       label: "Tile art",      opts: ["Fanart","Screenshot","Boxfront"], order: "Fanart,Screenshot,Boxfront", dflt: allArt },
        { key: "AllGames Tile Logo",      label: "Logo on tile",  opts: ["Yes","No"], order: "Yes,No", dflt: allLogo },
        { key: "AllGames Tile titles",    label: "Tile titles",   opts: ["On focus","Always","Never"], order: "On focus,Always,Never", dflt: allTitles }
    ]
    // A system. Row 0 says whether it follows Systems or has its own; the
    // rest show what it uses either way (`sys` is the per-system row name,
    // `base` what Systems uses). Changing any row gives it its own settings.
    // Every per-system row, whichever view: what makeSysOwn() copies.
    readonly property var sysAllRows: [
        { key: sysKey + " - View",               sys: "View",              label: "View",          opts: ["List","Grid"], order: null, base: sysView },
        { key: sysKey + " - Tile shape",         sys: "Tile shape",        label: "Tile shape",    opts: tileShapes, order: null, base: sysStyle },
        { key: sysKey + " - Tile ratio",         sys: "Tile ratio",        label: "Tile ratio",    opts: ratioOpts, order: null, base: sysRatio },
        { key: sysKey + " - Tiles per row",      sys: "Tiles per row",     label: "Tiles per row", opts: ["3","4","5","6","7","8"], order: null, base: sysColumns },
        { key: sysKey + " - Tile art",           sys: "Tile art",          label: "Tile art",      opts: ["Fanart","Screenshot","Boxfront"], order: null, base: sysArt },
        { key: sysKey + " - Show logo on tile",  sys: "Show logo on tile", label: "Logo on tile",  opts: ["Yes","No"], order: null, base: sysTileLogo },
        { key: sysKey + " - Game tile titles",   sys: "Game tile titles",  label: "Tile titles",   opts: ["On focus","Always","Never"], order: null, base: sysTitles }
    ]
    function sysRow(name) { for (var i = 0; i < sysAllRows.length; i++) if (sysAllRows[i].sys === name) return sysAllRows[i]; return null; }
    readonly property var sysOwnRow: ({ key: "__own", label: "Settings", opts: ["Follow Systems","Its own"], order: null, dflt: "Follow Systems" })
    // The panel mirrors All Games': the grid rows in grid view, the list
    // rows (with the shared Blurred background and Scanlines) in list view.
    readonly property var sysGridPanelRows: [sysOwnRow].concat(
        ["View","Tile shape","Tile ratio","Tiles per row","Tile art","Show logo on tile","Game tile titles"].map(sysRow))
    readonly property var sysListPanelRows: [sysOwnRow].concat(
        ["View"].map(sysRow),
        [ { key: "AllGames Blur Background", label: "Blurred background", opts: ["Yes","No"], order: "No,Yes", dflt: settings.AllGamesBlurBackground, group: "List view" },
          { key: "AllGames Show scanlines",  label: "Scanlines",          opts: ["Yes","No"], order: "No,Yes", dflt: settings.AllGamesScanlines } ])
    readonly property var panelRows: scoped ? (lvView === "Grid" ? sysGridPanelRows : sysListPanelRows) : (gridMode ? gridRows : listRows)
    function listValue(row) {
        var e = listEpoch; var r = panelRows[row];
        if (r.key === "__own") return sysOwn() ? "Its own" : "Follow Systems";
        if (r.sys) return sysPref(r.sys, String(r.base));
        return settingsStore.get(r.key, String(r.dflt));
    }
    function rowValue(key) {
        for (var i = 0; i < panelRows.length; i++) if (panelRows[i].key === key) return listValue(i);
        return "";
    }
    // Greying, the same rules as Settings.
    function listRowDisabled(row) {
        var e = listEpoch; var r = panelRows[row], k = r.key;
        var label = r.label;
        if (label === "Sound" || label === "Hide logo while it plays" || label === "While it plays, hide") {
            var prev = rowValue(scoped ? sysKey + " - Video preview" : "AllGames Video preview");
            if (prev === "No") return true;
            if (label === "Hide logo while it plays"
                && rowValue(scoped ? sysKey + " - Show logo on tile" : "AllGames Tile Logo") === "No") return true;
        }
        var shape = rowValue(scoped ? sysKey + " - Tile shape" : "AllGames Tile Style");
        if (label === "Tile art" || label === "Logo on tile") return shape === "Box Art" || shape === "3D Box";
        if (label === "Tile ratio") return shape === "Square";
        return false;
    }
    // Writes the value AND the index the Settings page draws its row from.
    function panelWrite(key, v, order) {
        settingsStore.set(key, v);
        if (!order) return;                      // per-system keys: no Settings row
        var oi = order.split(",").indexOf(String(v));
        if (oi >= 0) settingsStore.set(key + "Index", oi);
    }
    // A system following Systems gets its own settings, starting from
    // exactly what it shows now.
    function makeSysOwn() {
        if (sysOwn()) return;
        for (var i = 0; i < sysAllRows.length; i++) {
            var r = sysAllRows[i];
            settingsStore.set(r.key, String(r.base));
        }
        settingsStore.set(sysKey + " - Use theme settings", "No");
    }
    function sysFollow() {
        settingsStore.set(sysKey + " - Use theme settings", "Yes");
        listEpoch++; settingsEpoch++;
    }
    function listCycle(row, dir) {
        if (listRowDisabled(row)) return;
        var r = panelRows[row], opts = r.opts, i = opts.indexOf(listValue(row)); if (i < 0) i = 0;
        var ni = (i + dir + opts.length) % opts.length, v = opts[ni];
        var oldView = lvView;
        if (r.key === "__own") {
            if (v === "Its own") makeSysOwn(); else settingsStore.set(sysKey + " - Use theme settings", "Yes");
        } else if (r.sys) {
            makeSysOwn();
            settingsStore.set(r.key, v);
            if (r.sys === "Tile art" && v === "Boxfront") settingsStore.set(sysKey + " - Show logo on tile", "No");
        } else {
            panelWrite(r.key, v, r.order);
            // Same rule as Settings: box-front art already carries the name.
            if (r.key === "AllGames Tile Art" && v === "Boxfront") panelWrite("AllGames Tile Logo", "No", "Yes,No");
        }
        listEpoch++; settingsEpoch++; playNav();
        // Flipping the view can swap the row set; the incoming view's focus
        // binding grabs focus as it appears, so take it back and stay on
        // the row just changed.
        if (lvView !== oldView) {
            var vr = 0;
            for (var pi = 0; pi < panelRows.length; pi++) if (panelRows[pi].key === r.key) { vr = pi; break; }
            listRow = vr; listPanel.forceActiveFocus();
        }
    }
    function listStep(dir) {
        var n = panelRows.length, i = listRow, tries = 0;
        do { i = (i + dir + n) % n; tries++; } while (listRowDisabled(i) && tries < n);
        listRow = i; playNav();
    }

    Rectangle {
    id: listPanel
        visible: listPanelOpen; z: 31
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.66)
        focus: listPanelOpen
        // hoverEnabled + onWheel: tiles under the open panel don't light up or scroll.
        MouseArea { anchors.fill: parent; hoverEnabled: true; onWheel: wheel.accepted = true; onClicked: { listPanelOpen = false; focusGames(); } }
        // ── The panel, Xbox 2023 style ──────────────────────────────────────
        // A charcoal card with a hairline edge; rows are the same cards as
        // Settings (focus ring included); accent caps name each group.
        Rectangle {
        id: ypanel
            anchors.centerIn: parent
            // Xbox pop-up proportions: ~690 px wide at 1080p, 64 px rows.
            width: vpx(460)
            height: Math.min(parent.height - vpx(96), headBlock.height + rowCol.height + vpx(108))
            radius: vpx(6)
            color: "#1f1f1f"
            border.width: Math.max(1, vpx(1)); border.color: "#3a3a3a"
            // The wheel steps the panel's rows.
            MouseArea { anchors.fill: parent; onWheel: { wheel.accepted = true; listStep(wheel.angleDelta.y > 0 ? -1 : 1); } }

            Column {
            id: headBlock
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: vpx(28) }
                spacing: vpx(5)
                Row {
                    spacing: vpx(12)
                    Text {
                        text: scopedColl ? scopedColl.name : "All Games"; color: "white"
                        font.family: titleFont.name; font.pixelSize: vpx(26); font.bold: true
                    }
                    // A system: does it follow Systems or have its own?
                    Rectangle {
                        visible: scoped
                        anchors.verticalCenter: parent.verticalCenter
                        readonly property bool own: { var e = listEpoch; return scoped && sysOwn(); }
                        width: tagText.width + vpx(14); height: vpx(19); radius: vpx(3)
                        color: own ? accentA(0.16) : "#2c2c2c"
                        Text {
                        id: tagText
                            anchors.centerIn: parent
                            text: parent.own ? "OWN SETTINGS" : "FOLLOWS SYSTEMS"
                            color: parent.own ? theme.accent : "#a8a8a8"
                            font { family: subtitleFont.name; pixelSize: vpx(10.5); bold: true; letterSpacing: vpx(1) }
                        }
                    }
                }
                Text {
                    width: parent.width
                    text: { var e = listEpoch;
                            return scoped ? (sysOwn() ? "These change " + (scopedColl ? scopedColl.name : "this system") + " only."
                                                      : "Showing what Systems uses. Change any row to give " + (scopedColl ? scopedColl.name : "this system") + " its own settings.")
                                          : "These change All Games only. Systems keep their own."; }
                    color: "#a9a9a9"; font.family: subtitleFont.name; font.pixelSize: vpx(13.5)
                    wrapMode: Text.WordWrap
                }
            }

            // Rows scroll inside the card when they outgrow it; the focus
            // ring sits just outside a row, so the clip leaves room for it.
            Flickable {
            id: rowFlick
                anchors { left: parent.left; right: parent.right; top: headBlock.bottom; bottom: footer.top
                          topMargin: vpx(10); bottomMargin: vpx(8); leftMargin: vpx(20); rightMargin: vpx(20) }
                clip: true; interactive: false
                contentHeight: rowCol.height + vpx(12)
                Behavior on contentY { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                function keepRowVisible() {
                    var it = rowRep.itemAt(listRow); if (!it) return;
                    var pad = vpx(8), y = it.y, h = it.height, maxY = Math.max(0, contentHeight - height);
                    // Show the group name above the first row of a group too.
                    if (y - pad < contentY) contentY = Math.max(0, Math.min(y - pad, maxY));
                    else if (y + h + pad > contentY + height) contentY = Math.min(y + h + pad - height, maxY);
                }
                readonly property int watchRow: listRow
                onWatchRowChanged: keepRowVisible()
                onContentHeightChanged: { contentY = 0; Qt.callLater(keepRowVisible); }   // row set swapped (view flip)
            Column {
            id: rowCol
                x: vpx(6); y: vpx(6)
                width: parent.width - vpx(12)
                spacing: vpx(5)
                Repeater {
                id: rowRep
                    model: panelRows.length
                    delegate: Item {
                    id: prow
                        readonly property var r: panelRows[index]
                        readonly property bool cur: index === listRow && listPanel.activeFocus
                        readonly property bool dis: { var e = listEpoch; return listRowDisabled(index); }
                        readonly property bool isOwn: r.key === "__own"
                        // Group name above the row that starts a group.
                        readonly property real groupH: r.group ? vpx(30) : 0
                        width: rowCol.width
                        height: groupH + card.height
                        // y of the card itself, for keepRowVisible
                        Text {
                            visible: !!r.group
                            anchors { left: parent.left; leftMargin: vpx(2); bottom: card.top; bottomMargin: vpx(7) }
                            text: (r.group || "").toUpperCase()
                            color: theme.accent
                            font { family: subtitleFont.name; pixelSize: vpx(11.5); bold: true; letterSpacing: vpx(1.2) }
                        }
                        Rectangle {
                        id: card
                            y: prow.groupH
                            width: parent.width
                            height: isOwn ? vpx(52) : vpx(43)
                            radius: vpx(4)
                            color: cur ? "#2e2e2e" : "#262626"
                            opacity: dis ? 0.38 : 1
                            Column {
                                anchors { left: parent.left; leftMargin: vpx(15); verticalCenter: parent.verticalCenter }
                                spacing: vpx(1)
                                Text { text: r.label; color: "white"; font.family: subtitleFont.name; font.pixelSize: vpx(16) }
                                Text { visible: isOwn; text: "Follow Systems / Its own"; color: "#8e8e8e"; font.family: subtitleFont.name; font.pixelSize: vpx(11.5) }
                            }
                            Row {
                                anchors { right: parent.right; rightMargin: vpx(13); verticalCenter: parent.verticalCenter }
                                spacing: vpx(9)
                                Text { text: "‹"; color: "#8a8a8a"; font.family: subtitleFont.name; font.pixelSize: vpx(16); anchors.verticalCenter: parent.verticalCenter }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: { var e = listEpoch; var v = listValue(index); return v === "Yes" ? "On" : v === "No" ? "Off" : v; }
                                    color: "white"; font.family: subtitleFont.name; font.pixelSize: vpx(15); font.bold: true
                                }
                                Text { text: "›"; color: "#8a8a8a"; font.family: subtitleFont.name; font.pixelSize: vpx(16); anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                        Loader {
                            x: card.x; y: card.y; width: card.width; height: card.height
                            active: prow.cur
                            z: 2
                            sourceComponent: Item { FocusFrame { anchors.fill: parent; artRadius: vpx(4); glowStrength: tileHaloLive ? 0.45 : 0 } }   // glow honours Frame glow
                        }
                        // Mouse: hover picks the row, a click on it changes it.
                        MouseArea {
                            x: card.x; y: card.y; width: card.width; height: card.height
                            hoverEnabled: settings.MouseHover == "Yes"
                            function hoverPick() { if (pointerMoved() && listRow !== index && !prow.dis) { listRow = index; playNav(); } }
                            onEntered: hoverPick()
                            onPositionChanged: hoverPick()   // entered can arrive before the pointer tracker updates (theme.qml pointerMoved); the next nudge counts
                            onClicked: {
                                if (listRow !== index) { listRow = index; playNav(); return; }
                                listCycle(index, 1);
                            }
                            onWheel: { wheel.accepted = true; listStep(wheel.angleDelta.y > 0 ? -1 : 1); }
                        }
                    }
                }
            }
            }

            // Prompts, right-aligned like the Xbox's own; each is clickable.
            Row {
            id: footer
                anchors { right: parent.right; rightMargin: vpx(26); bottom: parent.bottom; bottomMargin: vpx(18) }
                spacing: vpx(20)
                Repeater {
                    model: { var e = listEpoch;
                             var m = [];
                             if (scoped && sysOwn()) m.push({ b: "details", t: "Back to Systems" });
                             m.push({ b: "filters", t: "All settings" });
                             m.push({ b: "cancel",  t: "Back" });
                             return m; }
                    delegate: Row {
                        spacing: vpx(7)
                        TapHandler { gesturePolicy: TapHandler.WithinBounds; onTapped: helpClick(modelData.b) }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: vpx(20); height: vpx(20)
                            source: "../assets/images/controller/" + Utils.processButtonArt(modelData.b) + ".png"
                            sourceSize { width: 40; height: 40 }
                            asynchronous: true
                        }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.t; color: "#d6d6d6"; font.family: subtitleFont.name; font.pixelSize: vpx(14.5) }
                    }
                }
            }
        }
        // Clickable prompts: the same as the keys below.
        function helpAction(button) {
            if (button === "cancel")       { playBack(); listPanelOpen = false; focusGames(); }
            else if (button === "filters") { listPanelOpen = false; settingsScreen(); }
            else if (button === "accept")  listCycle(listRow, 1);
            else if (button === "details") { if (scoped && sysOwn()) { playToggle(); sysFollow(); } }
            return true;
        }
        Keys.onPressed: {
            if (api.keys.isCancel(event) && !event.isAutoRepeat)  { event.accepted = true; playBack(); listPanelOpen = false; focusGames(); return; }
            if (api.keys.isFilters(event) && !event.isAutoRepeat) { event.accepted = true; listPanelOpen = false; settingsScreen(); return; }
            if (api.keys.isAccept(event) && !event.isAutoRepeat)  { event.accepted = true; listCycle(listRow, 1); return; }
            // X on a system with its own settings: back to following Systems.
            if (api.keys.isDetails(event) && !event.isAutoRepeat) {
                event.accepted = true;
                if (scoped && sysOwn()) { playToggle(); sysFollow(); }
                return;
            }
        }
        Keys.onUpPressed:    listStep(-1)
        Keys.onDownPressed:  listStep(1)
        Keys.onLeftPressed:  listCycle(listRow, -1)
        Keys.onRightPressed: listCycle(listRow, 1)
    }

    Rectangle {
    id: filterPanel
        visible: filterOpen; z: 30
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.78)

        MouseArea { anchors.fill: parent; hoverEnabled: true; onWheel: wheel.accepted = true; onClicked: { searchActive = false; filterOpen = false; focusGames(); } }

        // Shared on-screen keyboard — same presentation as the RA search:
        // title and text field up top, keys below, its own help prompts.
        VirtualKeyboard {
        id: filterKb

            anchors.centerIn: parent
            z: 60
            visible: searchActive
            focus: searchActive
            title: "Filter by Title"
            text: nameFilter

            onTextEdited: {
                nameFilter = newText;
                gamesView.currentIndex = 0;
            }
            // Focus MUST go back to the panel here — leaving it on a hidden
            // keyboard is what froze input on the way out.
            onAccepted:  { searchActive = false; filterPanel.forceActiveFocus(); }
            onCancelled: { searchActive = false; filterPanel.forceActiveFocus(); }
        }

        Rectangle {
            visible: !searchActive        // keyboard takes over the screen while typing
            anchors.centerIn: parent
            width: vpx(500)
            height: titleTxt.height + fieldCol.height + vpx(60)
            radius: vpx(10)
            color: Qt.rgba(0.10, 0.10, 0.10, 0.98)
            border.color: theme.accent; border.width: 2

            Text {
            id: titleTxt
                text: "Filters"
                color: "white"
                font.family: titleFont.name; font.pixelSize: fpx(24); font.bold: true
                anchors { top: parent.top; topMargin: vpx(18); left: parent.left; leftMargin: vpx(24) }
            }

            Column {
            id: fieldCol
                anchors { top: titleTxt.bottom; topMargin: vpx(14); left: parent.left; right: parent.right; leftMargin: vpx(16); rightMargin: vpx(16) }
                spacing: vpx(6)

                // Name row — shows the current search text
                Rectangle {
                    visible: !genrePickerOpen && !systemPickerOpen
                    width: parent.width; height: vpx(52); radius: vpx(6)
                    property bool onRow: filterRow === 0 || searchActive
                    color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"

                    Text {
                        anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: "\uD83D\uDD0D"; font.pixelSize: fpx(15); width: vpx(22)
                        color: "white"; opacity: parent.onRow ? 1 : 0.6
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: vpx(46); right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: searchActive
                              ? (nameFilter === "" ? "Type a name\u2026" : nameFilter)
                              : (nameFilter === "" ? "Name: (no filter)" : "Name: " + nameFilter)
                        color: "white"
                        opacity: parent.onRow ? 1 : 0.85
                        elide: Text.ElideRight
                        font.family: subtitleFont.name; font.pixelSize: fpx(20); font.bold: parent.onRow
                    }
                    MouseArea { anchors.fill: parent; onClicked: { filterRow = 0; activateSearch(); } }
                }

                // Genre row — opens the genre picker
                Rectangle {
                    visible: !searchActive && !genrePickerOpen && !systemPickerOpen
                    width: parent.width; height: vpx(52); radius: vpx(6)
                    property bool onRow: filterRow === 1
                    color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"

                    Text {
                        anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: "\u2630"; font.pixelSize: fpx(15); width: vpx(22)
                        color: "white"; opacity: parent.onRow ? 1 : 0.6
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: vpx(46); right: arrow.left; rightMargin: vpx(8); verticalCenter: parent.verticalCenter }
                        text: genreSelected.length === 0 ? "Genre: All"
                             : genreSelected.length === 1 ? "Genre: " + genreSelected[0]
                             : "Genre: " + genreSelected.length + " selected"
                        color: "white"
                        opacity: parent.onRow ? 1 : 0.85
                        elide: Text.ElideRight
                        font.family: subtitleFont.name; font.pixelSize: fpx(20); font.bold: parent.onRow
                    }
                    Text {
                        id: arrow
                        anchors { right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: "\u25B8"; color: "white"
                        opacity: parent.onRow ? 1 : 0.6; font.pixelSize: fpx(18)
                    }
                    MouseArea { anchors.fill: parent; onClicked: { filterRow = 1; openGenrePicker(); } }
                }

                // Genre picker (scrollable list of available genres)
                ListView {
                    visible: genrePickerOpen
                    width: parent.width
                    height: vpx(300)
                    clip: true
                    model: genreOptions
                    currentIndex: genrePickerIndex
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    delegate: Rectangle {
                        width: ListView.view.width; height: vpx(42); radius: vpx(4)
                        property bool onRow: index === genrePickerIndex
                        property bool isSel: modelData === "All" ? genreSelected.length === 0
                                                                 : genreSelected.indexOf(modelData) >= 0
                        color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                            text: isSel ? "\u2713" : "  "
                            color: "white"; font.pixelSize: fpx(15); font.bold: true; width: vpx(22)
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(46); right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                            text: modelData
                            color: "white"
                            opacity: onRow ? 1 : 0.85
                            elide: Text.ElideRight
                            font.family: subtitleFont.name; font.pixelSize: fpx(19); font.bold: onRow || isSel
                        }
                        MouseArea { anchors.fill: parent; onClicked: { genrePickerIndex = index; toggleGenre(modelData); } }
                    }
                }

                // System row — opens the system picker
                Rectangle {
                    visible: !searchActive && !genrePickerOpen && !systemPickerOpen
                    width: parent.width; height: vpx(52); radius: vpx(6)
                    property bool onRow: filterRow === 2
                    color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"

                    Text {
                        anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: "\u25A4"; font.pixelSize: fpx(15); width: vpx(22)
                        color: "white"; opacity: parent.onRow ? 1 : 0.6
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: vpx(46); right: sysArrow.left; rightMargin: vpx(8); verticalCenter: parent.verticalCenter }
                        text: systemIndex < 0 ? "System: ALL" : "System: " + systemFilter
                        color: "white"
                        opacity: parent.onRow ? 1 : 0.85
                        elide: Text.ElideRight
                        font.family: subtitleFont.name; font.pixelSize: fpx(20); font.bold: parent.onRow
                    }
                    Text {
                        id: sysArrow
                        anchors { right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: "\u25B8"; color: "white"
                        opacity: parent.onRow ? 1 : 0.6; font.pixelSize: fpx(18)
                    }
                    MouseArea { anchors.fill: parent; onClicked: { filterRow = 2; openSystemPicker(); } }
                }

                // System picker (scrollable list of platforms)
                ListView {
                    visible: systemPickerOpen
                    width: parent.width
                    height: vpx(300)
                    clip: true
                    model: systemOptions
                    currentIndex: systemPickerIndex
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    delegate: Rectangle {
                        width: ListView.view.width; height: vpx(42); radius: vpx(4)
                        property bool onRow: index === systemPickerIndex
                        property bool isSel: modelData.index === systemIndex
                        color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                            text: isSel ? "\u2713" : "  "
                            color: "white"; font.pixelSize: fpx(15); font.bold: true; width: vpx(22)
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(46); right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                            text: modelData.name
                            color: "white"
                            opacity: onRow ? 1 : 0.85
                            elide: Text.ElideRight
                            font.family: subtitleFont.name; font.pixelSize: fpx(19); font.bold: onRow || isSel
                        }
                        MouseArea { anchors.fill: parent; onClicked: { systemPickerIndex = index; selectSystem(modelData); } }
                    }
                }

                // Sort fields (shown when neither the keyboard nor genre picker is open)
                Column {
                    visible: !searchActive && !genrePickerOpen && !systemPickerOpen
                    width: parent.width
                    spacing: vpx(6)

                    Repeater {
                        model: sortFields
                        Rectangle {
                            width: parent.width; height: vpx(48); radius: vpx(6)
                            property bool active: sortField === modelData.key
                            property bool onRow:  filterRow === index + 3
                            color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"

                            Text {
                                anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                                text: active ? (sortDir === Qt.AscendingOrder ? "\u25B2" : "\u25BC") : "  "
                                color: "white"; font.pixelSize: fpx(16); font.bold: true
                                width: vpx(22)
                            }
                            Text {
                                anchors { left: parent.left; leftMargin: vpx(46); verticalCenter: parent.verticalCenter }
                                text: modelData.label
                                color: "white"
                                opacity: active ? 1 : 0.85
                                font.family: subtitleFont.name; font.pixelSize: fpx(20); font.bold: active
                            }
                            MouseArea { anchors.fill: parent; onClicked: { filterRow = index + 3; selectSort(modelData.key); } }
                        }
                    }
                }

                // Favorites-only toggle
                Column {
                    visible: !searchActive && !genrePickerOpen && !systemPickerOpen
                    width: parent.width
                    spacing: vpx(6)

                    // Favorites only
                    Rectangle {
                        width: parent.width; height: vpx(48); radius: vpx(6)
                        property bool onRow: filterRow === sortFields.length + 3
                        color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                            text: favsOnly ? "\u2713" : "  "
                            color: "white"; font.pixelSize: fpx(16); font.bold: true
                            width: vpx(22)
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(46); verticalCenter: parent.verticalCenter }
                            text: "Favorites only"
                            color: "white"
                            opacity: favsOnly ? 1 : 0.85
                            font.family: subtitleFont.name; font.pixelSize: fpx(20); font.bold: favsOnly
                        }
                        MouseArea { anchors.fill: parent; onClicked: { filterRow = sortFields.length + 3; favsOnly = !favsOnly; gamelist.currentIndex = 0; } }
                    }
                }

            }

            // Button-icon hint bar — swaps prompts per context (search / genre / sort)
            Row {
                visible: !searchActive     // the keyboard draws its own prompts
                anchors { bottom: parent.bottom; bottomMargin: vpx(12); right: parent.right; rightMargin: vpx(20) }
                spacing: vpx(22)

                Repeater {
                    model: searchActive    ? [ {a:"accept",t:"Type"}, {a:"details",t:"Delete"}, {a:"filters",t:"Done"}, {a:"cancel",t:"Close"} ]
                         : genrePickerOpen  ? [ {a:"accept",t:"Toggle"}, {a:"cancel",t:"Done"} ]
                         : systemPickerOpen ? [ {a:"accept",t:"Select"}, {a:"cancel",t:"Back"} ]
                         :                    [ {a:"accept",t:"Select"}, {a:"details",t:"Clear all"}, {a:"cancel",t:"Close"} ]
                    delegate: Row {
                        TapHandler { gesturePolicy: TapHandler.WithinBounds; onTapped: helpClick(modelData.a) }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        spacing: vpx(7)
                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            source: "../assets/images/controller/" + fpBtnArt(modelData.a) + ".png"
                            width: vpx(26); height: vpx(26)
                            asynchronous: true; smooth: true
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.t
                            color: "white"; opacity: 0.55
                            font.family: subtitleFont.name; font.pixelSize: fpx(15)
                        }
                    }
                }
            }
        }

        Keys.onUpPressed: {
            playNav();
            if (searchActive) { }
            else if (genrePickerOpen) { if (genrePickerIndex > 0) genrePickerIndex--; }
            else if (systemPickerOpen) { if (systemPickerIndex > 0) systemPickerIndex--; }
            else if (filterRow > 0) filterRow--;
        }
        Keys.onDownPressed: {
            playNav();
            if (searchActive) { }
            else if (genrePickerOpen) { if (genrePickerIndex < genreOptions.length - 1) genrePickerIndex++; }
            else if (systemPickerOpen) { if (systemPickerIndex < systemOptions.length - 1) systemPickerIndex++; }
            else if (filterRow < sortFields.length + 3) filterRow++;
        }
        Keys.onLeftPressed: {
            playNav();
            if (searchActive) { }
            else if (genrePickerOpen) genrePickerIndex = Math.max(0, genrePickerIndex - 10);
            else if (systemPickerOpen) systemPickerIndex = Math.max(0, systemPickerIndex - 10);
        }
        Keys.onRightPressed: {
            playNav();
            if (searchActive) { }
            else if (genrePickerOpen) genrePickerIndex = Math.min(genreOptions.length - 1, genrePickerIndex + 10);
            else if (systemPickerOpen) systemPickerIndex = Math.min(systemOptions.length - 1, systemPickerIndex + 10);
        }
        Keys.onPressed: {
            // While searching the VirtualKeyboard holds focus and handles its
            // own input, so nothing here should run.
            if (searchActive) return;
            if (genrePickerOpen) {
                if (api.keys.isPageDown(event) && !event.isAutoRepeat) { event.accepted = true; playToggle(); genreJumpLetter(1);  return; }
                if (api.keys.isPageUp(event)   && !event.isAutoRepeat) { event.accepted = true; playToggle(); genreJumpLetter(-1); return; }
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; playAccept(); toggleGenre(genreOptions[genrePickerIndex]); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); genrePickerOpen = false; }
                if (api.keys.isDetails(event) && !event.isAutoRepeat) { event.accepted = true; playAccept(); genrePickerOpen = false; }
                return;
            }
            if (systemPickerOpen) {
                if (api.keys.isPageDown(event) && !event.isAutoRepeat) { event.accepted = true; playToggle(); systemJumpLetter(1);  return; }
                if (api.keys.isPageUp(event)   && !event.isAutoRepeat) { event.accepted = true; playToggle(); systemJumpLetter(-1); return; }
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; playAccept(); selectSystem(systemOptions[systemPickerIndex]); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); systemPickerOpen = false; }
                if (api.keys.isDetails(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); systemPickerOpen = false; }
                return;
            }
            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true; filterAccept();
            }
            if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                event.accepted = true; playBack(); filterOpen = false; focusGames();
            }
            if (api.keys.isDetails(event) && !event.isAutoRepeat) {
                event.accepted = true; playToggle(); clearAllFilters();
            }
        }
        // A on a filter row.
        function filterAccept() {
            playAccept();
            if (filterRow === 0) activateSearch();
            else if (filterRow === 1) openGenrePicker();
            else if (filterRow === 2) openSystemPicker();
            else if (filterRow <= sortFields.length + 2) selectSort(sortFields[filterRow - 3].key);
            else if (filterRow === sortFields.length + 3) { favsOnly = !favsOnly; gamesView.currentIndex = 0; }
        }
        // Clickable prompts: the same branches as the keys above.
        function helpAction(button) {
            if (searchActive) return false;
            if (genrePickerOpen) {
                if (button === "accept")       { playAccept(); toggleGenre(genreOptions[genrePickerIndex]); }
                else if (button === "cancel")  { playBack(); genrePickerOpen = false; }
                else if (button === "details") { playAccept(); genrePickerOpen = false; }
                return true;
            }
            if (systemPickerOpen) {
                if (button === "accept") { playAccept(); selectSystem(systemOptions[systemPickerIndex]); }
                else if (button === "cancel" || button === "details") { playBack(); systemPickerOpen = false; }
                return true;
            }
            if (button === "accept")       filterAccept();
            else if (button === "cancel")  { playBack(); filterOpen = false; focusGames(); }
            else if (button === "details") { playToggle(); clearAllFilters(); }
            return true;
        }
    }

    // ── Input ─────────────────────────────────────────────────────────────
    // Down/Left/Right live on the gamelist ListView itself (see above); handling
    // them at root is unreliable because the focused ListView consumes Down first.

    Keys.onPressed: {
        // A — launch the game directly
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (filterOpen || !currentGame) return;
            // Grid: openGame() honours "Added App Launch" — imports and apps
            // set to Instant launch straight away, everything else opens
            // Game Details. List mode keeps launching directly, as before.
            // Grid mode: the focused tile consumes A itself (see the delegates),
            // so this only runs when a tile didn't — treat it the same way.
            if (gridMode) { activateCurrent(); return; }
            // List: games still launch directly (Y is More Details); imports
            // and added apps follow the same rule as every other screen.
            if (gamesFocused) activateGame(currentGame, false);
        }
        // B — back
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamesFocused) { previousScreen(); }
        }
        // X — open Sorting & Filters
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamesFocused) openFilters();
        }
        // Y — game details page, opened with the full details pane expanded.
        // Inert for imported apps: they carry no metadata, so the page would be
        // empty. The helpbar drops the prompt to match.
        // Start — More Details (list mode, games only). Raw code checked first
        // so the event is accepted before Pegasus's own menu reacts to Start.
        if (event.key === 1048587 && !event.isAutoRepeat && !gridMode && !filterOpen && gamesFocused && !listPanelOpen) {
            event.accepted = true;
            if (currentGame && !currentIsImportedApp) gameDetailsFull(currentGame);
            return;
        }
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (filterOpen || listPanelOpen) return;
            if (!gamesFocused) return;
            playAccept(); listRow = 0; listPanelOpen = true; listPanel.forceActiveFocus();
        }
        // LT — previous letter group
        if (api.keys.isPageUp(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamesFocused) { playToggle(); jumpToPrevLetter(); }
        }
        // RT — next letter group
        if (api.keys.isPageDown(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamesFocused) { playToggle(); jumpToNextLetter(); }
        }
        // LB / RB — on a scoped view with "LB/RB Function: Cycle Platforms",
        // the previous / next system (as on the Platform page); otherwise
        // straight up to the nav bar from anywhere in the list.
        if ((api.keys.isPrevPage(event) || api.keys.isNextPage(event)) && !event.isAutoRepeat) {
            event.accepted = true;
            if (filterOpen || !gamesFocused) return;
            if (scoped && settings.PlatformShoulderButtons !== "Nav Bar") cycleScope(api.keys.isNextPage(event) ? 1 : -1);
            else { playNav(); homebutton.focus = true; }
        }
    }

    // ── Helpbar: A Launch, X Filters, Y More Details, B Back ──────────────
    ListModel {
        id: allGamesHelpModel
        ListElement { name: "Back";         button: "cancel"  }
        ListElement { name: "Settings";     button: "filters" }
        ListElement { name: "Filters";      button: "details" }
        ListElement { name: "Launch";       button: "accept"  }
    }
    // Grid mode: no preview panel, so no More Details; Y opens Settings.
    // A reads "Launch" on an imported app (it launches straight away) and
    // "Select" on a game (it opens details), mirroring the list's two bars.
    ListModel {
        id: allGamesGridHelpModel
        ListElement { name: "Back";     button: "cancel"  }
        ListElement { name: "Settings"; button: "filters" }
        ListElement { name: "Filters";  button: "details" }
        ListElement { name: "Select";   button: "accept"  }
    }
    ListModel {
        id: allGamesGridAppHelpModel
        ListElement { name: "Back";     button: "cancel"  }
        ListElement { name: "Settings"; button: "filters" }
        ListElement { name: "Filters";  button: "details" }
        ListElement { name: "Launch";   button: "accept"  }
    }
    // Same bar without More Details, for imported apps. Two static models
    // swapped on demand rather than one model rebuilt as the cursor moves.
    ListModel {
        id: allGamesAppHelpModel
        ListElement { name: "Back";     button: "cancel"  }
        ListElement { name: "Settings"; button: "filters" }
        ListElement { name: "Filters";  button: "details" }
        ListElement { name: "Launch";   button: "accept"  }
    }

    // True when the highlighted entry is an app Pegasus imported.
    // Derived from the LIST, not from the shared currentGame property.
    //
    // currentGame is assigned imperatively when the proxy model finishes
    // filling, which happens asynchronously and may be after this screen takes
    // focus. If the first row is an imported app the index never changes, so
    // nothing re-triggered and the bar kept the stale value until the cursor
    // moved. Reading currentIndex and count makes this re-evaluate the moment
    // the model populates, whatever the ordering.
    readonly property bool currentIsImportedApp: {
        var idx = gamesView.currentIndex;
        var cnt = gamesView.count;
        if (cnt <= 0 || idx < 0) return false;
        var g = getCurrentGame(idx);
        if (!g || !g.files || g.files.count < 1) return false;
        return (g.files.get(0).path || "").indexOf("android:") === 0;
    }
    // The mode can change while this screen is open (the user comes back from
    // Settings), so the bar follows it.
    onGridModeChanged: refreshHelpbar()

    function refreshHelpbar() {
        if (!focus) return;
        currentHelpbarModel = gridMode ? (currentIsImportedApp ? allGamesGridAppHelpModel : allGamesGridHelpModel)
                            : currentIsImportedApp ? allGamesAppHelpModel
                                                   : allGamesHelpModel;
    }
    // Only fires when crossing between an app and a normal entry, not on every
    // cursor move.
    onCurrentIsImportedAppChanged: refreshHelpbar()

    onFocusChanged: {
        if (focus) {
            // Put focus on whichever view is showing. The two views' focus
            // bindings decide this at load, but an imperative hand-back from
            // a header button can leave the other one holding it.
            focusGames();
            // Covers focus arriving before the model has populated; once it
            // does, currentIsImportedApp changes and refreshes this again.
            refreshHelpbar();
            // Returning from game details: re-center the list on the current game
            restoreViewTimer.restart();
        }
    }

    // Status cluster (clock / battery / wifi) — the same component and the
    // same ShowClock/ShowBattery/ShowWifi settings as the Platform page.
    StatusCluster {
        anchors.fill: parent
        z: 50
        dark: whiteBackground
    }

    // Start prompt beside "Apps" in the help bar: More Details, list mode,
    // games only (imported apps have no details page).
    Row {
        visible: !gridMode && currentGame && !currentIsImportedApp && !hideAppsPrompt && !filterOpen && !listPanelOpen
        // Same geometry as the help bar's own Apps row (ButtonHelpBar): 30px
        // icon, spacing 10, fpx(16) text, anchored to the bar's top with the
        // same nudge — so the two sit on one line.
        anchors { left: parent.left; leftMargin: vpx(150); bottom: parent.bottom; bottomMargin: helpMargin - height }
        spacing: 10; z: 60
        // Clickable like every other prompt.
        TapHandler { gesturePolicy: TapHandler.WithinBounds; onTapped: if (currentGame && !currentIsImportedApp) gameDetailsFull(currentGame) }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        // The white badge has no padding, so at the glyphs' 30px box it reads
        // larger than their visible circle. 24px, centred in a 30px slot,
        // matches what you see.
        Item { width: vpx(30); height: vpx(30)
            Image { anchors.centerIn: parent; width: vpx(24); height: vpx(24); fillMode: Image.PreserveAspectFit
                    source: "../assets/images/kb_badge_start_white.svg"; sourceSize { width: Math.round(vpx(24) * 2); height: Math.round(vpx(24) * 2) } smooth: true } }
        Text  { height: parent.height; verticalAlignment: Text.AlignVCenter; text: "More Details"; color: theme.text
                font.family: subtitleFont.name; font.pixelSize: fpx(16) }
    }
}
