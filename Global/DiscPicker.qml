// XboxOSv2 — disc picker
//
// Multi-disc games ask which disc to start BEFORE the launch splash. Pegasus'
// own question only comes once a theme calls game.launch(), which here happens
// at the end of the splash, so the theme asks first and then launches the
// chosen file itself (theme.qml launchDelay).
//
// The disc played last is highlighted, from each file's own lastPlayed.

import QtQuick 2.15

FocusScope {
id: discPicker

    // ── Host interface ────────────────────────────────────────────────────
    signal chosen(int index)
    signal closed()

    property var game: null
    property bool open: false
    property var discs: []          // [{ label, detail }]

    anchors.fill: parent
    visible: open
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
            var label = discLabel(f.name, i);
            out.push({ "label": label, "detail": label === f.name ? "" : f.name });
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
    property int lastIndex: -1

    function closePicker(byUser) {
        open = false;
        if (byUser) playBack();
        closed();
    }
    function choose() {
        var i = discList.currentIndex;
        if (i < 0 || i >= discs.length) return;
        playAccept();
        open = false;
        closed();
        chosen(i);
    }

    Keys.onPressed: {
        if (event.isAutoRepeat && !(event.key === Qt.Key_Up || event.key === Qt.Key_Down)) return;
        if (api.keys.isAccept(event)) { event.accepted = true; choose(); return; }
        if (api.keys.isCancel(event)) { event.accepted = true; closePicker(true); return; }
        // the drawer key and anything else stays here while the picker is up
        event.accepted = true;
    }

    // Full-bleed blocker so touches never reach the screen underneath.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: discPicker.closePicker(true)
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.78)
    }

    Rectangle {
    id: card

        anchors.centerIn: parent
        width: Math.min(parent.width * 0.5, vpx(620))
        height: header.height + discList.height + footer.height + vpx(24)
        color: "#1f1f1f"
        radius: vpx(6)

        // swallow taps on the card itself
        MouseArea { anchors.fill: parent }

        Column {
        id: header

            anchors { top: parent.top; left: parent.left; right: parent.right; margins: vpx(22) }
            spacing: vpx(4)
            Text {
                width: parent.width
                text: discPicker.game ? discPicker.game.title : ""
                color: "white"
                font.family: titleFont.name
                font.pixelSize: fpx(24)
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                bottomPadding: vpx(10)
                text: "Choose a disc"
                color: Qt.rgba(1, 1, 1, 0.6)
                font.family: bodyFont.name
                font.pixelSize: fpx(17)
            }
        }

        ListView {
        id: discList

            anchors { top: header.bottom; left: parent.left; right: parent.right; leftMargin: vpx(12); rightMargin: vpx(12) }
            height: Math.min(count, 5) * vpx(58)
            clip: true
            focus: true
            model: discPicker.discs
            keyNavigationWraps: true
            highlightMoveDuration: 100
            onCurrentIndexChanged: if (discPicker.open) playNav()

            delegate: Item {
                width: ListView.view.width
                height: vpx(58)
                readonly property bool selected: ListView.isCurrentItem

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: vpx(3)
                    radius: vpx(4)
                    color: parent.selected ? theme.accent : Qt.rgba(1, 1, 1, 0.06)
                }
                Text {
                    anchors { left: parent.left; leftMargin: vpx(20); verticalCenter: parent.verticalCenter;
                              verticalCenterOffset: modelData.detail !== "" ? -vpx(8) : 0 }
                    text: modelData.label
                    color: "white"
                    font.family: subtitleFont.name
                    font.pixelSize: fpx(20)
                }
                Text {
                    visible: modelData.detail !== ""
                    anchors { left: parent.left; leftMargin: vpx(20); right: lastTag.left; rightMargin: vpx(12)
                              verticalCenter: parent.verticalCenter; verticalCenterOffset: vpx(11) }
                    text: modelData.detail
                    color: Qt.rgba(1, 1, 1, 0.6)
                    font.family: bodyFont.name
                    font.pixelSize: fpx(13)
                    elide: Text.ElideMiddle
                }
                Text {
                id: lastTag
                    anchors { right: parent.right; rightMargin: vpx(20); verticalCenter: parent.verticalCenter }
                    text: index === discPicker.lastIndex ? "Last played" : ""
                    color: Qt.rgba(1, 1, 1, 0.75)
                    font.family: bodyFont.name
                    font.pixelSize: fpx(15)
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (discList.currentIndex === index) discPicker.choose();
                        else discList.currentIndex = index;
                    }
                }
            }
        }

        Text {
        id: footer

            anchors { top: discList.bottom; topMargin: vpx(10); right: parent.right; rightMargin: vpx(22) }
            height: implicitHeight + vpx(6)
            text: "A  Play      B  Back"
            color: Qt.rgba(1, 1, 1, 0.6)
            font.family: bodyFont.name
            font.pixelSize: fpx(15)
        }
    }
}
