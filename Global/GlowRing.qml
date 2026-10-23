// XboxOS-V2
// Soft glow around the Xbox-style selection frame (ItemBorder xboxStyle).
//
// Drawn in one pass from the frame's rounded shape, no images and nothing
// offscreen: full strength at the frame's outer edge, fading to nothing
// glowSize further out. Nothing is drawn inside the frame, so the see-through
// gap between the frame and the art stays clean, as on the Xbox.
//
// Size this item to the frame's outer bounds plus glowSize on every side.

import QtQuick 2.15

ShaderEffect {
id: fx

    property color glowColor: theme.accent
    // The frame's outer corner radius.
    property real frameRadius: vpx(10)
    // How far the glow reaches past the frame.
    property real glowSize: vpx(6)
    // Strength at the frame's edge (0-1).
    property real strength: 0.65

    property size itemSize: Qt.size(Math.max(1, width), Math.max(1, height))
    property real r: frameRadius
    property real g: Math.max(1, glowSize)
    property real k: strength

    // Same rule as RoundedArt: an error only counts with a log (Qt 5.15
    // reports Error with an empty log for batched effects that compiled).
    readonly property bool failed: status === ShaderEffect.Error && log.length > 0
    onFailedChanged: if (failed) console.warn("GlowRing shader failed:", log)

    fragmentShader: "
        uniform lowp float qt_Opacity;
        uniform lowp vec4 glowColor;
        uniform highp vec2 itemSize;
        uniform highp float r;
        uniform highp float g;
        uniform highp float k;
        varying highp vec2 qt_TexCoord0;

        void main() {
            // Signed distance to the frame's outer rounded edge (frame bounds =
            // this item shrunk by g on every side). Negative inside.
            highp vec2 hs = itemSize * 0.5;
            highp vec2 p = qt_TexCoord0 * itemSize - hs;
            highp vec2 q = abs(p) - (hs - vec2(g) - vec2(r));
            highp float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;

            // Outside only; eased falloff to zero at g.
            highp float t = clamp(1.0 - d / g, 0.0, 1.0);
            lowp float a = (d > 0.0) ? t * t * k : 0.0;
            gl_FragColor = vec4(glowColor.rgb, 1.0) * (glowColor.a * a * qt_Opacity);
        }
    "
}
