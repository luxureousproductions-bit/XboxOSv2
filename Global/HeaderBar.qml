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

import QtQuick 2.12
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.10
import QtQml.Models 2.1
import "../utils.js" as Utils

FocusScope {
id: root

    property bool searchActive
    property int filteredCount: currentCollection.games.count

    onFocusChanged: buttonbar.currentIndex = 0;

    function toggleSearch() {
        searchActive = !searchActive;
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

                TextInput {
                id: searchInput
                    
                    anchors { 
                        left: searchicon.right; leftMargin: vpx(10)
                        top: parent.top; bottom: parent.bottom
                        right: modeLabel.left; rightMargin: vpx(5)
                    }
                    verticalAlignment: Text.AlignVCenter
                    color: theme.text
                    focus: searchbar.selected && searchActive
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(18)
                    clip: true
                    text: searchTerm
                    onTextEdited: {
                        searchTerm = searchInput.text
                    }

                    Keys.onDownPressed: {
                        if (searchActive) {
                            event.accepted = true;
                            searchModeDropdown.forceActiveFocus();
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
                                    searchInput.forceActiveFocus();
                                }
                            }
                        }

                        Keys.onUpPressed: {
                            if (currentIndex > 0) {
                                sfxNav.play();
                                currentIndex--;
                            } else {
                                searchInput.forceActiveFocus();
                            }
                        }
                        Keys.onDownPressed: {
                            if (currentIndex < count - 1) {
                                sfxNav.play();
                                currentIndex++;
                            }
                        }
                        Keys.onPressed: {
                            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                                event.accepted = true;
                                searchMode = model[currentIndex];
                                sfxToggle.play();
                                searchInput.forceActiveFocus();
                            }
                            if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                                event.accepted = true;
                                searchInput.forceActiveFocus();
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
                            searchInput.selectAll();
                        }
                    }
                }

                Keys.onPressed: {
                    // Accept
                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                        event.accepted = true;
                        if (!searchActive) {
                            toggleSearch();
                            searchInput.selectAll();
                        } else {
                            searchInput.selectAll();
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
            visible: settings.GameCounter !== "Off"
        }
        
    }

}