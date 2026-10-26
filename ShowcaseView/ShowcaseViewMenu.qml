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
import "../Lists"
import "../utils.js" as Utils

FocusScope {
id: root
    // Text over the page backdrop. theme.text goes dark for the White colour,
    // but fanart / a custom image covers that colour, so the text stays light
    // unless the White backdrop is actually the thing showing.
    readonly property color showcaseText: showcaseWhiteBackground ? theme.text : "#ebebeb"

    // Pull in our custom lists and define
    ListAllGames    { id: listNone;        max: 0 }
    ListAllGames    { id: listAllGames;    max: settings.ShowcaseColumns; hideRows: libraryHideRows }
    ListFavorites   { id: listFavorites;   max: settings.ShowcaseColumns }
    ListLastPlayed  { id: listLastPlayed;  max: settings.ShowcaseColumns; omitApplication: false; omitEmulator: false; hideTitles: noHideTitles; hideRows: homeHideRows }
    ListMostPlayed  { id: listMostPlayed;  max: settings.ShowcaseColumns; omitApplication: false; omitEmulator: false; hideTitles: noHideTitles; hideRows: homeHideRows }
    ListRecommended { id: listRecommended; active: true; max: settings.ShowcaseColumns; omitApplication: false; omitEmulator: false; hideTitles: noHideTitles; hideRows: homeHideRows }
    // "Play Something New For <System>": one random system, a few of its games.
    ListRandomSystem { id: listRandomSystem; active: true; max: settings.ShowcaseColumns }
    ListPublisher   { id: listPublisher;   max: settings.ShowcaseColumns; publisher: randoPub;   omitApplication: false; omitEmulator: false; hideTitles: noHideTitles; hideRows: homeHideRows }
    ListDeveloper   { id: listDeveloper;   max: settings.ShowcaseColumns; developer: randoDev;   omitApplication: false; omitEmulator: false; hideTitles: noHideTitles; hideRows: homeHideRows }
    ListGenre       { id: listGenre;       max: settings.ShowcaseColumns; genre: randoGenre;     omitApplication: false; omitEmulator: false; hideTitles: noHideTitles; hideRows: homeHideRows }
    ListGenre       { id: listGenre2;      max: settings.ShowcaseColumns; genre: randoGenre2;    omitApplication: false; omitEmulator: false; hideTitles: noHideTitles; hideRows: homeHideRows }

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
    property var collection1: getCollection(settings.ShowcaseCollection1, settings.ShowcaseCollection1_Thumbnail, settings.ShowcaseCollection1_Size, settings.ShowcaseCollection1_Ratio)
    property var collection2: getCollection(settings.ShowcaseCollection2, settings.ShowcaseCollection2_Thumbnail, settings.ShowcaseCollection2_Size, settings.ShowcaseCollection2_Ratio)
    property var collection3: getCollection(settings.ShowcaseCollection3, settings.ShowcaseCollection3_Thumbnail, settings.ShowcaseCollection3_Size, settings.ShowcaseCollection3_Ratio)
    property var collection4: getCollection(settings.ShowcaseCollection4, settings.ShowcaseCollection4_Thumbnail, settings.ShowcaseCollection4_Size, settings.ShowcaseCollection4_Ratio)
    property var collection5: getCollection(settings.ShowcaseCollection5, settings.ShowcaseCollection5_Thumbnail, settings.ShowcaseCollection5_Size, settings.ShowcaseCollection5_Ratio)
    property var collection6: getCollection(settings.ShowcaseCollection6, settings.ShowcaseCollection6_Thumbnail, settings.ShowcaseCollection6_Size, settings.ShowcaseCollection6_Ratio)

    function getCollection(collectionName, collectionThumbnail, collectionSize, collectionRatio) {
        var collection = {
            enabled: true,
        };

        var width = root.width - globalMargin * 2;
        var ratio = parseFloat(collectionRatio) || 0.66;
        // Size -> divisor. Square: Small 6 / Medium 5.5 / Large 5.
        //                  Tall:   Small 7 / Medium 6   / Large 5.
        //                  Wide:   Small 4 / Medium 3.5 / Large 3.
        var sDiv  = (collectionSize === "Large") ? 5.0 : (collectionSize === "Medium" ? 5.5 : 6.0);
        var tDiv  = (collectionSize === "Large") ? 5.0 : (collectionSize === "Medium" ? 6.0 : 7.0);
        var wDiv  = (collectionSize === "Large") ? 3.0 : (collectionSize === "Medium" ? 3.5 : 4.0);

        switch (collectionThumbnail) {
            case "Square":
                collection.itemWidth = (width / sDiv);
                collection.itemHeight = collection.itemWidth;
                break;
            case "Tall":
                collection.itemWidth = (width / tDiv);
                collection.itemHeight = collection.itemWidth / ratio;
                break;
            case "Box Art":
            case "3D Box":
                // Same scheme as the grids: a typical box proportion scaled by
                // the ratio, 0.66 being neutral. Uses the Tall widths.
                collection.itemWidth = (width / tDiv);
                collection.itemHeight = collection.itemWidth * 1.4 * (ratio / 0.66);
                collection.boxArt = true;
                collection.boxStyle = collectionThumbnail;    // "Box Art" or "3D Box"
                break;
            case "Wide":
            default:
                collection.itemWidth = (width / wDiv);
                collection.itemHeight = collection.itemWidth * ratio;
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
            case "System":
                collection.search = listRandomSystem;
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
    // Candidate pools exclude games the rows filter out anyway, so a value whose
    // every game would be filtered away can't be picked — that produced rows
    // like "Top Games by Sony" with nothing under them.
    // Live, like the rows themselves (omitAppsLive / omitEmulatorsLive).
    readonly property bool poolOmitApp: omitAppsLive
    readonly property bool poolOmitEmu: omitEmulatorsLive

    property string randoPub:    Utils.returnRandom(Utils.uniqueValuesArray('publisher', poolOmitApp, poolOmitEmu)) || ''
    property string randoDev:    Utils.returnRandom(Utils.uniqueValuesArray('developer', poolOmitApp, poolOmitEmu)) || ''
    property string randoGenre:  Utils.returnRandom(Utils.uniqueGenreValues(poolOmitEmu)) || ''
    property string randoGenre2: Utils.returnRandom(Utils.uniqueGenreValues(poolOmitEmu)) || ''

    function refreshLists() {
        var omitEmu = omitEmulatorsLive;
        var omitApp = omitAppsLive;
        var pub = Utils.returnRandom(Utils.uniqueValuesArray('publisher', omitApp, omitEmu)) || '';
        var dev = Utils.returnRandom(Utils.uniqueValuesArray('developer', omitApp, omitEmu)) || '';
        var genres = Utils.uniqueGenreValues(omitEmu);
        var genre = Utils.returnRandom(genres) || '';
        var filtered = genres.filter(function(g) { return g !== genre; });
        var pick = filtered.length > 0 ? filtered : genres;
        var genre2 = Utils.returnRandom(pick) || '';
        randoPub = pub;
        randoDev = dev;
        randoGenre = genre;
        randoGenre2 = genre2;
        api.memory.set("Showcase randoms", { pub: pub, dev: dev, genre: genre, genre2: genre2 });
        listRecommended.refresh();
        listRandomSystem.refresh();
        currentHelpbarModel = gridviewHelpModel;
    }


    function storeIndices(secondary) {
        storedHomePrimaryIndex = mainList.currentIndex;
        if (secondary)
            storedHomeSecondaryIndex = secondary;
    }

    Component.onDestruction: storeIndices();

    Component.onCompleted: {
        // One key instead of four: each api.memory.set rewrites the whole
        // settings file.
        var saved = api.memory.has("Showcase randoms") ? api.memory.get("Showcase randoms") : null;
        if (fromGame && saved) {
            // Returning from a game launch — restore saved random values so the
            // lists look exactly as the user left them
            randoPub    = saved.pub    || "";
            randoDev    = saved.dev    || "";
            randoGenre  = saved.genre  || "";
            randoGenre2 = saved.genre2 || "";
        } else {
            // Fresh startup — persist the property-initializer values so they
            // survive a game launch and can be restored on the way back
            api.memory.set("Showcase randoms",
                { pub: randoPub, dev: randoDev, genre: randoGenre, genre2: randoGenre2 });
        }
        // The four keys older builds used, removed once
        ["Showcase randoPub", "Showcase randoDev", "Showcase randoGenre", "Showcase randoGenre2"]
            .forEach(function(k) { if (api.memory.has(k)) api.memory.unset(k); });
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
        // Screen size: a 4K background.png was a 33 MB texture.
        sourceSize: Qt.size(root.width, root.height)
        // Shown only while NO fanart is on screen. Two images never overlap, so
        // fanart blends with the theme colour beneath rather than with this —
        // which is what caused the colour shift and the flash between fades.
        //
        // bgShownImg is null whenever the fanart layers are cleared, which is
        // exactly the case for entries with no art of their own (imported apps),
        // and whenever background art is switched off entirely.
        // Follows Showcase Background Opacity, same as the fanart layers, so one
        // setting governs how strong the background reads whichever source is
        // showing. Same parseFloat fallback startBgFade() uses.
        // Shown whenever no art is up OR a fade is in progress (the art fades in
        // on top of it), and hidden the instant it's fully covered. No fade of
        // its own: fading it against the art is what let the colour through.
        // When art goes away, the art layers fade out over it instead.
        opacity: (settings.CustomBackground === "Yes" && (bgShownImg === null || bgFadeRunning)) ? 1.0 : 0

        // ── Dynamic Background on the custom image ────────────────────────
        // Same drift as the fanart layers. One difference: this image has no
        // crossfade to restart it, and can be on screen indefinitely (Showcase
        // Background Art off), so it ping-pongs — each pass flips direction —
        // for as long as it's showing, and resets when it fades out.
        transformOrigin: Item.Center
        transform: Translate { id: customBg_pan; x: 0; y: 0 }
        property real panX: 0
        property real panY: 0
        property bool zoomIn: true
        readonly property bool showing: opacity > 0
        ParallelAnimation {
        id: customBg_drift
            NumberAnimation { target: customBg;     property: "scale"
                              from: customBg.zoomIn ? 1.0 : dynamicBgZoom; to: customBg.zoomIn ? dynamicBgZoom : 1.0
                              duration: dynamicBgMs; easing.type: Easing.InOutSine }
            NumberAnimation { target: customBg_pan; property: "x"
                              from: customBg.zoomIn ? 0 : customBg.panX; to: customBg.zoomIn ? customBg.panX : 0
                              duration: dynamicBgMs; easing.type: Easing.InOutSine }
            NumberAnimation { target: customBg_pan; property: "y"
                              from: customBg.zoomIn ? 0 : customBg.panY; to: customBg.zoomIn ? customBg.panY : 0
                              duration: dynamicBgMs; easing.type: Easing.InOutSine }
            // Keep going while shown, alternating direction each pass.
            onFinished: if (customBg.showing && dynamicBg) customBg.beginDrift()
        }
        function beginDrift() {
            customBg_drift.stop();
            dynamicBgFlip = !dynamicBgFlip;
            zoomIn = dynamicBgFlip;
            panX = (Math.random() < 0.5 ? -1 : 1) * width  * dynamicBgPan;
            panY = (Math.random() < 0.5 ? -1 : 1) * height * dynamicBgPan;
            scale = zoomIn ? 1.0 : dynamicBgZoom;
            customBg_pan.x = zoomIn ? 0 : panX;
            customBg_pan.y = zoomIn ? 0 : panY;
            customBg_drift.start();
        }
        function endDrift() {
            customBg_drift.stop();
            scale = 1.0; customBg_pan.x = 0; customBg_pan.y = 0;
        }
        onShowingChanged: {
            if (showing && dynamicBg) beginDrift();
            else if (!showing) endDrift();
        }
        Component.onCompleted: if (showing && dynamicBg) beginDrift()
    }

    // Fanart / screenshot background with crossfade. The fade is started by
    // startBgFade() only once the file is FULLY DECODED (Image.Ready) —
    // starting it at source-set time made slow files (large PNGs) pop in
    // mid-fade while quick JPGs faded, which is why some art crossfaded
    // and some didn't.
    Image {
    id: bgImage1
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true

        // ── Dynamic Background: slow drift ────────────────────────────────
        // A gentle zoom from 1.0 to 1.08 with a small diagonal pan, over ~28s,
        // restarted each time this layer becomes the shown one. Scale never
        // drops below 1.0 and the pan is a fraction of the zoom headroom, so
        // no edge is ever exposed. It's one transform on an already-drawn
        // texture: effectively free, so it's available in both modes.
        transformOrigin: Item.Center
        transform: Translate { id: bgImage1_pan; x: 0; y: 0 }
        property real panX: 0
        property real panY: 0
        // zoomIn: 1.0 -> zoom with the pan easing out to its target.
        // Otherwise the reverse: starts zoomed and panned, settles to rest.
        property bool zoomIn: true
        ParallelAnimation {
        id: bgImage1_drift
            NumberAnimation { target: bgImage1;     property: "scale"
                              from: bgImage1.zoomIn ? 1.0 : dynamicBgZoom; to: bgImage1.zoomIn ? dynamicBgZoom : 1.0
                              duration: dynamicBgMs; easing.type: Easing.InOutSine }
            NumberAnimation { target: bgImage1_pan; property: "x"
                              from: bgImage1.zoomIn ? 0 : bgImage1.panX; to: bgImage1.zoomIn ? bgImage1.panX : 0
                              duration: dynamicBgMs; easing.type: Easing.InOutSine }
            NumberAnimation { target: bgImage1_pan; property: "y"
                              from: bgImage1.zoomIn ? 0 : bgImage1.panY; to: bgImage1.zoomIn ? bgImage1.panY : 0
                              duration: dynamicBgMs; easing.type: Easing.InOutSine }
        }
        function beginDrift() {
            bgImage1_drift.stop();
            // Alternate direction with every new image.
            dynamicBgFlip = !dynamicBgFlip;
            zoomIn = dynamicBgFlip;
            // Random diagonal, inside the headroom the zoom provides.
            panX = (Math.random() < 0.5 ? -1 : 1) * width  * dynamicBgPan;
            panY = (Math.random() < 0.5 ? -1 : 1) * height * dynamicBgPan;
            // Put the layer at the animation's starting pose before it runs.
            scale = zoomIn ? 1.0 : dynamicBgZoom;
            bgImage1_pan.x = zoomIn ? 0 : panX;
            bgImage1_pan.y = zoomIn ? 0 : panY;
            bgImage1_drift.start();
        }
        function endDrift() {
            bgImage1_drift.stop();
            scale = 1.0; bgImage1_pan.x = 0; bgImage1_pan.y = 0;
        }
        // Reset at rest only once this layer is fully faded out.
        onOpacityChanged: if (opacity === 0) endDrift()
        // Decoded at 60% of the display size instead of the file's native
        // resolution. Fanart is often 1080p+, and this layer is shown dimmed,
        // behind a scrim and often blurred, so the loss is invisible while the
        // per-highlight decode cost drops by roughly 3x.
        sourceSize: fanartDecodeSize   // shared with the prefetcher — must match
        opacity: 0
        z: 0
        property bool pendingFade: false
        property bool animate: true
        Behavior on opacity { enabled: bgImage1.animate; PropertyAnimation { duration: hqFanartFadeMs; easing.type: hqMode ? Easing.InOutQuad : Easing.Linear } }
        onStatusChanged: {
            if (status === Image.Ready && pendingFade) startBgFade(bgImage1);
            else if (status === Image.Error && pendingFade) { pendingFade = false; lastBgShown = ""; }
        }
    }

    Image {
    id: bgImage2
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true

        // ── Dynamic Background: slow drift ────────────────────────────────
        // A gentle zoom from 1.0 to 1.08 with a small diagonal pan, over ~28s,
        // restarted each time this layer becomes the shown one. Scale never
        // drops below 1.0 and the pan is a fraction of the zoom headroom, so
        // no edge is ever exposed. It's one transform on an already-drawn
        // texture: effectively free, so it's available in both modes.
        transformOrigin: Item.Center
        transform: Translate { id: bgImage2_pan; x: 0; y: 0 }
        property real panX: 0
        property real panY: 0
        // zoomIn: 1.0 -> zoom with the pan easing out to its target.
        // Otherwise the reverse: starts zoomed and panned, settles to rest.
        property bool zoomIn: true
        ParallelAnimation {
        id: bgImage2_drift
            NumberAnimation { target: bgImage2;     property: "scale"
                              from: bgImage2.zoomIn ? 1.0 : dynamicBgZoom; to: bgImage2.zoomIn ? dynamicBgZoom : 1.0
                              duration: dynamicBgMs; easing.type: Easing.InOutSine }
            NumberAnimation { target: bgImage2_pan; property: "x"
                              from: bgImage2.zoomIn ? 0 : bgImage2.panX; to: bgImage2.zoomIn ? bgImage2.panX : 0
                              duration: dynamicBgMs; easing.type: Easing.InOutSine }
            NumberAnimation { target: bgImage2_pan; property: "y"
                              from: bgImage2.zoomIn ? 0 : bgImage2.panY; to: bgImage2.zoomIn ? bgImage2.panY : 0
                              duration: dynamicBgMs; easing.type: Easing.InOutSine }
        }
        function beginDrift() {
            bgImage2_drift.stop();
            // Alternate direction with every new image.
            dynamicBgFlip = !dynamicBgFlip;
            zoomIn = dynamicBgFlip;
            // Random diagonal, inside the headroom the zoom provides.
            panX = (Math.random() < 0.5 ? -1 : 1) * width  * dynamicBgPan;
            panY = (Math.random() < 0.5 ? -1 : 1) * height * dynamicBgPan;
            // Put the layer at the animation's starting pose before it runs.
            scale = zoomIn ? 1.0 : dynamicBgZoom;
            bgImage2_pan.x = zoomIn ? 0 : panX;
            bgImage2_pan.y = zoomIn ? 0 : panY;
            bgImage2_drift.start();
        }
        function endDrift() {
            bgImage2_drift.stop();
            scale = 1.0; bgImage2_pan.x = 0; bgImage2_pan.y = 0;
        }
        // Reset at rest only once this layer is fully faded out.
        onOpacityChanged: if (opacity === 0) endDrift()
        // Decoded at 60% of the display size instead of the file's native
        // resolution. Fanart is often 1080p+, and this layer is shown dimmed,
        // behind a scrim and often blurred, so the loss is invisible while the
        // per-highlight decode cost drops by roughly 3x.
        sourceSize: fanartDecodeSize   // shared with the prefetcher — must match
        opacity: 0
        z: 0
        property bool pendingFade: false
        property bool animate: true
        Behavior on opacity { enabled: bgImage2.animate; PropertyAnimation { duration: hqFanartFadeMs; easing.type: hqMode ? Easing.InOutQuad : Easing.Linear } }
        onStatusChanged: {
            if (status === Image.Ready && pendingFade) startBgFade(bgImage2);
            else if (status === Image.Error && pendingFade) { pendingFade = false; lastBgShown = ""; }
        }
    }

    // Background opacity, applied as BLACK over full-strength art instead of
    // drawing the art translucent over the theme colour. Same numbers, but
    // the theme colour no longer bleeds through and tints the fanart — on a
    // black theme the result is identical; on a coloured one the tint is gone.
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 1.0 - (parseFloat(settings.ShowcaseBackgroundOpacity) || 0.55)
        visible: opacity > 0.005
        z: 2   // above both art layers (the incoming one is lifted to z: 1 while fading)
    }

    // ── System-tile page background (Randomize System Tile Fanart = "No") ──
    // When a system tile is highlighted, the page background shows that
    // system's own background art (the same image the tile uses) instead of a
    // randomly picked game fanart. The resolver tries .png/.jpg/.jpeg/.webp;
    // if no file exists for the system it falls back to a random game's
    // fanart so the background never goes stale.
    property bool sysTileBgActive: false
    // Returning to the hero or game rows must re-run the fanart crossfade even
    // when bgSource doesn't change (re-assigning the same game emits no signal,
    // so onBgSourceChanged alone would leave the system art stuck on screen).
    // Sites that flip this off set highlightedGame FIRST (silent while active),
    // so this lands directly on the final image in a single fade.
    onSysTileBgActiveChanged: {
        // The scheduler inside crossfadeTo collapses this with any same-frame
        // fanart update from the row taking over — the last target wins, so
        // ordering between this handler and the row's no longer matters.
        if (!sysTileBgActive) crossfadeTo(bgSource);
    }
    property var  sysBgFallbackColl: null
    // Pegasus X: a collection's own background and logo (Settings > Edit
    // metadata) win over the theme's bundled system art
    function customSystemBackground(c) {
        return (c && c.assets && c.assets.background) ? c.assets.background : "";
    }
    function customSystemLogo(c) {
        return (c && c.assets && c.assets.logo) ? c.assets.logo : "";
    }

    Image {
    id: sysBgResolver
        visible: false
        asynchronous: true
        // Only a probe: it finds WHICH file exists, then the fanart layer
        // does the real decode at its own size. It used to decode every
        // system's background at full size (a second, full-resolution
        // decode on each step along the system strip). Tiny, and kept out
        // of the image cache so it never shares an entry with the real one.
        sourceSize: Qt.size(32, 18)
        cache: false
        property string basePath: ""
        property var exts: [".webp", ".png", ".jpg", ".jpeg"]
        property int extIdx: 0
        // Pegasus X: a background set for the collection itself (Settings >
        // Edit metadata) is one exact file, no extensions to try
        readonly property bool exact: basePath.indexOf("file:") === 0 || basePath.indexOf("/") === 0
        // Request the background for a system. Re-requesting the system that's
        // already resolved re-applies it instantly (returning from game rows);
        // a new system starts the load chain and the page holds the current
        // background until the file is ready.
        function request(path) {
            if (path === basePath) {
                if (status === Image.Ready && sysTileBgActive) {
                    crossfadeTo(source);
                } else if (status === Image.Error && sysTileBgActive
                           && sysBgFallbackColl && sysBgFallbackColl.games.count > 0) {
                    // Known-missing background — random fanart fallback again
                    highlightedGame = sysBgFallbackColl.games.get(Math.floor(Math.random() * sysBgFallbackColl.games.count));
                    sysTileBgActive = false;
                }
                return;
            }
            basePath = path;   // onBasePathChanged kicks off the load chain
        }
        onBasePathChanged: {
            extIdx = 0;
            source = basePath !== "" ? (exact ? basePath : basePath + exts[0]) : "";
        }
        onStatusChanged: {
            if (status === Image.Error) {
                if (!exact && extIdx < exts.length - 1) {
                    extIdx = extIdx + 1;          // try next extension
                    source = basePath + exts[extIdx];
                } else if (sysTileBgActive && sysBgFallbackColl && sysBgFallbackColl.games.count > 0) {
                    // No background file for this system — random fanart fallback
                    highlightedGame = sysBgFallbackColl.games.get(Math.floor(Math.random() * sysBgFallbackColl.games.count));
                    sysTileBgActive = false;
                }
            } else if (status === Image.Ready) {
                // File is ready — NOW run the single clean crossfade to it
                if (sysTileBgActive) crossfadeTo(source);
            }
        }
    }

    // Page-background update for the top strip. idx 0 = hero; idx >= 1 = system tile.
    function updateTopRowBackground(idx, resumeGame) {
        if (settings.ShowcaseBackgroundArt !== "Yes") return;
        if (idx <= 0) {
            if (resumeGame) highlightedGame = resumeGame;   // silent while flag is on
            sysTileBgActive = false;                        // handler runs the crossfade
            return;
        }
        var coll = api.collections.get(sortedColl[idx - 1]);
        if (!coll) return;
        if (settings.RandomizeSystemTileFanart === "Yes") {
            // A random game that HAS a background. It used to pick any game
            // and use whatever it had — once the screenshot fallback went,
            // a game with no fanart yielded nothing at all. A few random
            // tries rather than a full scan, so a big collection stays cheap;
            // if none land, the system's own art is used instead.
            var pick = null, n = coll.games.count;
            for (var t = 0; t < 12 && n > 0 && !pick; t++) {
                var g = coll.games.get(Math.floor(Math.random() * n));
                if (fanartFor(g) !== "") pick = g;
            }
            if (pick) {
                highlightedGame = pick;
                sysTileBgActive = false;   // handler runs the crossfade if needed
                return;
            }
            // none found: fall through to the system art below
        }
        // Default (and the randomiser's fallback): the system's own background
        // art, which matches the tile.
        sysBgFallbackColl = coll;
        sysTileBgActive   = true;
        sysBgResolver.request(customSystemBackground(coll)
            || "../assets/images/systembackground/" + Utils.processPlatformName(coll.shortName));
    }

    // Dim overlay so content stays readable. Lowered from 0.45: it sits above
    // everything, so it was darkening the chosen theme colour and the custom
    // image as much as it was taming bright fanart.
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.25
        z: 1
    }

    property string lastBgShown: ""
    property string pendingBg: ""
    property bool bgFlushQueued: false
    property var bgShownImg: null     // the background layer currently on screen
    property string bgSource: {
        if (settings.ShowcaseBackgroundArt !== "Yes") return "";
        if (!highlightedGame) return "";
        // Shared resolver: fanart, or a screenshot if Screenshot Fallback is
        // on, else "" (which reveals the custom background, if any).
        return fanartFor(highlightedGame);
    }

    // Single crossfade driver — bulletproof version:
    //  • All requests in one frame collapse to ONE fade (Qt.callLater, last
    //    target wins) — an up-press fires several handlers, and the second
    //    image-write used to land on the still-visible layer, swapping its
    //    picture instantly instead of fading.
    //  • The fade only starts once the file is READY, so slow-decoding art
    //    (large PNGs) fades exactly like quick JPGs instead of popping in.
    //  • Targets are normalized to strings so the duplicate-check can't be
    //    defeated by url-vs-string comparison (resolver passes a QUrl).
    //  • The on-screen layer is tracked explicitly (bgShownImg) and is never
    //    written to; it stays untouched until the incoming file is ready.
    // Two guards that stop the page colour showing through while scrolling:
    //
    //  1. SETTLE. Every cursor step used to start a crossfade at once. The
    //     flush now waits for the cursor to rest (bgSettle), so a run of
    //     steps produces ONE fade to the final game instead of a chain of
    //     half-finished ones.
    //  2. FADE LOCK. A target arriving mid-fade used to be written to the
    //     "hidden" layer — which was the OUTGOING layer, still on screen and
    //     fading out. It got snapped to zero and handed a new file to load,
    //     leaving only a half-faded-in layer: the flash to the page colour.
    //     While a fade runs, new targets wait (bgFadeDone re-flushes).
    property bool bgFadeRunning: false
    property var  bgOutgoing: null
    Timer { id: bgSettle;   interval: 180;              onTriggered: flushBg() }
    Timer {
    id: bgFadeDone
        interval: hqFanartFadeMs + 30
        onTriggered: {
            // The old layer is fully covered by now: hide it without a fade.
            if (bgOutgoing) { bgOutgoing.animate = false; bgOutgoing.opacity = 0; bgOutgoing.animate = true; bgOutgoing = null; }
            bgFadeRunning = false;
            if (pendingBg !== lastBgShown) flushBg();
        }
    }

    function crossfadeTo(src) {
        pendingBg = "" + src;          // normalize url → string; last target wins
        bgSettle.restart();
    }

    function flushBg() {
        bgFlushQueued = false;
        if (bgFadeRunning) return;              // bgFadeDone will call us back
        var src = pendingBg;
        if (src === lastBgShown) return;        // already showing / loading it
        lastBgShown = src;
        if (src === "") {
            bgImage1.pendingFade = false; bgImage2.pendingFade = false;
            bgImage1.opacity = 0; bgImage2.opacity = 0;   // fade out over the custom bg / page
            bgOutgoing = null;
            bgShownImg = null;
            return;
        }
        // Always write the layer that is NOT on screen
        var incoming = (bgShownImg === bgImage1) ? bgImage2 : bgImage1;
        incoming.pendingFade = true;
        if ("" + incoming.source === src && incoming.status === Image.Ready) {
            startBgFade(incoming);              // already cached — fade now
        } else {
            incoming.animate = false;           // snap hidden (no half-fade)
            incoming.opacity = 0;
            incoming.animate = true;
            incoming.source = src;              // Image.Ready → startBgFade()
        }
    }

    function startBgFade(img) {
        bgFadeRunning = true;
        bgFadeDone.restart();
        if (!img.pendingFade) return;
        img.pendingFade = false;
        var other = (img === bgImage1) ? bgImage2 : bgImage1;
        other.pendingFade = false;
        // Incoming-only fade. Two layers fading in opposite directions are
        // each half-transparent at the midpoint, so the page colour showed
        // through the PAIR (~25% mid-fade): the tint you could see on every
        // transition. Instead the new layer is lifted on top and fades in
        // over the old one, which stays fully opaque until it is covered.
        // bgFadeDone then drops the old layer (already hidden, so no fade).
        img.z = 1; other.z = 0;
        img.opacity = 1.0;
        bgOutgoing = other;
        bgShownImg = img;
        // Dynamic Background: the new image starts its drift fresh. The one
        // fading out is left alone — it keeps drifting through the crossfade
        // and resets only once fully hidden (see onOpacityChanged on the
        // layers). Resetting it here snapped it back to 1.0 while it was
        // still on screen.
        if (dynamicBg) img.beginDrift(); else img.endDrift();
    }

    onBgSourceChanged: {
        // While a system tile drives the background, hold the current image
        // until the resolver's file is ready (it calls crossfadeTo itself).
        // An empty bgSource (background art turned off) always clears.
        if (!sysTileBgActive || bgSource === "") crossfadeTo(bgSource);
    }


    // FTUE favorites banner removed — the hero box serves that role now; the Xbox
    // logo is rendered by the header below, honoring Settings > Home page > Xbox Logo.

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
            visible: settings.XboxLogo !== "None" && settings.XboxLogo !== "RetroAchievements"
        }

        // ── RetroAchievements header card ─────────────────────────────────
        // Replaces the Xbox logo when Settings > Home page > Xbox Logo = RetroAchievements.
        // Shows the same profile info as the RA overview (avatar, name, points, member).
        Item {
        id: raHeaderCard

            anchors { left: parent.left; leftMargin: globalMargin; verticalCenter: parent.verticalCenter }
            width: vpx(250); height: vpx(64)
            visible: settings.XboxLogo === "RetroAchievements"

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
                        color: showcaseText
                        font.family: subtitleFont.name
                        font.pixelSize: fpx(17); font.bold: true
                        elide: Text.ElideRight
                    }
                    // Points, alternating with Rank # when RA has one.
                    RAStatLine {
                        color: showcaseText
                        fontFamily: subtitleFont.name
                        pixelSize: fpx(12)
                        opacity: 0.7
                    }
                    Text {
                        text: cheevosData.memberText
                        color: showcaseText
                        font.family: subtitleFont.name
                        font.pixelSize: fpx(10)
                        opacity: 0.5
                        visible: cheevosData.memberText !== ""
                    }
                }
            }

            // Fallback hint if RA isn't set up yet
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Sign in to RetroAchievements"
                color: showcaseText
                opacity: 0.4
                font.family: subtitleFont.name
                font.pixelSize: fpx(13)
                visible: cheevosData.raUserName === ""
            }
        }
        Rectangle {
        id: homebutton

            width:  vpx(36); height: vpx(36); radius: height / 2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -vpx(108) }
            color:   focus ? theme.accent : "transparent"
            opacity: focus ? 1 : 0.6
            layer.enabled: true
            layer.effect: DropShadow {
                cached: true   // static: blur once, not every frame
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 0
                radius: 8
                samples: 17
                color: "#cc000000"
            }

            onFocusChanged: {
                if (focus) playNav();
                if (focus) mainList.currentIndex = -1;
            }
            Keys.onDownPressed:  { playNav(); var r = mainList.navJump ? mainList.savedRow : 1; mainList.navJump = false; mainList.forceActiveFocus(); mainList.currentIndex = r; }
            Keys.onRightPressed: discoverbutton.focus = true;
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; allGamesScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; if (mainList.navJump) { mainList.navJump = false; mainList.currentIndex = mainList.savedRow; } mainList.focus = true; }
                if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); discoverbutton.focus = true; }
                if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); settingsbutton.focus = true; }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: settings.MouseHover == "Yes"
                onEntered: homebutton.focus = true; onExited: homebutton.focus = false;
                onClicked: allGamesScreen();
            }
            Image {
                // vpx(6) margin on a vpx(36) button = a vpx(24) icon box, the
                // same box trophy.svg and settingsicon.svg use, so all four nav
                // icons are inset identically.
                anchors { fill: parent; margins: vpx(6) }
                source: "../assets/images/icon_gamesandapps.svg"
                sourceSize { width: Math.round(width * 2); height: Math.round(height * 2) }
                layer.enabled: showcaseWhiteBackground
                layer.effect: ColorOverlay { color: "black" }
                fillMode: Image.PreserveAspectFit
                smooth: true; asynchronous: true
                opacity: homebutton.focus ? 1.0 : 0.85
            }
        }

        Rectangle {
        id: discoverbutton

            width:  vpx(36); height: vpx(36); radius: height / 2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -vpx(54) }
            color:   focus ? theme.accent : "transparent"
            opacity: focus ? 1 : 0.6
            layer.enabled: true
            layer.effect: DropShadow {
                cached: true   // static: blur once, not every frame
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 0
                radius: 8
                samples: 17
                color: "#cc000000"
            }

            onFocusChanged: {
                if (focus) playNav();
                if (focus) mainList.currentIndex = -1;
            }
            Keys.onDownPressed:  { playNav(); var r = mainList.navJump ? mainList.savedRow : 1; mainList.navJump = false; mainList.forceActiveFocus(); mainList.currentIndex = r; }
            Keys.onLeftPressed:  homebutton.focus = true;
            Keys.onRightPressed: achievementsbutton.focus = true;
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; discoverScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; if (mainList.navJump) { mainList.navJump = false; mainList.currentIndex = mainList.savedRow; } mainList.focus = true; }
                if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); achievementsbutton.focus = true; }
                if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); homebutton.focus = true; }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: settings.MouseHover == "Yes"
                onEntered: discoverbutton.focus = true; onExited: discoverbutton.focus = false;
                onClicked: discoverScreen();
            }
            Image {
                anchors { fill: parent; margins: vpx(6) }
                source: "../assets/images/icon_discover.svg"
                // Rasterised above display size so it stays sharp on a TV.
                sourceSize { width: Math.round(width * 2); height: Math.round(height * 2) }
                layer.enabled: showcaseWhiteBackground
                layer.effect: ColorOverlay { color: "black" }
                fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
                opacity: discoverbutton.focus ? 1.0 : 0.85
            }
        }

        Rectangle {
        id: achievementsbutton

            width:  vpx(36); height: vpx(36); radius: height / 2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: 0 }
            color:   focus ? theme.accent : "transparent"
            opacity: focus ? 1 : 0.6
            layer.enabled: true
            layer.effect: DropShadow {
                cached: true   // static: blur once, not every frame
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 0
                radius: 8
                samples: 17
                color: "#cc000000"
            }

            onFocusChanged: {
                if (focus) playNav();
                if (focus) mainList.currentIndex = -1;
            }
            Keys.onDownPressed:  { playNav(); var r = mainList.navJump ? mainList.savedRow : 1; mainList.navJump = false; mainList.forceActiveFocus(); mainList.currentIndex = r; }
            Keys.onLeftPressed:  discoverbutton.focus = true;
            Keys.onRightPressed: searchbutton.focus = true;
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; achievementsScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; if (mainList.navJump) { mainList.navJump = false; mainList.currentIndex = mainList.savedRow; } mainList.focus = true; }
                if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); searchbutton.focus = true; }
                if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); discoverbutton.focus = true; }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: settings.MouseHover == "Yes"
                onEntered: achievementsbutton.focus = true; onExited: achievementsbutton.focus = false;
                onClicked: achievementsScreen();
            }
        }

        Image {
        id: achievementsTrophyIcon
            width: vpx(24); height: vpx(24)
            sourceSize: Qt.size(vpx(24), vpx(24))
            source: "../assets/images/trophy.svg"
            layer.enabled: showcaseWhiteBackground
            layer.effect: ColorOverlay { color: "black" }
            fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
            anchors.centerIn: achievementsbutton
            opacity: achievementsbutton.focus ? 1 : 0.7
        }

        // Global library search — opens the shared overlay in theme.qml.
        // Same box and inset as Discover so the five icons line up.
        Rectangle {
        id: searchbutton

            width:  vpx(36); height: vpx(36); radius: height / 2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: vpx(54) }
            color:   focus ? theme.accent : "transparent"
            opacity: focus ? 1 : 0.6
            layer.enabled: true
            layer.effect: DropShadow {
                cached: true   // static: blur once, not every frame
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 0
                radius: 8
                samples: 17
                color: "#cc000000"
            }

            onFocusChanged: {
                if (focus) playNav();
                if (focus) mainList.currentIndex = -1;
            }
            Keys.onDownPressed:  { playNav(); var r = mainList.navJump ? mainList.savedRow : 1; mainList.navJump = false; mainList.forceActiveFocus(); mainList.currentIndex = r; }
            Keys.onLeftPressed:  achievementsbutton.focus = true;
            Keys.onRightPressed: settingsbutton.focus = true;
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; openLibrarySearch(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; if (mainList.navJump) { mainList.navJump = false; mainList.currentIndex = mainList.savedRow; } mainList.focus = true; }
                if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); settingsbutton.focus = true; }
                if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); achievementsbutton.focus = true; }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: settings.MouseHover == "Yes"
                onEntered: searchbutton.focus = true; onExited: searchbutton.focus = false;
                onClicked: openLibrarySearch();
            }
            Image {
                anchors { fill: parent; margins: vpx(6) }
                source: "../assets/images/icon_search.svg"
                sourceSize { width: Math.round(width * 2); height: Math.round(height * 2) }
                layer.enabled: showcaseWhiteBackground
                layer.effect: ColorOverlay { color: "black" }
                fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
                opacity: searchbutton.focus ? 1.0 : 0.85
            }
        }

        Rectangle {
        id: settingsbutton

            width:  vpx(36); height: vpx(36); radius: height / 2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: vpx(108) }
            color:   focus ? theme.accent : "transparent"
            opacity: focus ? 1 : 0.6
            layer.enabled: true
            layer.effect: DropShadow {
                cached: true   // static: blur once, not every frame
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 0
                radius: 8
                samples: 17
                color: "#cc000000"
            }

            onFocusChanged: {
                if (focus) playNav();
                if (focus) mainList.currentIndex = -1;
            }
            Keys.onDownPressed:  { playNav(); var r = mainList.navJump ? mainList.savedRow : 1; mainList.navJump = false; mainList.forceActiveFocus(); mainList.currentIndex = r; }
            Keys.onLeftPressed:  searchbutton.focus = true;
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; settingsScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; if (mainList.navJump) { mainList.navJump = false; mainList.currentIndex = mainList.savedRow; } mainList.focus = true; }
                if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); homebutton.focus = true; }
                if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; playNav(); searchbutton.focus = true; }
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
            layer.enabled: showcaseWhiteBackground
            layer.effect: ColorOverlay { color: "black" }
            opacity: root.focus ? 0.8 : 0.5
        }

        // ── Nav button labels — shown only for the highlighted button ─────
        Text {
            text: "Full Library"
            anchors { top: homebutton.bottom; topMargin: vpx(3); horizontalCenter: homebutton.horizontalCenter }
            color: showcaseWhiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: fpx(11); font.bold: true
            opacity: homebutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "Discover"
            anchors { top: discoverbutton.bottom; topMargin: vpx(3); horizontalCenter: discoverbutton.horizontalCenter }
            color: showcaseWhiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: fpx(11); font.bold: true
            opacity: discoverbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "RetroAchievements"
            anchors { top: achievementsbutton.bottom; topMargin: vpx(3); horizontalCenter: achievementsbutton.horizontalCenter }
            color: showcaseWhiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: fpx(11); font.bold: true
            opacity: achievementsbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "Search"
            anchors { top: searchbutton.bottom; topMargin: vpx(3); horizontalCenter: searchbutton.horizontalCenter }
            color: showcaseWhiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: fpx(11); font.bold: true
            opacity: searchbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "Settings"
            anchors { top: settingsbutton.bottom; topMargin: vpx(3); horizontalCenter: settingsbutton.horizontalCenter }
            color: showcaseWhiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: subtitleFont.name; font.pixelSize: fpx(11); font.bold: true
            opacity: settingsbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
		
        // Shared status cluster (clock / battery / wifi) — the global component,
        // identical to every other page. Self-anchors to this container's top-right.
        StatusCluster {
            anchors.fill: parent
            z: 50
            dark: showcaseWhiteBackground
        }
    }

    // True only when every collection row is hidden (all 6 set to "None").
    // Drives the spacer below so the hero/system row settles at the bottom
    // of the screen instead of sitting up near the top with nothing below it.
    property bool allCollectionsHidden: settings.ShowcaseCollection1 === "None"
                                      && settings.ShowcaseCollection2 === "None"
                                      && settings.ShowcaseCollection3 === "None"
                                      && settings.ShowcaseCollection4 === "None"
                                      && settings.ShowcaseCollection5 === "None"
                                      && settings.ShowcaseCollection6 === "None"

    // Using an object model to build the list
    ObjectModel {
    id: mainModel

        // Empty space — background fanart shows through (Xbox dashboard style).
        // When every collection is hidden, this grows to push the hero/system
        // row down to the bottom of the screen instead of leaving it stranded
        // near the top with empty space below it.
        Item {
            width: parent.width
            height: allCollectionsHidden
                    ? Math.max(vpx(360), root.height - topRow.height - helpMargin)
                    : vpx(360)
            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
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
                if (selected) {
                    // currentIndex is -1 until platformlist takes focus (its
                    // onFocusChanged restores the saved index and updates the
                    // bg) — calling now would briefly route through the hero
                    // branch and double-fire the crossfade.
                    if (platformlist.currentIndex >= 0)
                        updateTopRowBackground(platformlist.currentIndex, platformlist.resumeGame);
                } else {
                    sysTileBgActive = false;   // leaving the top row — game rows take over
                }
            }

        ListView {
        id: platformlist
            // HQ: every platform tile built up front, so none pops in on
            // scroll. The row is ~30 tiles; a full-width buffer keeps all of
            // them decoded. OFF leaves the default (a screen's worth).
            cacheBuffer: hqResidentRows ? width * 3 : width

            focus: topRow.focus
            // The hero = the first game in Last Played. It used to be a binding
            // on listLastPlayed.currentGame(0): a function call, so it only
            // re-ran when the list's COUNT changed, and hooking the list's row
            // signals didn't reliably reach it either (the list is two filter
            // models deep). Hiding the app in the hero swaps the first game
            // for another at the same count, so the hero stayed until reload.
            //
            // Now it's re-read explicitly — always one step later
            // (Qt.callLater), once the filters have finished — whenever:
            //   - anything that decides what Home hides changes (resumeDeps)
            //   - the Last Played list's rows change
            //   - Home regains focus (back from Settings: see onActiveFocusChanged)
            property var resumeGame: null
            function refreshResume() {
                var g = listLastPlayed.games.count > 0 ? listLastPlayed.currentGame(0) : null;
                if (g === resumeGame) return;
                resumeGame = g;
                // Hero highlighted right now: the page background follows it.
                if (topRow.selected && currentIndex === 0) updateTopRowBackground(0, g);
            }
            readonly property var resumeDeps: [homeHideTitles, omitAppsLive, omitEmulatorsLive, libraryHideRows]
            onResumeDepsChanged: Qt.callLater(platformlist.refreshResume)
            Connections {
                target: listLastPlayed.games
                onRowsInserted:  Qt.callLater(platformlist.refreshResume)
                onRowsRemoved:   Qt.callLater(platformlist.refreshResume)
                onRowsMoved:     Qt.callLater(platformlist.refreshResume)
                onModelReset:    Qt.callLater(platformlist.refreshResume)
                onLayoutChanged: Qt.callLater(platformlist.refreshResume)
                onCountChanged:  Qt.callLater(platformlist.refreshResume)
            }
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
                if (idx <= firstVisible)
                    firstVisible = idx - 1;          // keep one tile of lead-in on the left (shift as soon
                                                     // as the tile reaches the edge) so the grown tile's
                                                     // left edge isn't clipped at the margin
                else if (idx > firstVisible + visibleCount - 1)
                    firstVisible = idx - visibleCount + 1;
                firstVisible = Math.max(0, firstVisible);
                contentX = firstVisible * unit;
            }

            onCurrentIndexChanged: {
                if (currentIndex < 0) return;   // deselected (focus moved away) — leave the scroll position alone
                // Align the list to whole-tile boundaries (same routine used on load).
                alignToIndex(currentIndex);
                // Update the page background for the highlighted strip item
                if (topRow.selected) updateTopRowBackground(currentIndex, resumeGame);
            }

            property int savedIndex: collectionVisited ? (sortedColl.indexOf(currentCollectionIndex) + 1) : 0   // strip index (hero = 0); hero until a collection is opened
            onFocusChanged: {
                if (focus) {
                    currentIndex = savedIndex;
                    updateTopRowBackground(currentIndex, resumeGame);
                } else {
                    savedIndex = currentIndex;
                    currentIndex = -1;
                }
            }

            Component.onCompleted: {
                refreshResume();            // first fill of the hero
                alignToIndex(savedIndex);
            }

            // Driven by sortedColl, NOT api.collections.count — the two differ
            // now that the apps collection is filtered out of the system row.
            // Using the raw count left a trailing tile whose sortedColl lookup
            // was undefined: blank, and impossible to enter.
            model: sortedColl.length + 1   // index 0 = hero, 1.. = platforms
            delegate: Rectangle {
                id: tile
                property bool isHero: index === 0
                property var  coll: isHero ? null : api.collections.get(sortedColl[index - 1])
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
                radius: vpx(6)   // concentric with the focus frame
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
                // Delegates lose their parent while being recycled; guarded so
                // that doesn't throw (it threw ~60 times per Home scroll).
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                // ── HERO (index 0): resume / last-played screenshot + title ──
                // Rounded without a mask: the art through RoundedArt (one
                // shader pass), the title bar from a square band plus a
                // clipped rounded strip. The old layer + OpacityMask kept
                // two off-screen copies of the whole hero tile alive.
                // Built for the hero tile only: every system tile used to carry
                // this whole block (art, shader, logo, title bar) invisibly.
                Loader {
                    anchors.fill: parent
                    active: isHero
                    sourceComponent: Component {
                Item {
                    id: heroClipper
                    anchors.fill: parent

                    Image {
                        id: heroBg
                        anchors.fill: parent
                        // All art types crop-fill the square at their native aspect (box art
                        // keeps its proportions, with top/bottom cropped) — no stretching.
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true; smooth: true
                        source: heroArtSource(platformlist.resumeGame)
                        // Decoded at the grown tile's size, not the file's.
                        sourceSize: Qt.size(Math.round(topRow.tileSz * topRow.growScale), Math.round(topRow.tileSz * topRow.growScale))
                        opacity: tile.selected ? 1 : 0.5
                        // Drawn by heroBgFx; shown directly only if the shader can't run
                        visible: heroBgFx.failed
                    }
                    RoundedArt {
                    id: heroBgFx
                        anchors.fill: heroBg
                        source: heroBg
                        crop: true
                        radius: tile.radius
                        opacity: heroBg.opacity
                        visible: heroBg.status === Image.Ready && !failed
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
                        sourceSize: Qt.size(Math.round(topRow.tileSz * topRow.growScale), Math.round(topRow.tileSz * topRow.growScale))
                        visible: source != ""
                                 && (settings.HeroBoxArt === "Screenshot" || settings.HeroBoxArt === "Fanart")
                        opacity: tile.selected ? 1 : 0.5
                    }

                    Rectangle {
                        // Full-width bar across the bottom — shown only on highlight now.
                        // Square top, bottom corners following tile.radius.
                    id: heroBar
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: Math.max(vpx(36), topRow.tileSz * 0.16, heroBarText.contentHeight + vpx(16)); color: "transparent"
                        opacity: gameTitleMode === "Never" ? 0 : ((tile.selected || gameTitleMode === "Always") ? 1 : 0)
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        readonly property real r: Math.min(tile.radius, height)
                        Rectangle {
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            height: parent.height - parent.r
                            color: "#99000000"
                        }
                        Item {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: heroBar.r
                            clip: true
                            Rectangle {
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                height: heroBar.r * 2
                                radius: heroBar.r
                                color: "#99000000"
                            }
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: vpx(8); right: parent.right; rightMargin: vpx(6); verticalCenter: parent.verticalCenter }
                            id: heroBarText
                            text: platformlist.resumeGame ? platformlist.resumeGame.title : ""
                            color: "white"; font.family: subtitleFont.name
                            font.pixelSize: Math.max(fpx(11), topRow.tileSz * 0.05); font.bold: true
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignLeft
                        }
                    }
                }
                    }   // Component
                }   // hero Loader

                // ── PLATFORM (index >= 1): system background + logo ──

                // System background art — place files in assets/images/systembackground/
                // named to match the system logo (e.g. "snes.png", "nintendo switch.jpg").
                // Tries .png → .jpg → .jpeg → .webp in order; stops at first match.
                Image {
                id: sysBg
                    property string basePath: (!isHero && coll)
                        ? "../assets/images/systembackground/" + Utils.processPlatformName(coll.shortName) : ""
                    property var exts: [".webp", ".png", ".jpg", ".jpeg"]
                    property int extIdx: 0
                    onBasePathChanged: extIdx = 0      // reset when tile recycles to a new system
                    onStatusChanged: {
                        if (status === Image.Error && extIdx < exts.length - 1)
                            extIdx = extIdx + 1;       // try next extension
                    }
                    // Drawn by sysBgFx below (rounded in one pass); shown
                    // directly only if that shader can't run on this GPU.
                    readonly property bool shown: !isHero && status === Image.Ready
                    visible: shown && sysBgFx.failed
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true; smooth: true
                    sourceSize: Qt.size(Math.round(topRow.tileSz * topRow.growScale), Math.round(topRow.tileSz * topRow.growScale))
                    readonly property string customBg: (!isHero && coll) ? customSystemBackground(coll) : ""
                    source: customBg !== "" ? customBg : (basePath !== "" ? basePath + exts[extIdx] : "")
                    // HQ: dissolve in once decoded instead of snapping. The
                    // target opacity is unchanged; the Behavior only animates
                    // the change, and only when HQ is on.
                    opacity: (status === Image.Ready) ? (selected ? 0.9 : 0.6) : 0
                    Behavior on opacity { enabled: hqFadeIn; NumberAnimation { duration: 180 } }
                }
                // Rounded corners in one shader pass, reading the image's own
                // texture. Replaces a layer + OpacityMask that kept two
                // off-screen images alive on EVERY system tile.
                RoundedArt {
                id: sysBgFx
                    anchors.fill: sysBg
                    source: sysBg
                    crop: true
                    radius: tile.radius
                    opacity: sysBg.opacity
                    visible: sysBg.shown && !failed
                }

                Image {
                id: collectionlogo
                    visible: !isHero
                    anchors.fill: parent
                    anchors.margins: vpx(15)
                    source: (!isHero && coll)
                        ? systemLogoSource(coll) : ""
                    // The grown tile's size: 512 px was twice what a 244 px
                    // tile (366 grown) can show, for every logo in the strip.
                    sourceSize: Qt.size(Math.round(topRow.tileSz * topRow.growScale), Math.round(topRow.tileSz * topRow.growScale))
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    opacity: (status === Image.Ready) ? (selected ? 1 : 0.2) : 0
                    Behavior on opacity { enabled: hqFadeIn; NumberAnimation { duration: 180 } }
                }
                Text {
                id: platformname
                    visible: !isHero && collectionlogo.status == Image.Error
                    text: coll ? coll.name : ""
                    anchors { fill: parent; margins: vpx(10) }
                    color: showcaseText
                    opacity: selected ? 1 : 0.2
                    font.pixelSize: fpx(18)
                    font.family: subtitleFont.name
                    font.bold: true
                    style: Text.Outline; styleColor: theme.main
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                    lineHeight: 0.8
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                // System name bar — appears on highlight with the system name,
                // masked exactly like the hero box's.
                // A radius on the bar itself rounds all four corners, and a
                // cover strip can't fix it either — the bar is translucent, so
                // anything laid over it just stacks alpha and the curve still
                // shows through. Masking a tile-shaped rounded rect is the only
                // way to get square top corners with a rounded bottom, which is
                // what the hero/collection/grid bars already do.
                Item {
                id: sysNameBarClip

                    anchors.fill: parent
                    visible: !isHero && sysNameBar.opacity > 0
                    // Square top, rounded bottom WITHOUT a mask: a plain square
                    // band, plus a strip clipped to the bottom corner radius
                    // holding a rounded rectangle. Clipping a plain rectangle
                    // is free; the OpacityMask it replaces allocated two
                    // offscreen buffers on every step along the strip (the
                    // newly selected tile turned its layer on each time).

                    Item {
                    id: sysNameBar

                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: Math.max(vpx(36), topRow.tileSz * 0.16, sysBarText.contentHeight + vpx(16))   // grows for 2-line names
                        readonly property color barColor: "#99000000"
                        readonly property real r: Math.min(tile.radius, height)

                        Rectangle {
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            height: parent.height - parent.r
                            color: parent.barColor
                        }
                        Item {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: parent.r
                            clip: true
                            Rectangle {
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                height: sysNameBar.r * 2
                                radius: sysNameBar.r
                                color: sysNameBar.barColor
                            }
                        }
                        // System tile titles: its own setting, separate from game tiles.
                        opacity: (isHero || systemTitleMode === "Never") ? 0
                               : ((selected || systemTitleMode === "Always") ? 1 : 0)
                        Behavior on opacity { NumberAnimation { duration: 120 } }

                    Text {
                        anchors { left: parent.left; leftMargin: vpx(8); right: parent.right; rightMargin: vpx(6); verticalCenter: parent.verticalCenter }
                        id: sysBarText
                        text: coll ? coll.name : ""
                        color: "white"; font.family: subtitleFont.name
                        font.pixelSize: Math.max(fpx(11), topRow.tileSz * 0.05); font.bold: true
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                    }
                    }
                }

                // Focus frame: gap, ring and glow in one pass, on the selected
                // tile only — the hero, or a system tile once its background is
                // loaded (one without keeps the accent-fill look). Sized
                // against the grow-on-focus scale so the ring matches the game
                // tiles'.
                Loader {
                    anchors.fill: parent
                    active: selected && (isHero || sysBg.status === Image.Ready)
                    sourceComponent: Item {
                        FocusFrame {
                            anchors.fill: parent
                            artRadius: tile.radius
                            gap: vpx(2) / topRow.growScale
                            ring: vpx(3) / topRow.growScale
                            glow: vpx(6) / topRow.growScale
                        }
                    }
                }


                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: settings.MouseHover == "Yes"
                    onEntered: { playNav(); mainList.currentIndex = topRow.ObjectModel.index; platformlist.currentIndex = index; }
                    onClicked: {
                        if (selected) {
                            if (isHero) { if (platformlist.resumeGame) { launchGame(platformlist.resumeGame); } }
                            else { currentCollectionIndex = sortedColl[index - 1]; collectionVisited = true; softwareScreen(); }
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
                        if (resumeGame) { launchGame(resumeGame); }
                    } else {
                        currentCollectionIndex = sortedColl[currentIndex - 1];
                        collectionVisited = true;
                        softwareScreen();
                    }
                }
            }

        }

        }

        HorizontalCollection {
        id: list1
            ownScreen: "showcasescreen"
            property bool selected: ListView.isCurrentItem
            property var currentList: list1
            property var collection: collection1

            enabled: collection.enabled
            visible: collection.enabled


            height: collection.height

            itemWidth: collection.itemWidth
            itemHeight: collection.itemHeight
            boxArt: collection.boxArt === true
            boxStyle: collection.boxStyle || "Box Art"

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
            ownScreen: "showcasescreen"
            property bool selected: ListView.isCurrentItem
            property var currentList: list2
            property var collection: collection2

            enabled: collection.enabled
            visible: collection.enabled


            height: collection.height

            itemWidth: collection.itemWidth
            itemHeight: collection.itemHeight
            boxArt: collection.boxArt === true
            boxStyle: collection.boxStyle || "Box Art"

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
            ownScreen: "showcasescreen"
            property bool selected: ListView.isCurrentItem
            property var currentList: list3
            property var collection: collection3

            enabled: collection.enabled
            visible: collection.enabled


            height: collection.height

            itemWidth: collection.itemWidth
            itemHeight: collection.itemHeight
            boxArt: collection.boxArt === true
            boxStyle: collection.boxStyle || "Box Art"

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
            ownScreen: "showcasescreen"
            property bool selected: ListView.isCurrentItem
            property var currentList: list4
            property var collection: collection4

            enabled: collection.enabled
            visible: collection.enabled


            height: collection.height

            itemWidth: collection.itemWidth
            itemHeight: collection.itemHeight
            boxArt: collection.boxArt === true
            boxStyle: collection.boxStyle || "Box Art"

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
            ownScreen: "showcasescreen"
            property bool selected: ListView.isCurrentItem
            property var currentList: list5
            property var collection: collection5

            enabled: collection.enabled
            visible: collection.enabled


            height: collection.height

            itemWidth: collection.itemWidth
            itemHeight: collection.itemHeight
            boxArt: collection.boxArt === true
            boxStyle: collection.boxStyle || "Box Art"

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
            ownScreen: "showcasescreen"
            property bool selected: ListView.isCurrentItem
            property var currentList: list6
            property var collection: collection6

            enabled: collection.enabled
            visible: collection.enabled


            height: collection.height

            itemWidth: collection.itemWidth
            itemHeight: collection.itemHeight
            boxArt: collection.boxArt === true
            boxStyle: collection.boxStyle || "Box Art"

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


    // ── Closest-column vertical navigation ──────────────────────────────
    // Moving between rows carries the horizontal position across: pick the item
    // in the destination row whose on-screen centre is nearest the item we were
    // just on, instead of restoring that row's own remembered index.
    function navRowCenterX() {
        var list = null;
        if (mainList.currentIndex === 1) list = platformlist;
        else if (mainList.currentItem && mainList.currentItem.collectionList) list = mainList.currentItem.collectionList;
        if (!list || !list.currentItem) return -1;
        var c = list.currentItem;
        return c.mapToItem(root, c.width / 2, 0).x;          // screen-x centre of current item
    }
    function navNearestIndex(list, tileW, spacing, screenX, count) {
        if (!list || count <= 0 || screenX < 0) return 0;
        var unit = tileW + spacing;
        if (unit <= 0) return 0;
        var local = list.mapFromItem(root, screenX, 0).x;    // x inside the list's viewport
        var i = Math.round((list.contentX + local - tileW / 2) / unit);
        if (i < 0) i = 0;
        if (i > count - 1) i = count - 1;
        return i;
    }
    function navNextEnabled(from, dir) {
        var i = from + dir;
        while (i >= 0 && i < mainList.count) {
            var it = mainList.itemAtIndex(i);
            if (!it || it.enabled) return i;
            i += dir;
        }
        return from;
    }
    // Pre-seat the destination row's savedIndex to the nearest column BEFORE we move,
    // so the row restores straight to that item in ONE step. (Overriding the index
    // AFTER the move changed highlightedGame twice mid-crossfade — that was the flicker.)
    function navPreset(destIndex, screenX) {
        if (screenX < 0) return;
        if (destIndex === 1) {
            platformlist.savedIndex = navNearestIndex(platformlist, topRow.tileSz, platformlist.spacing, screenX, platformlist.count);
        } else {
            var it = mainList.itemAtIndex(destIndex);
            if (!it || !it.collectionList) return;
            var list = it.collectionList;
            var unit = it.itemWidth + list.spacing;
            if (unit <= 0) return;
            var local = list.mapFromItem(root, screenX, 0).x;
            var i = Math.round((list.contentX + local - it.itemWidth / 2) / unit);
            if (i < 0) i = 0;
            if (i > list.count - 1) i = list.count - 1;
            it.savedIndex = i;
        }
    }

    ListView {
    id: mainList
        z: 2   // above dim overlay (z:1) so tiles render at full brightness
        // When the nav bar is reached via the LB/RB shortcut we must NOT glide the
        // page to the top; remember the row so we can restore it on the way back.
        property bool navJump: false
        property int  savedRow: 1
        onActiveFocusChanged: {
            if (activeFocus && navJump) {            // safety net (e.g. returning from a sub-screen)
                navJump = false;
                if (currentIndex < 0) currentIndex = savedRow;
            }
        }

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
            if (navJump) return;            // jumping to/from the nav bar: leave scroll position alone
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
            navPreset(navNextEnabled(currentIndex, -1), navRowCenterX());   // seat nearest column before moving
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
            navPreset(navNextEnabled(currentIndex, 1), navRowCenterX());   // seat nearest column before moving
            playNav();
            // Leaving the top zone (index >= 1): restore ApplyRange BEFORE the
            // index changes, otherwise the list's internal repositioning runs
            // while still in NoHighlightRange and never scrolls down. (At index
            // 0 we leave it alone so landing on the first row stays glued to top.)
            if (currentIndex >= 1) {
                glideTop.stop();
                highlightRangeMode = ListView.ApplyRange;
            }
            var before = currentIndex;
            do {
                incrementCurrentIndex();
            } while (!currentItem.enabled);
            // Index 0 is the empty spacer that lets the background show at the
            // top — it's "enabled" but has nothing to focus, so wrapping off the
            // last collection used to land there and need a second press to
            // reach the system tiles. Step past it in one go.
            if (currentIndex === 0) incrementCurrentIndex();

            // Wrapped from the last collection back to the top: ApplyRange was
            // switched on above and had already snapped contentY partway, so the
            // glide started from the wrong place and the system tiles came to
            // rest half off-screen. Settle the top zone explicitly instead.
            if (currentIndex < before) {
                glideTop.stop();
                highlightRangeMode = ListView.NoHighlightRange;
                positionViewAtBeginning();
            }
        }
    }

    // Wheel moves the selected ROW. Only while the rows themselves are
    // focused — with a header button focused the wheel would otherwise move
    // a list the user isn't in. navJump/savedRow are left alone: this is an
    // ordinary row change, not a jump to the nav bar.
    WheelNav {
        anchors.fill: mainList
        view: mainList
        columns: 1
        active: mainList.activeFocus
        onStepped: function() { playNav(); }
    }

    // Global input handling for the screen
    // Mouse back button: mirrors B exactly. On the Showcase that means
    // Discover from the rows — and, from a header button, returning to the
    // rows (restoring the saved row so a navJump doesn't glide to the top),
    // which is what those buttons' own B handlers do.
    function mouseBack() {
        if (!mainList.activeFocus) {
            if (mainList.navJump) { mainList.navJump = false; mainList.currentIndex = mainList.savedRow; }
            mainList.focus = true;
            return;
        }
        discoverScreen();
    }

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
        // LB / RB — jump straight up to the nav bar from the content area
        if ((api.keys.isPrevPage(event) || api.keys.isNextPage(event)) && !event.isAutoRepeat) {
            event.accepted = true;
            if (mainList.activeFocus) {
                playNav();
                mainList.savedRow = mainList.currentIndex;   // remember where we were
                mainList.navJump  = true;                    // don't glide the page to the top
                homebutton.focus  = true;
            }
        }
    }

    // Helpbar buttons
    ListModel {
        id: gridviewHelpModel

        // `icon` must be declared on the FIRST element: a ListModel fixes its
        // roles from element one, so a role introduced later is ignored.
        // Empty means "use the controller glyph for `button`".
        ListElement {
            name: "Discover"
            button: "cancel"
            icon: ""
        }
        ListElement {
            name: "Settings"
            button: "filters"
            icon: ""
        }
        ListElement {
            name: "Refresh"
            button: "details"
            icon: ""
        }
        ListElement {
            name: "Select"
            button: "accept"
            icon: ""
        }
    }

    onActiveFocusChanged: {
        if (activeFocus) {
            currentHelpbarModel = gridviewHelpModel;
            listRecommended.maybeRefresh();   // re-pick Recommended only if the showcased count changed
            // Re-read live settings on every return to this screen. Coming back
            // from Settings always lands here, so the featured box picks up a
            // changed "Featured Box Content" without depending on the settings
            // screen having bumped the counter itself.
            settingsEpoch++;
            // ...and re-read the hero once that settles: a hide option changed
            // in Settings must not leave the hero on an app it now hides.
            Qt.callLater(platformlist.refreshResume);
        }
    }

}
