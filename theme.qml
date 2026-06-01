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
    property var settings: {
        return {
            PlatformView:                  api.memory.has("Game View") ? api.memory.get("Game View") : "Grid",
            GridThumbnail:                 (function(){ var v = api.memory.has("Grid Thumbnail") ? api.memory.get("Grid Thumbnail") : "Dynamic Wide"; return (v === "3D Box" || v === "Box Art") ? "Square" : v; })(),
            GridArt:                       api.memory.has("Grid art") ? api.memory.get("Grid art") : "Fanart",
            GridGameLogo:                  api.memory.has("Grid Game Logo") ? api.memory.get("Grid Game Logo") : "Yes",
            GridColumns:                   api.memory.has("Number of columns") ? api.memory.get("Number of columns") : "3",
            GameBackground:                api.memory.has("Game Background") ? api.memory.get("Game Background") : "Screenshot",
            GameLogo:                      api.memory.has("Game Logo") ? api.memory.get("Game Logo") : "Show",
            GameRandomBackground:          api.memory.has("Randomize Background") ? api.memory.get("Randomize Background") : "No",
            GameBlurBackground:            api.memory.has("Blur Background") ? api.memory.get("Blur Background") : "No",
            VideoPreview:                  api.memory.has("Video preview") ? api.memory.get("Video preview") : "Yes",
            AllowThumbVideo:               api.memory.has("Allow video thumbnails") ? api.memory.get("Allow video thumbnails") : "Yes",
            AllowThumbVideoAudio:          api.memory.has("Play video thumbnail audio") ? api.memory.get("Play video thumbnail audio") : "No",
            HideLogo:                      api.memory.has("Hide logo when thumbnail video plays") ? api.memory.get("Hide logo when thumbnail video plays") : "No",
            HideButtonHelp:                api.memory.has("Hide button help") ? api.memory.get("Hide button help") : "No",
            ColorLayout:                   api.memory.has("Color Layout") ? api.memory.get("Color Layout") : "Dark Green",
            MouseHover:                    api.memory.has("Enable mouse hover") ? api.memory.get("Enable mouse hover") : "No",
            AlwaysShowTitles:              api.memory.has("Always show titles") ? api.memory.get("Always show titles") : "No",
            AnimateHighlight:              api.memory.has("Animate highlight") ? api.memory.get("Animate highlight") : "No",
            AllowVideoPreviewAudio:        api.memory.has("Video preview audio") ? api.memory.get("Video preview audio") : "No",
            ShowScanlines:                 api.memory.has("Show scanlines") ? api.memory.get("Show scanlines") : "Yes",
            DetailsDefault:                api.memory.has("Default to full details") ? api.memory.get("Default to full details") : "No",
            ShowcaseBackgroundArt:          api.memory.has("Showcase Background Art") ? api.memory.get("Showcase Background Art") : "Yes",
            CustomBackground:               api.memory.has("Custom Background") ? api.memory.get("Custom Background") : "No",
            ShowcaseBackgroundOpacity:     api.memory.has("Showcase Background Opacity") ? api.memory.get("Showcase Background Opacity") : "0.55",
            ShowcaseArt:                   api.memory.has("Showcase Art") ? api.memory.get("Showcase Art") : "Fanart",
            HeroBoxArt:                    api.memory.has("Hero box art") ? api.memory.get("Hero box art") : "Fanart",
            ShowcaseColumns:               api.memory.has("Number of games showcased") ? api.memory.get("Number of games showcased") : "15",
            ShowcaseFeaturedCollection:    api.memory.has("Featured collection") ? api.memory.get("Featured collection") : "Favorites",
            ShowcaseCollection1:           api.memory.has("Collection 1") ? api.memory.get("Collection 1") : "Recently Played",
            ShowcaseCollection1_Thumbnail: api.memory.has("Collection 1 - Thumbnail") ? api.memory.get("Collection 1 - Thumbnail") : "Wide",
            ShowcaseCollection2:           api.memory.has("Collection 2") ? api.memory.get("Collection 2") : "Most Played",
            ShowcaseCollection2_Thumbnail: api.memory.has("Collection 2 - Thumbnail") ? api.memory.get("Collection 2 - Thumbnail") : "Tall",
            ShowcaseCollection3:           api.memory.has("Collection 3") ? api.memory.get("Collection 3") : "Top by Publisher",
            ShowcaseCollection3_Thumbnail: api.memory.has("Collection 3 - Thumbnail") ? api.memory.get("Collection 3 - Thumbnail") : "Wide",
            ShowcaseCollection4:           api.memory.has("Collection 4") ? api.memory.get("Collection 4") : "Top by Genre",
            ShowcaseCollection4_Thumbnail: api.memory.has("Collection 4 - Thumbnail") ? api.memory.get("Collection 4 - Thumbnail") : "Tall",
            ShowcaseCollection5:           api.memory.has("Collection 5") ? api.memory.get("Collection 5") : "None",
            ShowcaseCollection5_Thumbnail: api.memory.has("Collection 5 - Thumbnail") ? api.memory.get("Collection 5 - Thumbnail") : "Wide",
            ShowcaseCollection6:           api.memory.has("Collection 6") ? api.memory.get("Collection 6") : "None",
            ShowcaseCollection6_Thumbnail: api.memory.has("Collection 6 - Thumbnail") ? api.memory.get("Collection 6 - Thumbnail") : "Wide",
            WideRatio:                     api.memory.has("Wide - Ratio") ? api.memory.get("Wide - Ratio") : "0.64",
            ColorBackground:               api.memory.has("Color Background") ? api.memory.get("Color Background") : "Black",
            XboxLogo:                      api.memory.has("Xbox Logo") ? api.memory.get("Xbox Logo") : "Logo1",
            LogoColorMatch:                api.memory.has("Logo Color Match") ? api.memory.get("Logo Color Match") : "No",
            TallRatio:                     api.memory.has("Tall - Ratio") ? api.memory.get("Tall - Ratio") : "0.66",
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
            MoreByGenreDisplay:            api.memory.has("More by Genre Display") ? api.memory.get("More by Genre Display") : "Full",
            AllowDiscoverVideoAudio:         api.memory.has("Play discover video audio") ? api.memory.get("Play discover video audio") : "No",
            MenuSounds:                      api.memory.has("Menu sounds") ? api.memory.get("Menu sounds") : "Yes",
            MenuVolume:                      api.memory.has("Menu Volume") ? api.memory.get("Menu Volume") : "1.0",
            StartupChime:                    api.memory.has("Start up chime") ? api.memory.get("Start up chime") : "Yes",
            AllGamesVideoPreview:            api.memory.has("AllGames Video preview") ? api.memory.get("AllGames Video preview") : "Yes",
            AllGamesHideArtOnVideo:          api.memory.has("AllGames Hide art on video") ? api.memory.get("AllGames Hide art on video") : "No",
            AllGamesBlurBackground:          api.memory.has("AllGames Blur Background") ? api.memory.get("AllGames Blur Background") : "No",
            AllGamesScanlines:               api.memory.has("AllGames Show scanlines") ? api.memory.get("AllGames Show scanlines") : "No",
            AllGamesVideoAudio:              api.memory.has("All games menu video audio") ? api.memory.get("All games menu video audio") : "No",
            ShowWifi:                      api.memory.has("Show WiFi Indicator")     ? api.memory.get("Show WiFi Indicator")     : "Yes",
            ShowBattery:                   api.memory.has("Show Battery Percentage") ? api.memory.get("Show Battery Percentage") : "Yes",
            ShowClock:                     api.memory.has("Show Clock")              ? api.memory.get("Show Clock")              : "Yes"
        }
    }


    // Collections
    property int currentCollectionIndex: 0
    property int currentGameIndex: 0
    property var currentCollection: api.collections.get(currentCollectionIndex)    
    property var currentGame

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
        if (game !== null) {
            //if (game.collections.get(0).name === "Steam")
                launchGameScreen();

            saveCurrentState(game);
            game.launch();
        } else {
            //if (currentGame.collections.get(0).name === "Steam")
                launchGameScreen();

            saveCurrentState(currentGame);
            currentGame.launch();
        }
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
            text          = "#101010";
        } else if (settings.ColorBackground === "Silver") {
            background    = "#909090";
            gradientstart = "#00909090";
            gradientend   = "#FF909090";
            text          = "#101010";
        } else if (settings.ColorBackground === "Light Blue") {
            background    = "#4a7aa0";
            gradientstart = "#004a7aa0";
            gradientend   = "#FF4a7aa0";
            text          = "#101010";
        } else if (settings.ColorBackground === "Sage") {
            background    = "#6a8a6a";
            gradientstart = "#006a8a6a";
            gradientend   = "#FF6a8a6a";
            text          = "#101010";
        } else if (settings.ColorBackground === "Tan") {
            background    = "#8a7a5a";
            gradientstart = "#008a7a5a";
            gradientend   = "#FF8a7a5a";
            text          = "#101010";
        } else if (settings.ColorBackground === "Rose") {
            background    = "#a06070";
            gradientstart = "#00a06070";
            gradientend   = "#FFa06070";
            text          = "#101010";
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

        var accent        = "#288928";   // default: Dark Green

        // ── Full color palette ───────────────────────────────────────────
        switch (settings.ColorLayout) {
            // Greens
            case "Dark Green":    accent = "#288928"; break;
            case "Light Green":   accent = "#65b032"; break;
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
            default:              accent = "#288928"; break;
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

    

    property real globalMargin: vpx(30)
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

    function discoverScreen() {
        playAccept();
        lastState.push(state);
        root.state = "discoverscreen";
    }

    // Navigate to game details without pushing "discoverscreen" onto lastState.
    // Called by DiscoverView so that pressing Back in Game Details returns to
    // Showcase (or wherever the user came from) rather than back to Discover.
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
            root.state = "launchgamescreen";
            saveCurrentState(game);
            game.launch();
        }
    }

    function launchGameScreen() {
        playAccept();
        lastState.push(state);
        root.state = "launchgamescreen";
    }

    function previousScreen() {
        playBack();
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

        focus: (root.state === "showcasescreen")
        opacity: focus ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: showcaseview
    }

    Loader {
    id: allgamesloader

        focus: (root.state === "allgamesscreen")
        active: opacity !== 0
        opacity: focus ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: allgamesview
        asynchronous: true
    }

    Loader  {
    id: gridviewloader

        focus: (root.state === "softwaregridscreen")
        active: opacity !== 0
        opacity: focus ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: gridview
        asynchronous: true
    }

    Loader  {
    id: listviewloader

        focus: (root.state === "softwarescreen")
        active: opacity !== 0
        opacity: focus ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: listview
        asynchronous: true
    }

    Loader  {
    id: gameviewloader

        focus: (root.state === "gameviewscreen")
        // Stay alive once loaded: the first visit sets gameviewLoaded = true via onLoaded,
        // after which active is always true so the component is never destroyed.
        // This prevents the blank-screen bug that occurred when returning from Settings
        // (previously, active went false on the opacity fade, which prematurely called
        // popLastGame() and left currentGame pointing at the wrong game).
        active: (root.state === "gameviewscreen") || gameviewLoaded
        onLoaded: gameviewLoaded = true
        opacity: focus ? 1 : 0
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

        focus: (root.state === "launchgamescreen")
        active: opacity !== 0
        opacity: focus ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: launchgameview
        asynchronous: true
    }

    Loader  {
    id: settingsloader

        focus: (root.state === "settingsscreen")
        active: opacity !== 0
        opacity: focus ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: settingsview
        asynchronous: true
    }

    Loader {
    id: achievementsloader

        focus: (root.state === "achievementsscreen")
        active: opacity !== 0
        opacity: focus ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: achievementsview
        asynchronous: true
    }

    Loader {
    id: gameachievementsloader

        focus: (root.state === "gameachievementsscreen")
        active: opacity !== 0
        opacity: focus ? 1 : 0
        Behavior on opacity { PropertyAnimation { duration: transitionTime } }

        anchors.fill: parent
        sourceComponent: gameachievementsview
        asynchronous: true
    }

    Loader {
    id: raentryloader

        focus: (root.state === "raentryscreen")
        active: opacity !== 0
        opacity: focus ? 1 : 0
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

        focus: (root.state === "discoverscreen")
        active: opacity !== 0
        opacity: focus ? 1 : 0
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
    ButtonHelpBar {
    id: buttonbar

        height: vpx(50)
        anchors {
            left: parent.left; right: parent.right; rightMargin: globalMargin
            bottom: parent.bottom
        }
        visible: settings.HideButtonHelp === "No"
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
