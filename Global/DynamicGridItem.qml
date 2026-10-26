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
    // One corner radius for every rounded piece of the tile; the focus
    // frame (Global/FocusFrame.qml) is drawn concentric with it.
    readonly property real artRadius: vpx(6)
    property var gameData: modelData

    // Apps imported by Pegasus, matched on file path — "android:<package>".
    readonly property bool isImportedApp: {
        if (!gameData || !gameData.files || gameData.files.count < 1) return false;
        var p = gameData.files.get(0).path || "";
        return p.indexOf("android:") === 0;
    }
    readonly property string appIconArt: {
        if (!gameData || !gameData.assets) return "";
        var a = gameData.assets;
        return a.boxFront || a.logo || a.poster || a.banner || "";
    }
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
    // HQ: neighbours recede further and the pop is eased. The highlighted
    // tile itself stays at 1.0 so it lines up with the highlight's video.
    scale: selected ? 1 : hqRestScale
    Behavior on scale { enabled: !reduceMotion;
        NumberAnimation {
            duration: hqMode ? 180 : 100
            easing.type: hqMode ? Easing.OutBack : Easing.Linear
            easing.overshoot: 1.2
        }
    }
    z: selected ? 10 : 1

    // The art fades out under the video preview so the video shows cleanly.
    // It must come back whenever the preview ISN'T actually covering it —
    // not only on deselect. Leaving the Showcase for Settings kept the tile
    // selected, so the art stayed hidden while the preview was torn down, and
    // the tile sat as an empty black box until the preview reloaded on return.
    // Which screen hosts this tile, relayed by the row. Empty means unknown,
    // which falls back to the old behaviour (covering whenever selected).
    property string ownScreen: ""
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
    // Show the name bar while the art is held back or decoding (the Library
    // grid sets it; Home rows keep their plain fade-in).
    property bool titleWhilePending: false
    // The game whose art this tile is showing. ASSIGNED, never bound: the
    // image sources below follow artGame, so they only ever change when
    // this tile decides — when it gets a game (born, or recycled with a new
    // index) while the grid is at rest, or when a race ends. A source bound
    // to gameData directly re-evaluated the moment a recycled tile's index
    // changed, before any reset could run, and requested a decode the reset
    // then cancelled: every step of a race churned through that.
    property var artGame: null
    // The logo has its own: it waits for the race to end, the art doesn't.
    property var logoGame: null
    readonly property bool artArmed: artGame !== null
    // Art while racing. A tile given a game mid-race takes its art once it
    // has kept that game for raceArtMs. The grid's rows only change game at
    // the screen edges, so a row scrolling up the screen keeps its game and
    // gets its art partway; a tile flashing past at the edge never asks.
    // That bounds the decodes to the rows actually seen, with no
    // request-then-cancel. 0 = no art until the race ends.
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
        if (!gameData)  { artGame = null; logoGame = null; return; }
        if (!deferArt)  { artGame = gameData; logoGame = gameData; return; }
        artGame = null; logoGame = null;
        if (raceArtMs > 0) raceArm.restart();
    }
    Component.onCompleted: takeGame()
    onGameDataChanged: takeGame()
    // Race over: whatever this tile is still missing (art, logo) catches up.
    // A tile that kept its art through the race is left alone.
    onDeferArtChanged: {
        if (deferArt || !gameData) return;
        raceArm.stop();
        if (artGame !== gameData)  artGame  = gameData;
        if (logoGame !== gameData) logoGame = gameData;
    }
    // Recycled (reuseItems): back to how a new tile starts. The art is made
    // fully visible again in case it was fading under a preview.
    function resetForReuse() {
        takeGame();
        restoreArt();
    }
    // Fast corners: the art rounds
    // its own corners in one draw (RoundedArt) instead of the whole tile going
    // through an offscreen layer + OpacityMask. Imported apps keep the layer —
    // their blurred backdrop needs it — and so does every tile if the shader
    // ever fails to compile. The video preview is not part of this tile.
    readonly property bool fastArt: !isImportedApp
                                    && !artFx.failed
    readonly property bool previewCovering: selected && playVideo
                                          && (ownScreen === "" || playbackOwner === ownScreen)
    function restoreArt() {
        screenshot.opacity = 1;
        container.opacity = 1;
    }
    // Fade the art the instant the preview is genuinely playing — not on the
    // old 3s timer, which let the video run audibly behind opaque art. The
    // Behaviors on the art give the 180ms crossfade; the preview fades in over
    // the same window, so it reads as one dissolve.
    readonly property bool videoShowing: previewCovering && rowPreviewPlaying
    onVideoShowingChanged: {
        if (videoShowing) fadeArt();
        else restoreArt();
    }
    function fadeArt() {
        if (settings.HideLogo == "Yes") container.opacity = 0;
        else screenshot.opacity = 0;
    }
    onPreviewCoveringChanged: {
        // No timer any more; the reveal is driven by videoShowing above.
        if (!previewCovering) restoreArt();
    }
    onSelectedChanged: {
        // Deselect always restores immediately; selection is handled above.
        if (!selected) restoreArt();
    }

    // (The old 3s fadescreenshot Timer is gone: nothing started it any more —
    // the reveal is driven by videoShowing — but every tile still built it.)

    // Halo image for the favourite glow below. The white PNG (transparent
    // centre) gives the glow shape; ColorOverlay tints it to the accent.
    // Sized per dimension so the transparent centre matches any tile shape.
    Image {
        id: tileHaloSrc
        anchors.centerIn: container
        width:  container.width  * 1.1228
        height: container.height * 1.1228
        source: "../assets/images/focus_halo.png"
        smooth: true
        mipmap: false
        visible: false
    }
    // Subtle persistent glow for favorited tiles (not selected — the focus
    // frame covers that case), so favourites read as "special" while
    // browsing past them.
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
            opacity: (gameData && gameData.favorite && !selected && settings.FavoritedTileAccent !== "No") ? 0.35 : 0
            visible: opacity > 0
            Behavior on opacity { enabled: !reduceMotion; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
        }
    }

    Item 
    {
    id: container

        anchors.fill: parent
        Behavior on opacity { enabled: !reduceMotion; NumberAnimation { duration: 200 } }

        // Round the tile art to match the rounded selection frame (vpx(6)),
        // so the crop-filled screenshot doesn't poke past the frame's corners.
        // Fast corners skip the layer; each piece below rounds itself instead.
        layer.enabled: !root.fastArt
        layer.smooth: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: container.width
                height: container.height
                radius: root.artRadius
            }
        }

        // Name bar — shows the game title on highlight only. Lives inside the
        // rounded container, so its bottom corners follow the tile radius (square top).
        Rectangle {
        id: titleBar
            z: 20
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: Math.max(vpx(44), container.height * 0.16, container.width * 0.16, nameBarText.contentHeight + vpx(16))   // scales with tile size; wide tiles use width factor
            color: root.fastArt ? "transparent" : "#99000000"   // ~60% black; text stays full-opacity
            // Game tile titles: Never hides it even on focus; Always keeps it up.
            // Also up while the tile has no art to show yet — held back by a
            // race, or still decoding after one — so a tile scrolling past is
            // a dark card with its name rather than a blank. The text is
            // already laid out, so this costs nothing extra.
            readonly property bool artPending: root.titleWhilePending && (!artArmed
                || (screenshot.source != "" && screenshot.status !== Image.Ready && screenshot.status !== Image.Error))
            opacity: titleMode === "Never" ? 0 : ((selected || titleMode === "Always" || artPending) ? 1 : 0)
            visible: opacity > 0
            Behavior on opacity { enabled: !reduceMotion; NumberAnimation { duration: 120 } }
            // Fast corners: without the tile's mask the bar rounds its own
            // bottom corners — a square upper part, and a rounded strip cut to
            // its lower half by a clip. The two never overlap, so the 60% black
            // stays even (overlapping halves would double up darker).
            Rectangle {
                visible: root.fastArt
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: parent.height - root.artRadius
                color: "#99000000"
            }
            Item {
                visible: root.fastArt
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
                anchors {
                    left: parent.left; leftMargin: vpx(8)
                    right: parent.right
                    rightMargin: (gameData && gameData.favorite) ? (favicon.width + vpx(14)) : vpx(6)
                    verticalCenter: parent.verticalCenter
                }
                id: nameBarText
                text: gameData ? gameData.title : ""
                color: "white"; font.family: subtitleFont.name
                font.pixelSize: Math.max(fpx(13), container.height * 0.05, container.width * 0.05); font.bold: true
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
            }

            // Favorite heart — lives inside the title bar, bottom-right corner.
            // Fades in/out with the bar itself (child of titleBar => inherits
            // its opacity), so it only ever shows alongside the title.
            Item {
            id: favicon

                anchors {
                    right: parent.right; rightMargin: vpx(8)
                    bottom: parent.bottom; bottomMargin: vpx(8)
                }
                width: Math.min(titleBar.height * 0.55, vpx(26))
                height: width
                visible: gameData && gameData.favorite
                Image {
                    source: "../assets/images/favicon.svg"
                    asynchronous: true
                    anchors.fill: parent
                    anchors.margins: parent.width / 6   // matches the glyph size from the old circle-badge version
                }
            }
        }

        // ── Imported apps ──
        // Apps Pegasus imports have only an icon: no screenshot, no logo. The
        // normal tile renders that icon stretched to a wide box, which looks
        // broken. Instead the icon is blurred to fill the tile, whatever its
        // shape, with a small round copy centred on top.
        //
        // Detected by file path ("android:<package>"), so a ROM or a
        // hand-written .app entry can't match.
        // Only built for an imported app: a blur, two layers and three
        // images that every ROM tile used to carry around invisibly.
        Loader {
        id: appTile
            anchors.fill: parent
            anchors.margins: vpx(2)
            active: root.isImportedApp
            readonly property bool ready: item ? item.ready : false
            visible: ready
            z: 5
            sourceComponent: Component {
        Item {
            readonly property bool ready: appTileArt.status === Image.Ready

            // Blurred backdrop. Oversized INSIDE this clipping item rather than
            // scaled: the effect maps its source's bounds onto its own, so
            // scaling the image directly would simply be undone.
            Item {
            id: appBlurSrc

                anchors.fill: parent
                visible: false
                Image {
                id: appTileArt
                    anchors.centerIn: parent
                    width:  parent.width  * 1.4
                    height: parent.height * 1.4
                    source: root.isImportedApp ? root.appIconArt : ""
                    // Decoded small: it's about to be blurred past any detail,
                    // and the upscale softens it further.
                    sourceSize { width: hqAppBlurSrcPx; height: hqAppBlurSrcPx }
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }
            FastBlur {
                anchors.fill: parent
                source: appBlurSrc
                radius: hqAppBlurRadius   // hard cap is 64; HQ runs at the cap
                cached: true
            }
            // Knocks the backdrop back so the icon stays legible.
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: hqAppTileScrim
            }
            // Shadow plate beneath the icon. Never sources the icon (a shadow
            // effect of a masked item gets its raw, unmasked texture). Base
            // shows the plate flat; HQ blurs it soft. Same as the launch screen.
            Rectangle {
                anchors { horizontalCenter: appRound.horizontalCenter; horizontalCenterOffset: appRound.width * 0.01
                          verticalCenter:   appRound.verticalCenter;   verticalCenterOffset: appRound.height * 0.05 }
                width: appRound.width; height: appRound.height
                radius: appRound.cornerRadius
                color: "#000000"; opacity: hqMode ? 0.55 : 0.35
                layer.enabled: hqMode
                layer.effect: FastBlur { radius: 24; transparentBorder: true }
            }

            // Rounded-square icon, sized off the SHORTER side so it stays
            // proportionate whether the tile is square, wide or tall. Same
            // crop as the drawer tiles and the launch screen.
            Item {
            id: appRound

                anchors.centerIn: parent
                width:  Math.min(parent.width, parent.height) * 0.52
                height: width
                readonly property real cornerRadius: width * 0.18
                layer.enabled: true
                layer.smooth: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: appRound.width; height: appRound.height
                        radius: appRound.cornerRadius
                    }
                }
                Rectangle { anchors.fill: parent; color: "#2E2E2E" }
                Image {
                    anchors.centerIn: parent
                    // Icons are a circle on a transparent square, so the art is
                    // blown past the frame to fill the rounded square.
                    width:  parent.width  * 1.45
                    height: parent.height * 1.45
                    source: root.isImportedApp ? root.appIconArt : ""
                    sourceSize { width: hqMode ? 384 : 256; height: hqMode ? 384 : 256 }
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                }
            }
        }
            }   // Component
        }   // appTile Loader

        Image {
        id: screenshot

            anchors.fill: parent
            anchors.margins: vpx(2)
            // Fast corners: this Image only decodes; artFx below draws it.
            visible: !appTile.visible && !root.fastArt
            // HQ: dissolve in on load. Starts hidden and lifts on Ready with a
            // plain assignment, matching how restoreArt/fadeArt already drive
            // this property — no binding for them to break. OFF starts at 1.
            // The existing 200ms Behavior below animates the lift, so this
            // is a dissolve in HQ and (starting at 1) a no-op otherwise.
            opacity: hqFadeIn ? 0 : 1
            onStatusChanged: if (status === Image.Ready && hqFadeIn && !root.videoShowing) opacity = 1
            // Follows artGame (assigned), never gameData: see artGame above.
            source: artGame ? (
                      artMode === "Screenshot" ? (artGame.assets.screenshots[0] || artGame.assets.background || "")
                    : artMode === "Boxfront"   ? (artGame.assets.boxFront || artGame.assets.background || artGame.assets.screenshots[0] || "")
                    :                            (artGame.assets.background || artGame.assets.screenshots[0] || "")
                  ) : ""
            fillMode: Image.PreserveAspectCrop
            // Decode at the tile's own size (plus room for the focus pop), never
            // above the cap. A 240px grid tile no longer decodes 512/1024px.
            readonly property int decodePx: Math.max(96, Math.min(hqTileArtPx, Math.round(Math.max(root.width, root.height) * hqTileDecodeScale)))
            sourceSize { width: decodePx; height: decodePx }
            smooth: true
            asynchronous: true
            Behavior on opacity { enabled: !reduceMotion; NumberAnimation { duration: 200 } }
        }

        // Fast corners: the screenshot above, drawn with its corners rounded in
        // the same pass. Follows its opacity, so the HQ fade-in and the fade
        // under the video preview behave exactly as before.
        RoundedArt {
        id: artFx
            anchors.fill: screenshot
            source: screenshot
            crop: true
            radius: root.artRadius
            inset: 0
            opacity: screenshot.opacity
            // Only once the image is decoded: with no texture yet, GL samples
            // solid black, which would flash a black box while art loads.
            visible: !root.isImportedApp && !failed
                     && screenshot.status === Image.Ready
        }

        Image {
        id: favelogo

            // Nothing to draw until the logo is decoded (an Image with no
            // texture still costs a node per tile).
            visible: showLogo && !appTile.visible && status === Image.Ready
            anchors.fill: parent
            anchors.centerIn: parent
            anchors.margins: root.width/10
            function logoFor(g) {
                if (!g) return "";
                var sn = g.collections.count > 0 ? g.collections.get(0).shortName : "";
                if (sn === "retropie") return g.assets.boxFront;
                if (sn === "steam") return logo(g);
                return g.assets.logo;
            }
            // No decode at all when the logo isn't shown — an invisible Image
            // still loads its source, which was a wasted decode per tile.
            // Held back until the race ends (logoGame; the art may come sooner).
            source: (showLogo && logoGame) ? (logoFor(logoGame) || "") : ""
            sourceSize { width: 200; height: 150 }
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            scale: selected ? 1.1 : 1
            Behavior on scale { enabled: !reduceMotion; NumberAnimation { duration: 100 } }
            z: 10
        }

        Rectangle {
        id: overlay
        
            anchors.fill: parent
            color: screenshot.source == "" ? theme.secondary : "black"
            opacity: screenshot.source == "" ? 1 : selected ? 0.1 : 0.2
            radius: root.fastArt ? root.artRadius : 0
        }

        Rectangle {
        id: regborder

            anchors.fill: parent
            radius: root.fastArt ? root.artRadius : 0
            color: "transparent"
            border.width: vpx(1)
            border.color: "white"
            opacity: 0.1
        }
        
    }

    // Thin persistent accent border for favorited tiles — always visible
    // (not just on focus), so favorites stand out while scrolling past.
    Rectangle {
        id: favBorder
        anchors.fill: container
        radius: root.artRadius
        color: "transparent"
        border.width: vpx(2)
        border.color: theme.accent
        visible: gameData && gameData.favorite && settings.FavoritedTileAccent !== "No"
    }

    Loader {
    id: borderloader

        active: selected
        anchors.fill: parent
        sourceComponent: xboxBorder
        asynchronous: true
    }

    Component {
    id: xboxBorder

        // Wrapped: the Loader sizes its item to itself, which would undo the
        // frame's negative margins (it reaches past the tile on every side).
        Item {
            FocusFrame {
                anchors.fill: parent
                artRadius: root.artRadius
            }
        }
    }

    // (The old faint under-tile title, permanently hidden, is gone: replaced
    // long ago by the on-tile name bar, but every tile still built it.)

    // Title in the tile's centre when there's no logo to show. This text is
    // the single most expensive thing a tile can draw (outlined, wrapped,
    // elided), and a Text lays itself out whenever its text changes even
    // while invisible — so it only GETS text when it's about to be shown:
    // never while the grid races, and only once the logo is known to be
    // missing. Racing with logos on used to lay this out on every recycled
    // tile, which halved the frame rate.
    Text {
    id: platformname

        readonly property bool wanted: showLogo && !appTile.visible && !reduceMotion && artArmed
                                       && (favelogo.source == "" || favelogo.status === Image.Error)
        text: wanted && gameData ? gameData.title : ""
        anchors { fill: parent; margins: vpx(10) }
        color: "white"
        scale: selected ? 1.1 : 1
        Behavior on opacity { enabled: !reduceMotion; NumberAnimation { duration: 100 } }
        font.pixelSize: fpx(18)
        font.family: subtitleFont.name
        font.bold: true
        style: Text.Outline; styleColor: theme.main
        visible: wanted && text !== ""
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