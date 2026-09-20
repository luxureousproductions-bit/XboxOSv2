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
    function steamBoxArt(gameData) {
        return steamAppID(gameData) + '/library_600x900_2x.jpg';
    }
    function is3dPath(path) {
        if (!path) return false;
        var p = path.toLowerCase();
        return p.includes("box3d") || p.includes("box_3d") || p.includes("3dbox");
    }
    function boxArt(data) {
        if (data != null) {
            var list = data.assets.boxFrontList;
            if (artStyle === "3D Box") {
                // Prefer 3D box art: scan boxFrontList for a 3D path
                if (list) {
                    for (var i = 0; i < list.length; i++) {
                        if (is3dPath(list[i])) return list[i];
                    }
                    // No 3D entry found — fall back to first non-3D entry from the list
                    for (var k = 0; k < list.length; k++) {
                        if (!is3dPath(list[k])) return list[k];
                    }
                }
            } else {
                // "Box Art" (2D): prefer the first boxFront entry that is NOT a 3D path
                if (list) {
                    for (var j = 0; j < list.length; j++) {
                        if (!is3dPath(list[j])) return list[j];
                    }
                }
            }
            // Shared fallback
            if (data.assets.boxFront && data.assets.boxFront.includes("/header.jpg"))
                return steamBoxArt(data);
            if (data.assets.boxFront)
                return data.assets.boxFront;
            if (data.assets.boxBack)
                return data.assets.boxBack;
            if (data.assets.poster)
                return data.assets.poster;
            if (data.assets.banner)
                return data.assets.banner;
            if (data.assets.tile)
                return data.assets.tile;
            if (data.assets.cartridge)
                return data.assets.cartridge;
            if (data.assets.miximage)
                return data.assets.miximage;
            if (data.assets.mix_image)
                return data.assets.mix_image;
            if (data.assets.logo)
                return data.assets.logo;
        }
        return "";
    }

    property bool selected
    // HQ: eased pop into the highlight instead of a linear ramp.
    Behavior on scale { enabled: !reduceMotion;
        NumberAnimation {
            duration: hqMode ? 180 : 100
            easing.type: hqMode ? Easing.OutBack : Easing.Linear
            easing.overshoot: 1.2
        }
    }
    property var gameData
    property int columns: 6
    property string artStyle: "Box Art"
    // Fast scrolling: the host sets this while the cursor is racing, and every
    // animation on the tile is skipped — a pop, fade or slide the user has
    // already scrolled past is pure cost. Nothing changes at rest.
    // Title mode: the global "Game tile titles" unless the host says otherwise
    // (the Platform page can set it per system).
    property string titleMode: gameTitleMode
    property bool reduceMotion: false
    // Fast-scroll art deferral: a tile CREATED while the host says deferArt
    // holds off loading its art until deferArt clears (the scroll stopped).
    // A tile that already has its art is never affected — the latch only
    // starts false when the tile is born mid-race.
    property bool deferArt: false
    property bool artArmed: true
    Component.onCompleted: if (deferArt) artArmed = false
    onDeferArtChanged: if (!deferArt) artArmed = true

    scale: selected ? 1.1 : 1
    z: selected ? 10 : 1

    signal activate()
    signal highlighted()

    // Focus glow — same asset, tint, and technique as the system tiles so it
    // matches their look. The white PNG (transparent centre) gives the glow
    // shape; ColorOverlay recolors it to the Color Layout accent. The
    // transparent centre means it never tints a video playing behind the tile.
    // True when the image actually shown is a 3D box render. Those have their
    // own silhouette, so the rectangular halo/frame is replaced by an accent
    // glow that traces the shape — the same treatment the media carousel uses.
    readonly property bool is3d: is3dPath(screenshot.source.toString())
    // A 3D render wider than it is tall (SNES, N64 and the like lie flat) is
    // stood on its side so it matches the other boxes. Decided from the
    // source image's own proportions, so it works for any wide system.
    readonly property bool wide3d: is3d && screenshot.status === Image.Ready
                                   && screenshot.implicitWidth > screenshot.implicitHeight

    Image {
        id: tileHaloSrc
        // Size per-dimension (not a uniform width-based margin) so the glow's
        // transparent centre matches the tile on ANY aspect — square, tall, or
        // wide — with no gap. 1.1228 = 1 + 2*0.0614 keeps the same bleed as the
        // system tiles.
        anchors.centerIn: artBounds
        width:  artBounds.width  * 1.1228
        height: artBounds.height * 1.1228
        source: "../assets/images/focus_halo.png"
        smooth: true
        mipmap: false
        visible: false
    }
    // On demand: the effect (a shader plus its own offscreen texture) exists
    // only while it could be seen. It used to be instantiated on EVERY tile —
    // two effects per tile doing nothing on every screen full of tiles.
    Loader {
        active: selected
        anchors.fill: tileHaloSrc
        z: -1
        sourceComponent: Component {
        ColorOverlay {
            id: tileGlow
            anchors.fill: tileHaloSrc
            source: tileHaloSrc
            color: theme.accent
            z: -1
            opacity: (selected && !is3d && settings.TileHalo === "Yes") ? 0.95 : 0
            visible: opacity > 0
            Behavior on opacity { enabled: !reduceMotion; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
        }
    }
    // Subtle persistent glow for favorited tiles (not selected — the bright
    // tileGlow above already covers that case).
    // On demand: the effect (a shader plus its own offscreen texture) exists
    // only while it could be seen. It used to be instantiated on EVERY tile —
    // two effects per tile doing nothing on every screen full of tiles.
    Loader {
        active: gameData && gameData.favorite && !selected
        anchors.fill: tileHaloSrc
        z: -1
        sourceComponent: Component {
        ColorOverlay {
            id: favGlow
            anchors.fill: tileHaloSrc
            source: tileHaloSrc
            color: theme.accent
            z: -1
            opacity: (gameData && gameData.favorite && !selected && !is3d && settings.FavoritedTileAccent !== "No") ? 0.35 : 0
            visible: opacity > 0
            Behavior on opacity { enabled: !reduceMotion; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
        }
    }

    // Tracks the art as actually drawn. cellHeight is derived from ONE sample
    // box (fakebox in GridViewMenu), so every cell is the same size while the
    // art inside varies — PreserveAspectFit then letterboxes anything with a
    // different aspect, and accents anchored to the cell float away from it.
    //
    // Falls back to the container while the image is still loading or missing,
    // so nothing collapses to zero.
    Item {
    id: artBounds

        readonly property bool ready: screenshot.status === Image.Ready
                                      && screenshot.paintedWidth > 0
        width:  ready ? (root.wide3d ? screenshot.paintedHeight : screenshot.paintedWidth)  : container.width
        height: ready ? (root.wide3d ? screenshot.paintedWidth  : screenshot.paintedHeight) : container.height
        anchors.centerIn: container
    }

    Item 
    {
    id: container

        anchors.fill: parent
        anchors.margins: vpx(6)
        Behavior on opacity { enabled: !reduceMotion; NumberAnimation { duration: 200 } }
                       
        Image {
        id: screenshot
            // Sized explicitly (not anchors.fill) so a stood-up wide render can
            // swap its box: rotated 90 deg, its width must be the frame's height.
            anchors.centerIn: parent
            width:  (root.wide3d ? parent.height : parent.width)  - vpx(4)
            height: (root.wide3d ? parent.width  : parent.height) - vpx(4)
            rotation: root.wide3d ? 90 : 0

            asynchronous: true
            // HQ: dissolve in on load instead of snapping.
            opacity: hqFadeIn ? (status === Image.Ready ? 1 : 0) : 1
            Behavior on opacity { enabled: !reduceMotion && hqFadeIn; NumberAnimation { duration: 180 } }
            source: artArmed ? boxArt(gameData) : ""
            sourceSize { width: root.width; height: root.height }
            smooth: false
            fillMode: Image.PreserveAspectFit

            // Rounded corners on the painted box, same radius as the dynamic
            // tile, so the art's corners don't poke past the halo's rounded
            // inner edge. The mask is a rounded rect over the PAINTED region
            // (PreserveAspectFit centres it), not the whole image bounds.
            // One layer slot: 2D boxes use it for rounded corners; a 3D box has
            // its own silhouette, so when selected it uses it for the accent
            // glow that traces that silhouette instead (as the carousel does).
            layer.enabled: is3d ? selected : true
            layer.smooth: true
            layer.effect: is3d ? accentTrace : roundedMask
            Component {
            id: roundedMask
                OpacityMask {
                    maskSource: Item {
                        width: screenshot.width; height: screenshot.height
                        Rectangle {
                            anchors.centerIn: parent
                            width: screenshot.paintedWidth; height: screenshot.paintedHeight
                            radius: vpx(12)
                        }
                    }
                }
            }
            // 2D title fade, inside the mask so its corners round with the box.
            Loader {
                active: !root.is3d && root.titleShown
                anchors.centerIn: parent
                width: screenshot.paintedWidth; height: screenshot.paintedHeight
                sourceComponent: boxTitleBar
                opacity: active ? 1 : 0
                Behavior on opacity { enabled: !reduceMotion; NumberAnimation { duration: 120 } }
            }
            Component {
            id: accentTrace
                Glow {
                    radius: vpx(10)
                    samples: 25
                    spread: 0.6
                    color: theme.accent
                    transparentBorder: true
                }
            }
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

        }

        // Favorite heart — bottom-right corner of the tile. No title bar exists
        // on box-art tiles to tie it to, so (unlike DynamicGridItem) this stays
        // persistently visible whenever the game is favorited, matching the
        // always-on border/glow treatment.
        Item {
        id: favicon

            // Corner of the CELL, as it originally was. Anchoring to the painted
            // art put it outside the visible box on 3D renders, whose painted
            // bounds include a transparent margin.
            anchors {
                right: parent.right; rightMargin: vpx(9)
                bottom: parent.bottom; bottomMargin: vpx(9)
            }
            z: 40
            width: vpx(20)
            height: width
            // 2D boxes carry the pin inside their title bar; this one is for 3D
            // renders only, and like the bar it shows only when the title does.
            opacity: (gameData && gameData.favorite && is3d && titleShown) ? 1 : 0
            visible: opacity > 0
            scale: (gameData && gameData.favorite) ? 1 : 0.4
            Behavior on opacity { enabled: !reduceMotion; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale { enabled: !reduceMotion; NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 3 } }
            Image {
                source: "../assets/images/favicon.svg"
                asynchronous: true
                anchors.fill: parent
                anchors.margins: vpx(4)   // matches the glyph size from the old circle-badge version
            }
        }

        Rectangle {
        id: regborder

            anchors.fill: parent
            color: "transparent"
            border.width: vpx(1)
            border.color: "white"
            opacity: 0.1
            visible: false
        }

        Rectangle {
        id: overlay
        
            width: screenshot.paintedWidth
            height: screenshot.paintedHeight
            anchors.centerIn: screenshot
            color: screenshot.source == "" ? theme.secondary : "black"
            opacity: screenshot.source == "" ? 1 : selected ? 0.0 : 0.2
            visible: false
        }

        
    }

    // Title bar for 2D boxes: the SAME bar the dynamic tile shows — solid,
    // along the bottom of the box, favourite pin inside it at the right. Drawn
    // as a child of the image so the box's rounded mask clips its corners.
    Component {
    id: boxTitleBar
        Item {
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: Math.max(vpx(44), parent.height * 0.16, parent.width * 0.16, barText.contentHeight + vpx(16))
                color: "#99000000"
                Text {
                id: barText
                    anchors {
                        left: parent.left; leftMargin: vpx(8)
                        right: parent.right
                        rightMargin: (gameData && gameData.favorite) ? (barPin.width + vpx(14)) : vpx(6)
                        verticalCenter: parent.verticalCenter
                    }
                    text: modelData ? modelData.title : ""
                    color: "white"; font.family: subtitleFont.name
                    font.pixelSize: Math.max(fpx(13), parent.parent.height * 0.05, parent.parent.width * 0.05); font.bold: true
                    wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
                }
                Image {
                id: barPin
                    anchors { right: parent.right; rightMargin: vpx(8); bottom: parent.bottom; bottomMargin: vpx(8) }
                    width: Math.min(parent.height * 0.55, vpx(26)); height: width
                    source: "../assets/images/favicon.svg"
                    sourceSize { width: Math.round(width * 2); height: Math.round(height * 2) }
                    visible: gameData && gameData.favorite
                    smooth: true
                }
            }
        }
    }
    readonly property bool titleShown: titleMode === "Never" ? false : (selected || titleMode === "Always")

    // Thin persistent accent border for favorited tiles — always visible
    // (not just on focus), so favorites stand out while scrolling past.
    Rectangle {
        id: favBorder
        anchors.fill: artBounds
        color: "transparent"
        radius: vpx(12)                   // follows the art's rounded corners
        border.width: vpx(2)
        border.color: theme.accent
        visible: gameData && gameData.favorite && !is3d && settings.FavoritedTileAccent !== "No"
    }

    Loader {
        active: selected && !is3d
        anchors.fill: artBounds
        sourceComponent: border
        asynchronous: true
    }

    Component {
    id: border

        ItemBorder { }
    }

    // Backing pill for the 3D-box title: hugs the text, so it reads over a
    // neighbouring box's transparent margin without being a slab.
    Rectangle {
        visible: title.visible
        z: 30
        anchors.centerIn: title
        width: Math.min(title.contentWidth + vpx(16), root.width)
        height: title.contentHeight + vpx(8)
        radius: height / 2
        color: "#B3000000"
        opacity: title.opacity
    }
    Text {
    id: title

        text: modelData ? modelData.title : ''
        color: theme.text
        font {
            family: subtitleFont.name
            pixelSize: Math.max(fpx(14), root.width * 0.075)   // scales with the tile; was a fixed 12
            bold: true
        }

        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        anchors {
            top: container.bottom; topMargin: vpx(8)
            left: parent.left; right: parent.right
        }

        // 3D boxes only: their painted bounds include transparent margin, so a
        // bar "along the bottom" floats in the wrong place. Plain text beneath
        // the box is the honest layout. 2D boxes use the fade inside the art.
        opacity: selected ? 1.0 : 0.6
        z: 30
        visible: is3d && titleShown
    }

    Text {
    id: platformname

        text: modelData.title
        anchors { fill: parent; margins: vpx(10) }
        color: "white"
        scale: selected ? 1.1 : 1
        Behavior on opacity { enabled: !reduceMotion; NumberAnimation { duration: 100 } }
        font.pixelSize: fpx(18)
        font.family: subtitleFont.name
        font.bold: true
        style: Text.Outline; styleColor: theme.main
        visible: screenshot.status === Image.Null || screenshot.status === Image.Error
        anchors.centerIn: parent
        elide: Text.ElideRight
        wrapMode: Text.WordWrap
        lineHeight: 0.8
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
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
            activate();        
        }
    }

    // Mouse/touch functionality
    MouseArea {
        anchors.fill: parent
        hoverEnabled: settings.MouseHover == "Yes"
        onEntered: { playNav(); highlighted(); }
        onClicked: {
            playNav();
            activate();
        }
    }
    
    /*// Mouse/touch functionality
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {}
        onExited: {}
        onClicked: {
            if (selected)
            {
                activate();
            }
            else
            {
                currentGameIndex = index
            }
        }
    }*/
}