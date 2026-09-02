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
import "../Lists"

FocusScope {
id: root

    property var collectionData
    property int itemWidth: vpx(150)
    property int itemHeight: itemWidth*1.5
    property alias currentIndex: collectionList.currentIndex
    property alias savedIndex: collectionList.savedIndex
    property alias title: collectiontitle.text
    property alias model: collectionList.model
    property alias delegate: collectionList.delegate
    property alias collectionList: collectionList
    property var search

    // Favorites carousel — only the row ShowcaseViewMenu designates as the
    // first-visible collection receives this; every other row leaves it null
    // and behaves exactly as before.
    property var favoritesData: null
    property bool showFavoritesHeader: favoritesData !== null
    // Set by the hosting screen ("showcasescreen", "gameviewscreen").
    property string ownScreen: ""

    // Paging state lives HERE (not inside FavoritesHeader) so key handling
    // never depends on reaching into ListView.headerItem, which can be null.
    property int favIndex: 0
    readonly property int favCount: favoritesData ? favoritesData.games.count : 0
    // When "Featured Box Content" forces a Discover/slideshow mode the box
    // isn't showing favourites, so there's nothing to page through — Left and
    // Right must pass straight over it instead of scrolling unseen entries.
    //
    // Reads the LIVE value (theme.qml's featuredBoxContent), not the settings
    // snapshot — FavoritesHeader.boxMode already does, and the two disagreeing
    // was the actual bug: switching modes updated what the box displayed
    // immediately, but left this stuck on the old mode until a reload. That
    // desync is what made paging and the auto-rotate timer work right after
    // switching one direction and silently break after switching the other.
    readonly property int favPageCount:
        (featuredBoxContent === "Discover Videos"
      || featuredBoxContent === "Fanart Slideshow") ? 0 : favCount
    onFavCountChanged: { if (favIndex >= favCount) favIndex = Math.max(0, favCount - 1); }

    // Cycles the favourites automatically whenever the carousel isn't the
    // thing being browsed, so it reads as a slideshow at rest. Paused the
    // moment focus lands on it so it can't move under the user's input.
    Timer {
        interval: 8000
        repeat: true
        running: showFavoritesHeader && favPageCount > 1
                 && !(collectionList.focus && collectionList.onFavoritesHeader)
        onTriggered: root.favIndex = (root.favIndex + 1) % root.favPageCount
    }

    // What Accept should act on while the carousel has focus. Favorites are
    // resolved directly from favoritesData; the no-favorites video fallback
    // is the one case that must come from the header item itself.
    readonly property var favTargetGame: {
        // Ask the header what it's DISPLAYING first — it already resolves the
        // favourites / Discover / slideshow modes. Checking favCount first
        // meant a forced Discover or slideshow view still opened the first
        // favourite instead of the game actually on screen.
        if (collectionList.headerItem && collectionList.headerItem.currentGame)
            return collectionList.headerItem.currentGame;
        // Header not built yet — only meaningful if favourites are pageable.
        if (favPageCount > 0 && favoritesData) return favoritesData.currentGame(favIndex);
        return null;
    }

    signal activate(int activeIndex)
    signal activateSelected
    signal listHighlighted

    Text {
    id: collectiontitle

        text: collectionData.name
        font.family: subtitleFont.name
        font.pixelSize: fpx(18)
        font.bold: true
        color: theme.text
        opacity: root.focus ? 1 : 0.2
        anchors { left: parent.left; leftMargin: vpx(10) }

        // Shadow so the title stays legible over bright fanart
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: vpx(1)
            radius: 7
            samples: 15
            color: Qt.rgba(0, 0, 0, 0.9)
        }
    }

    ListView {
    id: collectionList

        focus: root.focus
        anchors {
            top: collectiontitle.bottom; topMargin: vpx(10)
            left: parent.left; 
            right: parent.right;
            bottom: parent.bottom
        }
        spacing: vpx(5)
        orientation: ListView.Horizontal
        preferredHighlightBegin: vpx(0)
        preferredHighlightEnd: parent.width - vpx(60)
        highlightRangeMode: ListView.ApplyRange
        snapMode: ListView.SnapOneItem 
        highlightMoveDuration: 100
        highlight: highlightcomponent
        displayMarginEnd: itemWidth
        cacheBuffer: itemWidth * 2
        keyNavigationWraps: true
        
        property int savedIndex: 0
        // True while focus is "resting" on the favorites carousel rather than
        // any real tile. Only ever reachable when showFavoritesHeader is set.
        property bool onFavoritesHeader: false
        // Remembered across focus loss so returning to this row restores the
        // carousel only if that's where you actually were (savedIndex alone
        // can't tell the carousel apart from tile 0).
        property bool savedOnHeader: false

        onFocusChanged: {
            if (focus) {
                if (showFavoritesHeader && savedOnHeader) {
                    onFavoritesHeader = true;
                    currentIndex = -1;
                    positionViewAtBeginning();
                } else {
                    onFavoritesHeader = false;
                    currentIndex = savedIndex;
                }
            } else {
                // While resting on the carousel currentIndex reads -1 — keep
                // savedIndex pointing at a real tile so returning is sane.
                savedOnHeader = onFavoritesHeader;
                if (!onFavoritesHeader) savedIndex = currentIndex;
                currentIndex = -1;
            }
        }

        currentIndex: focus ? (onFavoritesHeader ? -1 : savedIndex) : -1
        Component.onCompleted: {
            if (showFavoritesHeader && savedIndex === 0) {
                onFavoritesHeader = true;
                savedOnHeader = true;
            }
            positionViewAtIndex(savedIndex, ListView.Visible);
        }

        model: search.games ? search.games : api.allGames
        delegate: DynamicGridItem {
            selected: ListView.isCurrentItem && collectionList.focus && !collectionList.onFavoritesHeader
            width: itemWidth
            height: itemHeight
            // Same relay the highlight gets, so the tile knows when its
            // preview has actually been torn down and restores its art.
            ownScreen: root.ownScreen
            
            onHighlighted: {
                collectionList.onFavoritesHeader = false;
                collectionList.savedIndex = index;
                collectionList.currentIndex = index;
                listHighlighted();
            }

            onActivated: {
                if (selected) {
                    activateSelected();
                    // Apps launch straight from the row; everything else opens
                    // its details page. See openGame() in theme.qml.
                    openGame(search.currentGame(currentIndex));
                } else {
                    activate(index);
                    collectionList.currentIndex = index;
                }
            }
        }

        Component {
        id: highlightcomponent

            ItemHighlight {
                width: collectionList.cellWidth
                height: collectionList.cellHeight
                game: search ? search.currentGame(collectionList.currentIndex) : ""
                selected: collectionList.focus && !collectionList.onFavoritesHeader
                // Relayed from whichever screen owns this row, so a preview
                // stops when THAT screen is left — the Showcase and GameView
                // both use this component and must not keep each other alive.
                ownScreen: root.ownScreen
            }
        }

        header: showFavoritesHeader ? favoritesHeaderComponent : null
        Component {
        id: favoritesHeaderComponent

            FavoritesHeader {
            id: favHeader
                favoritesData: root.favoritesData
                favIndex: root.favIndex
                selected: collectionList.focus && collectionList.onFavoritesHeader
                itemWidth: root.itemWidth
                itemHeight: root.itemHeight
            }
        }

        // Move focus onto the carousel and make sure it's actually scrolled
        // into view — without this it stays parked off-screen to the left
        // after the row has been scrolled rightward.
        function enterFavoritesHeader() {
            // Release the delegate we're leaving FIRST — it stays alive when
            // it's still on screen (i.e. arriving via Left from tile 0) and
            // would otherwise reclaim focus inside this FocusScope, swallowing
            // Accept. Arriving from the right only worked because wrapping
            // recycled that delegate.
            if (collectionList.currentItem) collectionList.currentItem.focus = false;
            onFavoritesHeader = true;
            collectionList.currentIndex = -1;
            collectionList.positionViewAtBeginning();
            // Without this the delegate we just left can keep activeFocus, so
            // Accept never reaches this ListView's Keys handler — that was the
            // "A only works when I arrive from the left" bug.
            collectionList.forceActiveFocus();
        }

        Keys.onLeftPressed: {
            playNav();
            if (onFavoritesHeader) {
                // Already on the carousel: page through favorites, then wrap
                // around to the LAST tile in the row once past the first one.
                if (root.favIndex > 0) {
                    root.favIndex -= 1;
                } else {
                    onFavoritesHeader = false;
                    collectionList.currentIndex = collectionList.count - 1;
                    collectionList.positionViewAtEnd();
                }
            } else if (showFavoritesHeader && collectionList.currentIndex === 0) {
                collectionList.enterFavoritesHeader();
            } else {
                collectionList.decrementCurrentIndex();
            }
        }
        Keys.onRightPressed: {
            playNav();
            if (onFavoritesHeader) {
                // Page forward through favorites, then hand off to the row's
                // first real tile once past the last one.
                if (root.favIndex < root.favPageCount - 1) {
                    root.favIndex += 1;
                } else {
                    onFavoritesHeader = false;
                    collectionList.currentIndex = 0;
                    collectionList.positionViewAtBeginning();
                }
            } else if (showFavoritesHeader && collectionList.currentIndex === collectionList.count - 1) {
                // Wrapping off the last tile lands on the carousel rather than
                // skipping straight past it back to tile 0.
                collectionList.enterFavoritesHeader();
            } else {
                collectionList.incrementCurrentIndex();
            }
        }
        Keys.onPressed: {
            if (onFavoritesHeader && api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true;
                if (root.favTargetGame) {
                    activateSelected();
                    openGame(root.favTargetGame);
                }
            }
        }
    }

}