// XboxOSv2 — Favorites carousel header.
//
// Sits as the ListView `header:` of whichever collection row is currently
// first-visible (see ShowcaseViewMenu's firstVisibleCollectionSlot), the same
// way the Showcase's hero box occupies index 0 of the system-tile row.
//
// Paging state (favIndex) is owned by the hosting HorizontalCollection so key
// handling never depends on reaching into ListView.headerItem. That row also
// auto-advances favIndex while the carousel isn't focused, which is what
// gives the unfocused "slideshow" behaviour.
//
// Content priority:
//   1. Favourited games        — art + logo, cycles automatically when unfocused
//   2. No favourites           — looping video previews (Discover-style)
//   3. No favourites, no video — slow static art slideshow
//
// NOTE: a horizontal ListView forces its header's HEIGHT to the view height,
// so the visible tile is drawn inside `frame`, pinned to the exact
// itemWidth/itemHeight the row's delegates use. Sizing the root alone does not
// work — that was making the box taller than every tile beside it.

import QtQuick 2.15
import QtMultimedia 5.15
import QtGraphicalEffects 1.15

Item {
id: root

    property var favoritesData          // ListFavorites instance (all favorites, uncapped)
    property bool selected: false       // true while the row's focus is on this header
    property int itemWidth: vpx(150)
    property int itemHeight: itemWidth * 1.5
    width: itemWidth
    height: itemHeight

    // Badge logo size, in multiples of the label text height.
    property real badgeLogoSize: 1.5

    readonly property int favCount: favoritesData ? favoritesData.games.count : 0
    // Driven by the hosting HorizontalCollection (single source of truth).
    property int favIndex: 0
    readonly property var currentFavorite: (favCount > 0 && favIndex < favCount)
                                            ? favoritesData.currentGame(favIndex) : null

    // Unified "what Accept should act on" — the shown favourite, or (in a
    // fallback mode) whichever game is currently on screen.
    readonly property var currentGame: (boxMode === "favorites") ? currentFavorite : fallbackGame

    // ── Which content the box is showing ──
    // Settings > Pins > "Pin Box Content" selects what the box shows. Pins
    // still degrades gracefully when none are set: videos, else art slideshow.
    readonly property string boxMode: {
        var m = settings.PinBoxContent;
        if (m === "Fanart Slideshow") return "art";
        if (m === "Discover Videos")  return useVideoFallback ? "video" : "art";
        if (favCount > 0)             return "favorites";       // Favorites mode
        return useVideoFallback ? "video" : "art";
    }

    // ── Art resolution — same mode preference as the hero box ──
    function favArtSource(g) {
        if (!g) return "";
        var fan  = g.assets.background || "";
        var shot = (g.assets.screenshots && g.assets.screenshots.length) ? g.assets.screenshots[0] : "";
        var box  = g.assets.boxFront || "";
        var mode = settings.HeroBoxArt;
        if (mode === "Boxfront")   return box  || fan  || shot || "";
        if (mode === "Screenshot") return shot || fan  || box  || "";
        return fan || shot || box || "";   // Fanart (default)
    }

    // ── Fallback content ──
    property var fallbackList: []       // games with a video asset
    property var artList: []            // games with any usable art
    property int fallbackIndex: 0
    property int artIndex: 0
    property bool videosScanned: false
    readonly property bool useVideoFallback: fallbackList.length > 0
    property var fallbackGame: (boxMode === "video")
        ? ((fallbackIndex < fallbackList.length) ? fallbackList[fallbackIndex] : null)
        : ((artIndex < artList.length) ? artList[artIndex] : null)

    function buildVideoList() {
        var all = api.allGames.toVarArray();
        var withVideos = [];
        for (var i = 0; i < all.length; i++) {
            if (all[i].assets.video) withVideos.push(all[i]);
        }
        fallbackList = withVideos;
        videosScanned = true;
        // Randomize the opening item here rather than at the call sites — the
        // lazy build path used to skip this and always start at index 0.
        if (withVideos.length > 0)
            fallbackIndex = Math.floor(Math.random() * withVideos.length);
        else
            buildArtList();             // nothing to play; fall through to art
    }
    function buildArtList() {
        if (artList.length > 0) return;
        var all = api.allGames.toVarArray();
        var withArt = [];
        for (var j = 0; j < all.length; j++) {
            if (favArtSource(all[j]) !== "") withArt.push(all[j]);
        }
        artList = withArt;
        if (withArt.length > 0)
            artIndex = Math.floor(Math.random() * withArt.length);
    }
    // Builds whichever list the current mode actually needs, once.
    function ensureFallbacks() {
        var m = settings.PinBoxContent;
        if (m === "Fanart Slideshow") { buildArtList(); return; }
        if (m === "Discover Videos")  { if (!videosScanned) buildVideoList(); return; }
        if (favCount === 0 && !videosScanned) buildVideoList();   // Favorites w/ none set
    }

    // boxMode re-evaluates whenever the setting or favourite count changes, so
    // watching it covers every path that could need a different list built.
    // (settings is a plain JS object, not a QObject — a Connections on it
    // would never fire.) The builders are self-guarding, so this can't loop.
    onFavCountChanged: ensureFallbacks()
    onBoxModeChanged: ensureFallbacks()
    Component.onCompleted: ensureFallbacks()

    function fallbackJump() {
        if (fallbackList.length < 2) return;
        var newIndex;
        do {
            newIndex = Math.floor(Math.random() * fallbackList.length);
        } while (newIndex === fallbackIndex);
        fallbackIndex = newIndex;
    }
    function artJump() {
        if (artList.length < 2) return;
        var newIndex;
        do {
            newIndex = Math.floor(Math.random() * artList.length);
        } while (newIndex === artIndex);
        artIndex = newIndex;
    }

    // Advances the static-art slideshow.
    Timer {
        interval: 8000
        repeat: true
        running: boxMode === "art" && artList.length > 1
        onTriggered: artJump()
    }

    // ── Visible tile — pinned to the row's real tile size (see header note) ──
    Item {
    id: frame

        width: root.itemWidth
        height: root.itemHeight
        anchors.top: parent.top

        // The row's tiles rest at 0.95 and grow to 1.0 on focus
        // (DynamicGridItem). Match it or the carousel reads as oversized
        // next to every tile beside it, at every size/ratio.
        scale: selected ? 1 : 0.95
        Behavior on scale { NumberAnimation { duration: 100 } }

        // Focus halo — identical asset and per-dimension sizing to the tiles so
        // it matches on any aspect. Lives OUTSIDE the masked tile below, or the
        // rounded-corner mask would clip the glow away.
        Image {
            id: favHaloSrc
            anchors.centerIn: tile
            width:  tile.width  * 1.1228
            height: tile.height * 1.1228
            source: "../assets/images/focus_halo.png"
            smooth: true
            mipmap: false
            visible: false
        }
        ColorOverlay {
            anchors.fill: favHaloSrc
            source: favHaloSrc
            color: theme.accent
            z: -1
            opacity: (selected && settings.TileHalo === "Yes") ? 0.95 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        Item {
        id: tile

            anchors.fill: parent

            // Round the tile art to match the selection frame so crop-filled
            // art AND video never poke past the corners — same approach the
            // grid/collection tiles use.
            layer.enabled: true
            layer.smooth: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: tile.width
                    height: tile.height
                    radius: vpx(12)
                }
            }

            Rectangle {
                anchors.fill: parent
                color: theme.main
            }

            // Static art — favourites, or the no-video art slideshow
            Image {
                id: favBg
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true; smooth: true
                visible: boxMode !== "video"
                source: (boxMode === "favorites") ? favArtSource(currentFavorite)
                                                  : favArtSource(fallbackGame)
                opacity: selected ? 1 : 0.5
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // No-favourites fallback: looping muted video preview
            Video {
            id: fallbackVideo

                anchors.fill: parent
                visible: boxMode === "video"
                source: (boxMode === "video" && fallbackGame) ? fallbackGame.assets.video : ""
                fillMode: VideoOutput.PreserveAspectCrop
                muted: true              // ambient background element — never plays audio
                autoPlay: true
                opacity: selected ? 1 : 0.5
                onSourceChanged: play()
                onStatusChanged: { if (status === MediaPlayer.EndOfMedia) fallbackJump(); }
            }

            // Darkening wash so the logo/title stay legible over bright art.
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: selected ? 0.1 : 0.25
            }

            // Game logo. Pins and the fanart slideshow both sit bottom-CENTER;
            // Discover keeps its bottom-RIGHT marker. Unused anchors are set
            // to undefined so the two layouts don't fight each other.
            Image {
                id: favCornerLogo

                // Tall tiles are narrow, so a width-based logo comes out tiny
                // there — widen the fraction for Tall specifically.
                readonly property bool isTall: frame.height > frame.width
                readonly property bool bottomRight: boxMode === "video"

                anchors {
                    right: bottomRight ? parent.right : undefined
                    rightMargin: vpx(8)
                    horizontalCenter: bottomRight ? undefined : parent.horizontalCenter
                    bottom: parent.bottom; bottomMargin: vpx(8)
                }
                width:  frame.width * (bottomRight ? (isTall ? 0.52 : 0.38)
                                                   : (isTall ? 0.70 : 0.50))
                height: frame.height * (bottomRight ? 0.26 : 0.30)
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: bottomRight ? Image.AlignRight : Image.AlignHCenter
                verticalAlignment: Image.AlignBottom
                asynchronous: true; smooth: true
                source: (currentGame && currentGame.assets.logo) ? currentGame.assets.logo : ""
                visible: source != ""
                opacity: selected ? 1 : 0.9
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // Top-left badge — Xbox dashboard "Game Pass" tile styling.
            // Reads "Pinned" while showing favourites, "Discover" for the
            // video / fanart fallback states.
            Rectangle {
            id: favBadge

                anchors {
                    left: parent.left; leftMargin: vpx(14)
                    top: parent.top;   topMargin: vpx(13)
                }
                width: badgeRow.width + vpx(20)
                height: badgeRow.height + vpx(10)
                radius: vpx(6)                 // softly rounded, per the Xbox dashboard
                color: "#B3000000"

                Row {
                id: badgeRow

                    anchors.centerIn: parent
                    spacing: vpx(6)

                    // Xbox-logo2.png is a 712x165 canvas whose sphere sits in
                    // the leftmost ~165px — the rest is empty transparency.
                    // Crop the source to just that square so the sphere fills
                    // the badge properly instead of rendering as a speck (or
                    // vanishing entirely when the empty middle got clipped).
                    Image {
                        source: "../assets/images/Xbox-logo2.png"
                        sourceClipRect: Qt.rect(0, 0, 165, 165)
                        height: badgeText.font.pixelSize * root.badgeLogoSize
                        width: height
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true; smooth: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        id: badgeText
                        text: (boxMode === "favorites") ? "PINS"
                            : (boxMode === "art")         ? "GAME PASS"
                            :                               "DISCOVER"
                        color: "white"
                        font.family: subtitleFont.name
                        font.pixelSize: Math.max(vpx(13), Math.min(tile.width, tile.height) * 0.062)
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Page dots — centered, one per favourite, matching the original
            // XboxOS favorites banner. Hidden when there's nothing to page.
            Row {
            id: favDots

                visible: boxMode === "favorites" && favCount > 1
                anchors.horizontalCenter: parent.horizontalCenter
                anchors { bottom: parent.bottom; bottomMargin: vpx(10) }
                spacing: vpx(6)
                Repeater {
                    model: favCount
                    Rectangle {
                        width: vpx(6); height: width
                        radius: width / 2
                        color: (favIndex === index && selected) ? theme.accent : theme.text
                        opacity: (favIndex === index) ? 1 : 0.5
                    }
                }
            }
        }

        // Selection frame — same ItemBorder the tiles use. Outside the masked
        // tile so the border stays crisp.
        Loader {
            anchors.fill: tile
            active: selected
            sourceComponent: favBorderComponent
            asynchronous: true
        }
        Component {
        id: favBorderComponent

            ItemBorder { }
        }
    }
}
