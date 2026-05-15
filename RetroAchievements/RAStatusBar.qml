// XboxOSv2 – RAStatusBar.qml
// Shared status bar: clock + battery + (optional) wifi indicator.
// Drop this anywhere in an Item/FocusScope with a known right anchor.
// Usage:
//   RAStatusBar { anchors { right: parent.right; verticalCenter: parent.verticalCenter } }

import QtQuick 2.15

Row {
    id: root

    spacing: vpx(14)

    // ── Optional wifi dot (set showWifi: true to enable) ─────────────────
    property bool showWifi: false
    property bool _online:  false

    Timer {
        id: wifiTimer
        interval:        30000
        repeat:          true
        running:         root.showWifi
        triggeredOnStart: root.showWifi
        onTriggered: {
            var xhr = new XMLHttpRequest();
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE)
                    root._online = (xhr.status >= 200 && xhr.status < 300);
            };
            xhr.onerror = function() { root._online = false; };
            xhr.open("HEAD", "https://1.1.1.1", true);
            xhr.timeout = 5000;
            xhr.send();
        }
    }

    Canvas {
        id: wifiCanvas
        width:  vpx(26)
        height: vpx(20)
        visible: root.showWifi
        anchors.verticalCenter: parent.verticalCenter

        onPaint: {
            var ctx      = getContext("2d");
            ctx.reset();
            var cx    = width / 2;
            var cy    = height - vpx(1);
            var outerR = cy - vpx(2);
            var sa    = Math.PI * 1.25;
            var ea    = Math.PI * 1.75;
            var alpha = root._online ? 0.9 : 0.3;
            ctx.strokeStyle  = "white";
            ctx.lineCap      = "round";
            ctx.globalAlpha  = alpha;
            ctx.lineWidth    = vpx(2);
            ctx.beginPath(); ctx.arc(cx, cy, outerR,       sa, ea, false); ctx.stroke();
            ctx.beginPath(); ctx.arc(cx, cy, outerR * 0.64, sa, ea, false); ctx.stroke();
            ctx.beginPath(); ctx.arc(cx, cy, outerR * 0.31, sa, ea, false); ctx.stroke();
            ctx.fillStyle = "white";
            ctx.beginPath(); ctx.arc(cx, cy, vpx(2), 0, Math.PI * 2, false); ctx.fill();
        }
        onVisibleChanged: if (visible) requestPaint()
        Connections {
            target: root
            function on_OnlineChanged() { wifiCanvas.requestPaint() }
        }
    }

    // ── Battery ───────────────────────────────────────────────────────────
    Row {
        spacing: vpx(4)
        anchors.verticalCenter: parent.verticalCenter
        visible: !isNaN(api.device.batteryPercent) && api.device.batteryPercent >= 0

        Text {
            text: "⚡"
            font.pixelSize: vpx(12)
            color: "#64B5F6"
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            visible: api.device.batteryCharging
        }
        Text {
            property int pct: (!isNaN(api.device.batteryPercent) && api.device.batteryPercent >= 0)
                              ? Math.round(api.device.batteryPercent * 100) : 0
            text: pct + "%"
            color: (pct <= 20 && !api.device.batteryCharging) ? "#EF5350" : theme.text
            font.family: subtitleFont.name
            font.pixelSize: vpx(16)
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ── Clock (one timer, shared) ─────────────────────────────────────────
    Text {
        id: clockText
        function refresh() { clockText.text = Qt.formatTime(new Date(), "h:mm AP") }
        color: theme.text
        font.family: subtitleFont.name
        font.pixelSize: vpx(22)
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
        Component.onCompleted: refresh()
    }

    Timer {
        interval: 60000
        repeat:   true
        running:  true
        onTriggered: clockText.refresh()
    }
}
