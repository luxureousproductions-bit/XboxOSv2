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
import QtGraphicalEffects 1.15
import QtMultimedia 5.15

Item {
id: root

    signal activated
    signal highlighted

    property string mediaItem: ""
    property bool selected
    property bool isVideo: mediaItem.includes(".mp4") || mediaItem.includes(".webm")
    function mapLayoutImage(layoutName) {
        if (layoutName === "Cyan") return "Turquoise";
        if (layoutName === "Crimson") return "Dark Red";
        if (layoutName === "Lime") return "Light Green";
        if (layoutName === "Gold") return "Yellow";
        if (layoutName === "Violet") return "Purple";
        if (layoutName === "Teal") return "Stone";
        return layoutName;
    }

    scale: selected ? 1.05 : 1
    Behavior on scale { NumberAnimation { duration: 100 } }
    z: selected ? 10 : 1

    Component {
    id: videoPreviewWrapper

        Video {
            anchors.fill: parent
            source: mediaItem
            fillMode: VideoOutput.PreserveAspectCrop
            muted: true
            loops: MediaPlayer.Infinite
            autoPlay: true
        }
    }

    // Anchor for the title bubble only. The accent trace itself is applied to
    // the image below as a layer effect, so it follows the artwork's real
    // silhouette — a round disc or a transparent logo gets outlined by its
    // actual shape rather than boxed in a square frame.
    Item {
    id: border
        anchors.fill: parent
        visible: selected
        z: 20

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
                    if (mediaItem.includes("titlescreen") || mediaItem.includes("screenshottitle")) return "Title Screen";
                    if (mediaItem.includes("box3d") || mediaItem.includes("box_3d") || mediaItem.includes("3dbox")) return "3D Box";
                    if (mediaItem.includes("box2dFront") || mediaItem.includes("box2dfront") || mediaItem.includes("box2d_front")) return "Box Art";
                    if (mediaItem.includes("boxFront") || mediaItem.includes("box_front")) return "Box Art";
                    if (mediaItem.includes("box2dBack") || mediaItem.includes("box2dback") || mediaItem.includes("box2d_back")) return "Back Box";
                    if (mediaItem.includes("boxBack")  || mediaItem.includes("box_back"))  return "Back Box";
                    if (mediaItem.includes("cartridge") || mediaItem.includes("support")) return "Cartridge";
                    if (mediaItem.includes("miximage") || mediaItem.includes("mix_image") || mediaItem.includes("steamgrid") || mediaItem.includes("/steam/") || mediaItem.includes("/grid/")) return "Miximage";
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

    // Traces the accent around whatever is actually visible in the artwork.
    // Glow blurs the SOURCE'S ALPHA and colours it, drawing the result behind
    // the source — so transparent regions are ignored and the outline hugs the
    // real shape instead of the item's bounding box.
    Component {
    id: accentTraceEffect

        Glow {
            // radius drives how far the trace extends; samples must stay ahead
            // of it or the edge bands. spread pushes the colour toward solid so
            // it reads as a border rather than a soft halo.
            radius: vpx(10)
            samples: 25
            spread: 0.6
            color: theme.accent
            transparentBorder: true
        }
    }

    Image {
    id: bg

        anchors.fill: parent
        anchors.margins: vpx(4)
        source: isVideo ? "" : mediaItem
        // Fit, not Crop. Crop scaled every image up to fill the tile and cut
        // off whatever didn't match its aspect — a clear logo or a round disc
        // lost its edges and read as a bigger, cropped square. Fit keeps the
        // whole picture intact at whatever size fits, and the margin it leaves
        // is transparent, which is also what lets the accent trace follow the
        // artwork's real silhouette rather than the tile's edge.
        fillMode: Image.PreserveAspectFit
        asynchronous: true

        // Only the selected tile is traced; unselected ones render plainly so
        // there is no per-tile effect cost across the whole row.
        layer.enabled: selected
        layer.effect: accentTraceEffect

        Rectangle {
        id: videopreview

            anchors.fill: parent
            color: theme.secondary
            visible: isVideo && !selected
        }

        Image {
        id: iconFill

            anchors.fill: parent
            source: "../assets/images/colorspng/" + mapLayoutImage(settings.ColorLayout) + ".png"
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
            visible: isVideo && !selected
        }

        Loader {
        id: videoPreviewLoader

            anchors.fill: parent
            sourceComponent: selected && isVideo ? videoPreviewWrapper : undefined
            asynchronous: true
        }
        
    }

    // Unselected tiles stay fully visible — just translucent — instead of being
    // darkened under a black scrim. This dims the whole item (image + border
    // trace together) rather than one layer, so the accent outline fades with
    // the photo instead of staying full-strength over a dim picture.
    opacity: selected ? 1.0 : 0.78
    Behavior on opacity { NumberAnimation { duration: 100 } }
    
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
