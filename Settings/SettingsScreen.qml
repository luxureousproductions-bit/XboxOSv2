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
import "../utils.js" as Utils

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

        ListElement {
            settingName: "UI Scale"
            setting: "1.0,1.1,1.25,1.4,1.5"
        }
        ListElement {
            settingName: "High Quality Mode"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Launch screen delay"
            setting: "2.0,2.5,3.0,3.5,4.0,4.5,5.0,0.5,1.0,1.5"
        }
        ListElement {
            settingName: "Hide button help"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Enable mouse hover"
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

        ListElement { settingName: "Menu"; setting: ""; header: true }
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
        ListElement { settingName: "Video"; setting: ""; header: true }
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
            label: "Hide apps from Home"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Omit genre: Emulator from Showcase"
            label: "Hide emulators from Home"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Hide Android System Tile"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Added App Launch"
            setting: "Instant,Details Page"
        }
        ListElement {
            settingName: "Show WiFi Indicator"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Show Battery Percentage"
            label: "Battery indicator"
            setting: "Battery Only,Percentage Only,Combined,No"
        }
        ListElement {
            settingName: "Show Clock"
            label: "Clock"
            setting: "12hr,24hr,No"
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

        ListElement { settingName: "Layout"; setting: ""; header: true }
        ListElement {
            settingName: "Xbox Logo"
            setting: "Logo1,Logo2,RetroAchievements,None"
        }
        ListElement {
            settingName: "Logo Color Match"
            label: "Tint logo to accent"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Showcase Collections Art"
            label: "Tile art"
            setting: "Fanart,Screenshot"
        }
        ListElement {
            settingName: "Hero box art"
            label: "Hero tile art"
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
        ListElement { settingName: "Background"; setting: ""; header: true }
        ListElement {
            settingName: "Showcase Background Art"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Screenshot Fallback"
            setting: "No,Yes"
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
            settingName: "Dynamic Background"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Showcase Background Opacity"
            label: "Background opacity"
            setting: "0.55,0.60,0.65,0.70,0.75,0.80,0.85,0.90,0.95,1.00,0.10,0.15,0.20,0.25,0.30,0.35,0.40,0.45,0.50"
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

        ListElement { settingName: "Collection 1"; setting: ""; header: true }
        ListElement {
            settingName: "Collection 1"
            label: "Content"
            setting: "Recently Played,Most Played,Recommended,Top by Publisher,Top by Developer,Top by Genre,Top by Genre 2,System,None,Favorites"
        }
        ListElement {
            settingName: "Collection 1 - Thumbnail"
            label: "Tile shape"
            setting: "Wide,Tall,Square,Box Art,3D Box"
        }
        ListElement {
            settingName: "Collection 1 - Size"
            label: "Tile size"
            setting: "Small,Medium,Large"
        }
        ListElement {
            settingName: "Collection 1 - Ratio"
            label: "Tile ratio"
            setting: "0.66,0.67,0.68,0.69,0.70,0.71,0.72,0.73,0.74,0.75,0.76,0.77,0.78,0.79,0.80,0.81,0.82,0.83,0.84,0.85,0.86,0.87,0.88,0.89,0.90,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,0.99,0.25,0.26,0.27,0.28,0.29,0.30,0.31,0.32,0.33,0.34,0.35,0.36,0.37,0.38,0.39,0.40,0.41,0.42,0.43,0.44,0.45,0.46,0.47,0.48,0.49,0.50,0.51,0.52,0.53,0.54,0.55,0.56,0.57,0.58,0.59,0.60,0.61,0.62,0.63,0.64,0.65"
        }
        ListElement { settingName: "Collection 2"; setting: ""; header: true }
        ListElement {
            settingName: "Collection 2"
            label: "Content"
            setting: "Most Played,Recommended,Top by Publisher,Top by Developer,Top by Genre,Top by Genre 2,System,None,Favorites,Recently Played"
        }
        ListElement {
            settingName: "Collection 2 - Thumbnail"
            label: "Tile shape"
            setting: "Tall,Square,Wide,Box Art,3D Box"
        }
        ListElement {
            settingName: "Collection 2 - Size"
            label: "Tile size"
            setting: "Small,Medium,Large"
        }
        ListElement {
            settingName: "Collection 2 - Ratio"
            label: "Tile ratio"
            setting: "0.66,0.67,0.68,0.69,0.70,0.71,0.72,0.73,0.74,0.75,0.76,0.77,0.78,0.79,0.80,0.81,0.82,0.83,0.84,0.85,0.86,0.87,0.88,0.89,0.90,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,0.99,0.25,0.26,0.27,0.28,0.29,0.30,0.31,0.32,0.33,0.34,0.35,0.36,0.37,0.38,0.39,0.40,0.41,0.42,0.43,0.44,0.45,0.46,0.47,0.48,0.49,0.50,0.51,0.52,0.53,0.54,0.55,0.56,0.57,0.58,0.59,0.60,0.61,0.62,0.63,0.64,0.65"
        }
        ListElement { settingName: "Collection 3"; setting: ""; header: true }
        ListElement {
            settingName: "Collection 3"
            label: "Content"
            setting: "Top by Publisher,Top by Developer,Top by Genre,Top by Genre 2,System,None,Favorites,Recently Played,Most Played,Recommended"
        }
        ListElement {
            settingName: "Collection 3 - Thumbnail"
            label: "Tile shape"
            setting: "Wide,Tall,Square,Box Art,3D Box"
        }
        ListElement {
            settingName: "Collection 3 - Size"
            label: "Tile size"
            setting: "Small,Medium,Large"
        }
        ListElement {
            settingName: "Collection 3 - Ratio"
            label: "Tile ratio"
            setting: "0.66,0.67,0.68,0.69,0.70,0.71,0.72,0.73,0.74,0.75,0.76,0.77,0.78,0.79,0.80,0.81,0.82,0.83,0.84,0.85,0.86,0.87,0.88,0.89,0.90,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,0.99,0.25,0.26,0.27,0.28,0.29,0.30,0.31,0.32,0.33,0.34,0.35,0.36,0.37,0.38,0.39,0.40,0.41,0.42,0.43,0.44,0.45,0.46,0.47,0.48,0.49,0.50,0.51,0.52,0.53,0.54,0.55,0.56,0.57,0.58,0.59,0.60,0.61,0.62,0.63,0.64,0.65"
        }
        ListElement { settingName: "Collection 4"; setting: ""; header: true }
        ListElement {
            settingName: "Collection 4"
            label: "Content"
            setting: "Top by Genre,Top by Genre 2,System,Top by Developer,None,Favorites,Recently Played,Most Played,Recommended,Top by Publisher"
        }
        ListElement {
            settingName: "Collection 4 - Thumbnail"
            label: "Tile shape"
            setting: "Tall,Square,Wide,Box Art,3D Box"
        }
        ListElement {
            settingName: "Collection 4 - Size"
            label: "Tile size"
            setting: "Small,Medium,Large"
        }
        ListElement {
            settingName: "Collection 4 - Ratio"
            label: "Tile ratio"
            setting: "0.66,0.67,0.68,0.69,0.70,0.71,0.72,0.73,0.74,0.75,0.76,0.77,0.78,0.79,0.80,0.81,0.82,0.83,0.84,0.85,0.86,0.87,0.88,0.89,0.90,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,0.99,0.25,0.26,0.27,0.28,0.29,0.30,0.31,0.32,0.33,0.34,0.35,0.36,0.37,0.38,0.39,0.40,0.41,0.42,0.43,0.44,0.45,0.46,0.47,0.48,0.49,0.50,0.51,0.52,0.53,0.54,0.55,0.56,0.57,0.58,0.59,0.60,0.61,0.62,0.63,0.64,0.65"
        }
        ListElement { settingName: "Collection 5"; setting: ""; header: true }
        ListElement {
            settingName: "Collection 5"
            label: "Content"
            setting: "None,Favorites,Recently Played,Most Played,Recommended,Top by Publisher,Top by Developer,Top by Genre,Top by Genre 2,System"
        }
        ListElement {
            settingName: "Collection 5 - Thumbnail"
            label: "Tile shape"
            setting: "Wide,Tall,Square,Box Art,3D Box"
        }
        ListElement {
            settingName: "Collection 5 - Size"
            label: "Tile size"
            setting: "Small,Medium,Large"
        }
        ListElement {
            settingName: "Collection 5 - Ratio"
            label: "Tile ratio"
            setting: "0.66,0.67,0.68,0.69,0.70,0.71,0.72,0.73,0.74,0.75,0.76,0.77,0.78,0.79,0.80,0.81,0.82,0.83,0.84,0.85,0.86,0.87,0.88,0.89,0.90,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,0.99,0.25,0.26,0.27,0.28,0.29,0.30,0.31,0.32,0.33,0.34,0.35,0.36,0.37,0.38,0.39,0.40,0.41,0.42,0.43,0.44,0.45,0.46,0.47,0.48,0.49,0.50,0.51,0.52,0.53,0.54,0.55,0.56,0.57,0.58,0.59,0.60,0.61,0.62,0.63,0.64,0.65"
        }
        ListElement { settingName: "Collection 6"; setting: ""; header: true }
        ListElement {
            settingName: "Collection 6"
            label: "Content"
            setting: "None,Favorites,Recently Played,Most Played,Recommended,Top by Publisher,Top by Developer,Top by Genre,Top by Genre 2,System"
        }
        ListElement {
            settingName: "Collection 6 - Thumbnail"
            label: "Tile shape"
            setting: "Wide,Tall,Square,Box Art,3D Box"
        }
        ListElement {
            settingName: "Collection 6 - Size"
            label: "Tile size"
            setting: "Small,Medium,Large"
        }
        ListElement {
            settingName: "Collection 6 - Ratio"
            label: "Tile ratio"
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

    property var tilesPage: {
        return {
            pageName: "Tiles",
            listmodel: tilesSettingsModel
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
    id: tilesSettingsModel

        ListElement { settingName: "Titles"; setting: ""; header: true }
        ListElement {
            settingName: "Always show titles"
            label: "Game tile titles"
            setting: "On focus,Always,Never"
        }
        ListElement {
            settingName: "System tile titles"
            setting: "On focus,Always,Never"
        }
        ListElement { settingName: "Appearance"; setting: ""; header: true }
        ListElement {
            settingName: "Tile Halo"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Favorited Tile Accent"
            label: "Favorite tile accent"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Animate highlight"
            label: "Highlight animation"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Game Counter"
            label: "Show game count"
            setting: "Yes,No"
        }
        ListElement { settingName: "Video"; setting: ""; header: true }
        ListElement {
            settingName: "Allow video thumbnails"
            label: "Video previews"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Hide logo when thumbnail video plays"
            label: "Hide logo when preview plays"
            setting: "No,Yes"
        }
        ListElement { settingName: "Featured box"; setting: ""; header: true }
        ListElement {
            settingName: "Featured Box"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Pins to collection"
            label: "Pin featured box to"
            setting: "1,2,3,4,5,6"
        }
        ListElement {
            settingName: "Featured Box Content"
            label: "Featured box shows"
            setting: "Favorites,Discover Videos,Fanart Slideshow"
        }
    }

    ListModel {
    id: gridSettingsModel

        ListElement {
            settingName: "Grid Thumbnail"
            label: "Tile shape"
            setting: "Wide,Tall,Square,Box Art,3D Box"
        }
        ListElement {
            settingName: "Grid Ratio"
            label: "Tile ratio"
            setting: "0.66,0.67,0.68,0.69,0.70,0.71,0.72,0.73,0.74,0.75,0.76,0.77,0.78,0.79,0.80,0.81,0.82,0.83,0.84,0.85,0.86,0.87,0.88,0.89,0.90,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,0.99,0.25,0.26,0.27,0.28,0.29,0.30,0.31,0.32,0.33,0.34,0.35,0.36,0.37,0.38,0.39,0.40,0.41,0.42,0.43,0.44,0.45,0.46,0.47,0.48,0.49,0.50,0.51,0.52,0.53,0.54,0.55,0.56,0.57,0.58,0.59,0.60,0.61,0.62,0.63,0.64,0.65"
        }
        ListElement {
            settingName: "Grid art"
            label: "Tile art"
            setting: "Fanart,Screenshot,Boxfront"
        }
        ListElement {
            settingName: "Grid Game Logo"
            label: "Show logo on tile"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Number of columns"
            label: "Tiles per row"
            setting: "3,4,5,6,7,8"
        }
        ListElement {
            settingName: "LB/RB Function"
            setting: "Cycle Platforms,Nav Bar"
        }
        ListElement {
            settingName: "Per-system tile settings"
            setting: "No,Yes"
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
            label: "Box art style"
            setting: "2D,3D,Miximage"
        }
        ListElement {
            settingName: "More by Genre Display"
            label: "More by genre uses"
            setting: "Full,Main Genre,Sub Genre"
        }
        ListElement {
            settingName: "Game Background"
            label: "Background art"
            setting: "Screenshot,Fanart"
        }
        ListElement {
            settingName: "Game Logo"
            setting: "Show,Text only,Hide"
        }
        ListElement {
            settingName: "Default to full details"
            label: "Open full details first"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Video preview"
            label: "Video previews"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Blur Background"
            label: "Blur background"
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
            settingName: "All Games View"
            setting: "List,Grid"
        }
        ListElement {
            settingName: "AllGames Video preview"
            label: "Video previews"
            setting: "Yes,No"
        }
        ListElement { settingName: "List view"; setting: ""; header: true }
        ListElement {
            settingName: "AllGames Hide box art on video"
            label: "Hide box art when preview plays"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "AllGames Hide logo on video"
            label: "Hide logo when preview plays"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "AllGames Blur Background"
            label: "Blur background"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "AllGames Show scanlines"
            label: "Show scanlines"
            setting: "No,Yes"
        }
        ListElement { settingName: "Grid view"; setting: ""; header: true }
        ListElement {
            settingName: "AllGames Match Platform"
            label: "Match Platform page"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "AllGames Tile Style"
            label: "Tile shape"
            setting: "Wide,Tall,Square,Box Art,3D Box"
        }
        ListElement {
            settingName: "AllGames Tile Ratio"
            label: "Tile ratio"
            setting: "0.66,0.67,0.68,0.69,0.70,0.71,0.72,0.73,0.74,0.75,0.76,0.77,0.78,0.79,0.80,0.81,0.82,0.83,0.84,0.85,0.86,0.87,0.88,0.89,0.90,0.91,0.92,0.93,0.94,0.95,0.96,0.97,0.98,0.99,0.25,0.26,0.27,0.28,0.29,0.30,0.31,0.32,0.33,0.34,0.35,0.36,0.37,0.38,0.39,0.40,0.41,0.42,0.43,0.44,0.45,0.46,0.47,0.48,0.49,0.50,0.51,0.52,0.53,0.54,0.55,0.56,0.57,0.58,0.59,0.60,0.61,0.62,0.63,0.64,0.65"
        }
        ListElement {
            settingName: "AllGames Tile Art"
            label: "Tile art"
            setting: "Fanart,Screenshot,Boxfront"
        }
        ListElement {
            settingName: "AllGames Tile Logo"
            label: "Show logo on tile"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "AllGames Items per row"
            label: "Tiles per row"
            setting: "3,4,5,6,7,8"
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

    property var settingsArr: [generalPage, showcasePage, collectionsPage, tilesPage, gridPage, allGamesPage, gamePage, mediaCarouselPage, audioPage, raPage, advancedPage]

    // ── Help text ─────────────────────────────────────────────────────────
    // In a function, not on the ListElements: a ListElement only accepts
    // literal values, so any string built with + is rejected and the whole
    // screen fails to load.
    function infoText(name) {
        if (name === "UI Scale") {
            return "Scales the ui text so small text can be read easier on handheld devices";
        }
        if (name === "High Quality Mode") {
            return "Extras for capable devices\n"
                 + "Leave it off on older or budget hardware\n"
                 + "\n"
                 + "WHEN ON\n"
                 + "\u2022 Sharper full-screen videos\n"
                 + "\u2022 Video previews start sooner\n"
                 + "\u2022 Crisper artwork and icons\n"
                 + "\u2022 Smoother transitions\n"
                 + "\u2022 A blurred backdrop behind the app drawer\n"
                 + "\n"
                 + "Off by default\n"
                 + "\n"
                 + "Theme reload recommended";
        }
        if (name === "Launch screen delay") {
            return "How long the launch screen stays up before launching your game,app, or emulator";
        }
        if (name === "Hide button help") {
            return "Hides all help prompts";
        }
        if (name === "Xbox Logo") {
            return "Logo displayed on top left of the home page\n"
                 + "\n"
                 + " \u2022 Logo 1 - Xbox sphere and text\n"
                 + " \u2022 Logo 2 - Xbox sphere only\n"
                 + " \u2022 RetroAchievments - Displays RA username, avatar, and stats (Log in required)\n"
                 + " \u2022 None - Shows nothing";
        }
        if (name === "Logo Color Match") {
            return "Tints the Xbox logo in the top corner to match your accent color";
        }
        if (name === "Showcase Collections Art") {
            return "The picture used on Home page tiles\n"
                 + "\n"
                 + "The game's fanart or a screenshot";
        }
        if (name === "Hero box art") {
            return "The picture used on the large hero tile at the start of the Home page's system row";
        }
        if (name === "System sort") {
            return "How the system row is arranged";
        }
        if (name === "Number of games showcased") {
            return "The max number of games shown on the home page per collection";
        }
        if (name === "Showcase Background Art") {
            return "Shows the highlighted game's fanart as the Showcase background, crossfading as you move between games\n"
                 + "\n"
                 + "Turn it off for a plain background \u2014 or your own image, if Custom Background is on";
        }
        if (name === "Screenshot Fallback") {
            return "If a game has no fanart, shows one of its screenshots as the background instead\n"
                 + "\n"
                 + "Off leaves the background plain for those games \u2014 or shows your own image, if Custom Background is on";
        }
        if (name === "Randomize System Tile Fanart") {
            return "Picks a random image from the highlighted collection's own fanart each time, instead of always using the same one\n"
                 + "\n"
                 + "The pick comes from that collection's games, so it changes as you move along the system row\n"
                 + "\n"
                 + "Needs Showcase Background Art on";
        }
        if (name === "Custom Background") {
            return "Shows your own image behind the Showcase\n"
                 + "\n"
                 + "TO USE YOUR OWN\n"
                 + "Rename the image to background.png and put it in the theme's assets/images/backgrounds folder\n"
                 + "\n"
                 + "Entries that do have fanart cover it completely, so this works alongside Showcase Background Art rather than replacing it. Turn that off to see your image behind the whole Showcase";
        }
        if (name === "Dynamic Background") {
            return "Gives the fanart slow, gentle motion \u2014 a gradual zoom and drift\n"
                 + "\n"
                 + "Applies to custom background as well";
        }
        if (name === "Showcase Background Opacity") {
            return "Transparency of home page background art";
        }
        if (name === "Always show titles") {
            return "When a game's name shows on its tile, on the Home page, Platform page and All Games grid\n"
                 + "\n"
                 + "ON FOCUS shows the name only on the tile you're on\n"
                 + "\n"
                 + "ALWAYS shows every name\n"
                 + "\n"
                 + "NEVER shows none, even on the highlighted tile";
        }
        if (name === "System tile titles") {
            return "When a system's name shows on its tile in the Home page's system row\n"
                 + "\n"
                 + "ON FOCUS shows it only on the tile you're on\n"
                 + "\n"
                 + "ALWAYS shows every name\n"
                 + "\n"
                 + "NEVER shows none";
        }
        if (name === "Tile Halo") {
            return "The soft glow around the highlighted tile, everywhere tiles appear";
        }
        if (name === "Favorited Tile Accent") {
            return "Marks favorited games with a colored edge on their tile, so they stand out while you scroll";
        }
        if (name === "Animate highlight") {
            return "A pulse animation on the highlighted tile accent";
        }
        if (name === "Game Counter") {
            return "Shows the live game count on the platform page and all games menu";
        }
        if (name === "Allow video thumbnails") {
            return "Plays a short preview video on the highlighted tile (Home & Platform page)";
        }
        if (name === "Hide logo when thumbnail video plays") {
            return "While a tile's preview video plays, hides the game's logo so it doesn't cover the video (Home & Platform page)";
        }
        if (name === "Featured Box") {
            return "The large featured tile on the Home page. Turn it off to remove it";
        }
        if (name === "Pins to collection") {
            return "Which collection row the featured tile sits with on the Home page";
        }
        if (name === "Featured Box Content") {
            return "What the featured tile shows: your Favorites, Discover videos, or a slideshow of fanart";
        }
        if (name === "All Games View") {
            return "How the All Games menu is shown\n"
                 + "\n"
                 + "LIST is a scrolling list with a preview panel and details\n"
                 + "\n"
                 + "GRID fills the page with tiles \u2014 no preview panel. Its own tile style, ratio, art and items-per-row are below, separate from the Platform page";
        }
        if (name === "AllGames Video preview") {
            return "Plays a short preview video for the highlighted game in the All Games menu (List & Grid mode)";
        }
        if (name === "AllGames Hide box art on video") {
            return "In the All Games list, hides the box art in the preview panel while the video plays";
        }
        if (name === "AllGames Hide logo on video") {
            return "In the All Games list, hides the game's logo while the preview video plays";
        }
        if (name === "AllGames Blur Background") {
            return "In the All Games list, softens the background artwork so the list stays easy to read";
        }
        if (name === "AllGames Show scanlines") {
            return "In the All Games list, draws faint scanlines over the preview for a retro look";
        }
        if (name === "AllGames Match Platform") {
            return "Use the Platform page's grid look for All Games Menu\n"
                 + "\n"
                 + "While this is on, the tile rows below follow the Platform page \u2014 change it there and All Games changes with it. The rows grey out because they aren't in use\n"
                 + "\n"
                 + "Turn it off and All Games goes back to its own settings, exactly as you had them";
        }
        if (name === "AllGames Tile Style") {
            return "The shape of each tile in the All Games grid";
        }
        if (name === "AllGames Tile Ratio") {
            return "How wide or tall All Games grid tiles are, as a proportion";
        }
        if (name === "AllGames Tile Art") {
            return "The picture used on All Games grid tiles";
        }
        if (name === "AllGames Tile Logo") {
            return "Shows the game's logo on each All Games grid tile";
        }
        if (name === "AllGames Items per row") {
            return "How many tiles fit across the All Games grid. Fewer means bigger tiles";
        }
        if (name === "Grid Thumbnail") {
            return "The shape of each tile on the Platform page";
        }
        if (name === "Grid Ratio") {
            return "How wide or tall Platform page tiles are, as a proportion";
        }
        if (name === "Grid art") {
            return "The picture used on Platform page tiles";
        }
        if (name === "Grid Game Logo") {
            return "Shows the game's logo on each Platform page tile";
        }
        if (name === "Number of columns") {
            return "How many tiles fit across the Platform page\n"
                 + "Fewer means bigger tiles";
        }
        if (name === "LB/RB Function") {
            return "What the shoulder buttons do on the Platform page\n"
                 + "\n"
                 + "CYCLE PLATFORMS moves to the previous or next system\n"
                 + "\n"
                 + "NAV BAR steps through the icons along the top \u2014 Home, Discover, Achievements, Settings \u2014 from wherever you are. Press Down to return to the games";
        }
        if (name === "Box Art") {
            return "How box art is drawn on the Game Details page: flat, as a 3D box, or as a mix image";
        }
        if (name === "More by Genre Display") {
            return "Which part of a game's genre the More by genre row on Game Details uses to find similar games. For a genre like Action / Platformer it can match on the whole thing, just Action, or just Platformer";
        }
        if (name === "Game Background") {
            return "The picture behind the Game Details page: a screenshot or the game's fanart";
        }
        if (name === "Game Logo") {
            return "If/How the games logo is displayed in Game Details page";
        }
        if (name === "Default to full details") {
            return "Opens Game Details straight onto the full description instead of the summary";
        }
        if (name === "Video preview") {
            return "Plays the game's preview video in the background of the Game Details page";
        }
        if (name === "Blur Background") {
            return "Softens the background picture on the Game Details page";
        }
        if (name === "Show scanlines") {
            return "In Games details, draws faint scanlines over the preview for a retro look";
        }
        if (name === "Video thumbnail audio") {
            return "Audio played from preview videos in the Home and Platform pages";
        }
        if (name === "Discover video audio") {
            return "Only affects Discover page; Audio for Discover videos in Featured box is controlled by \u201cVideo thumbnail audio\u201d";
        }
        if (name === "Game details video preview audio") {
            return "Audio played from preview videos in the Game Details page";
        }
        if (name === "All games menu video audio") {
            return "Audio played from preview videos in the All Games Menu (List & Grid modes)";
        }
        if (name === "Omit genre: Application from Showcase") {
            return "Keeps apps off the Home page\n"
                 + "\n"
                 + "Apps Pegasus found on its own are recognized automatically. For ones you added yourself, give them the genre tag \u201cApplication\u201d in their metadata and they'll be hidden too\n"
                 + "\n"
                 + "May need a theme reload";
        }
        if (name === "Omit genre: Emulator from Showcase") {
            return "Keeps emulators off the Home page\n"
                 + "\n"
                 + "Emulators Pegasus found on its own are recognized as applications and are affected by the \u201cHide Apps From Home\u201d option. For ones you added yourself, give them the genre tag \u201cEmulator\u201d in their metadata and they'll be hidden too\n"
                 + "\n"
                 + "May need a theme reload";
        }
        if (name === "Per-system tile settings") {
            return "Give each system its own tile look on the Platform page.\n\n"
                 + "When on, press Y on a Platform page to set that system's tile "
                 + "shape, ratio, art, logo, tiles per row and titles. Systems you "
                 + "don't change keep following this page.";
        }
        if (name === "Hide Android System Tile") {
            return "Hides the tile for the collection the App Drawer uses, so the same apps aren't in two places at once. Set this to No to keep the tile as well\n"
                 + "\n"
                 + "The drawer uses the collection named exactly \"Android\" \u2014 the one Pegasus creates when you enable app importing in its own settings\n"
                 + "\n"
                 + "SHORTNAME GUIDE\n"
                 + "\u2022 androidgames \u2014 for a collection of games you list yourself\n"
                 + "\u2022 android or androidapps \u2014 for apps you list yourself\n"
                 + "\n"
                 + "IMPORTANT\n"
                 + "The match is on the collection NAME, not the shortname. A collection using shortname \"android\" but named something else \u2014 \"Android Apps\", say \u2014 is NOT the one the drawer picks up while Pegasus app importing is on, because the imported \"Android\" collection wins\n"
                 + "\n"
                 + "Turn Pegasus app importing off and your own collection is used instead";
        }
        if (name === "Added App Launch") {
            return "What happens when you pick an app you added yourself from the Showcase\n"
                 + "\n"
                 + "There are two kinds of apps in the theme:\n"
                 + "\n"
                 + "Apps Pegasus found on its own \u2014 it only knows their name and icon. These always launch straight away, because there is nothing to show on a details page\n"
                 + "\n"
                 + "Apps you added yourself with a metadata file \u2014 these can have a description, genre and artwork, just like a game\n"
                 + "\n"
                 + "INSTANT launches apps you added straight away, like the rest\n"
                 + "\n"
                 + "DETAILS PAGE opens their details first, so you can see the artwork and media before launching";
        }
        if (name === "Show WiFi Indicator") {
            return "Shows a Wi-Fi symbol in the top corner";
        }
        if (name === "Show Battery Percentage") {
            return "What the battery shows in the top corner: just the icon, just the number, both, or nothing";
        }
        if (name === "Show Clock") {
            return "The clock in the top corner: 12-hour, 24-hour, or off";
        }
        return "";
    }

    // Cheap yes/no test. infoText() concatenates a lot of literals to build its
    // result, which is wasteful when all that's needed is whether one exists.
    // Mouse back button: mirrors B.
    function mouseBack() {
        if (infoOpen)  { infoOpen = false; settingsList.forceActiveFocus(); return; }
        if (!pagelist.activeFocus) { pagelist.forceActiveFocus(); return; }   // rows -> page list
        previousScreen();
    }

    function hasInfo(name) {
        return name === "UI Scale"
            || name === "High Quality Mode"
            || name === "Launch screen delay"
            || name === "Hide button help"
            || name === "Xbox Logo"
            || name === "Logo Color Match"
            || name === "Showcase Collections Art"
            || name === "Hero box art"
            || name === "System sort"
            || name === "Number of games showcased"
            || name === "Showcase Background Art"
            || name === "Screenshot Fallback"
            || name === "Randomize System Tile Fanart"
            || name === "Custom Background"
            || name === "Dynamic Background"
            || name === "Showcase Background Opacity"
            || name === "Always show titles"
            || name === "System tile titles"
            || name === "Tile Halo"
            || name === "Favorited Tile Accent"
            || name === "Animate highlight"
            || name === "Game Counter"
            || name === "Allow video thumbnails"
            || name === "Hide logo when thumbnail video plays"
            || name === "Featured Box"
            || name === "Pins to collection"
            || name === "Featured Box Content"
            || name === "All Games View"
            || name === "AllGames Video preview"
            || name === "AllGames Hide box art on video"
            || name === "AllGames Hide logo on video"
            || name === "AllGames Blur Background"
            || name === "AllGames Show scanlines"
            || name === "AllGames Match Platform"
            || name === "AllGames Tile Style"
            || name === "AllGames Tile Ratio"
            || name === "AllGames Tile Art"
            || name === "AllGames Tile Logo"
            || name === "AllGames Items per row"
            || name === "Grid Thumbnail"
            || name === "Grid Ratio"
            || name === "Grid art"
            || name === "Grid Game Logo"
            || name === "Number of columns"
            || name === "LB/RB Function"
            || name === "Box Art"
            || name === "More by Genre Display"
            || name === "Game Background"
            || name === "Game Logo"
            || name === "Default to full details"
            || name === "Video preview"
            || name === "Blur Background"
            || name === "Show scanlines"
            || name === "Video thumbnail audio"
            || name === "Discover video audio"
            || name === "Game details video preview audio"
            || name === "All games menu video audio"
            || name === "Omit genre: Application from Showcase"
            || name === "Omit genre: Emulator from Showcase"
            || name === "Hide Android System Tile"
            || name === "Added App Launch"
            || name === "Show WiFi Indicator"
            || name === "Show Battery Percentage"
            || name === "Show Clock";
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
                // Fresh install: no Index key saved yet, so show whichever entry
                // matches the theme's first-run default for this row. Previously
                // this fell to 0, which could disagree with what the theme was
                // actually using until the user touched the row.
                function defaultIndex() {
                    var d = settingDefaults[settingName];
                    if (d === undefined) return 0;
                    var i = settingList.indexOf(String(d));
                    return i >= 0 ? i : 0;
                }
                property int savedIndex: Math.min(
                    api.memory.has(settingName + 'Index') ? (api.memory.get(settingName + 'Index') || 0) : defaultIndex(),
                    settingList.length - 1)

                Connections {
                    target: settingsList
                    onSettingsVersionChanged: {
                        savedIndex = Math.min(
                            api.memory.has(settingName + 'Index') ? (api.memory.get(settingName + 'Index') || 0) : defaultIndex(),
                            settingList.length - 1);
                    }
                }
                property string itemNote: (typeof note !== 'undefined') ? note : ""
                // Optional friendly display label; storage key remains settingName
                property string displayLabel: (typeof label !== 'undefined' && label !== "") ? label : settingName
                // Section header rows: a label with a rule beneath, never
                // selectable. Declared with `header: true` in the page model.
                readonly property bool isHeader: (typeof header !== 'undefined') && header === true

                // Greyed-out/inert state — "Randomize System Tile Fanart" only has
                // an effect while the fanart background is showing, so it locks
                // when Showcase Background Art is off.
                //
                // It no longer locks on Custom Background: the two used to be
                // mutually exclusive, but the custom image is a base layer now
                // and fanart still runs on top of it.
                property bool rowDisabled: {
                    if (isHeader) return false;
                    var _v = settingsList.settingsVersion;   // re-evaluate after any save
                    // Both depend on the fanart background being shown at all.
                    // All Games: list rows are inert in Grid, grid rows in List.
                    // "All Games View" and "Video preview" apply to both.
                    var agGrid = (api.memory.has("All Games View")
                                ? api.memory.get("All Games View") : "List") === "Grid";
                    if (["AllGames Hide box art on video", "AllGames Hide logo on video",
                         "AllGames Blur Background", "AllGames Show scanlines"].indexOf(settingName) !== -1)
                        return agGrid;
                    if (settingName === "AllGames Match Platform") return !agGrid;
                    // The five tile rows are inert while matching the Platform page.
                    if (settingName.indexOf("AllGames Tile") === 0
                        || settingName === "AllGames Items per row") {
                        if (!agGrid) return true;
                        if ((api.memory.has("AllGames Match Platform")
                             ? api.memory.get("AllGames Match Platform") : "No") === "Yes") return true;
                        // Shape-dependent rows (this used to sit after a return above
                        // and never ran): Box Art greys art + logo; Square greys ratio.
                        var agShape = api.memory.has("AllGames Tile Style") ? api.memory.get("AllGames Tile Style") : "Wide";
                        if (settingName === "AllGames Tile Art" || settingName === "AllGames Tile Logo") return agShape === "Box Art" || agShape === "3D Box";
                        if (settingName === "AllGames Tile Ratio") return agShape === "Square";
                        return false;
                    }

                    if (settingName === "Randomize System Tile Fanart" || settingName === "Screenshot Fallback") {
                        var bgArt  = api.memory.has("Showcase Background Art") ? api.memory.get("Showcase Background Art") : "Yes";
                        return bgArt === "No";
                    }

                    // Small helper: current value of another row, with its default.
                    function mem(k, d) { return api.memory.has(k) ? api.memory.get(k) : d; }

                    // Dynamic Background moves whichever background is showing — fanart
                    // or the custom image — so it's only inert when neither is.
                    if (settingName === "Dynamic Background")
                        return mem("Showcase Background Art", "Yes") === "No" && mem("Custom Background", "No") === "No";
                    // Opacity applies to fanart AND the custom image; inert only when neither shows.
                    if (settingName === "Showcase Background Opacity")
                        return mem("Showcase Background Art", "Yes") === "No" && mem("Custom Background", "No") === "No";

                    // Sound master: with Menu sounds off, the volume and the chime are silent anyway.
                    if (settingName === "Menu Volume" || settingName === "Start up chime")
                        return mem("Menu sounds", "Yes") === "No";

                    // Logo tint only applies to the Xbox logos — not to None,
                    // and not to the RetroAchievements logo, which keeps its own colours.
                    if (settingName === "Logo Color Match") {
                        var xl = mem("Xbox Logo", "Logo1");
                        return xl === "None" || xl === "RetroAchievements";
                    }

                    // Showcase thumbnail previews: the logo-hide and audio rows do nothing without them.
                    if (settingName === "Hide logo when thumbnail video plays" || settingName === "Video thumbnail audio")
                        return mem("Allow video thumbnails", "Yes") === "No";

                    // Game Details preview video and its audio.
                    if (settingName === "Game details video preview audio")
                        return mem("Video preview", "Yes") === "No";

                    // All Games preview video and the rows that only matter while it plays.
                    if (settingName === "All games menu video audio"
                        || settingName === "AllGames Hide box art on video"
                        || settingName === "AllGames Hide logo on video")
                        return mem("AllGames Video preview", "Yes") === "No";

                    // Featured box off: its content and pin rows are moot.
                    if (settingName === "Featured Box Content" || settingName === "Pins to collection")
                        return mem("Featured Box", "Yes") === "No";

                    // A collection set to None has no thumbnail, size or ratio to configure.
                    var cm = settingName.match(/^(Collection \d) - (Thumbnail|Size|Ratio)$/);
                    if (cm && mem(cm[1], "") === "None") return true;
                    // A collection's Ratio row is inert when its shape is Square
                    if (settingName.indexOf("Collection ") === 0 && settingName.indexOf(" - Ratio") !== -1) {
                        var coll = settingName.replace(" - Ratio", "");
                        var shp = api.memory.has(coll + " - Thumbnail") ? api.memory.get(coll + " - Thumbnail") : "Wide";
                        return shp === "Square";
                    }
                    // Ratio is inert only for Square; Box Art scales with it on both grids.
                    if (settingName === "Grid Ratio") {
                        var gth = api.memory.has("Grid Thumbnail") ? api.memory.get("Grid Thumbnail") : "Wide";
                        return gth === "Square";
                    }
                    // Grid art / Grid Game Logo only apply to the Wide/Tall/Square
                    // tile styles — Box Art tiles always show the box art itself,
                    // so there's no art-source or logo-overlay choice to make.
                    // Box Art shape shows the box itself, so the art-source and logo
                    // rows have nothing to act on. Ratio and tiles-per-row stay live.
                    if (settingName === "Grid art" || settingName === "Grid Game Logo") {
                        var gth2 = api.memory.has("Grid Thumbnail") ? api.memory.get("Grid Thumbnail") : "Wide";
                        return gth2 === "Box Art" || gth2 === "3D Box";
                    }
                    return false;
                }

                // Text-input rows (RA credentials) skip the cycling logic
                property bool isTextInput: inputType === "text"
                property bool isEditing:   false
                property string originalText: ""

                // Writes another row's value AND its index, so the settings
                // screen displays it correctly on the next visit.
                function setOther(key, value, list) {
                    api.memory.set(key, value);
                    var i = list.indexOf(value);
                    if (i >= 0) api.memory.set(key + 'Index', i);
                }
                function saveSetting() {
                    if (isTextInput || rowDisabled) return;
                    api.memory.set(settingName + 'Index', savedIndex);
                    api.memory.set(settingName, settingList[savedIndex]);
                    // Box-front art already carries the game's name, so a logo on
                    // top is clutter: choosing it turns that grid's logo row off.
                    if (settingName === "Grid art" && settingList[savedIndex] === "Boxfront")
                        setOther("Grid Game Logo", "No", ["Yes", "No"]);
                    if (settingName === "AllGames Tile Art" && settingList[savedIndex] === "Boxfront")
                        setOther("AllGames Tile Logo", "No", ["Yes", "No"]);
                    // These two used to be mutually exclusive, each forcing the
                    // other off when enabled. They now layer instead: the custom
                    // image is the base and fanart paints over it, showing
                    // through only for entries that have no art of their own.
                    // Either of these changing can lock/unlock the randomize row
                    // Any row another row depends on refreshes the locks when saved.
                    var parents = ["Showcase Background Art", "Custom Background",
                                   "Omit genre: Application from Showcase", "Menu sounds", "Xbox Logo",
                                   "Allow video thumbnails", "Video preview", "AllGames Video preview",
                                   "Featured Box", "Grid Thumbnail", "All Games View",
                                   "AllGames Match Platform", "AllGames Tile Style"];
                    if (parents.indexOf(settingName) !== -1 || /^Collection \d$/.test(settingName)
                        || /^Collection \d - Thumbnail$/.test(settingName))
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
                height: isHeader ? vpx(44) : (itemNote !== "" ? itemheight + vpx(22) : itemheight)

                // Header rendering: green label, thin rule, nothing else.
                Text {
                    visible: isHeader
                    anchors { left: parent.left; leftMargin: vpx(4); bottom: headerRule.top; bottomMargin: vpx(6) }
                    text: settingName.toUpperCase()
                    color: theme.accent
                    font { family: subtitleFont.name; pixelSize: vpx(13); bold: true; letterSpacing: 1 }
                }
                Rectangle {
                id: headerRule
                    visible: isHeader
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: vpx(6) }
                    height: vpx(1); color: theme.secondary
                }

                // Selection tile
                Rectangle {
                id: setTile
                    visible: !isHeader
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
                    visible: !isHeader
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

                    visible: !isHeader && (!isTextInput)
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

                    visible: !isHeader && (!isTextInput)
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

                    visible: !isHeader && (isTextInput)
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

                    visible: !isHeader && (isTextInput)
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

                    visible: !isHeader && (itemNote !== "")
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
                    visible: !isHeader
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
                    visible: !isHeader
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
                            if (!isHeader) settingsList.currentIndex = index;
                        }
                    }
                }
            }
        } 

        onCurrentIndexChanged: root.rebuildHelpbar()
        onFocusChanged: root.rebuildHelpbar()

        // Wrap both ends, matching the page list on the left — dead-ending
        // partway down a long page was the odd one out.
        // Header rows are never landed on: step past them in either
        // direction, wrapping at both ends like before.
        function isHeaderAt(i) {
            var e = model.get(i);
            return !!e && e.header === true;
        }
        function step(dir) {
            if (count === 0) return;
            var i = currentIndex, tries = 0;
            do { i = (i + dir + count) % count; tries++; }
            while (isHeaderAt(i) && tries < count);
            currentIndex = i;
        }
        function firstSelectable() {
            for (var i = 0; i < count; i++) if (!isHeaderAt(i)) return i;
            return 0;
        }
        Keys.onUpPressed:   { playNav(); step(-1); }
        Keys.onDownPressed: { playNav(); step(1);  }
        // A page can open on a header (Home, Collections); move off it.
        onModelChanged: currentIndex = firstSelectable()
        Component.onCompleted: currentIndex = firstSelectable()
    }

    // Wheel moves the selected row.
    WheelNav {
        anchors.fill: settingsList
        view: settingsList
        columns: 1
        active: !infoOpen
        onStepped: function() { playNav(); }
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
                // Footer: the B glyph and "Back", drawn the same way the help
                // bar draws its buttons, right-aligned.
                Row {
                    anchors.right: parent.right
                    spacing: vpx(6)
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: vpx(18); height: vpx(18)
                        source: "../assets/images/controller/" + Utils.processButtonArt("cancel") + ".png"
                        sourceSize { width: Math.round(vpx(18) * 2); height: Math.round(vpx(18) * 2) }
                        smooth: true
                        opacity: 0.7
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Back"
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.family: subtitleFont.name
                        font.pixelSize: vpx(12)
                    }
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
