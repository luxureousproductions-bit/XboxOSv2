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
import QtQuick.Window 2.15   // Window.active — second signal for app-switch detection
import QtGraphicalEffects 1.15   // FastBlur, for the HQ drawer backdrop
import QtQuick.Layouts 1.15
import SortFilterProxyModel 0.2
import QtMultimedia 5.15
import "RetroAchievements"
import "Global"
import "GameDetails"
import "ShowcaseView"
import "Settings"
import "utils.js" as Utils
import "buildinfo.js" as BuildInfo

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
    property alias settingsEpoch: settingsStore.epoch

    SettingsStore {
    id: settingsStore
        defaults: settingDefaults
    }

    // OS and Pegasus X feature checks, in one place (Global/Platform.qml).
    Platform { id: platform }

    // What the Diagnostics page shows and "Write diagnostics to log" writes.
    function diagnosticsText() {
        return "XboxOSv2 build " + BuildInfo.build + " (" + BuildInfo.branch + ", " + BuildInfo.date + ")"
            + "\nFrontend: " + platform.frontendLine
            + "\nFeatures: " + platform.featureLine
            + "\nPDF manuals: " + (platform.hasPdf ? "yes" : "no") + "  |  Manual lookup: " + (platform.hasFindManual ? "native" : "theme")
            + "\nOS: " + platform.os + "  |  Screen: " + width + "x" + height + "  |  UI scale: " + settings.UiScale
            + "\nHQ mode: " + (hqMode ? "on" : "off") + "  |  Tile frame: " + (xboxFrameLive ? "Xbox" : "Classic")
            + "\nLibrary: " + api.allGames.count + " games, " + api.collections.count + " collections";
    }

    // Live copy of the featured box mode. Read by ShowcaseViewMenu's carousel
    // and by FavoritesHeader, so switching it applies without a reload.
    readonly property string featuredBoxContent: {
        var e = settingsEpoch;
        return settingsStore.get("Featured Box Content");
    }

    // ── Home "hide" sets: apps and emulators kept SEPARATE ────────────────
    // The Home rows (Lists/*.qml) hide by title:
    //   Hide apps from Home      -> homeAppTitleSet + genre "Application"
    //   Hide emulators from Home -> emulatorTitleSet + genre "Emulator"
    //
    // Before, the rows' app set was every title in the "Android" collection,
    // emulators included, so Hide apps took the emulators with it and Hide
    // emulators only ever saw genre tags. (An omitTitleSet / omitEmulatorLive
    // pair here looked like the fix but nothing ever read them — removed.)
    //
    // What counts as an emulator, per drawer entry (Pegasus imports AND your
    // entries in the "Android" collection):
    //   genre tag "Emulator"     -> emulator
    //   genre tag "Application"  -> app, wherever the drawer files it
    //   no tag                   -> the drawer's Emulators section decides:
    //                               the keyword rules or wherever you moved it
    //                               (saved moves update categoryMap, so this
    //                               follows them live)
    // A system's logo: the collection's own (Pegasus X Settings > Library >
    // System tile), else the theme's bundled one. Every screen uses this, so
    // a logo set for a collection shows everywhere. Relative to the screens'
    // folders (they all sit one level down).
    function systemLogoSource(coll) {
        if (!coll) return "";
        if (coll.assets && coll.assets.logo) return coll.assets.logo;
        return "../assets/images/logospng/" + Utils.processPlatformName(coll.shortName) + ".png";
    }
    function hasGenre(g, want) {
        var gl = g ? g.genreList : null;
        if (!gl) return false;
        for (var i = 0; i < gl.length; i++)
            if ((gl[i] || "").toLowerCase() === want) return true;
        return false;
    }
    // Pegasus X tags every entry of its one "Android" collection as Game,
    // Emulator or Application (Settings > Library > Combine Android collections)
    function hasTag(g, want) {
        var tl = g ? g.tagList : null;
        if (!tl) return false;
        for (var i = 0; i < tl.length; i++)
            if ((tl[i] || "").toLowerCase() === want) return true;
        return false;
    }
    readonly property var emulatorTitleSet: {
        var set = {};
        var idx = appLib.appIndex;
        var cat = appLib.categoryMap;
        for (var i = 0; i < idx.length; i++) {
            var e = idx[i];
            if (!e.title) continue;
            if (hasGenre(e.g, "emulator")
                || (cat[e.pkg] === "emulator" && !hasGenre(e.g, "application")))
                set[e.title] = true;
        }
        return set;
    }
    // Same rule for the drawer's Games section: an untagged entry you (or
    // the shipped list) filed under Games is a game, so "Hide apps" leaves it
    // on Home. A genre tag of "Application" still makes it an app.
    readonly property var drawerGameTitleSet: {
        var set = {};
        var idx = appLib.appIndex;
        var cat = appLib.categoryMap;
        for (var i = 0; i < idx.length; i++) {
            var e = idx[i];
            if (!e.title) continue;
            if (cat[e.pkg] === "game" && !hasGenre(e.g, "application")
                && !hasGenre(e.g, "emulator"))
                set[e.title] = true;
        }
        return set;
    }
    // appTitleSet minus emulators and games. appTitleSet itself stays as it
    // was — the launch rule (isAppGame) still reads it until the launch stage.
    readonly property var homeAppTitleSet: {
        var set = {};
        var a = appTitleSet;
        var emu = emulatorTitleSet;
        var gm = drawerGameTitleSet;
        for (var t in a)
            if (emu[t] !== true && gm[t] !== true) set[t] = true;
        return set;
    }

    // Titles of YOUR entries in the Android sources (anything that isn't a
    // Pegasus import). A Pegasus import with one of these exact titles is a
    // duplicate: the drawer shows only your copy, and so do these pages.
    // Exact titles only: your entries don't expose a package name, so a
    // differently-named copy can't be matched.
    readonly property var myAndroidTitles: {
        var mine = {};
        var cols = drawerCollections;
        for (var i = 0; i < cols.length; i++) {
            var gl = cols[i].games;
            for (var j = 0; j < gl.count; j++) {
                var g = gl.get(j);
                if (g.title && !isPegasusImport(g)) mine[g.title] = true;
            }
        }
        return mine;
    }
    // Rows the library leaves out, by ROW and never by title (a duplicate
    // shares its title with your copy, so a title filter would hide yours too):
    //   - Pegasus imports that duplicate one of your entries (exact title)
    //   - anything you set to "Library only" or "Both" in the drawer's Hide
    //     panel (libraryHiddenLive — the published copy, see rebuildHomeHide()),
    //     matched by the same key the drawer uses
    // Two numberings:
    //   libraryHideRows  - rows in api.allGames (Home rows, All Games with all
    //                      systems shown)
    //   androidHideRows  - { collection index: rows in THAT collection's own
    //                      list } for every Android collection (platform page,
    //                      All Games with one system chosen)
    function drawerKeyOf(g) {
        var p = appLib.packageOf(g);
        return p !== "" ? p : "title:" + (g.title || "");
    }
    function libraryHides(g, mine, lib, libOn) {
        if (isPegasusImport(g) && g.title && mine[g.title] === true) return true;
        return libOn && lib[drawerKeyOf(g)] === true;
    }
    readonly property var libraryHideRows: {
        var mine = myAndroidTitles;
        var lib = libraryHiddenLive;
        var libOn = Object.keys(lib).length > 0;
        var rows = {};
        var all = api.allGames;
        for (var k = 0; k < all.count; k++)
            if (libraryHides(all.get(k), mine, lib, libOn)) rows[k] = true;
        return rows;
    }
    // ── Home rows: everything they hide, as ONE row set ───────────────────
    // Each Home row used to re-check, for every one of ~4.4k games, the
    // hidden rows, the hidden titles AND the game's genre tags (apps,
    // emulators) — seven rows doing the same work on every re-filter. This
    // does it once per change of its inputs; the rows then only look up
    // their row number here.
    readonly property var homeHideRows: {
        var base = libraryHideRows, titles = homeHideTitles;
        var omitApp = omitAppsLive, omitEmu = omitEmulatorsLive;
        var rows = {};
        for (var r in base) rows[r] = true;
        var all = api.allGames;
        for (var k = 0; k < all.count; k++) {
            if (rows[k]) continue;
            var g = all.get(k);
            if (titles[g.title] === true) { rows[k] = true; continue; }
            if (!omitApp && !omitEmu) continue;
            var genres = g.genreList;
            for (var i = 0; i < genres.length; i++) {
                var gl = genres[i].toLowerCase();
                if ((omitApp && gl === "application") || (omitEmu && gl === "emulator")) { rows[k] = true; break; }
            }
        }
        return rows;
    }
    readonly property var noHideTitles: ({})

    readonly property var androidHideRows: {
        var mine = myAndroidTitles;
        var lib = libraryHiddenLive;
        var libOn = Object.keys(lib).length > 0;
        var out = {};
        var n = api.collections.count;
        for (var i = 0; i < n; i++) {
            var c = api.collections.get(i);
            if (!isAndroidSourceCollection(c)) continue;
            var rows = {}, any = false;
            var gl = c.games;
            for (var j = 0; j < gl.count; j++)
                if (libraryHides(gl.get(j), mine, lib, libOn)) { rows[j] = true; any = true; }
            if (any) out[i] = rows;
        }
        return out;
    }
    readonly property var noHideRows: ({})
    function hideRowsForCollection(i) {
        var m = androidHideRows;            // dependency, so callers re-run with it
        return (i >= 0 && m[i] !== undefined) ? m[i] : noHideRows;
    }

    // Live copies of the two Home hide options. `settings` is read once at
    // load, so rows bound to it only changed after a reload. These re-read on
    // settingsEpoch, which Settings bumps on every save (the same pattern as
    // featuredBoxContent above).
    readonly property bool omitAppsLive: {
        var e = settingsEpoch;
        return (settingsStore.get("Omit genre: Application from Showcase", "No")) === "Yes";
    }
    readonly property bool omitEmulatorsLive: {
        var e = settingsEpoch;
        return (settingsStore.get("Omit genre: Emulator from Showcase", "No")) === "Yes";
    }

    // Frame rate counter (Settings > Appearance > Diagnostics). Live.
    readonly property bool frameCounterLive: {
        var e = settingsEpoch;
        return (settingsStore.get("Frame counter", "No")) === "Yes";
    }

    // ── What the Home rows hide, as ONE list ──────────────────────────────
    // The rows re-filter the whole library (~4.4k games each, 7 rows) every
    // time an input they read changes. They used to read homeAppTitleSet and
    // emulatorTitleSet directly — and those rebuild as NEW objects whenever
    // the drawer's categoryMap does, i.e. on every "Move to …", even when
    // nothing in them changed. That was several full re-filters per move
    // (~10s frozen). Now:
    //   - the two sets + both options are combined into one list here
    //   - it's only republished when its CONTENTS change (signature check),
    //     so System <-> Other moves cost the rows nothing
    //   - while the drawer is open (Home isn't visible) it waits, and runs
    //     once after the drawer closes
    property var    homeHideTitles: ({})
    property string homeHideSig: ""
    property bool   homeHidePending: false
    // Published copy of the drawer's "Hide from library" list. The row lists
    // above read THIS, so a hide/show in the drawer reaches Home, the Android
    // page and All Games on the same terms: after the drawer closes, and only
    // if it actually changed.
    property var    libraryHiddenLive: ({})
    property string libraryHiddenSig: ""
    function rebuildHomeHide() {
        if (drawerOpen) { homeHidePending = true; return; }
        homeHidePending = false;
        var libSig = Object.keys(appLib.libraryHiddenPkgs).sort().join("\n");
        if (libSig !== libraryHiddenSig) {
            libraryHiddenSig = libSig;
            libraryHiddenLive = appLib.libraryHiddenPkgs;
        }
        var set = {};
        if (omitAppsLive)      { var a = homeAppTitleSet;  for (var t in a) set[t] = true; }
        if (omitEmulatorsLive) { var e = emulatorTitleSet; for (var u in e) set[u] = true; }
        var sig = Object.keys(set).sort().join("\n");
        if (sig === homeHideSig) return;
        homeHideSig = sig;
        homeHideTitles = set;
    }
    onHomeAppTitleSetChanged:   Qt.callLater(rebuildHomeHide)
    onEmulatorTitleSetChanged:  Qt.callLater(rebuildHomeHide)
    onOmitAppsLiveChanged:      Qt.callLater(rebuildHomeHide)
    onOmitEmulatorsLiveChanged: Qt.callLater(rebuildHomeHide)
    Connections {
        target: appLib
        onLibraryHiddenPkgsChanged: Qt.callLater(rebuildHomeHide)
    }
    // After the drawer's slide-out, so the one re-filter doesn't land on it.
    Timer {
    id: homeHideAfterDrawer
        interval: hqDrawerSlideMs + 100
        repeat: false
        onTriggered: rebuildHomeHide()
    }

    // ── Grid background dimming ───────────────────────────────────────────
    // A translucent black layer between the background and the tiles on the
    // Platform page and the All Games grid, so the grid reads as a surface
    // sitting on the art rather than mixed into it. One flat rectangle:
    // no texture, no shader, no per-tile cost.
    readonly property real gridDimOpacity: {
        switch (settings.GridDimming) {
        case "Light":  return 0.18;
        case "Medium": return 0.30;
        case "Strong": return 0.45;
        default:       return 0.0;     // Off
        }
    }

    // The bottom fade (last row dissolving under the button prompts) has its
    // own setting, "Bottom fade", with the same four levels: Off removes it,
    // Strong is the full fade, Light and Medium sit in between. Multiplied
    // into each page's fade rectangle.
    readonly property real gridFadeOpacity: {
        switch (settings.GridFade) {
        case "Light":  return 0.5;
        case "Medium": return 0.75;
        case "Strong": return 1.0;
        default:       return 0.0;     // Off
        }
    }

    // ── Tile titles ───────────────────────────────────────────────────────
    // "Game tile titles" reuses the old "Always show titles" key. Saved values
    // from before are Yes/No; the row now stores On focus/Always/Never. Both
    // forms resolve here, so nobody's install changes on update:
    //   No -> On focus (today's behaviour)   Yes -> Always
    readonly property string gameTitleMode: {
        var v = settings.AlwaysShowTitles;
        return v === "Yes" ? "Always" : (v === "No" ? "On focus" : v);
    }
    readonly property string systemTitleMode: settings.SystemTileTitles

    // ── First-run defaults ────────────────────────────────────────────────
    // What a fresh install gets before the user touches anything. Read by the
    // settings object below (as each key's fallback) AND by SettingsScreen (to
    // show the right current value on a fresh install) — one table, so the two
    // can never disagree. Keys absent here keep the fallback written inline.
    readonly property var settingDefaults: ({
        "3D Box":                                    "Yes",
        "All games menu video audio":                "Yes",
        "Allow video thumbnails":                    "Yes",
        "Bottom fade":                               "Strong",
        "Box Art":                                   "3D",
        "Collection 1":                              "Recommended",
        "Collection 1 - Ratio":                      "0.66",
        "Collection 1 - Size":                       "Small",
        "Collection 1 - Thumbnail":                  "Wide",
        "Collection 2":                              "Recently Played",
        "Collection 2 - Ratio":                      "0.55",
        "Collection 2 - Size":                       "Medium",
        "Collection 2 - Thumbnail":                  "Tall",
        "Collection 3":                              "Top by Genre",
        "Collection 3 - Size":                       "Medium",
        "Collection 3 - Thumbnail":                  "Square",
        "Collection 4":                              "Top by Publisher",
        "Collection 4 - Size":                       "Medium",
        "Collection 5":                              "Top by Genre 2",
        "Collection 5 - Ratio":                      "0.55",
        "Collection 5 - Size":                       "Large",
        "Collection 6":                              "Top by Developer",
        "Collection 6 - Size":                       "Large",
        "Collection 6 - Thumbnail":                  "Square",
        "Color Background":                          "Black",
        "Color Layout":                              "Lime",
        "Custom Background":                         "Yes",
        "Discover video audio":                      "Yes",
        "Dynamic Background":                        "No",
        "Favorited Tile Accent":                     "Yes",
        "Featured Box Content":                      "Fanart Slideshow",
        "Game Background":                           "Fanart",
        "Game details video preview audio":          "Yes",
        "Grid Thumbnail":                            "Square",
        "Hide Android System Tile":                  "Yes",
        "Hide Android Games System Tile":            "No",
        "Hide logo when thumbnail video plays":      "Yes",
        "High Quality Mode":                         "No",
        "Launch screen delay":                       "2.5",
        "More by Genre Display":                     "Full",
        "Number of columns":                         "3",
        "Number of games showcased":                 "20",
        "Omit genre: Application from Showcase":     "No",
        "Omit genre: Emulator from Showcase":        "No",
        "Pins to collection":                        "2",
        "Randomize System Tile Fanart":              "No",
        "Screenshot Fallback":                       "No",
        "Show scanlines":                            "No",
        "Showcase Background Art":                   "Yes",
        "Showcase Background Opacity":               "1.00",
        "System sort":                               "Release year (oldest)",
        "UI Scale":                                  "1.0",
        "Video thumbnail audio":                     "Yes",
        "Xbox Logo":                                 "Logo1",
        // ── Added with SettingsStore: every remaining setting, same values as
        //    the settings object's fallbacks, so this is the complete schema.
        "2D Box":                                    "Yes",
        "Added App Launch":                          "Instant",
        "All Games View":                            "List",
        "AllGames Blur Background":                  "No",
        "AllGames Hide box art on video":            "No",
        "AllGames Hide logo on video":               "No",
        "AllGames Items per row":                    "5",
        "AllGames Match Platform":                   "No",
        "AllGames Show scanlines":                   "No",
        "AllGames Tile Art":                         "Fanart",
        "AllGames Tile Logo":                        "Yes",
        "AllGames Tile Ratio":                       "0.66",
        "AllGames Tile Style":                       "Wide",
        "AllGames Video preview":                    "Yes",
        "Always show titles":                        "No",
        "Animate highlight":                         "No",
        "Back Box":                                  "Yes",
        "Blur Background":                           "No",
        "Cartridge":                                 "Yes",
        "Collection 3 - Ratio":                      "0.66",
        "Collection 4 - Ratio":                      "0.66",
        "Collection 4 - Thumbnail":                  "Tall",
        "Collection 5 - Thumbnail":                  "Wide",
        "Collection 6 - Ratio":                      "0.66",
        "Default to full details":                   "No",
        "Enable mouse hover":                        "No",
        "Fanart":                                    "Yes",
        "Featured Box":                              "Yes",
        "Featured collection":                       "Favorites",
        "Game Counter":                              "Yes",
        "Game Logo":                                 "Show",
        "Grid Game Logo":                            "Yes",
        "Grid Ratio":                                "0.66",
        "Grid art":                                  "Fanart",
        "Grid background dimming":                   "Light",
        "Hero box art":                              "Fanart",
        "Hide button help":                          "No",
        "LB/RB Function":                            "Cycle Platforms",
        "Logo":                                      "Yes",
        "Logo Color Match":                          "No",
        "Menu Volume":                               "1.0",
        "Menu sounds":                               "Yes",
        "Miximage":                                  "Yes",
        "Per-system tile settings":                  "No",
        "Screenshots":                               "Yes",
        "Show Battery Percentage":                   "Battery Only",
        "Show Clock":                                "12hr",
        "Show WiFi Indicator":                       "Yes",
        "Showcase Collections Art":                  "Fanart",
        "Start up chime":                            "Yes",
        "Startup intro":                             "Yes",
        "Tile frame":                                "Classic",
        "Library system tiles follow All":           "No",
        "System tile titles":                        "On focus",
        "Tile Halo":                                 "Yes",
        "Title Screen":                              "Yes",
        "Video":                                     "Yes",
        "Video preview":                             "Yes",
    })

    property var settings: {
        return {
            GridThumbnail:                 settingsStore.get("Grid Thumbnail", "Square"),
            GridArt:                       settingsStore.get("Grid art", "Fanart"),
            GridGameLogo:                  settingsStore.get("Grid Game Logo", "Yes"),
            GridColumns:                   settingsStore.get("Number of columns", "3"),
            GameBackground:                settingsStore.get("Game Background", "Fanart"),
            GameLogo:                      settingsStore.get("Game Logo", "Show"),
            GameBlurBackground:            settingsStore.get("Blur Background", "No"),
            VideoPreview:                  settingsStore.get("Video preview", "Yes"),
            AllowThumbVideo:               settingsStore.get("Allow video thumbnails", "Yes"),
            AllowThumbVideoAudio:          settingsStore.get("Video thumbnail audio", "Yes"),
            HideLogo:                      settingsStore.get("Hide logo when thumbnail video plays", "Yes"),
            HideButtonHelp:                settingsStore.get("Hide button help", "No"),
            // "Gradient" was removed as an option; a stale saved value falls back to the default.
            ColorLayout:                   (api.memory.has("Color Layout") && api.memory.get("Color Layout") !== "Gradient") ? api.memory.get("Color Layout") : "Lime",
            MouseHover:                    settingsStore.get("Enable mouse hover", "No"),
            AlwaysShowTitles:              settingsStore.get("Always show titles", "No"),
            AnimateHighlight:              settingsStore.get("Animate highlight", "No"),
            AllowVideoPreviewAudio:        settingsStore.get("Game details video preview audio", "Yes"),
            ShowScanlines:                 settingsStore.get("Show scanlines", "No"),
            DetailsDefault:                settingsStore.get("Default to full details", "No"),
            LaunchScreenDelay:             settingsStore.get("Launch screen delay", "2.5"),
            FeaturedBox:                   settingsStore.get("Featured Box", "Yes"),
            FeaturedBoxCollection:         settingsStore.get("Pins to collection", "2"),
            UiScale:                       settingsStore.get("UI Scale", "1.0"),
            FavoritedTileAccent:           settingsStore.get("Favorited Tile Accent", "Yes"),
            FeaturedBoxContent:            settingsStore.get("Featured Box Content", "Fanart Slideshow"),
            ShowcaseBackgroundArt:          settingsStore.get("Showcase Background Art", "Yes"),
            RandomizeSystemTileFanart:      settingsStore.get("Randomize System Tile Fanart", "No"),
            CustomBackground:               settingsStore.get("Custom Background", "Yes"),
            ShowcaseBackgroundOpacity:     settingsStore.get("Showcase Background Opacity", "1.00"),
            ShowcaseArt:                   settingsStore.get("Showcase Collections Art", "Fanart"),
            HeroBoxArt:                    settingsStore.get("Hero box art", "Fanart"),
            TileHalo:                      settingsStore.get("Tile Halo", "Yes"),
            SystemSort:                    settingsStore.get("System sort", "Release year (oldest)"),
            ShowcaseColumns:               settingsStore.get("Number of games showcased", "20"),
            ShowcaseFeaturedCollection:    settingsStore.get("Featured collection", "Favorites"),
            ShowcaseCollection1:           settingsStore.get("Collection 1", "Recommended"),
            ShowcaseCollection1_Thumbnail: settingsStore.get("Collection 1 - Thumbnail", "Wide"),
            ShowcaseCollection1_Size:      settingsStore.get("Collection 1 - Size", "Small"),
            ShowcaseCollection1_Ratio:     settingsStore.get("Collection 1 - Ratio", "0.66"),
            ShowcaseCollection2:           settingsStore.get("Collection 2", "Recently Played"),
            ShowcaseCollection2_Thumbnail: settingsStore.get("Collection 2 - Thumbnail", "Tall"),
            ShowcaseCollection2_Size:      settingsStore.get("Collection 2 - Size", "Medium"),
            ShowcaseCollection2_Ratio:     settingsStore.get("Collection 2 - Ratio", "0.55"),
            ShowcaseCollection3:           settingsStore.get("Collection 3", "Top by Genre"),
            ShowcaseCollection3_Thumbnail: settingsStore.get("Collection 3 - Thumbnail", "Square"),
            ShowcaseCollection3_Size:      settingsStore.get("Collection 3 - Size", "Medium"),
            ShowcaseCollection3_Ratio:     settingsStore.get("Collection 3 - Ratio", "0.66"),
            ShowcaseCollection4:           settingsStore.get("Collection 4", "Top by Publisher"),
            ShowcaseCollection4_Thumbnail: settingsStore.get("Collection 4 - Thumbnail", "Tall"),
            ShowcaseCollection4_Size:      settingsStore.get("Collection 4 - Size", "Medium"),
            ShowcaseCollection4_Ratio:     settingsStore.get("Collection 4 - Ratio", "0.66"),
            ShowcaseCollection5:           settingsStore.get("Collection 5", "Top by Genre 2"),
            ShowcaseCollection5_Thumbnail: settingsStore.get("Collection 5 - Thumbnail", "Wide"),
            ShowcaseCollection5_Size:      settingsStore.get("Collection 5 - Size", "Large"),
            ShowcaseCollection5_Ratio:     settingsStore.get("Collection 5 - Ratio", "0.55"),
            ShowcaseCollection6:           settingsStore.get("Collection 6", "Top by Developer"),
            ShowcaseCollection6_Thumbnail: settingsStore.get("Collection 6 - Thumbnail", "Square"),
            ShowcaseCollection6_Size:      settingsStore.get("Collection 6 - Size", "Large"),
            ShowcaseCollection6_Ratio:     settingsStore.get("Collection 6 - Ratio", "0.66"),
            GridRatio:                     settingsStore.get("Grid Ratio", "0.66"),
            ColorBackground:               (api.memory.has("Color Background") && api.memory.get("Color Background") !== "Gradient") ? api.memory.get("Color Background") : "Black",
            XboxLogo:                      settingsStore.get("Xbox Logo", "Logo1"),
            LogoColorMatch:                settingsStore.get("Logo Color Match", "No"),
            BoxArtStyle:                   settingsStore.get("Box Art", "3D"),
            GameCounter:                   settingsStore.get("Game Counter", "Yes"),
            CarouselVideo:                 settingsStore.get("Video", "Yes"),
            CarouselScreenshots:           settingsStore.get("Screenshots", "Yes"),
            CarouselTitleScreen:           settingsStore.get("Title Screen", "Yes"),
            CarouselFanart:                settingsStore.get("Fanart", "Yes"),
            Carousel3DBox:                 settingsStore.get("3D Box", "Yes"),
            Carousel2DBox:                 settingsStore.get("2D Box", "Yes"),
            CarouselBackBox:               settingsStore.get("Back Box", "Yes"),
            CarouselCartridge:             settingsStore.get("Cartridge", "Yes"),
            CarouselMiximage:              settingsStore.get("Miximage", "Yes"),
            CarouselWheel:                 settingsStore.get("Logo", "Yes"),
            OmitApplicationFromShowcase:   settingsStore.get("Omit genre: Application from Showcase", "No"),
            OmitEmulatorFromShowcase:      settingsStore.get("Omit genre: Emulator from Showcase", "No"),
            HighQualityMode:               settingsStore.get("High Quality Mode", "No"),
            PlatformShoulderButtons:       settingsStore.get("LB/RB Function", "Cycle Platforms"),
            DynamicBackground:             settingsStore.get("Dynamic Background", "No"),
            ScreenshotFallback:            settingsStore.get("Screenshot Fallback", "No"),
            AddedAppLaunch:                settingsStore.get("Added App Launch", "Instant"),
            HideAndroidSystemTile:         settingsStore.get("Hide Android System Tile", "Yes"),
            HideAndroidGamesSystemTile:    settingsStore.get("Hide Android Games System Tile", "No"),
            MoreByGenreDisplay:            settingsStore.get("More by Genre Display", "Full"),
            AllowDiscoverVideoAudio:         settingsStore.get("Discover video audio", "Yes"),
            MenuSounds:                      settingsStore.get("Menu sounds", "Yes"),
            MenuVolume:                      settingsStore.get("Menu Volume", "1.0"),
            StartupChime:                    settingsStore.get("Start up chime", "Yes"),
            AllGamesVideoPreview:            settingsStore.get("AllGames Video preview", "Yes"),
            AllGamesView:                  settingsStore.get("All Games View", "List"),
            AllGamesTileStyle:             settingsStore.get("AllGames Tile Style", "Wide"),
            AllGamesTileRatio:             settingsStore.get("AllGames Tile Ratio", "0.66"),
            AllGamesTileArt:               settingsStore.get("AllGames Tile Art", "Fanart"),
            AllGamesTileLogo:              settingsStore.get("AllGames Tile Logo", "Yes"),
            AllGamesColumns:               settingsStore.get("AllGames Items per row", "5"),
            AllGamesMatchPlatform:         settingsStore.get("AllGames Match Platform", "No"),
            SystemTileTitles:              settingsStore.get("System tile titles", "On focus"),
            PerSystemTiles:                settingsStore.get("Per-system tile settings", "No"),
            GridDimming:                   settingsStore.get("Grid background dimming", "Light"),
            GridFade:                      settingsStore.get("Bottom fade", "Strong"),
            AllGamesHideBoxOnVideo:          settingsStore.get("AllGames Hide box art on video", "No"),
            AllGamesHideLogoOnVideo:         settingsStore.get("AllGames Hide logo on video", "No"),
            AllGamesBlurBackground:          settingsStore.get("AllGames Blur Background", "No"),
            AllGamesScanlines:               settingsStore.get("AllGames Show scanlines", "No"),
            AllGamesVideoAudio:              settingsStore.get("All games menu video audio", "Yes"),
            ShowWifi:                      settingsStore.get("Show WiFi Indicator", "Yes"),
            ShowBattery:                   settingsStore.get("Show Battery Percentage", "Battery Only"),
            ShowClock:                     settingsStore.get("Show Clock", "12hr")
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
    // Also false while the app drawer is open: every video player already
    // pauses on this flag, so folding the drawer in here silences and pauses
    // all of them at once with no per-player changes. They resume on close.
    // Qt.application.state alone has proved unreliable on Android: swapping
    // apps doesn't always move it off ApplicationActive, so players kept
    // running in the background. Window.active is a second, independent
    // signal for the same thing.
    //
    // It is only trusted once it has been true at least once. If a platform
    // never reports it, windowSeenActive stays false and the expression falls
    // back to the old behaviour instead of silencing everything forever.
    property bool windowSeenActive: false
    onActiveFocusChanged: {
        if (Window.active) windowSeenActive = true;
        if (activeFocus && !themeSeenFocused) { startupChimeTimer.start(); homeDataTimer.start(); }   // theme just appeared
        if (activeFocus) themeSeenFocused = true;   // see appActive
    }
    Connections {
        target: root.Window.window
        function onActiveChanged() { if (root.Window.active) root.windowSeenActive = true; }
    }

    // Also false while Pegasus' own menu (its Settings) is open over the
    // theme: focus then leaves the theme, so every preview pauses, audio and
    // all, and resumes when the menu closes. Only trusted once the theme has
    // had focus, like windowSeenActive above.
    property bool themeSeenFocused: false
    readonly property bool appActive: Qt.application.state === Qt.ApplicationActive
                                      && (!windowSeenActive || Window.active)
                                      && (!themeSeenFocused || activeFocus)
                                      && !drawerOpen

    // ── Playback coordinator ──────────────────────────────────────────────
    // Names the ONE screen whose video players are allowed to run right now,
    // or "" for none. Every player asks a single question — "am I the owner?"
    // — instead of each re-deriving the rule from activeScreen + appActive +
    // its own guesses. Before this, that rule lived in eight places and every
    // playback regression came from one of them disagreeing with the rest.
    //
    // To add a global rule (pause while the keyboard is up, a mute switch),
    // change THIS line. Nothing else needs to know.
    readonly property string playbackOwner: appActive ? state : ""

    // ── High Quality Mode ─────────────────────────────────────────────────
    // One toggle, off by default, bundling extras that only capable devices
    // should pay for. Consumers read these knobs rather than the raw setting,
    // so what the toggle means is defined here and nowhere else. Every knob is
    // a value that already existed as a literal — this only lifts them out.
    // Read from the settings snapshot on purpose: this needs a reload, and
    // switching decoder policy live is exactly what fails in odd ways.
    readonly property bool hqMode: settings.HighQualityMode === "Yes"

    // Dynamic Background: the fanart drifts (slow zoom + pan). Available in
    // both modes. In base the fanart decodes a touch larger when it's on, so
    // the 1.08 zoom doesn't soften a 0.6 decode further; HQ is full-res anyway.
    readonly property bool dynamicBg:   settings.DynamicBackground === "Yes"
    readonly property int  dynamicBgMs: 24000
    readonly property real dynamicBgZoom: 1.12    // 6% headroom each side
    readonly property real dynamicBgPan:  0.03    // ±3% of the frame (was 2.5%): a slight bump, inside that headroom
    // Alternates each time a drift starts, so consecutive images move the
    // opposite way: one zooms in, the next zooms out.
    property bool dynamicBgFlip: false

    // ONE definition of "this game's Showcase background". The crossfade, the
    // system-tile randomiser and the HQ prefetcher all use it, so they can't
    // disagree about which image a game has — and Screenshot Fallback lands in
    // all three at once.
    function fanartFor(game) {
        if (!game || !game.assets) return "";
        if (game.assets.background) return game.assets.background;
        if (settings.ScreenshotFallback === "Yes"
            && game.assets.screenshots && game.assets.screenshots.length)
            return game.assets.screenshots[0];
        return "";
    }
    readonly property real hqFanartScale:   hqMode ? 1.0 : (dynamicBg ? 0.7 : 0.6)   // fanart decode vs display size
    readonly property bool hqDualDecoder:   hqMode                // featured box keeps playing under a row preview
    // Row/grid preview: how long a tile rests before its video plays, and how
    // far ahead of that the decoder warms. The lead is always 300ms short of
    // the delay in HQ: warming from the very first instant put the row's
    // decoder init in the same frame as the featured box's cold start, and
    // two cold inits at once can fail one of them on Android.
    readonly property int  hqPreviewDelay:  hqMode ? 1500 : 2500  // ms rest before the preview plays
    readonly property int  hqPreviewWarmup: hqMode ? 1200 : 1000  // ms ahead of reveal the decoder warms

    // Phase A extras. All read by consumers; OFF side is today's behaviour.
    readonly property bool hqFadeIn:        hqMode                // images dissolve in on load
    // The highlighted tile stays at 1.0: its video lives in ItemHighlight,
    // which is sized to the cell and does not scale, so growing the tile
    // opened a gap between the accent frame and the video. HQ instead makes
    // the neighbours recede further, which reads as the same emphasis.
    readonly property real hqRestScale:     hqMode ? 0.92 : 0.95  // unhighlighted row tile scale
    readonly property bool hqResidentRows:  hqMode                // build whole rows up front

    // Phase B
    readonly property bool hqPrefetch:      hqMode                // decode neighbours' fanart ahead of time
    readonly property int  hqFanartFadeMs:  hqMode ? 1100 : 700   // fanart crossfade
    readonly property int  hqBgFadeMs:      hqMode ? 650  : 400   // custom background fade
    readonly property real hqIconScale:     hqMode ? 2.0  : 1.4   // drawer icon decode multiplier
    // Tile art decodes at the TILE's size (times this), capped at hqTileArtPx.
    // It used to be a fixed 512/1024 regardless of tile size — far more than a
    // small grid tile can show (an 8-column tile is ~240px), and slightly
    // less than a big Showcase row tile wants. Nothing on screen changes;
    // only the wasted pixels go. Extra room covers the focus pop.
    readonly property real hqTileDecodeScale: hqMode ? 1.5 : 1.25
    readonly property int  hqTileArtPx:     hqMode ? 1024 : 512   // hard cap on that decode
    // Showcase app-tile backdrop. Kept LIGHT: at the old 48/64 the icon behind
    // the tile dissolved into a colour wash. A gentler blur keeps its shape
    // readable while still reading as a backdrop rather than a second icon.
    readonly property int  hqAppBlurRadius: hqMode ? 30   : 22    // app-tile backdrop blur (cap 64)
    readonly property int  hqAppBlurSrcPx:  hqMode ? 256  : 192   // app-tile backdrop decode edge
    readonly property real hqAppTileScrim:  0.30                  // dark wash over it (was 0.42)

    // Phase C
    readonly property bool hqDrawerBlur:    hqMode                // blurred screen behind the app drawer
    readonly property int  hqDrawerSlideMs: hqMode ? 320  : 220   // drawer slide duration
    readonly property bool hqAllGamesWarm:  hqMode                // warm the All Games preview during its rest
    // (No halo size knob: the halo PNG's transparent centre is cut for exactly
    // 1.1228x the tile, so any other scale puts the glow's inner edge onto the
    // tile itself. Scaling it broke the halo — leave it at the asset's ratio.)

    // The loader currently on screen — the thing the drawer blur snapshots.
    // Never the root (that would include the drawer and the blur itself).
    readonly property Item activeScreenItem: {
        switch (state) {
        case "showcasescreen":        return showcaseLoader;
        case "allgamesscreen":        return allgamesloader;
        case "gameviewscreen":        return gameviewloader;
        case "settingsscreen":        return settingsloader;
        case "achievementsscreen":    return achievementsloader;
        case "gameachievementsscreen":return gameachievementsloader;
        case "raentryscreen":         return raentryloader;
        case "discoverscreen":        return discoverviewloader;
        default:                      return null;
        }
    }

    // One definition of the fanart decode size, used by the crossfade layers
    // AND the prefetcher. They must match exactly, or a prefetched image lands
    // in a different cache entry and the crossfade decodes it all over again.
    readonly property size fanartDecodeSize: Qt.size(Math.round(width  * hqFanartScale),
                                                     Math.round(height * hqFanartScale))
    readonly property int  hqCacheTiles:    hqMode ? 4    : 2     // off-screen row tiles pre-decoded

    // All Games Menu
    readonly property int  hqAllGamesVideoMs: hqMode ? 800  : 2000 // rest before the preview video plays
    readonly property int  hqAllGamesArtMs:   hqMode ? 60   : 150  // rest before heavy art swaps in
    readonly property int  hqAllGamesCacheRows: hqMode ? 4  : 0    // off-screen list rows kept built

    // Phase 2 — within the Showcase, the featured box yields to a row preview.
    // Count of row previews currently loaded on the Showcase (0 or 1 in
    // practice; a counter so an overlap during a row change can't leave it
    // wrong). While non-zero the featured video pauses, so the Showcase never
    // runs two decoders at once — the guarantee that matters on weaker chips.
    property int showcaseRowPreviews: 0

    // True while a row preview video is actually PLAYING (not just loaded).
    // The tile under it fades its art on this, so the reveal is tied to the
    // first frame rather than to a fixed timer — previously the video ran
    // audibly for ~2.4s behind still-opaque art waiting on a 3s clock.
    property bool rowPreviewPlaying: false

    // ── Discover handoff ──────────────────────────────────────────────────
    // Lets the Showcase featured box (in Discover Videos mode) and the Discover
    // screen pick up where the other left off, in both directions. Whichever
    // side is leaving writes the game and position; whichever side is arriving
    // consumes and clears them. Null game means "nothing to resume — pick
    // randomly as before".
    property var handoffGame: null
    property int handoffPosition: 0
    function takeHandoff() {
        var g = handoffGame;
        handoffGame = null;
        return g;
    }

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

    // ── Android sources: ONE answer to "what is an app" ───────────────────
    // Every Android-side collection, in the order the system row pins them:
    //   "Android" by NAME   - Pegasus's import, plus any collection of yours
    //                         also named "Android" (Pegasus merges them)
    //   shortName android / androidapps (/ apps)  - your app collections
    //   shortName androidgames                    - your game collections
    // Used by the system row (pins + hide options), the launch rule
    // (androidKindOf) and the App Drawer's sources (drawerCollections).
    readonly property var androidAppShortNames:  ["android", "androidapps", "apps"]
    readonly property var androidGameShortNames: ["androidgames"]
    function isAndroidGamesCollection(c) {
        return !!c && !isDrawerCollection(c)
            && androidGameShortNames.indexOf((c.shortName || "").toLowerCase()) >= 0;
    }
    function isAndroidAppsCollection(c) {
        return !!c && !isDrawerCollection(c)
            && androidAppShortNames.indexOf((c.shortName || "").toLowerCase()) >= 0;
    }
    function isAndroidSourceCollection(c) {
        return isDrawerCollection(c) || isAndroidAppsCollection(c) || isAndroidGamesCollection(c);
    }
    readonly property var drawerCollections: {
        var out = [];
        var n = api.collections.count;          // referenced so this re-runs if collections reload
        for (var i = 0; i < n; i++) {
            var c = api.collections.get(i);
            if (isAndroidSourceCollection(c)) out.push(c);
        }
        return out;
    }

    // What an entry is, judged by the collections it's actually IN (not its
    // title, so a ROM that shares a name with an Android game is unaffected):
    //   android:<package> path (Pegasus import)   -> "import"
    //   genre "Application"                        -> "app"
    //   genre "Emulator"                           -> "emulator"
    //   untagged, in an androidgames collection    -> "game"
    //   untagged, in "Android" / android / androidapps -> "app"
    //   anything else                              -> "" (an ordinary game)
    // Genre tags count anywhere in the library, as the Home hide options do.
    function androidKindOf(game) {
        if (!game) return "";
        if (isPegasusImport(game)) return "import";
        if (hasGenre(game, "application")) return "app";
        if (hasGenre(game, "emulator"))    return "emulator";
        if (hasTag(game, "game"))          return "game";   // Pegasus X's Android collection
        var cl = game.collections;
        if (!cl) return "";
        var inGames = false, inApps = false;
        for (var i = 0; i < cl.count; i++) {
            var c = cl.get(i);
            if (isAndroidGamesCollection(c)) inGames = true;
            else if (isDrawerCollection(c) || isAndroidAppsCollection(c)) inApps = true;
        }
        if (inGames) return "game";
        if (inApps)  return "app";
        return "";
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
            // The drawer covers these collections, so their tiles are redundant
            // by default — but only skip them while the settings say so.
            //   Hide Android System Tile       -> "Android" + android/androidapps
            //   Hide Android Games System Tile -> androidgames
            if (settings.HideAndroidSystemTile !== "No"
                && (isDrawerCollection(c) || isAndroidAppsCollection(c))) continue;
            if (settings.HideAndroidGamesSystemTile === "Yes"
                && isAndroidGamesCollection(c)) continue;
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
            // Pinned systems (Android, Android apps, Android games) always lead.
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
    // Android tiles lead the system row, always in this order:
    //   0  "Android"               (Pegasus import, plus yours named "Android")
    //   1  android / androidapps   (your app collections; "apps" kept as an alias)
    //   2  androidgames            (your game collections)
    // Name is checked before shortName: the import's shortName is "android"
    // too, and it must stay first.
    function systemPinRank(sn, nm) {
        var s = (sn || "").toLowerCase();
        var nmm = (nm || "").toLowerCase();
        if (nmm === appsCollectionName.toLowerCase()) return 0;
        if (androidGameShortNames.indexOf(s) >= 0 || nmm === "android games") return 2;
        if (androidAppShortNames.indexOf(s) >= 0 || nmm === "android apps" || nmm === "apps") return 1;
        return -1;
    }
    property var currentGame
    property var launchingGame: null         // game shown on the launch splash
    property var launchingFile: null         // multi-disc: the disc picked before the splash
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

    // The drawer plays two sounds in sequence. Called back-to-back they land on
    // the same instant and sound stacked, so the second is delayed just long
    // enough for the first to be heard as its own note. SoundEffect exposes no
    // duration, hence a fixed gap; adjust interval to taste.
    Timer { id: drawerOpenChime;  interval: 140; onTriggered: playTabRight() }
    Timer { id: drawerCloseChime; interval: 140; onTriggered: playTabLeft()  }

    // ── Multi-disc: ask for the disc BEFORE the launch splash ──────────────
    // Every launch path calls askDisc() first. A game with more than one file
    // opens the disc picker and the launch is replayed once a disc is chosen
    // (discReady lets that second call through); launchDelay then starts the
    // chosen file instead of the game, so Pegasus doesn't ask again.
    property bool discReady: false
    property string discKind: ""
    property var discGame: null
    property var discPrevFocus: null
    function askDisc(game, kind) {
        if (discReady) { discReady = false; return false; }
        launchingFile = null;
        var g = (game !== null && game !== undefined) ? game : currentGame;
        if (!g || !g.files || g.files.count < 2) return false;
        discKind = kind;
        discGame = game;
        discPrevFocus = Window.activeFocusItem;
        playAccept();
        discPicker.openFor(g);
        return true;
    }
    function discChosen(index) {
        var g = (discGame !== null && discGame !== undefined) ? discGame : currentGame;
        launchingFile = g.files.get(index);
        discReady = true;
        if (discKind === "ra")            launchGameFromRA(discGame);
        else if (discKind === "discover") launchGameFromDiscover(discGame);
        else if (discKind === "drawer")   launchAppFromDrawer(discGame);
        else                              launchGame(discGame);
        discReady = false;
    }

    function launchGame(game) {
        if (askDisc(game, "game")) return;
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
        if (askDisc(game, "ra")) return;
        launchingGame = (game !== null) ? game : currentGame;
        launchGameScreen();             // pushes the RA screen onto the history
        navigator.setStack(["showcasescreen"]);  // ...replaced: return to the Showcase
        searchReturnDepth = -1;          // stack rewritten: no search to return to
        raSearchReturn = false;
        saveCurrentState(launchingGame);
        launchDelay.restart();
    }

    // ── Return from a game ────────────────────────────────────────────────
    // Everything needed to come back to the same screen is saved as ONE
    // memory key, "Resume", written once at launch. It used to be ten keys:
    // every api.memory.set rewrites the whole settings file, so a launch
    // cost ten full rewrites right before the game started. Games are saved
    // by identity (system + ROM path + title), not by their position in the
    // library, so a rescan, a late SD card or an import can't bring you back
    // to the wrong game.
    function gameKey(g) {
        if (!g) return null;
        var c = (g.collections && g.collections.count > 0) ? g.collections.get(0).shortName : "";
        var p = (g.files && g.files.count > 0) ? (g.files.get(0).path || "") : "";
        return { c: c, p: p, t: g.title || "" };
    }

    // Finds the games for a list of keys in one pass over the library.
    function resolveGameKeys(keys) {
        var out = [], want = 0;
        for (var k = 0; k < keys.length; k++) { out.push(null); if (keys[k]) want++; }
        for (var i = 0; i < api.allGames.count && want > 0; i++) {
            var g = api.allGames.get(i);
            for (var j = 0; j < keys.length; j++) {
                var key = keys[j];
                if (!key || out[j] || g.title !== key.t) continue;
                var gk = gameKey(g);
                if (gk.p === key.p && gk.c === key.c) { out[j] = g; want--; }
            }
        }
        return out;
    }

    function saveCurrentState(game, fromDrawer) {
        settingsStore.flush();          // pending settings reach disk before the game runs
        var nav = navigator.serialize(gameKey);
        api.memory.set('Resume', {
            v: 1,
            state: nav.state,
            lastState: nav.lastState,
            lastGame: nav.lastGame,
            game: gameKey(game),
            collection: currentCollectionIndex,
            homePrimary: storedHomePrimaryIndex,
            libScope: libraryScope,
            libIndex: storedAllGamesIndex,
            homeSecondary: storedHomeSecondaryIndex,
            collectionGame: storedCollectionGameIndex,
            fromDrawer: !!fromDrawer
        });
    }

    // Pegasus is still running (instant return, the "press any button"
    // fallback, a cancelled splash or a failed launch): nothing to restore.
    // Without this the key outlived the session and the NEXT cold start,
    // possibly days later, jumped back to that old screen.
    function clearResume() {
        if (api.memory.has('Resume')) api.memory.unset('Resume');
    }

    // Read once at startup (api.memory.has isn't a live binding).
    readonly property bool fromGame: api.memory.has('Resume')
    function returnedFromGame() {
        var r = api.memory.get('Resume');
        api.memory.unset('Resume');
        if (!r || r.v !== 1) return;

        var keys = [r.game].concat(r.lastGame || []);
        var games = resolveGameKeys(keys);

        storedHomePrimaryIndex    = r.homePrimary || 0;
        storedHomeSecondaryIndex  = r.homeSecondary || 0;
        currentCollectionIndex    = r.collection || 0;
        storedCollectionGameIndex = r.collectionGame || 0;
        if (r.libIndex !== undefined) storedAllGamesIndex = r.libIndex;
        if (r.libScope !== undefined && r.libScope !== -2) libraryScope = r.libScope;
        if (games[0]) currentGame = games[0];

        var screen = r.state || "showcasescreen";
        var stack  = r.lastState || [];
        // The game is gone (removed, or its SD card isn't mounted): don't
        // land on a details page with no game behind it.
        if (!games[0] && screen === "gameviewscreen") { screen = "showcasescreen"; stack = []; }
        // Saved while the launch splash was up (the normal case): land on the
        // page the game was launched from instead of the splash.
        if (screen === "launchgamescreen") screen = stack.length ? stack.pop() : "showcasescreen";
        // Launched from the app drawer: always land on Home.
        if (r.fromDrawer) { screen = "showcasescreen"; stack = []; }

        navigator.restore(screen, stack, games.slice(1).filter(function(g) { return g !== null; }));
    }

    // Older builds saved ten separate keys (and "To Game"). Removed once,
    // without restoring from them: if they're still here they're stale.
    function dropLegacyResumeKeys() {
        if (!api.memory.has('To Game') && !api.memory.has('savedState')) return;
        ['To Game', 'savedState', 'savedGame', 'savedCollection', 'lastState', 'lastGame',
         'storedHomePrimaryIndex', 'storedHomeSecondaryIndex', 'storedCollectionIndex',
         'storedCollectionGameIndex', 'From App Drawer'].forEach(function(k) {
            if (api.memory.has(k)) api.memory.unset(k);
        });
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
    // Help-bar prompt colour. theme.text goes dark for the White background,
    // but the bar does not always sit on theme.main: Settings draws its own
    // hard-coded dark chrome, and Showcase is covered by fanart / a custom
    // image unless both are off. Passed into the bar from here (like
    // leftPromptNudge) because `root.state` inside ButtonHelpBar.qml is the
    // bar's own root, whose state is always "".
    readonly property color helpPromptColor:
        (state === "settingsscreen")                              ? "#ebebeb"
      : (state === "showcasescreen" && !showcaseWhiteBackground) ? "#ebebeb"
      : theme.text

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

    // All screen changes and the Back history live here (Global/Navigator.qml).
    // root.state follows navigator.current; the screen Loaders key on root.state.
    Navigator {
    id: navigator
        onCurrentChanged: root.state = current
    }

    // ── Library screen ────────────────────────────────────────────────────
    // One screen (AllGamesMenu) for All Games and for a single system:
    // opening a system from Home scopes it to that system. The old Platform
    // page (GridView/, VerticalList/) was removed in build 29.
    // What All Games should show next: a collection index, -1 for All,
    // -2 for "leave it as it is". Bumping the serial makes it look.
    property int libraryScopePending: -2
    property int libraryScopeSerial: 0
    // The scope the Library is showing (-1 = All). Kept here because the
    // All Games screen is unloaded while hidden and rebuilt on return, and
    // the rebuilt one must come back on the same system.
    property int libraryScope: -1
    function requestLibraryScope(idx) { libraryScopePending = idx; libraryScopeSerial++; }

    // Screen switching functions
    function softwareScreen() {
        playAccept();
        searchTerm = "";
        searchMode = "Title";
        genreSelected = [];
        requestLibraryScope(currentCollectionIndex);
        navigator.go("allgamesscreen");
    }

    function showcaseScreen() {
        playAccept();
        navigator.go("showcasescreen");
    }

    function allGamesScreen() {
        playAccept();
        requestLibraryScope(-1);                 // the Library button means All
        if (root.state === "allgamesscreen") return;
        navigator.go("allgamesscreen");
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
        if (navigator.depth > 0)
            navigator.pushGame(currentGame);

        // Push the new game
        if (game !== null)
            currentGame = game;

        navigator.go("gameviewscreen");
    }

    function settingsScreen() {
        playAccept();
        navigator.go("settingsscreen");
    }

    function achievementsScreen() {
        playAccept();
        navigator.go("achievementsscreen");
    }

    // Navigate to RA overview without pushing onto lastState.
    // Used when already inside RA (A from game achievements, or "View Overview"
    // from RAGameEntryView) so B exits RA in one press.
    function achievementsScreenFromGame() {
        playAccept();
        navigator.jump("achievementsscreen");
        // Back on the overview after opening an RA search result: show the
        // results again (B from the game's achievements lands here).
        if (raSearchReturn) {
            raSearchReturn = false;
            reopenLibrarySearch();
        }
    }

    function gameAchievementsScreen() {
        raFromDetails = false;
        navigator.go("gameachievementsscreen");
    }

    // Navigate to game achievements from the RA overview without pushing.
    // Called by AchievementsView so that B always exits RA in one press
    // regardless of whether RA was entered from GameView or Showcase.
    // Set when a game's achievements page was opened straight from Game
    // details (the RA button), so one Back there returns to the details page.
    // Opened from the RA overview instead, Back returns to the overview and a
    // second Back leaves RA.
    property bool raFromDetails: false
    function gameAchievementsScreenFromOverview() {
        raFromDetails = false;
        navigator.jump("gameachievementsscreen");
    }

    // Navigate to GameAchievementsView without pushing onto lastState.
    // Called by RAGameEntryView when a game is found so pressing Back
    // returns directly to wherever RA was entered from.
    function gameAchievementsScreenFromEntry() {
        // Via an RA search pick the entry page was reached from the overview,
        // so Back must return to the search results, not to a details page.
        raFromDetails = !raSearchReturn;
        navigator.jump("gameachievementsscreen");
    }

    function raEntryScreen() {
        navigator.go("raentryscreen");
    }

    // RA entry from the achievements search overlay. Deliberately does NOT
    // push onto lastState: we're already on the RA overview, and B from the
    // achievements page calls achievementsScreenFromGame() to return there
    // directly. Pushing left a stale "achievementsscreen" on the stack, so the
    // next B popped back onto the page you were already on and appeared to do
    // nothing until a third press.
    function raEntryScreenFromSearch() {
        navigator.jump("raentryscreen");
    }

    // Optional 'collection' scopes Discover to a single system (passed from
    // GridView's Discover nav button). Omitted/null => whole-library Discover,
    // same as every other entry point (Showcase, AllGames, GameView).
    property var discoverContext: null
    function discoverScreen(collection) {
        playAccept();
        discoverContext = collection || null;
        navigator.go("discoverscreen");
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

    // True for everything "Added App Launch" governs: your own apps, tagged
    // apps/emulators, and your Android games (androidgames). Pegasus imports
    // are handled before this and always launch straight away.
    //
    // Used to be "title is in the collection named Android", so only your
    // entries merged into "Android" followed the setting — androidgames and
    // android/androidapps collections always opened Details.
    function isAppGame(game) {
        var k = androidKindOf(game);
        return k === "app" || k === "emulator" || k === "game";
    }
    // Live copy of "Added App Launch", like the Home hide options: re-read on
    // every Settings save, so changing it no longer needs a reload.
    readonly property string addedAppLaunchLive: {
        var e = settingsEpoch;
        return settingsStore.get("Added App Launch", "Instant");
    }
    // Apps Pegasus imported on its own have a file path of "android:<package>"
    // and no metadata at all. Apps the user wrote a metadata entry for point at
    // a real file. That prefix is the reliable way to tell the two apart.
    function isPegasusImport(game) {
        if (!game || !game.files || game.files.count < 1) return false;
        return (game.files.get(0).path || "").indexOf("android:") === 0;
    }

    // ── The launch rule, used by every screen ─────────────────────────────
    //   Pegasus import (android:<package>)  -> launch straight away, always
    //   Your apps, tagged apps/emulators and
    //   Android games (see androidKindOf)    -> "Added App Launch" decides
    //   Game                                 -> details, or launch if the
    //                                           screen says so (All Games list)
    // Showcase, Platform page, All Games grid and list all call this, so the
    // behaviour cannot drift between screens.
    function activateGame(game, gamesOpenDetails) {
        if (!game) return;
        if (isPegasusImport(game)) { launchGame(game); return; }
        if (isAppGame(game)) {
            if (addedAppLaunchLive === "Details Page") gameDetails(game);
            else                                           launchGame(game);
            return;
        }
        if (gamesOpenDetails) gameDetails(game); else launchGame(game);
    }
    function openGame(game) { activateGame(game, true); }

    // ── Global library search (Home nav + App Drawer) ─────────────────────
    // One shared LibrarySearch instance (librarySearch, beside the drawer).
    // Choosing a result goes through openGame(): Game Details for games, the
    // usual app rule for apps. B back out of that lands on the results again:
    // searchReturnDepth records the back-stack depth the search was opened
    // at, and previousScreen() reopens the results once the stack unwinds to
    // exactly that depth. -1 = not armed. The two places that rewrite the
    // stack wholesale (drawer Home, RA launch) disarm it.
    property int searchReturnDepth: -1
    property var searchPrevFocus: null
    // Index build waits until a few seconds after startup so it never
    // competes with the first Showcase load; opening sooner builds on demand.
    property bool searchWarmupGo: false
    Timer { interval: 5000; running: true; repeat: false; onTriggered: searchWarmupGo = true }

    // mode "ra": opened from the RA overview (X). Results go to the RA
    // lookup instead of Game Details, and coming back to the overview
    // reopens them (raSearchReturn, see achievementsScreenFromGame()).
    property string librarySearchMode: "global"
    property bool raSearchReturn: false
    function openLibrarySearch(mode) {
        playAccept();
        librarySearchMode = (mode === "ra") ? "ra" : "global";
        searchReturnDepth = -1;
        raSearchReturn = false;
        searchPrevFocus = Window.activeFocusItem;
        librarySearch.openSearch();
    }
    function reopenLibrarySearch() {
        searchPrevFocus = Window.activeFocusItem;
        librarySearch.reopenResults();
    }

    function gameDetailsFromDiscover(game) {
        playAccept();
        if (navigator.depth > 0)
            navigator.pushGame(currentGame);
        if (game !== null)
            currentGame = game;
        navigator.jump("gameviewscreen");
    }

    // Launch a game from DiscoverView without pushing "discoverscreen" onto
    // lastState so that returning from the game skips the Discover screen.
    function launchGameFromDiscover(game) {
        if (game !== null && askDisc(game, "discover")) return;
        if (game !== null) {
            playAccept();
            launchingGame = game;
            launchSuspended = false;
            navigator.jump("launchgamescreen");
            saveCurrentState(game);
            launchDelay.restart();      // hold the splash, then launch (see launchDelay)
        }
    }

    // Drawer launches always come back to the Showcase, wherever they were
    // started from. Flagged in memory rather than by rewriting lastState, so
    // the normal return path is left completely alone.
    function launchAppFromDrawer(game) {
        if (game === null) return;
        if (askDisc(game, "drawer")) return;
        launchingGame = game;
        // MUST go through launchGameScreen(): it pushes the current state onto
        // lastState before switching. Setting root.state directly pushed
        // nothing, so cancelling the splash popped an entry that was never
        // there — the stack emptied and the next cancel had nothing to return
        // to, leaving the launch to go ahead anyway.
        launchGameScreen();
        saveCurrentState(game, true);   // comes back to the Showcase
        launchDelay.restart();
    }

    onStateChanged: {
        settingsStore.flush();          // e.g. leaving Settings: write what was changed
        if (state !== "gameviewscreen") forceFullDetails = false;
    }

    function launchGameScreen() {
        playAccept();
        launchSuspended = false;
        navigator.go("launchgamescreen");
    }

    function previousScreen() {
        playBack();
        // Leaving the launch splash with Pegasus still running (instant
        // return, any-button fallback, cancelled launch): nothing to resume.
        if (state === "launchgamescreen")
            clearResume();

        // B on the RA lookup page after an RA search pick. That entry doesn't
        // push onto lastState (see raEntryScreenFromSearch), so popping here
        // would leave RA altogether — go back to the overview's results.
        if (raSearchReturn && state === "raentryscreen") {
            raSearchReturn = false;
            navigator.jump("achievementsscreen");
            reopenLibrarySearch();
            return;
        }
        raSearchReturn = false;     // any other Back leaves the search behind

        // Guard against an empty stack. Reading past the end sets state to
        // undefined, which leaves the screen stuck exactly where it was.
        // Details opened from details: the game swaps back as the screen does.
        if (!navigator.back(function(g) { currentGame = g; })) {
            searchReturnDepth = -1;
            navigator.home("showcasescreen");
            return;
        }

        // Back at the screen the global search was opened from: show its
        // results again. Anything shallower means the stack was cut past it.
        if (searchReturnDepth >= 0 && navigator.depth <= searchReturnDepth) {
            var reopen = (navigator.depth === searchReturnDepth);
            searchReturnDepth = -1;
            if (reopen) reopenLibrarySearch();
        }
    }

    function popLastGame() {
        var g = navigator.popGame();
        if (g) currentGame = g;
    }

    // Set default state to the platform screen
    Component.onCompleted: { 
        // First line in lastrun.log from the theme: which build, and which
        // Pegasus features it found. Stock Pegasus shows "stock".
        console.log("[XboxOSv2] build " + BuildInfo.build + " (" + BuildInfo.branch + ", " + BuildInfo.date + ")"
            + " | frontend: " + platform.frontendLine
            + " | pdf: " + (platform.hasPdf ? "yes" : "no")
            + " | findManual: " + (platform.hasFindManual ? "yes" : "no")
            + " | " + platform.os + " " + width + "x" + height
            + " | HQ: " + (hqMode ? "on" : "off"));
        // "Gradient" is no longer a color option. Clear it if it was saved, so
        // Settings shows the default color instead of the last one in the list.
        ["Color Background", "Color Layout"].forEach(function(k) {
            if (api.memory.has(k) && api.memory.get(k) === "Gradient") {
                api.memory.unset(k);
                api.memory.unset(k + "Index");
            }
        });
        rebuildHomeHide();      // first fill, before the Home rows filter
        navigator.home("showcasescreen");

        if (!introLoader.active) homeDataReady = true;   // no intro: lists build now, before the theme shows
        dropLegacyResumeKeys();
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

    Loader  {
    id: showcaseLoader

        readonly property bool shown: (root.state === "showcasescreen")
        focus: shown
        opacity: shown ? 1 : 0
        // Hidden once faded out: the Home screen stays loaded under every
        // other screen, and while "visible" its pulses, marquees and
        // bindings kept running (and redrawing) behind them.
        visible: shown || opacity > 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: showcaseview
        // Built in the background when the startup intro covers it. Pegasus
        // keeps its own splash up until everything the theme builds
        // synchronously is done, so a synchronous Home held the Pegasus logo
        // on screen for seconds. Without the intro (setting off, or coming
        // back from a game) Home is still built before the theme shows.
        asynchronous: introLoader.active
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
        function onStateChanged() {
            // Android may kill a backgrounded Pegasus without warning
            if (Qt.application.state !== Qt.ApplicationActive) settingsStore.flush();
            if (root.state !== "launchgamescreen") return;
            if (Qt.application.state !== Qt.ApplicationActive)
                root.launchSuspended = true;
            else if (root.launchSuspended) {
                root.launchSuspended = false;
                previousScreen();
            }
        }
    }

    // A launch that fails (app not installed, bad launch command) never
    // leaves Pegasus: drop the resume key and leave the splash. Pegasus
    // shows its own error dialog on top.
    Connections {
        target: api
        onEventLaunchError: {
            if (root.state !== "launchgamescreen") return;
            launchDelay.stop();
            previousScreen();
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
            if (root.state !== "launchgamescreen" || !launchingGame) return;
            if (launchingFile) {
                var file = launchingFile;   // the disc picked before the splash
                launchingFile = null;
                file.launch();
            } else {
                launchingGame.launch();
            }
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
        leftPromptText: (drawerOpen || hideAppsPrompt) ? "" : "Apps"
        // Path is relative to ButtonHelpBar.qml, NOT this file: the string is
        // converted to a url by the `source:` binding inside that component, so
        // it resolves against that component's folder. Same "../" the delegate
        // beside it uses.
        leftPromptIcon: "../assets/images/icon_select.svg"
        // The three RetroAchievements pages draw their prompts lower; Apps follows.
        leftPromptNudge: (root.state === "achievementsscreen"
                          || root.state === "gameachievementsscreen"
                          || root.state === "raentryscreen") ? vpx(12) : 0
        promptColor: helpPromptColor
    }

    // ── App drawer ────────────────────────────────────────────────────────
    // ── Mouse back / right button ────────────────────────────────────────
    // Every screen's full-screen blocker MouseArea takes Qt.AllButtons and
    // discards what it doesn't use, so a mouse Back button was swallowed
    // before it reached anything. This sits above them all and accepts ONLY
    // the back and right buttons — left clicks, touch, hover and wheel pass
    // straight through, so nothing else changes.
    //
    // Remove Qt.RightButton below to make it thumb-button only.
    readonly property int mouseBackButtons: Qt.BackButton | Qt.RightButton

    function mouseBack() {
        // Global search mirrors B: results -> back to the keyboard, keyboard -> close.
        if (librarySearch.open) {
            playBack();
            if (librarySearch.showingResults) librarySearch.resetSearch();
            else                              librarySearch.closeSearch();
            return;
        }
        if (drawerOpen) { closeAppDrawer(); return; }
        if (state === "launchgamescreen") { previousScreen(); return; }
        // Otherwise hand it to the screen showing, if it knows what B means.
        var scr = activeScreenItem ? activeScreenItem.item : null;
        if (scr && typeof scr.mouseBack === "function") scr.mouseBack();
    }

    // Frame rate counter (Settings > Appearance > Diagnostics). Top-left,
    // above everything. Exists only while switched on.
    Loader {
        active: frameCounterLive
        z: 2000
        anchors { left: parent.left; top: parent.top; margins: vpx(8) }
        sourceComponent: Component { FrameCounter { } }
    }

    MouseArea {
        anchors.fill: parent
        z: 1000
        acceptedButtons: root.mouseBackButtons
        propagateComposedEvents: true
        onPressed:  mouse.accepted = true
        onReleased: { mouse.accepted = true; root.mouseBack(); }
    }

    // ── HQ: blurred screen behind the app drawer ─────────────────────────
    // A one-time SNAPSHOT of the current screen, blurred, faded in with the
    // drawer's slide. Snapshot rather than live: a live full-screen FastBlur
    // is a blur pass every frame; this is one pass per open. Fail-safe: if
    // FastBlur can't render on a GPU the layer is simply transparent and the
    // drawer looks as it does today. Sits just under the drawer (z 499).
    Loader {
        anchors.fill: parent
        z: 499
        active: hqDrawerBlur
        sourceComponent: Item {
            visible: drawerSlide > 0.001
            opacity: drawerSlide
            ShaderEffectSource {
            id: drawerSnap
                anchors.fill: parent
                sourceItem: activeScreenItem
                // Live only while the drawer is sliding open, then frozen. A
                // single capture at the open instant caught the highlighted
                // tile mid-transition: its art was still faded out under the
                // preview video, and the video had just been torn down — so
                // the snapshot held an empty tile for as long as the drawer
                // stayed open. The slide is longer than the art's 200ms
                // restore, so by the time this freezes the tile is whole.
                live: drawerOpen && drawerSlide < 1
                hideSource: false
                visible: false
            }
            FastBlur {
                anchors.fill: parent
                source: drawerSnap
                radius: 48
                cached: true
            }
            // Capture the instant the drawer starts opening, before it slides
            // over the screen. live:false means this is the only capture.
            Connections {
                target: root
                onDrawerOpenChanged: if (drawerOpen) drawerSnap.scheduleUpdate()
            }
        }
    }

    // One instance at the top level so it overlays every screen. z sits above
    // launchgameloader (z: 100) and the help bar so nothing draws over it.
    // The drawer's DATA (app index, categories, favourites, hidden lists) is
    // always here: the Home and library hide sets are built from it at
    // startup. Global/AppLibrary.qml.
    AppLibrary {
    id: appLib
        // Same constant the system-row filter uses, so the collection the
        // drawer shows is exactly the one hidden from the row — they can't
        // drift apart.
        collectionMatch: root.appsCollectionName
        // Every Android source: "Android" plus your android / androidapps /
        // androidgames collections. An explicit list wins over collectionMatch,
        // which stays only as the fallback when none of them exist.
        collections: drawerCollections
    }

    // The drawer's SCREEN is created the first time it's opened (it used to be
    // built at startup, 1,700 lines of QML nobody sees until they press the
    // button) and kept from then on. Everything that used to read appDrawer
    // reads these instead; they're safe before the first open.
    readonly property bool drawerOpen:  appDrawerLoader.item ? appDrawerLoader.item.open  : false
    readonly property real drawerSlide: appDrawerLoader.item ? appDrawerLoader.item.slide : 0
    function openAppDrawer() {
        if (!appDrawerLoader.active) appDrawerLoader.active = true;   // built synchronously
        appDrawerLoader.item.openDrawer();
    }
    function closeAppDrawer() {
        if (appDrawerLoader.item) appDrawerLoader.item.closeDrawer();
    }

    Loader {
    id: appDrawerLoader
        anchors.fill: parent
        z: 500
        active: false
        sourceComponent: appDrawerComponent
    }

    Component {
    id: appDrawerComponent

    AppDrawer {
        lib: appLib
        title: "My games & apps"

        // Reuses the Discover launch path, which deliberately does NOT push
        // onto lastState — so coming back from an app returns to the screen
        // that was showing, rather than re-entering wherever the drawer was
        // opened from.
        onAppChosen: launchAppFromDrawer(game)
        // Dismissal (B / Select / scrim): back, then the slide. Navigation
        // (Home, Library, Discover, RA, Settings): the destination plays its
        // own accept, so only the slide is added here — a back sound as well
        // was landing on top of that accept.
        onClosed: {
            if (byUser) playBack();
            drawerCloseChime.restart();
            if (homeHidePending) homeHideAfterDrawer.restart();
        }

        // Home resets the back stack rather than pushing onto it — otherwise
        // backing out of the Showcase would return to whatever screen you were
        // on when you opened the drawer, which isn't what "Home" means. Seeded
        // rather than emptied because previousScreen() reads the top of the
        // stack without checking it's non-empty.
        onNavHome: {
            if (root.state === "showcasescreen") return;
            playAccept();
            navigator.home("showcasescreen");
            searchReturnDepth = -1;     // history cleared: no search to return to
            raSearchReturn = false;
        }
        // Library pushes normally, so Back returns where you came from.
        onNavLibrary: {
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
        // Search opens the shared overlay on top of whatever screen is
        // showing; the drawer has already handed focus back by this point,
        // so the search captures the right item to return to.
        onNavSearch: openLibrarySearch()
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
    }

    // Disc picker for multi-disc games, shown before the launch splash (see
    // askDisc). Above the drawer and search so a launch from either works.
    DiscPicker {
    id: discPicker

        z: 700
        onChosen: discChosen(index)
        onClosed: {
            if (discPrevFocus) {
                discPrevFocus.forceActiveFocus();
            } else {
                var s = root.state;
                root.state = "";
                root.state = s;
            }
            discPrevFocus = null;
        }
    }

    // Global library search. Above the drawer (500) and its blur (499) so it
    // can be opened from a drawer tile; below the mouse-back catcher (1000).
    // Focus goes back to whatever had it, the same way the drawer does it,
    // with the same state re-apply as the fallback.
    LibrarySearch {
    id: librarySearch

        z: 600
        title: librarySearchMode === "ra" ? "RA SEARCH" : "SEARCH LIBRARY"
        warmup: searchWarmupGo
        onClosed: {
            if (searchPrevFocus) {
                searchPrevFocus.forceActiveFocus();
            } else {
                var s = root.state;
                root.state = "";
                root.state = s;
            }
            searchPrevFocus = null;
        }
        onChosen: {
            // RA mode: hand the game to the RA lookup, same as the old
            // page-level search; the way back is raSearchReturn.
            if (librarySearchMode === "ra") {
                currentGame = game;
                raSearchReturn = true;
                raEntryScreenFromSearch();
                return;
            }
            // From Game Details itself the page just swaps games (gameDetails
            // doesn't push), so there's no separate screen to come back to.
            if (root.state !== "gameviewscreen")
                searchReturnDepth = navigator.depth;
            openGame(game);
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
    property bool logCollections: false

    Keys.onPressed: {
        if (event.isAutoRepeat) return;

        if (logKeys)
            console.log("[theme] key code:", event.key, "text:", event.text);

        if (appDrawerKeys.indexOf(event.key) === -1) return;
        event.accepted = true;
        if (librarySearch.open) return;   // no drawer over an open search
        if (drawerOpen) {
            closeAppDrawer();
        } else {
            playAccept();
            drawerOpenChime.restart();    // tabRight follows once accept has sounded
            openAppDrawer();
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
        // Started the first time the theme gets focus: that is when Pegasus
        // hides its own splash and the theme appears. Starting at load (as
        // before) fired while Pegasus' splash was still on screen.
        id: startupChimeTimer
        interval: 150; running: false; repeat: false
        // With the intro on, the chime waits for the fade into Home (onRevealing)
        onTriggered: if (!introLoader.active) playStartupChime()
    }
    // Safety net: a platform that never reports focus still gets its chime.
    Timer {
        interval: 5000; running: true; repeat: false
        onTriggered: { homeDataReady = true; if (!introLoader.active) playStartupChime(); }
    }
    property bool startupChimeDone: false
    function playStartupChime() {
        if (startupChimeDone) return;
        startupChimeDone = true;
        if (settings.StartupChime !== "No" && sfxVolume > 0) { sfxStartup.stop(); sfxStartup.play(); }
    }

    // ── Startup intro ─────────────────────────────────────────────────────
    // Cold start only (never on the way back from a game). Settings > Audio >
    // Startup intro. See Global/StartupIntro.qml.
    // Settings > Tiles > Tile frame: Classic or Xbox (Global/FocusFrame.qml).
    // Live, so the two can be compared without a reload.
    readonly property bool xboxFrameLive: { var e = settingsEpoch; return settingsStore.get("Tile frame") === "Xbox"; }

    // Settings > Tiles > Tile Halo, live. In Xbox mode it switches the
    // frame's glow (Global/FocusFrame.qml); in Classic, the halo image.
    readonly property bool tileHaloLive: { var e = settingsEpoch; return settingsStore.get("Tile Halo") === "Yes"; }

    property bool introDone: false
    // The game lists behind the Home rows (Lists/*.qml) filter and sort the
    // whole library, ~1.5 s on the test machine, and all of it ran before
    // Pegasus would hide its splash. With the intro on, they start right
    // after the theme appears, behind the intro, which waits for them.
    // Without the intro they start at load, as before.
    property bool homeDataReady: false
    Timer { id: homeDataTimer; interval: 50; onTriggered: homeDataReady = true }
    Loader {
    id: introLoader
        anchors.fill: parent
        z: 10000
        active: !introDone && !fromGame && settingsStore.get("Startup intro") === "Yes"
        sourceComponent: StartupIntro {
            volume: sfxVolume
            homeReady: showcaseLoader.status === Loader.Ready && homeDataReady
            onFinished: introDone = true
            onRevealing: playStartupChime()     // chime as the intro fades into Home
        }
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
