// XboxOSv2 – RAFilterDialog.qml
// The Filters pop-up on a game's achievements page, after the Xbox Series
// one: columns of radio rows and an Apply button, over a dimmed page.
//
//   Set:    All / Base set / Subsets / Unofficial     (the console's
//           Original / Add-on column: RA subsets are its add-ons; All is
//           the base set plus subsets, unofficial ones only show on their own)
//   Status: All / Locked / Unlocked / Rare / Common   (rare: under 10%)
//   Type:   All / Progression / Win condition / Missable
//
// Other pages give it their own columns (gamePage: false, open(picks)) and
// get the picks back through applied(); the Gaming tab does.
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

    readonly property var setKeys:     ["all", "base", "subsets", "unofficial"]
    readonly property var setNames:    ["All", "Base set", "Subsets", "Unofficial"]
    readonly property var statusKeys:  ["all", "locked", "earned", "rare", "common"]
    readonly property var statusNames: ["All", "Locked", "Unlocked", "Rare", "Common"]
    readonly property var typeKeys:    ["all", "progression", "win_condition", "missable"]
    readonly property var typeNames:   ["All", "Progression", "Win condition", "Missable"]
    property bool gamePage: true
    property var columns: [
        { title: "Set",    keys: setKeys,    names: setNames },
        { title: "Status", keys: statusKeys, names: statusNames },
        { title: "Type",   keys: typeKeys,   names: typeNames }
    ]
    readonly property int applyCol: columns.length   // the column index of Apply

    property var pending: ["all", "all", "all"]      // one key per column (game page: set, status, type)
    property int col: 1                 // the columns, then applyCol = Apply
    property int row: 0
    property int lastCol: 1             // the column Up from Apply returns to

    signal closed()
    signal applied(var picks)

    readonly property color panelColor: whiteBackground ? "#f4f4f4" : "#2b2b2b"
    readonly property color applyColor: whiteBackground ? "#e2e2e2" : "#3a3a3a"

    function open(picks) {
        pending = gamePage ? [cheevosData.setFilter, cheevosData.filterMode, cheevosData.typeFilter] : picks.slice();
        col = gamePage ? 1 : 0; lastCol = col;
        row = Math.max(0, columns[col].keys.indexOf(pending[col]));
        visible = true;
        forceActiveFocus();
        playAccept();
    }
    function close(apply) {
        if (apply) {
            playAccept();
            if (gamePage) cheevosData.setFilters(pending[1], pending[2], pending[0]);
            else applied(pending);
        }
        else playBack();
        visible = false;
        closed();
    }
    function rows(c) { return columns[c].keys.length; }
    function pick(c, r) {
        var p = pending.slice();
        p[c] = columns[c].keys[r];
        pending = p;
        playToggle();
    }
    // A, from the key or the help bar.
    function accept() {
        if (col === applyCol) close(true);
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
        width: vpx(Math.max(2, dlg.columns.length) * 287)
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
                    model: dlg.columns.length
                    delegate: Column {
                    id: column
                        readonly property int c: index
                        width: (cols.width - cols.spacing * (dlg.columns.length - 1)) / dlg.columns.length
                        spacing: vpx(6)
                        Text {
                            visible: text !== ""
                            leftPadding: vpx(12); bottomPadding: vpx(2)
                            text: dlg.columns[column.c].title || ""
                            color: theme.text; opacity: 0.6
                            font.family: titleFont.name; font.pixelSize: fpx(14)
                        }
                        Repeater {
                            model: dlg.columns[column.c].names
                            delegate: Item {
                                readonly property bool chosen: dlg.columns[column.c].keys[index] === dlg.pending[column.c]
                                readonly property bool hot: dlg.col === column.c && dlg.row === index && dlg.activeFocus
                                // Subsets is dim when this game has none.
                                readonly property bool empty: dlg.gamePage && column.c === 0 && index === 2 && cheevosData.subsetNames.length === 0
                                width: column.width; height: vpx(44)
                                RAFocus { on: parent.hot }
                                Text {
                                    anchors { left: parent.left; leftMargin: vpx(12); right: radio.left; rightMargin: vpx(8); verticalCenter: parent.verticalCenter }
                                    elide: Text.ElideRight
                                    text: modelData
                                    color: theme.text; opacity: parent.empty ? 0.45 : 1
                                    font.family: bodyFont.name; font.pixelSize: fpx(17)
                                }
                                Rectangle {
                                id: radio
                                    anchors { right: parent.right; rightMargin: vpx(14); verticalCenter: parent.verticalCenter }
                                    width: vpx(20); height: width; radius: width / 2
                                    color: "transparent"
                                    border.width: vpx(2); border.color: theme.text
                                    opacity: parent.empty ? 0.45 : 1
                                    Rectangle {
                                        visible: radio.parent.chosen
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
                readonly property bool hot: dlg.col === dlg.applyCol && dlg.activeFocus
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
        // Dividers between the columns.
        Repeater {
            model: dlg.columns.length - 1
            delegate: Rectangle {
                readonly property real colW: (cols.width - cols.spacing * (dlg.columns.length - 1)) / dlg.columns.length
                x: content.x + cols.x + (index + 1) * colW + index * cols.spacing + cols.spacing / 2
                y: content.y + cols.y
                width: vpx(1); height: cols.height
                color: theme.text; opacity: 0.15
            }
        }
    }

    // ── Keys: everything stays in the pop-up while it's open ─────────────
    Keys.onUpPressed: {
        event.accepted = true;
        if (col === applyCol) { col = lastCol; row = rows(col) - 1; playNav(); }
        else if (row > 0) { row--; playNav(); }
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (col === applyCol) return;
        if (row < rows(col) - 1) row++;
        else { lastCol = col; col = applyCol; }
        playNav();
    }
    Keys.onLeftPressed: {
        event.accepted = true;
        if (col > 0 && col < applyCol) { col--; lastCol = col; row = Math.min(row, rows(col) - 1); playNav(); }
    }
    Keys.onRightPressed: {
        event.accepted = true;
        if (col < applyCol - 1) { col++; lastCol = col; row = Math.min(row, rows(col) - 1); playNav(); }
    }
    Keys.onPressed: {
        if (event.isAutoRepeat) { event.accepted = true; return; }
        if (api.keys.isCancel(event)) close(false);
        else if (api.keys.isAccept(event)) accept();
        event.accepted = true;
    }
}
