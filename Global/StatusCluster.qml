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

        // Display style from the Advanced tab ("Show Battery Percentage"):
        // "Battery Only" (icon), "Percentage Only" (text like the original
        // layout), "Combined" (icon with the % inside). A legacy stored
        // "Yes" maps to Battery Only.
        property string mode: settings.ShowBattery === "Percentage Only" ? "Percentage Only"
                            : settings.ShowBattery === "Combined" ? "Combined" : "Battery Only"

        width: mode === "Percentage Only" ? pctRow.width : vpx(38)
        height: mode === "Percentage Only" ? pctRow.height : vpx(16)
        anchors {
            // Reflow: if the clock is disabled, slide into its position
            right: sysTime.visible ? sysTime.left : parent.right
            rightMargin: sysTime.visible ? vpx(14) : vpx(25)
            // Icon modes centre on the clock; Percentage Only top-aligns to
            // the clock (same font + size) so the digit bottoms share the
            // same line as the clock and wifi
            verticalCenter: mode === "Percentage Only" ? undefined : sysTime.verticalCenter
            top: mode === "Percentage Only" ? sysTime.top : undefined
        }
        // Hide when no battery is present or setting is disabled
        visible: settings.ShowBattery !== "No" && batteryAvailable

        // Body outline (icon modes only)
        Rectangle {
            id: batteryBody
            visible: batteryDisplay.mode !== "Percentage Only"
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: parent.width - vpx(4)
            radius: vpx(3)
            color: "transparent"
            border.color: "white"
            border.width: vpx(1.5)

            // Charge-level fill
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: vpx(2.5) }
                width: Math.max(0, (batteryBody.width - vpx(5)) * (batteryDisplay.pct / 100))
                radius: vpx(2)
                color: batteryDisplay.fillColor
                opacity: 0.85
                Behavior on width { NumberAnimation { duration: 300 } }
            }

            // Inside label — Combined mode only (hidden while charging; the
            // bolt takes its place). Outlined so it stays readable over both
            // fill and empty regions.
            Text {
                anchors.centerIn: parent
                visible: batteryDisplay.mode === "Combined" && !batteryDisplay.charging
                text: batteryDisplay.pct + "%"
                color: "white"
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.75)
                font.pixelSize: vpx(10)
                font.family: subtitleFont.name
                font.bold: true
            }

            // Charging bolt — drawn on a Canvas so it's ALWAYS white. (The
            // \u26A1 glyph renders as a fixed-color yellow emoji on Android
            // and ignores Text.color entirely.)
            Canvas {
                id: chargeBolt
                visible: batteryDisplay.charging
                anchors.centerIn: parent
                width: vpx(8)
                height: vpx(11)
                onVisibleChanged: requestPaint()
                Component.onCompleted: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    var w = width, h = height;
                    ctx.beginPath();
                    ctx.moveTo(w * 0.62, 0);
                    ctx.lineTo(w * 0.10, h * 0.58);
                    ctx.lineTo(w * 0.44, h * 0.58);
                    ctx.lineTo(w * 0.34, h);
                    ctx.lineTo(w * 0.92, h * 0.40);
                    ctx.lineTo(w * 0.52, h * 0.40);
                    ctx.closePath();
                    ctx.fillStyle = "white";
                    ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.6);
                    ctx.lineWidth = 1;
                    ctx.fill();
                    ctx.stroke();
                }
            }
        }

        // Positive terminal cap (icon modes only)
        Rectangle {
            visible: batteryDisplay.mode !== "Percentage Only"
            anchors {
                left: batteryBody.right; leftMargin: vpx(1)
                verticalCenter: parent.verticalCenter
            }
            width: vpx(3)
            height: parent.height * 0.45
            radius: vpx(1)
            color: "white"
        }

        // Percentage Only — plain text like the pre-icon layout, in the
        // clock's font and size so the digit bottoms line up with the clock
        // (and the wifi icon, which sits on the clock's baseline).
        Row {
            id: pctRow
            visible: batteryDisplay.mode === "Percentage Only"
            spacing: vpx(5)
            anchors { right: parent.right; top: parent.top }

            // White charging bolt (Canvas — the \u26A1 glyph is a fixed
            // yellow emoji on Android)
            Canvas {
                id: pctBolt
                visible: batteryDisplay.charging
                width: vpx(11)
                height: vpx(15)
                anchors.verticalCenter: parent.verticalCenter
                onVisibleChanged: requestPaint()
                Component.onCompleted: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    var w = width, h = height;
                    ctx.beginPath();
                    ctx.moveTo(w * 0.62, 0);
                    ctx.lineTo(w * 0.10, h * 0.58);
                    ctx.lineTo(w * 0.44, h * 0.58);
                    ctx.lineTo(w * 0.34, h);
                    ctx.lineTo(w * 0.92, h * 0.40);
                    ctx.lineTo(w * 0.52, h * 0.40);
                    ctx.closePath();
                    ctx.fillStyle = "white";
                    ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.6);
                    ctx.lineWidth = 1;
                    ctx.fill();
                    ctx.stroke();
                }
            }

            Text {
                text: batteryDisplay.pct + "%"
                // Turn red when critically low and not charging
                color: (batteryDisplay.pct <= 20 && !batteryDisplay.charging) ? "#EF5350" : "white"
                font.pixelSize: vpx(22)
                font.family: subtitleFont.name
            }
        }
    }

    // WiFi signal indicator — three concentric arcs drawn via Canvas.
    // Connectivity is checked every 30 s with a HEAD request to 1.1.1.1;
    // arcs show full-brightness when reachable, dimmed when offline.
    Canvas {
        id: wifiIndicator

        width: vpx(24)
        height: vpx(18)
        visible: settings.ShowWifi !== "No"
        anchors {
            // Reflow: chain to the nearest enabled neighbour on the right,
            // all the way to the screen edge if both are disabled
            right: batteryDisplay.visible ? batteryDisplay.left
                 : (sysTime.visible ? sysTime.left : parent.right)
            rightMargin: batteryDisplay.visible ? vpx(14)
                       : (sysTime.visible ? vpx(14) : vpx(25))
            bottom: sysTime.baseline
        }

        property bool online: false
        // Number of lit bars. Pegasus exposes no real wifi RSSI, so this is
        // all-or-nothing (connected = 4, offline = 0). To approximate strength
        // from ping latency later, set this to a 0-4 value in the Timer instead.
        property int bars: online ? 4 : 0

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

            var n   = 4;
            var gap = width * 0.10;
            var bw  = (width - gap * (n - 1)) / n;
            var litCount = bars;

            // Ascending signal bars, bottom-aligned. Lit bars bright, the rest dim.
            ctx.fillStyle = "white";
            for (var i = 0; i < n; i++) {
                var bh = height * (0.40 + i * 0.20);     // 0.40, 0.60, 0.80, 1.00
                var x  = i * (bw + gap);
                var y  = height - bh;
                ctx.globalAlpha = (i < litCount) ? 0.95 : 0.22;
                ctx.fillRect(x, y, bw, bh);
            }

            // No connection: dim bars (already drawn) + a slash through the icon
            if (!online) {
                ctx.lineCap = "round";
                // dark backing for contrast
                ctx.globalAlpha = 0.6;
                ctx.strokeStyle = Qt.rgba(0, 0, 0, 1);
                ctx.lineWidth = vpx(3.5);
                ctx.beginPath();
                ctx.moveTo(vpx(1), height - vpx(1));
                ctx.lineTo(width - vpx(1), vpx(1));
                ctx.stroke();
                // white slash on top
                ctx.globalAlpha = 0.95;
                ctx.strokeStyle = "white";
                ctx.lineWidth = vpx(1.6);
                ctx.beginPath();
                ctx.moveTo(vpx(1), height - vpx(1));
                ctx.lineTo(width - vpx(1), vpx(1));
                ctx.stroke();
            }
        }

        onBarsChanged: requestPaint()
        onOnlineChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }
}
