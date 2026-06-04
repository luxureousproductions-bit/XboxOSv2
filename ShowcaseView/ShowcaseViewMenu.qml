// gameOS theme
// Copyright (C) 2018-2020 Seth Powell 
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

import QtQuick 2.15
import QtQuick.Layouts 1.15
import SortFilterProxyModel 0.2
import QtGraphicalEffects 1.15
import QtMultimedia 5.15
import QtQml.Models 2.15
import "../Global"
import "../GridView"
import "../Lists"
import "../utils.js" as Utils

FocusScope {
id: root

    // Pull in our custom lists and define
    ListAllGames    { id: listNone;        max: 0 }
    ListAllGames    { id: listAllGames;    max: settings.ShowcaseColumns }
    ListFavorites   { id: listFavorites;   max: settings.ShowcaseColumns }
    ListLastPlayed  { id: listLastPlayed;  max: settings.ShowcaseColumns; omitApplication: settings.OmitApplicationFromShowcase === "Yes"; omitEmulator: settings.OmitEmulatorFromShowcase === "Yes" }
    ListMostPlayed  { id: listMostPlayed;  max: settings.ShowcaseColumns; omitApplication: settings.OmitApplicationFromShowcase === "Yes"; omitEmulator: settings.OmitEmulatorFromShowcase === "Yes" }
    ListRecommended { id: listRecommended; max: settings.ShowcaseColumns; omitApplication: settings.OmitApplicationFromShowcase === "Yes"; omitEmulator: settings.OmitEmulatorFromShowcase === "Yes" }
    ListPublisher   { id: listPublisher;   max: settings.ShowcaseColumns; publisher: randoPub;   omitApplication: settings.OmitApplicationFromShowcase === "Yes"; omitEmulator: settings.OmitEmulatorFromShowcase === "Yes" }
    ListDeveloper   { id: listDeveloper;   max: settings.ShowcaseColumns; developer: randoDev;   omitApplication: settings.OmitApplicationFromShowcase === "Yes"; omitEmulator: settings.OmitEmulatorFromShowcase === "Yes" }
    ListGenre       { id: listGenre;       max: settings.ShowcaseColumns; genre: randoGenre;     omitApplication: settings.OmitApplicationFromShowcase === "Yes"; omitEmulator: settings.OmitEmulatorFromShowcase === "Yes" }
    ListGenre       { id: listGenre2;      max: settings.ShowcaseColumns; genre: randoGenre2;    omitApplication: settings.OmitApplicationFromShowcase === "Yes"; omitEmulator: settings.OmitEmulatorFromShowcase === "Yes" }

    property var featuredCollection: listFavorites
    property var highlightedGame: null

    // Every Color Layout now has its own PNG, so use it directly (matches game tiles)
    function heroBorderImage(layoutName) {
        return layoutName;
    }

    // Hero box art for the resume/last-played game, per the "Hero box art" setting.
    // Falls back to other art types if the chosen one is missing, so it's never blank.
    function heroArtSource(g) {
        if (!g) return "";
        var fan  = g.assets.background || "";
        var shot = (g.assets.screenshots && g.assets.screenshots.length) ? g.assets.screenshots[0] : "";
        var box  = g.assets.boxFront || "";
        var mode = settings.HeroBoxArt;
        if (mode === "Boxfront")   return box  || fan  || shot || "";
        if (mode === "Screenshot") return shot || fan  || box  || "";
        return fan || shot || box || "";   // Fanart (default)
    }
    property var collection1: getCollection(settings.ShowcaseCollection1, settings.ShowcaseCollection1_Thumbnail)
    property var collection2: getCollection(settings.ShowcaseCollection2, settings.ShowcaseCollection2_Thumbnail)
    property var collection3: getCollection(settings.ShowcaseCollection3, settings.ShowcaseCollection3_Thumbnail)
    property var collection4: getCollection(settings.ShowcaseCollection4, settings.ShowcaseCollection4_Thumbnail)
    property var collection5: getCollection(settings.ShowcaseCollection5, settings.ShowcaseCollection5_Thumbnail)
    property var collection6: getCollection(settings.ShowcaseCollection6, settings.ShowcaseCollection6_Thumbnail)

    // Sorted mapping of strip position -> api.collections index, per the
    // "System sort" setting. The system tiles read api.collections THROUGH this
    // array, so they can be ordered alphabetically, by release year, or by
    // manufacturer+year without altering Pegasus's own collection order.
    property var sortedColl: buildSortedColl()
    function buildSortedColl() {
        var n = api.collections.count;
        var items = [];
        for (var i = 0; i < n; i++) {
            var c = api.collections.get(i);
            items.push({
                idx:   i,
                name:  (c.name || "").toLowerCase(),
                year:  Utils.systemYear(c.shortName),
                maker: Utils.systemMaker(c.shortName),
                count: c.games ? c.games.count : 0,
                pin:   systemPinRank(c.shortName, c.name)
            });
        }
        var mode = settings.SystemSort;
        items.sort(function(a, b) {
            // Pinned systems (Android, then Android games) always lead, in pin order,
            // regardless of the chosen sort.
            if (a.pin !== b.pin) {
                if (a.pin === -1) return 1;
                if (b.pin === -1) return -1;
                return a.pin - b.pin;
            }
            if (a.pin !== -1) return 0;

            var alpha = (a.name < b.name) ? -1 : (a.name > b.name ? 1 : 0);

            if (mode === "Alphabetical (Z-A)")
                return -alpha;

            // older labels "Release year" map to oldest-first
            if (mode === "Release year (oldest)" || mode === "Release year") {
                if (a.year !== b.year) {
                    if (a.year === 9999) return 1;   // unknown year sinks to the end
                    if (b.year === 9999) return -1;
                    return a.year - b.year;          // oldest first
                }
                return alpha;
            }
            if (mode === "Release year (newest)") {
                if (a.year !== b.year) {
                    if (a.year === 9999) return 1;   // unknown year sinks to the end
                    if (b.year === 9999) return -1;
                    return b.year - a.year;          // newest first
                }
                return alpha;
            }
            if (mode === "Manufacturer") {
                if (a.maker !== b.maker) return a.maker < b.maker ? -1 : 1;  // "zzz" unknown sinks
                if (a.year !== b.year) return a.year - b.year;
                return alpha;
            }
            if (mode === "Game count (most)") {
                if (a.count !== b.count) return b.count - a.count;
                return alpha;
            }
            if (mode === "Game count (fewest)") {
                if (a.count !== b.count) return a.count - b.count;
                return alpha;
            }
            if (mode === "Default") {
                return a.idx - b.idx;   // Pegasus's own collection order
            }
            // Alphabetical (A-Z) — default (also catches the old "Alphabetical" value)
            return alpha;
        });
        var arr = [];
        for (var k = 0; k < items.length; k++) arr.push(items[k].idx);
        return arr;
    }
    // Returns a pin rank for systems that must always lead the list (0 = first).
    // Android, then Android games; -1 means "not pinned" (normal sort).
    function systemPinRank(sn, nm) {
        var s = (sn || "").toLowerCase();
        var nmm = (nm || "").toLowerCase();
        if (s === "android" || nmm === "android") return 0;
        if (s === "apps" || s === "androidgames" || nmm === "apps" || nmm === "android games" || nmm === "androidgames") return 1;
        return -1;
    }

    function getCollection(collectionName, collectionThumbnail) {
        var collection = {
            enabled: true,
        };

        var width = root.width - globalMargin * 2;

        switch (collectionThumbnail) {
            case "Square":
                collection.itemWidth = (width / 6.0);
                collection.itemHeight = collection.itemWidth;
                break;
            case "Tall":
                collection.itemWidth = (width / 8.0);
                collection.itemHeight = collection.itemWidth / settings.TallRatio;
                break;
            case "Wide":
            default:
                collection.itemWidth = (width / 4.0);
                collection.itemHeight = collection.itemWidth * settings.WideRatio;
                break;
            
        }

        collection.height = collection.itemHeight + vpx(40) + globalMargin

        switch (collectionName) {
            case "Favorites":
                collection.search = listFavorites;
                break;
            case "Recently Played":
                collection.search = listLastPlayed;
                break;
            case "Most Played":
                collection.search = listMostPlayed;
                break;
            case "Recommended":
                collection.search = listRecommended;
                break;
            case "Top by Publisher":
                collection.search = listPublisher;
                break;
            case "Top by Developer":
                collection.search = listDeveloper;
                break;
            case "Top by Genre":
                collection.search = listGenre;
                break;
            case "Top by Genre 2":
                collection.search = listGenre2;
                break;
            case "None":
                collection.enabled = false;
                collection.height = 0;

                collection.search = listNone;
                break;
            default:
                collection.search = listAllGames;
                break;
        }

        collection.title = collection.search.collection.name;
        return collection;
    }

    // Pegasus populates api.allGames fully before any QML runs, so these
    // property initializers evaluate once at component creation with the
    // complete game library available — no timer or debounce needed.
    property string randoPub:    Utils.returnRandom(Utils.uniqueValuesArray('publisher')) || ''
    property string randoDev:    Utils.returnRandom(Utils.uniqueValuesArray('developer')) || ''
    property string randoGenre:  Utils.returnRandom(Utils.uniqueGenreValues()) || ''
    property string randoGenre2: Utils.returnRandom(Utils.uniqueGenreValues()) || ''

    function refreshLists() {
        var omitEmu = settings.OmitEmulatorFromShowcase === "Yes";
        var pub = Utils.returnRandom(Utils.uniqueValuesArray('publisher')) || '';
        var dev = Utils.returnRandom(Utils.uniqueValuesArray('developer')) || '';
        var genres = Utils.uniqueGenreValues(omitEmu);
        var genre = Utils.returnRandom(genres) || '';
        var filtered = genres.filter(function(g) { return g !== genre; });
        var pick = filtered.length > 0 ? filtered : genres;
        var genre2 = Utils.returnRandom(pick) || '';
        randoPub = pub;
        randoDev = dev;
        randoGenre = genre;
        randoGenre2 = genre2;
        api.memory.set("Showcase randoPub", pub);
        api.memory.set("Showcase randoDev", dev);
        api.memory.set("Showcase randoGenre", genre);
        api.memory.set("Showcase randoGenre2", genre2);
        listRecommended.refresh();
        currentHelpbarModel = gridviewHelpModel;
    }

    property bool ftue: featuredCollection.games.count == 0

    function storeIndices(secondary) {
        storedHomePrimaryIndex = mainList.currentIndex;
        if (secondary)
            storedHomeSecondaryIndex = secondary;
    }

    Component.onDestruction: storeIndices();

    Component.onCompleted: {
        if (api.memory.has("To Game")) {
            // Returning from a game launch — restore saved random values so the
            // lists look exactly as the user left them
            randoPub    = api.memory.get("Showcase randoPub")    || "";
            randoDev    = api.memory.get("Showcase randoDev")    || "";
            randoGenre  = api.memory.get("Showcase randoGenre")  || "";
            randoGenre2 = api.memory.get("Showcase randoGenre2") || "";
        } else {
            // Fresh startup — persist the property-initializer values so they
            // survive a game launch and can be restored on the way back
            api.memory.set("Showcase randoPub",    randoPub);
            api.memory.set("Showcase randoDev",    randoDev);
            api.memory.set("Showcase randoGenre",  randoGenre);
            api.memory.set("Showcase randoGenre2", randoGenre2);
        }
    }
    
    anchors.fill: parent

    // Set initial fanart background on first load
    Timer {
        interval: 300; running: true; repeat: false
        onTriggered: {
            if      (list1.selected && list1.search) highlightedGame = list1.search.currentGame(list1.currentIndex)
            else if (list2.selected && list2.search) highlightedGame = list2.search.currentGame(list2.currentIndex)
            else if (list3.selected && list3.search) highlightedGame = list3.search.currentGame(list3.currentIndex)
            else if (list4.selected && list4.search) highlightedGame = list4.search.currentGame(list4.currentIndex)
            else if (list5.selected && list5.search) highlightedGame = list5.search.currentGame(list5.currentIndex)
            else if (list6.selected && list6.search) highlightedGame = list6.search.currentGame(list6.currentIndex)
        }
    }

    // User's custom background (background.png) — shows when fanart is OFF
    Image {
    id: customBg
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        z: -1
        source: (settings.CustomBackground === "Yes") ? "../assets/images/backgrounds/background.png" : ""
        opacity: (settings.CustomBackground === "Yes" && settings.ShowcaseBackgroundArt !== "Yes") ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: 400 } }
    }

    // Fanart / screenshot background with crossfade
    Image {
    id: bgImage1
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        opacity: 0
        z: 0
        Behavior on opacity { PropertyAnimation { duration: 700 } }
    }

    Image {
    id: bgImage2
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        opacity: 0
        z: 0
        Behavior on opacity { PropertyAnimation { duration: 700 } }
    }

    // Dim overlay so content stays readable
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.45
        z: 1
    }

    property bool bgToggle: false
    property string bgSource: {
        if (settings.ShowcaseBackgroundArt !== "Yes") return "";
        if (!highlightedGame) return "";
        return highlightedGame.assets.background || highlightedGame.assets.screenshots[0] || "";
    }

    onBgSourceChanged: {
        if (!bgSource) {
            bgImage1.opacity = 0;
            bgImage2.opacity = 0;
            return;
        }
        if (bgToggle) {
            bgImage1.source = bgSource;
            bgImage1.opacity = parseFloat(settings.ShowcaseBackgroundOpacity) || 0.55;
            bgImage2.opacity = 0;
        } else {
            bgImage2.source = bgSource;
            bgImage2.opacity = parseFloat(settings.ShowcaseBackgroundOpacity) || 0.55;
            bgImage1.opacity = 0;
        }
        bgToggle = !bgToggle;
    }


    Item {
    id: ftueContainer

        width: parent.width
        height: vpx(360)
        visible: ftue
        opacity: {
            switch (mainList.currentIndex) {
                case 0:
                    return 1;
                case 1:
                    return 0.3;
                case 2:
                    return 0.1;
                case -1:
                    return 0.3;
                default:
                    return 0
            }
        }
        Behavior on opacity { PropertyAnimation { duration: 1000; easing.type: Easing.OutQuart; easing.amplitude: 2.0; easing.period: 1.5 } }

        /*Image {
            anchors.fill: parent
            source: "../assets/images/ftueBG01.jpeg"
            sourceSize { width: root.width; height: root.height}
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
        }*/

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.5
        }

        Video {
        id: videocomponent

            anchors.fill: parent
            source: "../assets/video/ftue.mp4"
            fillMode: VideoOutput.PreserveAspectCrop
            muted: true
            loops: MediaPlayer.Infinite
            autoPlay: true

            OpacityAnimator {
                target: videocomponent;
                from: 0;
                to: 1;
                duration: 1000;
                running: true;
            }

        }

        Image {
        id: ftueLogo

            width: vpx(350)
            anchors { left: parent.left; leftMargin: globalMargin }
            // Logo file chosen by Settings > Home page > Xbox Logo. "None" hides it.
            source: settings.XboxLogo === "None" ? "" :
                    settings.XboxLogo === "Logo2" ? "../assets/images/Xbox-logo2.png" :
                                                    "../assets/images/Xbox-logo.png"
            visible: settings.XboxLogo !== "None"
            // Logo Color Match: tints the logo to the current Color Layout accent.
            // layer.enabled: false when off — zero render cost.
            layer.enabled: settings.LogoColorMatch === "Yes"
            layer.effect: ColorOverlay { color: theme.accent }
            sourceSize { width: 350; height: 250}
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            anchors.centerIn: parent
        }

        Text {
            text: "Try adding some favorite games"
            
            horizontalAlignment: Text.AlignHCenter
            anchors { bottom: parent.bottom; bottomMargin: vpx(75) }
            width: parent.width
            height: contentHeight
            color: theme.text
            font.family: subtitleFont.name
            font.pixelSize: vpx(16)
            opacity: 0.5
            visible: false
        }
    }

    Item {
    id: header

        width: parent.width
        height: vpx(90)
        z: 10
        Image {
        id: logo

            width: vpx(150)
            anchors { left: parent.left; leftMargin: globalMargin }
            // Logo file chosen by Settings > Home page > Xbox Logo. "None" hides it.
            source: settings.XboxLogo === "None" ? "" :
                    settings.XboxLogo === "Logo2" ? "../assets/images/Xbox-logo2.png" :
                                                    "../assets/images/Xbox-logo.png"
            // Logo Color Match: tints the logo to the current Color Layout accent.
            layer.enabled: settings.LogoColorMatch === "Yes"
            layer.effect: ColorOverlay { color: theme.accent }
            sourceSize { width: 150; height: 100}
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            anchors.verticalCenter: parent.verticalCenter
            visible: !ftueContainer.visible && settings.XboxLogo !== "None" && settings.XboxLogo !== "RetroAchievements"
        }

        // ── RetroAchievements header card ─────────────────────────────────
        // Replaces the Xbox logo when Settings > Home page > Xbox Logo = RetroAchievements.
        // Shows the same profile info as the RA overview (avatar, name, points, member).
        Item {
        id: raHeaderCard

            anchors { left: parent.left; leftMargin: globalMargin; verticalCenter: parent.verticalCenter }
            width: vpx(250); height: vpx(64)
            visible: !ftueContainer.visible && settings.XboxLogo === "RetroAchievements"

            // Pull the profile if RA credentials exist but the avatar hasn't been fetched yet
            function ensureProfile() {
                if (visible && cheevosData.raUserName !== "" && cheevosData.avatarUrl === "")
                    cheevosData.loadUserProfile();
            }
            Component.onCompleted: ensureProfile()
            onVisibleChanged:      ensureProfile()

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: vpx(10)

                // Circular avatar with accent ring
                Item {
                    width: vpx(52); height: vpx(52)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: cheevosData.avatarUrl !== ""
                    Image {
                    id: raHeaderAvatar
                        anchors.fill: parent
                        source: cheevosData.avatarUrl
                        fillMode: Image.PreserveAspectCrop
                        smooth: true; asynchronous: true
                        sourceSize { width: 64; height: 64 }
                        layer.enabled: true
                        layer.smooth: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: raHeaderAvatar.width; height: raHeaderAvatar.height
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

                // Username / points / member-since
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: vpx(2)
                    visible: cheevosData.raUserName !== ""

                    Text {
                        text: cheevosData.raUserName
                        color: theme.text
                        font.family: subtitleFont.name
                        font.pixelSize: vpx(17); font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: cheevosData.pointsText
                        color: theme.text
                        font.family: subtitleFont.name
                        font.pixelSize: vpx(12)
                        opacity: 0.7
                        visible: cheevosData.pointsText !== ""
                    }
                    Text {
                        text: cheevosData.memberText
                        color: theme.text
                        font.family: subtitleFont.name
                        font.pixelSize: vpx(10)
                        opacity: 0.5
                        visible: cheevosData.memberText !== ""
                    }
                }
            }

            // Fallback hint if RA isn't set up yet
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Sign in to RetroAchievements"
                color: theme.text
                opacity: 0.4
                font.family: subtitleFont.name
                font.pixelSize: vpx(13)
                visible: cheevosData.raUserName === ""
            }
        }
        Rectangle {
        id: homebutton

            width:  vpx(36); height: vpx(36); radius: height / 2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -vpx(81) }
            color:   focus ? theme.accent : "transparent"
            opacity: focus ? 1 : 0.6
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 0
                radius: 8
                samples: 17
                color: "#cc000000"
            }

            onFocusChanged: {
                if (focus) playNav();
                mainList.currentIndex = focus ? -1 : 0;
            }
            Keys.onDownPressed:  { playNav(); mainList.forceActiveFocus(); mainList.currentIndex = 1; }
            Keys.onRightPressed: discoverbutton.focus = true;
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; allGamesScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; mainList.focus = true; }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: settings.MouseHover == "Yes"
                onEntered: homebutton.focus = true; onExited: homebutton.focus = false;
                onClicked: allGamesScreen();
            }
            Image {
                anchors { fill: parent; margins: vpx(2) }
                source: "../assets/images/gamesandapps.png"
                fillMode: Image.PreserveAspectFit
                smooth: true; asynchronous: true
                opacity: homebutton.focus ? 1.0 : 0.85
            }
        }

        Rectangle {
        id: discoverbutton

            width:  vpx(36); height: vpx(36); radius: height / 2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -vpx(27) }
            color:   focus ? theme.accent : "transparent"
            opacity: focus ? 1 : 0.6
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 0
                radius: 8
                samples: 17
                color: "#cc000000"
            }

            onFocusChanged: {
                if (focus) playNav();
                mainList.currentIndex = focus ? -1 : 0;
            }
            Keys.onDownPressed:  { playNav(); mainList.forceActiveFocus(); mainList.currentIndex = 1; }
            Keys.onLeftPressed:  homebutton.focus = true;
            Keys.onRightPressed: achievementsbutton.focus = true;
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; discoverScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; mainList.focus = true; }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: settings.MouseHover == "Yes"
                onEntered: discoverbutton.focus = true; onExited: discoverbutton.focus = false;
                onClicked: discoverScreen();
            }
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

            width:  vpx(36); height: vpx(36); radius: height / 2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: vpx(27) }
            color:   focus ? theme.accent : "transparent"
            opacity: focus ? 1 : 0.6
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 0
                radius: 8
                samples: 17
                color: "#cc000000"
            }

            onFocusChanged: {
                if (focus) playNav();
                mainList.currentIndex = focus ? -1 : 0;
            }
            Keys.onDownPressed:  { playNav(); mainList.forceActiveFocus(); mainList.currentIndex = 1; }
            Keys.onLeftPressed:  discoverbutton.focus = true;
            Keys.onRightPressed: settingsbutton.focus = true;
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; achievementsScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; mainList.focus = true; }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: settings.MouseHover == "Yes"
                onEntered: achievementsbutton.focus = true; onExited: achievementsbutton.focus = false;
                onClicked: achievementsScreen();
            }
        }

        Text {
        id: achievementsTrophyIcon
            text: "🏆"
            anchors.centerIn: achievementsbutton
            font.pixelSize: vpx(18)
            opacity: achievementsbutton.focus ? 1 : 0.7
        }

        Rectangle {
        id: settingsbutton

            width:  vpx(36); height: vpx(36); radius: height / 2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: vpx(81) }
            color:   focus ? theme.accent : "transparent"
            opacity: focus ? 1 : 0.6
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 0
                radius: 8
                samples: 17
                color: "#cc000000"
            }

            onFocusChanged: {
                if (focus) playNav();
                mainList.currentIndex = focus ? -1 : 0;
            }
            Keys.onDownPressed:  { playNav(); mainList.forceActiveFocus(); mainList.currentIndex = 1; }
            Keys.onLeftPressed:  achievementsbutton.focus = true;
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; settingsScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; mainList.focus = true; }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: settings.MouseHover == "Yes"
                onEntered: settingsbutton.focus = true; onExited: settingsbutton.focus = false;
                onClicked: settingsScreen();
            }
        }

        Image {
        id: settingsicon
            width: height; height: vpx(24)
            anchors.centerIn: settingsbutton
            smooth: true; asynchronous: true
            source: "../assets/images/settingsicon.svg"
            opacity: root.focus ? 0.8 : 0.5
        }

        // ── Nav button labels — shown only for the highlighted button ─────
        Text {
            text: "Full Library"
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
		
       Text {
        id: sysTime

            visible: settings.ShowClock !== "No"
            // Direct binding — updates instantly when Show Clock setting changes
            text: Qt.formatTime(new Date(), "h:mm AP")

            function set() {
                sysTime.text = Qt.formatTime(new Date(), "h:mm AP");
            }

            Timer {
                id: textTimer
                interval: 60000
                repeat: true
                running: true
                triggeredOnStart: true
                onTriggered: sysTime.set()
            }

            height: vpx(40)
            anchors {
                top: parent.top; topMargin: vpx(5)
                right: parent.right; rightMargin: vpx(25)
            }
            color: "white"
            font.pixelSize: vpx(18)
            font.family: subtitleFont.name
            horizontalAlignment: Text.Right
            verticalAlignment: Text.AlignVCenter
        }

        // Battery percentage display
        Row {
        id: batteryDisplay

            property bool batteryAvailable: !isNaN(api.device.batteryPercent) && api.device.batteryPercent >= 0

            spacing: vpx(4)
            anchors {
                right: sysTime.left; rightMargin: vpx(10)
                top: parent.top; topMargin: vpx(12)
            }
            // Hide when no battery is present or setting is disabled
            visible: settings.ShowBattery !== "No" && batteryAvailable

            // Lightning bolt shown while charging
            Text {
                text: "⚡"
                font.pixelSize: vpx(12)
                color: "#64B5F6"
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
                visible: api.device.batteryCharging
            }

            Text {
                property int pct: batteryDisplay.batteryAvailable
                                  ? Math.round(api.device.batteryPercent * 100) : 0
                text: pct + "%"
                // Turn red when critically low and not charging
                color: (pct <= 20 && !api.device.batteryCharging) ? "#EF5350" : "white"
                font.pixelSize: vpx(16)
                font.family: subtitleFont.name
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // WiFi signal indicator — three concentric arcs drawn via Canvas.
        // Connectivity is checked every 30 s with a HEAD request to 1.1.1.1;
        // arcs show full-brightness when reachable, dimmed when offline.
        Canvas {
        id: wifiIndicator

            width: vpx(26)
            height: vpx(20)
            visible: settings.ShowWifi !== "No"
            anchors {
                right: batteryDisplay.left; rightMargin: vpx(8)
                top: parent.top; topMargin: vpx(14)
            }

            property bool online: false

            Timer {
                id: wifiTimer
                interval: 30000
                repeat: true
                running: true
                triggeredOnStart: true
                onTriggered: {
                    var xhr = new XMLHttpRequest();
                    xhr.onreadystatechange = function() {
                        if (xhr.readyState === XMLHttpRequest.DONE) {
                            wifiIndicator.online = xhr.status >= 200 && xhr.status < 300;
                        }
                    };
                    xhr.onerror = function() { wifiIndicator.online = false; };
                    xhr.open("HEAD", "https://1.1.1.1", true);
                    xhr.timeout = 5000;
                    xhr.send();
                }
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();

                var cx         = width / 2;
                var cy         = height - vpx(1);           // arcs radiate upward from here
                var outerR     = cy - vpx(2);               // largest radius fits within canvas
                var startAngle = Math.PI * 1.25;            // 225° — upper-left
                var endAngle   = Math.PI * 1.75;            // 315° — upper-right
                var alpha      = online ? 0.9 : 0.3;

                ctx.strokeStyle = "white";
                ctx.lineCap     = "round";
                ctx.globalAlpha = alpha;

                // Outer arc
                ctx.lineWidth = vpx(2);
                ctx.beginPath();
                ctx.arc(cx, cy, outerR, startAngle, endAngle, false);
                ctx.stroke();

                // Middle arc
                ctx.beginPath();
                ctx.arc(cx, cy, outerR * 0.64, startAngle, endAngle, false);
                ctx.stroke();

                // Inner arc
                ctx.beginPath();
                ctx.arc(cx, cy, outerR * 0.31, startAngle, endAngle, false);
                ctx.stroke();

                // Centre dot
                ctx.fillStyle = "white";
                ctx.beginPath();
                ctx.arc(cx, cy, vpx(2), 0, Math.PI * 2, false);
                ctx.fill();
            }

            onOnlineChanged: requestPaint()
            Component.onCompleted: requestPaint()
        }
    }

    // Using an object model to build the list
    ObjectModel {
    id: mainModel

        // Empty space — background fanart shows through (Xbox dashboard style)
        Item {
            width: parent.width
            height: vpx(360)
        }

        // Collections list
        // ── Top row: Resume box + system collections ───────────────────────
        FocusScope {
        id: topRow

            property bool selected: ListView.isCurrentItem
            property int myIndex: ObjectModel.index
            // Hero box / system tile size. NOT tied to any collection row.
            // NOTE: the divisor is inverse — HIGHER value = SMALLER tiles.
            // tileDivisor and growScale are tuned TOGETHER so the GROWN (selected)
            // size stays constant while the RESTING tile shrinks: the peak,
            // tileSz * growScale, is held. ~40% growth here (Xbox-like). To shrink
            // the resting tile further, raise tileDivisor AND raise growScale by
            // the same ratio to keep the same peak (peak ≈ width/5.08 * 1.25).
            property real tileDivisor: 7.62
            property real tileSz: (root.width - globalMargin * 2) / tileDivisor
            property real growScale: 1.50
            focus: selected
            width: root.width
            height: tileSz + globalMargin * 2

            onFocusChanged: { if (focus && platformlist.currentIndex < 0) platformlist.currentIndex = platformlist.savedIndex; }
            onSelectedChanged: {
                if (selected && settings.ShowcaseBackgroundArt === "Yes") {
                    if (platformlist.currentIndex <= 0) {
                        if (platformlist.resumeGame) highlightedGame = platformlist.resumeGame;
                    } else {
                        var coll = api.collections.get(root.sortedColl[platformlist.currentIndex - 1]);
                        if (coll && coll.games.count > 0) {
                            var randomIdx = Math.floor(Math.random() * coll.games.count);
                            highlightedGame = coll.games.get(randomIdx);
                        }
                    }
                }
            }

        ListView {
        id: platformlist

            focus: topRow.focus
            property var resumeGame: listLastPlayed.games.count > 0 ? listLastPlayed.currentGame(0) : null
            height: topRow.tileSz + globalMargin * 2
            clip: false
            anchors {
                left: parent.left; leftMargin: globalMargin
                right: parent.right; rightMargin: globalMargin
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(10)
            orientation: ListView.Horizontal
            highlightRangeMode: ListView.NoHighlightRange
            snapMode: ListView.SnapToItem
            highlightMoveDuration: 100
            keyNavigationWraps: false
            
            // Whole-tile alignment of the scroll position. Shared by both the live
            // navigation handler AND the first-load positioning so the gap between
            // the hero box and the system tiles is identical at all times.
            function alignToIndex(idx) {
                var unit = topRow.tileSz + spacing;
                if (unit <= 0) return;
                var visibleCount = Math.max(1, Math.floor((width + spacing) / unit));
                var firstVisible = Math.round(contentX / unit);
                if (idx < firstVisible)
                    firstVisible = idx;
                else if (idx > firstVisible + visibleCount - 1)
                    firstVisible = idx - visibleCount + 1;
                firstVisible = Math.max(0, firstVisible);
                contentX = firstVisible * unit;
            }

            onCurrentIndexChanged: {
                if (currentIndex < 0) return;   // deselected (focus moved away) — leave the scroll position alone
                // Align the list to whole-tile boundaries (same routine used on load).
                alignToIndex(currentIndex);
                // Update background fanart for the highlighted strip item
                if (topRow.selected && settings.ShowcaseBackgroundArt === "Yes") {
                    if (currentIndex <= 0) {
                        if (resumeGame) highlightedGame = resumeGame;
                    } else {
                        var coll = api.collections.get(root.sortedColl[currentIndex - 1]);
                        if (coll && coll.games.count > 0) {
                            var randomIdx = Math.floor(Math.random() * coll.games.count);
                            highlightedGame = coll.games.get(randomIdx);
                        }
                    }
                }
            }

            property int savedIndex: root.sortedColl.indexOf(currentCollectionIndex) + 1   // strip index (hero = 0)
            onFocusChanged: {
                if (focus) {
                    currentIndex = savedIndex;
                    if (settings.ShowcaseBackgroundArt === "Yes") {
                        if (currentIndex <= 0) {
                            if (resumeGame) highlightedGame = resumeGame;
                        } else {
                            var coll = api.collections.get(root.sortedColl[currentIndex - 1]);
                            if (coll && coll.games.count > 0) {
                                var randomIdx = Math.floor(Math.random() * coll.games.count);
                                highlightedGame = coll.games.get(randomIdx);
                            }
                        }
                    }
                } else {
                    savedIndex = currentIndex;
                    currentIndex = -1;
                }
            }

            Component.onCompleted: alignToIndex(savedIndex)

            model: api.collections.count + 1   // index 0 = hero, 1.. = platforms
            delegate: Rectangle {
                id: tile
                property bool isHero: index === 0
                property var  coll: isHero ? null : api.collections.get(root.sortedColl[index - 1])
                property bool selected: ListView.isCurrentItem && platformlist.focus
                // Xbox-style: tiles to either side of the selected one slide a bit to make room
                property real navShift: {
                    // Only make room when a tile is actually enlarged — i.e. the list is
                    // focused. On first load the hero is the current item but isn't grown
                    // yet (focus hasn't arrived), so shifting the tiles here opened an
                    // empty "room" gap beside the hero until the first scroll. Gating on
                    // focus keeps the spacing identical at all times.
                    if (!platformlist.focus || platformlist.currentIndex < 0 || index === platformlist.currentIndex) return 0;
                    var sel  = platformlist.currentIndex;
                    var last = platformlist.count - 1;
                    var grow = topRow.tileSz * (topRow.growScale - 1);   // full growth, in px
                    // The first (hero) and last tiles grow toward the INSIDE only (outer
                    // border pinned), so the tiles beside them must slide by the FULL
                    // growth. A middle tile grows from its centre, so its two neighbours
                    // split the growth (half each).
                    if (sel === 0)    return grow;     // hero grows right -> inside tiles slide right
                    if (sel === last) return -grow;    // last grows left  -> inside tiles slide left
                    return (index < sel) ? -(grow / 2) : (grow / 2);
                }
                width: topRow.tileSz
                height: topRow.tileSz
                radius: vpx(6)
                color: selected ? theme.accent : theme.secondary
                Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                // Grow from the bottom edge so the bottom stays put. The first (hero) tile
                // grows up-and-right (left border pinned) and the last tile grows up-and-left
                // (right border pinned) so neither outer border is clipped at the screen edge;
                // every middle tile grows up from its centre.
                transformOrigin: index === 0 ? Item.BottomLeft
                                 : (index === platformlist.count - 1 ? Item.BottomRight : Item.Bottom)
                scale: selected ? topRow.growScale : 1.0
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                // Animated horizontal shift so neighbors slide out of the way of the selected tile
                transform: Translate {
                    x: navShift
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }
                // Selected always renders above its neighbors so the border can't be clipped behind them
                z: selected ? 1 : 0
                border.width: vpx(1)
                border.color: "#19FFFFFF"
                anchors.verticalCenter: parent.verticalCenter

                // ── HERO (index 0): resume / last-played screenshot + title ──
                // heroBg + title bar share a single OpacityMask so the bar's BOTTOM
                // corners follow the rounded tile edge while its TOP corners stay square.
                Item {
                    id: heroClipper
                    visible: isHero
                    anchors.fill: parent
                    layer.enabled: isHero
                    layer.smooth: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: heroClipper.width
                            height: heroClipper.height
                            radius: tile.radius
                        }
                    }

                    Image {
                        id: heroBg
                        anchors.fill: parent
                        // All art types crop-fill the square at their native aspect (box art
                        // keeps its proportions, with top/bottom cropped) — no stretching.
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true; smooth: true
                        source: heroArtSource(platformlist.resumeGame)
                        opacity: selected ? 1 : 0.5
                    }

                    // Game logo overlay — only for the Screenshot / Fanart hero art modes.
                    // (Boxfront already shows the title on the box, so it gets no logo.)
                    Image {
                        id: heroLogo
                        anchors.fill: parent
                        anchors.margins: vpx(16)
                        anchors.bottomMargin: vpx(42)   // leave room for the title bar
                        fillMode: Image.PreserveAspectFit
                        horizontalAlignment: Image.AlignHCenter
                        verticalAlignment: Image.AlignVCenter
                        asynchronous: true; smooth: true
                        source: (platformlist.resumeGame && platformlist.resumeGame.assets.logo)
                                ? platformlist.resumeGame.assets.logo : ""
                        visible: source != ""
                                 && (settings.HeroBoxArt === "Screenshot" || settings.HeroBoxArt === "Fanart")
                        opacity: selected ? 1 : 0.5
                    }

                    Rectangle {
                        // Full-width bar across the bottom — shown only on highlight now.
                        // No radius — the parent OpacityMask clips the bottom corners to
                        // match tile.radius automatically.
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: vpx(36); color: "#99000000"
                        opacity: selected ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(8); right: parent.right; rightMargin: vpx(6); verticalCenter: parent.verticalCenter }
                            text: platformlist.resumeGame ? platformlist.resumeGame.title : ""
                            color: "white"; font.family: subtitleFont.name
                            font.pixelSize: vpx(11); font.bold: true
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignLeft
                        }
                    }
                }

                // ── PLATFORM (index >= 1): system background + logo ──

                // System background art — place files in assets/images/systembackground/
                // named to match the system logo (e.g. "snes.png", "nintendo switch.jpg").
                // Tries .png → .jpg → .jpeg → .webp in order; stops at first match.
                Image {
                id: sysBg
                    property string basePath: (!isHero && coll)
                        ? "../assets/images/systembackground/" + Utils.processPlatformName(coll.shortName) : ""
                    property var exts: [".png", ".jpg", ".jpeg", ".webp"]
                    property int extIdx: 0
                    onBasePathChanged: extIdx = 0      // reset when tile recycles to a new system
                    onStatusChanged: {
                        if (status === Image.Error && extIdx < exts.length - 1)
                            extIdx = extIdx + 1;       // try next extension
                    }
                    visible: !isHero && status === Image.Ready
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true; smooth: true
                    source: basePath !== "" ? basePath + exts[extIdx] : ""
                    opacity: selected ? 0.9 : 0.6
                    // Rounded-corner clip just on the image
                    layer.enabled: !isHero
                    layer.smooth: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: sysBg.width
                            height: sysBg.height
                            radius: tile.radius
                        }
                    }
                }

                Image {
                id: collectionlogo
                    visible: !isHero
                    anchors.fill: parent
                    anchors.margins: vpx(15)
                    source: (!isHero && coll) ? "../assets/images/logospng/" + Utils.processPlatformName(coll.shortName) + ".png" : ""
                    sourceSize { width: 512; height: 512 }
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    opacity: selected ? 1 : 0.2
                }
                Text {
                id: platformname
                    visible: !isHero && collectionlogo.status == Image.Error
                    text: coll ? coll.name : ""
                    anchors { fill: parent; margins: vpx(10) }
                    color: theme.text
                    opacity: selected ? 1 : 0.2
                    font.pixelSize: vpx(18)
                    font.family: subtitleFont.name
                    font.bold: true
                    style: Text.Outline; styleColor: theme.main
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                    lineHeight: 0.8
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                // System name bar (experiment) — appears on highlight with the system name
                Rectangle {
                    visible: !isHero && opacity > 0
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: vpx(36)
                    radius: vpx(6)
                    color: "#99000000"
                    opacity: (!isHero && selected) ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                    Text {
                        anchors { left: parent.left; leftMargin: vpx(8); right: parent.right; rightMargin: vpx(6); verticalCenter: parent.verticalCenter }
                        text: coll ? coll.name : ""
                        color: "white"; font.family: subtitleFont.name
                        font.pixelSize: vpx(11); font.bold: true
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                    }
                }

                // Accent frame: hero when selected; platform when selected AND system background loaded
                // (platforms without a background keep the current accent-fill look instead)
                Rectangle {
                    anchors.fill: parent
                    visible: selected && (isHero || sysBg.status === Image.Ready)
                    color: "transparent"
                    radius: vpx(6)
                    border.color: theme.accent
                    border.width: vpx(5)
                }

                // Animated highlight — flashes the frame white when the AnimateHighlight setting is on
                Rectangle {
                    id: highlightPulse
                    anchors.fill: parent
                    visible: selected && settings.AnimateHighlight === "Yes"
                    color: "transparent"
                    radius: vpx(6)
                    border.color: "#ffffff"
                    border.width: vpx(5)
                    opacity: 0   // start invisible so it can't pop in at peak brightness
                    SequentialAnimation on opacity {
                        running: highlightPulse.visible
                        loops: Animation.Infinite
                        PropertyAction { target: highlightPulse; property: "opacity"; value: 0 }
                        NumberAnimation { to: 1; duration: 200 }
                        NumberAnimation { to: 0; duration: 500 }
                        PauseAnimation  { duration: 200 }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: settings.MouseHover == "Yes"
                    onEntered: { playNav(); mainList.currentIndex = topRow.ObjectModel.index; platformlist.currentIndex = index; }
                    onClicked: {
                        if (selected) {
                            if (isHero) { if (platformlist.resumeGame) { playAccept(); platformlist.resumeGame.launch(); } }
                            else { currentCollectionIndex = root.sortedColl[index - 1]; softwareScreen(); }
                        } else {
                            mainList.currentIndex = topRow.ObjectModel.index;
                            platformlist.currentIndex = index;
                        }
                    }
                }
            }

            // List specific input
            Keys.onLeftPressed: {
                playNav();
                if (currentIndex > 0) decrementCurrentIndex();
                else currentIndex = count - 1;   // hero -> last tile
            }
            Keys.onRightPressed: {
                playNav();
                if (currentIndex < count - 1) incrementCurrentIndex();
                else currentIndex = 0;            // last tile -> hero
            }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    if (currentIndex <= 0) {
                        if (resumeGame) { playAccept(); resumeGame.launch(); }
                    } else {
                        currentCollectionIndex = root.sortedColl[currentIndex - 1];
                        softwareScreen();
                    }
                }
            }

        }

        }

        HorizontalCollection {
        id: list1
            property bool selected: ListView.isCurrentItem
            property var currentList: list1
            property var collection: collection1

            enabled: collection.enabled
            visible: collection.enabled

            height: collection.height

            itemWidth: collection.itemWidth
            itemHeight: collection.itemHeight

            title: collection.title
            search: collection.search

            focus: selected
            width: root.width - globalMargin * 2
            x: globalMargin - vpx(8)

            savedIndex: (storedHomePrimaryIndex === currentList.ObjectModel.index) ? storedHomeSecondaryIndex : 0

            onActivateSelected: storedHomeSecondaryIndex = currentIndex;
            onActivate: { if (!selected) { mainList.currentIndex = currentList.ObjectModel.index; } }
            onListHighlighted: { playNav(); mainList.currentIndex = currentList.ObjectModel.index; }
            onCurrentIndexChanged: { if (selected) highlightedGame = search ? search.currentGame(currentIndex) : null; }
            onSelectedChanged: { if (selected) highlightedGame = search ? search.currentGame(currentIndex) : null; }
        }

        HorizontalCollection {
        id: list2
            property bool selected: ListView.isCurrentItem
            property var currentList: list2
            property var collection: collection2

            enabled: collection.enabled
            visible: collection.enabled

            height: collection.height

            itemWidth: collection.itemWidth
            itemHeight: collection.itemHeight

            title: collection.title
            search: collection.search

            focus: selected
            width: root.width - globalMargin * 2
            x: globalMargin - vpx(8)

            savedIndex: (storedHomePrimaryIndex === currentList.ObjectModel.index) ? storedHomeSecondaryIndex : 0

            onActivateSelected: storedHomeSecondaryIndex = currentIndex;
            onActivate: { if (!selected) { mainList.currentIndex = currentList.ObjectModel.index; } }
            onListHighlighted: { playNav(); mainList.currentIndex = currentList.ObjectModel.index; }
            onCurrentIndexChanged: { if (selected) highlightedGame = search ? search.currentGame(currentIndex) : null; }
            onSelectedChanged: { if (selected) highlightedGame = search ? search.currentGame(currentIndex) : null; }
        }

        HorizontalCollection {
        id: list3
            property bool selected: ListView.isCurrentItem
            property var currentList: list3
            property var collection: collection3

            enabled: collection.enabled
            visible: collection.enabled

            height: collection.height

            itemWidth: collection.itemWidth
            itemHeight: collection.itemHeight

            title: collection.title
            search: collection.search

            focus: selected
            width: root.width - globalMargin * 2
            x: globalMargin - vpx(8)

            savedIndex: (storedHomePrimaryIndex === currentList.ObjectModel.index) ? storedHomeSecondaryIndex : 0

            onActivateSelected: storedHomeSecondaryIndex = currentIndex;
            onActivate: { if (!selected) { mainList.currentIndex = currentList.ObjectModel.index; } }
            onListHighlighted: { playNav(); mainList.currentIndex = currentList.ObjectModel.index; }
            onCurrentIndexChanged: { if (selected) highlightedGame = search ? search.currentGame(currentIndex) : null; }
            onSelectedChanged: { if (selected) highlightedGame = search ? search.currentGame(currentIndex) : null; }
        }

        HorizontalCollection {
        id: list4
            property bool selected: ListView.isCurrentItem
            property var currentList: list4
            property var collection: collection4

            enabled: collection.enabled
            visible: collection.enabled

            height: collection.height

            itemWidth: collection.itemWidth
            itemHeight: collection.itemHeight

            title: collection.title
            search: collection.search

            focus: selected
            width: root.width - globalMargin * 2
            x: globalMargin - vpx(8)

            savedIndex: (storedHomePrimaryIndex === currentList.ObjectModel.index) ? storedHomeSecondaryIndex : 0

            onActivateSelected: storedHomeSecondaryIndex = currentIndex;
            onActivate: { if (!selected) { mainList.currentIndex = currentList.ObjectModel.index; } }
            onListHighlighted: { playNav(); mainList.currentIndex = currentList.ObjectModel.index; }
            onCurrentIndexChanged: { if (selected) highlightedGame = search ? search.currentGame(currentIndex) : null; }
            onSelectedChanged: { if (selected) highlightedGame = search ? search.currentGame(currentIndex) : null; }
        }

        HorizontalCollection {
        id: list5
            property bool selected: ListView.isCurrentItem
            property var currentList: list5
            property var collection: collection5

            enabled: collection.enabled
            visible: collection.enabled

            height: collection.height

            itemWidth: collection.itemWidth
            itemHeight: collection.itemHeight

            title: collection.title
            search: collection.search

            focus: selected
            width: root.width - globalMargin * 2
            x: globalMargin - vpx(8)

            savedIndex: (storedHomePrimaryIndex === currentList.ObjectModel.index) ? storedHomeSecondaryIndex : 0

            onActivateSelected: storedHomeSecondaryIndex = currentIndex;
            onActivate: { if (!selected) { mainList.currentIndex = currentList.ObjectModel.index; } }
            onListHighlighted: { playNav(); mainList.currentIndex = currentList.ObjectModel.index; }
            onCurrentIndexChanged: { if (selected) highlightedGame = search ? search.currentGame(currentIndex) : null; }
            onSelectedChanged: { if (selected) highlightedGame = search ? search.currentGame(currentIndex) : null; }
        }

        HorizontalCollection {
        id: list6
            property bool selected: ListView.isCurrentItem
            property var currentList: list6
            property var collection: collection6

            enabled: collection.enabled
            visible: collection.enabled

            height: collection.height

            itemWidth: collection.itemWidth
            itemHeight: collection.itemHeight

            title: collection.title
            search: collection.search

            focus: selected
            width: root.width - globalMargin * 2
            x: globalMargin - vpx(8)

            savedIndex: (storedHomePrimaryIndex === currentList.ObjectModel.index) ? storedHomeSecondaryIndex : 0

            onActivateSelected: storedHomeSecondaryIndex = currentIndex;
            onActivate: { if (!selected) { mainList.currentIndex = currentList.ObjectModel.index; } }
            onListHighlighted: { playNav(); mainList.currentIndex = currentList.ObjectModel.index; }
            onCurrentIndexChanged: { if (selected) highlightedGame = search ? search.currentGame(currentIndex) : null; }
            onSelectedChanged: { if (selected) highlightedGame = search ? search.currentGame(currentIndex) : null; }
        }

    }


    ListView {
    id: mainList

        anchors.fill: parent
        model: mainModel
        focus: true
        highlightMoveDuration: 200
        highlightRangeMode: ListView.ApplyRange 
        preferredHighlightBegin: header.height
        preferredHighlightEnd: parent.height - (helpMargin * 2)
        snapMode: ListView.SnapOneItem
        keyNavigationWraps: true
        currentIndex: storedHomePrimaryIndex
        
        cacheBuffer: 1000
        footer: Item { height: helpMargin }

        // When landing on the top row (hero box / system tiles), glide the
        // whole page smoothly to the very top. positionViewAtBeginning() sets
        // contentY in C++ (instant, bypasses Behaviors), so instead we animate
        // contentY explicitly and disable the highlight range while it runs so
        // the ListView's own positioning can't override the animation.
        NumberAnimation {
            id: glideTop
            target: mainList; property: "contentY"; to: mainList.originY
            duration: 220; easing.type: Easing.OutCubic
        }
        onCurrentIndexChanged: {
            if (currentIndex <= 1) {
                highlightRangeMode = ListView.NoHighlightRange;
                glideTop.restart();
            } else {
                glideTop.stop();
                highlightRangeMode = ListView.ApplyRange;
            }
        }

        Keys.onUpPressed: {
            if (currentIndex <= 1) { homebutton.focus = true; return; }
            playNav();
            // Leaving a collection to land on the strip: pre-switch to NoHighlightRange
            // BEFORE the index changes so ApplyRange doesn't snap contentY first,
            // letting the glide own the whole transition. (Mirrors the down handler.)
            if (currentIndex === 2) {
                highlightRangeMode = ListView.NoHighlightRange;
            }
            do {
                decrementCurrentIndex();
            } while (!currentItem.enabled);
        }
        Keys.onDownPressed: {
            playNav();
            // Leaving the top zone (index >= 1): restore ApplyRange BEFORE the
            // index changes, otherwise the list's internal repositioning runs
            // while still in NoHighlightRange and never scrolls down. (At index
            // 0 we leave it alone so landing on the first row stays glued to top.)
            if (currentIndex >= 1) {
                glideTop.stop();
                highlightRangeMode = ListView.ApplyRange;
            }
            do {
                incrementCurrentIndex();
            } while (!currentItem.enabled);
        }
    }

    // Global input handling for the screen
    Keys.onPressed: {
        // Settings
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            settingsScreen();
        }
        // Refresh lists
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            refreshLists();
        }
        // Discover mode (B)
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            discoverScreen();
        }
    }

    // Helpbar buttons
    ListModel {
        id: gridviewHelpModel

        ListElement {
            name: "Discover"
            button: "cancel"
        }
        ListElement {
            name: "Settings"
            button: "filters"
        }
        ListElement {
            name: "Refresh"
            button: "details"
        }
        ListElement {
            name: "Select"
            button: "accept"
        }
    }

    onActiveFocusChanged: {
        if (activeFocus)
            currentHelpbarModel = gridviewHelpModel;
    }

}
