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
    // Pegasus X lists the game's 3D boxes in extra.box3d; the file-name test
    // is the fallback (same rule as utils.js is3dFor, inlined: see NOTE above).
    function is3dPath(path) {
        if (!path) return false;
        var l = (gameData && gameData.extra) ? gameData.extra.box3d : null;
        if (l) {
            if (typeof l === "string") l = [l];
            var k = urlKey(path);
            for (var i = 0; i < l.length; i++) if (urlKey(l[i]) === k) return true;
        }
        var p = String(path).toLowerCase();
        return p.includes("box3d") || p.includes("box_3d") || p.includes("3dbox");
    }
    function urlKey(u) {
        var s = String(u || "");
        if (s.indexOf("file://") === 0) s = s.substring(7);
        try { s = decodeURIComponent(s); } catch (e) {}
        return s;
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
    // Xbox-style focus: small corners and Global/FocusFrame.qml around a 2D
    // box; a thin, tight trace around a 3D box.
    readonly property real artRadius: vpx(6)
    // HQ: eased pop into the highlight instead of a linear ramp.
    Behavior on scale { enabled: !reduceMotion;
        NumberAnimation {
            duration: animMs(hqMode ? 180 : 100)
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
    // The game whose art is shown — ASSIGNED, never bound, so the art's
    // source only changes when the tile decides (see DynamicGridItem.artGame).
    property var artGame: null
    readonly property bool artArmed: artGame !== null
    // Art while racing, once the tile has kept its game this long (see
    // DynamicGridItem.raceArtMs). 0 = no art until the race ends.
    property int raceArtMs: 100
    // Set by a host that knows; a tile in a look-ahead row waits until its
    // row is actually on screen, so no decode is spent on rows never seen.
    property bool onScreen: true
    Timer {
    id: raceArm
        interval: Math.max(1, root.raceArtMs)
        onTriggered: if (root.deferArt && root.gameData && root.onScreen) root.artGame = root.gameData
    }
    onOnScreenChanged: if (onScreen && deferArt && gameData && artGame === null && raceArtMs > 0) raceArm.restart()
    function takeGame() {
        raceArm.stop();
        artGame = (deferArt || !gameData) ? null : gameData;
        if (deferArt && gameData && raceArtMs > 0) raceArm.restart();
    }
    Component.onCompleted: takeGame()
    onGameDataChanged: takeGame()
    onDeferArtChanged: if (!deferArt && gameData && artGame !== gameData) { raceArm.stop(); artGame = gameData; }
    function resetForReuse() { takeGame(); }

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
    // Fast corners: a 2D box rounds
    // its own corners in one draw (RoundedArt) instead of going through an
    // offscreen layer + OpacityMask. 3D renders have no corners to round and
    // keep their selected-tile glow layer. Falls back to the mask if the
    // shader ever fails to compile.
    readonly property bool fastArt: !is3d
                                    && !artFx.failed

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
    // Subtle persistent glow for favorited tiles (not selected — the focus
    // frame covers that case).
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
            anchors.fill: parent   // the Loader, which already fills tileHaloSrc
            source: tileHaloSrc
            color: theme.accent
            z: -1
            opacity: (gameData && gameData.favorite && !selected && !is3d && settings.FavoritedTileAccent !== "No") ? 0.35 : 0
            visible: opacity > 0
            Behavior on opacity { enabled: !reduceMotion; NumberAnimation { duration: animMs(180); easing.type: Easing.OutCubic } }
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
        Behavior on opacity { enabled: !reduceMotion; NumberAnimation { duration: animMs(200) } }
                       
        Image {
        id: screenshot
            // Sized explicitly (not anchors.fill) so a stood-up wide render can
            // swap its box: rotated 90 deg, its width must be the frame's height.
            anchors.centerIn: parent
            width:  (root.wide3d ? parent.height : parent.width)  - vpx(4)
            height: (root.wide3d ? parent.width  : parent.height) - vpx(4)
            rotation: root.wide3d ? 90 : 0
            // Fast corners: this Image only decodes; artFx below draws it.
            visible: !root.fastArt

            asynchronous: true
            // HQ: dissolve in on load instead of snapping.
            opacity: hqFadeIn ? (status === Image.Ready ? 1 : 0) : 1
            Behavior on opacity { enabled: !reduceMotion && hqFadeIn; NumberAnimation { duration: animMs(180) } }
            source: artGame ? boxArt(artGame) : ""
            sourceSize { width: root.width; height: root.height }
            smooth: true
            fillMode: Image.PreserveAspectFit

            // Rounded corners on the painted box, same radius as the dynamic
            // tile, so the art's corners don't poke past the halo's rounded
            // inner edge. The mask is a rounded rect over the PAINTED region
            // (PreserveAspectFit centres it), not the whole image bounds.
            // One layer slot: 2D boxes use it for rounded corners; a 3D box has
            // its own silhouette, so when selected it uses it for the accent
            // glow that traces that silhouette instead (as the carousel does).
            layer.enabled: is3d ? selected : !root.fastArt
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
                            radius: root.artRadius
                        }
                    }
                }
            }
            Component {
            id: accentTrace
                // 3D renders often carry near-invisible pixels (a faint drop
                // shadow, leftover alpha) around the box. A glow straight off
                // the image traced those too and drew a blocky accent patch
                // beside the box. The glow now traces a thresholded copy (only
                // what's clearly the box), and the untouched image is drawn
                // back on top, soft shadow included.
                Item {
                    property variant source
                    ThresholdMask {
                    id: solidBox
                        anchors.fill: parent
                        source: parent.source
                        maskSource: parent.source
                        threshold: 0.75   // only solid box pixels; drop shadows sit below this
                        spread: 0.1
                        visible: false
                    }
                    Glow {
                        anchors.fill: solidBox
                        source: solidBox
                        // A thin, tight trace, like the 2D boxes' frame
                        radius: vpx(4)
                        samples: 17
                        spread: 0.85
                        color: theme.accent
                        transparentBorder: true
                    }
                    ShaderEffect {
                        anchors.fill: parent
                        property variant source: parent.source
                    }
                }
            }
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

        }

        // Fast corners: the 2D box above, drawn with its corners rounded in the
        // same pass. Sized to the PAINTED box (PreserveAspectFit centres it),
        // which the texture fills exactly. Follows the image's opacity, so the
        // HQ dissolve-in is unchanged.
        RoundedArt {
        id: artFx
            anchors.centerIn: screenshot
            width: screenshot.paintedWidth
            height: screenshot.paintedHeight
            source: screenshot
            crop: false
            radius: root.artRadius
            opacity: screenshot.opacity
            // Only once the image is decoded: with no texture yet, GL samples
            // solid black, which would flash a black box while art loads.
            visible: !root.is3d && !failed
                     && screenshot.status === Image.Ready
        }

        // 2D title bar over the box. It used to live INSIDE the image so the
        // box's mask rounded its corners; it now rounds its own (see
        // boxTitleBar), so it sits beside the image and works whether the
        // image is drawn masked or by artFx. 2D boxes are never rotated, so
        // centring on the image places it exactly where it was.
        Loader {
            active: !root.is3d && root.titleShown
            anchors.centerIn: screenshot
            width: screenshot.paintedWidth; height: screenshot.paintedHeight
            sourceComponent: boxTitleBar
            // As a child of the image it inherited the HQ dissolve-in; keep that.
            opacity: (active ? 1 : 0) * screenshot.opacity
            Behavior on opacity { enabled: !reduceMotion; NumberAnimation { duration: animMs(120) } }
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
            width: Math.min(root.width * 0.075, vpx(20))
            height: width
            // 2D boxes carry the pin inside their title bar; this one is for 3D
            // renders only, and like the bar it shows only when the title does.
            opacity: (gameData && gameData.favorite && is3d && titleShown) ? 1 : 0
            visible: opacity > 0
            scale: (gameData && gameData.favorite) ? 1 : 0.4
            Behavior on opacity { enabled: !reduceMotion; NumberAnimation { duration: animMs(180); easing.type: Easing.OutCubic } }
            Behavior on scale { enabled: !reduceMotion; NumberAnimation { duration: animMs(220); easing.type: Easing.OutBack; easing.overshoot: 3 } }
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
    // along the bottom of the box, favourite pin inside it at the right. It
    // rounds its own bottom corners to the box's 12px radius (a square upper
    // part, and a rounded strip cut to its lower half by a clip; the two never
    // overlap, so the 60% black stays even).
    Component {
    id: boxTitleBar
        Item {
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: Math.max(vpx(44), parent.height * 0.16, parent.width * 0.16, barText.contentHeight + vpx(16))
                color: "transparent"
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: parent.height - root.artRadius
                    color: "#99000000"
                }
                Item {
                    clip: true
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: root.artRadius
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: root.artRadius * 2
                        radius: root.artRadius
                        color: "#99000000"
                    }
                }
                Text {
                id: barText
                    anchors {
                        left: parent.left; leftMargin: vpx(8)
                        right: parent.right
                        rightMargin: (gameData && gameData.favorite) ? (barPin.width + vpx(14)) : vpx(6)
                        verticalCenter: parent.verticalCenter
                    }
                    text: gameData ? gameData.title : ""
                    color: "white"; font.family: subtitleFont.name
                    font.pixelSize: Math.max(fpx(13), parent.parent.height * 0.05, parent.parent.width * 0.05); font.bold: true
                    wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
                }
                Image {
                id: barPin
                    anchors { right: parent.right; rightMargin: vpx(8); bottom: parent.bottom; bottomMargin: vpx(8) }
                    // Sized against the BOX's width, not the bar's height. Every
                    // tile hit the same 26px cap, but a box is narrower than a
                    // wide/square tile, so the identical pin covered more of it
                    // and read as oversized. 0.075 matches the proportion the
                    // dynamic tile's pin has to its own width.
                    width: Math.min(parent.width * 0.075, vpx(26)); height: width
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
        radius: root.artRadius                   // follows the art's rounded corners
        border.width: vpx(2)
        border.color: theme.accent
        visible: gameData && gameData.favorite && !is3d && settings.FavoritedTileAccent !== "No"
    }

    Loader {
        active: selected && !is3d
        anchors.fill: artBounds
        sourceComponent: xboxBorder
        asynchronous: true
    }

    Component {
    id: xboxBorder

        // Wrapped: the Loader sizes its item to itself, which would undo the
        // frame's negative margins.
        Item {
            FocusFrame {
                anchors.fill: parent
                artRadius: root.artRadius
                // This tile grows 1.1x on focus; the frame is sized against
                // that so its ring matches the other tiles'.
                gap: vpx(2) / 1.1
                ring: vpx(3) / 1.1
                glow: vpx(6) / 1.1
            }
        }
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

        text: gameData ? gameData.title : ''
        // Always light: the pill behind it (#B3000000) is dark whatever the
        // page background colour is, so theme.text's White-mode flip is wrong here.
        color: "#ebebeb"
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

        text: gameData ? gameData.title : ""
        anchors { fill: parent; margins: vpx(10) }
        color: "white"
        scale: selected ? 1.1 : 1
        Behavior on opacity { enabled: !reduceMotion; NumberAnimation { duration: animMs(100) } }
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
    // Clickable prompts (theme.qml helpClick): A on the focused tile.
    function helpAction(button) {
        if (button !== "accept") return false;
        activate();
        return true;
    }

    // Mouse/touch functionality
    MouseArea {
        anchors.fill: parent
        hoverEnabled: settings.MouseHover == "Yes"
        // Hover selects only when the pointer itself moved (theme.qml
        // pointerMoved): a list scrolling under a still mouse must not
        // steal the selection. Movement inside the tile counts too, so the
        // first nudge onto a tile after a pause still selects it.
        function hoverSelect() { if (!root.selected && pointerMoved()) { playNav(); highlighted(); } }
        onEntered: hoverSelect()
        onPositionChanged: hoverSelect()
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