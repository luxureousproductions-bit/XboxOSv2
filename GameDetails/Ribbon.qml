// XboxOS-V2
// Bookmark ribbon (a tab with a notched end), used by the manual reader on
// bookmarked pages and their thumbnails. Set the width; the height follows.

import QtQuick 2.15

Canvas {
id: ribbon

    property color ribbonColor: theme.accent

    width: vpx(26)
    height: width * 1.7

    onRibbonColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = ribbonColor;
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.lineTo(width, 0);
        ctx.lineTo(width, height);
        ctx.lineTo(width / 2, height * 0.78);
        ctx.lineTo(0, height);
        ctx.closePath();
        ctx.fill();
    }
}
