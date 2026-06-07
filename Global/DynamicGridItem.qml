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

Item {
id: root
    
    // NOTE: This is technically duplicated from utils.js but importing that file into every delegate causes crashes
    function steamAppID (gameData) {
        var str = (gameData.assets.boxFront || "").split("header");
        return str[0];
    }

    function steamLogo(gameData) {
        return steamAppID(gameData) + "/logo.png"
    }


    function logo(data) {
    if (data != null) {
        if (data.assets.boxFront && data.assets.boxFront.includes("header.jpg")) 
            return steamLogo(data);
        else {
            if (data.assets.logo != "")
                return data.assets.logo;
            }
        }
        return "";
    }

    signal activated
    signal highlighted
    signal unhighlighted

    property bool selected
    property var gameData: modelData
    // Art type to display. Defaults to the showcase art setting so the showcase
    // (HorizontalCollection) is unchanged; GridViewMenu overrides this with the
    // platform-page "Grid art" setting (Fanart / Screenshot / Boxfront).
    property string artMode: settings.ShowcaseArt
    // Whether to draw the game-logo overlay. Defaults true so the showcase
    // (HorizontalCollection) is unchanged; GridViewMenu sets this from the
    // platform-page "Game logo" setting (lets logos be hidden so they don't
    // clash with, e.g., Tall + Boxfront tiles that already show the title).
    property bool showLogo: true


    // In order to use the retropie icons here we need to do a little collection specific hack
    property bool playVideo: gameData ? gameData.assets.videoList.length && (settings.AllowThumbVideo == "Yes") : ""
    scale: selected ? 1 : 0.95
    Behavior on scale { NumberAnimation { duration: 100 } }
    z: selected ? 10 : 1

    onSelectedChanged: {
        if (selected && playVideo)
            fadescreenshot.restart();
        else {
            fadescreenshot.stop();
            screenshot.opacity = 1;
            container.opacity = 1;
        }
    }

    // NOTE: Fade out the bg so there is a smooth transition into the video
    Timer {
    id: fadescreenshot

        interval: 1200
        onTriggered: {
            if (settings.HideLogo == "Yes")
                container.opacity = 0;
            else
                screenshot.opacity = 0;
        }
    }

    Item 
    {
    id: container

        anchors.fill: parent
        Behavior on opacity { NumberAnimation { duration: 200 } }

        // Round the tile art to match the rounded selection frame (vpx(6)),
        // so the crop-filled screenshot doesn't poke past the frame's corners.
        layer.enabled: true
        layer.smooth: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: container.width
                height: container.height
                radius: vpx(6)
            }
        }

        // Name bar — shows the game title on highlight only. Lives inside the
        // rounded container, so its bottom corners follow the tile radius (square top).
        Rectangle {
        id: titleBar
            z: 20
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: Math.max(vpx(36), container.height * 0.16, nameBarText.contentHeight + vpx(16))   // scales with tile size; grows for 2-line titles
            color: "#99000000"            // ~60% black; text stays full-opacity
            opacity: (selected || settings.AlwaysShowTitles === "Yes") ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
            Text {
                anchors { left: parent.left; leftMargin: vpx(8); right: parent.right; rightMargin: vpx(6); verticalCenter: parent.verticalCenter }
                id: nameBarText
                text: modelData ? modelData.title : ""
                color: "white"; font.family: subtitleFont.name
                font.pixelSize: Math.max(vpx(11), container.height * 0.05); font.bold: true
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
            }
        }

        Image {
        id: screenshot

            anchors.fill: parent
            anchors.margins: vpx(2)
            source: modelData ? (
                      artMode === "Screenshot" ? (modelData.assets.screenshots[0] || modelData.assets.background || "")
                    : artMode === "Boxfront"   ? (modelData.assets.boxFront || modelData.assets.background || modelData.assets.screenshots[0] || "")
                    :                            (modelData.assets.background || modelData.assets.screenshots[0] || "")
                  ) : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize { width: 512; height: 512 }
            smooth: false
            asynchronous: true
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        Image {
        id: favelogo

            visible: showLogo
            anchors.fill: parent
            anchors.centerIn: parent
            anchors.margins: root.width/10
            property var logoImage: (gameData && gameData.collections.get(0).shortName === "retropie") ? gameData.assets.boxFront : (gameData.collections.get(0).shortName === "steam") ? logo(gameData) : gameData.assets.logo
            source: modelData ? logoImage || "" : ""
            sourceSize { width: 200; height: 150 }
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            scale: selected ? 1.1 : 1
            Behavior on scale { NumberAnimation { duration: 100 } }
            z: 10
        }

        Rectangle {
        id: overlay
        
            anchors.fill: parent
            color: screenshot.source == "" ? theme.secondary : "black"
            opacity: screenshot.source == "" ? 1 : selected ? 0.1 : 0.2
        }
        
        Rectangle {
        id: regborder

            anchors.fill: parent
            color: "transparent"
            border.width: vpx(1)
            border.color: "white"
            opacity: 0.1
        }
        
    }

    Loader {
    id: borderloader

        active: selected
        anchors.fill: parent
        sourceComponent: border
        asynchronous: true
    }

    Component {
    id: border

        ItemBorder { }
    }

    Text {
    id: title

        text: modelData ? modelData.title : ''
        color: theme.text
        font {
            family: subtitleFont.name
            pixelSize: vpx(12)
            bold: true
        }

        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        anchors {
            top: container.bottom; topMargin: vpx(8)
        }

        width: parent.width

        opacity: 0.2
        visible: false   // old faint under-tile title; replaced by the on-tile black bar
    }

    Text {
    id: platformname

        text: modelData.title
        anchors { fill: parent; margins: vpx(10) }
        color: "white"
        scale: selected ? 1.1 : 1
        Behavior on opacity { NumberAnimation { duration: 100 } }
        font.pixelSize: vpx(18)
        font.family: subtitleFont.name
        font.bold: true
        style: Text.Outline; styleColor: theme.main
        visible: showLogo && (favelogo.status === Image.Null || favelogo.status === Image.Error)
        anchors.centerIn: parent
        elide: Text.ElideRight
        wrapMode: Text.WordWrap
        lineHeight: 0.8
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Rectangle {
    id: favicon

        anchors { 
            right: parent.right; rightMargin: vpx(10); 
            top: parent.top; topMargin: vpx(10) 
        }
        width: parent.width / 12
        height: width
        radius: width/2
        color: theme.accent
        visible: gameData.favorite
        Image {
            source: "../assets/images/favicon.svg"
            asynchronous: true
            anchors.fill: parent
            anchors.margins: parent.width / 6
        }
    }

    Loader {
    id: spinnerloader

        anchors.centerIn: parent
        active: screenshot.status === Image.Loading
        sourceComponent: loaderspinner
    }

    Component {
    id: loaderspinner
    
        Image {        
            source: "../assets/images/loading.png"
            width: vpx(50)
            height: vpx(50)
            asynchronous: true
            sourceSize { width: vpx(50); height: vpx(50) }
            RotationAnimator on rotation {
                loops: Animator.Infinite;
                from: 0;
                to: 360;
                duration: 500
            }
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
        onEntered: { playNav(); highlighted(); }
        onExited: { unhighlighted(); }
        onClicked: {
            playNav();
            activated();
        }
    }
}