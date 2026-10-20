// XboxOSv2 — disc picker
//
// Multi-disc games ask which disc to start BEFORE the launch splash. Pegasus'
// own question only comes once a theme calls game.launch(), which here happens
// at the end of the splash, so the theme asks first and then launches the
// chosen file itself (theme.qml launchDelay).
//
// Drawn like Pegasus' own dialog (dialogs/MultifileSelector.qml): grey title
// bar, darker list, lighter highlight, shade behind, grows in from half size.
// The disc played last starts highlighted, from each file's own lastPlayed.

import QtQuick 2.15

FocusScope {
id: discPicker

    // ── Host interface ────────────────────────────────────────────────────
    signal chosen(int index)
    signal closed()

    property var game: null
    property bool open: false
    property var discs: []          // [{ label }]
    property int lastIndex: -1

    readonly property int textSize: vpx(16)
    readonly property int titleTextSize: vpx(18)

    anchors.fill: parent
    visible: shade.opacity > 0
    focus: open

    // "Final Fantasy VII (USA) (Disc 2)" -> "Disc 2"; anything else keeps its name
    function discLabel(name, i) {
        var m = /(?:disc|disk|cd)\s*([0-9]+|[a-d])\b/i.exec(name);
        if (m) return "Disc " + m[1].toUpperCase();
        var side = /\bside\s*([ab])\b/i.exec(name);
        if (side) return "Side " + side[1].toUpperCase();
        return name !== "" ? name : "Disc " + (i + 1);
    }

    function openFor(g) {
        game = g;
        var out = [];
        var last = -1;
        var lastTime = 0;
        for (var i = 0; i < g.files.count; i++) {
            var f = g.files.get(i);
            out.push({ "label": discLabel(f.name, i) });
            var t = f.lastPlayed ? f.lastPlayed.getTime() : 0;
            if (!isNaN(t) && t > lastTime) { lastTime = t; last = i; }
        }
        discs = out;
        lastIndex = last;
        discList.currentIndex = last >= 0 ? last : 0;
        discList.positionViewAtIndex(discList.currentIndex, ListView.Center);
        open = true;
        forceActiveFocus();
    }

    function closePicker(byUser) {
        open = false;
        if (byUser) playBack();
        closed();
    }
    function choose(i) {
        if (i < 0 || i >= discs.length) return;
        playAccept();
        open = false;
        closed();
        chosen(i);
    }

    Keys.onPressed: {
        if (event.isAutoRepeat) return;
        if (api.keys.isAccept(event)) { event.accepted = true; choose(discList.currentIndex); return; }
        if (api.keys.isCancel(event)) { event.accepted = true; closePicker(true); return; }
        // the drawer key and anything else stays here while the picker is up
        event.accepted = true;
    }

    // shade, as Pegasus' Shade.qml: black at 0.8, tap to close
    Rectangle {
    id: shade
        anchors.fill: parent
        color: "#000"
        opacity: discPicker.open ? 0.8 : 0
        Behavior on opacity { NumberAnimation { duration: 125 } }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            enabled: discPicker.open
            onClicked: discPicker.closePicker(true)
        }
    }

    // swallow taps on the dialog itself
    MouseArea {
        anchors.centerIn: parent
        width: dialogBox.width
        height: dialogBox.height
        enabled: discPicker.open
    }

    Column {
    id: dialogBox

        width: parent.height * 0.66
        anchors.centerIn: parent
        opacity: shade.opacity / 0.8
        scale: discPicker.open ? 1 : 0.5
        Behavior on scale { NumberAnimation { duration: 125 } }

        // title bar
        Rectangle {
            width: parent.width
            height: titleText.height
            color: "#444"

            Text {
            id: titleText
                width: parent.width
                text: discPicker.game
                    ? "“" + discPicker.game.title + "” has multiple discs, which one would you like to play?"
                    : ""
                color: "#eee"
                font.pixelSize: discPicker.titleTextSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                padding: font.pixelSize
            }
        }

        // content area
        Rectangle {
            width: parent.width
            height: Math.min(discList.fullHeight, discPicker.height * 0.5)
            color: "#333"

            ListView {
            id: discList

                readonly property int itemHeight: discPicker.textSize * 3
                readonly property int fullHeight: count * itemHeight

                anchors.fill: parent
                clip: true
                focus: true
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: height * 0.5 - itemHeight * 0.5
                preferredHighlightEnd: height * 0.5 + itemHeight * 0.5
                onCurrentIndexChanged: if (discPicker.open) playNav()

                model: discPicker.discs
                delegate: Rectangle {
                    readonly property bool highlighted: ListView.isCurrentItem || mouseArea.containsMouse

                    width: dialogBox.width
                    height: discList.itemHeight
                    color: highlighted ? "#585858" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: "#eee"
                        font.pixelSize: discPicker.textSize
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: discPicker.textSize
                        anchors.verticalCenter: parent.verticalCenter
                        text: index === discPicker.lastIndex ? "last played" : ""
                        color: "#aaa"
                        font.pixelSize: discPicker.textSize * 0.85
                    }

                    MouseArea {
                    id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: discPicker.choose(index)
                    }
                }
            }
        }
    }
}
