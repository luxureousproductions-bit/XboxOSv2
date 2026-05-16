// XboxOSv2 – RAStatusBar.qml
// Shared status bar: clock + battery + wifi indicator.
// All three are individually toggled by Settings → General.
// Clock respects the "Clock Format" setting (12hr / 24hr).

import QtQuick 2.15

Row {
    id: root

    spacing: vpx(14)

    // showWifi controls whether the wifi connectivity check runs at all.
    // Even when true, the indicator is hidden if the setting is "No".
    property bool showWifi: false
    property bool _online:  false

    // ── Wifi connectivity check ───────────────────────────────────────────
    Timer {
        id: wifiTimer
        interval:         30000
        repeat:           true
        running:          root.showWifi
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

    // ── Wifi indicator ────────────────────────────────────────────────────
    Canvas {
        id: wifiCanvas
        width:  vpx(26)
        height: vpx(20)
        visible: root.showWifi && (settings.ShowWifi !== "No")
        anchors.verticalCenter: parent.verticalCenter

        onPaint: {
            var ctx    = getContext("2d");
            ctx.reset();
            var cx     = width / 2;
            var cy     = height - vpx(1);
            var outerR = cy - vpx(2);
            var sa     = Math.PI * 1.25;
            var ea     = Math.PI * 1.75;
            var alpha  = root._online ? 0.9 : 0.3;
            ctx.strokeStyle = "white";
            ctx.lineCap     = "round";
            ctx.globalAlpha = alpha;
            ctx.lineWidth   = vpx(2);
            ctx.beginPath(); ctx.arc(cx, cy, outerR,        sa, ea, false); ctx.stroke();
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
        visible: settings.ShowBattery !== "No"
                 && !isNaN(api.device.batteryPercent)
                 && api.device.batteryPercent >= 0

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

    // ── Clock ─────────────────────────────────────────────────────────────
    Text {
        id: clockText

        visible: settings.ShowClock !== "No"
        anchors.verticalCenter: parent.verticalCenter
        color: theme.text
        font.family: subtitleFont.name
        font.pixelSize: vpx(22)
        font.bold: true

        // Direct binding — re-evaluates instantly whenever ClockFormat changes
        text: Qt.formatTime(new Date(), "h:mm AP")

        function refresh() {
            text = Qt.formatTime(new Date(), "h:mm AP");
        }
    }

    Timer {
        interval: 60000
        repeat:   true
        running:  true
        onTriggered: clockText.refresh()
    }
}
