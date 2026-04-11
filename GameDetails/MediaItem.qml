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

import QtQuick 2.0
import QtGraphicalEffects 1.0

Item {
id: root

    signal activated
    signal highlighted

    property string mediaItem: ""
    property bool selected
    property bool isVideo: mediaItem.includes(".mp4") || mediaItem.includes(".webm")

    scale: selected ? 1.05 : 1
    Behavior on scale { NumberAnimation { duration: 100 } }
    z: selected ? 10 : 1

    Image {
    id: border

        anchors.fill: parent
        source: "../assets/images/" + settings.ColorLayout + ".png"
        visible: selected
        asynchronous: true

        Rectangle {
        id: titlecontainer

            width: bubbletitle.contentWidth + vpx(20)
            height: bubbletitle.contentHeight + vpx(8)
            color: theme.secondary
            anchors {
                top: border.bottom; topMargin: vpx(5)
            }
            anchors.horizontalCenter: parent.horizontalCenter
            radius: height/2

            Text {
            id: bubbletitle

                text: {
                    if (isVideo) return "Video";
                    if (mediaItem.includes("background") || mediaItem.includes("fanart")) return "Fanart";
                    if (mediaItem.includes("titlescreen") || mediaItem.includes("screenshottitle")) return "Title Screenshot";
                    if (mediaItem.includes("box3d") || mediaItem.includes("box_3d") || mediaItem.includes("3dbox")) return "3D Box";
                    if (mediaItem.includes("box2dFront") || mediaItem.includes("box2dfront") || mediaItem.includes("box2d_front")) return "Box Art";
                    if (mediaItem.includes("boxFront") || mediaItem.includes("box_front")) return "Box Art";
                    if (mediaItem.includes("box2dBack") || mediaItem.includes("box2dback") || mediaItem.includes("box2d_back")) return "Back Box";
                    if (mediaItem.includes("boxBack")  || mediaItem.includes("box_back"))  return "Back Box";
                    if (mediaItem.includes("cartridge") || mediaItem.includes("support")) return "Cartridge";
                    if (mediaItem.includes("miximage") || mediaItem.includes("mix_image")) return "Miximage";
                    if (mediaItem.includes("wheel")) return "Logo";
                    return "Screenshot";
                }
                color: theme.text
                font {
                    family: subtitleFont.name
                    pixelSize: vpx(14)
                    bold: true
                }
                elide: Text.ElideRight
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Image {
    id: bg

        anchors.fill: parent
        anchors.margins: vpx(4)
        source: isVideo ? "" : mediaItem
        fillMode: Image.PreserveAspectCrop
        asynchronous: true

        Rectangle {
        id: videopreview

            anchors.fill: parent
            color: theme.secondary
            visible: isVideo
        }

        Image {
        id: iconFill

            anchors.fill: parent
            source: "../assets/images/" + settings.ColorLayout + ".png"
            fillMode: Image.PreserveAspectCrop
            visible: false
            asynchronous: true
        }

        Image {
        id: mask

            source: "../assets/images/icon_mediaplayer.svg"
            anchors.centerIn: parent
            width: vpx(150); height: width
            sourceSize: Qt.size(parent.width, parent.height)
            smooth: true
            fillMode: Image.PreserveAspectFit
            visible: false
            asynchronous: true
        }

        OpacityMask {
            anchors.fill: mask
            anchors.margins: vpx(30)
            source: iconFill
            maskSource: mask
            visible: isVideo
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: selected ? 0 : 0.7
            z: selected ? 0 : 10
        }
        
    }
    
    // List specific input
    Keys.onPressed: {
        // Accept
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            activated();        
        }
    }

    // Mouse/touch functionality
    MouseArea {
        anchors.fill: parent
        hoverEnabled: settings.MouseHover == "Yes"
        onEntered: { sfxNav.play(); highlighted(); }
        onExited: {}
        onClicked: activated();
    }
}