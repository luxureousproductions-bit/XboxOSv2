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
    // The game's system (collection shortname), so the physical media art
    // (support / physicalmedia) can be named the way that system named it
    property string systemShortName: ""

    // Name of a system's game media; anything not listed is a "Cartridge"
    function physicalMediaLabel() {
        switch (systemShortName.toLowerCase()) {
            // CD / DVD / Blu-ray / GD-ROM
            case "psx": case "ps1": case "playstation": case "ps2": case "ps2_alt":
            case "ps3": case "ps4":
            case "segacd": case "megacd": case "megacdjp": case "saturn": case "saturnjp":
            case "dreamcast": case "naomigd": case "triforce":
            case "gc": case "gamecube": case "wii": case "wiiu":
            case "xbox": case "xbox360": case "xboxone":
            case "3do": case "pcfx": case "pcenginecd": case "tgcd": case "turbografxcd":
            case "neogeocd": case "neogeocdjp":
            case "cdimono1": case "cdi": case "cdtv": case "amigacd32":
            case "atarijaguarcd": case "fmtowns":
            case "windows": case "windows9x":
                return "Disc";
            case "laserdisc": case "daphne":
                return "LaserDisc";
            // Disk-based computers
            case "windows3x": case "pc": case "dos": case "pc88": case "pc98":
            case "amiga": case "amiga600": case "amiga1200": case "atarist":
            case "apple2": case "apple2gs": case "archimedes": case "macintosh":
            case "x1": case "fm7": case "to8": case "c64":
                return "Floppy Disk";
            // Tape-based computers
            case "zxspectrum": case "zx81": case "trs-80": case "bbcmicro": case "electron":
            case "amstradcpc": case "dragon32": case "plus4": case "moto": case "spectravideo":
                return "Cassette";
            case "psp":
                return "UMD";
            case "nds": case "3ds": case "n3ds": case "switch": case "psvita": case "vita":
            case "atarilynx": case "ngage":
                return "Game Card";
            case "pcengine": case "supergrafx":
                return "HuCard";
            case "tg16":
                return "TurboChip";
            case "fds":
                return "Disk Card";
            case "n64dd":
                return "Disk";
            case "channelf":
                return "Videocart";
            case "coco":
                return "Program Pak";
            case "adam":
                return "Data Pack";
            // Arcade: the game is the board itself
            case "arcade": case "mame": case "fba": case "fbneo":
            case "cps": case "cps1": case "cps2": case "cps3":
            case "model1": case "model2": case "model3": case "type-x":
                return "Arcade Board";
            // Digital-only and mixed collections: a neutral name
            case "android": case "androidapps": case "androidgames": case "steam": case "epic":
            case "desktop": case "emulators": case "ports": case "doom": case "scummvm":
            case "pico8": case "tic80": case "easyrpg": case "mugen": case "ags":
            case "cavestory": case "chailove": case "stratagus": case "flash": case "fpinball":
            case "palm": case "arduboy": case "zxnext": case "mess": case "consolearcade":
            case "pcarcade": case "gameandwatch": case "lcdgames":
            case "completed": case "custom-collections": case "final-fantasy":
                return "Physical Media";
            default:
                return "Cartridge";
        }
    }
    property bool selected
    property bool isVideo: mediaItem.includes(".mp4") || mediaItem.includes(".webm")
    // True once the highlighted video tile's player is playing. The film
    // placeholder stays up until then, so there's never a frame where the tile
    // is empty (the player is created asynchronously on highlight).
    readonly property bool videoShowing: selected && isVideo
                                         && videoPreviewLoader.item !== null
                                         && videoPreviewLoader.item.started === true
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

            // Hidden while the player spins up (a loaded-but-idle VideoOutput
            // paints black), shown the moment it reports PlayingState.
            // Deliberately NOT gated on position > 0: Android only reports
            // position about once a second, which held the video back ~1s.
            // Snaps rather than fades: a crossfade over the film glyph read as
            // a milky blue haze on the video.
            readonly property bool started: playbackState === MediaPlayer.PlayingState
            opacity: started ? 1 : 0
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
                    // Matched without regard to capitals (Box2dFront, BOXFRONT, ...)
                    var m = String(mediaItem).toLowerCase();
                    if (m.includes("background") || m.includes("fanart")) return "Fanart";
                    if (m.includes("titlescreen") || m.includes("screenshottitle")) return "Title Screen";
                    if (m.includes("box3d") || m.includes("box_3d") || m.includes("3dbox")) return "3D Box";
                    if (m.includes("box2dfront") || m.includes("box2d_front")) return "Box Art";
                    if (m.includes("boxfront") || m.includes("box_front")) return "Box Art";
                    if (m.includes("box2dback") || m.includes("box2d_back")) return "Back Box";
                    if (m.includes("boxback")  || m.includes("box_back"))  return "Back Box";
                    // ES-DE media folders (Pegasus X reads these). Matched as
                    // whole folders, so a game title containing "cover" or
                    // "logos" can't trigger them; backcovers before covers.
                    if (m.includes("/backcovers/")) return "Back Box";
                    if (m.includes("/covers/")) return "Box Art";
                    if (m.includes("/physicalmedia/")) return physicalMediaLabel();
                    if (m.includes("/marquees/") || m.includes("/marquee/") || m.includes("/logos/")) return "Logo";
                    if (m.includes("cartridge") || m.includes("support")) return physicalMediaLabel();
                    if (m.includes("miximage") || m.includes("mix_image") || m.includes("steamgrid") || m.includes("/steam/") || m.includes("/grid/")) return "Miximage";
                    if (m.includes("wheel")) return "Logo";
                    return "Screenshot";
                }
                // Always light: the pill is theme.secondary (fixed dark grey),
                // not the page background, so it never goes white.
                color: "#ebebeb"
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
        // HQ: dissolve in on load instead of snapping. Video tiles are exempt:
        // their source is empty, so status never reaches Ready — and the video
        // preview Loader is a CHILD of this Image, so it inherited the 0 and
        // the playing video was invisible.
        opacity: (hqFadeIn && !isVideo) ? (status === Image.Ready ? 1 : 0) : 1
        Behavior on opacity { enabled: hqFadeIn; NumberAnimation { duration: 180 } }

        // Only the selected tile is traced; unselected ones render plainly so
        // there is no per-tile effect cost across the whole row. A video tile
        // waits for its video: the trace follows the tile's alpha, and around
        // the thin film glyph it swelled into a solid blob. Once the video is
        // up the trace is a clean border on its rectangle, as before.
        layer.enabled: selected && (!isVideo || videoShowing)
        layer.effect: accentTraceEffect

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
            // No backing square: just the film glyph on a transparent tile.
            // Held (crisp, untraced) through the highlight until the video
            // starts, then swapped out in the same frame the video appears.
            visible: isVideo && !videoShowing
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
