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
import QtGraphicalEffects 1.15   // DropShadow: the rail's focused plate glow
import "../Global"
import "../utils.js" as Utils
import "../buildinfo.js" as BuildInfo

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
        onWheel: wheel.accepted = true   // the wheel stops here too, not on the screen behind
        onClicked: mouse.accepted = true
        onReleased: mouse.accepted = true
    }

    // ── General ──
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
            settingName: "Startup intro"
            setting: "Yes,No"
        }
    }

    property var generalPage: {
        return {
            pageName: "General",
            listmodel: settingsModel,
            lead: "How the theme behaves: scale, quality, launch and mouse."
        }
    }

    // ── Appearance ──
    ListModel {
    id: appearanceSettingsModel

        ListElement { settingName: "Colors"; setting: ""; header: true }
        ListElement {
            settingName: "Color Background"
            label: "Background color"
            setting: "White,Light Gray,Silver,Cool Gray,Gray,Mid Gray,Dark Gray,Charcoal,Black,Light Blue,Steel Blue,Slate,Dark Steel,Dark Blue,Navy Blue,Midnight Blue,Teal,Dark Teal,Sage,Forest,Forest Green,Dark Green,Rose,Dark Red,Wine,Burgundy,Plum,Dark Purple,Deep Purple,Indigo,Tan,Dark Orange,Dark Brown"
        }
        ListElement {
            settingName: "Color Layout"
            label: "Accent color"
            setting: "White,Silver,Light Gray,Stone,Mid Gray,Steel,Slate,Dark Gray,Gunmetal,Charcoal,Onyx,Ice Blue,Arctic,Sky Blue,Light Blue,Cyan,Royal Blue,Cobalt,Sapphire,Dark Blue,Navy Blue,Seafoam,Turquoise,Teal,Dark Teal,Mint,Lime,Light Green,Jade,Emerald,Sage,Olive,Dark Green,Forest Green,Yellow,Gold,Amber,Dark Gold,Orange,Dark Orange,Coral,Salmon,Copper,Bronze,Rust,Sienna,Light Pink,Hot Pink,Rose,Dark Pink,Magenta,Light Red,Ruby,Crimson,Dark Red,Brick Red,Maroon,Burgundy,Lavender,Violet,Purple,Dark Purple,Indigo,Tan,Light Brown,Dark Brown"
        }
        ListElement {
            settingName: "Grid background dimming"
            label: "Background dimming"
            setting: "Off,Light,Medium,Strong"
        }
        ListElement {
            settingName: "Bottom fade"
            label: "Bottom fade"
            setting: "Off,Light,Medium,Strong"
        }
        ListElement { settingName: "Tiles"; setting: ""; header: true }
        ListElement {
            settingName: "Tile Halo"
            label: "Frame glow"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Favorited Tile Accent"
            label: "Favorite tile accent"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Game Counter"
            label: "Show game count"
            setting: "Yes,No"
        }
    }

    property var appearancePage: {
        return {
            pageName: "Appearance",
            listmodel: appearanceSettingsModel,
            lead: "Colors, background shading and how tiles are drawn."
        }
    }

    // ── Home ──
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
            settingName: "Hero box art"
            label: "Hero tile art"
            setting: "Fanart,Boxfront,Screenshot"
        }
        ListElement {
            settingName: "Showcase Collections Art"
            label: "Row tile art"
            setting: "Fanart,Screenshot"
        }
        ListElement {
            settingName: "System sort"
            setting: "Alphabetical (A-Z),Alphabetical (Z-A),Release year (oldest),Release year (newest),Manufacturer,Game count (most),Game count (fewest),Default"
        }
        ListElement {
            settingName: "Number of games showcased"
            setting: "15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,1,2,3,4,5,6,7,8,9,10,11,12,13,14"
        }
        ListElement { settingName: "Titles"; setting: ""; header: true }
        ListElement {
            settingName: "System tile titles"
            label: "System row titles"
            setting: "On focus,Always,Never"
        }
        ListElement {
            settingName: "Always show titles"
            label: "Collection row titles"
            setting: "On focus,Always,Never"
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
            pageName: "Home",
            listmodel: showcaseSettingsModel,
            lead: "The Home page: logo, hero tile, titles and the background."
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
        ListElement { settingName: "While a preview plays"; setting: ""; header: true }
        ListElement {
            settingName: "Hide logo when thumbnail video plays"
            label: "Hide logo"
            setting: "No,Yes"
        }
    }

    property var collectionsPage: {
        return {
            pageName: "Home rows",
            listmodel: collectionsSettingsModel,
            lead: "What each Home row shows and how its tiles look."
        }
    }

    // ── Library: All Games and Systems, set separately (a system can have its own: Y on it) ──
    ListModel {
    id: librarySettingsModel

        ListElement { settingName: "All Games"; setting: ""; header: true }
        ListElement {
            settingName: "All Games View"
            label: "View"
            setting: "List,Grid"
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
            settingName: "AllGames Items per row"
            label: "Tiles per row"
            setting: "3,4,5,6,7,8"
        }
        ListElement {
            settingName: "AllGames Tile Art"
            label: "Tile art"
            setting: "Fanart,Screenshot,Boxfront"
        }
        ListElement {
            settingName: "AllGames Tile Logo"
            label: "Logo on tile"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "AllGames Tile titles"
            label: "Tile titles"
            setting: "On focus,Always,Never"
        }
        ListElement { settingName: "Systems"; setting: ""; header: true }
        ListElement {
            settingName: "Systems View"
            label: "View"
            setting: "List,Grid"
        }
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
            settingName: "Number of columns"
            label: "Tiles per row"
            setting: "3,4,5,6,7,8"
        }
        ListElement {
            settingName: "Grid art"
            label: "Tile art"
            setting: "Fanart,Screenshot,Boxfront"
        }
        ListElement {
            settingName: "Grid Game Logo"
            label: "Logo on tile"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Systems Tile titles"
            label: "Tile titles"
            setting: "On focus,Always,Never"
        }
        ListElement { settingName: "List view"; setting: ""; header: true }
        ListElement {
            settingName: "AllGames Blur Background"
            label: "Blurred background"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "AllGames Show scanlines"
            label: "Scanlines"
            setting: "No,Yes"
        }
        ListElement { settingName: "While a preview plays"; setting: ""; header: true }
        ListElement {
            settingName: "AllGames Grid hide logo on video"
            label: "Grid: hide logo"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "AllGames List hide on video"
            label: "List: hide"
            setting: "None,Box art,Logo,Both"
        }
        ListElement { settingName: "Navigation"; setting: ""; header: true }
        ListElement {
            settingName: "LB/RB Function"
            label: "LB/RB on a system"
            setting: "Cycle Platforms,Nav Bar"
        }
    }

    property var libraryPage: {
        return {
            pageName: "Library",
            listmodel: librarySettingsModel,
            lead: "All Games and the systems are set separately. A system follows Systems unless you give it its own settings with Y while you're on it.",
            grid: "library"
        }
    }

    // ── Game details (Media carousel items included) ──
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
            setting: "Screenshot,Fanart,Banner"
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
            settingName: "Blur Background"
            label: "Blur background"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Show scanlines"
            setting: "Yes,No"
        }
        ListElement { settingName: "More like this"; setting: ""; header: true }
        ListElement {
            settingName: "Details rows hide logo on video"
            label: "Hide logo while a preview plays"
            setting: "Yes,No"
        }
        ListElement { settingName: "Media carousel"; setting: ""; header: true }
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
            label: "Physical Media"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Miximage"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Banner"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Logo"
            setting: "Yes,No"
        }
    }

    property var gamePage: {
        return {
            pageName: "Game details",
            listmodel: gameSettingsModel,
            lead: "The Game details page and the items in its media carousel."
        }
    }

    // ── Previews & sound: every video preview and every sound, one group per screen ──
    ListModel {
    id: previewsSettingsModel

        ListElement { settingName: "Everywhere"; setting: ""; header: true }
        ListElement {
            settingName: "Video previews"
            label: "All video previews"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Preview sound"
            label: "All preview sound"
            setting: "Yes,No"
        }
        ListElement { settingName: "Home rows"; setting: ""; header: true }
        ListElement {
            settingName: "Allow video thumbnails"
            label: "Preview"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Video thumbnail audio"
            label: "Sound"
            setting: "No,Yes"
        }
        ListElement { settingName: "Library"; setting: ""; header: true }
        ListElement {
            settingName: "AllGames Video preview"
            label: "Preview"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "All games menu video audio"
            label: "Sound"
            setting: "No,Yes"
        }
        ListElement { settingName: "Game details · background"; setting: ""; header: true }
        ListElement {
            settingName: "Video preview"
            label: "Preview"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Game details video preview audio"
            label: "Sound"
            setting: "No,Yes"
        }
        ListElement { settingName: "Game details · More like this"; setting: ""; header: true }
        ListElement {
            settingName: "Details rows video preview"
            label: "Preview"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Details rows video audio"
            label: "Sound"
            setting: "Yes,No"
        }
        ListElement { settingName: "Discover"; setting: ""; header: true }
        ListElement {
            settingName: "Media viewer video audio"
            label: "Sound"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Discover video audio"
            label: "Sound"
            setting: "No,Yes"
        }
        ListElement { settingName: "Menu sounds"; setting: ""; header: true }
        ListElement {
            settingName: "Menu sounds"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Menu Volume"
            label: "Volume"
            setting: "1.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9"
        }
        ListElement {
            settingName: "Start up chime"
            label: "Startup chime"
            setting: "Yes,No"
        }
    }

    property var previewsPage: {
        return {
            pageName: "Previews & sound",
            listmodel: previewsSettingsModel,
            lead: "Where video previews play, and their sound. The switches at the top turn them off everywhere and keep your choices.",
            grid: "previews"
        }
    }

    // ── System (status bar, apps, diagnostics) ──
    ListModel {
    id: advancedSettingsModel

        ListElement { settingName: "Home"; setting: ""; header: true }
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
        ListElement { settingName: "Apps"; setting: ""; header: true }
        ListElement {
            settingName: "Hide Android System Tile"
            setting: "Yes,No"
        }
        ListElement {
            settingName: "Hide Android Games System Tile"
            setting: "No,Yes"
        }
        ListElement {
            settingName: "Added App Launch"
            setting: "Instant,Details Page"
        }
        ListElement { settingName: "Status bar"; setting: ""; header: true }
        ListElement {
            settingName: "Show WiFi Indicator"
            label: "Wi-Fi indicator"
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
        ListElement { settingName: "Diagnostics"; setting: ""; header: true }
        // One read-only panel with every line (no More info: it said the same).
        ListElement { settingName: "Diagnostics panel"; setting: ""; panel: true }
        ListElement {
            settingName: "Frame counter"
            label: "Frame rate counter"
            setting: "No,Yes"
        }
        ListElement { settingName: "Write diagnostics to log"; setting: ""; tip: true }
    }

    property var advancedPage: {
        return {
            pageName: "System",
            listmodel: advancedSettingsModel,
            lead: "Hiding apps and emulators, the status bar, and diagnostics for bug reports."
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
            listmodel: raSettingsModel,
            lead: "Your RetroAchievements account."
        }
    }


    // ── Tips & Tricks ─────────────────────────────────────────────────────
    // Read-only page: the lesser-known behaviours that have no button prompt
    // anywhere on screen. Each `tip: true` row has no value to cycle; A or X
    // opens its text (tipTexts below) in the shared More info panel.
    // Every element declares both `header` and `tip` so the roles are fixed
    // from the first element on.
    ListModel {
    id: tipsSettingsModel

        ListElement { settingName: "Navigation"; setting: ""; header: true; tip: false }
        ListElement { settingName: "Discover follows the system"; setting: ""; header: false; tip: true }
        ListElement { settingName: "Jump by letter"; setting: ""; header: false; tip: true }
        ListElement { settingName: "Shortcut to the nav bar"; setting: ""; header: false; tip: true }
        ListElement { settingName: "Skipping in Discover"; setting: ""; header: false; tip: true }
        ListElement { settingName: "Mouse support"; setting: ""; header: false; tip: true }
        ListElement { settingName: "Home page"; setting: ""; header: true; tip: false }
        ListElement { settingName: "The hero tile"; setting: ""; header: false; tip: true }
        ListElement { settingName: "Random rows stay put"; setting: ""; header: false; tip: true }
        ListElement { settingName: "Library"; setting: ""; header: true; tip: false }
        ListElement { settingName: "Per-system tiles"; setting: ""; header: false; tip: true }
        ListElement { settingName: "Search"; setting: ""; header: true; tip: false }
        ListElement { settingName: "Forgiving search"; setting: ""; header: false; tip: true }
        ListElement { settingName: "App drawer"; setting: ""; header: true; tip: false }
        ListElement { settingName: "The Hidden tab"; setting: ""; header: false; tip: true }
        ListElement { settingName: "Moving apps between tabs"; setting: ""; header: false; tip: true }
        ListElement { settingName: "Duplicate apps"; setting: ""; header: false; tip: true }
        ListElement { settingName: "Customizing"; setting: ""; header: true; tip: false }
        ListElement { settingName: "Your own system backgrounds"; setting: ""; header: false; tip: true }
    }

    property var tipsPage: {
        return {
            pageName:  "Tips & Tricks",
            listmodel: tipsSettingsModel,
            lead: "Things worth knowing that no button prompt tells you."
        }
    }

    // Diagnostics on the System page: the panel's lines (name, value).
    function diagLines() {
        return [
            ["Theme build", BuildInfo.build + " (" + BuildInfo.branch + ", " + BuildInfo.date + ")"],
            ["Frontend",    platform.frontendLine],
            ["Features",    platform.featureLine],
            ["Display",     platform.os + ", " + Math.round(root.width) + "x" + Math.round(root.height) + ", UI scale " + settings.UiScale + ", HQ " + (hqMode ? "on" : "off")],
            ["Library",     api.allGames.count + " games, " + api.collections.count + " collections"]
        ];
    }
    // Long-form labels (diagnosticsText and older callers).
    function diagLabel(name) {
        switch (name) {
        case "Theme build":  return "Theme build " + BuildInfo.build + " (" + BuildInfo.branch + ", " + BuildInfo.date + ")";
        case "Frontend":     return "Frontend: " + platform.frontendLine;
        case "Features":     return "Features: " + platform.featureLine;
        case "Display":      return "Display: " + platform.os + ", " + Math.round(root.width) + "x" + Math.round(root.height) + ", UI scale " + settings.UiScale + ", HQ " + (hqMode ? "on" : "off");
        case "Library size": return "Library: " + api.allGames.count + " games, " + api.collections.count + " collections";
        }
        return name;
    }

    // ── Grid pages (Settings/SettingsGrid.qml) ────────────────────────────
    // The option string of a row as its ListModel declares it, so a grid
    // card writes the same "<key>Index" the list row would.
    function optsOf(model, key) {
        for (var i = 0; i < model.count; i++) {
            var e = model.get(i);
            if (e.settingName === key && e.header !== true) return e.setting;
        }
        return "Yes,No";
    }
    readonly property var onOff: ({ "Yes": "On", "No": "Off" })
    readonly property var volumeShow: ({ "1.0": "100%", "0.1": "10%", "0.2": "20%", "0.3": "30%", "0.4": "40%",
                                         "0.5": "50%", "0.6": "60%", "0.7": "70%", "0.8": "80%", "0.9": "90%" })

    // Previews & sound: one row per screen, one column per setting.
    function previewsCells() {
        var m = previewsSettingsModel, out = [], r = 0;
        function v(row, col, key, extra) {
            var c = { kind: "value", row: row, col: col, key: key, opts: optsOf(m, key), show: onOff };
            for (var k in extra) c[k] = extra[k];
            out.push(c);
        }
        function none(row, col, t) { out.push({ kind: "label", row: row, col: col, text: t || "—", dim: true }); }
        // Re-built when a master switch changes: Off hides what it covers
        // instead of greying out rows that still read "On".
        var e = settingsEpoch;
        var previewsOn = settingsStore.get("Video previews", "Yes") !== "No";
        var soundOn    = settingsStore.get("Preview sound", "Yes") !== "No";
        out.push({ kind: "header", row: r, col: 0, span: 3, text: "Everywhere" }); r++;
        v(r, 0, "Video previews", { label: "Video previews" });
        v(r, 1, "Preview sound",  { label: "Preview sound", span: 2 });
        r++;
        out.push({ kind: "header", row: r, col: 0, span: 3, text: "Where previews play" }); r++;
        if (!previewsOn) {
            out.push({ kind: "label", row: r, col: 0, span: 3, h: vpx(64),
                       text: "Video previews are off everywhere",
                       sub: "Turn them on to choose where they play. Your choices are kept." });
            r++;
        } else {
            out.push({ kind: "colhead", row: r, col: 1, text: "Preview" });
            if (soundOn) out.push({ kind: "colhead", row: r, col: 2, text: "Sound" });
            r++;
            var screens = [
                { t: "Home rows",      s: "The highlighted tile",        p: "Allow video thumbnails", a: "Video thumbnail audio" },
                { t: "Library",        s: "All Games and every system",  p: "AllGames Video preview", a: "All games menu video audio" },
                { t: "Game details",   s: "Behind the page",             p: "Video preview",          a: "Game details video preview audio" },
                { t: "More like this", s: "The rows under Game details", p: "Details rows video preview", a: "Details rows video audio" }
            ];
            for (var i = 0; i < screens.length; i++, r++) {
                var sc = screens[i];
                out.push({ kind: "label", row: r, col: 0, text: sc.t, sub: sc.s });
                v(r, 1, sc.p);
                // A screen with its preview off has no sound to set: "—", not a greyed "On".
                if (soundOn) { if (settingsStore.get(sc.p) === "No") none(r, 2); else v(r, 2, sc.a); }
            }
        }
        // Discover and the media viewer always play their video: only the
        // sound is a choice.
        if (soundOn) {
            out.push({ kind: "label", row: r, col: 0, text: "Media viewer", sub: "A video opened from Game details' media" });
            none(r, 1, "Always");
            v(r, 2, "Media viewer video audio");
            r++;
            out.push({ kind: "label", row: r, col: 0, text: "Discover", sub: "Always plays its video" });
            none(r, 1, "Always");
            v(r, 2, "Discover video audio");
            r++;
        }
        out.push({ kind: "header", row: r, col: 0, span: 3, text: "Menu sounds" }); r++;
        v(r, 0, "Menu sounds", { label: "Menu sounds" });
        v(r, 1, "Menu Volume", { label: "Volume", span: 2, show: volumeShow });
        r++;
        v(r, 0, "Start up chime", { label: "Startup chime" });
        return out;
    }

    // Library: All Games and Systems side by side, then the list-view and
    // navigation rows, then every system that has its own settings.
    property int libraryRev: 0
    function libraryCells() {
        var e = libraryRev;
        var m = librarySettingsModel, out = [], r = 0;
        function v(row, col, key, label, extra) {
            var c = { kind: "value", row: row, col: col, key: key, label: label, opts: optsOf(m, key) };
            for (var k in extra) c[k] = extra[k];
            out.push(c);
        }
        out.push({ kind: "header", row: r, col: 0, text: "All Games" });
        out.push({ kind: "header", row: r, col: 1, text: "Systems · default for every system" });
        r++;
        var rows = [
            ["View",          "All Games View",         "Systems View",        null],
            ["Tile shape",    "AllGames Tile Style",    "Grid Thumbnail",      null],
            ["Tile ratio",    "AllGames Tile Ratio",    "Grid Ratio",          null],
            ["Tiles per row", "AllGames Items per row", "Number of columns",   null],
            ["Tile art",      "AllGames Tile Art",      "Grid art",            null],
            ["Logo on tile",  "AllGames Tile Logo",     "Grid Game Logo",      onOff],
            ["Tile titles",   "AllGames Tile titles",   "Systems Tile titles", null]
        ];
        for (var i = 0; i < rows.length; i++, r++) {
            var x = rows[i];
            v(r, 0, x[1], x[0], x[3] ? { show: x[3] } : {});
            v(r, 1, x[2], x[0], x[3] ? { show: x[3] } : {});
        }
        out.push({ kind: "header", row: r, col: 0, span: 2, text: "While a preview plays" }); r++;
        v(r, 0, "AllGames Grid hide logo on video", "Grid: hide logo", { show: onOff });
        v(r, 1, "AllGames List hide on video",      "List: hide");
        r++;
        out.push({ kind: "header", row: r, col: 0, span: 2, text: "List view & navigation" }); r++;
        v(r, 0, "AllGames Blur Background", "Blurred background", { show: onOff });
        v(r, 1, "AllGames Show scanlines",  "Scanlines",          { show: onOff });
        r++;
        v(r, 0, "LB/RB Function", "LB / RB on a system", { span: 2 });
        r++;
        out.push({ kind: "header", row: r, col: 0, span: 2, text: "Systems with their own settings" }); r++;
        var any = false;
        for (var c = 0; c < api.collections.count; c++) {
            var coll = api.collections.get(c), sn = coll.shortName || "";
            if (!sn || settingsStore.get(sn + " - Use theme settings", "Yes") !== "No") continue;
            any = true;
            var view = settingsStore.get(sn + " - View", "");
            var sub = view === "Grid"
                ? "Grid · " + settingsStore.get(sn + " - Tile shape", "") + " · " + settingsStore.get(sn + " - Tiles per row", "") + " per row"
                : "List";
            out.push({ kind: "item", row: r, col: 0, span: 2, text: coll.name, sub: sub, sys: sn, action: "Back to Systems" });
            r++;
        }
        if (!any)
            out.push({ kind: "label", row: r, col: 0, span: 2, text: "None yet", sub: "Press Y while viewing a system to give it its own settings" });
        return out;
    }

    readonly property var currentPage: settingsArr[pagelist.currentIndex]
    readonly property string gridPage: (currentPage && currentPage.grid) ? currentPage.grid : ""
    // Focus the page's content: its grid, or its list.
    function focusContent() {
        if (gridPage !== "") settingsGrid.forceActiveFocus();
        else settingsList.forceActiveFocus();
        rebuildHelpbar();
    }

    property var settingsArr: [generalPage, appearancePage, showcasePage, collectionsPage, libraryPage, gamePage, previewsPage, raPage, advancedPage, tipsPage]

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
            return "When a game's name shows on its tile, on the Home page and in the Library\n"
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
            return "The soft glow just outside the highlighted tile's frame, everywhere tiles appear";
        }
        if (name === "Favorited Tile Accent") {
            return "Marks favorited games with a colored edge on their tile, so they stand out while you scroll";
        }
        if (name === "Game Counter") {
            return "Shows the live game count at the top of the Library";
        }
        if (name === "Frame counter") {
            return "Shows frames per second and the slowest frame in the top-left corner"
                 + "\n"
                 + "At 60 fps each frame has about 17 ms; a worst well past that is a visible stutter";
        }
        if (name === "Allow video thumbnails") {
            return "Plays a short preview video on the highlighted tile in the Home rows";
        }
        if (name === "Hide logo when thumbnail video plays" || name === "AllGames Grid hide logo on video"
            || name === "Systems Grid hide logo on video" || name === "Details rows hide logo on video") {
            return "The tile's art always fades away when its preview plays; this hides the game's logo too";
        }
        if (name === "AllGames List hide on video" || name === "Systems List hide on video") {
            return "In the list view the screenshot always gives way to the preview; this also hides the box art, the logo, both, or neither while it plays";
        }
        if (name === "Systems Video preview") {
            return "Plays a short preview for the highlighted game when viewing a system (any system without its own settings)";
        }
        if (name === "Details rows video preview") {
            return "Plays a short preview on the highlighted tile in Game details' \u201cMore like this\u201d rows";
        }
        if (name === "All Games View") {
            return "How All Games is shown (systems have their own View under Systems)\n"
                 + "\n"
                 + "LIST is a scrolling list with a preview panel and details\n"
                 + "\n"
                 + "GRID fills the page with tiles \u2014 no preview panel";
        }
        if (name === "Systems View") {
            return "How every system is shown, unless it has its own settings (Y while viewing it)";
        }
        if (name === "AllGames Tile titles" || name === "Systems Tile titles") {
            return "When the game's name shows on its tile: on the highlighted tile, always, or never";
        }
        if (name === "AllGames Video preview") {
            return "Plays a short preview video for the highlighted game in the Library (List & Grid)";
        }
        if (name === "AllGames Blur Background") {
            return "In the list view (All Games and systems), softens the background artwork so the list stays easy to read";
        }
        if (name === "AllGames Show scanlines") {
            return "In the list view (All Games and systems), draws faint scanlines over the preview for a retro look";
        }
        if (name === "AllGames Tile Style") {
            return "The shape of each tile when viewing All Games";
        }
        if (name === "AllGames Tile Ratio") {
            return "How wide or tall All Games tiles are, as a proportion";
        }
        if (name === "AllGames Tile Art") {
            return "The picture used on All Games tiles";
        }
        if (name === "AllGames Tile Logo") {
            return "Shows the game's logo on each All Games tile";
        }
        if (name === "AllGames Items per row") {
            return "How many tiles fit across when viewing All Games. Fewer means bigger tiles";
        }
        if (name === "Grid Thumbnail") {
            return "The shape of each tile when viewing one system";
        }
        if (name === "Grid Ratio") {
            return "How wide or tall a system's tiles are, as a proportion";
        }
        if (name === "Grid art") {
            return "The picture used on a system's tiles";
        }
        if (name === "Grid Game Logo") {
            return "Shows the game's logo on each of a system's tiles";
        }
        if (name === "Number of columns") {
            return "How many tiles fit across when viewing one system\n"
                 + "Fewer means bigger tiles";
        }
        if (name === "LB/RB Function") {
            return "What the shoulder buttons do while viewing one system\n"
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
        if (name === "Media viewer video audio") {
            return "Sound for a video you open full screen from the media row on Game details. Off keeps it silent. Preview sound Off at the top mutes it too";
        }
        if (name === "Video previews") {
            return "Off stops every video preview at once: Home rows, the Library, Game details and its rows. Each screen keeps its own choice, so turning this back On restores them. Discover always plays";
        }
        if (name === "Preview sound") {
            return "Off mutes every preview, Discover included. Each screen keeps its own Sound choice, so turning this back On restores them";
        }
        if (name === "Game Background") {
            return "The picture behind the Game Details page: a screenshot, the game's fanart, or its banner. A game with no banner shows its fanart instead";
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
            return "Audio played from preview videos on the Home page";
        }
        if (name === "Discover video audio") {
            return "Audio for the videos on the Discover page";
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
                 + "Apps Pegasus found on its own are recognized automatically. For ones you added yourself, give them the genre tag \u201cApplication\u201d in their metadata and they'll be hidden too. Apps in the App Drawer's Games or Emulators sections aren't counted as apps here";
        }
        if (name === "Omit genre: Emulator from Showcase") {
            return "Keeps emulators off the Home page\n"
                 + "\n"
                 + "Apps Pegasus found on its own follow the App Drawer: anything in its Emulators section is hidden, including apps you moved there yourself. For ones you added yourself, give them the genre tag \u201cEmulator\u201d in their metadata and they'll be hidden too";
        }
        if (name === "Grid background dimming") {
            return "Slightly darkens the area below the header in the "
                 + "Library, Game Details and the Achievements pages, so "
                 + "tiles, text and lists stand out.\n\n"
                 + "OFF leaves it as is. Turn it up if things blend into the "
                 + "background.";
        }
        if (name === "Bottom fade") {
            return "How strongly the last row fades out above the button "
                 + "prompts at the bottom of the Library, "
                 + "Game Details and the Achievements pages.\n\n"
                 + "OFF removes the fade. STRONG is the full fade, so the "
                 + "prompts always sit on a clean background.";
        }
        if (name === "Hide Android System Tile") {
            return "Hides the Android app tiles from the system row, since the App Drawer already has these apps. Set this to No to keep the tiles as well\n"
                 + "\n"
                 + "COVERS\n"
                 + "\u2022 The collection named \"Android\" \u2014 the one Pegasus creates when you turn on app importing, plus any collection of yours also named \"Android\" (Pegasus merges them)\n"
                 + "\u2022 Collections with the shortname android \u2014 apps you list yourself\n"
                 + "\n"
                 + "Android games (shortname androidgames) have their own option below\n"
                 + "\n"
                 + "Theme reload recommended";
        }
        if (name === "Hide Android Games System Tile") {
            return "Hides the tile for your Android games collection \u2014 the one with the shortname androidgames \u2014 from the system row\n"
                 + "\n"
                 + "Off by default\n"
                 + "\n"
                 + "Theme reload recommended";
        }
        if (name === "Added App Launch") {
            return "What happens when you pick an app or Android game you added yourself, anywhere outside the App Drawer\n"
                 + "\n"
                 + "Apps Pegasus found on its own \u2014 it only knows their name and icon. These always launch straight away, because there is nothing to show on a details page\n"
                 + "\n"
                 + "Entries you added yourself with a metadata file \u2014 these can have a description, genre and artwork, just like a game. This option covers:\n"
                 + "\u2022 Anything in a collection named \"Android\", or with the shortname android or androidgames\n"
                 + "\u2022 Anything tagged with the genre \u201cApplication\u201d or \u201cEmulator\u201d, in any collection\n"
                 + "\n"
                 + "INSTANT launches them straight away, like the rest\n"
                 + "\n"
                 + "DETAILS PAGE opens their details first, so you can see the artwork and media before launching\n"
                 + "\n"
                 + "The App Drawer always launches straight away";
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
        if (name === "Theme build" || name === "Frontend" || name === "Features" || name === "Display" || name === "Library size")
            return diagnosticsText();
        if (name === "Write diagnostics to log")
            return "Writes the lines above to lastrun.log so you can send them with a bug report";
        return tipTexts.hasOwnProperty(name) ? tipTexts[name] : "";
    }

    // Text for each row on the Tips & Tricks page, keyed by its settingName.
    // infoText() falls back to this, and hasInfo() checks it, so tips use the
    // same More info panel as settings.
    readonly property var tipTexts: ({
        "Discover follows the system":
            "Open Discover while viewing one system in the Library and it only plays that system's games\nOpen it from anywhere else and it covers your whole library",
        "Jump by letter":
            "In the Library and in search results, LT and RT jump to the previous or next letter",
        "Shortcut to the nav bar":
            "On the Home page and Game details, LB or RB jumps straight up to the nav bar along the top\nOn the Home page, coming back down returns you to the row you were on",
        "Skipping in Discover":
            "LB, RB, Left and Right all skip to another game\nWhen a video ends, Discover moves on to the next one by itself",
        "Mouse support":
            "The mouse wheel moves the selection through lists and grids, and the mouse back button works like B",
        "The hero tile":
            "The large tile at the start of the Home page's system row is always the game you played most recently. Press A to jump straight back in",
        "Random rows stay put":
            "Rows like Recommended and Top by Genre keep their picks until you press Refresh (X) on the Home page\nTwo rows set to System always pick different systems",
        "Per-system tiles":
            "Every system follows Settings \u203a Library \u203a Systems until you give it its own settings: press Y while viewing it\nX in that panel sends it back to following Systems",
        "Forgiving search":
            "Search ignores capitals, punctuation and region tags like (USA)\nIt also finds \u201cLegend of Zelda, The\u201d when you type \u201cThe Legend of Zelda\u201d",
        "The Hidden tab":
            "The App Drawer's Hidden tab only appears once something is hidden\nThe first tile along the bottom of the drawer shows or hides it",
        "Moving apps between tabs":
            "Moving an app to another tab (Start \u2192 Move to) is remembered, and overrides both the automatic sorting and the app's genre tag\nUse Reset to automatic to undo it",
        "Duplicate apps":
            "An app that's in both the Pegasus import and your own collection is only shown once, with your entry taking priority\nThe two names must match exactly",
        "Your own system backgrounds":
            "Put an image in the theme's assets/images/systembackground folder, named after the system's shortname (for example snes.png)\nIt shows behind the Home page when that system's tile is highlighted. PNG, JPG, JPEG and WEBP all work"
    })

    // Cheap yes/no test. infoText() concatenates a lot of literals to build its
    // result, which is wasteful when all that's needed is whether one exists.
    // Mouse back button: mirrors B.
    // Clickable prompts (theme.qml helpClick). The grid answers its own
    // A and X; this is the list's More info. B is left to mouseBack().
    function helpAction(button) {
        if (kbOpen) return true;                  // the keyboard has its own keys
        if (infoOpen) { if (button === "cancel" || button === "details") { playBack(); closeInfo(); } return true; }
        if (button === "details" && settingsList.activeFocus) {
            var page = settingsArr[pagelist.currentIndex];
            var i = settingsList.currentIndex;
            var entry = (page && page.listmodel && i >= 0 && i < page.listmodel.count) ? page.listmodel.get(i) : null;
            if (entry && hasInfo(entry.settingName)) {
                playToggle();
                openInfo(settingsList.currentItem ? settingsList.currentItem.displayLabel : entry.settingName, infoText(entry.settingName));
            }
            return true;
        }
        return false;
    }

    function mouseBack() {
        if (infoOpen)  { infoOpen = false; focusContent(); return; }
        if (settingsGrid.editing) { playBack(); settingsGrid.editing = false; return; }   // finish editing first
        if (!pagelist.activeFocus) { pagelist.forceActiveFocus(); return; }   // rows -> page list
        previousScreen();
    }

    // Greying: true when a row's setting does nothing right now (another
    // setting turns it off). Shared by the list rows and the grid pages.
    function settingDisabled(settingName) {
        // All Games' tile rows do nothing while All Games is a list.
        var agGrid = (settingsStore.get("All Games View", "List")) === "Grid";
        if (settingName === "AllGames Tile Style" || settingName === "AllGames Tile Ratio"
            || settingName === "AllGames Tile Art" || settingName === "AllGames Tile Logo"
            || settingName === "AllGames Items per row" || settingName === "AllGames Tile titles") {
            if (!agGrid) return true;
            // Shape-dependent rows (this used to sit after a return above
            // and never ran): Box Art greys art + logo; Square greys ratio.
            var agShape = settingsStore.get("AllGames Tile Style", "Wide");
            if (settingName === "AllGames Tile Art" || settingName === "AllGames Tile Logo") return agShape === "Box Art" || agShape === "3D Box";
            if (settingName === "AllGames Tile Ratio") return agShape === "Square";
            return false;
        }

        if (settingName === "Randomize System Tile Fanart" || settingName === "Screenshot Fallback") {
            var bgArt  = settingsStore.get("Showcase Background Art", "Yes");
            return bgArt === "No";
        }

        // Small helper: current value of another row, with its default.
        function mem(k, d) { return settingsStore.get(k, d); }

        // Dynamic Background moves whichever background is showing — fanart
        // or the custom image — so it's only inert when neither is.
        if (settingName === "Dynamic Background")
            return mem("Showcase Background Art", "Yes") === "No" && mem("Custom Background", "No") === "No";
        // Opacity applies to fanart AND the custom image; inert only when neither shows.
        if (settingName === "Showcase Background Opacity")
            return mem("Showcase Background Art", "Yes") === "No" && mem("Custom Background", "No") === "No";

        // Sound master: with Menu sounds off, the volume and the chime are silent anyway.
        if (settingName === "Menu Volume" || settingName === "Start up chime")
            return mem("Menu sounds") === "No";

        // Logo tint only applies to the Xbox logos — not to None,
        // and not to the RetroAchievements logo, which keeps its own colours.
        if (settingName === "Logo Color Match") {
            var xl = mem("Xbox Logo", "Logo1");
            return xl === "None" || xl === "RetroAchievements";
        }

        // Previews & sound masters: Off greys every screen's row it covers.
        var previewKeys = ["Allow video thumbnails", "AllGames Video preview", "Systems Video preview",
                           "Video preview", "Details rows video preview"];
        var soundKeys = ["Video thumbnail audio", "All games menu video audio", "Systems video audio",
                         "Game details video preview audio", "Details rows video audio", "Discover video audio"];
        var hideKeys = ["Hide logo when thumbnail video plays", "AllGames Grid hide logo on video",
                        "AllGames List hide on video", "Systems Grid hide logo on video",
                        "Systems List hide on video", "Details rows hide logo on video"];
        var previewsOff = mem("Video previews", "Yes") === "No";
        if (previewsOff && (previewKeys.indexOf(settingName) !== -1 || hideKeys.indexOf(settingName) !== -1)) return true;
        if (soundKeys.indexOf(settingName) !== -1) {
            if (mem("Preview sound", "Yes") === "No") return true;
            if (previewsOff && settingName !== "Discover video audio") return true;   // Discover always plays
        }
        // Previews & sound: each screen's Sound and "while it plays"
        // rows do nothing while that screen's Preview is off.
        if (settingName === "Hide logo when thumbnail video plays" || settingName === "Video thumbnail audio")
            return mem("Allow video thumbnails") === "No";
        if (settingName === "Game details video preview audio")
            return mem("Video preview") === "No";
        if (settingName === "All games menu video audio"
            || settingName === "AllGames Grid hide logo on video"
            || settingName === "AllGames List hide on video")
            return mem("AllGames Video preview") === "No";
        if (settingName === "Systems video audio"
            || settingName === "Systems Grid hide logo on video"
            || settingName === "Systems List hide on video")
            return mem("Systems Video preview") === "No";
        if (settingName === "Details rows video audio" || settingName === "Details rows hide logo on video")
            return mem("Details rows video preview") === "No";
        // Systems' tile rows do nothing while Systems is a list.
        if (["Grid Thumbnail", "Grid Ratio", "Grid art", "Grid Game Logo", "Number of columns",
             "Systems Tile titles"].indexOf(settingName) !== -1
            && mem("Systems View") === "List")
            return true;

        // A collection set to None has no thumbnail, size or ratio to configure.
        var cm = settingName.match(/^(Collection \d) - (Thumbnail|Size|Ratio)$/);
        if (cm && mem(cm[1], "") === "None") return true;
        // A collection's Ratio row is inert when its shape is Square
        if (settingName.indexOf("Collection ") === 0 && settingName.indexOf(" - Ratio") !== -1) {
            var coll = settingName.replace(" - Ratio", "");
            var shp = settingsStore.get(coll + " - Thumbnail", "Wide");
            return shp === "Square";
        }
        // Ratio is inert only for Square; Box Art scales with it on both grids.
        if (settingName === "Grid Ratio") {
            var gth = settingsStore.get("Grid Thumbnail");
            return gth === "Square";
        }
        // Grid art / Grid Game Logo only apply to the Wide/Tall/Square
        // tile styles — Box Art tiles always show the box art itself,
        // so there's no art-source or logo-overlay choice to make.
        // Box Art shape shows the box itself, so the art-source and logo
        // rows have nothing to act on. Ratio and tiles-per-row stay live.
        if (settingName === "Grid art" || settingName === "Grid Game Logo") {
            var gth2 = settingsStore.get("Grid Thumbnail");
            return gth2 === "Box Art" || gth2 === "3D Box";
        }
        return false;
    }

    function hasInfo(name) {
        return name === "Grid background dimming"
            || name === "Theme build" || name === "Frontend" || name === "Features"
            || name === "Display" || name === "Library size" || name === "Write diagnostics to log"
            || name === "Bottom fade"
            || name === "UI Scale"
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
            || name === "Game Counter"
            || name === "Frame counter"
            || name === "Allow video thumbnails"
            || name === "Hide logo when thumbnail video plays"
            || name === "All Games View"
            || name === "AllGames Video preview"
            || name === "AllGames Grid hide logo on video" || name === "Systems Grid hide logo on video"
            || name === "Details rows hide logo on video"
            || name === "AllGames List hide on video" || name === "Systems List hide on video"
            || name === "Systems Video preview" || name === "Details rows video preview"
            || name === "Systems View" || name === "AllGames Tile titles" || name === "Systems Tile titles"
            || name === "AllGames Blur Background"
            || name === "AllGames Show scanlines"
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
            || name === "Hide Android Games System Tile"
            || name === "Added App Launch"
            || name === "Show WiFi Indicator"
            || name === "Show Battery Percentage"
            || name === "Show Clock"
            || tipTexts.hasOwnProperty(name);
    }

    property real itemheight: vpx(45)   // ~68 px at 1080p
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
        editText = settingsStore.get(name, "");
        kbOpen = true;             // builds the keyboard (credsKbLoader)
        var kb = credsKbLoader.item;
        kb.page = 0;               // always start on the letters page
        kb.shifted = false;
        kb.row = 0;
        kb.col = 0;
        kb.forceActiveFocus();
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

    // Settings background — locked dark (independent of Color Background),
    // the Xbox settings charcoal.
    Rectangle {
        anchors.fill: parent
        color: "#101010"
        z: -10
    }

    Rectangle {
    id: header

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: vpx(84)
        color: "transparent"
        z: 5

        // Settings cog (same icon used elsewhere in the theme)
        Image {
            id: settingsCog
            anchors {
                left: parent.left; leftMargin: vpx(72)   // lines up with the rail's text, as on the Xbox
                verticalCenter: parent.verticalCenter
            }
            height: vpx(27)
            width: height
            source: "../assets/images/settingsicon.svg"
            sourceSize: Qt.size(vpx(54), vpx(54))
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
        }

        // Platform title
        Text {
        id: headertitle
            
            text: "Settings"
            
            anchors {
                top: parent.top;
                left: settingsCog.right; leftMargin: vpx(12)
                right: parent.right
                bottom: parent.bottom
            }
            
            color: settingsTextColor
            font.family: titleFont.name
            font.pixelSize: vpx(27)
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

    // Clock / battery / Wi-Fi, top right, as on every other screen.
    StatusCluster { anchors.fill: parent; z: 50 }

    ListView {
    id: pagelist
    
        focus: true
        // Full-bleed rail from the screen's left edge to the divider, as on
        // the Xbox: the selected page is an accent plate while the rail has
        // focus, and a grey plate with an accent edge while you're in a page.
        anchors {
            top: header.bottom; topMargin: vpx(14)
            bottom: parent.bottom; bottomMargin: helpMargin
            left: parent.left
        }
        // A quarter of the screen, as on the Xbox (480 of 1920).
        width: Math.round(root.width * 0.25)
        spacing: vpx(2)
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
                height: vpx(43)            // 64 px at 1080p, the Xbox rail's row

                readonly property bool railFocused: selected && pagelist.activeFocus

                // Rail focused: an accent plate with a soft glow.
                Rectangle {
                    anchors.fill: parent
                    anchors.rightMargin: vpx(2)
                    visible: railFocused
                    radius: vpx(3)
                    color: theme.accent
                    layer.enabled: visible && tileHaloLive   // the glow follows Frame glow
                    layer.effect: DropShadow {
                        cached: true
                        transparentBorder: true
                        radius: 14; samples: 29
                        color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.55)
                    }
                }
                // In a page: a grey plate, accent edge against the divider.
                Rectangle {
                    anchors.fill: parent
                    visible: selected && !railFocused
                    color: "#2e2e2e"
                    Rectangle {
                        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                        width: vpx(5)
                        color: theme.accent
                    }
                }
                Text {
                    anchors { left: parent.left; leftMargin: vpx(72); verticalCenter: parent.verticalCenter }   // 108 px at 1080p
                    text: modelData.pageName
                    // Dark text on a light accent (lime, yellow), white otherwise.
                    color: railFocused ? (accentIsLight ? "#111111" : "white") : selected ? "white" : "#d2d2d2"
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(17.5)
                }

                // Mouse/touch functionality
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: settings.MouseHover == "Yes"
                    onEntered: { playNav(); }
                    onClicked: {
                        playNav();
                        pagelist.currentIndex = index;
                        focusContent();
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
        Keys.onRightPressed: { playNav(); focusContent(); }
        Keys.onPressed: {
            // Accept
            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true;
                playAccept();
                focusContent();
            }
            // Back
            if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                event.accepted = true;
                previousScreen();
            }
        }

    }

    // Rail / page divider
    Rectangle {
        anchors { left: pagelist.right; top: parent.top; bottom: parent.bottom }
        width: Math.max(1, vpx(1.5))
        color: "#2f2f2f"
    }
    readonly property bool accentIsLight: (0.299 * theme.accent.r + 0.587 * theme.accent.g + 0.114 * theme.accent.b) > 0.62

    // ── Page title and lead line ──────────────────────────────────────────
    Item {
    id: pane
        anchors {
            top: header.bottom; topMargin: vpx(6)
            bottom: parent.bottom; bottomMargin: helpMargin
            left: pagelist.right; leftMargin: vpx(31)        // title 47 px past the divider at 1080p
            right: parent.right; rightMargin: globalMargin + vpx(18)
        }
        Text {
        id: pageTitle
            text: currentPage ? currentPage.pageName : ""
            color: "white"
            font.family: titleFont.name
            font.pixelSize: vpx(29)
            font.bold: true
        }
        Text {
        id: pageLead
            anchors { top: pageTitle.bottom; topMargin: vpx(4) }
            width: Math.min(pane.width, vpx(780))
            text: (currentPage && currentPage.lead) ? currentPage.lead : ""
            color: "#a9a9a9"
            font.family: subtitleFont.name
            font.pixelSize: vpx(14.5)
            wrapMode: Text.WordWrap
        }
    }

    // Grid pages: Previews & sound, Library.
    SettingsGrid {
    id: settingsGrid
        visible: gridPage !== ""
        anchors {
            top: pane.top; topMargin: pageLead.y + pageLead.height + vpx(18)
            left: content.left; right: content.right; bottom: pane.bottom
        }
        cells: gridPage === "previews" ? previewsCells() : gridPage === "library" ? libraryCells() : []
        colWidths: gridPage === "previews" ? [0.5, 0.25, 0.25] : [0.5, 0.5]
        isDisabled: function(c) { return root.settingDisabled(c.key); }
        onChanged: {
            // Box-front art already carries the name: its logo row turns off.
            if (cell.key === "AllGames Tile Art" && value === "Boxfront") { settingsStore.set("AllGames Tile Logo", "No"); settingsStore.set("AllGames Tile LogoIndex", 1); }
            if (cell.key === "Grid art" && value === "Boxfront") { settingsStore.set("Grid Game Logo", "No"); settingsStore.set("Grid Game LogoIndex", 1); }
            settingsEpoch++;
        }
        onInfoRequested: { if (root.hasInfo(cell.key)) { playToggle(); root.openInfo(cell.label || cell.text || cell.key, root.infoText(cell.key)); } }
        onItemAction: {
            // A system with its own settings: back to following Systems.
            if (cell.sys) { playToggle(); settingsStore.set(cell.sys + " - Use theme settings", "Yes"); settingsEpoch++; libraryRev++; }
        }
        onLeave: pagelist.forceActiveFocus()
        onCurrentChanged: root.rebuildHelpbar()
        onActiveFocusChanged: root.rebuildHelpbar()
        onEditingChanged: root.rebuildHelpbar()
    }

    // The settings column: indented from the title and as wide as the Xbox's
    // two columns of cards (2 x 438 + 16 px at 1080p). Previews & sound has
    // five columns, so it gets more room.
    Item {
    id: content
        anchors { top: pane.top; bottom: pane.bottom; left: pane.left; leftMargin: vpx(28) }
        width: Math.min(pane.width - vpx(28), vpx(595))
    }

    // RetroAchievements credential status — only on the RA page.
    Text {
        id: raVerifyBanner
        z: 2
        visible: settingsArr[pagelist.currentIndex]
                 && settingsArr[pagelist.currentIndex].pageName === "Retro Achievements"
        anchors {
            left: content.left
            right: content.right
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
        visible: gridPage === ""

        anchors {
            top: pane.top; topMargin: pageLead.y + pageLead.height + vpx(10)
            bottom: pane.bottom
            left: content.left; leftMargin: -vpx(8)
            right: content.right; rightMargin: -vpx(8)
        }
        // Room for the focus frame, which sits just outside the card.
        topMargin: vpx(8); bottomMargin: vpx(8)
        leftMargin: vpx(8); rightMargin: vpx(8)

        spacing: vpx(8)
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
                    settingsStore.has(settingName + 'Index') ? (settingsStore.get(settingName + 'Index') || 0) : defaultIndex(),
                    settingList.length - 1)

                Connections {
                    target: settingsList
                    onSettingsVersionChanged: {
                        savedIndex = Math.min(
                            settingsStore.has(settingName + 'Index') ? (settingsStore.get(settingName + 'Index') || 0) : defaultIndex(),
                            settingList.length - 1);
                    }
                }
                property string itemNote: (typeof note !== 'undefined') ? note : ""
                // Optional friendly display label; storage key remains settingName
                readonly property bool isDiag: (typeof diag !== 'undefined') && diag === true
                property string displayLabel: isDiag ? root.diagLabel(settingName)
                                            : (typeof label !== 'undefined' && label !== "") ? label : settingName
                // Section header rows: a label with a rule beneath, never
                // selectable. Declared with `header: true` in the page model.
                readonly property bool isHeader: (typeof header !== 'undefined') && header === true
                // The Diagnostics panel: read-only, never landed on.
                readonly property bool isPanel: (typeof panel !== 'undefined') && panel === true
                readonly property bool isDecor: isHeader || isPanel
                // Tips & Tricks rows: a title only, no value; A or X opens the tip.
                readonly property bool isTip: (typeof tip !== 'undefined') && tip === true

                // Greyed-out/inert state — "Randomize System Tile Fanart" only has
                // an effect while the fanart background is showing, so it locks
                // when Showcase Background Art is off.
                //
                // It no longer locks on Custom Background: the two used to be
                // mutually exclusive, but the custom image is a base layer now
                // and fanart still runs on top of it.
                property bool rowDisabled: {
                    if (isDecor || isTip) return false;
                    var _v = settingsList.settingsVersion;   // re-evaluate after any save
                    return root.settingDisabled(settingName);
                }

                // Text-input rows (RA credentials) skip the cycling logic
                property bool isTextInput: model.inputType === "text"   // optional role: model.x is undefined, bare x throws
                property bool isEditing:   false
                property string originalText: ""

                // Writes another row's value AND its index, so the settings
                // screen displays it correctly on the next visit.
                function setOther(key, value, list) {
                    settingsStore.set(key, value);
                    var i = list.indexOf(value);
                    if (i >= 0) settingsStore.set(key + 'Index', i);
                }
                function saveSetting() {
                    if (isTextInput || rowDisabled || isTip) return;
                    settingsStore.set(settingName + 'Index', savedIndex);
                    settingsStore.set(settingName, settingList[savedIndex]);
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
                                   "Menu sounds", "Xbox Logo",
                                   "Allow video thumbnails", "Video preview", "AllGames Video preview",
                                   "Systems Video preview", "Details rows video preview",
                                   "Grid Thumbnail", "All Games View", "Systems View", "AllGames Tile Style"];
                    if (parents.indexOf(settingName) !== -1 || /^Collection \d$/.test(settingName)
                        || /^Collection \d - Thumbnail$/.test(settingName))
                        settingsList.settingsVersion++;
                    // Wakes any binding that opted into live updates.
                    settingsEpoch++;
                }

                function nextSetting() {
                    if (isTextInput || rowDisabled || isTip) return;
                    if (savedIndex != settingList.length -1)
                        savedIndex++;
                    else
                        savedIndex = 0;
                }

                function prevSetting() {
                    if (isTextInput || rowDisabled || isTip) return;
                    if (savedIndex > 0)
                        savedIndex--;
                    else
                        savedIndex = settingList.length -1;
                }

                width: ListView.view.width - vpx(16)
                height: isHeader ? vpx(36) : isPanel ? diagCol.height + vpx(26) : (itemNote !== "" ? itemheight + vpx(30) : itemheight)

                // Diagnostics panel
                Rectangle {
                    visible: isPanel
                    anchors.fill: parent
                    radius: vpx(4)
                    color: "#1b1b1b"
                    border.width: Math.max(1, vpx(1)); border.color: "#2c2c2c"
                    Column {
                    id: diagCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: vpx(13); leftMargin: vpx(16) }
                        spacing: vpx(5)
                        Repeater {
                            model: isPanel ? root.diagLines() : []
                            delegate: Row {
                                spacing: vpx(12)
                                Text { width: vpx(118); text: modelData[0]; color: "#8e8e8e"; font { family: subtitleFont.name; pixelSize: vpx(15) } }
                                Text { text: modelData[1]; color: "white"; font { family: subtitleFont.name; pixelSize: vpx(15) } }
                            }
                        }
                    }
                }

                // Header rendering: accent caps over the group's cards.
                Text {
                    visible: isHeader
                    anchors { left: parent.left; leftMargin: vpx(2); bottom: parent.bottom; bottomMargin: vpx(6) }
                    text: settingName.toUpperCase()
                    color: theme.accent
                    font { family: subtitleFont.name; pixelSize: vpx(12); bold: true; letterSpacing: vpx(1.2) }
                }

                // Card
                Rectangle {
                id: setTile
                    visible: !isDecor
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: itemheight
                    radius: vpx(4)
                    color: selected ? "#2e2e2e" : "#232323"
                    opacity: rowDisabled ? 0.38 : 1
                }
                // Focus: the same Xbox frame the tiles use.
                Loader {
                    anchors.fill: setTile
                    active: selected && !isDecor
                    z: 2
                    sourceComponent: Item { FocusFrame { anchors.fill: parent; artRadius: vpx(4); glowStrength: tileHaloLive ? 0.45 : 0 } }   // glow honours Frame glow
                }

                // ── Cycle-value rows (existing style) ──────────────────────
                Text {
                id: settingNameText

                    visible: !isDecor && (!isTextInput)
                    text: displayLabel
                    color: "white"
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(17)
                    verticalAlignment: Text.AlignVCenter
                    opacity: rowDisabled ? 0.38 : 1

                    width: parent.width * 0.62
                    elide: Text.ElideRight
                    height: itemheight
                    anchors {
                        left: parent.left; leftMargin: vpx(16)
                    }
                }
                Text {
                id: settingtext

                    visible: !isDecor && (!isTextInput)
                    // Yes/No reads as On/Off; arrows grey, value bold.
                    readonly property string shown: {
                        var v = settingList[savedIndex];
                        return v === "Yes" ? "On" : v === "No" ? "Off" : v;
                    }
                    textFormat: Text.StyledText
                    text: isTip ? "<font color='#8a8a8a'>\u203A</font>"
                                : "<font color='#8a8a8a'>\u2039</font>&nbsp;&nbsp;<b>" + shown + "</b>&nbsp;&nbsp;<font color='#8a8a8a'>\u203A</font>"
                    color: "white"
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(16)
                    verticalAlignment: Text.AlignVCenter
                    opacity: rowDisabled ? 0.38 : 1

                    height: itemheight
                    anchors {
                        right: parent.right; rightMargin: vpx(14)
                    }
                }

                // ── Text-input rows (RA credentials) ───────────────────────
                Text {
                id: textInputLabel

                    visible: !isDecor && (isTextInput)
                    text: displayLabel
                    color: "white"
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(17)
                    verticalAlignment: Text.AlignVCenter

                    width: contentWidth
                    height: itemheight
                    anchors {
                        left: parent.left; leftMargin: vpx(16)
                    }
                }

                // Read-only value display — editing happens in the on-screen
                // keyboard overlay (no native TextInput here)
                Rectangle {
                id: textInputContainer

                    visible: !isDecor && (isTextInput)
                    anchors {
                        right: parent.right; rightMargin: vpx(14)
                        top: parent.top; topMargin: (itemheight - height) / 2
                    }
                    width:  vpx(280)
                    height: vpx(34)
                    color: "transparent"
                    border.width: vpx(1)
                    border.color: settingRow.selected ? "#6a6a6a" : "#3a3a3a"
                    radius: vpx(4)

                    Text {
                        anchors { fill: parent; margins: vpx(8) }
                        property string storedVal: {
                            var _r = root.memRevision;   // refresh after edits
                            return settingsStore.get(settingName, "");
                        }
                        text: storedVal === ""
                              ? "(press A to set)"
                              : ((typeof masked !== 'undefined' && masked)
                                 ? Array(storedVal.length + 1).join("\u25CF")
                                 : storedVal)
                        color: storedVal === "" ? "#8a8a8a" : "white"
                        font.family: subtitleFont.name
                        font.pixelSize: vpx(16)
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }

                // ── Optional note (shared) — accent badge ─────────────────
                Rectangle {
                id: noteBadge

                    visible: !isDecor && (itemNote !== "")
                    width: noteLabel.width + vpx(16)
                    height: noteLabel.height + vpx(6)
                    color: "transparent"
                    border.width: vpx(1)
                    border.color: theme.accent
                    radius: vpx(4)
                    opacity: selected ? 1 : 0.45

                    anchors {
                        left: parent.left; leftMargin: vpx(16)
                        top: parent.top; topMargin: itemheight + vpx(4)
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

                // ── Input handling ────────────────────────────────────────
                Keys.onRightPressed: {
                    if (!isTextInput && !rowDisabled && !isTip) { playToggle(); nextSetting(); saveSetting(); }
                }
                Keys.onLeftPressed: {
                    if (!isTextInput && !rowDisabled && !isTip) { playToggle(); prevSetting(); saveSetting(); }
                }

                Keys.onPressed: {
                    // Accept
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        if (settingName === "Write diagnostics to log") {
                            playAccept();
                            var dtext = diagnosticsText();
                            console.log("[XboxOSv2 diagnostics]\n" + dtext);
                            root.openInfo("Written to lastrun.log", dtext + "\n\nSend lastrun.log (in the Pegasus folder) with your report.");
                        } else if (isTip) {
                            playToggle();
                            root.openInfo(displayLabel, root.infoText(settingName));
                        } else if (isTextInput) {
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
                    visible: !isDecor
                    anchors.fill: parent
                    hoverEnabled: settings.MouseHover == "Yes"
                    // Hover picks the row (and moves focus into the list).
                    function hoverPick() {
                        if (!pointerMoved()) return;
                        if (!settingsList.activeFocus) settingsList.forceActiveFocus();
                        if (settingsList.currentIndex !== index) { settingsList.currentIndex = index; playNav(); }
                    }
                    onEntered: hoverPick()
                    onPositionChanged: hoverPick()   // see SettingsGrid: entered can arrive before the pointer tracker
                    onClicked: {
                        if (selected) {
                            if (isTip) {
                                playToggle();
                                root.openInfo(displayLabel, root.infoText(settingName));
                            } else if (isTextInput) {
                                playAccept();
                                root.openEditor(settingName, (typeof masked !== 'undefined' && masked));
                            } else if (!rowDisabled) {
                                playToggle();
                                nextSetting();
                                saveSetting();
                            }
                        } else {
                            settingsList.forceActiveFocus();
                            if (!isDecor) settingsList.currentIndex = index;
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
            return !!e && (e.header === true || e.panel === true);   // headers and the diagnostics panel
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
        // Off on the grid pages: the list sits hidden under the grid there,
        // and this used to take the wheel meant for the grid.
        active: !infoOpen && gridPage === ""
        visible: gridPage === ""
        onStepped: function(quiet) { if (!quiet) playNav(); }
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

        MouseArea { anchors.fill: parent; hoverEnabled: true; onWheel: wheel.accepted = true; onClicked: closeEditor(); }

        // Built only while open: an 890-line keyboard used to be created
        // with every visit to Settings for the two RA text fields.
        Loader {
        id: credsKbLoader
            anchors.centerIn: parent
            active: kbOpen
            focus: kbOpen
            sourceComponent: Component {
        VirtualKeyboard {
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
            }   // Component
        }   // credsKbLoader
    }

    // Helpbar buttons
    ListModel { id: settingsHelpModel }

    // Only rebuilt when the answer actually changes: clearing and repopulating
    // the model recreates the help bar's delegates, and doing that on every
    // cursor move is a hitch on every keypress.
    property int helpState: -1      // -1 unset, 0 without info, 1 with

    function rebuildHelpbar() {
        var want = 0;
        if (gridPage !== "" && settingsGrid.activeFocus) {
            var gc = settingsGrid.cells[settingsGrid.current];   // currentCell lags inside onCurrentChanged
            if (settingsGrid.editing) want = 6;
            else if (gc && gc.kind === "item") want = 3;
            else {
                var canEdit = gc && gc.kind === "value" && !settingDisabled(gc.key);
                var info = gc && hasInfo(gc.key);
                want = canEdit ? (info ? 5 : 4) : (info ? 1 : 0);
            }
        } else if (settingsList.focus) {
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
        if (want === 6) {                       // editing a grid value
            settingsHelpModel.append({ name: "Back", button: "cancel" });
            settingsHelpModel.append({ name: "Done", button: "accept" });
            return;
        }
        settingsHelpModel.append({ name: "Back", button: "cancel" });
        if (want === 5)
            settingsHelpModel.append({ name: "More info", button: "details" });
        if (want === 4 || want === 5)
            settingsHelpModel.append({ name: "Change", button: "accept" });
        if (want === 1)
            settingsHelpModel.append({ name: "More info", button: "details" });
        if (want === 3)
            settingsHelpModel.append({ name: "Back to Systems", button: "details" });
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
        focusContent();
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
            MouseArea { anchors.fill: parent; hoverEnabled: true; onWheel: wheel.accepted = true; onClicked: root.closeInfo() }
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
