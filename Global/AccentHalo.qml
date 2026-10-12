// XboxOSv2 – AccentHalo.qml
// The "Tile Halo" glow for accent-bordered highlights of ANY shape: wide
// rows, square tiles, menu items. Place it inside the highlight Rectangle:
//
//   AccentHalo { active: parent.current; targetRadius: parent.radius }
//
// Why not the focus_halo.png the grid tiles use: that image's glow and
// corner curve are drawn for one tile shape. Stretched onto a wide row the
// side glow gets several times thicker than the top; shrunk onto a small
// tile its corner curve (~7px at full size) ends up much tighter than the
// tile's own corners. RectangularGlow takes the corner radius directly, so
// the glow follows each highlight's real outline at an even thickness.
// It's a single shader with no source capture, so it's lighter than the
// image + ColorOverlay pair, and only the active one is ever drawn.

import QtQuick 2.15
import QtGraphicalEffects 1.15

RectangularGlow {
id: halo

    property bool active: false
    // Corner radius of the highlight this sits in.
    property real targetRadius: 0
    // Glow thickness: the grid tiles' proportion (14px of glow on a 228px
    // tile ≈ 6%) of the highlight's SHORT side, with a floor so slim rows
    // still read.
    property real thickness: Math.max(vpx(6), Math.min(parent.width, parent.height) * 0.0614)

    anchors.fill: parent
    z: -1                                   // behind the highlight
    glowRadius: thickness
    spread: 0.2
    // RectangularGlow measures cornerRadius at the OUTER edge of the glow,
    // so it's the highlight's radius plus the glow itself.
    cornerRadius: targetRadius + glowRadius
    color: theme.accent
    cached: true

    // Fades IN, but switches OFF instantly. The glow is a solid shape, not a
    // ring: while active, the highlight's opaque fill covers its middle. When
    // the highlight moves on, that fill goes transparent at once, so a glow
    // still fading out would show its whole body as a light-blue flash on
    // the row being left. Driven imperatively (not a Behavior) so the
    // instant-off can't depend on binding update order.
    readonly property bool shown: active && settings.TileHalo === "Yes"
    opacity: 0
    visible: opacity > 0
    NumberAnimation { id: fadeIn; target: halo; property: "opacity"; to: 0.95
                      duration: 180; easing.type: Easing.OutCubic }
    onShownChanged: {
        fadeIn.stop();
        if (shown) fadeIn.start(); else opacity = 0;
    }
    Component.onCompleted: opacity = shown ? 0.95 : 0
}
