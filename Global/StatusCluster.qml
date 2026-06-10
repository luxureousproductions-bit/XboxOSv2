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

        anchors {
            top: parent.top; topMargin: vpx(12)
            right: parent.right; rightMargin: vpx(25)
        }
        color: "white"
        font.pixelSize: vpx(22)
        font.family: subtitleFont.name
        horizontalAlignment: Text.Right
    }

    // Battery — Xbox-dashboard-style icon: outlined body + terminal cap,
    // proportional fill, and the charge bolt (charging) or percentage shown
    // INSIDE the body. Plain Rectangles only — shader-free.
    Item {
        id: batteryDisplay

        property bool batteryAvailable: !isNaN(api.device.batteryPercent) && api.device.batteryPercent >= 0
        property int  pct: batteryAvailable ? Math.round(api.device.batteryPercent * 100) : 0
        property bool charging: api.device.batteryCharging
        // Fill: green while charging, red when critically low, white otherwise
        property color fillColor: charging ? "#3DD13D" : (pct <= 20 ? "#EF5350" : "white")

        width: vpx(46)
        height: vpx(22)
        anchors {
            right: sysTime.left; rightMargin: vpx(10)
            verticalCenter: sysTime.verticalCenter
        }
        // Hide when no battery is present or setting is disabled
        visible: settings.ShowBattery !== "No" && batteryAvailable

        // Body outline
        Rectangle {
            id: batteryBody
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: parent.width - vpx(4)
            radius: vpx(4)
            color: "transparent"
            border.color: "white"
            border.width: vpx(2)

            // Charge-level fill
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: vpx(3) }
                width: Math.max(0, (batteryBody.width - vpx(6)) * (batteryDisplay.pct / 100))
                radius: vpx(2)
                color: batteryDisplay.fillColor
                opacity: 0.85
                Behavior on width { NumberAnimation { duration: 300 } }
            }

            // Inside label: bolt while charging, percentage otherwise.
            // Outlined so it stays readable over both fill and empty regions.
            Text {
                anchors.centerIn: parent
                text: batteryDisplay.charging ? "\u26A1" : batteryDisplay.pct
                color: "white"
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.75)
                font.pixelSize: vpx(12)
                font.family: subtitleFont.name
                font.bold: true
            }
        }

        // Positive terminal cap
        Rectangle {
            anchors {
                left: batteryBody.right; leftMargin: vpx(1)
                verticalCenter: parent.verticalCenter
            }
            width: vpx(3)
            height: parent.height * 0.45
            radius: vpx(1)
            color: "white"
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
            bottom: sysTime.baseline
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
