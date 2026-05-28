// AllGamesMenu.qml — All games across all collections
import QtQuick 2.15
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.12
import "../Global"
import "../Lists"
import "../utils.js" as Utils
import SortFilterProxyModel 0.2

FocusScope {
id: root

    property real itemheight: vpx(50)
    property int  skipnum: 10

    // ── Data ──────────────────────────────────────────────────────────────
    ListAllGames {
    id: listAllGames
        max: api.allGames.count
    }

    // ── Sort / filter state ───────────────────────────────────────────────
    property string sortField:   "sortBy"        // sortBy|lastPlayed|rating|releaseYear|favorite
    property int    sortDir:     Qt.AscendingOrder
    property bool   filterOpen:  false
    property int    filterRow:   0
    property string nameFilter:   ""
    property bool   searchActive: false   // on-screen keyboard open

    // Genre filter
    property string genreFilter:      ""   // "" = All
    property bool   genrePickerOpen:  false
    property var    genreOptions:     []   // ["All", ...] built lazily & cached
    property int    genrePickerIndex: 0

    // ── Game preview art — screenshot backdrop + logo + 3D box (2D fallback)
    // Independent of the Box Art (GameView) setting.
    property string artScreenshot: {
        if (!currentGame) return "";
        var ss = currentGame.assets.screenshotList;
        if (ss && ss.length) return ss[0];
        return Utils.fanArt(currentGame) || "";
    }
    property string artLogo: currentGame ? (Utils.logo(currentGame) || currentGame.assets.logo || "") : ""
    property string artBoxSource: {
        if (!currentGame) return "";
        var three = Utils.get3dBoxArt(currentGame);
        if (three) return three;                       // 3D box
        return currentGame.assets.boxFront || "";      // 2D fallback
    }
    // SNES & N64 boxes are oversized — scale just those two down a bit
    property real boxScale: {
        if (!currentGame || currentGame.collections.count === 0) return 1.0;
        var c = currentGame.collections.get(0);
        var s = ((c.shortName ? c.shortName : "") + " " + (c.name ? c.name : "")).toLowerCase();
        if (s.indexOf("snes") >= 0 || s.indexOf("super nintendo") >= 0
            || s.indexOf("n64") >= 0 || s.indexOf("nintendo 64") >= 0)
            return 0.72;
        return 1.0;
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
    function genreToPattern(g) {
        if (g === "" || g === "All") return "";
        var esc = g.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
        return "(^|,\\s*)" + esc + "(\\s*,|$)";
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
        var want = (genreFilter === "") ? "All" : genreFilter;
        var idx = genreOptions.indexOf(want);
        genrePickerIndex = idx >= 0 ? idx : 0;
        genrePickerOpen = true;
    }
    function selectGenre(g) {
        genreFilter = (g === "All") ? "" : g;
        gamelist.currentIndex = 0;
        genrePickerOpen = false;
    }

    // ── Display model ─────────────────────────────────────────────────────
    SortFilterProxyModel {
    id: displayModel
        sourceModel: listAllGames.games
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
                pattern: genreToPattern(genreFilter)
                caseSensitivity: Qt.CaseInsensitive
                enabled: genreFilter !== ""
            }
        ]
    }

    function getCurrentGame(idx) {
        return listAllGames.currentGame(displayModel.mapToSource(idx));
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
        currentGameIndex = 0;
        if (displayModel.count > 0) currentGame = getCurrentGame(0);
    }

    // Vertical accent line dividing the text list from the game details
    Rectangle {
    id: vDivider
        anchors {
            left: gamelist.right; leftMargin: globalMargin / 2
            top: header.bottom; topMargin: globalMargin
            bottom: parent.bottom; bottomMargin: globalMargin + helpMargin
        }
        width: vpx(2)
        color: theme.accent
    }

    // ── Game preview (top of right side): screenshot + logo + 3D/2D box ───
    Item {
    id: boxArt
        anchors {
            top: header.bottom; topMargin: globalMargin
            left: gamelist.right; leftMargin: globalMargin
            right: parent.right; rightMargin: globalMargin
            bottom: metaPanel.top; bottomMargin: vpx(14)
        }
        clip: true

        // Screenshot backdrop (fills the area)
        Image {
        id: artScreenshotImg
            anchors.fill: parent
            asynchronous: true
            source: artScreenshot
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: status === Image.Ready
        }
        // Fallback backdrop when there's no screenshot
        Rectangle {
            anchors.fill: parent
            visible: !artScreenshotImg.visible
            color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.10)
        }
        // Gentle top/bottom darkening so the logo and box read clearly
        Rectangle {
            anchors.fill: parent
            visible: artScreenshotImg.visible
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.45) }
                GradientStop { position: 0.35; color: Qt.rgba(0, 0, 0, 0.10) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.50) }
            }
        }

        // Game logo (top)
        Image {
        id: artLogoImg
            anchors { top: parent.top; topMargin: vpx(14); right: parent.right; rightMargin: vpx(14) }
            width:  parent.width * 0.52
            height: parent.height * 0.26
            asynchronous: true
            source: artLogo
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignRight
            verticalAlignment: Image.AlignTop
            smooth: true
            visible: status === Image.Ready
        }

        // 3D box art (2D fallback) — bottom-left
        Image {
        id: artBoxImg
            anchors { left: parent.left; leftMargin: vpx(12); bottom: parent.bottom; bottomMargin: vpx(12) }
            width:  parent.width * 0.52 * boxScale
            height: parent.height * 0.64 * boxScale
            asynchronous: true
            source: artBoxSource
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignLeft
            verticalAlignment: Image.AlignBottom
            smooth: true
            visible: status === Image.Ready
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
        height: vpx(150)
        visible: currentGame ? true : false

        // Accent line above the metadata
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: vpx(2); color: theme.accent
        }

        Row {
            anchors { top: parent.top; topMargin: vpx(16); left: parent.left; right: parent.right; bottom: parent.bottom }
            spacing: vpx(30)

            // Left column
            Column {
                width: (parent.width - vpx(30)) / 2
                spacing: vpx(11)

                Column {
                    width: parent.width; spacing: vpx(1)
                    Text { text: "Publisher"; color: theme.accent; font.family: subtitleFont.name; font.pixelSize: vpx(13); font.bold: true }
                    Text { width: parent.width; text: currentGame && currentGame.publisher ? currentGame.publisher : "—"; color: theme.text; font.family: subtitleFont.name; font.pixelSize: vpx(17); elide: Text.ElideRight }
                }
                Column {
                    width: parent.width; spacing: vpx(1)
                    Text { text: "Developer"; color: theme.accent; font.family: subtitleFont.name; font.pixelSize: vpx(13); font.bold: true }
                    Text { width: parent.width; text: currentGame && currentGame.developer ? currentGame.developer : "—"; color: theme.text; font.family: subtitleFont.name; font.pixelSize: vpx(17); elide: Text.ElideRight }
                }
                Column {
                    width: parent.width; spacing: vpx(1)
                    Text { text: "Released"; color: theme.accent; font.family: subtitleFont.name; font.pixelSize: vpx(13); font.bold: true }
                    Text { width: parent.width; text: currentGame && currentGame.releaseYear > 0 ? currentGame.releaseYear : "—"; color: theme.text; font.family: subtitleFont.name; font.pixelSize: vpx(17); elide: Text.ElideRight }
                }
            }

            // Right column
            Column {
                width: (parent.width - vpx(30)) / 2
                spacing: vpx(11)

                Column {
                    width: parent.width; spacing: vpx(1)
                    Text { text: "Genre"; color: theme.accent; font.family: subtitleFont.name; font.pixelSize: vpx(13); font.bold: true }
                    Text { width: parent.width; text: currentGame && currentGame.genre ? currentGame.genre : "—"; color: theme.text; font.family: subtitleFont.name; font.pixelSize: vpx(17); elide: Text.ElideRight }
                }
                Column {
                    width: parent.width; spacing: vpx(1)
                    Text { text: "Players"; color: theme.accent; font.family: subtitleFont.name; font.pixelSize: vpx(13); font.bold: true }
                    Text { width: parent.width; text: currentGame && currentGame.players > 0 ? currentGame.players + "P" : "—"; color: theme.text; font.family: subtitleFont.name; font.pixelSize: vpx(17); elide: Text.ElideRight }
                }
                Column {
                    width: parent.width; spacing: vpx(1)
                    Text { text: "Rating"; color: theme.accent; font.family: subtitleFont.name; font.pixelSize: vpx(13); font.bold: true }
                    Text { width: parent.width; text: currentGame && currentGame.rating > 0 ? Math.round(currentGame.rating * 100) + "%" : "—"; color: theme.text; font.family: subtitleFont.name; font.pixelSize: vpx(17); elide: Text.ElideRight }
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

        // Accent line under the header
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: vpx(2); color: theme.accent
        }

        Image {
        id: libIcon
            source: "../assets/images/gamesandapps.png"
            anchors { left: parent.left; leftMargin: globalMargin; verticalCenter: parent.verticalCenter }
            height: vpx(40); width: vpx(40)
            fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
        }
        Text {
            anchors { left: libIcon.right; leftMargin: vpx(10); verticalCenter: parent.verticalCenter }
            text: "My Games & Apps"
            color: theme.text; font.family: titleFont.name; font.pixelSize: vpx(22); font.bold: true
        }
        Text {
            anchors { left: parent.left; leftMargin: globalMargin; bottom: parent.bottom; bottomMargin: vpx(6) }
            text: displayModel.count + " games"
            color: theme.text; opacity: 0.7; font.family: subtitleFont.name; font.pixelSize: vpx(14)
        }

        // Nav buttons (home / discover / achievements / settings)
        Rectangle {
        id: homebutton
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -vpx(81) }
            color: focus ? theme.accent : "transparent"; opacity: focus ? 1 : 0.6
            Keys.onDownPressed:  { sfxNav.play(); gamelist.focus = true; }
            Keys.onRightPressed: { sfxNav.play(); discoverbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; showcaseScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; sfxBack.play(); gamelist.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: showcaseScreen(); }
            Canvas {
                anchors { fill: parent; margins: vpx(7) }
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset();
                    var w = width, h = height;
                    ctx.fillStyle = "white";
                    ctx.globalAlpha = homebutton.focus ? 1.0 : 0.85;
                    // roof
                    ctx.beginPath();
                    ctx.moveTo(w*0.5, h*0.05);
                    ctx.lineTo(w*0.95, h*0.5);
                    ctx.lineTo(w*0.05, h*0.5);
                    ctx.closePath(); ctx.fill();
                    // body
                    ctx.fillRect(w*0.18, h*0.5, w*0.64, h*0.42);
                    // door cutout
                    ctx.clearRect(w*0.42, h*0.62, w*0.16, h*0.30);
                }
                Connections { target: homebutton; onFocusChanged: parent.requestPaint() }
            }
        }

        Rectangle {
        id: discoverbutton
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -vpx(27) }
            color: focus ? theme.accent : "transparent"; opacity: focus ? 1 : 0.6
            Keys.onDownPressed:  { sfxNav.play(); gamelist.focus = true; }
            Keys.onLeftPressed:  { sfxNav.play(); homebutton.focus = true; }
            Keys.onRightPressed: { sfxNav.play(); achievementsbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; discoverScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; sfxBack.play(); gamelist.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: discoverScreen(); }
            Canvas {
                anchors { fill: parent; margins: vpx(6) }
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset();
                    var cx = width/2, cy = height/2, r = Math.min(cx,cy)-1;
                    ctx.globalAlpha = discoverbutton.focus ? 1.0 : 0.85;
                    ctx.strokeStyle = "white"; ctx.lineWidth = 1.5;
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2); ctx.stroke();
                    ctx.fillStyle = "white";
                    ctx.beginPath(); ctx.moveTo(cx, cy-r*0.65); ctx.lineTo(cx+r*0.30, cy+r*0.10); ctx.lineTo(cx, cy+r*0.20); ctx.lineTo(cx-r*0.30, cy+r*0.10); ctx.closePath(); ctx.fill();
                    ctx.globalAlpha = 0.35;
                    ctx.beginPath(); ctx.moveTo(cx, cy+r*0.65); ctx.lineTo(cx-r*0.30, cy-r*0.10); ctx.lineTo(cx, cy-r*0.20); ctx.lineTo(cx+r*0.30, cy-r*0.10); ctx.closePath(); ctx.fill();
                }
                Connections { target: discoverbutton; onFocusChanged: parent.requestPaint() }
            }
        }

        Rectangle {
        id: achievementsbutton
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: vpx(27) }
            color: focus ? theme.accent : "transparent"; opacity: focus ? 1 : 0.6
            Keys.onDownPressed:  { sfxNav.play(); gamelist.focus = true; }
            Keys.onLeftPressed:  { sfxNav.play(); discoverbutton.focus = true; }
            Keys.onRightPressed: { sfxNav.play(); settingsbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; achievementsScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; sfxBack.play(); gamelist.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: achievementsScreen(); }
            Text {
                anchors.centerIn: parent
                text: "🏆"; font.pixelSize: vpx(18)
                opacity: achievementsbutton.focus ? 1 : 0.7
            }
        }

        Rectangle {
        id: settingsbutton
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: vpx(81) }
            color: focus ? theme.accent : "transparent"; opacity: focus ? 1 : 0.6
            Keys.onDownPressed: { sfxNav.play(); gamelist.focus = true; }
            Keys.onLeftPressed: { sfxNav.play(); achievementsbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; settingsScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; sfxBack.play(); gamelist.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: settingsScreen(); }
            Image {
                anchors { fill: parent; margins: vpx(10) }
                source: "../assets/images/settingsicon.svg"
                fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
            }
        }

        // Nav button labels — shown only when the button is highlighted
        Text {
            text: "Home"
            anchors { top: homebutton.bottom; topMargin: vpx(3); horizontalCenter: homebutton.horizontalCenter }
            color: "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: vpx(11); font.bold: true
            opacity: homebutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "Discover"
            anchors { top: discoverbutton.bottom; topMargin: vpx(3); horizontalCenter: discoverbutton.horizontalCenter }
            color: "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: vpx(11); font.bold: true
            opacity: discoverbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "RetroAchievements"
            anchors { top: achievementsbutton.bottom; topMargin: vpx(3); horizontalCenter: achievementsbutton.horizontalCenter }
            color: "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: vpx(11); font.bold: true
            opacity: achievementsbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "Settings"
            anchors { top: settingsbutton.bottom; topMargin: vpx(3); horizontalCenter: settingsbutton.horizontalCenter }
            color: "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
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
            }
        }
        // The proxy model populates asynchronously; when it first fills,
        // set the box art / metadata for the current row immediately
        onCountChanged: {
            if (count > 0) {
                if (currentIndex < 0) currentIndex = 0;
                currentGame = getCurrentGame(currentIndex < 0 ? 0 : currentIndex);
            }
        }

        Keys.onUpPressed: {
            event.accepted = true;
            sfxNav.play();
            if (currentIndex !== 0) currentIndex--;
            else homebutton.focus = true;
        }
        // Down/Left/Right handled here (not at root) because a focused vertical
        // ListView consumes Down internally before the root handler can fire —
        // which is why the nav sound was intermittent. accepted=true stops the
        // built-in navigation from double-moving.
        Keys.onDownPressed: {
            event.accepted = true;
            sfxNav.play();
            if (currentIndex !== count - 1) currentIndex++;
            else currentIndex = 0;
        }
        Keys.onLeftPressed: {
            event.accepted = true;
            sfxNav.play();
            currentIndex = Math.max(0, currentIndex - skipnum);
        }
        Keys.onRightPressed: {
            event.accepted = true;
            sfxNav.play();
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
                property bool selected: ListView.isCurrentItem

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
                Text {
                    text: modelData.title
                    height: parent.height
                    anchors {
                        left: parent.left; leftMargin: vpx(20)
                        right: parent.right; rightMargin: vpx(30)
                    }
                    color: selected ? "white" : theme.text
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(20)
                    font.bold: selected
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    opacity: selected ? 1 : 0.35
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
                color: theme.text
                font.family: titleFont.name; font.pixelSize: vpx(24); font.bold: true
                anchors { top: parent.top; topMargin: vpx(18); left: parent.left; leftMargin: vpx(24) }
            }

            Column {
            id: fieldCol
                anchors { top: titleTxt.bottom; topMargin: vpx(14); left: parent.left; right: parent.right; leftMargin: vpx(16); rightMargin: vpx(16) }
                spacing: vpx(6)

                // Name row — shows the current search text
                Rectangle {
                    visible: !genrePickerOpen
                    width: parent.width; height: vpx(52); radius: vpx(6)
                    property bool onRow: filterRow === 0 || searchActive
                    color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"

                    Text {
                        anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: "\uD83D\uDD0D"; font.pixelSize: vpx(15); width: vpx(22)
                        color: theme.text; opacity: onRow ? 1 : 0.6
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: vpx(46); right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: searchActive
                              ? (nameFilter === "" ? "Type a name\u2026" : nameFilter)
                              : (nameFilter === "" ? "Name: (no filter)" : "Name: " + nameFilter)
                        color: onRow ? theme.accent : theme.text
                        opacity: onRow ? 1 : 0.85
                        elide: Text.ElideRight
                        font.family: subtitleFont.name; font.pixelSize: vpx(20); font.bold: onRow
                    }
                    MouseArea { anchors.fill: parent; onClicked: { filterRow = 0; activateSearch(); } }
                }

                // Genre row — opens the genre picker
                Rectangle {
                    visible: !searchActive && !genrePickerOpen
                    width: parent.width; height: vpx(52); radius: vpx(6)
                    property bool onRow: filterRow === 1
                    color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"

                    Text {
                        anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: "\u2630"; font.pixelSize: vpx(15); width: vpx(22)
                        color: theme.text; opacity: onRow ? 1 : 0.6
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: vpx(46); right: arrow.left; rightMargin: vpx(8); verticalCenter: parent.verticalCenter }
                        text: genreFilter === "" ? "Genre: All" : "Genre: " + genreFilter
                        color: onRow ? theme.accent : theme.text
                        opacity: onRow ? 1 : 0.85
                        elide: Text.ElideRight
                        font.family: subtitleFont.name; font.pixelSize: vpx(20); font.bold: onRow
                    }
                    Text {
                        id: arrow
                        anchors { right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: "\u25B8"; color: onRow ? theme.accent : theme.text
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
                        property bool isSel: modelData === (genreFilter === "" ? "All" : genreFilter)
                        color: onRow ? Qt.rgba(1,1,1,0.12) : "transparent"
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                            text: isSel ? "\u2713" : "  "
                            color: theme.accent; font.pixelSize: vpx(15); font.bold: true; width: vpx(22)
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(46); right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                            text: modelData
                            color: (onRow || isSel) ? theme.accent : theme.text
                            opacity: onRow ? 1 : 0.85
                            elide: Text.ElideRight
                            font.family: subtitleFont.name; font.pixelSize: vpx(19); font.bold: onRow || isSel
                        }
                        MouseArea { anchors.fill: parent; onClicked: { genrePickerIndex = index; selectGenre(modelData); } }
                    }
                }

                // Sort fields (shown when neither the keyboard nor genre picker is open)
                Column {
                    visible: !searchActive && !genrePickerOpen
                    width: parent.width
                    spacing: vpx(6)

                    Repeater {
                        model: sortFields
                        Rectangle {
                            width: parent.width; height: vpx(48); radius: vpx(6)
                            property bool active: sortField === modelData.key
                            property bool onRow:  filterRow === index + 2
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
                                color: active ? theme.accent : theme.text
                                opacity: active ? 1 : 0.85
                                font.family: subtitleFont.name; font.pixelSize: vpx(20); font.bold: active
                            }
                            MouseArea { anchors.fill: parent; onClicked: { filterRow = index + 2; selectSort(modelData.key); } }
                        }
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
                                color: sel ? "white" : theme.text
                                font.family: subtitleFont.name
                                font.pixelSize: wide ? vpx(12) : vpx(17)
                                font.bold: sel
                            }
                            MouseArea { anchors.fill: parent; onClicked: { keyIndex = index; pressKey(modelData); } }
                        }
                    }
                }
            }

            Text {
                anchors { bottom: parent.bottom; bottomMargin: vpx(14); horizontalCenter: parent.horizontalCenter }
                text: searchActive    ? "\u25B2\u25BC\u25C0\u25B6 keys    A type    B done"
                     : genrePickerOpen ? "\u25B2\u25BC navigate    A choose genre    B back"
                                       : "\u25B2\u25BC navigate    A select    B close"
                color: theme.text; opacity: 0.4
                font.family: subtitleFont.name; font.pixelSize: vpx(13)
            }
        }

        Keys.onUpPressed: {
            sfxNav.play();
            if (searchActive) { if (keyIndex >= keyCols) keyIndex -= keyCols; }
            else if (genrePickerOpen) { if (genrePickerIndex > 0) genrePickerIndex--; }
            else if (filterRow > 0) filterRow--;
        }
        Keys.onDownPressed: {
            sfxNav.play();
            if (searchActive) { var ni = keyIndex + keyCols; if (ni < keyboardKeys.length) keyIndex = ni; else keyIndex = keyboardKeys.length - 1; }
            else if (genrePickerOpen) { if (genrePickerIndex < genreOptions.length - 1) genrePickerIndex++; }
            else if (filterRow < sortFields.length + 1) filterRow++;
        }
        Keys.onLeftPressed: {
            sfxNav.play();
            if (searchActive && (keyIndex % keyCols) !== 0) keyIndex--;
        }
        Keys.onRightPressed: {
            sfxNav.play();
            if (searchActive && (keyIndex % keyCols) !== (keyCols - 1) && keyIndex < keyboardKeys.length - 1) keyIndex++;
        }
        Keys.onPressed: {
            if (searchActive) {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; sfxAccept.play(); pressKey(keyboardKeys[keyIndex]); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; sfxBack.play(); searchActive = false; }
                if (api.keys.isDetails(event) && !event.isAutoRepeat) { event.accepted = true; sfxAccept.play(); searchActive = false; }
                return;
            }
            if (genrePickerOpen) {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; sfxAccept.play(); selectGenre(genreOptions[genrePickerIndex]); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; sfxBack.play(); genrePickerOpen = false; }
                if (api.keys.isDetails(event) && !event.isAutoRepeat) { event.accepted = true; sfxAccept.play(); genrePickerOpen = false; }
                return;
            }
            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true; sfxAccept.play();
                if (filterRow === 0) activateSearch();
                else if (filterRow === 1) openGenrePicker();
                else selectSort(sortFields[filterRow - 2].key);
            }
            if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                event.accepted = true; sfxBack.play(); filterOpen = false; gamelist.focus = true;
            }
            if (api.keys.isDetails(event) && !event.isAutoRepeat) {
                event.accepted = true; sfxAccept.play(); filterOpen = false; gamelist.focus = true;
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
            if (!filterOpen && gamelist.focus && currentGame) { sfxAccept.play(); currentGame.launch(); }
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
                sfxAccept.play();
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
            if (!filterOpen && gamelist.focus) { sfxToggle.play(); jumpToPrevLetter(); }
        }
        // RT — next letter group
        if (api.keys.isPageDown(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && gamelist.focus) { sfxToggle.play(); jumpToNextLetter(); }
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
        }
    }
}
