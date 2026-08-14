// XboxOSv2 — VirtualKeyboard
//
// Shared on-screen keyboard, laid out to match the official Xbox virtual
// keyboard: a centre QWERTY grid flanked by two columns of command keys that
// span multiple rows, with controller badges drawn on the keys themselves.
//
//     [ #+= LT ] [ 1 2 3 4 5 6 7 8 9 0 ] [ DEL  X  ]
//     [  <  LB ] [ q w e r t y u i o p ] [  >  RB  ]
//     [        ] [ a s d f g h j k l ' ] [        ]
//     [  ^     ] [ z x c v b n m , . ? ] [  ->  ≡  ]
//     [        ] [       SPACE   Y     ] [        ]
//
// The HOST owns the string being edited — this component only reports edits
// back — so it can drop into places with different state models (a live
// filter, a search query, a settings field) without any of them changing how
// they store their text.
//
//   VirtualKeyboard {
//       title: "Filter Library"
//       text: root.nameFilter                 // current value in
//       showTextField: false                  // host already draws its own
//       masked: false                         // true = show bullets (API keys)
//       allowClipboard: false                 // true = show COPY / PASTE
//       onTextEdited:  root.nameFilter = newText
//       onAccepted:    root.applyFilter()
//       onCancelled:   root.closeKeyboard()
//   }
//
// Controls: A type · X delete · Y space · Menu accept · B close ·
//           LB/RB move the caret · LT change page.
// Focus: give this item focus; it handles all navigation internally.

import QtQuick 2.15

