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
import QtQml.Models 2.15
import "../utils.js" as Utils

FocusScope {
id: root

    property bool searchActive
    property int filteredCount: currentCollection.games.count
    function focusNavButtons() {
        // Nav buttons are items 4-7 in headermodel (home is index 7, rightmost in model = leftmost visually)
        buttonbar.currentIndex = 7;
        buttonbar.forceActiveFocus();
    }

    onFocusChanged: buttonbar.currentIndex = 0;

    function toggleSearch() {
        if (searchActive) {
            // On Android, Qt.inputMethod.hide() must be called while the TextInput
            // still exists and has focus. Calling it after changing searchActive
            // destroys (or defocuses) the native EditText first, leaving Android's
            // IME attached to a dead view — which causes the persistent blue box.
            if (searchLoader.item) searchLoader.item.focus = false;
            Qt.inputMethod.hide();
            buttonbar.forceActiveFocus();
            searchActive = false;
        } else {
            searchActive = true;
        }
    }

    // Reliable watcher: when the soft keyboard becomes hidden for ANY reason
    // (controller B mapped to Android BACK, system gesture, etc.) tear down the
    // search so no orphaned native input box remains on screen.
    property bool imeVisible: Qt.inputMethod.visible
    onImeVisibleChanged: {
        if (!imeVisible && searchActive) {
            if (searchLoader.item) searchLoader.item.focus = false;
            buttonbar.forceActiveFocus();
            searchActive = false;
        }
    }

    Item {
    id: container

        anchors.fill: parent

        // Platform logo
        Image {
        id: logobg

            anchors.fill: platformlogo
            source: "../assets/images/blank.png"
            asynchronous: true
            visible: false
        }

        Image {
        id: platformlogo

            anchors {
                top: parent.top; topMargin: vpx(15)
                left: parent.left; leftMargin: globalMargin
            }
            height: vpx(45)
            fillMode: Image.PreserveAspectFit
            source: "../assets/images/logospng/" + Utils.processPlatformName(currentCollection.shortName) + ".png"
            sourceSize: Qt.size(parent.width, parent.height)
            smooth: true
            visible: false
            asynchronous: true           
        }

        OpacityMask {
            anchors.fill: platformlogo
            source: platformlogo
            maskSource: logobg
            // Mouse/touch functionality
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: previousScreen();
            }
        }

        // Platform title
        Text {
        id: softwareplatformtitle
            
            text: currentCollection.name
            
            anchors {
                top:    parent.top;    topMargin: vpx(15)
                left:   parent.left;   leftMargin: globalMargin
                right:  parent.right
            }
            height: vpx(45)
            
            color: theme.text
            font.family: titleFont.name
            font.pixelSize: vpx(30)
            font.bold: true
            horizontalAlignment: Text.AlignHLeft
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            visible: platformlogo.status == Image.Error

            // Mouse/touch functionality
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: previousScreen();
            }
        }

        ObjectModel {
        id: headermodel

            // Search bar
            Item {
            id: searchbar
                
                property bool selected: ListView.isCurrentItem && root.focus
                onSelectedChanged: if (!selected && searchActive) toggleSearch();

                width: (searchActive || searchTerm != "") ? vpx(250) : height
                height: vpx(40)

                Behavior on width {
                    PropertyAnimation { duration: 200; easing.type: Easing.OutQuart; easing.amplitude: 2.0; easing.period: 1.5 }
                }
                
                Rectangle {
                    width: parent.width
                    height: parent.height
                    color: searchbar.selected && !searchActive ? theme.accent : "white"
                    radius: height/2
                    opacity: searchbar.selected && !searchActive ? 1 : searchActive ? 0.4 : 0.2

                }

                Image {
                id: searchicon

                    width: height
                    height: vpx(18)
                    anchors { 
                        left: parent.left; leftMargin: vpx(11)
                        top: parent.top; topMargin: vpx(10)
                    }
                    source: "../assets/images/searchicon.svg"
                    opacity: searchbar.selected && !searchActive ? 1 : searchActive ? 0.8 : 0.5
                    asynchronous: true
                }

                // Loader: only instantiates a native TextInput (Android EditText)
                // while the search bar is actively open. When searchActive goes
                // false the object is destroyed and the Android IME loses its
                // target, eliminating the persistent blue-square highlight.
                Loader {
                id: searchLoader

                    anchors {
                        left: searchicon.right; leftMargin: vpx(10)
                        top: parent.top; bottom: parent.bottom
                        right: modeLabel.left; rightMargin: vpx(5)
                    }
                    active: searchActive
                    asynchronous: false
                    onLoaded: {
                        if (item) {
                            item.forceActiveFocus();
                            item.selectAll();
                        }
                    }

                    sourceComponent: Component {
                        TextInput {
                            verticalAlignment: Text.AlignVCenter
                            color: theme.text
                            font.family: subtitleFont.name
                            font.pixelSize: vpx(18)
                            clip: true
                            text: searchTerm
                            selectionColor: theme.accent
                            selectedTextColor: theme.text
                            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                            onActiveFocusChanged: {
                                if (!activeFocus) Qt.inputMethod.hide();
                                else Qt.inputMethod.show();
                            }
                            onTextEdited: {
                                searchTerm = text
                            }
                            Keys.onDownPressed: {
                                event.accepted = true;
                                searchModeDropdown.forceActiveFocus();
                            }
                        }
                    }
                }

                // Current mode label inside the search bar
                Text {
                id: modeLabel

                    visible: searchActive || searchTerm != ""
                    text: searchMode
                    color: theme.text
                    opacity: 0.6
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(13)
                    anchors {
                        right: parent.right; rightMargin: vpx(12)
                        verticalCenter: parent.verticalCenter
                    }
                }

                // Search mode dropdown - appears below the search bar when active
                FocusScope {
                id: searchModeDropdown

                    visible: searchActive
                    width: vpx(160)
                    height: vpx(96)
                    y: parent.height + vpx(6)
                    x: vpx(0)
                    z: 50

                    Rectangle {
                        anchors.fill: parent
                        color: theme.secondary
                        radius: vpx(10)
                        border.color: Qt.rgba(1, 1, 1, 0.15)
                        border.width: 1
                    }

                    ListView {
                    id: modeListView

                        anchors { fill: parent; margins: vpx(8) }
                        spacing: vpx(6)
                        model: ["Title", "Genre"]
                        currentIndex: searchMode === "Genre" ? 1 : 0
                        focus: searchModeDropdown.activeFocus
                        interactive: false

                        delegate: Rectangle {
                            width: modeListView.width
                            height: vpx(34)
                            radius: height / 2
                            color: modelData === searchMode
                                    ? theme.accent
                                    : (ListView.isCurrentItem && modeListView.focus ? Qt.rgba(1, 1, 1, 0.15) : "transparent")

                            Text {
                                text: modelData
                                color: theme.text
                                font.family: subtitleFont.name
                                font.pixelSize: vpx(16)
                                font.bold: modelData === searchMode
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    searchMode = modelData;
                                    if (searchLoader.item) searchLoader.item.forceActiveFocus();
                                }
                            }
                        }

                        Keys.onUpPressed: {
                            if (currentIndex > 0) {
                                playNav();
                                currentIndex--;
                            } else {
                                if (searchLoader.item) searchLoader.item.forceActiveFocus();
                            }
                        }
                        Keys.onDownPressed: {
                            if (currentIndex < count - 1) {
                                playNav();
                                currentIndex++;
                            }
                        }
                        Keys.onPressed: {
                            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                                event.accepted = true;
                                searchMode = model[currentIndex];
                                playToggle();
                                if (searchLoader.item) searchLoader.item.forceActiveFocus();
                            }
                            if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                                event.accepted = true;
                                if (searchLoader.item) searchLoader.item.forceActiveFocus();
                            }
                        }
                    }
                }

                // Mouse/touch functionality
                MouseArea {
                    anchors.fill: parent
                    enabled: !searchActive
                    hoverEnabled: true
                    onEntered: {}
                    onExited: {}
                    onClicked: {
                        if (!searchActive)
                        {
                            toggleSearch();
                            if (searchLoader.item) searchLoader.item.selectAll();
                        }
                    }
                }

                Keys.onPressed: {
                    // Accept
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        if (!searchActive) {
                            toggleSearch();
                            if (searchLoader.item) searchLoader.item.selectAll();
                        } else {
                            if (searchLoader.item) searchLoader.item.selectAll();
                        }
                    }
                }
            }

            // Ascending/descending
            Item {
            id: directionbutton

                property bool selected: ListView.isCurrentItem && root.focus
                width: directiontitle.contentWidth + vpx(30)
                height: searchbar.height

                Rectangle
                { 
                    anchors.fill: parent
                    radius: height/2
                    color: theme.accent
                    visible: directionbutton.selected
                }

                Text {
                id: directiontitle
                    
                    text: (orderBy === Qt.AscendingOrder) ? "Ascending" : "Descending"
                                    
                    color: theme.text
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(18)
                    anchors.centerIn: parent
                    elide: Text.ElideRight
                }

                Keys.onPressed: {
                    // Accept
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        toggleOrderBy();
                    }
                }
            }

            // Order by title
            Item {
            id: titlebutton

                property bool selected: ListView.isCurrentItem && root.focus
                width: ordertitle.contentWidth + vpx(30)
                height: searchbar.height

                Rectangle
                { 
                    anchors.fill: parent
                    radius: height/2
                    color: theme.accent
                    visible: titlebutton.selected
                }

                Text {
                id: ordertitle
                    
                    text: "By " + sortByFilter[sortByIndex]
                                    
                    color: theme.text
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(18)
                    anchors.centerIn: parent
                    elide: Text.ElideRight
                }

                Keys.onPressed: {
                    // Accept
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        cycleSort();
                    }
                }
            }
            
            // Filters menu
            Item {
            id: filterbutton

                property bool selected: ListView.isCurrentItem && root.focus
                width: filtertitle.contentWidth + vpx(30)
                height: searchbar.height

                Rectangle
                { 
                    anchors.fill: parent
                    radius: height/2
                    color: theme.accent
                    visible: filterbutton.selected
                }
                
                // Filter title
                Text {
                id: filtertitle
                    
                    text: (showFavs) ? "Favorites" : "All games"
                                    
                    color: theme.text
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(18)
                    anchors.centerIn: parent
                    elide: Text.ElideRight
                }

                Keys.onPressed: {
                    // Accept
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        toggleFavs();
                    }
                }
            }

            // ── Nav buttons (home, discover, RA, settings) ──────────────────
            Item {
            id: sl_settingsbutton
                property bool selected: ListView.isCurrentItem && root.focus
                width: vpx(40); height: searchbar.height
                Rectangle {
                    anchors.fill: parent; radius: height/2
                    color: theme.accent; visible: sl_settingsbutton.selected
                }
                Image {
                    anchors { fill: parent; margins: vpx(10) }
                    source: "../assets/images/settingsicon.svg"; smooth: true; asynchronous: true
                    opacity: parent.selected ? 1 : 0.7
                }
                Keys.onPressed: {
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; settingsScreen(); }
                }
            }

            Item {
            id: sl_rabutton
                property bool selected: ListView.isCurrentItem && root.focus
                width: vpx(40); height: searchbar.height
                Rectangle {
                    anchors.fill: parent; radius: height/2
                    color: theme.accent; visible: sl_rabutton.selected
                }
                Text {
                    anchors.centerIn: parent; text: "🏆"
                    font.pixelSize: vpx(18); opacity: parent.selected ? 1 : 0.7
                }
                Keys.onPressed: {
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; achievementsScreen(); }
                }
            }

            Item {
            id: sl_discoverbutton
                property bool selected: ListView.isCurrentItem && root.focus
                width: vpx(40); height: searchbar.height
                Rectangle {
                    anchors.fill: parent; radius: height/2
                    color: theme.accent; visible: sl_discoverbutton.selected
                }
                Canvas {
                    anchors { fill: parent; margins: vpx(10) }
                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset();
                        var cx = width/2, cy = height/2, r = Math.min(cx,cy)-1;
                        ctx.globalAlpha = sl_discoverbutton.selected ? 1.0 : 0.7;
                        ctx.strokeStyle = "white"; ctx.lineWidth = 1.5;
                        ctx.beginPath(); ctx.arc(cx,cy,r,0,Math.PI*2); ctx.stroke();
                        ctx.fillStyle = "white";
                        ctx.beginPath(); ctx.moveTo(cx,cy-r*0.65); ctx.lineTo(cx+r*0.3,cy+r*0.1); ctx.lineTo(cx,cy+r*0.2); ctx.lineTo(cx-r*0.3,cy+r*0.1); ctx.closePath(); ctx.fill();
                        ctx.globalAlpha=0.35;
                        ctx.beginPath(); ctx.moveTo(cx,cy+r*0.65); ctx.lineTo(cx-r*0.3,cy-r*0.1); ctx.lineTo(cx,cy-r*0.2); ctx.lineTo(cx+r*0.3,cy-r*0.1); ctx.closePath(); ctx.fill();
                    }
                    Connections { target: sl_discoverbutton; onSelectedChanged: parent.requestPaint() }
                }
                Keys.onPressed: {
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; discoverScreen(); }
                }
            }

            Item {
            id: sl_homebutton
                property bool selected: ListView.isCurrentItem && root.focus
                width: vpx(40); height: searchbar.height
                Rectangle {
                    anchors.fill: parent; radius: height/2
                    color: theme.accent; visible: sl_homebutton.selected
                }
                Canvas {
                    anchors { fill: parent; margins: vpx(10) }
                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset();
                        var w = width, h = height;
                        ctx.fillStyle = "white"; ctx.globalAlpha = sl_homebutton.selected ? 1.0 : 0.7;
                        ctx.beginPath(); ctx.moveTo(w*0.5,0); ctx.lineTo(w,h*0.5); ctx.lineTo(0,h*0.5); ctx.closePath(); ctx.fill();
                        ctx.fillRect(w*0.1,h*0.5,w*0.8,h*0.5);
                        ctx.clearRect(w*0.37,h*0.68,w*0.26,h*0.32);
                    }
                    Connections { target: sl_homebutton; onSelectedChanged: parent.requestPaint() }
                }
                Keys.onPressed: {
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; showcaseScreen(); }
                }
            }

        }

        // Buttons
        ListView {
        id: buttonbar

            focus: true
            model: headermodel
            spacing: vpx(10)
            orientation: ListView.Horizontal
            layoutDirection: Qt.RightToLeft
            anchors {
                right: parent.right; rightMargin: globalMargin
                left: parent.left; top: parent.top; topMargin: vpx(15)
            }
            
        }

        // Game count label — displayed on the left side below the collection logo
        Text {
        id: gameCountLabel

            anchors {
                top:  platformlogo.bottom; topMargin: vpx(4)
                left: parent.left;         leftMargin: globalMargin
            }
            text: filteredCount + " game" + (filteredCount !== 1 ? "s" : "")
            color: theme.text
            opacity: 0.7
            font.family: subtitleFont.name
            font.pixelSize: vpx(18)
            font.bold: true
            visible: settings.GameCounter !== "No"
        }
        
    }

}