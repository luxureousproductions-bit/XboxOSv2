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
import QtGraphicalEffects 1.15
import SortFilterProxyModel 0.2
import QtQml.Models 2.15
import QtMultimedia 5.15
import "../Global"
import "../Lists"
import "../utils.js" as Utils

FocusScope {
id: root

    property var game: api.allGames.get(0)
    property string favIcon: game && game.favorite ? "../assets/images/icon_unheart.svg" : "../assets/images/icon_heart.svg"
    property string collectionName: game ? game.collections.get(0).name : ""
    property string collectionShortName: game ? game.collections.get(0).shortName : ""
    property bool iamsteam: game ? (collectionShortName == "steam") : false
    property bool canPlayVideo: settings.VideoPreview === "Yes"
    property real detailsOpacity: (settings.DetailsDefault === "Yes") ? 1 : 0
    property bool blurBG: settings.GameBlurBackground === "Yes"
    // One-way latch: true once the details panel has been opened for the first
    // time (or immediately when "Default to full details" is enabled). Used to
    // defer instantiation of the boxart image and GameInfo until they are needed.
    property bool detailsEverShown: settings.DetailsDefault === "Yes"
    property string publisherName: {
        if (game !== null && game.publisher !== null) {
            var str = game.publisher;
            var result = str.split(" ");
            return result[0]
        } else {
            return ""
        }
    }
    
    // --- BEGIN: More section – merged Publisher/Developer list (Option 5) ---
    // publisher/developer/currentTitle are set imperatively in the debounce timer
    // (filterDebounce), followed by an explicit rebuild() call.
    ListPublisherDeveloper {
        id: publisherCollection
        max: 20
    }
    // --- END: More section – merged Publisher/Developer list (Option 5) ---

    // --- BEGIN: More section – Recommended Games fallback ---
    // Shown in place of the Publisher/Developer list when that list is empty.
    // Only affects the "More" section of the Game Details page.
    ListRecommended {
        id: recommendedCollection
        max: 20
        omitApplication: omitAppsLive
        omitEmulator: omitEmulatorsLive
        // Same app/emulator sets as the Home rows, so Pegasus imports are
        // hidden here too (genre tags alone can't see them).
        hideTitles: homeHideTitles
    }
    // --- END: More section – Recommended Games fallback ---

    // --- BEGIN: More section – main-genre list (Option B: JS array) ---
    // genre/currentTitle are set imperatively in the debounce timer, then
    // rebuild() fires a single JS pass matching only the main genre (left of "/").
    ListGenreExpanded {
        id: genreCollection
        max: 20
    }
    // --- END: More section – main-genre list (Option B: JS array) ---

    // Combine the video and the screenshot arrays into one
    function mediaArray() {
        let mediaList = [];
        if (game && game.assets.video && settings.CarouselVideo === "Yes" && !videoUnsupported)
            game.assets.videoList.forEach(v => mediaList.push(v));

        if (game) {
            if (settings.CarouselScreenshots === "Yes")
                game.assets.screenshotList.forEach(v => mediaList.push(v));
            if (settings.CarouselTitleScreen === "Yes" && game.assets.titlescreen)
                mediaList.push(game.assets.titlescreen);
            if (settings.CarouselFanart === "Yes")
                game.assets.backgroundList.forEach(v => mediaList.push(v));
            var art3d = Utils.get3dBoxArt(game);
            if (settings.Carousel3DBox === "Yes" && art3d)
                mediaList.push(art3d);
            // In Pegasus, ALL box images (box3d, box2dFront, etc.) are stored in boxFrontList.
            // Push every 2D entry that wasn't already added as the 3D art above.
            // Pegasus X marks every 3D box (extra.box3d), so the others are
            // left out of the 2D list too.
            if (settings.Carousel2DBox === "Yes" && game.assets.boxFrontList) {
                var known3d = Utils.box3dList(game).length > 0;
                game.assets.boxFrontList.forEach(function(url) {
                    if (url && url !== art3d && !(known3d && Utils.is3dFor(game, url))) mediaList.push(url);
                });
            }
            if (settings.CarouselBackBox === "Yes" && game.assets.boxBack)
                mediaList.push(game.assets.boxBack);
            if (settings.CarouselCartridge === "Yes" && game.assets.cartridge)
                mediaList.push(game.assets.cartridge);
            // steamList contains all steamgrid/miximage images (UI_STEAMGRID slot in Pegasus).
            // Push all entries so they appear in the media viewer for browsing.
            // getMiximage() separately picks the best one for the box art thumbnail.
            if (settings.CarouselMiximage === "Yes" && game.assets.steamList) {
                game.assets.steamList.forEach(function(url) {
                    if (url) mediaList.push(url);
                });
            }
            if (game.assets.poster)     mediaList.push(game.assets.poster);
            if (settings.CarouselBanner === "Yes" && game.assets.banner) mediaList.push(game.assets.banner);
            if (game.assets.tile)       mediaList.push(game.assets.tile);
            if (settings.CarouselWheel === "Yes" && game.assets.logo)
                mediaList.push(game.assets.logo);
        }

        return mediaList;
    }

    // Reset the screen to default state
    function reset() {
        content.currentIndex = 0;
        menu.currentIndex = 0;
        media.savedIndex = 0;
        list1.savedIndex = 0;
        list2.savedIndex = 0;
        screenshot.opacity = 1;
        mediaScreen.opacity = 0;
        manualScreen.opacity = 0;
        toggleVideo(true);
        // Defer the "More" list filter updates (Options 1 & 2) so the expensive
        // ExpressionFilter scans don't block the navigation transition.
        filterDebounce.restart();
    }

    // Show/hide the details overlay
    // Watches the theme-level one-shot flag. GameView is kept alive after its
    // first load, so Component.onCompleted would only ever fire once —
    // reacting to the flag flipping false->true works on every visit, and
    // survives detailsOpacity's binding being broken by showDetails().
    property bool wantFullDetails: forceFullDetails
    onWantFullDetailsChanged: {
        if (wantFullDetails) {
            detailsEverShown = true;
            detailsOpacity = 1;
            toggleVideo(false);
        }
    }

    function showDetails() {
        if (detailsOpacity === 1) {
            toggleVideo(true);
            detailsOpacity = 0;
        }
        else {
            detailsEverShown = true;
            detailsOpacity = 1;
            toggleVideo(false);
        }
    }

    // Show/hide the media view
    function showMedia(index) {
        playAccept();
        mediaScreen.mediaIndex = index;
        mediaScreen.focus = true;
        mediaScreen.opacity = 1;
    }

    function closeMedia() {
        playBack();
        mediaScreen.opacity = 0;
        content.focus = true;
        currentHelpbarModel = gameviewHelpModel;
    }

    onGameChanged: { reset(); scheduleExtras(); }

    // Pre-computed media list for this game; used by both the strip and the full-screen viewer.
    // Binding to `game` means it is computed once per game change instead of twice.
    readonly property var mediaList: game ? mediaArray() : []

    // Game manual (PDF). Needs a Pegasus build with PDF support, which adds
    // api.pdfPageCount(); on stock Pegasus this stays "" and the Manual
    // button never shows. Tried in order, first match wins:
    //   1. x-manual: <path> in the metadata (absolute, or relative to the ROM)
    //   2. next to the game's own art: if the box art is
    //      .../media/box2dfront/<sub path>/<name>.png, then
    //      .../media/manuals/<sub path>/<name>.pdf (exactly the Skraper
    //      layout Pegasus used to find the art, multi-disc folders included)
    //   3. the ROM folder and its parent (for games without art):
    //      <dir>/media/manuals/<path below dir>.pdf, and for games in a
    //      subfolder also <folder name>.pdf / <folder name>/<folder name>.pdf
    //   4. <dir>/media/manuals/<game title>.pdf
    // Each step tries media/manuals, media/manual and plain manuals.
    //
    // Only looked up while Game details is on screen, and once per game per
    // session. This screen stays loaded with `game` following the Home
    // cursor, so a binding here ran the whole lookup (file opens, often on
    // the SD card) on every Home move.
    property string manualPath: ""
    property var manualCache: ({})

    // RetroAchievements game ID when this game has achievements, else 0 (or
    // -1 while its console list hasn't been downloaded). Same rule as the
    // Manual button: no achievements, no button.
    property int raGameId: 0

    readonly property bool extrasWanted: !!game && gameviewloader.shown
    onExtrasWantedChanged: scheduleExtras()

    function scheduleExtras() {
        manualPath = "";
        raGameId = 0;
        if (extrasWanted) Qt.callLater(resolveExtras);
    }

    function resolveExtras() {
        if (!extrasWanted) return;
        var files = (game.files && game.files.count > 0) ? (game.files.get(0).path || "") : "";
        var key = files !== "" ? files : (collectionShortName + "|" + game.title);
        if (manualCache[key] === undefined) manualCache[key] = findManual(game);
        manualPath = manualCache[key];
        refreshRa();
    }

    function refreshRa() {
        if (!extrasWanted) return;
        raGameId = cheevosData.quickGameId(game.title, collectionShortName);
        if (raGameId < 0) cheevosData.prefetchList(collectionShortName);
    }

    Connections {
        target: cheevosData
        onListsEpochChanged: refreshRa()
    }

    function localPath(url) {
        var p = url ? String(url) : "";
        if (p.indexOf("file://") === 0) p = p.substring(7);
        try { p = decodeURIComponent(p); } catch (err) {}
        return p;
    }

    function stripExt(path) {
        var dot = path.lastIndexOf(".");
        return (dot > path.lastIndexOf("/")) ? path.substring(0, dot) : path;
    }

    function findManual(g) {
        if (!platform.hasPdf) return "";

        // Pegasus X (build 2124+) finds the manual itself: x-manual, media/
        // manual(s) in any case, media/<game>/manual.pdf, ES-DE's manuals.
        var pm = g.extra ? g.extra.manual : null;
        if (pm) {
            var first = (typeof pm === "string") ? pm : (pm.length ? pm[0] : "");
            if (first) return first;
        }

        var candidates = [];
        var seen = {};
        function add(path) {
            if (path && !seen[path]) { seen[path] = true; candidates.push(path); }
        }
        // Folder names: "manuals" and "manual" are both accepted
        function addRoot(root, name) {
            add(root + "/media/manuals/" + name + ".pdf");
            add(root + "/media/manual/" + name + ".pdf");
            add(root + "/manuals/" + name + ".pdf");
        }

        var romPath = (g.files && g.files.count > 0) ? (g.files.get(0).path || "") : "";
        if (romPath.indexOf("android:") === 0) romPath = "";
        var romDir = romPath.substring(0, Math.max(0, romPath.lastIndexOf("/")));

        // 1. metadata
        var extra = g.extra ? g.extra["manual"] : undefined;
        if (extra) {
            var e = (typeof extra === "string") ? extra : (extra[0] || "");
            if (e !== "") add(e.charAt(0) === "/" ? e : romDir + "/" + e);
        }

        // 2. mirror the art's location
        var a = g.assets;
        var arts = [a.boxFront, a.screenshot, a.logo, a.background, a.titlescreen,
                    a.boxBack, a.cartridge, a.marquee, a.video];
        for (var i = 0; i < arts.length; i++) {
            var art = localPath(arts[i]);
            var m = art.lastIndexOf("/media/");
            if (m < 0) continue;
            var rest = art.substring(m + 7);              // <type>/<sub path>/<name>.ext
            var typeEnd = rest.indexOf("/");
            if (typeEnd < 0) continue;
            addRoot(art.substring(0, m), stripExt(rest.substring(typeEnd + 1)));
            break;
        }

        // 3. walk up from the ROM folder: the folder itself and its parent
        //    (enough for one level of game subfolders; going higher would
        //    match collection names, eg. iROMs/media/manuals/psx.pdf)
        if (romDir !== "") {
            var dir = romDir;
            for (var level = 0; level < 2 && dir.lastIndexOf("/") > 0; level++) {
                var rel = stripExt(romPath.substring(dir.length + 1));
                addRoot(dir, rel);
                var sub = rel.indexOf("/");
                if (sub > 0) {
                    var folder = rel.substring(0, sub);
                    var base = rel.substring(rel.lastIndexOf("/") + 1);
                    addRoot(dir, base);
                    addRoot(dir, folder);
                    addRoot(dir, folder + "/" + folder);
                }
                // 4. by title, at the ROM folder and its parent
                if (g.title) addRoot(dir, g.title);
                dir = dir.substring(0, dir.lastIndexOf("/"));
            }
        }

        // Pegasus X with findManual: one native call that only checks the
        // files exist (no PDF parsing)
        if (platform.hasFindManual)
            return api.findManual(candidates) || "";
        for (var c = 0; c < candidates.length; c++) {
            if (api.pdfPageCount(candidates[c]) > 0) return candidates[c];
        }
        return "";
    }

    // Show/hide the manual reader
    function showManual() {
        if (manualPath === "") return;
        playAccept();
        // The preview only stops when leaving the top row, and the Manual
        // button is on the top row, so stop it here
        toggleVideo(false);
        manualScreen.open(manualPath, game.title);
        manualScreen.focus = true;
        manualScreen.opacity = 1;
    }

    function closeManual() {
        playBack();
        manualScreen.opacity = 0;
        content.focus = true;
        currentHelpbarModel = gameviewHelpModel;
        // Back on the top row with details closed: preview resumes as usual
        if (content.currentIndex === 0 && detailsOpacity === 0)
            toggleVideo(true);
    }

    anchors.fill: parent

    // Video
    // Show/hide the video
    function toggleVideo(toggle) {
      if (!toggle)
      {
        // Turn off video. Cancel the two start-up timers NOW, not when
        // stopvideo fires a second later: if the list left row 0 while the
        // video was still spinning up, videoDelay / fadescreenshot would
        // otherwise still fire and put screenshot.opacity back to 0 - which is
        // why the art went missing on the Media row when scrolling right as
        // the preview began.
        videoDelay.stop();
        fadescreenshot.stop();
        screenshot.opacity = 1;
        stopvideo.restart();
      } else {
        stopvideo.stop();
        // Turn on video
        if (canPlayVideo)
            videoDelay.restart();
      }
    }

    // Timer to show the video
    Timer {
    id: videoDelay

        interval: 2000
        onTriggered: {
            if (game && game.assets.videos.length && canPlayVideo) {
                videoPreviewLoader.sourceComponent = videoPreviewWrapper;
                fadescreenshot.begin();
            }
        }
    }

    // NOTE: Next fade out the bg so there is a smooth transition into the video
    Timer {
    id: fadescreenshot

        interval: 1000
        // Fades the picture only once the video is really showing frames. It
        // used to fade after a fixed second whether or not the video had
        // started, so a video that never plays (no codecs on Windows) left a
        // black screen. Re-checks every half second for ~5s, then gives up
        // and keeps the picture.
        property int tries: 0
        onTriggered: {
            var w = videoPreviewLoader.item;
            if (!w || w.failed) { tries = 0; return; }
            if (w.framesFlowing) {
                tries = 0;
                // The blur layer's opacity is bound to screenshot.opacity, so
                // this one write fades both.
                screenshot.opacity = 0;
                return;
            }
            if (tries < 10) { tries += 1; interval = 500; restart(); }
            else tries = 0;
        }
        // Every new start begins with the full first second and no retries.
        function begin() { tries = 0; interval = 1000; restart(); }
    }

    Timer {
    id: stopvideo

        interval: 1000
        onTriggered: {
            videoPreviewLoader.sourceComponent = undefined;
            videoDelay.stop();
            fadescreenshot.stop();
        }
    }

    // Options B & 5: Debounce timer for the "More" list filter inputs.
    // Fires 200 ms after a game change so all scans run after the navigation
    // transition has rendered.
    // Both genre and publisher/developer lists are rebuilt via a single JS pass
    // each (rebuild()) instead of reactive ExpressionFilters.
    // Option 2: recommendedCollection.refresh() is only called when the
    // publisher/developer list comes up empty (avoiding the scan entirely
    // when it's not needed).
    Timer {
    id: filterDebounce

        interval: 200
        onTriggered: {
            var title = game ? game.title : "";

            // Option 5: publisher/developer
            publisherCollection.publisher    = game && game.publisher ? game.publisher : "";
            publisherCollection.developer    = game && game.developer ? game.developer : "";
            publisherCollection.currentTitle = title;
            publisherCollection.rebuild();
            // Refresh the recommended fallback only when the publisher/developer
            // list has no results (Option 2: skip the scan when not needed).
            if (publisherCollection.games.length === 0) {
                recommendedCollection.active = true;   // arm the proxy only when actually shown
                recommendedCollection.refresh();
            }

            // Option B: genre – extract the correct genre token based on the
            // "More by Genre Display" setting, then trigger a rebuild.
            var genreStr  = game && game.genreList.length > 0 ? game.genreList[0] : "";
            var sepMatch  = genreStr.match(/^(.*?)\s*[\/,]\s*(.+)$/);
            var mainGenre = sepMatch ? sepMatch[1].trim() : genreStr;
            var subGenre  = sepMatch ? sepMatch[2].trim() : mainGenre;
            var modeStr   = settings.MoreByGenreDisplay || "Main Genre";
            var genreTarget, genreMatchMode;
            if (modeStr === "Sub Genre") {
                genreTarget    = subGenre;
                genreMatchMode = "sub";
            } else if (modeStr === "Full") {
                genreTarget    = genreStr;
                genreMatchMode = "full";
            } else {
                genreTarget    = mainGenre;
                genreMatchMode = "main";
            }
            genreCollection.genre        = genreTarget;
            genreCollection.matchMode    = genreMatchMode;
            genreCollection.currentTitle = title;
            genreCollection.rebuild();
        }
    }

    // NOTE: Video Preview
    // High Quality Mode kill switch for the sharpen below. Lives here, not in
    // the Component: a Component can't declare properties (that's what failed
    // to load). See the DEVICE CHECK note by the Loader.
    property bool gameViewSharpen: true

    Component {
    id: videoPreviewWrapper

      Item {
        anchors.fill: parent
        // Read by fadescreenshot: frames actually on screen / playback failed.
        readonly property bool framesFlowing: videocomponent.playbackState === MediaPlayer.PlayingState
                                              && videocomponent.position > 0
        readonly property bool failed: videocomponent.error !== MediaPlayer.NoError

        Video {
        id: videocomponent
            // Stop before the player is destroyed (screen change, row rebuild, or
            // Pegasus unloading the theme to launch a game): destroying a playing
            // video is what the Windows media backend crashes on.
            Component.onDestruction: stop()
            onErrorChanged: reportVideoError(videocomponent)   // logged; see videoUnsupported in theme.qml

            property bool videoExists: game ? game.assets.videos.length : false
            // Cleared off-screen, same reason as the other players.
            source: (videoExists && playbackOwner === "gameviewscreen")
                    ? game.assets.videos[0] : ""
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
            // Also muted at once under the manual: toggleVideo(false) only
            // unloads the player after its 1 s fade
            muted: settings.AllowVideoPreviewAudio === "No"
                   || playbackOwner !== "gameviewscreen"
                   || manualScreen.visible
            loops: MediaPlayer.Infinite
            autoPlay: true
            //onPlaying: videocomponent.seek(5000)
        }

        // High Quality Mode: sharpen over the Game View video. Same fail-safe
        // Loader as Discover — with HQ off none of this exists.
        //
        // DEVICE CHECK NEEDED: this video is PreserveAspectCrop, and capturing
        // a cropped VideoOutput through an FBO has been seen to lose the crop
        // on this stack (pillarbox bars appear — see the note in
        // ItemHighlight). If bars show with HQ on, set gameViewSharpen to
        // false at the top of this file; the proper fix is then to crop via
        // the effect's geometry rather than the VideoOutput.
        Loader {
            anchors.fill: videocomponent
            active: hqMode && gameViewSharpen
            sourceComponent: VideoSharpen {
                source: videocomponent
                amount: 0.5
            }
        }
      }

    }

    // Video
    Loader {
    id: videoPreviewLoader

        asynchronous: true
        anchors { fill: parent }
    }

    // Background
    Image {
    id: screenshot

        anchors.fill: parent
        asynchronous: true
        // First screenshot / fanart. (A "random background" option was read
        // here but never existed as a setting, so it was always the first.)
        property var randoScreenshot: game ? game.assets.screenshotList[0] : ""
        property var randoFanart: game ? game.assets.backgroundList[0] : ""
        // Banner falls back to fanart for games that have none.
        property var actualBackground: (settings.GameBackground === "Screenshot") ? randoScreenshot
                                     : (settings.GameBackground === "Banner" && game && game.assets.banner) ? game.assets.banner
                                     : Utils.fanArt(game) || randoFanart;
        source: actualBackground || ""
        sourceSize: Qt.size(root.width, root.height)
        fillMode: Image.PreserveAspectCrop
        smooth: false
        Behavior on opacity { NumberAnimation { duration: 500 } }
        visible: !blurBG
    }

    // Blur background – shader is compiled only when the blur setting is active.
    // blurSource and blurOpacity are surfaced as Loader properties so the inner
    // Component can reference them via parent without relying on ID scope crossing.
    Loader {
        id: blurLoader
        anchors.fill: screenshot
        active: blurBG
        readonly property Item blurSource: screenshot
        readonly property real blurOpacity: screenshot.opacity
        sourceComponent: Component {
            FastBlur {
                cached: true   // static: blur once, not every frame
                // Big desktop screens: blur at 1080p size and scale up (1 on Android).
                width: parent.width / hiResScale
                height: parent.height / hiResScale
                scale: hiResScale
                transformOrigin: Item.TopLeft
                source: blurLoader.blurSource
                radius: 64
                opacity: blurLoader.blurOpacity
                Behavior on opacity { NumberAnimation { duration: 500 } }
            }
        }
    }

    // HQ: the art fades away in place (Showcase crossfade pace) under this
    // cover, in the same colour the sliding overlay ends on, so HQ and base
    // arrive at the identical resting page. Base never draws it.
    Rectangle {
        anchors.fill: parent
        color: theme.gradientend
        opacity: (hqMode && artAway) ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: hqFanartFadeMs; easing.type: Easing.InOutQuad } }
    }

    // Scanlines
    Image {
    id: scanlines

        anchors.fill: parent
        source: settings.ShowScanlines === "Yes" ? "../assets/images/scanlines_v3.png" : ""
        asynchronous: true
        opacity: 0.2
        visible: !iamsteam && (settings.ShowScanlines == "Yes")
    }

    // Clear logo
    // Top state used by the logo/title/shadow. Keys off the list's actual top
    // position (atYBeginning), not just currentIndex — so a mouse wheel or
    // finger flick (which scrolls contentY without changing currentIndex) also
    // hides the logo, matching controller behavior.
    // Also off while the manual reader is open: the logo sits above it in z
    // (the media viewer never needed this, it opens from the media row).
    property bool logoAtTop: content.atYBeginning && content.currentIndex === 0 && detailsScreen.opacity === 0 && !manualScreen.visible
    Image {
    id: logo

        anchors { 
            top: parent.top; //topMargin: vpx(70)
            left: parent.left; leftMargin: vpx(70)
        }
        width: vpx(500)
        height: vpx(450) + header.height
        source: settings.GameLogo === "Show" && game ? Utils.logo(game) : ""
        sourceSize { width: hrpx(512); height: hrpx(512) }
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        opacity: logoAtTop ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        z: logoAtTop ? 10 : -10
        visible: settings.GameLogo === "Show"
    }

    // Drop shadow behind the logo – shader compiled only when logo is shown.
    // shadowSource and shadowOpacity are surfaced as Loader properties so the
    // inner Component can reference them via parent without relying on ID scope.
    Loader {
        id: shadowLoader
        anchors.fill: logo
        active: settings.GameLogo === "Show"
        readonly property Item shadowSource: logo
        readonly property real shadowOpacity: logoAtTop ? 0.4 : 0
        sourceComponent: Component {
            DropShadow {
                cached: true   // static: blur once, not every frame
                anchors.fill: parent
                horizontalOffset: 0
                verticalOffset: 0
                radius: 8.0
                samples: 9
                color: "#000000"
                source: shadowLoader.shadowSource
                opacity: shadowLoader.shadowOpacity
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }
    }

    // Platform title
    Text {
    id: gametitle
        
        text: game.title
        
        anchors {
            top:    logo.top;
            left:   logo.left;//    leftMargin: globalMargin
            right:  parent.right;
            bottom: logo.bottom
        }
        
        color: theme.text
        font.family: titleFont.name
        font.pixelSize: fpx(80)
        font.bold: true
        horizontalAlignment: Text.AlignHLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        wrapMode: Text.WordWrap
        lineHeight: 0.8
        visible: logo.source === "" || settings.GameLogo === "Text only"
        opacity: logoAtTop ? 1 : 0
    }

    // Gradient – plain Rectangle avoids the shader-compilation stall on first
    // load that the QtGraphicalEffects LinearGradient causes. Qt's built-in
    // Rectangle gradient is rendered without a custom GLSL effect.
    Rectangle {
    id: bggradient

        width: parent.width
        height: parent.height/2
        gradient: Gradient {
            GradientStop { position: 0.0; color: theme.gradientstart }
            GradientStop { position: 0.7; color: theme.gradientend }
        }
        y: (artAway && !hqMode) ? -height : height
        Behavior on y { NumberAnimation { duration: 200 } }
    }

    // Below the Play row the page dresses like the Platform page: a solid
    // band behind the header, a soft shadow under it, and the last row
    // dissolving into theme.main above the prompts.
    // In both modes the band, its depth shadow and the bottom fade come up
    // when the first "More" list (list1) is reached, not on the Media
    // carousel, and the art stays behind the carousel until the list moves
    // past it (row 2+). The modes differ in HOW:
    //   Base: band/bottom fade in at 350 ms; the art slides away behind the
    //         gradient in 200 ms, as it always has.
    //   HQ:   band, bottom fade AND the art all ease at the Showcase
    //         crossfade's pace (hqFanartFadeMs, InOutQuad); the art fades
    //         in place under a cover rather than sliding.
    readonly property bool scrolledPast: content.currentIndex >= list1.ObjectModel.index
    readonly property bool artAway:      content.currentIndex > 1
    readonly property int  chromeFadeMs: hqMode ? hqFanartFadeMs : 350
    readonly property int  chromeEasing: hqMode ? Easing.InOutQuad : Easing.Linear
    // Gate for the band / depth / bottom fade while the fullscreen media
    // viewer is up (they sit above it in z). Drops in step with the viewer's
    // own 100 ms fade-in; comes back over the chrome fade so it eases in under
    // the logo and nav instead of popping. The duration is read when the
    // Behavior starts, i.e. after mediaScreen.visible has already flipped.
    property real viewerGate: mediaScreen.visible ? 0 : 1
    Behavior on viewerGate { NumberAnimation { duration: mediaScreen.visible ? 100 : chromeFadeMs; easing.type: chromeEasing } }

    Rectangle {
    id: overlay

        color: theme.gradientend
        anchors {
            left: parent.left; right: parent.right
            top: bggradient.bottom; bottom: parent.bottom
        }
    }

    // Background dimming - same "Grid background dimming" level as the
    // Platform page. Declared HERE, above the art, the HQ cover, the gradient
    // and the overlay (all of which are the page's backdrop in one state or
    // another) and below the details panel, header and content. Rides on the
    // backdrop's opacity so it lifts with it when the video plays, and hands
    // off to the details panel's own dim layer while that is showing.
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: gridDimOpacity * screenshot.opacity * (1 - detailsScreen.opacity)
        visible: opacity > 0
    }

    

    // Details screen
    Item {
    id: detailsScreen
        
        anchors.fill: parent
        visible: opacity !== 0
        opacity: (content.currentIndex !== 0) ? 0 : detailsOpacity
        Behavior on opacity { NumberAnimation { duration: 200 } }

        // Inner content is deferred until the panel is first opened (or at
        // startup when "Default to full details" is enabled) to avoid loading
        // the box art image and GameInfo metadata on every navigation.
        // headerH surfaces header.height as an explicit Loader property so the
        // inner Component can access it via parent.headerH without relying on
        // cross-Component ID lookups.
        Loader {
            id: detailsContentLoader
            anchors.fill: parent
            asynchronous: true
            active: detailsEverShown
            readonly property real headerH: header.height
            sourceComponent: Component {
                Item {
                    anchors.fill: parent

                    Rectangle {
                        anchors.fill: parent
                        color: theme.main
                        opacity: 0.7
                    }
                    // Background dimming sits ABOVE the wash and below the
                    // text: the wash is 70% page colour, so the page-level dim
                    // under it is all but invisible while details are up.
                    Rectangle {
                        anchors.fill: parent
                        color: "#000000"
                        opacity: gridDimOpacity
                        visible: opacity > 0
                    }

                    Item {
                    id: details

                        anchors {
                            top: parent.top; topMargin: vpx(100)
                            left: parent.left; leftMargin: vpx(70)
                            right: parent.right; rightMargin: vpx(70)
                        }
                        height: vpx(450) - detailsContentLoader.headerH

                        Image {
                        id: boxart

                            source: Utils.boxArt(game, settings.BoxArtStyle)
                            width: vpx(350)
                            height: parent.height
                            sourceSize { width: hrpx(512); height: hrpx(512) }
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                        }

                        GameInfo {
                        id: info

                            anchors {
                                left: boxart.right; leftMargin: vpx(30)
                                top: parent.top; bottom: parent.bottom; right: parent.right
                            }
                        }
                    }
                }
            }
        }
    }

    // Header
    Item {
    id: header

        anchors {
            left: parent.left; 
            right: parent.right
        }
        height: vpx(75)
        // z: 10 puts it above the manual reader, whose own title bar sits here
        opacity: manualScreen.visible ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 100 } }

        // Platform-page band: fades in once the list leaves the Play row.
        // Never over the fullscreen media viewer (it sits under the header).
        Rectangle {
            anchors.fill: parent
            color: theme.main
            opacity: (scrolledPast ? 1 : 0) * viewerGate
            Behavior on opacity { NumberAnimation { duration: chromeFadeMs; easing.type: chromeEasing } }
        }

        // Platform logo
        Image {
        id: platformlogo

            anchors {
                top: parent.top; topMargin: vpx(20)
                bottom: parent.bottom; bottomMargin: vpx(20)
                left: parent.left; leftMargin: globalMargin
            }
            fillMode: Image.PreserveAspectFit
            source: systemLogoSource(game.collections.get(0))
            sourceSize { width: hrpx(256); height: hrpx(256) }
            smooth: true
            asynchronous: true

            // Mouse/touch functionality
            MouseArea {
                anchors.fill: parent
                hoverEnabled: settings.MouseHover == "Yes"
                onClicked: previousScreen();
            }
        }

        // Platform title
        Text {
        id: softwareplatformtitle
            
            text: game.collections.get(0).name
            
            anchors {
                top:    parent.top;
                left:   parent.left;    leftMargin: globalMargin
                right:  parent.right
                bottom: parent.bottom
            }
            
            color: theme.text
            font.family: titleFont.name
            font.pixelSize: fpx(30)
            font.bold: true
            horizontalAlignment: Text.AlignHLeft
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            visible: platformlogo.status == Image.Error

            // Mouse/touch functionality
            MouseArea {
                anchors.fill: parent
                hoverEnabled: settings.MouseHover == "Yes"
                onClicked: previousScreen();
            }
        }
        z: 10

        // 4 nav buttons — centered in header
        Rectangle {
        id: gv_homebutton
            color: "transparent"
            NavPill { focused: gv_homebutton.focus; light: whiteBackground; icon: "../assets/images/icon_home.svg"; iconFilled: "../assets/images/icon_home_fill.svg" }
            width: vpx(32); height: vpx(32); radius: height / 2
            anchors { verticalCenter: parent.verticalCenter; horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -vpx(48) }

            onFocusChanged: if (focus) playNav();
            Keys.onDownPressed:  { event.accepted = true; content.focus = true; }
            Keys.onRightPressed: gv_discoverbutton.focus = true;
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; showcaseScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; content.focus = true; }
                if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; gv_discoverbutton.focus = true; }
                if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; gv_settingsbutton.focus = true; }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: settings.MouseHover == "Yes"
                onEntered: gv_homebutton.focus = true; onExited: gv_homebutton.focus = false;
                onClicked: showcaseScreen();
            }
        }

        Rectangle {
        id: gv_discoverbutton
            color: "transparent"
            NavPill { focused: gv_discoverbutton.focus; light: whiteBackground; icon: "../assets/images/icon_discover.svg" }
            width: vpx(32); height: vpx(32); radius: height / 2
            anchors { verticalCenter: parent.verticalCenter; horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: vpx(0) }

            onFocusChanged: if (focus) playNav();
            Keys.onDownPressed:  { event.accepted = true; content.focus = true; }
            Keys.onLeftPressed:  gv_homebutton.focus = true;
            Keys.onRightPressed: gv_settingsbutton.focus = true;
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; discoverScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; content.focus = true; }
                if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; gv_settingsbutton.focus = true; }
                if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; gv_homebutton.focus = true; }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: settings.MouseHover == "Yes"
                onEntered: gv_discoverbutton.focus = true; onExited: gv_discoverbutton.focus = false;
                onClicked: discoverScreen();
            }
        }


        Rectangle {
        id: gv_settingsbutton
            color: "transparent"
            NavPill { focused: gv_settingsbutton.focus; light: whiteBackground; icon: "../assets/images/settingsicon.svg"; iconFilled: "../assets/images/settingsicon_fill.svg" }
            width: vpx(32); height: vpx(32); radius: height / 2
            anchors { verticalCenter: parent.verticalCenter; horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: vpx(48) }

            onFocusChanged: if (focus) playNav();
            Keys.onDownPressed:  { event.accepted = true; content.focus = true; }
            Keys.onLeftPressed:  gv_discoverbutton.focus = true;
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; settingsScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; content.focus = true; }
                if (api.keys.isNextPage(event) && !event.isAutoRepeat) { event.accepted = true; gv_homebutton.focus = true; }
                if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { event.accepted = true; gv_discoverbutton.focus = true; }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: settings.MouseHover == "Yes"
                onEntered: gv_settingsbutton.focus = true; onExited: gv_settingsbutton.focus = false;
                onClicked: settingsScreen();
            }
        }

        // Nav button labels — shown only when the button is highlighted
        Text {
            text: "Home"
            anchors { top: gv_homebutton.bottom; topMargin: vpx(8); horizontalCenter: gv_homebutton.horizontalCenter }
            color: whiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: titleFont.name; font.pixelSize: fpx(11); font.bold: true
            opacity: gv_homebutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "Discover"
            anchors { top: gv_discoverbutton.bottom; topMargin: vpx(8); horizontalCenter: gv_discoverbutton.horizontalCenter }
            color: whiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: titleFont.name; font.pixelSize: fpx(11); font.bold: true
            opacity: gv_discoverbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            text: "Settings"
            anchors { top: gv_settingsbutton.bottom; topMargin: vpx(8); horizontalCenter: gv_settingsbutton.horizontalCenter }
            color: whiteBackground ? "black" : "white"; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.7)
            font.family: titleFont.name; font.pixelSize: fpx(11); font.bold: true
            opacity: gv_settingsbutton.focus ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
    }


    // Game menu
    ObjectModel {
    id: menuModel

        Button { 
        id: button1 

            text: {
                if (!game || game.genreList.length === 0) return "Play game";
                var g = game.genreList[0];
                var sepM = g.match(/^(.*?)\s*[\/,]\s*(.+)$/);
                var lower = (sepM ? sepM[1] : g).trim().toLowerCase();
                return (lower === "application" || lower === "emulator") ? "Open" : "Play game";
            }
            iconVisible: {
                if (!game || game.genreList.length === 0) return true;
                var g2 = game.genreList[0];
                var m2 = g2.match(/^(.*?)\s*[\/,]\s*(.+)$/);
                var low2 = (m2 ? m2[1] : g2).trim().toLowerCase();
                return !(low2 === "application" || low2 === "emulator");
            }
            height: parent.height
            selected: ListView.isCurrentItem && menu.activeFocus
            onHighlighted: { menu.currentIndex = ObjectModel.index; content.currentIndex = 0; }
            onActivated: 
                if (selected) {
                    launchGame(game);
                } else {
                    playNav();
                    menu.currentIndex = ObjectModel.index;
                }
        }

        Button { 
        id: button2 

            icon: "../assets/images/icon_details.svg"
            height: parent.height
            selected: ListView.isCurrentItem && menu.activeFocus
            onHighlighted: { menu.currentIndex = ObjectModel.index; content.currentIndex = 0; }
            onActivated: 
                if (selected) {
                    playToggle();
                    showDetails();
                } else {
                    playNav();
                    menu.currentIndex = ObjectModel.index;
                }
        }

        Button {
        id: buttonManual

            // Only when this game has a manual. Hidden, a negative width
            // cancels the row spacing so no gap is left behind; the menu's
            // left/right handlers skip it.
            visible: manualPath !== ""
            width: visible ? height : -menu.spacing
            icon: "../assets/images/icon_manual.svg"
            iconPadding: vpx(22)
            height: parent.height
            selected: ListView.isCurrentItem && menu.activeFocus
            onHighlighted: { menu.currentIndex = ObjectModel.index; content.currentIndex = 0; }
            onActivated:
                if (selected) {
                    showManual();
                } else {
                    playNav();
                    menu.currentIndex = ObjectModel.index;
                }
        }

        Button {
        id: button5

            // Only when this game has achievements (see raGameId); hidden
            // the same way as the Manual button.
            visible: raGameId > 0
            width: visible ? height : -menu.spacing
            icon: "../assets/images/trophy.svg"
            iconPadding: vpx(22)
            height: parent.height
            selected: ListView.isCurrentItem && menu.activeFocus
            onHighlighted: { menu.currentIndex = ObjectModel.index; content.currentIndex = 0; }
            onActivated:
                if (selected) {
                    playAccept();
                    raEntryScreen();
                } else {
                    playNav();
                    menu.currentIndex = ObjectModel.index;
                }
        }

        Button { 
        id: button3 

            property string buttonText: game && game.favorite ? "Unfavorite" : "Add favorite"
            //text: buttonText
            icon: favIcon
            iconPadding: vpx(22)
            height: parent.height
            selected: ListView.isCurrentItem && menu.activeFocus
            onHighlighted: { menu.currentIndex = ObjectModel.index; content.currentIndex = 0; }
            onActivated: 
                if (selected) {
                    playToggle();
                    game.favorite = !game.favorite;
                } else {
                    playNav();
                    menu.currentIndex = ObjectModel.index;
                }
        }
        
        Button { 
        id: button4

            //text: "Back"
            icon: "../assets/images/icon_back.svg"
            height: parent.height
            selected: ListView.isCurrentItem && menu.activeFocus
            onHighlighted: { menu.currentIndex = ObjectModel.index; content.currentIndex = 0; }
            onActivated: 
                if (selected) 
                    previousScreen();
                else {
                    playNav(); 
                    menu.currentIndex = ObjectModel.index;
                }
        }
    }

    // Full list
    ObjectModel {
    id: extrasModel

        // Game menu
        ListView {
        id: menu

            property bool selected: parent.focus
            focus: selected
            width: parent.width
            height: vpx(50)
            model: menuModel
            orientation: ListView.Horizontal
            spacing: vpx(10)
            keyNavigationWraps: true
            // Hidden buttons (Manual, Achievements) are skipped; a loop, since
            // both can be hidden side by side.
            Keys.onLeftPressed: {
                playNav(); decrementCurrentIndex();
                for (var i = 0; i < count && currentItem && !currentItem.visible; i++) decrementCurrentIndex();
            }
            Keys.onRightPressed: {
                playNav(); incrementCurrentIndex();
                for (var j = 0; j < count && currentItem && !currentItem.visible; j++) incrementCurrentIndex();
            }
        }

        HorizontalCollection {
        id: media
            ownScreen: "gameviewscreen"

            width: root.width - vpx(70) - globalMargin
            height: ((root.width - globalMargin * 2) / 6.0) + vpx(60)
            title: "Media"
            model: mediaList
            delegate: MediaItem {
            id: mediadelegate

                width: (root.width - globalMargin * 2) / 6.0
                height: width
                selected: ListView.isCurrentItem && media.ListView.isCurrentItem
                mediaItem: modelData
                systemShortName: collectionShortName   // Disc / UMD / Game Card label

                onHighlighted: {
                    playNav(); 
                    media.currentIndex = index;
                    content.currentIndex = media.ObjectModel.index;
                }

                onActivated: {
                if (selected)
                    showMedia(index);
                else
                {
                    playNav(); 
                    media.currentIndex = index;
                    content.currentIndex = media.ObjectModel.index;
                }
            }
            }
            
        }

        // --- BEGIN: More by Publisher/Developer (More section only) ---
        // Falls back to "More Recommended Games" when no publisher/developer results exist.
        HorizontalCollection {
        id: list1
            ownScreen: "gameviewscreen"
            // "More like this" rows have their own preview settings
            // (Settings > Previews & sound); they used to follow Home's.
            previewOn:       gatePreview(liveSetting("Details rows video preview")) === "Yes"
            previewSound:    gateSound(liveSetting("Details rows video audio")) === "Yes"
            hideLogoOnVideo: liveSetting("Details rows hide logo on video") === "Yes"

            property bool selected: ListView.isCurrentItem
            focus: selected
            width: root.width - vpx(70) - globalMargin
            height: itemHeight + vpx(60)
            itemWidth: (root.width - globalMargin * 2) / 3.0
            itemHeight: itemWidth * 0.68

            // Show recommended games when there are no publisher/developer results
            title: {
                if (!game) return "";
                if (publisherCollection.games.length === 0)
                    return "Picked For You";
                var pub = game.publisher || "";
                var dev = game.developer || "";
                var g = game.genreList.length > 0 ? game.genreList[0] : "";
                var sepM = g.match(/^(.*?)\s*[\/,]\s*(.+)$/);
                var lower = (sepM ? sepM[1] : g).trim().toLowerCase();
                var prefix = (lower === "application" || lower === "emulator") ? "More by " : "More games by ";
                if (pub && dev && pub.toLowerCase() !== dev.toLowerCase())
                    return prefix + pub + " / " + dev;
                return prefix + (pub || dev);
            }
            // Switch to the recommended fallback when publisher/developer list is empty
            search: publisherCollection.games.length > 0 ? publisherCollection : recommendedCollection
            onActivate: {
                // Replace the current game without pushing a new gameviewscreen onto lastState
                currentGame = search.currentGame(activeIndex);
            }
            onListHighlighted: { playNav(); content.currentIndex = list1.ObjectModel.index; }
        }
        // --- END: More by Publisher/Developer (More section only) ---

        // --- BEGIN: More by Genre (Option B: genre token controlled by setting) ---
        HorizontalCollection {
        id: list2
            ownScreen: "gameviewscreen"
            // "More like this" rows have their own preview settings
            // (Settings > Previews & sound); they used to follow Home's.
            previewOn:       gatePreview(liveSetting("Details rows video preview")) === "Yes"
            previewSound:    gateSound(liveSetting("Details rows video audio")) === "Yes"
            hideLogoOnVideo: liveSetting("Details rows hide logo on video") === "Yes"

            property bool selected: ListView.isCurrentItem
            focus: selected
            width: root.width - vpx(70) - globalMargin
            height: itemHeight + vpx(60)
            itemWidth: (root.width - globalMargin * 2) / 5.0
            itemHeight: itemWidth / 0.66

            title: {
                if (!game || game.genreList.length === 0) return "              ";
                var g  = game.genreList[0];
                var sepM = g.match(/^(.*?)\s*[\/,]\s*(.+)$/);
                var mainGenre = sepM ? sepM[1].trim() : g;
                var lower = mainGenre.toLowerCase();
                // Special labels are always based on the main genre.
                if (lower === "application") return "More Applications";
                if (lower === "emulator") return "More Emulators";
                var modeStr = settings.MoreByGenreDisplay || "Main Genre";
                if (modeStr === "Sub Genre") {
                    var displayGenre = sepM ? sepM[2].trim() : mainGenre;
                    return "More " + displayGenre + " Games";
                }
                if (modeStr === "Full") return "More " + g + " Games";
                return "More " + mainGenre + " Games";
            }
            search: genreCollection
            onActivate: {
                // Replace the current game without pushing a new gameviewscreen onto lastState
                currentGame = search.currentGame(activeIndex);
            }
            onListHighlighted: { playNav(); content.currentIndex = list2.ObjectModel.index; }
        }
        // --- END: More by Genre (Option B: genre token controlled by setting) ---
        
    }

    // Depth under the header band (Platform page has the same): a few
    // pixels of soft darkening so the band sits ON the content. Only with
    // the band up, and only when dimming is on, as on the Platform page.
    Rectangle {
        anchors { top: header.bottom; left: parent.left; right: parent.right }
        height: vpx(14)
        z: 9
        opacity: ((scrolledPast && gridDimOpacity > 0) ? 1 : 0) * viewerGate
        Behavior on opacity { NumberAnimation { duration: chromeFadeMs; easing.type: chromeEasing } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.35) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
        }
    }

    // The last row dissolves under the help bar, as on the Platform page.
    // Only once scrolled: at the top the Media row is meant to peek in.
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: helpMargin + vpx(120)
        z: 6
        opacity: (scrolledPast ? 1 : 0) * viewerGate * gridFadeOpacity   // z:6 would otherwise paint over the viewer; scaled by Background dimming
        Behavior on opacity { NumberAnimation { duration: chromeFadeMs; easing.type: chromeEasing } }
        gradient: Gradient {
            GradientStop { position: 0.0;  color: mainA(0.0)  }
            GradientStop { position: 0.25; color: mainA(0.12) }
            GradientStop { position: 0.5;  color: mainA(0.45) }
            GradientStop { position: 0.75; color: mainA(0.85) }
            GradientStop { position: 1.0;  color: theme.main }
        }
    }

    ListView {
    id: content

        anchors {
            left: parent.left; leftMargin: vpx(70)
            right: parent.right
            top: parent.top; topMargin: header.height
            bottom: parent.bottom; bottomMargin: vpx(150)
        }
        model: extrasModel
        focus: true
        spacing: vpx(30)
        header: Item { height: vpx(450) }
        
        snapMode: ListView.SnapToItem
        highlightMoveDuration: 100
        displayMarginEnd: 150
        // ObjectModel always instantiates all items regardless of cacheBuffer,
        // so no cacheBuffer is needed here.
        onCurrentIndexChanged: { 
            if (content.currentIndex === 0) {
                toggleVideo(true); 
            } else {
                toggleVideo(false);
            }
        }
        keyNavigationWraps: true
        Keys.onUpPressed: {
            if (currentIndex > 0) { playNav(); decrementCurrentIndex(); }
            else { gv_homebutton.focus = true; }
        }
        Keys.onDownPressed: { playNav(); incrementCurrentIndex() }
    }

    // Touch/click blocker — while the fullscreen media viewer is open, absorb
    // pointer input so taps that miss its controls can't fall through to the
    // menu/buttons behind it. Sits just below mediaScreen in stacking order
    // (declared right before it) and is only active while media is showing.
    MouseArea {
        id: mediaInputBlocker
        anchors.fill: parent
        enabled: mediaScreen.visible || manualScreen.visible
        visible: enabled
        acceptedButtons: Qt.AllButtons
        preventStealing: true
        hoverEnabled: true
        onPressed: mouse.accepted = true
        onWheel: wheel.accepted = true   // the wheel stops here too, not on the screen behind
        onClicked: mouse.accepted = true
        onReleased: mouse.accepted = true
    }

    MediaView {
    id: mediaScreen
        
        anchors.fill: parent
        Behavior on opacity { NumberAnimation { duration: 100 } }
        visible: opacity != 0
        // The drawer can't open over fullscreen media (MediaView swallows the
        // key), so don't advertise it. Restored when the overlay closes.
        onVisibleChanged: hideAppsPrompt = visible

        mediaModel: mediaList;
        mediaIndex: media.currentIndex != -1 ? media.currentIndex : 0
        onClose: closeMedia();
    }

    ManualView {
    id: manualScreen

        anchors.fill: parent
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
        visible: opacity != 0
        // Same as the media viewer: the drawer can't open over it
        onVisibleChanged: hideAppsPrompt = visible
        onClose: closeManual();
    }

    // Input handling
    // Mouse back button: mirrors B in the same order — fullscreen media
    // closes first, then a focused header button returns to the content,
    // then the screen itself.
    // Clickable prompts (theme.qml helpClick). Buttons, media and tiles take
    // A themselves; this is the page's own keys. B is left to mouseBack().
    function helpAction(button) {
        if (button === "details") { if (game) { playAccept(); game.favorite = !game.favorite; } return true; }
        if (button === "filters") { settingsScreen(); return true; }
        if (button === "accept") {
            if (gv_homebutton.activeFocus)          showcaseScreen();
            else if (gv_discoverbutton.activeFocus) discoverScreen();
            else if (gv_settingsbutton.activeFocus) settingsScreen();
            return true;
        }
        return false;
    }

    function mouseBack() {
        if (mediaScreen.visible)  { closeMedia(); return; }
        if (manualScreen.visible) { closeManual(); return; }
        if (!content.activeFocus) { content.focus = true; return; }
        previousScreen();
    }

    Keys.onPressed: {
        // Back
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (mediaScreen.visible)
                closeMedia();
            else if (manualScreen.visible)
                closeManual();
            else
                previousScreen();
        }
        // Toggle Favorite
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            playAccept();
            game.favorite = !game.favorite;
        }
        // Settings
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            settingsScreen();
        }
        // LB / RB — jump straight up to the nav bar from the content area
        if ((api.keys.isPrevPage(event) || api.keys.isNextPage(event)) && !event.isAutoRepeat) {
            event.accepted = true;
            if (content.activeFocus && !mediaScreen.visible) { gv_homebutton.focus = true; }
        }
    }

    // Helpbar buttons
    ListModel {
        id: gameviewHelpModel

        ListElement {
            name: "Back"
            button: "cancel"
        }
        ListElement {
            name: "Settings"
            button: "filters"
        }
        ListElement {
            name: "Toggle Favorite"
            button: "details"
        }
        ListElement {
            name: "Select"
            button: "accept"
        }
    }
    
    onActiveFocusChanged: {
        if (activeFocus) {
            currentHelpbarModel = gameviewHelpModel;
            content.currentIndex = 0;
            content.focus = true;
            menu.currentIndex = 0;
        } else {
            screenshot.opacity = 1;
            toggleVideo(false);
        }
    }

    // Status cluster (clock / battery / wifi) — same component and
    // ShowClock/ShowBattery/ShowWifi settings as the home page.
    // Hidden while the fullscreen media viewer is open.
    StatusCluster {
        anchors.fill: parent
        z: 50
        visible: mediaScreen.opacity < 0.5 && manualScreen.opacity < 0.5
        dark: whiteBackground
    }

}