FocusScope {
id: root

    // ── Host interface ────────────────────────────────────────────────────
    property string title: ""
    property string text: ""
    property bool masked: false
    property bool allowClipboard: false
    // Hosts that already draw their own title + query box (the RA search
    // overlay does) should set this false so the field isn't drawn twice.
    property bool showTextField: true

    // On the real Xbox keyboard Y is the spacebar and Menu submits. Pegasus
    // exposes no Menu binding (only accept/cancel/details/filters/pages), so
    // the submit key has no shortcut by default — it's reached by navigating
    // to it. Set this true to put Y on submit instead, matching how the old
    // inline keyboards in this theme behaved. The badges follow the setting,
    // so a drawn badge always corresponds to a button that actually works.
    property bool submitOnY: false

    // Emitted on every character change; the host assigns this to its own
    // property. (Not a two-way binding, so a host can filter/transform.)
    signal textEdited(string newText)
    signal accepted()
    signal cancelled()

    // ── Sizing — proportions taken from the Xbox keyboard ─────────────────
    // Reference: 148px key pitch, 110px row pitch, 242px side columns.
    property real keyW: vpx(58)
    property real keyH: vpx(44)
    property real keyGap: vpx(5)
    readonly property real sideW: keyW * 1.6
    readonly property real gridW: (keyW * 10) + (keyGap * 9)
    readonly property real panelW: gridW + (keyGap * 2) + (sideW * 2)

    implicitWidth: panelW
    implicitHeight: layout.height

    // ── Caret ─────────────────────────────────────────────────────────────
    // Insertion point within `text`. LB / RB (and the < > keys) move it, so
    // characters land mid-string like the real Xbox keyboard rather than
    // always appending.
    property int caret: 0
    onTextChanged: if (caret > text.length) caret = text.length

    // ── Pages ─────────────────────────────────────────────────────────────
    // The LT key cycles letters -> symbols -> accents. Xbox itself only has
    // two pages; the accent page is kept from the previous keyboard so the
    // theme doesn't lose characters it already supported.
    property int page: 0        // 0 letters, 1 symbols, 2 accents
    property bool shifted: false

    readonly property var letterRows: [
        ["1","2","3","4","5","6","7","8","9","0"],
        ["q","w","e","r","t","y","u","i","o","p"],
        ["a","s","d","f","g","h","j","k","l","'"],
        ["z","x","c","v","b","n","m",",",".","?"]
    ]
    readonly property var symbolRows: [
        ["1","2","3","4","5","6","7","8","9","0"],
        ["!","@","#","$","%","^","&","*","(",")"],
        ["-","_","=","+","[","]","{","}","\\","|"],
        [";",":","\"","/","<",">","~","`","€","£"]
    ]
    readonly property var accentRows: [
        ["à","á","â","ã","ä","å","æ","ç","è","é"],
        ["ê","ë","ì","í","î","ï","ñ","ò","ó","ô"],
        ["õ","ö","ø","ù","ú","û","ü","ý","ÿ","ß"],
        ["œ","¢","£","¥","™","©","®","°","¡","¿"]
    ]
    readonly property var rows:
        (page === 1) ? symbolRows : (page === 2 ? accentRows : letterRows)

    // Label on the page key — shows what the NEXT press switches to, the way
    // Xbox flips between "#+=" and "ABC".
    readonly property string pageLabel:
        (page === 0) ? "#+=" : (page === 1 ? "áé" : "ABC")

    // ── Grid addressing ───────────────────────────────────────────────────
    // col -1 = left command column, 0..9 = centre grid, 10 = right column.
    // row 0..3 = character rows, 4 = spacebar, 5 = clipboard strip.
    readonly property bool hasClipRow: allowClipboard
    readonly property int clipRow: 5

    property int row: 1
    property int col: 0

    // The side columns hold three cells each; the middle and bottom ones span
    // two grid rows, so navigation collapses them to a single stop.
    function sideSlot(r) { return (r <= 0) ? 0 : (r <= 2 ? 1 : 2); }
    function slotRow(s)  { return (s === 0) ? 0 : (s === 1 ? 1 : 3); }

    function keyAt(r, c) {
        if (c === -1) {
            var sl = sideSlot(r);
            return (sl === 0) ? "CMD_PAGE" : (sl === 1 ? "CMD_LEFT" : "CMD_SHIFT");
        }
        if (c === 10) {
            var sr = sideSlot(r);
            return (sr === 0) ? "CMD_DEL" : (sr === 1 ? "CMD_RIGHT" : "CMD_ENTER");
        }
        if (r === clipRow) return (c === 0) ? "CMD_COPY" : "CMD_PASTE";
        if (r === 4)       return "CMD_SPACE";
        return rows[r][c];
    }

    // Highlight tests, one per region of the layout.
    function selCentre(r, c) { return row === r && col === c; }
    function selSpace()      { return row === 4 && col >= 0 && col <= 9; }
    function selSide(left, slot) {
        return col === (left ? -1 : 10) && sideSlot(row) === slot;
    }
    function selClip(c) { return row === clipRow && col === c; }

    // ── Editing ───────────────────────────────────────────────────────────
    function insert(str) {
        var t = root.text;
        textEdited(t.slice(0, caret) + str + t.slice(caret));
        caret += str.length;
    }
    function backspace() {
        if (caret <= 0) return;
        var t = root.text;
        textEdited(t.slice(0, caret - 1) + t.slice(caret));
        caret--;
    }
    function caretLeft()  { if (caret > 0) caret--; }
    function caretRight() { if (caret < root.text.length) caret++; }

    // Real system clipboard. A zero-size TextInput is the only way to reach
    // Android's clipboard from QML — an internal string would not let the user
    // paste an API key copied from a browser, which is the whole point here.
    TextInput {
        id: clipProxy
        width: 0; height: 0; opacity: 0
        activeFocusOnPress: false
    }
    function doCopy() {
        clipProxy.text = root.text;
        clipProxy.selectAll();
        clipProxy.copy();
        clipProxy.deselect();
    }
    function doPaste() {
        clipProxy.text = "";
        clipProxy.paste();
        if (clipProxy.text.length > 0) insert(clipProxy.text);
    }

    function press(k) {
        if (k === "CMD_PAGE")  { page = (page + 1) % 3; return; }
        if (k === "CMD_LEFT")  { caretLeft(); return; }
        if (k === "CMD_RIGHT") { caretRight(); return; }
        if (k === "CMD_SHIFT") { shifted = !shifted; return; }
        if (k === "CMD_DEL")   { backspace(); return; }
        if (k === "CMD_ENTER") { accepted(); return; }
        if (k === "CMD_SPACE") { insert(" "); return; }
        if (k === "CMD_COPY")  { doCopy(); return; }
        if (k === "CMD_PASTE") { doPaste(); return; }
        // Shift is a one-shot, the way on-screen keyboards normally behave.
        insert(shifted ? k.toUpperCase() : k);
        if (shifted) shifted = false;
    }

    // ── Styling ───────────────────────────────────────────────────────────
    readonly property color keyFill: Qt.rgba(1, 1, 1, 0.09)
    readonly property color keyFillSel: Qt.rgba(1, 1, 1, 0.18)
    readonly property color badgeGrey: Qt.rgba(1, 1, 1, 0.55)
    readonly property color badgeBlue: "#3D9BD5"
    readonly property color badgeAmber: "#E8A317"

    Column {
    id: layout

        anchors.horizontalCenter: parent.horizontalCenter
        spacing: vpx(10)

        // Title + current text. Hosts that draw their own set showTextField
        // false (and leave title empty) so nothing is duplicated.
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: vpx(6)
            visible: root.showTextField || root.title !== ""

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.title
                visible: root.title !== ""
                color: "white"
                font.family: titleFont.name
                font.pixelSize: fpx(22)
                font.bold: true
            }

            Rectangle {
            id: fieldBox

                width: root.panelW
                height: vpx(46)
                visible: root.showTextField
                radius: vpx(4)
                color: Qt.rgba(1, 1, 1, 0.10)
                border.width: vpx(2)
                border.color: theme.accent

                readonly property string shown:
                    root.masked ? "\u2022".repeat(root.text.length) : root.text

                Text {
                    anchors { left: parent.left; leftMargin: vpx(12); verticalCenter: parent.verticalCenter }
                    text: root.text === "" ? "Type to search..." : fieldBox.shown
                    color: root.text === "" ? Qt.rgba(1, 1, 1, 0.4) : "white"
                    font.family: subtitleFont.name
                    font.pixelSize: fpx(20)
                }
                // Caret sits at the insertion point, not the end of the string.
                // TextMetrics is not an Item, so it refers to fieldBox by id.
                TextMetrics {
                    id: caretMetrics
                    font.family: subtitleFont.name
                    font.pixelSize: fpx(20)
                    text: fieldBox.shown.slice(0, root.caret)
                }
                Rectangle {
                    width: vpx(2)
                    height: fieldBox.height * 0.55
                    color: theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                    x: vpx(12) + Math.min(fieldBox.width - vpx(24), caretMetrics.width)
                    visible: root.text !== ""
                }
            }
        }

        // ── Keyboard block ────────────────────────────────────────────────
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.keyGap

            // Left command column
            Column {
                spacing: root.keyGap

                // #+= page switch (LT)
                Rectangle {
                    width: root.sideW; height: root.keyH
                    radius: vpx(6)
                    color: root.selSide(true, 0) ? root.keyFillSel : root.keyFill
                    border.color: theme.accent
                    border.width: root.selSide(true, 0) ? vpx(3) : 0
                    Row {
                        anchors.centerIn: parent
                        spacing: vpx(7)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.pageLabel
                            color: "white"
                            font.family: subtitleFont.name
                            font.pixelSize: fpx(17)
                            font.bold: true
                        }
                        // LT trigger badge
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: vpx(21); height: vpx(16)
                            radius: vpx(5)
                            color: "transparent"
                            border.color: root.badgeGrey
                            border.width: vpx(1.5)
                            Text {
                                anchors.centerIn: parent
                                text: "LT"
                                color: root.badgeGrey
                                font.family: subtitleFont.name
                                font.pixelSize: fpx(9)
                                font.bold: true
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { root.col = -1; root.row = 0; root.press("CMD_PAGE"); }
                    }
                }

                // Caret left (LB) — spans the q and a rows
                Rectangle {
                    width: root.sideW; height: (root.keyH * 2) + root.keyGap
                    radius: vpx(6)
                    color: root.selSide(true, 1) ? root.keyFillSel : root.keyFill
                    border.color: theme.accent
                    border.width: root.selSide(true, 1) ? vpx(3) : 0
                    Column {
                        anchors.centerIn: parent
                        spacing: vpx(6)
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "\u2039"
                            color: "white"
                            font.family: subtitleFont.name
                            font.pixelSize: fpx(34)
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: vpx(24); height: vpx(15)
                            radius: vpx(7)
                            color: "transparent"
                            border.color: root.badgeGrey
                            border.width: vpx(1.5)
                            Text {
                                anchors.centerIn: parent
                                text: "LB"
                                color: root.badgeGrey
                                font.family: subtitleFont.name
                                font.pixelSize: fpx(9)
                                font.bold: true
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { root.col = -1; root.row = 1; root.press("CMD_LEFT"); }
                    }
                }

                // Shift — spans the z and space rows
                Rectangle {
                    width: root.sideW; height: (root.keyH * 2) + root.keyGap
                    radius: vpx(6)
                    color: root.selSide(true, 2) ? root.keyFillSel
                           : (root.shifted ? Qt.rgba(1, 1, 1, 0.26) : root.keyFill)
                    border.color: theme.accent
                    border.width: root.selSide(true, 2) ? vpx(3) : 0
                    Text {
                        anchors.centerIn: parent
                        text: "\u2191"
                        color: root.shifted ? theme.accent : "white"
                        font.family: subtitleFont.name
                        font.pixelSize: fpx(30)
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { root.col = -1; root.row = 3; root.press("CMD_SHIFT"); }
                    }
                }
            }

            // Centre grid
            Column {
                spacing: root.keyGap

                Repeater {
                    model: 4
                    Row {
                        property int rowIndex: index
                        spacing: root.keyGap
                        Repeater {
                            model: 10
                            Rectangle {
                                property string key: root.rows[rowIndex][index]
                                width: root.keyW; height: root.keyH
                                radius: vpx(6)
                                color: root.selCentre(rowIndex, index) ? root.keyFillSel : root.keyFill
                                border.color: theme.accent
                                border.width: root.selCentre(rowIndex, index) ? vpx(3) : 0
                                Text {
                                    anchors.centerIn: parent
                                    text: (root.shifted && rowIndex > 0) ? key.toUpperCase() : key
                                    color: "white"
                                    font.family: subtitleFont.name
                                    font.pixelSize: fpx(20)
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        root.row = rowIndex; root.col = index;
                                        root.press(key);
                                    }
                                }
                            }
                        }
                    }
                }

                // Spacebar
                Rectangle {
                    width: root.gridW; height: root.keyH
                    radius: vpx(6)
                    color: root.selSpace() ? root.keyFillSel : root.keyFill
                    border.color: theme.accent
                    border.width: root.selSpace() ? vpx(3) : 0
                    Row {
                        anchors.centerIn: parent
                        spacing: vpx(10)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\u2423"
                            color: "white"
                            font.family: subtitleFont.name
                            font.pixelSize: fpx(20)
                        }
                        // Y face-button badge
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !root.submitOnY
                            width: vpx(19); height: vpx(19)
                            radius: width / 2
                            color: "transparent"
                            border.color: root.badgeAmber
                            border.width: vpx(1.5)
                            Text {
                                anchors.centerIn: parent
                                text: "Y"
                                color: root.badgeAmber
                                font.family: subtitleFont.name
                                font.pixelSize: fpx(11)
                                font.bold: true
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { root.row = 4; root.col = 0; root.press("CMD_SPACE"); }
                    }
                }
            }

            // Right command column
            Column {
                spacing: root.keyGap

                // Backspace (X)
                Rectangle {
                    width: root.sideW; height: root.keyH
                    radius: vpx(6)
                    color: root.selSide(false, 0) ? root.keyFillSel : root.keyFill
                    border.color: theme.accent
                    border.width: root.selSide(false, 0) ? vpx(3) : 0
                    Row {
                        anchors.centerIn: parent
                        spacing: vpx(8)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\u232B"
                            color: "white"
                            font.family: subtitleFont.name
                            font.pixelSize: fpx(20)
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: vpx(19); height: vpx(19)
                            radius: width / 2
                            color: "transparent"
                            border.color: root.badgeBlue
                            border.width: vpx(1.5)
                            Text {
                                anchors.centerIn: parent
                                text: "X"
                                color: root.badgeBlue
                                font.family: subtitleFont.name
                                font.pixelSize: fpx(11)
                                font.bold: true
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { root.col = 10; root.row = 0; root.press("CMD_DEL"); }
                    }
                }

                // Caret right (RB)
                Rectangle {
                    width: root.sideW; height: (root.keyH * 2) + root.keyGap
                    radius: vpx(6)
                    color: root.selSide(false, 1) ? root.keyFillSel : root.keyFill
                    border.color: theme.accent
                    border.width: root.selSide(false, 1) ? vpx(3) : 0
                    Column {
                        anchors.centerIn: parent
                        spacing: vpx(6)
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "\u203A"
                            color: "white"
                            font.family: subtitleFont.name
                            font.pixelSize: fpx(34)
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: vpx(24); height: vpx(15)
                            radius: vpx(7)
                            color: "transparent"
                            border.color: root.badgeGrey
                            border.width: vpx(1.5)
                            Text {
                                anchors.centerIn: parent
                                text: "RB"
                                color: root.badgeGrey
                                font.family: subtitleFont.name
                                font.pixelSize: fpx(9)
                                font.bold: true
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { root.col = 10; root.row = 1; root.press("CMD_RIGHT"); }
                    }
                }

                // Submit (Menu)
                Rectangle {
                    width: root.sideW; height: (root.keyH * 2) + root.keyGap
                    radius: vpx(6)
                    color: root.selSide(false, 2) ? root.keyFillSel : root.keyFill
                    border.color: theme.accent
                    border.width: root.selSide(false, 2) ? vpx(3) : 0
                    Column {
                        anchors.centerIn: parent
                        spacing: vpx(6)
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "\u2192"
                            color: "white"
                            font.family: subtitleFont.name
                            font.pixelSize: fpx(28)
                        }
                        // The reference puts a Menu badge here, but Pegasus has
                        // no Menu binding — so a badge is only drawn when Y is
                        // actually mapped to submit.
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.submitOnY
                            width: vpx(19); height: vpx(19)
                            radius: width / 2
                            color: "transparent"
                            border.color: root.badgeAmber
                            border.width: vpx(1.5)
                            Text {
                                anchors.centerIn: parent
                                text: "Y"
                                color: root.badgeAmber
                                font.family: subtitleFont.name
                                font.pixelSize: fpx(11)
                                font.bold: true
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { root.col = 10; root.row = 3; root.press("CMD_ENTER"); }
                    }
                }
            }
        }

        // ── Clipboard strip ───────────────────────────────────────────────
        // Not part of the Xbox keyboard; added below the block only when the
        // host opts in, so the layout above stays faithful.
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.keyGap
            visible: root.hasClipRow

            Repeater {
                model: [ { t: "COPY", c: 0 }, { t: "PASTE", c: 1 } ]
                Rectangle {
                    width: (root.panelW - root.keyGap) / 2
                    height: vpx(34)
                    radius: vpx(6)
                    color: root.selClip(modelData.c) ? root.keyFillSel : root.keyFill
                    border.color: theme.accent
                    border.width: root.selClip(modelData.c) ? vpx(3) : 0
                    Text {
                        anchors.centerIn: parent
                        text: modelData.t
                        color: "white"
                        font.family: subtitleFont.name
                        font.pixelSize: fpx(15)
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.row = root.clipRow; root.col = modelData.c;
                            root.press(modelData.c === 0 ? "CMD_COPY" : "CMD_PASTE");
                        }
                    }
                }
            }
        }
    }

    // ── Navigation ────────────────────────────────────────────────────────
    // The side columns are single stops even though they span two rows, so
    // movement between regions is remapped rather than using raw indices.
    Keys.onUpPressed: {
        event.accepted = true;
        if (col === -1 || col === 10) {
            var s = sideSlot(row);
            if (s > 0) row = slotRow(s - 1);
            return;
        }
        if (row === clipRow) { row = 4; return; }
        if (row > 0) row--;
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (col === -1 || col === 10) {
            var s = sideSlot(row);
            if (s < 2) row = slotRow(s + 1);
            else if (hasClipRow) { row = clipRow; col = (col === 10) ? 1 : 0; }
            return;
        }
        if (row === clipRow) return;
        if (row < 4) { row++; return; }
        if (hasClipRow) { row = clipRow; col = Math.min(col, 1); }
    }
    Keys.onLeftPressed: {
        event.accepted = true;
        if (col === -1) return;
        if (row === clipRow) { if (col > 0) col--; return; }
        if (col === 10) { col = 9; return; }
        // The spacebar is one key, so left from anywhere on it exits the grid.
        if (row === 4 || col === 0) { col = -1; row = slotRow(sideSlot(row)); return; }
        col--;
    }
    Keys.onRightPressed: {
        event.accepted = true;
        if (col === 10) return;
        if (row === clipRow) { if (col < 1) col++; return; }
        if (col === -1) { col = 0; return; }
        if (row === 4 || col === 9) { col = 10; row = slotRow(sideSlot(row)); return; }
        col++;
    }

    Keys.onPressed: {
        if (event.isAutoRepeat) return;

        if (api.keys.isAccept(event)) {                  // A — press the key
            event.accepted = true;
            press(keyAt(row, col));
            return;
        }
        if (api.keys.isDetails(event)) {                 // X — backspace
            event.accepted = true;
            backspace();
            return;
        }
        if (api.keys.isFilters(event)) {                 // Y — space or submit
            event.accepted = true;
            if (submitOnY) accepted();
            else insert(" ");
            return;
        }
        if (api.keys.isPrevPage(event)) {                // LB — caret left
            event.accepted = true;
            caretLeft();
            return;
        }
        if (api.keys.isNextPage(event)) {                // RB — caret right
            event.accepted = true;
            caretRight();
            return;
        }
        if (api.keys.isCancel(event)) {                  // B — close
            event.accepted = true;
            cancelled();
            return;
        }

        // ── Triggers / Start / stick-click ───────────────────────────────
        // Pegasus only exposes eight key predicates (accept, cancel, details,
        // filters, prev/nextPage, page up/down) — there is nothing for Start
        // or the stick clicks. LT/RT normally arrive as page up/down, so those
        // are safe; Start and L3 have to be matched on raw key codes, which is
        // why they're listed below and easy to adjust if a pad differs.
        if (api.keys.isPageUp(event) || api.keys.isPageDown(event)) {   // LT / RT
            event.accepted = true;
            press("CMD_PAGE");                          // cycle ABC -> #+= -> áé
            return;
        }
        if (startKeys.indexOf(event.key) !== -1) {                      // Start
            event.accepted = true;
            accepted();
            return;
        }
        if (shiftKeys.indexOf(event.key) !== -1) {                      // L3
            event.accepted = true;
            shifted = !shifted;
            return;
        }
    }

    // Raw key codes, since api.keys has no predicate for these. Qt maps the
    // gamepad's Start to Return/Enter and the stick clicks into the gamepad
    // key range; extra codes are listed so a pad that reports differently
    // still works. Add to these arrays if a controller isn't picked up.
    readonly property var startKeys: [ Qt.Key_Return, Qt.Key_Enter, Qt.Key_Menu, 0x01000053 ]
    readonly property var shiftKeys: [ Qt.Key_Shift,  0x01000060, 0x01000061 ]
}
