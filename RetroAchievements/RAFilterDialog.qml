// XboxOSv2 – RAFilterDialog.qml
// The Filters pop-up on a game's achievements page, after the Xbox Series
// one: two columns of radio rows and an Apply button, over a dimmed page.
//
//   Left:  RA's achievement types   All / Progression / Win condition / Missable
//          (the console's Original / Add-on column)
//   Right: status and rarity        All / Locked / Unlocked / Rare / Common
//          (rare: under 10% of players have it)
//
// Picks stay pending until Apply; B (or a tap outside) closes without
// changing anything. Up/Down move in a column, Left/Right switch columns,
// Down from a column's last row reaches Apply.

import QtQuick 2.15

FocusScope {
id: dlg

    anchors.fill: parent
    visible: false
    z: 100

    readonly property var typeKeys:    ["all", "progression", "win_condition", "missable"]
    readonly property var typeNames:   ["All", "Progression", "Win condition", "Missable"]
    readonly property var statusKeys:  ["all", "locked", "earned", "rare", "common"]
    readonly property var statusNames: ["All", "Locked", "Unlocked", "Rare", "Common"]

    property string pendingType:   "all"
    property string pendingStatus: "all"
    property int col: 1                 // 0 types, 1 status, 2 Apply
    property int row: 0
    property int lastCol: 1             // the column Up from Apply returns to

    signal closed()

    readonly property color panelColor: whiteBackground ? "#f4f4f4" : "#2b2b2b"
    readonly property color applyColor: whiteBackground ? "#e2e2e2" : "#3a3a3a"

    function open() {
        pendingType   = cheevosData.typeFilter;
        pendingStatus = cheevosData.filterMode;
        col = 1; lastCol = 1;
        row = Math.max(0, statusKeys.indexOf(pendingStatus));
        visible = true;
        forceActiveFocus();
        playAccept();
    }
    function close(apply) {
        if (apply) { playAccept(); cheevosData.setFilters(pendingStatus, pendingType); }
        else playBack();
        visible = false;
        closed();
    }
    function rows(c) { return c === 0 ? typeKeys.length : statusKeys.length; }
    function pick(c, r) {
        if (c === 0) pendingType = typeKeys[r];
        else pendingStatus = statusKeys[r];
        playToggle();
    }
    // A, from the key or the help bar.
    function accept() {
        if (col === 2) close(true);
        else pick(col, row);
    }

    // ── Dim, closes on a tap outside the panel ───────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "black"; opacity: 0.55
        MouseArea { anchors.fill: parent; onClicked: dlg.close(false) }
    }

    Rectangle {
    id: panel
        anchors.centerIn: parent
        width: vpx(600)
        height: content.height + vpx(48)
        radius: vpx(4)
        color: dlg.panelColor
        MouseArea { anchors.fill: parent }     // taps on the panel don't close it

        Column {
        id: content
            x: vpx(28); y: vpx(22)
            width: parent.width - vpx(56)
            spacing: vpx(16)

            Text {
                text: "Filters"
                color: theme.text
                font.family: titleFont.name; font.pixelSize: fpx(20)
            }

            Row {
            id: cols
                width: parent.width
                spacing: vpx(20)
                Repeater {
                    model: 2
                    delegate: Column {
                    id: column
                        readonly property int c: index
                        width: (cols.width - cols.spacing) / 2
                        spacing: vpx(6)
                        Repeater {
                            model: column.c === 0 ? dlg.typeNames : dlg.statusNames
                            delegate: Item {
                                readonly property bool chosen: column.c === 0 ? dlg.typeKeys[index] === dlg.pendingType
                                                                                : dlg.statusKeys[index] === dlg.pendingStatus
                                readonly property bool hot: dlg.col === column.c && dlg.row === index && dlg.activeFocus
                                width: column.width; height: vpx(44)
                                RAFocus { on: parent.hot }
                                Text {
                                    anchors { left: parent.left; leftMargin: vpx(12); verticalCenter: parent.verticalCenter }
                                    text: modelData
                                    color: theme.text
                                    font.family: bodyFont.name; font.pixelSize: fpx(17)
                                }
                                // Radio
                                Rectangle {
                                    anchors { right: parent.right; rightMargin: vpx(14); verticalCenter: parent.verticalCenter }
                                    width: vpx(20); height: width; radius: width / 2
                                    color: "transparent"
                                    border.width: vpx(2); border.color: theme.text
                                    Rectangle {
                                        visible: parent.parent.chosen
                                        anchors.centerIn: parent
                                        width: vpx(10); height: width; radius: width / 2
                                        color: theme.text
                                    }
                                }
                                TapHandler { onTapped: { dlg.col = column.c; dlg.row = index; dlg.lastCol = column.c; dlg.pick(column.c, index); } }
                            }
                        }
                    }
                }
            }

            // Apply
            Rectangle {
            id: applyBtn
                readonly property bool hot: dlg.col === 2 && dlg.activeFocus
                anchors.horizontalCenter: parent.horizontalCenter
                width: vpx(210); height: vpx(42)
                radius: vpx(4)
                color: hot ? theme.accent : dlg.applyColor
                RAFocus { on: applyBtn.hot }
                Text {
                    anchors.centerIn: parent
                    text: "Apply"
                    color: applyBtn.hot ? "white" : theme.text
                    font.family: bodyFont.name; font.pixelSize: fpx(17)
                }
                TapHandler { onTapped: dlg.close(true) }
            }
        }
        // The divider between the columns.
        Rectangle {
            x: content.x + cols.x + (cols.width - cols.spacing) / 2 + cols.spacing / 2
            y: content.y + cols.y
            width: vpx(1); height: cols.height
            color: theme.text; opacity: 0.15
        }
    }

    // ── Keys: everything stays in the pop-up while it's open ─────────────
    Keys.onUpPressed: {
        event.accepted = true;
        if (col === 2) { col = lastCol; row = rows(col) - 1; playNav(); }
        else if (row > 0) { row--; playNav(); }
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (col === 2) return;
        if (row < rows(col) - 1) row++;
        else { lastCol = col; col = 2; }
        playNav();
    }
    Keys.onLeftPressed: {
        event.accepted = true;
        if (col === 1) { col = 0; lastCol = 0; row = Math.min(row, rows(0) - 1); playNav(); }
    }
    Keys.onRightPressed: {
        event.accepted = true;
        if (col === 0) { col = 1; lastCol = 1; row = Math.min(row, rows(1) - 1); playNav(); }
    }
    Keys.onPressed: {
        if (event.isAutoRepeat) { event.accepted = true; return; }
        if (api.keys.isCancel(event)) close(false);
        else if (api.keys.isAccept(event)) accept();
        event.accepted = true;
    }
}
