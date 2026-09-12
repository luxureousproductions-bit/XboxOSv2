// Contrast-adaptive sharpen for full-screen video. High Quality Mode only.
//
// HOW IT WORKS
// For each pixel it samples a cross of five (centre plus the four neighbours)
// and measures how much local contrast the neighbourhood has. Flat regions —
// sky, a wall, noise — get almost no boost and are left alone; genuine edges
// get pushed away from the average of their neighbours. The result is then
// clamped to the neighbourhood's own min/max, so it cannot ring or halo past
// what was already there. That adaptive weighting is what keeps it from
// looking crunchy the way a blanket unsharp mask does.
//
// HOW IT'S WIRED
// The source is captured with a ShaderEffectSource and the sharpened result
// is drawn OVER it. hideSource is deliberately false: if the shader fails to
// compile on some GPU, a ShaderEffect draws nothing, and the untouched video
// underneath is what you see. Sharpening fails to plain video, never to black.
//
// Costs a second full-screen draw plus the shader. That's why it's gated to
// High Quality Mode, and only applied where there is exactly one video on
// screen. Do not put this on the row previews.
//
// SCOPE
// Safe for PreserveAspectFit sources. A PreserveAspectCrop VideoOutput crops on
// the GPU, and capturing it through an FBO is known to break that crop on this
// stack (see the note in ItemHighlight) — do not wrap one of those with this.

import QtQuick 2.15

Item {
    id: root

    // The video item to sharpen. Position this Item to cover it exactly.
    property Item source: null

    // 0 = off, 1 = maximum. 0.5 is a good default; above ~0.7 fine detail
    // starts to look etched on already-sharp material.
    property real amount: 0.5

    // Skipped entirely when there is nothing to sharpen.
    readonly property bool active: source !== null && amount > 0

    ShaderEffectSource {
        id: capture
        sourceItem: root.source
        // The original stays visible beneath; see header.
        hideSource: false
        live: true
        smooth: true
        visible: false
    }

    ShaderEffect {
        anchors.fill: parent
        visible: root.active

        property variant tex: capture
        property real amt: root.amount
        // One texel, in texture coordinates, for the neighbour taps.
        property size texel: Qt.size(1.0 / Math.max(1, root.width),
                                     1.0 / Math.max(1, root.height))

        fragmentShader: "
            uniform sampler2D tex;
            uniform lowp float qt_Opacity;
            uniform mediump float amt;
            uniform mediump vec2 texel;
            varying highp vec2 qt_TexCoord0;

            void main() {
                mediump vec2 uv = qt_TexCoord0;
                mediump vec3 c = texture2D(tex, uv).rgb;
                mediump vec3 n = texture2D(tex, uv - vec2(0.0, texel.y)).rgb;
                mediump vec3 s = texture2D(tex, uv + vec2(0.0, texel.y)).rgb;
                mediump vec3 w = texture2D(tex, uv - vec2(texel.x, 0.0)).rgb;
                mediump vec3 e = texture2D(tex, uv + vec2(texel.x, 0.0)).rgb;

                // Neighbourhood range.
                mediump vec3 mn = min(min(min(n, s), min(w, e)), c);
                mediump vec3 mx = max(max(max(n, s), max(w, e)), c);

                // How much room there is to sharpen without clipping: small in
                // flat or already-saturated areas, large on clean edges.
                mediump vec3 room = clamp(min(mn, 1.0 - mx) / max(mx, vec3(0.001)),
                                          0.0, 1.0);
                room = sqrt(room);

                // Strength. Negative: neighbours are pushed away from centre.
                // amt scales between a gentle and a strong setting.
                mediump float peak = -1.0 / mix(8.0, 5.0, clamp(amt, 0.0, 1.0));
                mediump vec3 wgt = room * peak;

                // Weighted sum, normalised so overall brightness is unchanged.
                mediump vec3 result = ((n + s + w + e) * wgt + c) / (1.0 + 4.0 * wgt);

                // Never leave the neighbourhood's own range: no ringing.
                result = clamp(result, mn, mx);

                gl_FragColor = vec4(result, 1.0) * qt_Opacity;
            }
        "
    }
}
