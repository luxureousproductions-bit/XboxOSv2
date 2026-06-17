// AllGamesMenu.qml — All games across all collections
import QtQuick 2.15
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.12
import QtMultimedia 5.15
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
        onClicked: mouse.accepted = true
        onReleased: mouse.accepted = true
    }

    property real itemheight: vpx(50)
    property int  skipnum: 10

    // ── Data ──────────────────────────────────────────────────────────────
    ListAllGames {
    id: listAllGames
        max: api.allGames.count
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
        gamelist.currentIndex = idx;
        currentGameIndex = idx;
        currentGame = getCurrentGame(idx);
        restoreViewTimer.restart();   // scroll the view to center on it (deferred)
    }

    // Center the list view on the current row by setting contentY directly.
    // (positionViewAtIndex is unreliable right after a reload — the view geometry
    //  isn't ready yet, so it clamps to the top until the user scrolls.)
    function centerListOnCurrent() {
        var n = gamelist.count;
        if (n <= 0 || gamelist.height <= 0) { restoreViewTimer.restart(); return; }
        var i = gamelist.currentIndex < 0 ? 0 : gamelist.currentIndex;
        // Re-assert the current index so the highlight realizes on the visible row
        // (a delegate scrolled into view via contentY won't refresh isCurrentItem
        //  until the current item changes again).
        gamelist.currentIndex = -1;
        gamelist.currentIndex = i;
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

    // ── Game preview art (miximage-style composite) ──
    // Backdrop = fanart (falls back to a screenshot); framed square = a screenshot.
    property string artBackdrop: {
        if (!settledGame) return "";
        var f = Utils.fanArt(settledGame);
        if (f) return f;
        var s2 = settledGame.assets.screenshotList;
        return (s2 && s2.length) ? s2[0] : "";
    }
    property string artScreenshot: {
        if (!settledGame) return "";
        var ss = settledGame.assets.screenshotList;
        if (ss && ss.length) return ss[0];
        return Utils.fanArt(settledGame) || "";
    }
    property string artLogo: settledGame ? (Utils.logo(settledGame) || settledGame.assets.logo || "") : ""
    property string artBoxSource: {
        if (!settledGame) return "";
        var three = Utils.get3dBoxArt(settledGame);
        if (three) return three;                       // 3D box
        return settledGame.assets.boxFront || "";      // 2D fallback
    }
    // SNES & N64 3D box scans are stored landscape — rotate them upright (tall) so
    // they match their miximages. Detected the same way the old scale-down was.
    property bool boxRotated: {
        if (!settledGame || settledGame.collections.count === 0) return false;
        var c = settledGame.collections.get(0);
        var s = ((c.shortName ? c.shortName : "") + " " + (c.name ? c.name : "")).toLowerCase();
        return (s.indexOf("snes") >= 0 || s.indexOf("super nintendo") >= 0
                || s.indexOf("n64") >= 0 || s.indexOf("nintendo 64") >= 0);
    }
    property real boxScale: 1.0   // full size (the old SNES/N64 0.88 shrink removed)

    // ── Video preview (plays inside the screenshot frame after a brief rest) ──
    property string videoSource: (currentGame && currentGame.assets && currentGame.assets.videos && currentGame.assets.videos.length > 0) ? currentGame.assets.videos[0] : ""
    property bool   videoArmed:      false
    property bool   videoPlaying:    previewVideo.playbackState === MediaPlayer.PlayingState
    property bool   hideBoxForVideo:  videoPlaying && settings.AllGamesHideBoxOnVideo === "Yes"
    property bool   hideLogoForVideo: videoPlaying && settings.AllGamesHideLogoOnVideo === "Yes"
    Timer {
    id: videoDebounce
        interval: 2000; repeat: false
        onTriggered: videoArmed = true
    }

    // Heavy preview art (backdrop/screenshot/box/logo) only swaps once the cursor
    // settles, so flicking the list doesn't decode four images on every step.
    // Metadata text stays bound to currentGame (instant); video has its own debounce.
    property var settledGame: null
    Timer {
    id: artDebounce
        interval: 150; repeat: false
        onTriggered: settledGame = currentGame
    }

    // On-screen keyboard — fully controller-driven, NO native Android IME
    // (this is what eliminates the stuck blue input box entirely)
    property bool kbSpecial: false
    property var kbMain: [
        "A","B","C","D","E","F","G","H","I","J",
        "K","L","M","N","O","P","Q","R","S","T",
        "U","V","W","X","Y","Z","-","'",".",":",
        "0","1","2","3","4","5","6","7","8","9",
        "áé","SPACE","DEL","CLR","OK"
    ]
    property var kbSpec: [
        "À","Á","Â","Ã","Ä","Å","Æ","Ç","È","É",
        "Ê","Ë","Ì","Í","Î","Ï","Ñ","Ò","Ó","Ô",
        "Õ","Ö","Ø","Ù","Ú","Û","Ü","Ý","ß","°",
        "&","!","?","@","#","%","+","=",",",";",
        "ABC","SPACE","DEL","CLR","OK"
    ]
    property var keyboardKeys: kbSpecial ? kbSpec : kbMain
    property int keyCols:  10
    property int keyIndex: 0

    function activateSearch() { keyIndex = 0; kbSpecial = false; searchActive = true; }
    function pressKey(k) {
        if (k === "áé")  { kbSpecial = true;  return; }
        if (k === "ABC") { kbSpecial = false; return; }
        if (k === "SPACE")    nameFilter += " ";
        else if (k === "DEL") nameFilter = nameFilter.slice(0, -1);
        else if (k === "CLR") nameFilter = "";
        else if (k === "OK")  searchActive = false;
        else                  nameFilter += k;
        gamelist.currentIndex = 0;
    }

    property var sortFields: [
        { key: "sortBy",      label: "Title" },
        { key: "lastPlayed",  label: "Last Played" },
        { key: "rating",      label: "Rating" },
        { key: "releaseYear", label: "Release Date" },
        { key: "favorite",    label: "Favorites" }
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
        gamelist.currentIndex = 0;
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
        if (g === "All") { genreSelected = []; gamelist.currentIndex = 0; return; }
        var arr = genreSelected.slice();
        var idx = arr.indexOf(g);
        if (idx >= 0) arr.splice(idx, 1);
        else           arr.push(g);
        genreSelected = arr;            // reassign so bindings re-evaluate
        gamelist.currentIndex = 0;
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
        systemIndex  = opt.index;
        gamelist.currentIndex = 0;
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
        gamelist.currentIndex = 0;
    }

    // ── Display model ─────────────────────────────────────────────────────
    SortFilterProxyModel {
    id: displayModel
        // All systems -> full all-games list; a chosen system -> that collection's games
        sourceModel: systemIndex < 0 ? listAllGames.games : api.collections.get(systemIndex).games
        sorters: RoleSorter {
            roleName:  sortField
            sortOrder: sortDir
        }
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
            }
        ]
    }

    function getCurrentGame(idx) {
        var srcIdx = displayModel.mapToSource(idx);
        if (systemIndex < 0) return listAllGames.currentGame(srcIdx);
        return api.collections.get(systemIndex).games.get(srcIdx);
    }

    // Jump to the first game of the next / previous letter group
    function jumpToNextLetter() {
        if (gamelist.count === 0) return;
        var cur = gamelist.currentIndex;
        var curE = cur >= 0 ? displayModel.get(cur) : null;
        var curLtr = curE ? (curE.title || "").charAt(0).toUpperCase() : "";
        for (var i = cur + 1; i < gamelist.count; i++) {
            var e = displayModel.get(i);
            if (e && (e.title || "").charAt(0).toUpperCase() !== curLtr) { gamelist.currentIndex = i; return; }
        }
        gamelist.currentIndex = 0;
    }
    function jumpToPrevLetter() {
        if (gamelist.count === 0) return;
        var cur = gamelist.currentIndex;
        if (cur <= 0) { gamelist.currentIndex = gamelist.count - 1; return; }
        var prevE = displayModel.get(cur - 1);
        var prevLtr = prevE ? (prevE.title || "").charAt(0).toUpperCase() : "";
        for (var i = cur - 2; i >= 0; i--) {
            var e = displayModel.get(i);
            if (e && (e.title || "").charAt(0).toUpperCase() !== prevLtr) { gamelist.currentIndex = i + 1; return; }
        }
        gamelist.currentIndex = 0;
    }

    Component.onCompleted: {
        currentHelpbarModel     = allGamesHelpModel;
        currentCustomCollection = listAllGames.collection;
        restoreSelection();   // restore the row we were on (if the model is ready)
        settledGame = currentGame;   // show the persisted game's art right away
    }

    // Vertical accent line dividing the text list from the game details
    Rectangle {
    id: vDivider
        anchors {
            left: gamelist.right; leftMargin: globalMargin / 2
            top: header.bottom; topMargin: globalMargin
            bottom: parent.bottom; bottomMargin: globalMargin + helpMargin
        }
        width: vpx(3)
        color: theme.accent
    }

    // ── Game preview (miximage-style): darkened fanart backdrop + framed
    //    square screenshot, with the 3D box overlapping its bottom-left and
    //    the logo straddling its top edge. Border hugs just the screenshot.
    Item {
    id: boxArt
        anchors {
            top: header.bottom; topMargin: globalMargin
            left: gamelist.right; leftMargin: globalMargin
            right: parent.right; rightMargin: globalMargin
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
            visible: status === Image.Ready && settings.AllGamesBlurBackground !== "Yes"
            opacity: 0.55
        }
        // Blurred backdrop variant (only built when the setting is on)
        Loader {
        id: bgBlurLoader
            anchors.fill: parent
            active: settings.AllGamesBlurBackground === "Yes" && artBackdrop !== ""
            readonly property Item blurSrc: bgArtImg
            sourceComponent: Component {
                FastBlur {
                    anchors.fill: parent
                    source: bgBlurLoader.blurSrc
                    radius: 64
                    opacity: 0.55
                }
            }
        }
        Rectangle {
            anchors.fill: parent
            color: (bgArtImg.visible || bgBlurLoader.active) ? Qt.rgba(0, 0, 0, 0.45)
                                    : Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.06)
        }

        // Framed square screenshot (shifted slightly right to leave room for the box)
        Item {
        id: shotFrame
            width:  boxArt.shotSide
            height: boxArt.shotSide
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: vpx(28)

            Image {
            id: artScreenshotImg
                anchors.fill: parent
                asynchronous: true
                sourceSize: Qt.size(width, height)
                source: artScreenshot
                fillMode: Image.PreserveAspectCrop   // crop to a clean square
                smooth: true
                visible: status === Image.Ready
                layer.enabled: true
                layer.smooth: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle { width: artScreenshotImg.width; height: artScreenshotImg.height; radius: vpx(10) }
                }
            }
            Rectangle {   // fallback fill when no screenshot
                anchors.fill: parent
                visible: !artScreenshotImg.visible
                radius: vpx(10)
                color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.14)
            }
            // Video preview — plays over the screenshot once armed (after resting)
            Video {
            id: previewVideo
                anchors.fill: parent
                anchors.margins: vpx(3)   // inset so the square video corners stay inside the
                                          // rounded screenshot; corners then show the backdrop
                                          // (transparent) without ever masking the video itself
                source: (settings.AllGamesVideoPreview !== "No" && videoArmed && videoSource !== "") ? videoSource : ""
                fillMode: VideoOutput.PreserveAspectCrop
                muted: settings.AllGamesVideoAudio !== "Yes"
                loops: MediaPlayer.Infinite
                autoPlay: true
                visible: playbackState === MediaPlayer.PlayingState
                // No layer/OpacityMask here: rendering a VideoOutput through an FBO+mask
                // shows audio-only (black frame) on some low-end Android GPUs. Square
                // corners on the playing video are the safe, universal choice.
            }
            // Scanlines overlay (optional)
            Image {
            id: scanlinesOverlay
                anchors.fill: parent
                source: settings.AllGamesScanlines === "Yes" ? "../assets/images/scanlines_v3.png" : ""
                asynchronous: true
                opacity: 0.2
                visible: settings.AllGamesScanlines === "Yes"
                layer.enabled: true
                layer.smooth: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle { width: scanlinesOverlay.width; height: scanlinesOverlay.height; radius: vpx(10) }
                }
            }
            Rectangle {   // border around JUST the screenshot
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
        height: vpx(170)
        visible: currentGame ? true : false

        // Accent line above the metadata
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: vpx(3); color: theme.accent
        }

        Column {
            anchors { top: parent.top; topMargin: vpx(14); left: parent.left; right: parent.right }
            spacing: 0

            // Row 1: Publisher | Developer | Players
            RowLayout {
                width: parent.width; height: vpx(42); spacing: vpx(18)
                Item {
                    Layout.fillWidth: true; Layout.preferredWidth: vpx(100); Layout.fillHeight: true
                    Text { id: agPubLabel
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        text: "Publisher: "; font.pixelSize: vpx(17); font.family: subtitleFont.name; font.bold: true; color: theme.accent
                    }
                    Text {
                        anchors { left: agPubLabel.right; right: parent.right; verticalCenter: parent.verticalCenter }
                        text: currentGame && currentGame.publisher ? currentGame.publisher : "—"
                        font.pixelSize: vpx(17); font.family: subtitleFont.name; color: theme.text; elide: Text.ElideRight
                    }
                }
                Rectangle { width: vpx(2); height: vpx(26); Layout.alignment: Qt.AlignVCenter; opacity: 0.2 }
                Item {
                    Layout.fillWidth: true; Layout.preferredWidth: vpx(100); Layout.fillHeight: true
                    Text { id: agDevLabel
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        text: "Developer: "; font.pixelSize: vpx(17); font.family: subtitleFont.name; font.bold: true; color: theme.accent
                    }
                    Text {
                        anchors { left: agDevLabel.right; right: parent.right; verticalCenter: parent.verticalCenter }
                        text: currentGame && currentGame.developer ? currentGame.developer : "—"
                        font.pixelSize: vpx(17); font.family: subtitleFont.name; color: theme.text; elide: Text.ElideRight
                    }
                }
                Rectangle { width: vpx(2); height: vpx(26); Layout.alignment: Qt.AlignVCenter; opacity: 0.2 }
                Item {
                    Layout.fillWidth: true; Layout.preferredWidth: vpx(100); Layout.fillHeight: true
                    Text { id: agPlayersLabel
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        text: "Players: "; font.pixelSize: vpx(17); font.family: subtitleFont.name; font.bold: true; color: theme.accent
                    }
                    Text {
                        anchors { left: agPlayersLabel.right; right: parent.right; verticalCenter: parent.verticalCenter }
                        text: currentGame && currentGame.players > 0 ? currentGame.players : "—"
                        font.pixelSize: vpx(17); font.family: subtitleFont.name; color: theme.text; elide: Text.ElideRight
                    }
                }
            }

            // extra gap before Row 2 ("down 1")
            Item { width: 1; height: vpx(10) }

            // Row 2: Genre | Released | Rating
            RowLayout {
                width: parent.width; height: vpx(42); spacing: vpx(18)
                Item {
                    Layout.fillWidth: true; Layout.preferredWidth: vpx(100); Layout.fillHeight: true
                    Text { id: agGenreLabel
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        text: "Genre: "; font.pixelSize: vpx(17); font.family: subtitleFont.name; font.bold: true; color: theme.accent
                    }
                    Text {
                        anchors { left: agGenreLabel.right; right: parent.right; verticalCenter: parent.verticalCenter }
                        text: currentGame && currentGame.genre ? currentGame.genre : "—"
                        font.pixelSize: vpx(17); font.family: subtitleFont.name; color: theme.text; elide: Text.ElideRight
                    }
                }
                Rectangle { width: vpx(2); height: vpx(26); Layout.alignment: Qt.AlignVCenter; opacity: 0.2 }
                Item {
                    Layout.fillWidth: true; Layout.preferredWidth: vpx(100); Layout.fillHeight: true
                    Text { id: agRelLabel
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        text: "Released: "; font.pixelSize: vpx(17); font.family: subtitleFont.name; font.bold: true; color: theme.accent
                    }
                    Text {
                        anchors { left: agRelLabel.right; right: parent.right; verticalCenter: parent.verticalCenter }
                        text: fmtReleaseDate(currentGame)
                        font.pixelSize: vpx(17); font.family: subtitleFont.name; color: theme.text; elide: Text.ElideRight
                    }
                }
                Rectangle { width: vpx(2); height: vpx(26); Layout.alignment: Qt.AlignVCenter; opacity: 0.2 }
                Item {
                    Layout.fillWidth: true; Layout.preferredWidth: vpx(100); Layout.fillHeight: true
                    Text { id: agRatingLabel
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        text: "Rating: "; font.pixelSize: vpx(17); font.family: subtitleFont.name; font.bold: true; color: theme.accent
                    }
                    Text {
                        anchors { left: agRatingLabel.right; right: parent.right; verticalCenter: parent.verticalCenter }
                        text: currentGame && currentGame.rating > 0 ? (currentGame.rating * 10).toFixed(1) : "—"
                        font.pixelSize: vpx(17); font.family: subtitleFont.name; color: theme.text; elide: Text.ElideRight
                    }
                }
            }

            // extra gap before Row 3 ("down 2")
            Item { width: 1; height: vpx(16) }

            // Row 3: Last Played (single field, left-aligned)
            RowLayout {
                width: parent.width; height: vpx(42); spacing: vpx(18)
                Item {
                    Layout.fillWidth: true; Layout.preferredWidth: vpx(100); Layout.fillHeight: true
                    Text { id: agLastLabel
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        text: "Last Played: "; font.pixelSize: vpx(17); font.family: subtitleFont.name; font.bold: true; color: theme.accent
                    }
                    Text {
                        anchors { left: agLastLabel.right; right: parent.right; verticalCenter: parent.verticalCenter }
                        text: fmtLastPlayed(currentGame)
                        font.pixelSize: vpx(17); font.family: subtitleFont.name; color: theme.text; elide: Text.ElideRight
                    }
                }
            }
        }
    }

    // ── Custom header (library icon + nav buttons) ────────────────────────
    Item {
    id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(75)

        Rectangle { anchors.fill: parent; color: theme.main }

        // Accent line above the preview — pushed down so it sits the same
        // distance from the fanart (vpx(14)) as the bottom accent line does.
        Rectangle {
            anchors {
                bottom: parent.bottom; bottomMargin: -(globalMargin - vpx(14))
                left: parent.left; right: parent.right
            }
            height: vpx(3); color: theme.accent
        }

        // Icon + title (top row) — matches the platform page's clean header rhythm
        Image {
        id: libIcon
            source: "../assets/images/gamesandapps.png"
            anchors { top: parent.top; topMargin: vpx(10); left: parent.left; leftMargin: globalMargin }
            height: vpx(40); width: vpx(40)
            fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
            // White-lettering logo flips to black on a white background
            layer.enabled: whiteBackground
            layer.effect: ColorOverlay { color: "black" }
        }
        Text {
            anchors { left: libIcon.right; leftMargin: vpx(12); verticalCenter: libIcon.verticalCenter }
            text: "My Games & Apps"
            color: theme.text; font.family: titleFont.name; font.pixelSize: vpx(24); font.bold: true
        }
        // Game counter sits directly below the title row (no longer crowding it)
        Text {
            anchors { left: parent.left; leftMargin: globalMargin; top: libIcon.bottom; topMargin: vpx(2) }
            text: displayModel.count + " games"
            color: theme.text; opacity: 0.7; font.family: subtitleFont.name; font.pixelSize: vpx(15)
        }

        // Current game's system logo (top-right), updates while scrolling the list
        Image {
        id: sysLogo
            anchors { top: parent.top; topMargin: vpx(14); right: parent.right; rightMargin: globalMargin }
            height: vpx(40)
            fillMode: Image.PreserveAspectFit
            source: (currentGame && currentGame.collections.count > 0)
                    ? "../assets/images/logospng/" + Utils.processPlatformName(currentGame.collections.get(0).shortName) + ".png"
                    : ""
            visible: status === Image.Ready
            smooth: true; asynchronous: true; cache: true
        }

        // Nav buttons (home / discover / achievements / settings)
        Rectangle {
        id: homebutton
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -vpx(81) }
            color: focus ? theme.accent : "transparent"; opacity: focus ? 1 : 0.6
            Keys.onDownPressed:  { playNav(); gamelist.focus = true; }
            Keys.onRightPressed: { playNav(); discoverbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; showcaseScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); gamelist.focus = true; }
                if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); discoverbutton.focus = true; }
                if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); settingsbutton.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: showcaseScreen(); }
            Image {
                anchors.centerIn: parent
                width: vpx(24); height: vpx(24)
                sourceSize: Qt.size(vpx(24), vpx(24))
                source: "../assets/images/icon_home.svg"
                layer.enabled: whiteBackground
                layer.effect: ColorOverlay { color: "black" }
                fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
                opacity: homebutton.focus ? 1 : 0.7
            }
        }

        Rectangle {
        id: discoverbutton
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -vpx(27) }
            color: focus ? theme.accent : "transparent"; opacity: focus ? 1 : 0.6
            Keys.onDownPressed:  { playNav(); gamelist.focus = true; }
            Keys.onLeftPressed:  { playNav(); homebutton.focus = true; }
            Keys.onRightPressed: { playNav(); achievementsbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; discoverScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); gamelist.focus = true; }
                if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); achievementsbutton.focus = true; }
                if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); homebutton.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: discoverScreen(); }
            Canvas {
                anchors { fill: parent; margins: vpx(6) }
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset();
                    var cx = width/2, cy = height/2, r = Math.min(cx,cy)-1;
                    ctx.globalAlpha = discoverbutton.focus ? 1.0 : 0.85;
                    ctx.strokeStyle = navCol; ctx.lineWidth = 1.5;
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2); ctx.stroke();
                    ctx.fillStyle = navCol;
                    ctx.beginPath(); ctx.moveTo(cx, cy-r*0.65); ctx.lineTo(cx+r*0.30, cy+r*0.10); ctx.lineTo(cx, cy+r*0.20); ctx.lineTo(cx-r*0.30, cy+r*0.10); ctx.closePath(); ctx.fill();
                    ctx.globalAlpha = 0.35;
                    ctx.beginPath(); ctx.moveTo(cx, cy+r*0.65); ctx.lineTo(cx-r*0.30, cy-r*0.10); ctx.lineTo(cx, cy-r*0.20); ctx.lineTo(cx+r*0.30, cy-r*0.10); ctx.closePath(); ctx.fill();
                }
                property string navCol: whiteBackground ? "black" : "white"
                onNavColChanged: requestPaint()
                Connections { target: discoverbutton; onFocusChanged: parent.requestPaint() }
            }
        }

        Rectangle {
        id: achievementsbutton
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: vpx(27) }
            color: focus ? theme.accent : "transparent"; opacity: focus ? 1 : 0.6
            Keys.onDownPressed:  { playNav(); gamelist.focus = true; }
            Keys.onLeftPressed:  { playNav(); discoverbutton.focus = true; }
            Keys.onRightPressed: { playNav(); settingsbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; achievementsScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); gamelist.focus = true; }
                if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); settingsbutton.focus = true; }
                if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); discoverbutton.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: achievementsScreen(); }
            Image {
                anchors.centerIn: parent
                width: vpx(24); height: vpx(24)
                sourceSize: Qt.size(vpx(24), vpx(24))
                source: "../assets/images/trophy.svg"
                layer.enabled: whiteBackground
                layer.effect: ColorOverlay { color: "black" }
                fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
                opacity: achievementsbutton.focus ? 1 : 0.7
            }
        }

        Rectangle {
        id: settingsbutton
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: vpx(81) }
            color: focus ? theme.accent : "transparent"; opacity: focus ? 1 : 0.6
            Keys.onDownPressed: { playNav(); gamelist.focus = true; }
            Keys.onLeftPressed: { playNav(); achievementsbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; settingsScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); gamelist.focus = true; }
                if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); homebutton.focus = true; }
                if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); achievementsbutton.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: settingsScreen(); }
            Image {
                anchors.centerIn: parent
                width: vpx(24); height: vpx(24)
                sourceSize: Qt.size(vpx(24), vpx(24))
                source: "../assets/images/settingsicon.svg"
                layer.enabled: whiteBackground
                layer.effect: ColorOverlay { color: "black" }
                fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
            }
        }

        // Nav button labels — shown only when the button is highlighted
        Text {
            text: "Home"
            anchors { top: homebutton.bottom; topMargin: vpx(3); horizontalCenter: homebutton.horizontalCenter }
            color: whiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: vpx(11); font.bold: true
            opacity: homebutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "Discover"
            anchors { top: discoverbutton.bottom; topMargin: vpx(3); horizontalCenter: discoverbutton.horizontalCenter }
            color: whiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: vpx(11); font.bold: true
            opacity: discoverbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "RetroAchievements"
            anchors { top: achievementsbutton.bottom; topMargin: vpx(3); horizontalCenter: achievementsbutton.horizontalCenter }
            color: whiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: vpx(11); font.bold: true
            opacity: achievementsbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "Settings"
            anchors { top: settingsbutton.bottom; topMargin: vpx(3); horizontalCenter: settingsbutton.horizontalCenter }
            color: whiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: vpx(11); font.bold: true
            opacity: settingsbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
    }

    // ── Game list ─────────────────────────────────────────────────────────
    ListView {
    id: gamelist
        focus: true
        currentIndex: currentGameIndex

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
            playNav();
            if (currentIndex !== 0) currentIndex--;
            else homebutton.focus = true;
        }
        // Down/Left/Right handled here (not at root) because a focused vertical
        // ListView consumes Down internally before the root handler can fire —
        // which is why the nav sound was intermittent. accepted=true stops the
        // built-in navigation from double-moving.
        Keys.onDownPressed: {
            event.accepted = true;
            playNav();
            if (currentIndex !== count - 1) currentIndex++;
            else currentIndex = 0;
        }
        Keys.onLeftPressed: {
            event.accepted = true;
            playNav();
            currentIndex = Math.max(0, currentIndex - skipnum);
        }
        Keys.onRightPressed: {
            event.accepted = true;
            playNav();
            currentIndex = Math.min(count - 1, currentIndex + skipnum);
        }

        anchors {
            top: header.bottom; topMargin: globalMargin
            bottom: parent.bottom; bottomMargin: globalMargin
            left: parent.left
        }
        width: vpx(400)
        spacing: vpx(0); orientation: ListView.Vertical
        preferredHighlightBegin: gamelist.height / 2 - itemheight
        preferredHighlightEnd:   gamelist.height / 2
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 100
        clip: true

        model: displayModel

        delegate: Component {
            Item {
                width: ListView.view.width
                height: itemheight
                property bool selected: ListView.isCurrentItem && gamelist.activeFocus

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right; rightMargin: vpx(20)
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
                        font.pixelSize: vpx(25)
                        font.bold: true
                        text: modelData.title
                    }
                    Text {
                        id: titleText
                        text: modelData.title
                        height: titleClip.height
                        color: selected ? "white" : theme.text
                        font.family: subtitleFont.name
                        font.pixelSize: selected ? vpx(25) : vpx(19)
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

    // ── Sorting & Filters overlay ─────────────────────────────────────────
    Rectangle {
    id: filterPanel
        visible: filterOpen; z: 30
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.78)

        MouseArea { anchors.fill: parent; onClicked: { searchActive = false; filterOpen = false; gamelist.focus = true; } }

        Rectangle {
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
                font.family: titleFont.name; font.pixelSize: vpx(24); font.bold: true
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
                        text: "\uD83D\uDD0D"; font.pixelSize: vpx(15); width: vpx(22)
                        color: "white"; opacity: onRow ? 1 : 0.6
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: vpx(46); right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: searchActive
                              ? (nameFilter === "" ? "Type a name\u2026" : nameFilter)
                              : (nameFilter === "" ? "Name: (no filter)" : "Name: " + nameFilter)
                        color: onRow ? theme.accent : "white"
                        opacity: onRow ? 1 : 0.85
                        elide: Text.ElideRight
                        font.family: subtitleFont.name; font.pixelSize: vpx(20); font.bold: onRow
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
                        text: "\u2630"; font.pixelSize: vpx(15); width: vpx(22)
                        color: "white"; opacity: onRow ? 1 : 0.6
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: vpx(46); right: arrow.left; rightMargin: vpx(8); verticalCenter: parent.verticalCenter }
                        text: genreSelected.length === 0 ? "Genre: All"
                             : genreSelected.length === 1 ? "Genre: " + genreSelected[0]
                             : "Genre: " + genreSelected.length + " selected"
                        color: onRow ? theme.accent : "white"
                        opacity: onRow ? 1 : 0.85
                        elide: Text.ElideRight
                        font.family: subtitleFont.name; font.pixelSize: vpx(20); font.bold: onRow
                    }
                    Text {
                        id: arrow
                        anchors { right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: "\u25B8"; color: onRow ? theme.accent : "white"
                        opacity: onRow ? 1 : 0.6; font.pixelSize: vpx(18)
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
                            color: theme.accent; font.pixelSize: vpx(15); font.bold: true; width: vpx(22)
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(46); right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                            text: modelData
                            color: (onRow || isSel) ? theme.accent : "white"
                            opacity: onRow ? 1 : 0.85
                            elide: Text.ElideRight
                            font.family: subtitleFont.name; font.pixelSize: vpx(19); font.bold: onRow || isSel
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
                        text: "\u25A4"; font.pixelSize: vpx(15); width: vpx(22)
                        color: "white"; opacity: onRow ? 1 : 0.6
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: vpx(46); right: sysArrow.left; rightMargin: vpx(8); verticalCenter: parent.verticalCenter }
                        text: systemIndex < 0 ? "System: ALL" : "System: " + systemFilter
                        color: onRow ? theme.accent : "white"
                        opacity: onRow ? 1 : 0.85
                        elide: Text.ElideRight
                        font.family: subtitleFont.name; font.pixelSize: vpx(20); font.bold: onRow
                    }
                    Text {
                        id: sysArrow
                        anchors { right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: "\u25B8"; color: onRow ? theme.accent : "white"
                        opacity: onRow ? 1 : 0.6; font.pixelSize: vpx(18)
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
                            color: theme.accent; font.pixelSize: vpx(15); font.bold: true; width: vpx(22)
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(46); right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                            text: modelData.name
                            color: (onRow || isSel) ? theme.accent : "white"
                            opacity: onRow ? 1 : 0.85
                            elide: Text.ElideRight
                            font.family: subtitleFont.name; font.pixelSize: vpx(19); font.bold: onRow || isSel
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
                                color: theme.accent; font.pixelSize: vpx(16); font.bold: true
                                width: vpx(22)
                            }
                            Text {
                                anchors { left: parent.left; leftMargin: vpx(46); verticalCenter: parent.verticalCenter }
                                text: modelData.label
                                color: active ? theme.accent : "white"
                                opacity: active ? 1 : 0.85
                                font.family: subtitleFont.name; font.pixelSize: vpx(20); font.bold: active
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
                            color: theme.accent; font.pixelSize: vpx(16); font.bold: true
                            width: vpx(22)
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(46); verticalCenter: parent.verticalCenter }
                            text: "Favorites only"
                            color: favsOnly ? theme.accent : "white"
                            opacity: favsOnly ? 1 : 0.85
                            font.family: subtitleFont.name; font.pixelSize: vpx(20); font.bold: favsOnly
                        }
                        MouseArea { anchors.fill: parent; onClicked: { filterRow = sortFields.length + 3; favsOnly = !favsOnly; gamelist.currentIndex = 0; } }
                    }
                }

                // On-screen keyboard (shown when searching)
                Grid {
                    visible: searchActive
                    columns: keyCols
                    spacing: vpx(4)
                    width: parent.width

                    Repeater {
                        model: keyboardKeys
                        Rectangle {
                            width: (fieldCol.width - (keyCols - 1) * vpx(4)) / keyCols
                            height: vpx(42); radius: vpx(4)
                            property bool sel: keyIndex === index
                            property bool wide: modelData.length > 1 && modelData !== "SPACE" && modelData !== "DEL"
                            color: sel ? theme.accent : Qt.rgba(1,1,1,0.08)
                            Text {
                                anchors.centerIn: parent
                                text: modelData === "SPACE" ? "\u2423" : (modelData === "DEL" ? "\u232B" : modelData)
                                color: sel ? "white" : "white"
                                font.family: subtitleFont.name
                                font.pixelSize: wide ? vpx(12) : vpx(17)
                                font.bold: sel
                            }
                            MouseArea { anchors.fill: parent; onClicked: { keyIndex = index; pressKey(modelData); } }
                        }
                    }
                }
            }

            // Button-icon hint bar — swaps prompts per context (search / genre / sort)
            Row {
                anchors { bottom: parent.bottom; bottomMargin: vpx(12); right: parent.right; rightMargin: vpx(20) }
                spacing: vpx(22)

                Repeater {
                    model: searchActive    ? [ {a:"accept",t:"Type"},   {a:"cancel",t:"Done"} ]
                         : genrePickerOpen  ? [ {a:"accept",t:"Toggle"}, {a:"cancel",t:"Done"} ]
                         : systemPickerOpen ? [ {a:"accept",t:"Select"}, {a:"cancel",t:"Back"} ]
                         :                    [ {a:"accept",t:"Select"}, {a:"details",t:"Clear all"}, {a:"cancel",t:"Close"} ]
                    delegate: Row {
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
                            font.family: subtitleFont.name; font.pixelSize: vpx(15)
                        }
                    }
                }
            }
        }

        Keys.onUpPressed: {
            playNav();
            if (searchActive) { if (keyIndex >= keyCols) keyIndex -= keyCols; }
            else if (genrePickerOpen) { if (genrePickerIndex > 0) genrePickerIndex--; }
            else if (systemPickerOpen) { if (systemPickerIndex > 0) systemPickerIndex--; }
            else if (filterRow > 0) filterRow--;
        }
        Keys.onDownPressed: {
            playNav();
            if (searchActive) { var ni = keyIndex + keyCols; if (ni < keyboardKeys.length) keyIndex = ni; else keyIndex = keyboardKeys.length - 1; }
            else if (genrePickerOpen) { if (genrePickerIndex < genreOptions.length - 1) genrePickerIndex++; }
            else if (systemPickerOpen) { if (systemPickerIndex < systemOptions.length - 1) systemPickerIndex++; }
            else if (filterRow < sortFields.length + 3) filterRow++;
        }
        Keys.onLeftPressed: {
            playNav();
            if (searchActive && (keyIndex % keyCols) !== 0) keyIndex--;
            else if (genrePickerOpen) genrePickerIndex = Math.max(0, genrePickerIndex - 10);
            else if (systemPickerOpen) systemPickerIndex = Math.max(0, systemPickerIndex - 10);
        }
        Keys.onRightPressed: {
            playNav();
            if (searchActive && (keyIndex % keyCols) !== (keyCols - 1) && keyIndex < keyboardKeys.length - 1) keyIndex++;
            else if (genrePickerOpen) genrePickerIndex = Math.min(genreOptions.length - 1, genrePickerIndex + 10);
            else if (systemPickerOpen) systemPickerIndex = Math.min(systemOptions.length - 1, systemPickerIndex + 10);
        }
        Keys.onPressed: {
            if (searchActive) {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; playAccept(); pressKey(keyboardKeys[keyIndex]); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; playBack(); searchActive = false; }
                if (api.keys.isDetails(event) && !event.isAutoRepeat) { event.accepted = true; playAccept(); searchActive = false; }
                return;
            }
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
                event.accepted = true; playAccept();
                if (filterRow === 0) activateSearch();
                else if (filterRow === 1) openGenrePicker();
                else if (filterRow === 2) openSystemPicker();
                else if (filterRow <= sortFields.length + 2) selectSort(sortFields[filterRow - 3].key);
                else if (filterRow === sortFields.length + 3) { favsOnly = !favsOnly; gamelist.currentIndex = 0; }
            }
            if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                event.accepted = true; playBack(); filterOpen = false; gamelist.focus = true;
            }
            if (api.keys.isDetails(event) && !event.isAutoRepeat) {
                event.accepted = true; playToggle(); clearAllFilters();
            }
        }
    }

    // ── Input ─────────────────────────────────────────────────────────────
    // Down/Left/Right live on the gamelist ListView itself (see above); handling
    // them at root is unreliable because the focused ListView consumes Down first.

    Keys.onPressed: {
        // A — launch the game directly
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamelist.focus && currentGame) { launchGame(currentGame); }
        }
        // B — back
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamelist.focus) { previousScreen(); }
        }
        // X — open Sorting & Filters
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamelist.focus) {
                playAccept();
                var fi = sortFields.map(function(f){ return f.key; }).indexOf(sortField);
                filterRow = fi >= 0 ? fi + 2 : 0;
                filterOpen = true;
                searchActive = false;
                genrePickerOpen = false;
                filterPanel.forceActiveFocus();
            }
        }
        // Y — game details page
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamelist.focus) { gameDetails(currentGame); }
        }
        // LT — previous letter group
        if (api.keys.isPageUp(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamelist.focus) { playToggle(); jumpToPrevLetter(); }
        }
        // RT — next letter group
        if (api.keys.isPageDown(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamelist.focus) { playToggle(); jumpToNextLetter(); }
        }
        // LB / RB — jump straight up to the nav bar from anywhere in the list
        if ((api.keys.isPrevPage(event) || api.keys.isNextPage(event)) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamelist.focus) { playNav(); homebutton.focus = true; }
        }
    }

    // ── Helpbar: A Launch, X Filters, Y Game Details, B Back ──────────────
    ListModel {
        id: allGamesHelpModel
        ListElement { name: "Back";         button: "cancel"  }
        ListElement { name: "Game Details"; button: "filters" }
        ListElement { name: "Filters";      button: "details" }
        ListElement { name: "Launch";       button: "accept"  }
    }

    onFocusChanged: {
        if (focus) {
            currentHelpbarModel     = allGamesHelpModel;
            currentCustomCollection = listAllGames.collection;
            // Returning from game details: re-center the list on the current game
            restoreViewTimer.restart();
        }
    }
}
