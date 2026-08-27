// gameOS theme
// Copyright (C) 2018-2020 Seth Powell 
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

import QtQuick 2.15
import "../utils.js" as Utils
import QtGraphicalEffects 1.15


FocusScope {
id: root

    property var game: launchingGame ? launchingGame : currentGame
    focus: true

    // Background
    Image {
    id: screenshot

        anchors.fill: parent
        asynchronous: true
        property int randoScreenshotNumber: {
            if (game && settings.GameRandomBackground === "Yes")
                return Math.floor(Math.random() * game.assets.screenshotList.length);
            else
                return 0;
        }
        property int randoFanartNumber: {
            if (game && settings.GameRandomBackground === "Yes")
                return Math.floor(Math.random() * game.assets.backgroundList.length);
            else
                return 0;
        }

        property var randoScreenshot: game ? game.assets.screenshotList[randoScreenshotNumber] : ""
        property var randoFanart: game ? game.assets.backgroundList[randoFanartNumber] : ""
        property var actualBackground: (settings.GameBackground === "Screenshot") ? randoScreenshot : Utils.fanArt(game) || randoFanart;
        source: root.useAppFallback ? "" : (actualBackground || "")
        sourceSize: Qt.size(root.width, root.height)
        fillMode: Image.PreserveAspectCrop
        smooth: false
        Behavior on opacity { NumberAnimation { duration: 500 } }
    }

    // ── Fallback splash ───────────────────────────────────────────────────
    // Imported Android apps have no fanart or screenshots, so the splash was a
    // black screen. Falls back to the app's own icon: blurred and blown up as a
    // backdrop, crisp in the middle, with the title underneath.
    //
    // Scoped by file path rather than by collection: Pegasus gives imported
    // apps an "android:<package>" path, so this can't catch a ROM or a
    // hand-written entry even if they sit in the same collection.
    readonly property bool isImportedApp: {
        if (!game || !game.files || game.files.count < 1) return false;
        var p = game.files.get(0).path || "";
        return p.indexOf("android:") === 0;
    }
    readonly property string appIcon: {
        if (!game || !game.assets) return "";
        var a = game.assets;
        return a.boxFront || a.logo || a.poster || a.banner || "";
    }
    // Every imported app gets this treatment, not just the ones missing art, so
    // they read as one consistent group rather than a mix of styles. Still
    // requires an icon — without one there'd be nothing to show.
    readonly property bool useAppFallback:
        isImportedApp && appIcon !== ""

    Item {
    id: appFallback

        anchors.fill: parent
        visible: root.useAppFallback

        // Blurred backdrop. Decoded small on purpose — it's about to be blurred
        // beyond any detail, so a full-size decode would be wasted work.
        Image {
        id: fallbackSource

            anchors.fill: parent
            source: root.useAppFallback ? root.appIcon : ""
            sourceSize: Qt.size(192, 192)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }
        FastBlur {
            anchors.fill: parent
            source: fallbackSource
            // FastBlur's radius maxes out at 64. vpx(110) scales well past that,
            // which is why the backdrop rendered as nothing and the splash came
            // out black. The working blur in AllGamesMenu uses 64 flat.
            radius: 64
            cached: true
            visible: fallbackSource.status === Image.Ready
        }
        // Knocks the backdrop back so the icon and title stay legible.
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.5
        }

        Image {
        id: fallbackIcon

            anchors { horizontalCenter: parent.horizontalCenter
                      verticalCenter: parent.verticalCenter
                      verticalCenterOffset: -vpx(30) }
            width: vpx(190); height: vpx(190)
            source: root.useAppFallback ? root.appIcon : ""
            sourceSize: Qt.size(Math.round(vpx(190) * 2), Math.round(vpx(190) * 2))
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
        }

        Text {
            anchors { top: fallbackIcon.bottom; topMargin: vpx(26)
                      horizontalCenter: parent.horizontalCenter }
            width: parent.width * 0.7
            text: game ? game.title : ""
            color: "white"
            font.family: titleFont.name
            font.pixelSize: vpx(34)
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WordWrap
        }
    }

    // Scanlines
    Image {
    id: scanlines

        anchors.fill: parent
        source: "../assets/images/scanlines_v3.png"
        asynchronous: true
        opacity: 0.2
        visible: (settings.ShowScanlines == "Yes")
    }

    // Clear logo
    Image {
    id: logo

        width: vpx(500)
        height: vpx(500)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        sourceSize: Qt.size(parent.width, parent.height)
        source: game ? Utils.logo(game) : ""
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        visible: !root.useAppFallback
    }

    DropShadow {
    id: logoshadow

        anchors.fill: logo
        horizontalOffset: 0
        verticalOffset: 0
        radius: 8.0
        samples: 9
        color: "#000000"
        source: logo
        opacity: 1
        visible: !root.useAppFallback
    }

    // (Launch splash text removed — logo-only splash. Only B backs out, after a 1s delay.)

    // Helpbar buttons
    ListModel {
        id: launchGameHelpModel

        ListElement {
            name: "Back"
            button: "cancel"
        }
    }
    
    onFocusChanged: { if (focus) currentHelpbarModel = launchGameHelpModel; }

    // Input handling — ONLY the B / cancel button backs out, available the whole
    // time the splash is up. Every other key is swallowed so nothing else can
    // dismiss it.
    Keys.onPressed: {
        event.accepted = true;
        if (api.keys.isCancel(event) && !event.isAutoRepeat)
            previousScreen();
    }

    // Absorb touch/click so a tap can't dismiss the splash or fall through to
    // anything behind it — only B backs out.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onPressed: mouse.accepted = true
        onClicked: mouse.accepted = true
        onReleased: mouse.accepted = true
    }

    // "B  Back" hint, bottom-right, matching the global help bar's glyph + label.
    // Always visible while the splash is up (respects Hide Button Help).
    Row {
        id: backHint
        spacing: 10
        anchors {
            right: parent.right; rightMargin: globalMargin
            bottom: parent.bottom; bottomMargin: vpx(20)
        }
        visible: settings.HideButtonHelp === "No"

        Image {
            source: "../assets/images/controller/" + cancelGlyph() + ".png"
            width: vpx(30)
            height: vpx(30)
            asynchronous: true
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: "Back"
            font.family: subtitleFont.name
            font.pixelSize: fpx(16)
            color: theme.text
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Resolve the controller glyph filename for the cancel/B button, the same
    // way the help bar does (find the Gamepad mapping, use its hex key digit).
    function cancelGlyph() {
        var bm = api.keys.cancel;
        for (var i = 0; i < bm.length; i++) {
            if (bm[i].name().includes("Gamepad")) {
                var v = bm[i].key.toString(16);
                return v.substring(v.length - 1, v.length);
            }
        }
        return "";
    }
}