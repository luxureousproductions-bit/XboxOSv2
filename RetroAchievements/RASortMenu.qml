// XboxOSv2 – RASortMenu.qml
// The sort drop-down under a sort box (Gaming tab, a game's Progress page):
// the orders as rows, the current one marked with an accent bar, the
// highlighted one with the focus frame. The host moves `index` with its own
// keys and calls picked on A; a tap picks directly.

import QtQuick 2.15

Rectangle {
id: menu

    property var names: []
    property int current: 0         // the sort in use
    property int index: 0           // the highlighted row
    property bool hasFocus: true
    signal picked(int i)

    visible: false
    z: 20
    height: col.height + vpx(12)
    radius: vpx(4)
    color: whiteBackground ? "#f4f4f4" : "#2b2b2b"
    border.width: vpx(1); border.color: Qt.rgba(0.5, 0.5, 0.5, 0.35)

    Column {
    id: col
        x: vpx(6); y: vpx(6)
        width: parent.width - vpx(12)
        Repeater {
            model: menu.names
            delegate: Item {
                width: col.width; height: vpx(42)
                RAFocus { on: index === menu.index && menu.hasFocus }
                Rectangle {
                    visible: index === menu.current
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    width: vpx(4); height: vpx(20); radius: vpx(2); color: theme.accent
                }
                Text {
                    anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                    text: modelData
                    color: theme.text; font.family: bodyFont.name; font.pixelSize: fpx(16)
                }
                TapHandler { onTapped: { menu.index = index; menu.picked(index); } }
            }
        }
    }
}
