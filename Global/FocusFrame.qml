// XboxOSv2 – Xbox-style focus frame, drawn in ONE shader pass.
//
// Place it over a tile with anchors.fill: the tile's art rectangle. It draws
// outward from that rectangle: a see-through gap, the accent ring, then a
// short soft glow — all from one distance calculation, so there are no
// layers, masks or blur passes, and nothing inside the art is touched (a
// video playing under the tile shows through untouched).
//
// Proportions follow the Xbox dashboard's focus visual: small art corner,
// thin gap, thin ring, tight glow. Corners stay concentric because the ring
// is an offset of the art's own rounded rectangle.
import QtQuick 2.15

ShaderEffect {
id: fx

    property real artRadius: vpx(6)
    property real gap: vpx(2)
    property real ring: vpx(2.5)
    property real glow: vpx(6)
    property color accent: theme.accent
    property real glowStrength: 0.55

    // The effect extends past the art by the whole frame on every side.
    readonly property real reach: gap + ring + glow + 1
    anchors.margins: -reach

    // Uniforms
    property size itemSize: Qt.size(Math.max(1, width), Math.max(1, height))
    property real m: reach
    property real r: artRadius
    property real g: gap
    property real rw: ring
    property real gw: Math.max(0.001, glow)
    property real gs: glowStrength
    property color col: accent

    readonly property bool failed: status === ShaderEffect.Error && log.length > 0
    onFailedChanged: if (failed) console.warn("FocusFrame shader failed:", log)

    fragmentShader: "
        uniform lowp float qt_Opacity;
        uniform highp vec2 itemSize;
        uniform highp float m;
        uniform highp float r;
        uniform highp float g;
        uniform highp float rw;
        uniform highp float gw;
        uniform lowp float gs;
        uniform lowp vec4 col;
        varying highp vec2 qt_TexCoord0;

        void main() {
            // Signed distance from the art's rounded rectangle (> 0 outside).
            highp vec2 p = qt_TexCoord0 * itemSize;
            highp vec2 artHalf = itemSize * 0.5 - vec2(m);
            highp vec2 q = abs(p - itemSize * 0.5) - (artHalf - vec2(r));
            highp float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;

            // Ring: from d = g to d = g + rw, one pixel of anti-aliasing.
            lowp float ringA = smoothstep(g - 0.5, g + 0.5, d)
                             * (1.0 - smoothstep(g + rw - 0.5, g + rw + 0.5, d));
            // Glow: fades out over gw past the ring.
            highp float t = clamp((d - (g + rw)) / gw, 0.0, 1.0);
            lowp float glowA = (d > g + rw) ? (1.0 - t) * (1.0 - t) * gs : 0.0;

            lowp float a = max(ringA, glowA);
            gl_FragColor = vec4(col.rgb, 1.0) * (a * col.a * qt_Opacity);
        }
    "
}
