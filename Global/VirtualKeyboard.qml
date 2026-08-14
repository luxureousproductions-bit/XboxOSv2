// XboxOSv2 — VirtualKeyboard
//
// Shared on-screen keyboard, styled after the Xbox virtual keyboard: QWERTY,
// bottom-centre of the screen, with page switches for symbols and accented
// characters.
//
// The HOST owns the string being edited — this component only reports edits
// back — so it can drop into places with different state models (a live
// filter, a search query, a settings field) without any of them changing how
// they store their text.
//
//   VirtualKeyboard {
//       title: "Filter Library"
//       text: root.nameFilter                 // current value in
//       masked: false                         // true = show bullets (API keys)
//       allowClipboard: false                 // true = show COPY / PASTE
//       onTextEdited:  root.nameFilter = newText
//       onAccepted:    root.applyFilter()
//       onCancelled:   root.closeKeyboard()
//   }
//
// Controls: A type · X delete · Y accept · B close · LB/RB switch page.
// Focus: give this item focus; it handles all navigation internally.

import QtQuick 2.15

FocusScope {
id: root

    // ── Host interface ────────────────────────────────────────────────────
    property string title: ""
    property string text: ""
    property bool masked: false
    property bool allowClipboard: false

    // Emitted on every character change; the host assigns this to its own
    // property. (Not a two-way binding, so a host can filter/transform.)
    signal textEdited(string newText)
    signal accepted()
    signal cancelled()

    // ── Sizing — roughly matches the Xbox keyboard's proportions ──────────
    property real keyW: vpx(58)
    property real keyH: vpx(48)
    property real keyGap: vpx(6)

    implicitWidth: grid.width
    implicitHeight: grid.height

    // ── Clipboard (host opts in) ─────────────────────────────────────────
    property string clipboard: ""

    // ── Pages ─────────────────────────────────────────────────────────────
    // Row 4 differs per page but always ends with the same command cluster so
    // muscle memory holds when switching.
    property int page: 0        // 0 letters, 1 symbols, 2 accents
    property bool shifted: false

    readonly property var letterRows: [
        ["1","2","3","4","5","6","7","8","9","0"],
        ["Q","W","E","R","T","Y","U","I","O","P"],
        ["A","S","D","F","G","H","J","K","L","DEL"],
        ["SHIFT","Z","X","C","V","B","N","M","SPACE","OK"]
    ]
    readonly property var symbolRows: [
        ["!","?",".",",",":",";","'","\"","-","_"],
        ["(",")","[","]","{","}","<",">","/","\\"],
        ["@","#","$","%","&","*","+","=","~","DEL"],
        ["^","`","|","°","·","¡","¿","§","SPACE","OK"]
    ]
    readonly property var accentRows: [
        ["à","á","â","ã","ä","å","æ","ç","è","é"],
        ["ê","ë","ì","í","î","ï","ñ","ò","ó","ô"],
        ["õ","ö","ø","ù","ú","û","ü","ý","ß","DEL"],
        ["œ","¢","£","¥","€","™","©","®","SPACE","OK"]
    ]
    readonly property var clipRow: ["COPY","PASTE"]

    readonly property var rows: {
        var base = (page === 1) ? symbolRows : (page === 2 ? accentRows : letterRows);
        return allowClipboard ? base.concat([clipRow]) : base;
    }

    property int row: 0
    property int col: 0

    function clampCol() {
        var len = rows[row].length;
        if (col > len - 1) col = len - 1;
    }
    function setPage(p) {
        page = p;
        if (row > rows.length - 1) row = rows.length - 1;
        clampCol();
    }

    // ── Key handling ──────────────────────────────────────────────────────
    function press(k) {
        if (k === "DEL")   { textEdited(root.text.slice(0, -1)); return; }
        if (k === "SPACE") { textEdited(root.text + " "); return; }
        if (k === "OK")    { accepted(); return; }
        if (k === "SHIFT") { shifted = !shifted; return; }
        if (k === "COPY")  { clipboard = root.text; return; }
        if (k === "PASTE") { textEdited(root.text + clipboard); return; }
        textEdited(root.text + (shifted ? k.toUpperCase() : k.toLowerCase()));
    }

    // Label shown on a key — commands get glyphs, letters follow shift state.
    function keyLabel(k) {
        if (k === "DEL")   return "\u232B";
        if (k === "SPACE") return "\u2423";
        if (k === "OK")    return "\u2713";
        if (k === "SHIFT") return "\u21E7";
        if (k.length > 1)  return k;                       // COPY / PASTE
        return shifted ? k.toUpperCase() : k.toLowerCase();
    }
    function isCommand(k) { return k.length > 1; }

    // ── Layout ────────────────────────────────────────────────────────────
    Column {
    id: grid

        anchors.horizontalCenter: parent.horizontalCenter
        spacing: vpx(10)

        // Title + current text
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: vpx(6)

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
                width: (root.keyW * 10) + (root.keyGap * 9)
                height: vpx(46)
                color: Qt.rgba(1, 1, 1, 0.10)
                border.width: vpx(2)
                border.color: theme.accent
                Text {
                    anchors { left: parent.left; leftMargin: vpx(12); verticalCenter: parent.verticalCenter }
                    text: root.text === "" ? "Type to search..."
                          : (root.masked ? "\u2022".repeat(root.text.length) : root.text)
                    color: root.text === "" ? Qt.rgba(1, 1, 1, 0.4) : "white"
                    font.family: subtitleFont.name
                    font.pixelSize: fpx(20)
                }
                // Caret
                Rectangle {
                    width: vpx(2); height: parent.height * 0.5
                    color: theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                    x: vpx(12) + Math.min(parent.width - vpx(24), textMetrics.width + vpx(2))
                    visible: root.text !== ""
                    TextMetrics {
                        id: textMetrics
                        font.family: subtitleFont.name
                        font.pixelSize: fpx(20)
                        text: root.masked ? "\u2022".repeat(root.text.length) : root.text
                    }
                }
            }
        }

        // Key grid
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.keyGap

            Repeater {
                model: root.rows.length
                Row {
                    property int rowIndex: index
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.keyGap

                    Repeater {
                        model: root.rows[rowIndex].length
                        Rectangle {
                            property string key: root.rows[rowIndex][index]
                            width: root.keyW
                            height: root.keyH
                            radius: vpx(4)
                            color: (root.row === rowIndex && root.col === index)
                                   ? theme.accent
                                   : (key === "SHIFT" && root.shifted)
                                     ? Qt.rgba(1, 1, 1, 0.25)
                                     : Qt.rgba(1, 1, 1, 0.08)
                            Text {
                                anchors.centerIn: parent
                                text: root.keyLabel(key)
                                color: "white"
                                font.family: subtitleFont.name
                                // COPY / PASTE need to fit a word in one cell.
                                font.pixelSize: (key === "COPY" || key === "PASTE") ? fpx(13) : fpx(20)
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { root.row = rowIndex; root.col = index; root.press(key); }
                            }
                        }
                    }
                }
            }
        }

        // Page switcher — LB/RB also cycle these.
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.keyGap
            Repeater {
                model: [ { p: 0, t: "ABC" }, { p: 1, t: "&12" }, { p: 2, t: "áé" } ]
                Rectangle {
                    width: root.keyW * 1.6
                    height: vpx(34)
                    radius: vpx(4)
                    color: (root.page === modelData.p) ? theme.accent : Qt.rgba(1, 1, 1, 0.08)
                    Text {
                        anchors.centerIn: parent
                        text: modelData.t
                        color: "white"
                        font.family: subtitleFont.name
                        font.pixelSize: fpx(16)
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.setPage(modelData.p)
                    }
                }
            }
        }
    }

    // ── Navigation ────────────────────────────────────────────────────────
    Keys.onUpPressed:    { event.accepted = true; if (row > 0) { row--; clampCol(); } }
    Keys.onDownPressed:  { event.accepted = true; if (row < rows.length - 1) { row++; clampCol(); } }
    Keys.onLeftPressed:  { event.accepted = true; if (col > 0) col--; }
    Keys.onRightPressed: { event.accepted = true; if (col < rows[row].length - 1) col++; }

    Keys.onPressed: {
        if (event.isAutoRepeat) return;

        if (api.keys.isAccept(event)) {                 // A — type
            event.accepted = true;
            press(rows[row][col]);
            return;
        }
        if (api.keys.isDetails(event)) {                // X — backspace
            event.accepted = true;
            textEdited(root.text.slice(0, -1));
            return;
        }
        if (api.keys.isFilters(event)) {                // Y — accept
            event.accepted = true;
            accepted();
            return;
        }
        if (api.keys.isPrevPage(event)) {               // LB — previous page
            event.accepted = true;
            setPage((page + 2) % 3);
            return;
        }
        if (api.keys.isNextPage(event)) {               // RB — next page
            event.accepted = true;
            setPage((page + 1) % 3);
            return;
        }
        if (api.keys.isCancel(event)) {                 // B — close
            event.accepted = true;
            cancelled();
        }
    }
}
