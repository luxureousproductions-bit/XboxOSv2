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
import QtMultimedia 5.15
import "RetroAchievements"
import "VerticalList"
import "GridView"
import "Global"
import "GameDetails"
import "ShowcaseView"
import "Settings"
import "utils.js" as Utils

FocusScope {
id: root

    FontLoader { id: titleFont; source:      "assets/fonts/SegoeProDisplay-Bold.ttf" }
    FontLoader { id: subtitleFont; source:   "assets/fonts/SegoeProDisplay-Bold.ttf" }
    FontLoader { id: bodyFont; source:       "assets/fonts/SegoeProDisplay-Semibold.ttf" }

    // ── RetroAchievements data layer ─────────────────────────────────────
    CheevosData {
    id: cheevosData
    }

    // Load settings
    // Bumped by SettingsScreen after any save. Bindings that reference it become
    // live; everything else keeps reading the `settings` snapshot below.
    //
    // `settings` itself can never re-evaluate: api.memory.has/get are method
    // CALLS, so QML records no dependency on them. That is why most settings
    // are marked "Reload Required". Opting one binding in at a time is far
    // safer than making the whole object reactive, which would invalidate all
    // 224 settings.* bindings at once — including several that walk the full
    // game list.
    property int settingsEpoch: 0

    // Live copy of the featured box mode. Read by ShowcaseViewMenu's carousel
    // and by FavoritesHeader, so switching it applies without a reload.
    readonly property string featuredBoxContent: {
        var e = settingsEpoch;
        return api.memory.has("Featured Box Content")
             ? api.memory.get("Featured Box Content") : "Favorites";
    }

    // Titles of emulators among the imported apps.
    //
    // The genre rule can never catch these: Pegasus imports carry NO genre at
    // all, so an emulator like Citra or DraStic has nothing to match on. This
    // is the emulator equivalent of appTitleSet, identified by package name
    // using the same keywords the App Drawer categorises with.
    readonly property var emulatorKeywords: [
        "citra", "dolphin", "drastic", "duckstation", "aethersx2", "ppsspp", "retroarch",
        "vita3k", "yuzu", "ryujinx", "eden", "sudachi", "redream", "mupen", "melonds",
        "flycast", "pcsx", "epsxe", "mame", "xemu", "winlator", "lime3ds", "azahar",
        "panda3ds", "skyline", "nethersx2", "snes9x", "mgba", "fpse", "dsemu", "mm.jr",
        "emu", "emulator", "gamenative"
    ]
    readonly property var emulatorTitleSet: {
        var set = {};
        if (!omitEmulatorLive) return set;      // nothing reads it when off
        var cols = drawerCollections;
        for (var i = 0; i < cols.length; i++) {
            var gl = cols[i].games;
            for (var j = 0; j < gl.count; j++) {
                var g = gl.get(j);
                if (!g.files || g.files.count < 1) continue;
                var path = (g.files.get(0).path || "").toLowerCase();
                var title = (g.title || "");
                var t = title.toLowerCase();
                for (var k = 0; k < emulatorKeywords.length; k++) {
                    var kw = emulatorKeywords[k];
                    if (path.indexOf(kw) >= 0 || t.indexOf(kw) >= 0) { set[title] = true; break; }
                }
            }
        }
        return set;
    }

    // One pass over the library, replacing the per-row genre work.
    //
    // Each Showcase row used to walk every game itself, lowercasing each genre
    // string to compare it — 7 rows x 4300 games on every change, twice over.
    // The answer is the same for every row, so it's computed once here and the
    // rows do a single hash lookup each.
    readonly property var omitTitleSet: {
        var set = {};
        var oApp = (settings.OmitApplicationFromShowcase === "Yes");
        var oEmu = omitEmulatorLive;
        if (!oApp && !oEmu) return set;         // nothing to do

        // Imported apps and emulators, by collection/package.
        if (oApp) { var a = appTitleSet;      for (var k in a) set[k] = true; }
        if (oEmu) { var e = emulatorTitleSet; for (var k2 in e) set[k2] = true; }

        // Genre-tagged entries. Lowercased once per game, not once per row.
        var all = api.allGames;
        for (var i = 0; i < all.count; i++) {
            var g = all.get(i);
            var t = g.title;
            if (!t || set[t] === true) continue;
            var gl = g.genreList;
            for (var j = 0; j < gl.length; j++) {
                var gg = (gl[j] || "").toLowerCase();
                if (oApp && gg === "application") { set[t] = true; break; }
                if (oEmu && gg === "emulator")    { set[t] = true; break; }
            }
        }
        return set;
    }

    // Live copy of the Emulator omit setting. Read by the Showcase rows, so
    // toggling it applies without a reload.
    readonly property bool omitEmulatorLive: {
        var e = settingsEpoch;
        return (api.memory.has("Omit genre: Emulator from Showcase")
              ? api.memory.get("Omit genre: Emulator from Showcase") : "No") === "Yes";
    }

    property var settings: {
        return {
            PlatformView:                  api.memory.has("Game View") ? api.memory.get("Game View") : "Grid",
            GridThumbnail:                 api.memory.has("Grid Thumbnail") ? api.memory.get("Grid Thumbnail") : "Dynamic Wide",
            GridArt:                       api.memory.has("Grid art") ? api.memory.get("Grid art") : "Fanart",
            GridGameLogo:                  api.memory.has("Grid Game Logo") ? api.memory.get("Grid Game Logo") : "Yes",
            GridColumns:                   api.memory.has("Number of columns") ? api.memory.get("Number of columns") : "3",
            GameBackground:                api.memory.has("Game Background") ? api.memory.get("Game Background") : "Screenshot",
            GameLogo:                      api.memory.has("Game Logo") ? api.memory.get("Game Logo") : "Show",
            GameRandomBackground:          api.memory.has("Randomize Background") ? api.memory.get("Randomize Background") : "No",
            GameBlurBackground:            api.memory.has("Blur Background") ? api.memory.get("Blur Background") : "No",
            VideoPreview:                  api.memory.has("Video preview") ? api.memory.get("Video preview") : "Yes",
            AllowThumbVideo:               api.memory.has("Allow video thumbnails") ? api.memory.get("Allow video thumbnails") : "Yes",
            AllowThumbVideoAudio:          api.memory.has("Video thumbnail audio") ? api.memory.get("Video thumbnail audio") : "No",
            HideLogo:                      api.memory.has("Hide logo when thumbnail video plays") ? api.memory.get("Hide logo when thumbnail video plays") : "No",
            HideButtonHelp:                api.memory.has("Hide button help") ? api.memory.get("Hide button help") : "No",
            ColorLayout:                   api.memory.has("Color Layout") ? api.memory.get("Color Layout") : "Dark Green",
            MouseHover:                    api.memory.has("Enable mouse hover") ? api.memory.get("Enable mouse hover") : "No",
            AlwaysShowTitles:              api.memory.has("Always show titles") ? api.memory.get("Always show titles") : "No",
            AnimateHighlight:              api.memory.has("Animate highlight") ? api.memory.get("Animate highlight") : "No",
            AllowVideoPreviewAudio:        api.memory.has("Game details video preview audio") ? api.memory.get("Game details video preview audio") : "No",
            ShowScanlines:                 api.memory.has("Show scanlines") ? api.memory.get("Show scanlines") : "Yes",
            DetailsDefault:                api.memory.has("Default to full details") ? api.memory.get("Default to full details") : "No",
            LaunchScreenDelay:             api.memory.has("Launch screen delay") ? api.memory.get("Launch screen delay") : "0.6",
            FeaturedBox:                   api.memory.has("Featured Box") ? api.memory.get("Featured Box") : "Yes",
            FeaturedBoxCollection:         api.memory.has("Pins to collection") ? api.memory.get("Pins to collection") : "1",
            UiScale:                       api.memory.has("UI Scale") ? api.memory.get("UI Scale") : "1.0",
            FavoritedTileAccent:           api.memory.has("Favorited Tile Accent") ? api.memory.get("Favorited Tile Accent") : "Yes",
            FeaturedBoxContent:            api.memory.has("Featured Box Content") ? api.memory.get("Featured Box Content") : "Favorites",
            ShowcaseBackgroundArt:          api.memory.has("Showcase Background Art") ? api.memory.get("Showcase Background Art") : "Yes",
            RandomizeSystemTileFanart:      api.memory.has("Randomize System Tile Fanart") ? api.memory.get("Randomize System Tile Fanart") : "No",
            CustomBackground:               api.memory.has("Custom Background") ? api.memory.get("Custom Background") : "No",
            ShowcaseBackgroundOpacity:     api.memory.has("Showcase Background Opacity") ? api.memory.get("Showcase Background Opacity") : "0.55",
            ShowcaseArt:                   api.memory.has("Showcase Collections Art") ? api.memory.get("Showcase Collections Art") : "Fanart",
            HeroBoxArt:                    api.memory.has("Hero box art") ? api.memory.get("Hero box art") : "Fanart",
            TileHalo:                      api.memory.has("Tile Halo") ? api.memory.get("Tile Halo") : "Yes",
            SystemSort:                    api.memory.has("System sort") ? api.memory.get("System sort") : "Alphabetical (A-Z)",
            ShowcaseColumns:               api.memory.has("Number of games showcased") ? api.memory.get("Number of games showcased") : "15",
            ShowcaseFeaturedCollection:    api.memory.has("Featured collection") ? api.memory.get("Featured collection") : "Favorites",
            ShowcaseCollection1:           api.memory.has("Collection 1") ? api.memory.get("Collection 1") : "Recently Played",
            ShowcaseCollection1_Thumbnail: api.memory.has("Collection 1 - Thumbnail") ? api.memory.get("Collection 1 - Thumbnail") : "Wide",
            ShowcaseCollection1_Size:      api.memory.has("Collection 1 - Size") ? api.memory.get("Collection 1 - Size") : "Small",
            ShowcaseCollection1_Ratio:     api.memory.has("Collection 1 - Ratio") ? api.memory.get("Collection 1 - Ratio") : "0.66",
            ShowcaseCollection2:           api.memory.has("Collection 2") ? api.memory.get("Collection 2") : "Most Played",
            ShowcaseCollection2_Thumbnail: api.memory.has("Collection 2 - Thumbnail") ? api.memory.get("Collection 2 - Thumbnail") : "Tall",
            ShowcaseCollection2_Size:      api.memory.has("Collection 2 - Size") ? api.memory.get("Collection 2 - Size") : "Small",
            ShowcaseCollection2_Ratio:     api.memory.has("Collection 2 - Ratio") ? api.memory.get("Collection 2 - Ratio") : "0.66",
            ShowcaseCollection3:           api.memory.has("Collection 3") ? api.memory.get("Collection 3") : "Top by Publisher",
            ShowcaseCollection3_Thumbnail: api.memory.has("Collection 3 - Thumbnail") ? api.memory.get("Collection 3 - Thumbnail") : "Wide",
            ShowcaseCollection3_Size:      api.memory.has("Collection 3 - Size") ? api.memory.get("Collection 3 - Size") : "Small",
            ShowcaseCollection3_Ratio:     api.memory.has("Collection 3 - Ratio") ? api.memory.get("Collection 3 - Ratio") : "0.66",
            ShowcaseCollection4:           api.memory.has("Collection 4") ? api.memory.get("Collection 4") : "Top by Genre",
            ShowcaseCollection4_Thumbnail: api.memory.has("Collection 4 - Thumbnail") ? api.memory.get("Collection 4 - Thumbnail") : "Tall",
            ShowcaseCollection4_Size:      api.memory.has("Collection 4 - Size") ? api.memory.get("Collection 4 - Size") : "Small",
            ShowcaseCollection4_Ratio:     api.memory.has("Collection 4 - Ratio") ? api.memory.get("Collection 4 - Ratio") : "0.66",
            ShowcaseCollection5:           api.memory.has("Collection 5") ? api.memory.get("Collection 5") : "None",
            ShowcaseCollection5_Thumbnail: api.memory.has("Collection 5 - Thumbnail") ? api.memory.get("Collection 5 - Thumbnail") : "Wide",
            ShowcaseCollection5_Size:      api.memory.has("Collection 5 - Size") ? api.memory.get("Collection 5 - Size") : "Small",
            ShowcaseCollection5_Ratio:     api.memory.has("Collection 5 - Ratio") ? api.memory.get("Collection 5 - Ratio") : "0.66",
            ShowcaseCollection6:           api.memory.has("Collection 6") ? api.memory.get("Collection 6") : "None",
            ShowcaseCollection6_Thumbnail: api.memory.has("Collection 6 - Thumbnail") ? api.memory.get("Collection 6 - Thumbnail") : "Wide",
            ShowcaseCollection6_Size:      api.memory.has("Collection 6 - Size") ? api.memory.get("Collection 6 - Size") : "Small",
            ShowcaseCollection6_Ratio:     api.memory.has("Collection 6 - Ratio") ? api.memory.get("Collection 6 - Ratio") : "0.66",
            GridRatio:                     api.memory.has("Grid Ratio") ? api.memory.get("Grid Ratio") : "0.66",
            ColorBackground:               api.memory.has("Color Background") ? api.memory.get("Color Background") : "Black",
            XboxLogo:                      api.memory.has("Xbox Logo") ? api.memory.get("Xbox Logo") : "Logo1",
            LogoColorMatch:                api.memory.has("Logo Color Match") ? api.memory.get("Logo Color Match") : "No",
            BoxArtStyle:                   api.memory.has("Box Art") ? api.memory.get("Box Art") : "2D",
            GameCounter:                   api.memory.has("Game Counter") ? api.memory.get("Game Counter") : "Yes",
            CarouselVideo:                 api.memory.has("Video") ? api.memory.get("Video") : "Yes",
            CarouselScreenshots:           api.memory.has("Screenshots") ? api.memory.get("Screenshots") : "Yes",
            CarouselTitleScreen:           api.memory.has("Title Screen") ? api.memory.get("Title Screen") : "Yes",
            CarouselFanart:                api.memory.has("Fanart") ? api.memory.get("Fanart") : "Yes",
            Carousel3DBox:                 api.memory.has("3D Box") ? api.memory.get("3D Box") : "Yes",
            Carousel2DBox:                 api.memory.has("2D Box") ? api.memory.get("2D Box") : "Yes",
            CarouselBackBox:               api.memory.has("Back Box") ? api.memory.get("Back Box") : "Yes",
            CarouselCartridge:             api.memory.has("Cartridge") ? api.memory.get("Cartridge") : "Yes",
            CarouselMiximage:              api.memory.has("Miximage") ? api.memory.get("Miximage") : "Yes",
            CarouselWheel:                 api.memory.has("Logo") ? api.memory.get("Logo") : "Yes",
            OmitApplicationFromShowcase:   api.memory.has("Omit genre: Application from Showcase") ? api.memory.get("Omit genre: Application from Showcase") : "No",
            OmitEmulatorFromShowcase:      api.memory.has("Omit genre: Emulator from Showcase") ? api.memory.get("Omit genre: Emulator from Showcase") : "No",
            HideAndroidSystemTile:         api.memory.has("Hide Android System Tile") ? api.memory.get("Hide Android System Tile") : "Yes",
            MoreByGenreDisplay:            api.memory.has("More by Genre Display") ? api.memory.get("More by Genre Display") : "Full",
            AllowDiscoverVideoAudio:         api.memory.has("Discover video audio") ? api.memory.get("Discover video audio") : "No",
            MenuSounds:                      api.memory.has("Menu sounds") ? api.memory.get("Menu sounds") : "Yes",
            MenuVolume:                      api.memory.has("Menu Volume") ? api.memory.get("Menu Volume") : "1.0",
            StartupChime:                    api.memory.has("Start up chime") ? api.memory.get("Start up chime") : "Yes",
            AllGamesVideoPreview:            api.memory.has("AllGames Video preview") ? api.memory.get("AllGames Video preview") : "Yes",
            AllGamesHideBoxOnVideo:          api.memory.has("AllGames Hide box art on video") ? api.memory.get("AllGames Hide box art on video") : "No",
            AllGamesHideLogoOnVideo:         api.memory.has("AllGames Hide logo on video") ? api.memory.get("AllGames Hide logo on video") : "No",
            AllGamesBlurBackground:          api.memory.has("AllGames Blur Background") ? api.memory.get("AllGames Blur Background") : "No",
            AllGamesScanlines:               api.memory.has("AllGames Show scanlines") ? api.memory.get("AllGames Show scanlines") : "No",
            AllGamesVideoAudio:              api.memory.has("All games menu video audio") ? api.memory.get("All games menu video audio") : "No",
            ShowWifi:                      api.memory.has("Show WiFi Indicator")     ? api.memory.get("Show WiFi Indicator")     : "Yes",
            ShowBattery:                   api.memory.has("Show Battery Percentage") ? api.memory.get("Show Battery Percentage") : "Battery Only",
            ShowClock:                     api.memory.has("Show Clock")              ? api.memory.get("Show Clock")              : "12hr"
        }
    }


    // Collections
    property int currentCollectionIndex: 0
    property bool collectionVisited: false   // strip stays on the hero until a collection is actually opened
    property int currentGameIndex: 0

    // Mirrors `state` under a name child components can reference. `state` is
    // shadowed by every Item's own state property, so a child asking for it
    // gets its own, not the theme's. Video players use this to stop when their
    // screen isn't current — the screen Loaders stay resident once visited, so
    // without this a preview keeps playing (and its audio with it) under
    // whatever screen you move to.
    readonly property string activeScreen: state

    // False while Pegasus is in the background (another app in front, screen
    // off). Video players gate on this too — otherwise a preview kept playing,
    // audio and all, after switching away from Pegasus entirely.
    readonly property bool appActive: Qt.application.state === Qt.ApplicationActive

    // Set by a screen that hides its whole UI (Discover's X toggle), so the
    // bottom-left Apps prompt goes with it. Deliberately explicit rather than
    // inferred from currentHelpbarModel being null: the RA screens null that
    // too because they draw their own local help bars, and inferring hid the
    // prompt there as well.
    property bool hideAppsPrompt: false
    property var currentCollection: api.collections.get(currentCollectionIndex)

    // The app drawer replaces Pegasus's own installed-apps tile, so that
    // collection is kept out of the system row everywhere.
    //
    // Matched on NAME, not shortName: the provider's collection and a
    // hand-written "Android Apps" collection both report shortName "android",
    // so shortName can't tell them apart. Hand-made app collections are left
    // alone on purpose — only the provider's own tile is replaced.
    readonly property string appsCollectionName: "Android"
    function isDrawerCollection(c) {
        return !!c && (c.name || "").toLowerCase() === appsCollectionName.toLowerCase();
    }

    // Titles of everything in the drawer's collection, used to keep installed
    // apps out of the Showcase rows when "Omit genre: Application" is on.
    //
    // Keyed by TITLE rather than collection because the Showcase rows filter
    // through SortFilterProxyModel, and an ExpressionFilter there only sees
    // model *roles* — a game's collections aren't reachable from inside one.
    //
    // Needed at all because the existing filter tests genre, and the provider's
    // apps get genres from Play Store lookups that frequently fail outright, so
    // most of them carry no genre for that test to match on.
    readonly property var appTitleSet: {
        var set = {};
        var n = api.collections.count;          // referenced so this re-runs if collections reload
        for (var i = 0; i < n; i++) {
            var c = api.collections.get(i);
            if (!isDrawerCollection(c)) continue;
            var gl = c.games;
            for (var j = 0; j < gl.count; j++) {
                var t = gl.get(j).title;
                if (t) set[t] = true;
            }
        }
        return set;
    }

    // Shared system order (home/platform page + grid LB/RB cycle), per the
    // "System sort" setting. Collections are read THROUGH this index array so
    // every screen orders systems identically without altering Pegasus's order.
    property var sortedColl: buildSortedColl()
    function buildSortedColl() {
        var n = api.collections.count;
        var items = [];
        for (var i = 0; i < n; i++) {
            var c = api.collections.get(i);
            // The drawer covers this collection, so its tile is redundant by
            // default — but only skip it while the setting says so.
            if (settings.HideAndroidSystemTile !== "No" && isDrawerCollection(c)) continue;
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
            // Pinned systems (Android, then Android games) always lead.
            if (a.pin !== b.pin) {
                if (a.pin === -1) return 1;
                if (b.pin === -1) return -1;
                return a.pin - b.pin;
            }
            if (a.pin !== -1) return 0;

            var alpha = (a.name < b.name) ? -1 : (a.name > b.name ? 1 : 0);

            if (mode === "Alphabetical (Z-A)")
                return -alpha;
            if (mode === "Release year (oldest)" || mode === "Release year") {
                if (a.year !== b.year) {
                    if (a.year === 9999) return 1;
                    if (b.year === 9999) return -1;
                    return a.year - b.year;
                }
                return alpha;
            }
            if (mode === "Release year (newest)") {
                if (a.year !== b.year) {
                    if (a.year === 9999) return 1;
                    if (b.year === 9999) return -1;
                    return b.year - a.year;
                }
                return alpha;
            }
            if (mode === "Manufacturer") {
                if (a.maker !== b.maker) return a.maker < b.maker ? -1 : 1;
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
                return a.idx - b.idx;
            }
            return alpha;
        });
        var arr = [];
        for (var k = 0; k < items.length; k++) arr.push(items[k].idx);
        return arr;
    }
    function systemPinRank(sn, nm) {
        var s = (sn || "").toLowerCase();
        var nmm = (nm || "").toLowerCase();
        if (s === "android" || nmm === "android") return 0;
        if (s === "apps" || s === "androidgames" || nmm === "apps" || nmm === "android games" || nmm === "androidgames") return 1;
        return -1;
    }
    property var currentGame
    property var launchingGame: null         // game shown on the launch splash
    property bool launchSuspended: false     // true once the app has backgrounded for a launch
    property int  launchSplashDelay: {       // ms the splash is held before launch, from the "Launch screen delay" setting (seconds)
        var v = parseFloat(settings.LaunchScreenDelay);
        return isNaN(v) ? 600 : Math.round(v * 1000);
    }

    // Stored variables for page navigation
    property int storedHomePrimaryIndex: 0
    property int storedHomeSecondaryIndex: 0
    property int storedCollectionIndex: 0
    property int storedCollectionGameIndex: 0
    property int storedAllGamesIndex: 0
    // Keeps GameView alive after first visit so returning from Settings never shows a blank page.
    // Set to true by gameviewloader.onLoaded; never reset, so the component is only created once.
    property bool gameviewLoaded: false

    // Reset the stored game index when changing collections
    onCurrentCollectionIndexChanged: storedCollectionGameIndex = 0

    // Filtering options
    property bool showFavs: false
    property var sortByFilter: ["title", "lastPlayed", "playCount", "rating"]
    property int sortByIndex: 0
    property var orderBy: Qt.AscendingOrder
    property string searchTerm: ""
    property string searchMode: "Title"
    property var    genreSelected: []   // grid genre filter (multi-select; [] = All)
    // Turn a selected genre into a regex matching it as a whole comma-token
    function genreToPattern(g) {
        if (g === "" || g === "All") return "";
        var esc = g.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
        return "(^|,\\s*)" + esc + "(\\s*,|$)";
    }
    // Multi-genre: regex matching ANY selected genre as a whole comma-token
    function genresToPattern(arr) {
        if (!arr || arr.length === 0) return "";
        var parts = [];
        for (var i = 0; i < arr.length; i++)
            parts.push(arr[i].replace(/[.*+?^${}()|[\]\\]/g, "\\$&"));
        return "(^|,\\s*)(" + parts.join("|") + ")(\\s*,|$)";
    }
    property bool steam: currentCollection.name === "Steam"
    function steamExists() {
        for (i = 0; i < api.collections.count; i++) {
            if (api.collections.get(i).name === "Steam") {
                return true;
            }
            return false;
        }
    }

    // Functions for switching currently active collection
    function toggleFavs() {
        showFavs = !showFavs;
    }

    function cycleSort() {
        if (sortByIndex < sortByFilter.length - 1)
            sortByIndex++;
        else
            sortByIndex = 0;
    }

    function toggleOrderBy() {
        if (orderBy === Qt.AscendingOrder)
            orderBy = Qt.DescendingOrder;
        else
            orderBy = Qt.AscendingOrder;
    }

    // Launch the current game
    // ── Robust SFX helpers ────────────────────────────────────────────────
    // stop() before play() forces a clean restart on every call, so rapid
    // retriggers (scrolling, cycling, etc.) never drop a play() the way Qt's
    // SoundEffect otherwise does when one is already in-flight.
    function playNav()    { if (sfxVolume <= 0) return; sfxNav.stop();    sfxNav.play(); }
    function playAccept() { if (sfxVolume <= 0) return; sfxAccept.stop(); sfxAccept.play(); }
    function playBack()   { if (sfxVolume <= 0) return; sfxBack.stop();   sfxBack.play(); }
    function playToggle() { if (sfxVolume <= 0) return; sfxToggle.stop(); sfxToggle.play(); }
    function playTabLeft()  { if (sfxVolume <= 0) return; sfxTabLeft.stop();  sfxTabLeft.play(); }
    function playTabRight() { if (sfxVolume <= 0) return; sfxTabRight.stop(); sfxTabRight.play(); }

    function launchGame(game) {
        launchingGame = (game !== null) ? game : currentGame;
        launchGameScreen();
        saveCurrentState(launchingGame);
        launchDelay.restart();          // hold the splash, then launch (see launchDelay)
    }

    // Launch from the RetroAchievements pages. Identical to launchGame() except
    // the return target is rewritten to the Showcase: coming back into a
    // stale achievements page (possibly for a game reached via search) isn't
    // useful. lastState must be replaced BEFORE saveCurrentState() serializes it.
    function launchGameFromRA(game) {
        launchingGame = (game !== null) ? game : currentGame;
        launchGameScreen();             // pushes the RA screen onto lastState
        lastState = ["showcasescreen"];  // ...replaced: return to the Showcase
        saveCurrentState(launchingGame);
        launchDelay.restart();
    }

    // Save current states for returning from game
    function saveCurrentState(game) {
        api.memory.set('savedState', root.state);
        api.memory.set('savedCollection', currentCollectionIndex);
        api.memory.set('lastState', JSON.stringify(lastState));
        api.memory.set('lastGame', JSON.stringify(lastGame));
        api.memory.set('storedHomePrimaryIndex', storedHomePrimaryIndex);
        api.memory.set('storedHomeSecondaryIndex', storedHomeSecondaryIndex);
        api.memory.set('storedCollectionIndex', currentCollectionIndex);
        api.memory.set('storedCollectionGameIndex', storedCollectionGameIndex);

        const savedGameIndex = api.allGames.toVarArray().findIndex(g => g === game);
        api.memory.set('savedGame', savedGameIndex);

        api.memory.set('To Game', 'True');
    }

    // Handle loading settings when returning from a game
    property bool fromGame: api.memory.has('To Game');
    function returnedFromGame() {
        lastState                   = JSON.parse(api.memory.get('lastState'));
        lastGame                    = JSON.parse(api.memory.get('lastGame'));
        currentCollectionIndex      = api.memory.get('savedCollection');
        storedHomePrimaryIndex      = api.memory.get('storedHomePrimaryIndex');
        storedHomeSecondaryIndex    = api.memory.get('storedHomeSecondaryIndex');
        currentCollectionIndex      = api.memory.get('storedCollectionIndex');
        storedCollectionGameIndex   = api.memory.get('storedCollectionGameIndex');

        currentGame                 = api.allGames.get(api.memory.get('savedGame'));
        root.state                  = api.memory.get('savedState');

        // savedState is "launchgamescreen" (the splash was on-screen at launch).
        // On reload-type devices we land back on the splash, so redirect to the
        // page we launched from (top of lastState) and drop it from the stack.
        if (root.state === "launchgamescreen") {
            if (lastState.length > 0) {
                root.state = lastState[lastState.length - 1];
                lastState.pop();
            } else {
                root.state = "showcasescreen";
            }
        }

        // Launched from the app drawer: always land on the Showcase, whatever
        // screen it was opened from. Checked after the redirect above so it
        // wins over the restored state.
        if (api.memory.has('From App Drawer')) {
            lastState  = ["showcasescreen"];
            root.state = "showcasescreen";
            api.memory.unset('From App Drawer');
        }

        // Remove these from memory so as to not clog it up
        api.memory.unset('savedState');
        api.memory.unset('savedGame');
        api.memory.unset('lastState');
        api.memory.unset('lastGame');
        api.memory.unset('storedHomePrimaryIndex');
        api.memory.unset('storedHomeSecondaryIndex');
        api.memory.unset('storedCollectionIndex');
        api.memory.unset('storedCollectionGameIndex');

        // Remove this one so we only have it when we come back from the game and not at Pegasus launch
        api.memory.unset('To Game');
    }

    // Theme settings
    property var theme: {
        var background    = "#000000";
        var text          = "#ebebeb";
        var gradientstart = "#001f1f1f";
        var gradientend   = "#FF000000";
        if (settings.ColorBackground === "Black") {
            background    = "#000000";
            gradientstart = "#001f1f1f";
            gradientend   = "#FF000000";
        } else if (settings.ColorBackground === "Charcoal") {
            background    = "#1a1a1a";
            gradientstart = "#001a1a1a";
            gradientend   = "#FF1a1a1a";
        } else if (settings.ColorBackground === "Dark Gray") {
            background    = "#1f1f1f";
            gradientstart = "#001f1f1f";
            gradientend   = "#FF1F1F1F";
        } else if (settings.ColorBackground === "Mid Gray") {
            background    = "#2d2d2d";
            gradientstart = "#002d2d2d";
            gradientend   = "#FF2d2d2d";
        } else if (settings.ColorBackground === "Navy Blue") {
            background    = "#0a0e2e";
            gradientstart = "#000a0e2e";
            gradientend   = "#FF0a0e2e";
        } else if (settings.ColorBackground === "Dark Blue") {
            background    = "#1d253d";
            gradientstart = "#001d253d";
            gradientend   = "#FF1d253d";
        } else if (settings.ColorBackground === "Dark Teal") {
            background    = "#041a18";
            gradientstart = "#00041a18";
            gradientend   = "#FF041a18";
        } else if (settings.ColorBackground === "Dark Green") {
            background    = "#054b16";
            gradientstart = "#00054b16";
            gradientend   = "#FF054b16";
        } else if (settings.ColorBackground === "Forest Green") {
            background    = "#0a200a";
            gradientstart = "#000a200a";
            gradientend   = "#FF0a200a";
        } else if (settings.ColorBackground === "Dark Red") {
            background    = "#520000";
            gradientstart = "#00520000";
            gradientend   = "#FF520000";
        } else if (settings.ColorBackground === "Burgundy") {
            background    = "#1c0008";
            gradientstart = "#001c0008";
            gradientend   = "#FF1c0008";
        } else if (settings.ColorBackground === "Dark Purple") {
            background    = "#120012";
            gradientstart = "#00120012";
            gradientend   = "#FF120012";
        } else if (settings.ColorBackground === "Indigo") {
            background    = "#0a0020";
            gradientstart = "#000a0020";
            gradientend   = "#FF0a0020";
        } else if (settings.ColorBackground === "Dark Brown") {
            background    = "#1a0e00";
            gradientstart = "#001a0e00";
            gradientend   = "#FF1a0e00";
        } else if (settings.ColorBackground === "Dark Orange") {
            background    = "#1a0800";
            gradientstart = "#001a0800";
            gradientend   = "#FF1a0800";
        } else if (settings.ColorBackground === "Slate") {
            background    = "#1a1e26";
            gradientstart = "#001a1e26";
            gradientend   = "#FF1a1e26";
        } else if (settings.ColorBackground === "Midnight Blue") {
            background    = "#050510";
            gradientstart = "#00050510";
            gradientend   = "#FF050510";
        } else if (settings.ColorBackground === "Deep Purple") {
            background    = "#0e0018";
            gradientstart = "#000e0018";
            gradientend   = "#FF0e0018";
        } else if (settings.ColorBackground === "Dark Steel") {
            background    = "#1e2a3a";
            gradientstart = "#001e2a3a";
            gradientend   = "#FF1e2a3a";
        } else if (settings.ColorBackground === "Gray") {
            background    = "#3a3a3a";
            gradientstart = "#003a3a3a";
            gradientend   = "#FF3a3a3a";
        } else if (settings.ColorBackground === "Cool Gray") {
            background    = "#4a5060";
            gradientstart = "#004a5060";
            gradientend   = "#FF4a5060";
        } else if (settings.ColorBackground === "Steel Blue") {
            background    = "#2c4a6e";
            gradientstart = "#002c4a6e";
            gradientend   = "#FF2c4a6e";
        } else if (settings.ColorBackground === "Teal") {
            background    = "#1a4a4a";
            gradientstart = "#001a4a4a";
            gradientend   = "#FF1a4a4a";
        } else if (settings.ColorBackground === "Forest") {
            background    = "#1a3a1a";
            gradientstart = "#001a3a1a";
            gradientend   = "#FF1a3a1a";
        } else if (settings.ColorBackground === "Wine") {
            background    = "#4a1020";
            gradientstart = "#004a1020";
            gradientend   = "#FF4a1020";
        } else if (settings.ColorBackground === "Plum") {
            background    = "#3a1a3a";
            gradientstart = "#003a1a3a";
            gradientend   = "#FF3a1a3a";
        } else if (settings.ColorBackground === "Light Gray") {
            background    = "#707070";
            gradientstart = "#00707070";
            gradientend   = "#FF707070";
        } else if (settings.ColorBackground === "Silver") {
            background    = "#909090";
            gradientstart = "#00909090";
            gradientend   = "#FF909090";
        } else if (settings.ColorBackground === "Light Blue") {
            background    = "#4a7aa0";
            gradientstart = "#004a7aa0";
            gradientend   = "#FF4a7aa0";
        } else if (settings.ColorBackground === "Sage") {
            background    = "#6a8a6a";
            gradientstart = "#006a8a6a";
            gradientend   = "#FF6a8a6a";
        } else if (settings.ColorBackground === "Tan") {
            background    = "#8a7a5a";
            gradientstart = "#008a7a5a";
            gradientend   = "#FF8a7a5a";
        } else if (settings.ColorBackground === "Rose") {
            background    = "#a06070";
            gradientstart = "#00a06070";
            gradientend   = "#FFa06070";
        } else if (settings.ColorBackground === "Gradient") {
            // theme.main becomes transparent so the root-level Gradient Image shows through.
            background    = "transparent";
            gradientstart = "#00000000";
            gradientend   = "#A0000000";
            text          = "#ebebeb";
        } else if (settings.ColorBackground === "White") {
            background    = "#ebebeb";
            gradientstart = "#00ebebeb";
            gradientend   = "#FFebebeb";
            text          = "#101010";
        }

        var accent        = "#107C10";   // default: Dark Green (Xbox brand green)

        // ── Full color palette ───────────────────────────────────────────
        switch (settings.ColorLayout) {
            // Greens
            case "Dark Green":    accent = "#107C10"; break;   // Xbox brand green (Pantone 362 C)
            case "Light Green":   accent = "#9BF00B"; break;   // Xbox bright green
            case "Lime":          accent = "#86c440"; break;
            case "Mint":          accent = "#3eb489"; break;
            case "Sage":          accent = "#7d9e7a"; break;
            case "Forest Green":  accent = "#2d6a2d"; break;
            case "Olive":         accent = "#6b7a2a"; break;
            // Teals / Cyans
            case "Turquoise":     accent = "#288e80"; break;
            case "Teal":          accent = "#3f8f86"; break;
            case "Dark Teal":     accent = "#1a5f5a"; break;
            case "Cyan":          accent = "#19c6d1"; break;
            case "Arctic":        accent = "#5bc8d4"; break;
            case "Seafoam":       accent = "#3cb4a0"; break;
            // Blues
            case "Dark Blue":     accent = "#30519c"; break;
            case "Light Blue":    accent = "#288dcf"; break;
            case "Navy Blue":     accent = "#1a2f6e"; break;
            case "Royal Blue":    accent = "#2952c4"; break;
            case "Sky Blue":      accent = "#4ab0e0"; break;
            case "Ice Blue":      accent = "#7ac4df"; break;
            case "Cobalt":        accent = "#0047ab"; break;
            case "Sapphire":      accent = "#1a4fa0"; break;
            // Reds
            case "Dark Red":      accent = "#ab283b"; break;
            case "Light Red":     accent = "#e52939"; break;
            case "Crimson":       accent = "#c6283c"; break;
            case "Burgundy":      accent = "#7a1c2e"; break;
            case "Maroon":        accent = "#7c2020"; break;
            case "Brick Red":     accent = "#b53a2f"; break;
            case "Ruby":          accent = "#c0192c"; break;
            // Pinks
            case "Dark Pink":     accent = "#c52884"; break;
            case "Light Pink":    accent = "#ee6694"; break;
            case "Hot Pink":      accent = "#e0287a"; break;
            case "Rose":          accent = "#c2466e"; break;
            case "Coral":         accent = "#e8583a"; break;
            case "Salmon":        accent = "#e07060"; break;
            // Purples
            case "Magenta":       accent = "#b857c6"; break;
            case "Purple":        accent = "#825fb1"; break;
            case "Dark Purple":   accent = "#5a2d82"; break;
            case "Violet":        accent = "#7d4bc4"; break;
            case "Lavender":      accent = "#9b7fd4"; break;
            case "Indigo":        accent = "#4b3a9a"; break;
            // Oranges / Yellows
            case "Orange":        accent = "#ed5b28"; break;
            case "Dark Orange":   accent = "#c44a18"; break;
            case "Amber":         accent = "#e09820"; break;
            case "Yellow":        accent = "#ed9728"; break;
            case "Gold":          accent = "#c8961a"; break;
            case "Dark Gold":     accent = "#a07010"; break;
            case "Bronze":        accent = "#a0722a"; break;
            // Browns
            case "Dark Brown":    accent = "#806044"; break;
            case "Light Brown":   accent = "#7e715c"; break;
            case "Copper":        accent = "#b5602a"; break;
            case "Rust":          accent = "#b04020"; break;
            case "Sienna":        accent = "#a0522d"; break;
            case "Tan":           accent = "#c8a878"; break;
            // Grays / Neutrals
            case "Dark Gray":     accent = "#5e5c5d"; break;
            case "Mid Gray":      accent = "#6e6e6e"; break;
            case "Light Gray":    accent = "#818181"; break;
            case "Silver":        accent = "#a8a8a8"; break;
            case "Steel":         accent = "#768294"; break;
            case "Slate":         accent = "#5a6478"; break;
            case "Stone":         accent = "#658780"; break;
            case "Charcoal":      accent = "#454545"; break;
            case "Gunmetal":      accent = "#4a5060"; break;
            // Gems / Specials
            case "Emerald":       accent = "#1a7a4a"; break;
            case "Jade":          accent = "#2a8a5a"; break;
            case "Onyx":          accent = "#353535"; break;
            case "White":         accent = "#e8e8e8"; break;
            // Special: image-based palette using assets/images/colorspng/Gradient.png
            case "Gradient":      accent = "#c060c0"; break;
            default:              accent = "#107C10"; break;
        }
        return {
            main:          background,
            secondary:     "#303030",
            accent:        accent,
            highlight:     accent,
            text:          text,
            button:        accent,
            gradientstart: gradientstart,
            gradientend:   gradientend
        };
    }

    // ── White-background contrast flags ───────────────────────────────────
    // When the page background is the light "White" color, chrome that is
    // normally white (nav bar, status bar, library logo) should flip to black
    // so it stays visible. theme.text already flips on its own for light
    // backgrounds; these flags drive the hardcoded-white chrome.
    //   whiteBackground          → AllGames, GridView, GameView, RA pages
    //   showcaseWhiteBackground  → Showcase, but ONLY when no fanart/custom
    //                              image is covering theme.main (otherwise the
    //                              visible backdrop is the image, not white)
    property bool whiteBackground: settings.ColorBackground === "White"
    property bool showcaseWhiteBackground: whiteBackground
                                           && settings.ShowcaseBackgroundArt === "No"
                                           && settings.CustomBackground === "No"

    property real globalMargin: vpx(30)

    // ── UI text scaling ──────────────────────────────────────────────────
    // vpx() is Pegasus's resolution scaler. fpx() layers the user's "UI Scale"
    // setting on top and is used for FONT SIZES ONLY — tiles, margins and
    // icons stay on vpx() so layouts tuned at 1.0 can't overflow. Resolves by
    // bare name in child screens and Global/ components, exactly like vpx().
    property real uiScale: parseFloat(settings.UiScale) || 1.0
    function fpx(n) { return vpx(n) * uiScale; }
    property real helpMargin: buttonbar.height
    property int transitionTime: 100

    // State settings
    states: [
        State {
            name: "softwarescreen";
        },
        State {
            name: "softwaregridscreen";
        },
        State {
            name: "showcasescreen";
        },
        State {
            name: "gameviewscreen";
        },
        State {
            name: "settingsscreen";
        },
        State {
            name: "launchgamescreen";
        },
        State {
            name: "achievementsscreen";
        },
        State {
            name: "gameachievementsscreen";
        },
        State {
            name: "raentryscreen";
        },
        State {
            name: "discoverscreen";
        },
        State {
            name: "allgamesscreen";
        }
    ]

    property var lastState: []
    property var lastGame: []

    // Screen switching functions
    function softwareScreen() {
        playAccept();
        lastState.push(state);
        searchTerm = "";
        searchMode = "Title";
        genreSelected = [];
        switch(settings.PlatformView) {
            case "Grid":
                root.state = "softwaregridscreen";
                break;
            default:
                root.state = "softwarescreen";
        }
    }

    function showcaseScreen() {
        playAccept();
        lastState.push(state);
        root.state = "showcasescreen";
    }

    function allGamesScreen() {
        playAccept();
        lastState.push(state);
        root.state = "allgamesscreen";
    }

    function gameDetails(game) {
        playAccept();

        // If we're already on gameviewscreen (e.g. navigating the "More games"
        // lists inside GameView), just swap the current game without pushing a
        // new gameviewscreen onto lastState — that would cause stacking.
        if (state === "gameviewscreen") {
            if (game !== null)
                currentGame = game;
            return;
        }

        // As long as there is a state history, save the last game
        if (lastState.length != 0)
            lastGame.push(currentGame);

        // Push the new game
        if (game !== null)
            currentGame = game;

        // Save the state before pushing the new one
        lastState.push(state);
        root.state = "gameviewscreen";
    }

    function settingsScreen() {
        playAccept();
        lastState.push(state);
        root.state = "settingsscreen";
    }

    function achievementsScreen() {
        playAccept();
        lastState.push(state);
        root.state = "achievementsscreen";
    }

    // Navigate to RA overview without pushing onto lastState.
    // Used when already inside RA (A from game achievements, or "View Overview"
    // from RAGameEntryView) so B exits RA in one press.
    function achievementsScreenFromGame() {
        playAccept();
        root.state = "achievementsscreen";
    }

    function gameAchievementsScreen() {
        lastState.push(state);
        root.state = "gameachievementsscreen";
    }

    // Navigate to game achievements from the RA overview without pushing.
    // Called by AchievementsView so that B always exits RA in one press
    // regardless of whether RA was entered from GameView or Showcase.
    function gameAchievementsScreenFromOverview() {
        root.state = "gameachievementsscreen";
    }

    // Navigate to GameAchievementsView without pushing onto lastState.
    // Called by RAGameEntryView when a game is found so pressing Back
    // returns directly to wherever RA was entered from.
    function gameAchievementsScreenFromEntry() {
        root.state = "gameachievementsscreen";
    }

    function raEntryScreen() {
        lastState.push(state);
        root.state = "raentryscreen";
    }

    // RA entry from the achievements search overlay. Deliberately does NOT
    // push onto lastState: we're already on the RA overview, and B from the
    // achievements page calls achievementsScreenFromGame() to return there
    // directly. Pushing left a stale "achievementsscreen" on the stack, so the
    // next B popped back onto the page you were already on and appeared to do
    // nothing until a third press.
    function raEntryScreenFromSearch() {
        root.state = "raentryscreen";
    }

    // Optional 'collection' scopes Discover to a single system (passed from
    // GridView's Discover nav button). Omitted/null => whole-library Discover,
    // same as every other entry point (Showcase, AllGames, GameView).
    property var discoverContext: null
    function discoverScreen(collection) {
        playAccept();
        discoverContext = collection || null;
        lastState.push(state);
        root.state = "discoverscreen";
    }

    // Navigate to game details without pushing "discoverscreen" onto lastState.
    // Called by DiscoverView so that pressing Back in Game Details returns to
    // Showcase (or wherever the user came from) rather than back to Discover.
    // Set for a single visit by callers that want GameView to open with the
    // full details pane already expanded, regardless of the global
    // "Default to full details" setting. Cleared on leaving GameView.
    property bool forceFullDetails: false
    function gameDetailsFull(game) {
        forceFullDetails = true;
        gameDetails(game);
    }

    // Installed apps carry almost no metadata, so a details page for them is an
    // empty screen and an extra button press. When they're allowed into the
    // rows, open them straight away instead.
    //
    // Gated on the Omit setting deliberately: with omit ON, apps aren't in the
    // rows at all, so this must not change how anything else behaves.
    function isAppGame(game) {
        return !!game && appTitleSet[game.title] === true;
    }
    function openGame(game) {
        if (!game) return;
        if (settings.OmitApplicationFromShowcase !== "Yes" && isAppGame(game))
            launchGame(game);
        else
            gameDetails(game);
    }

    function gameDetailsFromDiscover(game) {
        playAccept();
        if (lastState.length != 0)
            lastGame.push(currentGame);
        if (game !== null)
            currentGame = game;
        root.state = "gameviewscreen";
    }

    // Launch a game from DiscoverView without pushing "discoverscreen" onto
    // lastState so that returning from the game skips the Discover screen.
    function launchGameFromDiscover(game) {
        if (game !== null) {
            playAccept();
            launchingGame = game;
            launchSuspended = false;
            root.state = "launchgamescreen";
            saveCurrentState(game);
            launchDelay.restart();      // hold the splash, then launch (see launchDelay)
        }
    }

    // Drawer launches always come back to the Showcase, wherever they were
    // started from. Flagged in memory rather than by rewriting lastState, so
    // the normal return path is left completely alone.
    function launchAppFromDrawer(game) {
        if (game === null) return;
        launchingGame = game;
        // MUST go through launchGameScreen(): it pushes the current state onto
        // lastState before switching. Setting root.state directly pushed
        // nothing, so cancelling the splash popped an entry that was never
        // there — the stack emptied and the next cancel had nothing to return
        // to, leaving the launch to go ahead anyway.
        launchGameScreen();
        saveCurrentState(game);
        api.memory.set('From App Drawer', 'True');
        launchDelay.restart();
    }

    onStateChanged: {
        if (state !== "gameviewscreen") forceFullDetails = false;
    }

    function launchGameScreen() {
        playAccept();
        launchSuspended = false;
        lastState.push(state);
        root.state = "launchgamescreen";
    }

    function previousScreen() {
        playBack();
        // A cancelled drawer launch never returns, so clear the flag here or a
        // later, unrelated return would be redirected to the Showcase.
        if (api.memory.has('From App Drawer'))
            api.memory.unset('From App Drawer');

        // Guard against an empty stack. Reading past the end sets state to
        // undefined, which leaves the screen stuck exactly where it was.
        if (lastState.length === 0) {
            state = "showcasescreen";
            return;
        }

        if (state == lastState[lastState.length-1])
            popLastGame();

        state = lastState[lastState.length - 1];
        lastState.pop();
    }

    function popLastGame() {
        if (lastGame.length) {
            currentGame = lastGame[lastGame.length-1];
            lastGame.pop();
        }
    }

    // Set default state to the platform screen
    Component.onCompleted: { 
        root.state = "showcasescreen";

        if (fromGame)
            returnedFromGame();

        // currentCollectionIndex defaults to 0, which can now be the hidden
        // apps collection. Set once (not bound) so it lands on the first
        // system that actually has a tile, without resetting on re-sorts.
        if (sortedColl.length > 0)
            currentCollectionIndex = sortedColl[0];

        // Temporary, paired with logKeys: dumps every collection so the apps
        // one can be identified by its exact name. Several collections here
        // contain "android" (the ROM folders as well as the system apps
        // provider), so the drawer's loose name match can land on the wrong
        // one. Remove once the drawer is pointed at the right collection.
        if (logCollections) {
            for (var i = 0; i < api.collections.count; i++) {
                var c = api.collections.get(i);
                console.log("[theme] collection", i, "name:", c.name,
                            "| shortName:", c.shortName,
                            "| games:", c.games.count);
            }

            // What the apps provider actually gives us per app. Deciding how to
            // split them into tabs (system / games / emulators) depends on which
            // of these fields is populated — package names would be ideal, genre
            // is patchy given how many store lookups fail. First 15 is enough to
            // see the shape without flooding the log.
            for (var ai = 0; ai < api.collections.count; ai++) {
                var ac = api.collections.get(ai);
                if (!isDrawerCollection(ac)) continue;
                var agl = ac.games;
                var lim = Math.min(agl.count, 15);
                console.log("[apps] dumping", lim, "of", agl.count, "from", ac.name);
                for (var aj = 0; aj < lim; aj++) {
                    var ag = agl.get(aj);
                    var nfiles = ag.files ? ag.files.count : 0;
                    var af = nfiles > 0 ? ag.files.get(0) : null;
                    console.log("[apps]", aj,
                                "| title:", ag.title,
                                "| genre:", ag.genre,
                                "| dev:", ag.developer,
                                "| pub:", ag.publisher,
                                "| files:", nfiles,
                                "| path:", af ? af.path : "-",
                                "| name:", af ? af.name : "-");
                }
            }
        }
    }

    // Background
    Rectangle {
    id: background
        
        anchors.fill: parent
        // Image { source: "assets/images/backgrounds/halo.jpg"; fillMode: Image.PreserveAspectFit; anchors.fill: parent;  opacity: 0.3 }
        color: theme.main
    }

    // ── Background gradient image ─────────────────────────────────────────
    // Renders behind all screen Loaders (z: -1). Each screen's bg Rectangle has
    // color: theme.main, which is "transparent" only when Gradient is selected,
    // so this image shows through. Other ColorBackground choices render normally
    // as solid colors and this Image is hidden.
    Image {
        id: bgGradient
        anchors.fill: parent
        source: "assets/images/colorspng/Gradient.png"
        fillMode: Image.PreserveAspectCrop
        visible: settings.ColorBackground === "Gradient"
        asynchronous: true
        smooth: true
        z: -1
    }

    Loader  {
    id: showcaseLoader

        readonly property bool shown: (root.state === "showcasescreen")
        focus: shown
        opacity: shown ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: showcaseview
    }

    Loader {
    id: allgamesloader

        readonly property bool shown: (root.state === "allgamesscreen")
        focus: shown
        active: opacity !== 0
        opacity: shown ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: allgamesview
        asynchronous: true
    }

    Loader  {
    id: gridviewloader

        readonly property bool shown: (root.state === "softwaregridscreen")
        focus: shown
        active: opacity !== 0
        opacity: shown ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: gridview
        asynchronous: true
    }

    Loader  {
    id: listviewloader

        readonly property bool shown: (root.state === "softwarescreen")
        focus: shown
        active: opacity !== 0
        opacity: shown ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: listview
        asynchronous: true
    }

    Loader  {
    id: gameviewloader

        readonly property bool shown: (root.state === "gameviewscreen")
        focus: shown
        // Stay alive once loaded: the first visit sets gameviewLoaded = true via onLoaded,
        // after which active is always true so the component is never destroyed.
        // This prevents the blank-screen bug that occurred when returning from Settings
        // (previously, active went false on the opacity fade, which prematurely called
        // popLastGame() and left currentGame pointing at the wrong game).
        active: (root.state === "gameviewscreen") || gameviewLoaded
        onLoaded: gameviewLoaded = true
        opacity: shown ? 1 : 0
        // Skip GPU compositing entirely while fully hidden to keep memory overhead low.
        visible: opacity > 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: gameview
        asynchronous: true
        //game: currentGame
    }

    Loader  {
    id: launchgameloader

        // Declared before the RA loaders, so it needs an explicit z to sit on
        // top of them — otherwise launching from the achievements page shows
        // the RA page for the whole splash delay instead of the launch screen.
        z: 100
        readonly property bool shown: (root.state === "launchgamescreen")
        focus: shown
        active: opacity !== 0
        opacity: shown ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: launchgameview
        asynchronous: true
    }

    // Auto-return from the launch splash: once the app has been backgrounded (the game
    // ran) and then comes back to the foreground, leave the splash and land back where
    // we launched from. The "press any button" handler in LaunchGame stays as a fallback
    // for devices where this app-state signal doesn't fire.
    Connections {
        target: Qt.application
        onStateChanged: {
            if (root.state !== "launchgamescreen") return;
            if (Qt.application.state !== Qt.ApplicationActive)
                root.launchSuspended = true;
            else if (root.launchSuspended) {
                root.launchSuspended = false;
                previousScreen();
            }
        }
    }

    // Holds the launch splash on screen for launchSplashDelay ms, THEN starts the game.
    // (The wait happens before the OS suspends Pegasus, so it's reliable.) Guarded so a
    // back-press during the hold cancels the launch instead of starting it late.
    Timer {
        id: launchDelay
        interval: launchSplashDelay
        repeat: false
        onTriggered: {
            if (root.state === "launchgamescreen" && launchingGame)
                launchingGame.launch();
        }
    }

    Loader  {
    id: settingsloader

        readonly property bool shown: (root.state === "settingsscreen")
        focus: shown
        active: opacity !== 0
        opacity: shown ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: settingsview
        asynchronous: true
    }

    Loader {
    id: achievementsloader

        readonly property bool shown: (root.state === "achievementsscreen")
        focus: shown
        active: opacity !== 0
        opacity: shown ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: achievementsview
        asynchronous: true
    }

    Loader {
    id: gameachievementsloader

        readonly property bool shown: (root.state === "gameachievementsscreen")
        focus: shown
        active: opacity !== 0
        opacity: shown ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: gameachievementsview
        asynchronous: true
    }

    Loader {
    id: raentryloader

        readonly property bool shown: (root.state === "raentryscreen")
        focus: shown
        active: opacity !== 0
        opacity: shown ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: raentryview
        asynchronous: true
    }

    Component {
    id: showcaseview

        ShowcaseViewMenu { focus: true }
    }

    Component {
    id: gridview

        GridViewMenu { focus: true }
    }

    Component {
    id: listview

        SoftwareListMenu { focus: true }
    }

    Component {
    id: allgamesview

        AllGamesMenu { focus: true }
    }

    Component {
    id: gameview

        GameView {
            focus: true
            game: currentGame
        }
    }

    Component {
    id: launchgameview

        LaunchGame { focus: true }
    }

    Component {
    id: settingsview

        SettingsScreen { focus: true }
    }

    Component {
    id: achievementsview

        AchievementsView { focus: true }
    }

    Component {
    id: gameachievementsview

        GameAchievementsView { focus: true }
    }

    Component {
    id: raentryview

        RAGameEntryView { focus: true }
    }

    Loader {
    id: discoverviewloader

        readonly property bool shown: (root.state === "discoverscreen")
        focus: shown
        active: opacity !== 0
        opacity: shown ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: discoverview
        asynchronous: true
    }

    Component {
    id: discoverview

        DiscoverView { focus: true }
    }

    
    // Button help
    property var currentHelpbarModel
    // Help bar text follows theme.text everywhere EXCEPT the settings page,
    // whose background is locked black — there it stays light so it never vanishes.
    ButtonHelpBar {
    id: buttonbar

        height: vpx(50)
        anchors {
            left: parent.left; leftMargin: globalMargin
            right: parent.right; rightMargin: globalMargin
            bottom: parent.bottom
        }
        visible: settings.HideButtonHelp === "No" && root.state !== "launchgamescreen"

        // Pinned bottom-left, away from the right-hand prompts. Shown on every
        // screen because Select opens the drawer from anywhere — the root key
        // handler catches it wherever the focused screen doesn't.
        //
        // The bar itself already hides on the launch screen and when the user
        // turns button help off, so this needs no state test of its own. It is
        // suppressed while the drawer is open, where Select closes rather than
        // opens and the prompt would be misleading.
        // Hidden when the drawer is open (Select closes rather than opens), and
        // when a screen has cleared the helpbar entirely — Discover's X toggle
        // nulls the model to hide its UI, and this prompt has to go with it
        // rather than sitting there alone.
        leftPromptText: (appDrawer.open || hideAppsPrompt) ? "" : "Apps"
        // Path is relative to ButtonHelpBar.qml, NOT this file: the string is
        // converted to a url by the `source:` binding inside that component, so
        // it resolves against that component's folder. Same "../" the delegate
        // beside it uses.
        leftPromptIcon: "../assets/images/icon_select.svg"
    }

    // ── App drawer ────────────────────────────────────────────────────────
    // One instance at the top level so it overlays every screen. z sits above
    // launchgameloader (z: 100) and the help bar so nothing draws over it.
    AppDrawer {
    id: appDrawer

        z: 500
        // Same constant the system-row filter uses, so the collection the
        // drawer shows is exactly the one hidden from the row — they can't
        // drift apart.
        collectionMatch: root.appsCollectionName
        title: "My games & apps"

        // Reuses the Discover launch path, which deliberately does NOT push
        // onto lastState — so coming back from an app returns to the screen
        // that was showing, rather than re-entering wherever the drawer was
        // opened from.
        onAppChosen: launchAppFromDrawer(game)
        onClosed: playTabLeft()

        // Home resets the back stack rather than pushing onto it — otherwise
        // backing out of the Showcase would return to whatever screen you were
        // on when you opened the drawer, which isn't what "Home" means. Seeded
        // rather than emptied because previousScreen() reads the top of the
        // stack without checking it's non-empty.
        onNavHome: {
            if (root.state === "showcasescreen") return;
            playAccept();
            lastState = ["showcasescreen"];
            root.state = "showcasescreen";
        }
        // Library pushes normally, so Back returns where you came from.
        onNavLibrary: {
            if (root.state === "allgamesscreen") return;
            allGamesScreen();
        }
        // Action tiles. Each pushes onto the back stack the same way the rest
        // of the theme does, so Back returns to wherever the drawer was opened.
        onNavDiscover: {
            if (root.state === "discoverscreen") return;
            discoverScreen(null);
        }
        onNavAchievements: {
            if (root.state === "achievementsscreen") return;
            achievementsScreen();
        }
        onNavSettings: {
            if (root.state === "settingsscreen") return;
            settingsScreen();
        }
        // Last-resort recovery: re-apply the current state so every loader's
        // `focus: shown` binding re-evaluates and the active screen takes focus
        // back. Only fires if the captured item is gone.
        onFocusRestoreFailed: {
            var s = root.state;
            root.state = "";
            root.state = s;
        }
    }

    // Trigger. Screens accept the keys they use, so anything they ignore
    // bubbles up to here — which is why this works from any screen without
    // touching the individual views.
    //
    // 1048586 = Select, captured from the device log. Tab is kept for
    // desktop testing.
    readonly property var appDrawerKeys: [ 1048586, Qt.Key_Tab ]

    // Diagnostics, both off-switchable. Key logging is done — Select was
    // caught — but the collection dump is worth one more run to confirm which
    // collection the Android apps provider creates once it's enabled.
    property bool logKeys: false
    property bool logCollections: true

    Keys.onPressed: {
        if (event.isAutoRepeat) return;

        if (logKeys)
            console.log("[theme] key code:", event.key, "text:", event.text);

        if (appDrawerKeys.indexOf(event.key) === -1) return;
        event.accepted = true;
        if (appDrawer.open) {
            appDrawer.closeDrawer();
        } else {
            playTabRight();
            appDrawer.openDrawer();
        }
    }

    ///////////////////
    // SOUND EFFECTS //
    ///////////////////

    // Master menu-sound volume: 0 when "Menu sounds" = No, else the Menu Volume
    // level (0.1-1.0). SoundEffect.volume is capped at 1.0.
    property real sfxVolume: {
        if (settings.MenuSounds === "No") return 0.0;
        var v = parseFloat(settings.MenuVolume);
        return (isNaN(v) || v < 0) ? 1.0 : Math.min(v, 1.0);
    }

    // Startup chime — plays shortly after the theme loads (delay lets the audio
    // engine come up so the first play isn't dropped). Respects the menu volume.
    Timer {
        interval: 450; running: true; repeat: false
        onTriggered: { if (settings.StartupChime !== "No" && sfxVolume > 0) { sfxStartup.stop(); sfxStartup.play(); } }
    }
    SoundEffect {
        id: sfxStartup
        source: "assets/sfx/startup.wav"
        volume: sfxVolume
    }
    SoundEffect {
        id: sfxNav
        source: "assets/sfx/navigation.wav"
        volume: sfxVolume
    }

    SoundEffect {
        id: sfxBack
        source: "assets/sfx/back.wav"
        volume: sfxVolume
    }

    SoundEffect {
        id: sfxAccept
        source: "assets/sfx/accept.wav"
        volume: sfxVolume
    }

    SoundEffect {
        id: sfxToggle
        source: "assets/sfx/toggle.wav"
        volume: sfxVolume
    }

    SoundEffect {
        id: sfxTabLeft
        source: "assets/sfx/tab_left.wav"
        volume: sfxVolume
    }

    SoundEffect {
        id: sfxTabRight
        source: "assets/sfx/tab_right.wav"
        volume: sfxVolume
    }
    
}
