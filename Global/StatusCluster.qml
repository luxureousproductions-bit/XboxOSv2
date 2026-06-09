import QtQuick 2.15

// Reusable status cluster: clock + battery% + wifi, identical to the Showcase
// header and driven by the SAME settings (ShowClock / ShowBattery / ShowWifi),
// so toggling those in Settings affects every page that shows this cluster.
//
// Drop into any screen and anchor it to fill that screen, e.g.:
//     StatusCluster { anchors.fill: parent; z: 50 }
// The three indicators pin themselves to this item's top-right.
Item {
    id: statusCluster

    // Clock — top-right
    Text {
        id: sysTime

        visible: settings.ShowClock !== "No"
        text: Qt.formatTime(new Date(), "h:mm AP")

        function set() {
            sysTime.text = Qt.formatTime(new Date(), "h:mm AP");
        }

        Timer {
            interval: 60000
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: sysTime.set()
        }

        height: vpx(40)
        anchors {
            top: parent.top; topMargin: vpx(5)
            right: parent.right; rightMargin: vpx(25)
        }
        color: "white"
        font.pixelSize: vpx(18)
        font.family: subtitleFont.name
        horizontalAlignment: Text.Right
        verticalAlignment: Text.AlignVCenter
    }

    // Battery percentage display
    Row {
        id: batteryDisplay

        property bool batteryAvailable: !isNaN(api.device.batteryPercent) && api.device.batteryPercent >= 0

        spacing: vpx(4)
        anchors {
            right: sysTime.left; rightMargin: vpx(10)
            top: parent.top; topMargin: vpx(12)
        }
        // Hide when no battery is present or setting is disabled
        visible: settings.ShowBattery !== "No" && batteryAvailable

        // Lightning bolt shown while charging
        Text {
            text: "\u26A1"
            font.pixelSize: vpx(12)
            color: "#64B5F6"
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            visible: api.device.batteryCharging
        }

        Text {
            property int pct: batteryDisplay.batteryAvailable
                              ? Math.round(api.device.batteryPercent * 100) : 0
            text: pct + "%"
            // Turn red when critically low and not charging
            color: (pct <= 20 && !api.device.batteryCharging) ? "#EF5350" : "white"
            font.pixelSize: vpx(16)
            font.family: subtitleFont.name
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // WiFi signal indicator — three concentric arcs drawn via Canvas.
    // Connectivity is checked every 30 s with a HEAD request to 1.1.1.1;
    // arcs show full-brightness when reachable, dimmed when offline.
    Canvas {
        id: wifiIndicator

        width: vpx(26)
        height: vpx(20)
        visible: settings.ShowWifi !== "No"
        anchors {
            right: batteryDisplay.left; rightMargin: vpx(8)
            top: parent.top; topMargin: vpx(14)
        }

        property bool online: false

        Timer {
            id: wifiTimer
            interval: 30000
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: {
                var xhr = new XMLHttpRequest();
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        wifiIndicator.online = xhr.status >= 200 && xhr.status < 300;
                    }
                };
                xhr.onerror = function() { wifiIndicator.online = false; };
                xhr.open("HEAD", "https://1.1.1.1", true);
                xhr.timeout = 5000;
                xhr.send();
            }
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            var cx         = width / 2;
            var cy         = height - vpx(1);            // arcs radiate upward from here
            var outerR     = cy - vpx(2);                // largest radius fits within canvas
            var startAngle = Math.PI * 1.25;             // 225° — upper-left
            var endAngle   = Math.PI * 1.75;             // 315° — upper-right
            var alpha      = online ? 0.9 : 0.3;

            ctx.strokeStyle = "white";
            ctx.lineCap     = "round";
            ctx.globalAlpha = alpha;

            // Outer arc
            ctx.lineWidth = vpx(2);
            ctx.beginPath();
            ctx.arc(cx, cy, outerR, startAngle, endAngle, false);
            ctx.stroke();

            // Middle arc
            ctx.beginPath();
            ctx.arc(cx, cy, outerR * 0.64, startAngle, endAngle, false);
            ctx.stroke();

            // Inner arc
            ctx.beginPath();
            ctx.arc(cx, cy, outerR * 0.31, startAngle, endAngle, false);
            ctx.stroke();

            // Centre dot
            ctx.fillStyle = "white";
            ctx.beginPath();
            ctx.arc(cx, cy, vpx(2), 0, Math.PI * 2, false);
            ctx.fill();
        }

        onOnlineChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }
}
