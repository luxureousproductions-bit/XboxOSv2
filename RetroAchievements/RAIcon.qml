// XboxOSv2 – RAIcon.qml
// A small white SVG icon (assets/images/fluent: Microsoft's Fluent UI System
// Icons, MIT: see THIRD_PARTY_NOTICES.md) in the page's text colour. Drawn as is
// on Dark (they're white); on Light, one ColorOverlay pass turns them dark,
// cached as a texture until the colour changes.

import QtQuick 2.15
import QtGraphicalEffects 1.15

Image {
    property real size: vpx(18)
    width: size; height: size
    // Decoded at twice its size (at least 32): bigger icons stay sharp.
    sourceSize: Qt.size(Math.max(hrpx(32), Math.ceil(size * 2)), Math.max(hrpx(32), Math.ceil(size * 2)))
    smooth: true
    layer.enabled: whiteBackground
    layer.effect: ColorOverlay { color: theme.text }
}
