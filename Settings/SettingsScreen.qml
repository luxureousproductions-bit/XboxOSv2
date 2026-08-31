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
import "../Global"

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

    ListModel {
    id: settingsModel

        /*ListElement {
            settingName: "Game View"
            setting: "Grid,Vertical List"
        }*/
        ListElement {
            settingName: "Allow video thumbnails"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Hide logo when thumbnail video plays"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Animate highlight"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Tile Halo"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Favorited Tile Accent"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Enable mouse hover"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Always show titles"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Hide button help"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Color Background"
            setting: "Black,Charcoal,Dark Gray,Mid Gray,Navy Blue,Dark Blue,Dark Teal,Dark Green,Forest Green,Dark Red,Burgundy,Dark Purple,Indigo,Dark Brown,Dark Orange,Slate,Midnight Blue,Deep Purple,Dark Steel,Gray,Cool Gray,Steel Blue,Teal,Forest,Wine,Plum,Light Gray,Silver,Light Blue,Sage,Tan,Rose,White,Gradient"
        }
        ListElement {
            settingName: "Color Layout"
            setting: "Dark Green,Light Green,Turquoise,Dark Red,Light Red,Dark Pink,Light Pink,Dark Blue,Light Blue,Navy Blue,Royal Blue,Sky Blue,Ice Blue,Cobalt,Orange,Dark Orange,Amber,Yellow,Gold,Dark Gold,Bronze,Magenta,Hot Pink,Rose,Coral,Salmon,Purple,Dark Purple,Violet,Lavender,Indigo,Maroon,Crimson,Burgundy,Brick Red,Lime,Mint,Sage,Forest Green,Olive,Dark Gray,Mid Gray,Light Gray,Silver,Steel,Slate,Stone,Charcoal,Gunmetal,Tan,Dark Brown,Light Brown,Copper,Rust,Sienna,Cyan,Teal,Dark Teal,Arctic,Seafoam,Ruby,Sapphire,Emerald,Jade,Onyx,White,Gradient"
        }

    }

    property var generalPage: {
        return {
            pageName: "General",
            listmodel: settingsModel
        }
    }

    ListModel {
    id: audioSettingsModel

        ListElement {
            settingName: "Menu sounds"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Start up chime"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Menu Volume"
            setting: "1.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9"
        }
        ListElement {
            settingName: "Video thumbnail audio"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Discover video audio"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Game details video preview audio"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "All games menu video audio"
            setting: "No,Yes"
        }
    }

    property var audioPage: {
        return {
            pageName: "Audio",
            listmodel: audioSettingsModel
        }
    }

    ListModel {
        id: advancedSettingsModel
        ListElement {
            settingName: "Omit genre: Application from Showcase"
            label: "Omit Applications from Showcase"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Omit genre: Emulator from Showcase"
            label: "Omit Emulators from Showcase"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Hide Android System Tile"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Show WiFi Indicator"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Show Battery Percentage"
            setting: "Battery Only,Percentage Only,Combined,No"
        }
        ListElement {
            settingName: "Show Clock"
            setting: "12hr,24hr,No"
        }
        ListElement {
            settingName: "Launch screen delay"
            setting: "2.0,2.5,3.0,3.5,4.0,4.5,5.0,0.5,1.0,1.5"
        }
        ListElement {
            settingName: "UI Scale"
            setting: "1.0,1.1,1.25,1.4,1.5"
        }
    }

    property var advancedPage: {
        return {
            pageName: "Advanced",
            listmodel: advancedSettingsModel
        }
    }

    ListModel {
    id: showcaseSettingsModel

        ListElement {
            settingName: "Xbox Logo"
            setting: "Logo1,Logo2,RetroAchievements,None"
        }
        ListElement {
            settingName: "Logo Color Match"
            label: "Logo Color Layout Match"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Showcase Background Art"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Randomize System Tile Fanart"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Custom Background"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Showcase Background Opacity"
            setting: "0.55,0.60,0.65,0.70,0.75,0.80,0.85,0.90,0.95,1.00,0.10,0.15,0.20,0.25,0.30,0.35,0.40,0.45,0.50"
        }
                ListElement {
            settingName: "Showcase Collections Art"
            setting: "Fanart,Screenshot"
        }
        ListElement {
            settingName: "Hero box art"
            setting: "Fanart,Boxfront,Screenshot"
        }
        ListElement {
            settingName: "System sort"
            setting: "Alphabetical (A-Z),Alphabetical (Z-A),Release year (oldest),Release year (newest),Manufacturer,Game count (most),Game count (fewest),Default"
        }
        ListElement {
            settingName: "Number of games showcased"
            setting: "15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,1,2,3,4,5,6,7,8,9,10,11,12,13,14"
        }

    }

    property var showcasePage: {
        return {
            pageName: "Home page",
            listmodel: showcaseSettingsModel
        }
    }

    ListModel {
    id: collectionsSettingsModel

        ListElement {
            settingName: "Collection 1"
            setting: "Recently Played,Most Played,Recommended,Top by Publisher,Top by Developer,Top by Genre,Top by Genre 2,None,Favorites"
        }
        ListElement {
            settingName: "Collection 1 - Thumbnail"
            setting: "Wide,Tall,Square"
        }
        ListElement {
            settingName: "Collection 1 - Size"
            setting: "Small,Medium,Large"
        }
        ListElement {
            settingName: "Collection 1 - Ratio"
            setting: "0.66,0.67,0.68,0.69,0.70,0.71,0.72,0.73,0.74,0.75,0.76,0.77,0.78,0.79,0.80,0.81,0.82,0.83,0.84,0.85,0.86,0.87,0.88,0.89,0.90,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,0.99,0.25,0.26,0.27,0.28,0.29,0.30,0.31,0.32,0.33,0.34,0.35,0.36,0.37,0.38,0.39,0.40,0.41,0.42,0.43,0.44,0.45,0.46,0.47,0.48,0.49,0.50,0.51,0.52,0.53,0.54,0.55,0.56,0.57,0.58,0.59,0.60,0.61,0.62,0.63,0.64,0.65"
        }
        ListElement {
            settingName: "Collection 2"
            setting: "Most Played,Recommended,Top by Publisher,Top by Developer,Top by Genre,Top by Genre 2,None,Favorites,Recently Played"
        }
        ListElement {
            settingName: "Collection 2 - Thumbnail"
            setting: "Tall,Square,Wide"
        }
        ListElement {
            settingName: "Collection 2 - Size"
            setting: "Small,Medium,Large"
        }
        ListElement {
            settingName: "Collection 2 - Ratio"
            setting: "0.66,0.67,0.68,0.69,0.70,0.71,0.72,0.73,0.74,0.75,0.76,0.77,0.78,0.79,0.80,0.81,0.82,0.83,0.84,0.85,0.86,0.87,0.88,0.89,0.90,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,0.99,0.25,0.26,0.27,0.28,0.29,0.30,0.31,0.32,0.33,0.34,0.35,0.36,0.37,0.38,0.39,0.40,0.41,0.42,0.43,0.44,0.45,0.46,0.47,0.48,0.49,0.50,0.51,0.52,0.53,0.54,0.55,0.56,0.57,0.58,0.59,0.60,0.61,0.62,0.63,0.64,0.65"
        }
        ListElement {
            settingName: "Collection 3"
            setting: "Top by Publisher,Top by Developer,Top by Genre,Top by Genre 2,None,Favorites,Recently Played,Most Played,Recommended"
        }
        ListElement {
            settingName: "Collection 3 - Thumbnail"
            setting: "Wide,Tall,Square"
        }
        ListElement {
            settingName: "Collection 3 - Size"
            setting: "Small,Medium,Large"
        }
        ListElement {
            settingName: "Collection 3 - Ratio"
            setting: "0.66,0.67,0.68,0.69,0.70,0.71,0.72,0.73,0.74,0.75,0.76,0.77,0.78,0.79,0.80,0.81,0.82,0.83,0.84,0.85,0.86,0.87,0.88,0.89,0.90,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,0.99,0.25,0.26,0.27,0.28,0.29,0.30,0.31,0.32,0.33,0.34,0.35,0.36,0.37,0.38,0.39,0.40,0.41,0.42,0.43,0.44,0.45,0.46,0.47,0.48,0.49,0.50,0.51,0.52,0.53,0.54,0.55,0.56,0.57,0.58,0.59,0.60,0.61,0.62,0.63,0.64,0.65"
        }
        ListElement {
            settingName: "Collection 4"
            setting: "Top by Genre,Top by Genre 2,Top by Developer,None,Favorites,Recently Played,Most Played,Recommended,Top by Publisher"
        }
        ListElement {
            settingName: "Collection 4 - Thumbnail"
            setting: "Tall,Square,Wide"
        }
        ListElement {
            settingName: "Collection 4 - Size"
            setting: "Small,Medium,Large"
        }
        ListElement {
            settingName: "Collection 4 - Ratio"
            setting: "0.66,0.67,0.68,0.69,0.70,0.71,0.72,0.73,0.74,0.75,0.76,0.77,0.78,0.79,0.80,0.81,0.82,0.83,0.84,0.85,0.86,0.87,0.88,0.89,0.90,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,0.99,0.25,0.26,0.27,0.28,0.29,0.30,0.31,0.32,0.33,0.34,0.35,0.36,0.37,0.38,0.39,0.40,0.41,0.42,0.43,0.44,0.45,0.46,0.47,0.48,0.49,0.50,0.51,0.52,0.53,0.54,0.55,0.56,0.57,0.58,0.59,0.60,0.61,0.62,0.63,0.64,0.65"
        }
        ListElement {
            settingName: "Collection 5"
            setting: "None,Favorites,Recently Played,Most Played,Recommended,Top by Publisher,Top by Developer,Top by Genre,Top by Genre 2"
        }
        ListElement {
            settingName: "Collection 5 - Thumbnail"
            setting: "Wide,Tall,Square"
        }
        ListElement {
            settingName: "Collection 5 - Size"
            setting: "Small,Medium,Large"
        }
        ListElement {
            settingName: "Collection 5 - Ratio"
            setting: "0.66,0.67,0.68,0.69,0.70,0.71,0.72,0.73,0.74,0.75,0.76,0.77,0.78,0.79,0.80,0.81,0.82,0.83,0.84,0.85,0.86,0.87,0.88,0.89,0.90,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,0.99,0.25,0.26,0.27,0.28,0.29,0.30,0.31,0.32,0.33,0.34,0.35,0.36,0.37,0.38,0.39,0.40,0.41,0.42,0.43,0.44,0.45,0.46,0.47,0.48,0.49,0.50,0.51,0.52,0.53,0.54,0.55,0.56,0.57,0.58,0.59,0.60,0.61,0.62,0.63,0.64,0.65"
        }
        ListElement {
            settingName: "Collection 6"
            setting: "None,Favorites,Recently Played,Most Played,Recommended,Top by Publisher,Top by Developer,Top by Genre,Top by Genre 2"
        }
        ListElement {
            settingName: "Collection 6 - Thumbnail"
            setting: "Wide,Tall,Square"
        }
        ListElement {
            settingName: "Collection 6 - Size"
            setting: "Small,Medium,Large"
        }
        ListElement {
            settingName: "Collection 6 - Ratio"
            setting: "0.66,0.67,0.68,0.69,0.70,0.71,0.72,0.73,0.74,0.75,0.76,0.77,0.78,0.79,0.80,0.81,0.82,0.83,0.84,0.85,0.86,0.87,0.88,0.89,0.90,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,0.99,0.25,0.26,0.27,0.28,0.29,0.30,0.31,0.32,0.33,0.34,0.35,0.36,0.37,0.38,0.39,0.40,0.41,0.42,0.43,0.44,0.45,0.46,0.47,0.48,0.49,0.50,0.51,0.52,0.53,0.54,0.55,0.56,0.57,0.58,0.59,0.60,0.61,0.62,0.63,0.64,0.65"
        }

    }

    ListModel {
        id: featuredSettingsModel

        ListElement {
            settingName: "Featured Box"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Pins to collection"
            setting: "1,2,3,4,5,6"
        }
        ListElement {
            settingName: "Featured Box Content"
            setting: "Favorites,Discover Videos,Fanart Slideshow"
        }
    }

    property var featuredPage: {
        return {
            pageName: "Featured",
            listmodel: featuredSettingsModel
        }
    }

    property var collectionsPage: {
        return {
            pageName: "Collections",
            listmodel: collectionsSettingsModel
        }
    }

    ListModel {
    id: gridSettingsModel

        ListElement {
            settingName: "Grid Thumbnail"
            setting: "Wide,Tall,Square,Box Art"
        }
        ListElement {
            settingName: "Grid Ratio"
            setting: "0.66,0.67,0.68,0.69,0.70,0.71,0.72,0.73,0.74,0.75,0.76,0.77,0.78,0.79,0.80,0.81,0.82,0.83,0.84,0.85,0.86,0.87,0.88,0.89,0.90,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,0.99,0.25,0.26,0.27,0.28,0.29,0.30,0.31,0.32,0.33,0.34,0.35,0.36,0.37,0.38,0.39,0.40,0.41,0.42,0.43,0.44,0.45,0.46,0.47,0.48,0.49,0.50,0.51,0.52,0.53,0.54,0.55,0.56,0.57,0.58,0.59,0.60,0.61,0.62,0.63,0.64,0.65"
        }
        ListElement {
            settingName: "Grid art"
            setting: "Fanart,Screenshot,Boxfront"
        }
        ListElement {
            settingName: "Grid Game Logo"
            label: "Game logo"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Number of columns"
            setting: "3,4,5,6,7,8"
        }
        ListElement {
            settingName: "Game Counter"
            setting: "Yes,No"
        }
    }

    property var gridPage: {
        return {
            pageName: "Platform page",
            listmodel: gridSettingsModel
        }
    }

    ListModel {
    id: gameSettingsModel

        ListElement {
            settingName: "Box Art"
            setting: "2D,3D,Miximage"
        }
        ListElement {
            settingName: "More by Genre Display"
            setting: "Full,Main Genre,Sub Genre"
        }
        ListElement {
            settingName: "Game Background"
            setting: "Screenshot,Fanart"
        }
        ListElement {
            settingName: "Game Logo"
            setting: "Show,Text only,Hide"
        }
        ListElement {
            settingName: "Default to full details"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Video preview"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Randomize Background"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Blur Background"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Show scanlines"
            setting: "Yes,No"
        }
    }

    property var gamePage: {
        return {
            pageName: "Game details",
            listmodel: gameSettingsModel
        }
    }

    ListModel {
    id: allGamesSettingsModel
        ListElement {
            settingName: "AllGames Video preview"
            label: "Video preview"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "AllGames Hide box art on video"
            label: "Hide box art when video plays"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "AllGames Hide logo on video"
            label: "Hide logo when video plays"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "AllGames Blur Background"
            label: "Blur Background"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "AllGames Show scanlines"
            label: "Show scanlines"
            setting: "No,Yes"
        }
    }

    property var allGamesPage: {
        return {
            pageName: "All Games Menu",
            listmodel: allGamesSettingsModel
        }
    }

    ListModel {
    id: mediaCarouselSettingsModel

        ListElement {
            settingName: "Video"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Screenshots"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Title Screen"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Fanart"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "3D Box"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "2D Box"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Back Box"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Cartridge"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Miximage"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Logo"
            setting: "Yes,No"
        }
    }

    property var mediaCarouselPage: {
        return {
            pageName: "Media Carousel",
            listmodel: mediaCarouselSettingsModel
        }
    }

    // ── RetroAchievements credentials page ──────────────────────────────
    ListModel {
    id: raSettingsModel

        // inputType: "text" marks rows that take free-form keyboard input
        // instead of cycling through a comma-separated list.
        ListElement {
            settingName: "RA Username"
            setting:     ""
            inputType:   "text"
            note:        "Your retroachievements.org username"
        }
        ListElement {
            settingName: "RA API Key"
            setting:     ""
            inputType:   "text"
            masked:      true
            note:        "Web API key from retroachievements.org/settings"
        }
    }

    property var raPage: {
        return {
            pageName:  "Retro Achievements",
            listmodel: raSettingsModel
        }
    }

    property var settingsArr: [generalPage, showcasePage, collectionsPage, featuredPage, gridPage, gamePage, allGamesPage, mediaCarouselPage, audioPage, advancedPage, raPage]

    // ── Help text ─────────────────────────────────────────────────────────
    // In a function, not on the ListElements: a ListElement only accepts
    // literal values, so any string built with + is rejected and the whole
    // screen fails to load.
    function infoText(name) {
        if (name === "Custom Background") {
            return "Shows your own image behind the Showcase.\n\n"
                 + "TO USE YOUR OWN\n"
                 + "Rename the image to background.png and put it in the "
                 + "theme's assets/images/backgrounds folder.\n\n"
                 + "It sits underneath everything, so it stays visible behind "
                 + "entries that have no fanart of their own \u2014 apps "
                 + "imported by Pegasus, for instance \u2014 instead of "
                 + "leaving a blank screen.\n\n"
                 + "Entries that do have fanart cover it completely, so this "
                 + "works alongside Showcase Background Art rather than "
                 + "replacing it. Turn that off to see your image behind the "
                 + "whole Showcase.";
        }
        if (name === "Randomize System Tile Fanart") {
            return "Picks a random image from the highlighted collection's own "
                 + "fanart each time, instead of always using the same one.\n\n"
                 + "The pick comes from that collection's games, so it changes "
                 + "as you move along the system row.\n\n"
                 + "Needs Showcase Background Art on \u2014 with it off there "
                 + "is no fanart to choose from, and this row locks.";
        }
        if (name === "Hide Android System Tile") {
            return "Hides the tile for the collection the App Drawer uses, so "
                 + "the same apps aren't in two places at once. Set this to No "
                 + "to keep the tile as well.\n\n"
                 + "The drawer uses the collection named exactly \"Android\" "
                 + "\u2014 the one Pegasus creates when you enable app "
                 + "importing in its own settings.\n\n"
                 + "SHORTNAME GUIDE\n"
                 + "\u2022 androidgames \u2014 for a collection of games you "
                 + "list yourself\n"
                 + "\u2022 android or androidapps \u2014 for apps you list "
                 + "yourself\n\n"
                 + "IMPORTANT\n"
                 + "The match is on the collection NAME, not the shortname. A "
                 + "collection using shortname \"android\" but named something "
                 + "else \u2014 \"Android Apps\", say \u2014 is NOT the one "
                 + "the drawer picks up while Pegasus app importing is on, "
                 + "because the imported \"Android\" collection wins.\n\n"
                 + "Turn Pegasus app importing off and your own collection is "
                 + "used instead.";
        }
        if (name === "Omit genre: Application from Showcase") {
            return "Keeps applications out of the Showcase content rows "
                 + "(Recently Played, Recommended and so on).\n\n"
                 + "It works two ways: apps imported by Pegasus are filtered "
                 + "by collection, and apps you list yourself are filtered by "
                 + "the genre: Application tag.\n\n"
                 + "Both rules exist because imported apps carry no genre at "
                 + "all, so the tag alone would miss them.\n\n"
                 + "May need a theme reload.\n\n"
                 + "WHICH COLLECTION IS USED\n"
                 + "In order: the Pegasus import named \"Android\" wins if app "
                 + "importing is on; otherwise a collection you named "
                 + "\"Android\"; otherwise one whose shortname is android or "
                 + "androidgames.\n\n"
                 + "While this is off, apps appear in the rows and launch "
                 + "straight away instead of opening a details page.";
        }
        if (name === "Omit genre: Emulator from Showcase") {
            return "Keeps emulators out of the Showcase content rows.\n\n"
                 + "It works two ways: emulators among the apps imported by "
                 + "Pegasus are recognised automatically, and emulators you "
                 + "list yourself are filtered by the genre: Emulator tag.\n\n"
                 + "Both rules exist because imported apps carry no genre at "
                 + "all, so the tag alone would miss them.\n\n"
                 + "May need a theme reload.";
        }
        return "";
    }

    // Cheap yes/no test. infoText() concatenates a lot of literals to build its
    // result, which is wasteful when all that's needed is whether one exists.
    function hasInfo(name) {
        return name === "Custom Background"
            || name === "Randomize System Tile Fanart"
            || name === "Hide Android System Tile"
            || name === "Omit genre: Application from Showcase"
            || name === "Omit genre: Emulator from Showcase";
    }

    property real itemheight: vpx(50)
    property color settingsTextColor: "white"   // locked white: the settings background is locked black, so text must never follow the Color Layout light/dark flip

    // ── On-screen keyboard for text fields (RA credentials) ───────────────
    // Fully controller-driven. NO native Android TextInput/IME (no blue box).
    property bool   kbOpen:          false
    property string editText:        ""
    property string editSettingName: ""
    property bool   editMasked:      false
    property int    memRevision:     0   // bump to refresh displayed values
    // Only the two RA fields are text inputs, so an edit always means RA creds changed.
    onMemRevisionChanged: cheevosData.verify()

    function openEditor(name, masked) {
        editSettingName = name;
        editMasked = masked;
        editText = api.memory.has(name) ? api.memory.get(name) : "";
        kbOpen = true;
        credsKb.page = 0;          // always start on the letters page
        credsKb.shifted = false;
        credsKb.row = 0;
        credsKb.col = 0;
        credsKb.forceActiveFocus();
    }
    // Resolve a controller action to its glyph file (assets/images/controller/<hex>.png)
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

    function closeEditor() {
        kbOpen = false;
        settingsList.forceActiveFocus();
    }

    // Settings background — locked to black (independent of Color Background)
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        z: -10
    }

    Rectangle {
    id: header

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: vpx(75)
        color: "#000000"
        z: 5

        // Settings cog (same icon used elsewhere in the theme)
        Image {
            id: settingsCog
            anchors {
                left: parent.left; leftMargin: globalMargin
                verticalCenter: parent.verticalCenter
            }
            height: vpx(28)
            width: height
            source: "../assets/images/settingsicon.svg"
            sourceSize: Qt.size(vpx(28), vpx(28))
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
        }

        // Platform title
        Text {
        id: headertitle
            
            text: "SETTINGS"
            
            anchors {
                top: parent.top;
                left: settingsCog.right; leftMargin: vpx(12)
                right: parent.right
                bottom: parent.bottom
            }
            
            color: settingsTextColor
            font.family: titleFont.name
            font.pixelSize: vpx(30)
            font.bold: true
            horizontalAlignment: Text.AlignHLeft
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight

            // Mouse/touch functionality
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    previousScreen();
                }
            }
        }

    }

    // Active page name — left of the content box, matches the SETTINGS title color
    Text {
        id: activePageLabel
        z: 6
        anchors {
            left: settingsList.left; leftMargin: vpx(25)
            verticalCenter: header.verticalCenter
        }
        text: (pagelist.currentIndex >= 0 && settingsArr[pagelist.currentIndex])
              ? settingsArr[pagelist.currentIndex].pageName.toUpperCase() : ""
        color: settingsTextColor
        font.family: subtitleFont.name
        font.pixelSize: vpx(24)
        font.bold: true
        verticalAlignment: Text.AlignVCenter
    }

    // Subtle nav-rail panel (balances the content panel)
    Rectangle {
        id: railPanel
        anchors {
            top: header.bottom
            bottom: parent.bottom; bottomMargin: helpMargin
            left: parent.left
            right: pagelist.right
        }
        color: theme.secondary
        opacity: 0.5
        radius: 0
        z: -1
    }

    ListView {
    id: pagelist
    
        focus: true
        anchors {
            top: header.bottom
            bottom: parent.bottom; bottomMargin: helpMargin
            left: parent.left; leftMargin: globalMargin
        }
        width: vpx(300)
        model: settingsArr
        onCurrentIndexChanged: {
            if (settingsArr[currentIndex] && settingsArr[currentIndex].pageName === "Retro Achievements")
                cheevosData.verify();
        }
        delegate: Component {
        id: pageDelegate
        
            Item {
            id: pageRow

                property bool selected: ListView.isCurrentItem

                width: ListView.view.width
                height: itemheight

                // Selection tile
                Rectangle {
                id: pageTile
                    anchors.fill: parent
                    anchors.rightMargin: vpx(8)
                    radius: vpx(6)
                    color: theme.accent
                    opacity: selected ? 0.16 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }
                // Left accent edge-bar
                Rectangle {
                    anchors { left: pageTile.left; verticalCenter: pageTile.verticalCenter }
                    width: vpx(4)
                    height: pageTile.height * 0.55
                    radius: width / 2
                    color: theme.accent
                    opacity: selected ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                // Page name
                Text {
                id: oageNameText
                
                    text: modelData.pageName.toUpperCase()
                    color: settingsTextColor
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(24)
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                    opacity: selected ? 1 : 0.2

                    width: contentWidth
                    height: parent.height
                    anchors {
                        left: parent.left; leftMargin: vpx(25)
                    }
                }

                // Mouse/touch functionality
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: settings.MouseHover == "Yes"
                    onEntered: { playNav(); }
                    onClicked: {
                        playNav();
                        pagelist.currentIndex = index;
                        settingsList.focus = true;
                    }
                }

            }
        } 

        // Wrap around both ends of the page list (General <-> Retro Achievements)
        // instead of dead-ending at the first/last entry.
        Keys.onUpPressed: {
            playNav();
            if (currentIndex === 0) currentIndex = count - 1;
            else decrementCurrentIndex();
        }
        Keys.onDownPressed: {
            playNav();
            if (currentIndex === count - 1) currentIndex = 0;
            else incrementCurrentIndex();
        }
        Keys.onPressed: {
            // Accept
            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true;
                playAccept();
                settingsList.focus = true;
            }
            // Back
            if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                event.accepted = true;
                previousScreen();
            }
        }

    }

    // Subtle content panel (depth behind the settings column)
    Rectangle {
        id: settingsPanel
        anchors {
            top: header.bottom
            bottom: parent.bottom; bottomMargin: helpMargin
            left: pagelist.right; leftMargin: vpx(10)
            right: parent.right
        }
        color: theme.secondary
        opacity: 0.5
        radius: 0
        z: -1
    }

    // RetroAchievements credential status — only on the RA page.
    Text {
        id: raVerifyBanner
        z: 2
        visible: settingsArr[pagelist.currentIndex]
                 && settingsArr[pagelist.currentIndex].pageName === "Retro Achievements"
        anchors {
            left: pagelist.right;  leftMargin: globalMargin + vpx(25)
            right: parent.right;   rightMargin: vpx(25)
            bottom: parent.bottom; bottomMargin: helpMargin + vpx(18)
        }
        wrapMode: Text.WordWrap
        font.family: subtitleFont.name
        font.pixelSize: vpx(18)
        opacity: (cheevosData.verifyState === "idle") ? 0 : 1
        color: cheevosData.verifyState === "ok"  ? "#5fd36b"
             : cheevosData.verifyState === "bad" ? "#e06c6c"
             : settingsTextColor
        text: cheevosData.verifyState === "checking" ? "Checking credentials\u2026"
            : cheevosData.verifyState === "ok"       ? ("\u2713  Verified \u2014 signed in as " + cheevosData.verifyName)
            : cheevosData.verifyState === "bad"      ? "\u2717  Invalid username or API key"
            : cheevosData.verifyState === "neterr"   ? "No network connection \u2014 try again"
            : cheevosData.verifyState === "empty"    ? "Enter your username and API key above"
            : ""
    }

    ListView {
    id: settingsList

        property int settingsVersion: 0   // increment to force delegate savedIndex refresh

        model: settingsArr[pagelist.currentIndex].listmodel
        delegate: settingsDelegate
        
        anchors {
            top: header.bottom; bottom: parent.bottom; bottomMargin: helpMargin
            left: pagelist.right; leftMargin: globalMargin
            right: parent.right; rightMargin: globalMargin
        }
        width: vpx(500)

        spacing: vpx(0)
        orientation: ListView.Vertical

        preferredHighlightBegin: settingsList.height / 2 - itemheight
        preferredHighlightEnd: settingsList.height / 2
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 100
        clip: true

        Component {
        id: settingsDelegate
        
            Item {
            id: settingRow

                property bool selected: ListView.isCurrentItem && settingsList.focus
                property variant settingList: setting.split(',')
                property int savedIndex: Math.min(api.memory.get(settingName + 'Index') || 0, settingList.length - 1)

                Connections {
                    target: settingsList
                    onSettingsVersionChanged: {
                        savedIndex = Math.min(api.memory.get(settingName + 'Index') || 0, settingList.length - 1);
                    }
                }
                property string itemNote: (typeof note !== 'undefined') ? note : ""
                // Optional friendly display label; storage key remains settingName
                property string displayLabel: (typeof label !== 'undefined' && label !== "") ? label : settingName

                // Greyed-out/inert state — "Randomize System Tile Fanart" only has
                // an effect while the fanart background is showing, so it locks
                // when Showcase Background Art is off.
                //
                // It no longer locks on Custom Background: the two used to be
                // mutually exclusive, but the custom image is a base layer now
                // and fanart still runs on top of it.
                property bool rowDisabled: {
                    var _v = settingsList.settingsVersion;   // re-evaluate after any save
                    if (settingName === "Randomize System Tile Fanart") {
                        var bgArt  = api.memory.has("Showcase Background Art") ? api.memory.get("Showcase Background Art") : "Yes";
                        return bgArt === "No";
                    }
                    // A collection's Ratio row is inert when its shape is Square
                    if (settingName.indexOf("Collection ") === 0 && settingName.indexOf(" - Ratio") !== -1) {
                        var coll = settingName.replace(" - Ratio", "");
                        var shp = api.memory.has(coll + " - Thumbnail") ? api.memory.get(coll + " - Thumbnail") : "Wide";
                        return shp === "Square";
                    }
                    // Grid Ratio is inert when the grid shape is Square or Box Art
                    // (Box Art tiles use the box art's own native aspect ratio).
                    if (settingName === "Grid Ratio") {
                        var gth = api.memory.has("Grid Thumbnail") ? api.memory.get("Grid Thumbnail") : "Wide";
                        return gth === "Square" || gth === "Box Art";
                    }
                    // Grid art / Grid Game Logo only apply to the Wide/Tall/Square
                    // tile styles — Box Art tiles always show the box art itself,
                    // so there's no art-source or logo-overlay choice to make.
                    if (settingName === "Grid art" || settingName === "Grid Game Logo") {
                        var gth2 = api.memory.has("Grid Thumbnail") ? api.memory.get("Grid Thumbnail") : "Wide";
                        return gth2 === "Box Art";
                    }
                    return false;
                }

                // Text-input rows (RA credentials) skip the cycling logic
                property bool isTextInput: inputType === "text"
                property bool isEditing:   false
                property string originalText: ""

                function saveSetting() {
                    if (isTextInput || rowDisabled) return;
                    api.memory.set(settingName + 'Index', savedIndex);
                    api.memory.set(settingName, settingList[savedIndex]);
                    // These two used to be mutually exclusive, each forcing the
                    // other off when enabled. They now layer instead: the custom
                    // image is the base and fanart paints over it, showing
                    // through only for entries that have no art of their own.
                    // Either of these changing can lock/unlock the randomize row
                    if (settingName === "Showcase Background Art" || settingName === "Custom Background")
                        settingsList.settingsVersion++;
                    // Wakes any binding that opted into live updates.
                    settingsEpoch++;
                }

                function nextSetting() {
                    if (isTextInput || rowDisabled) return;
                    if (savedIndex != settingList.length -1)
                        savedIndex++;
                    else
                        savedIndex = 0;
                }

                function prevSetting() {
                    if (isTextInput || rowDisabled) return;
                    if (savedIndex > 0)
                        savedIndex--;
                    else
                        savedIndex = settingList.length -1;
                }

                width: ListView.view.width
                height: itemNote !== "" ? itemheight + vpx(22) : itemheight

                // Selection tile
                Rectangle {
                id: setTile
                    anchors { left: parent.left; top: parent.top }
                    anchors.right: isTextInput ? textInputContainer.left : parent.right
                    anchors.leftMargin: vpx(12)
                    anchors.rightMargin: vpx(12)
                    height: itemheight
                    radius: vpx(6)
                    color: theme.accent
                    opacity: selected ? 0.16 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }
                // Left accent edge-bar
                Rectangle {
                    anchors { left: setTile.left; verticalCenter: setTile.verticalCenter }
                    width: vpx(4)
                    height: itemheight * 0.55
                    radius: width / 2
                    color: theme.accent
                    opacity: selected ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                // ── Cycle-value rows (existing style) ──────────────────────
                Text {
                id: settingNameText

                    visible: !isTextInput
                    text: displayLabel.toUpperCase() + ": "
                    color: settingsTextColor
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(22)
                    verticalAlignment: Text.AlignVCenter
                    opacity: rowDisabled ? 0.12 : (selected ? 1 : 0.2)

                    width: contentWidth
                    height: itemheight
                    anchors {
                        left: parent.left; leftMargin: vpx(25)
                    }
                }
                Text {
                id: settingtext

                    visible: !isTextInput
                    text: (selected && !rowDisabled ? "\u2039  " : "") + settingList[savedIndex].toUpperCase() + (selected && !rowDisabled ? "  \u203A" : "")
                    font.bold: selected
                    color: settingsTextColor
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(22)
                    verticalAlignment: Text.AlignVCenter
                    opacity: rowDisabled ? 0.12 : (selected ? 1 : 0.2)

                    height: itemheight
                    anchors {
                        right: parent.right; rightMargin: vpx(25)
                    }
                }

                // ── Text-input rows (RA credentials) ───────────────────────
                Text {
                id: textInputLabel

                    visible: isTextInput
                    text: settingName.toUpperCase() + ":"
                    color: settingsTextColor
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(22)
                    verticalAlignment: Text.AlignVCenter
                    opacity: selected ? 1 : 0.2

                    width: contentWidth
                    height: itemheight
                    anchors {
                        left: parent.left; leftMargin: vpx(25)
                    }
                }

                // Read-only value display — editing happens in the on-screen
                // keyboard overlay (no native TextInput here)
                Rectangle {
                id: textInputContainer

                    visible: isTextInput
                    anchors {
                        right: parent.right; rightMargin: vpx(25)
                        top: parent.top
                    }
                    y: (itemheight - height) / 2
                    width:  vpx(280)
                    height: vpx(34)
                    color: "transparent"
                    border.width: settingRow.selected ? vpx(1) : 0
                    border.color: theme.accent
                    radius: vpx(4)

                    Text {
                        anchors { fill: parent; margins: vpx(8) }
                        property string storedVal: {
                            var _r = root.memRevision;   // refresh after edits
                            return api.memory.has(settingName) ? api.memory.get(settingName) : "";
                        }
                        text: storedVal === ""
                              ? "(press A to set)"
                              : ((typeof masked !== 'undefined' && masked)
                                 ? Array(storedVal.length + 1).join("\u25CF")
                                 : storedVal)
                        color: settingsTextColor
                        font.family: subtitleFont.name
                        font.pixelSize: vpx(18)
                        opacity: settingRow.selected ? 1 : 0.2
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }

                // ── Optional note (shared) — accent badge ─────────────────
                Rectangle {
                id: noteBadge

                    visible: itemNote !== ""
                    width: noteLabel.width + vpx(16)
                    height: noteLabel.height + vpx(6)
                    color: "transparent"
                    border.width: vpx(1)
                    border.color: theme.accent
                    radius: vpx(4)
                    opacity: selected ? 1 : 0.45

                    anchors {
                        left: parent.left; leftMargin: vpx(25)
                        top: parent.top; topMargin: itemheight - vpx(4)
                    }

                    Text {
                        id: noteLabel
                        anchors.centerIn: parent
                        text: itemNote
                        color: theme.accent
                        font.family: bodyFont.name
                        font.pixelSize: vpx(13)
                        font.bold: true
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left; leftMargin: vpx(25)
                        right: parent.right; rightMargin: vpx(25)
                        bottom: parent.bottom
                    }
                    color: settingsTextColor
                    opacity: selected ? 0.1 : 0
                    height: vpx(1)
                }

                // ── Input handling ────────────────────────────────────────
                Keys.onRightPressed: {
                    if (!isTextInput && !rowDisabled) { playToggle(); nextSetting(); saveSetting(); }
                }
                Keys.onLeftPressed: {
                    if (!isTextInput && !rowDisabled) { playToggle(); prevSetting(); saveSetting(); }
                }

                Keys.onPressed: {
                    // Accept
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        if (isTextInput) {
                            // Capture current saved value before opening editor
                            playAccept();
                            root.openEditor(settingName, (typeof masked !== 'undefined' && masked));
                        } else if (!rowDisabled) {
                            playToggle();
                            nextSetting();
                            saveSetting();
                        }
                    }
                    // More info
                    if (api.keys.isDetails(event) && !event.isAutoRepeat
                        && root.hasInfo(settingName)) {
                        event.accepted = true;
                        playToggle();
                        root.openInfo(displayLabel, root.infoText(settingName));
                        return;
                    }
                    // Back
                    if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        playBack();
                        pagelist.focus = true;
                    }
                }

                // Mouse/touch functionality
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: settings.MouseHover == "Yes"
                    onEntered: { playNav(); }
                    onClicked: {
                        if (selected) {
                            if (isTextInput) {
                                playAccept();
                                root.openEditor(settingName, (typeof masked !== 'undefined' && masked));
                            } else if (!rowDisabled) {
                                playToggle();
                                nextSetting();
                                saveSetting();
                            }
                        } else {
                            settingsList.forceActiveFocus();
                            settingsList.currentIndex = index;
                        }
                    }
                }
            }
        } 

        onCurrentIndexChanged: root.rebuildHelpbar()
        onFocusChanged: root.rebuildHelpbar()

        // Wrap both ends, matching the page list on the left — dead-ending
        // partway down a long page was the odd one out.
        Keys.onUpPressed: {
            playNav();
            if (currentIndex === 0) currentIndex = count - 1;
            else decrementCurrentIndex();
        }
        Keys.onDownPressed: {
            playNav();
            if (currentIndex === count - 1) currentIndex = 0;
            else incrementCurrentIndex();
        }
    }

    // ── On-screen keyboard overlay ────────────────────────────────────────
    // Uses the shared VirtualKeyboard (Global/) so the RA credential fields
    // match every other keyboard in the theme. This host keeps owning
    // editText; the keyboard reports edits back via onTextEdited.
    Rectangle {
    id: kbOverlay

        visible: kbOpen; z: 100
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.82)
        focus: kbOpen

        MouseArea { anchors.fill: parent; onClicked: closeEditor(); }

        VirtualKeyboard {
        id: credsKb

            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
            focus: kbOpen
            title: editSettingName
            text: editText
            masked: editMasked
            allowClipboard: true        // COPY / PASTE for the API key

            onTextEdited:  editText = newText
            onAccepted: {
                api.memory.set(editSettingName, editText);
                memRevision++;
                kbOpen = false;
                settingsList.forceActiveFocus();
            }
            onCancelled:   closeEditor()
        }
    }

    // Helpbar buttons
    ListModel { id: settingsHelpModel }

    // Only rebuilt when the answer actually changes: clearing and repopulating
    // the model recreates the help bar's delegates, and doing that on every
    // cursor move is a hitch on every keypress.
    property int helpState: -1      // -1 unset, 0 without info, 1 with

    function rebuildHelpbar() {
        var want = 0;
        if (settingsList.focus) {
            var page = settingsArr[pagelist.currentIndex];
            var i = settingsList.currentIndex;
            if (page && page.listmodel && i >= 0 && i < page.listmodel.count) {
                var row = page.listmodel.get(i);
                if (row && hasInfo(row.settingName)) want = 1;
            }
        }
        if (want === helpState) return;
        helpState = want;
        settingsHelpModel.clear();
        // The bar lays out right-to-left, so the LAST entry appended is the
        // one furthest left. Back goes first to sit on the right of it.
        settingsHelpModel.append({ name: "Back", button: "cancel" });
        if (want === 1)
            settingsHelpModel.append({ name: "More info", button: "details" });
    }

    Component.onCompleted: rebuildHelpbar()

    onFocusChanged: { if (focus) currentHelpbarModel = settingsHelpModel; }

    // ── Info panel ────────────────────────────────────────────────────────
    property bool   infoOpen:  false
    property string infoTitle: ""
    property string infoBody:  ""

    function openInfo(title, body) {
        infoTitle = title;
        infoBody  = body;
        infoOpen  = true;
        infoPanel.forceActiveFocus();
    }
    function closeInfo() {
        infoOpen = false;
        settingsList.forceActiveFocus();
    }

    FocusScope {
    id: infoPanel

        anchors.fill: parent
        visible: root.infoOpen
        enabled: root.infoOpen
        z: 60

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.65
            MouseArea { anchors.fill: parent; onClicked: root.closeInfo() }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.6, vpx(600))
            height: infoCol.height + vpx(44)
            radius: vpx(10)
            color: "#242424"
            border.width: vpx(1)
            border.color: Qt.rgba(1, 1, 1, 0.14)

            Column {
            id: infoCol

                anchors { top: parent.top; topMargin: vpx(22)
                          left: parent.left; leftMargin: vpx(26)
                          right: parent.right; rightMargin: vpx(26) }
                spacing: vpx(12)

                Text {
                    width: parent.width
                    text: root.infoTitle
                    color: theme.accent
                    font.family: titleFont.name
                    font.pixelSize: vpx(21)
                    font.bold: true
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    text: root.infoBody
                    color: root.settingsTextColor
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(15)
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    text: "Press B to close"
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(12)
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        // Swallows input so the list underneath can't move while it's open.
        Keys.onPressed: {
            if (event.isAutoRepeat) return;
            event.accepted = true;
            if (api.keys.isCancel(event) || api.keys.isAccept(event)
                || api.keys.isDetails(event)) {
                playBack();
                root.closeInfo();
            }
        }
    }

}
