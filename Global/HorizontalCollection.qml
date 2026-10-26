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
    // Box Art / 3D Box rows use the box-art tile instead of the dynamic one.
    property bool boxArt: false
    property string boxStyle: "Box Art"
    property alias currentIndex: collectionList.currentIndex
    property alias savedIndex: collectionList.savedIndex
    property alias title: collectiontitle.text
    property alias model: collectionList.model
    property alias delegate: collectionList.delegate
    property alias collectionList: collectionList
    property var search

    // ── HQ: fanart prefetch ─────────────────────────────────────────────
    // While this row has focus, quietly decode the previous and next games'
    // backgrounds into Qt's image cache, at exactly the size the Showcase
    // crossfade layers decode at (theme.fanartDecodeSize). When the cursor
    // moves, the incoming fanart is already decoded and the fade starts at
    // once instead of after a decode. Two hidden Images, never displayed.
    function neighbourBg(offset) {
        if (!search || !hqPrefetch || !collectionList.focus) return "";
        var i = collectionList.currentIndex + offset;
        if (i < 0 || i >= collectionList.count) return "";
        // Same resolver the crossfade uses, so a screenshot-fallback image is
        // prefetched too, and never a different file from the one shown.
        return fanartFor(search.currentGame(i));
    }
    Image { visible: false; asynchronous: true; cache: true
            sourceSize: fanartDecodeSize
            source: neighbourBg(-1) }
    Image { visible: false; asynchronous: true; cache: true
            sourceSize: fanartDecodeSize
            source: neighbourBg(+1) }
    // Set by the hosting screen ("showcasescreen", "gameviewscreen").
    property string ownScreen: ""

    // A held Left/Right: the highlight skips its preview warm-up while this
    // holds (see ItemHighlight.racing). Released 200 ms after the last repeat.
    property bool held: false
    function noteHeld(event) { if (event.isAutoRepeat) { held = true; heldRelease.restart(); } }
    Timer { id: heldRelease; interval: 200; onTriggered: root.held = false }

    signal activate(int activeIndex)
    signal activateSelected
    signal listHighlighted

    Text {
    id: collectiontitle

        text: collectionData.name
        font.family: subtitleFont.name
        font.pixelSize: fpx(18)
        font.bold: true
        // Over fanart / a custom image the text stays light; only when the
        // White colour itself is showing does it follow theme.text.
        color: showcaseWhiteBackground ? theme.text : "#ebebeb"
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
        cacheBuffer: itemWidth * hqCacheTiles
        keyNavigationWraps: true
        
        property int savedIndex: 0

        onFocusChanged: {
            if (focus) {
                currentIndex = savedIndex;
            } else {
                savedIndex = currentIndex;
                currentIndex = -1;
            }
        }

        currentIndex: focus ? savedIndex : -1
        Component.onCompleted: positionViewAtIndex(savedIndex, ListView.Visible)

        model: search.games ? search.games : api.allGames
        // Same pairing the grids use: the box-art tile for Box Art rows, the
        // dynamic tile otherwise. Both wire the same highlight/activate logic.
        delegate: root.boxArt ? boxArtDelegate : dynamicDelegate

        Component {
        id: dynamicDelegate
            DynamicGridItem {
                selected: ListView.isCurrentItem && collectionList.focus
                width: itemWidth
                height: itemHeight
                // Same relay the highlight gets, so the tile knows when its
                // preview has actually been torn down and restores its art.
                ownScreen: root.ownScreen

                onHighlighted: {
                    collectionList.savedIndex = index;
                    collectionList.currentIndex = index;
                    listHighlighted();
                }
                onActivated: {
                    if (selected) {
                        activateSelected();
                        openGame(search.currentGame(currentIndex));
                    } else {
                        activate(index);
                        collectionList.currentIndex = index;
                    }
                }
            }
        }
        Component {
        id: boxArtDelegate
            BoxArtGridItem {
                selected: ListView.isCurrentItem && collectionList.focus
                // Unlike the dynamic tile, this one has no default for gameData —
                // without it the art has no game to draw (the title still showed,
                // as it reads modelData directly).
                gameData: modelData
                width: itemWidth
                height: itemHeight
                artStyle: root.boxStyle

                onHighlighted: {
                    collectionList.savedIndex = index;
                    collectionList.currentIndex = index;
                    listHighlighted();
                }
                onActivate: {
                    if (selected) {
                        activateSelected();
                        openGame(search.currentGame(currentIndex));
                    } else {
                        activate(index);
                        collectionList.currentIndex = index;
                    }
                }
            }
        }

        Component {
        id: highlightcomponent

            ItemHighlight {
                width: collectionList.cellWidth
                height: collectionList.cellHeight
                game: search ? search.currentGame(collectionList.currentIndex) : ""
                selected: collectionList.focus
                boxArt: root.boxArt          // no video preview on box-art rows
                // Relayed from whichever screen owns this row, so a preview
                // stops when THAT screen is left — the Showcase and GameView
                // both use this component and must not keep each other alive.
                ownScreen: root.ownScreen
                racing: root.held
            }
        }

        Keys.onLeftPressed: {
            playNav(); noteHeld(event);
            collectionList.decrementCurrentIndex();
        }
        Keys.onRightPressed: {
            playNav(); noteHeld(event);
            collectionList.incrementCurrentIndex();
        }
    }

}