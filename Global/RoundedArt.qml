// XboxOS-V2
// Tile art with rounded corners, drawn WITHOUT an offscreen layer.
//
// The old way (layer.enabled + OpacityMask) renders the tile into its own
// texture, renders a rounded rectangle into a second one, then draws a third
// pass combining them. Two extra textures per tile, allocated again for every
// tile the grid creates while scrolling.
//
// This reads the Image's own texture directly and fades the corners in the
// same single draw the image needed anyway. Nothing offscreen, nothing extra
// to allocate.
//
// Usage: keep the Image (visible: false) as the decoder, point `source` at it,
// and put this where the Image was. Video is never routed through here.
//
// If the shader fails to compile on some GPU, status becomes Error; the tiles
// watch for that and fall back to the old mask, so the art never disappears.

import QtQuick 2.15

ShaderEffect {
id: fx

    // The Image to draw. Its texture is used as-is (no copy, no layer).
    property variant source
    // Corner radius, measured in the FRAME this art sits in.
    property real radius: vpx(12)
    // How far the art sits inside that frame on every side. The game tile's
    // art is inset 2px inside a frame rounded at 12px, so its corners follow
    // the frame's curve exactly, as the old mask did.
    property real inset: 0
    // true  = PreserveAspectCrop (the texture is cropped to this item's shape)
    // false = the texture fills this item exactly (PreserveAspectFit callers
    //         size this item to the painted area)
    property bool crop: false

    // Uniforms
    property size itemSize: Qt.size(Math.max(1, width), Math.max(1, height))
    property real r: radius
    property real ins: inset
    // Fraction of the texture visible on each axis.
    property size frac: {
        if (!crop || !source) return Qt.size(1, 1);
        var iw = Math.max(1, source.implicitWidth), ih = Math.max(1, source.implicitHeight);
        var w = Math.max(1, width), h = Math.max(1, height);
        var s = Math.max(w / iw, h / ih);
        return Qt.size(Math.min(1, w / (iw * s)), Math.min(1, h / (ih * s)));
    }

    onStatusChanged: if (status === ShaderEffect.Error) console.warn("RoundedArt shader:", log)

    fragmentShader: "
        uniform sampler2D source;
        uniform lowp float qt_Opacity;
        uniform highp vec2 itemSize;
        uniform highp float r;
        uniform highp float ins;
        uniform highp vec2 frac;
        varying highp vec2 qt_TexCoord0;

        void main() {
            highp vec2 uv = vec2(0.5) + (qt_TexCoord0 - vec2(0.5)) * frac;
            lowp vec4 c = texture2D(source, uv);

            // Distance to the frame's rounded edge, in pixels.
            highp vec2 frame = itemSize + vec2(2.0 * ins);
            highp vec2 p = qt_TexCoord0 * itemSize + vec2(ins);
            highp vec2 q = abs(p - frame * 0.5) - (frame * 0.5 - vec2(r));
            highp float d = length(max(q, vec2(0.0))) - r;

            // One pixel of anti-aliasing, like the mask's smooth edge.
            lowp float a = 1.0 - smoothstep(-0.5, 0.5, d);
            gl_FragColor = c * (a * qt_Opacity);
        }
    "
}
