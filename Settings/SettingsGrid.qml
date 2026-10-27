// XboxOSv2 – a Settings page laid out as cards on a grid (Xbox 2023 style).
//
// Used where a single column of rows doesn't fit the content: Previews &
// sound (one row per screen, one column per setting) and Library (All
// Games and Systems side by side). The page describes its cells; this lays
// them out, moves the focus between them in two dimensions, and changes
// values.
//
// Controls: the D-pad moves between cards; A or RB steps a value forward,
// LB back; X opens More info (or, on an "item" card, its action); B goes
// back to the page list. Left from the first column also goes back.
//
// A cell is a plain object:
//   kind   "header" | "colhead" | "label" | "value" | "item"
//   row, col, span       grid position (span defaults to 1)
//   text                 header / colhead / label text, or an item's title
//   sub                  second line on label and item cards
//   key, opts            value cells: the setting and its options ("A,B,C");
//                        written with "<key>Index" in that order, as the
//                        list rows do, so both stay in step
//   label                value cells: a name on the left (else value only)
//   show                 value cells: display names, e.g. {Yes: "On"}
//   action               item cells: the X prompt's text
import QtQuick 2.15
import "../Global"
import "../utils.js" as Utils

FocusScope {
id: grid

    property var cells: []
    // Column widths as fractions of the width (gaps come out of them).
    property var colWidths: [1]
    property real gap: vpx(6)
    readonly property real edge: vpx(8)
    property real rowH: vpx(50)
    property real headerH: vpx(34)
    property real colHeadH: vpx(24)
    property color accent: theme.accent
    // Host hooks
    property var isDisabled: function(cell) { return false; }
    property var readValue: function(cell) { return String(settingsStore.get(cell.key)); }
    signal changed(var cell, string value)
    signal infoRequested(var cell)
    signal itemAction(var cell)
    signal leave()

    // Index into `cells` of the focused card; -1 = none yet.
    property int current: -1
    // Bumped on every change so value texts and greying re-read.
    property int rev: 0
    readonly property var currentCell: (current >= 0 && current < cells.length) ? cells[current] : null

    function interactive(c) { return c && (c.kind === "value" || c.kind === "item"); }
    function firstInteractive() {
        for (var i = 0; i < cells.length; i++) if (interactive(cells[i])) return i;
        return -1;
    }
    onCellsChanged: { current = firstInteractive(); layout(); }

    // ── Layout ────────────────────────────────────────────────────────────
    property var rowTops: []
    property real contentH: 0
    function rowHeightOf(r) {
        var h = 0;
        for (var i = 0; i < cells.length; i++) {
            var c = cells[i]; if (c.row !== r) continue;
            var ch = c.kind === "header" ? headerH : c.kind === "colhead" ? colHeadH : (c.h || rowH);
            if (ch > h) h = ch;
        }
        return h;
    }
    function layout() {
        var maxRow = -1;
        for (var i = 0; i < cells.length; i++) if (cells[i].row > maxRow) maxRow = cells[i].row;
        var tops = [], y = 0;
        for (var r = 0; r <= maxRow; r++) {
            tops.push(y);
            var h = rowHeightOf(r);
            if (h > 0) y += h + gap;
        }
        rowTops = tops;
        contentH = y;
    }
    function colX(col) {
        var x = 0;
        for (var i = 0; i < col; i++) x += colWidths[i] * width;
        return x;
    }
    function cellW(c) {
        var w = 0, span = c.span || 1;
        for (var i = c.col; i < c.col + span && i < colWidths.length; i++) w += colWidths[i] * width;
        return w - gap;
    }
    function cellH(c) { return c.kind === "header" ? headerH : c.kind === "colhead" ? colHeadH : (c.h || rowH); }
    function cellX(c) { return colX(c.col); }
    function cellY(c) { return rowTops.length > c.row ? rowTops[c.row] : 0; }

    // ── Values ────────────────────────────────────────────────────────────
    function display(c) {
        var e = rev;
        if (!c || !c.key) return "";
        var v = readValue(c);
        return (c.show && c.show[v] !== undefined) ? c.show[v] : v;
    }
    function step(c, dir) {
        if (!c || c.kind !== "value" || isDisabled(c)) return;
        var opts = c.opts.split(",");
        var i = opts.indexOf(readValue(c)); if (i < 0) i = 0;
        var v = opts[(i + dir + opts.length) % opts.length];
        settingsStore.set(c.key, v);
        settingsStore.set(c.key + "Index", opts.indexOf(v));
        rev++;
        playToggle();
        changed(c, v);
    }

    // ── Focus movement ────────────────────────────────────────────────────
    // The nearest interactive card in a direction, by centre distance with
    // sideways offset weighted double (so Down prefers the card below over
    // one diagonally closer).
    function move(dx, dy) {
        var c = currentCell; if (!c) { current = firstInteractive(); return true; }
        var cx = cellX(c) + cellW(c) / 2, cy = cellY(c) + cellH(c) / 2;
        var best = -1, bestD = 1e12;
        for (var i = 0; i < cells.length; i++) {
            if (i === current || !interactive(cells[i])) continue;
            var o = cells[i];
            var ox = cellX(o) + cellW(o) / 2, oy = cellY(o) + cellH(o) / 2;
            var ddx = ox - cx, ddy = oy - cy;
            if (dx !== 0 && (Math.sign(ddx) !== dx || Math.abs(ddx) < 1)) continue;
            if (dy !== 0 && (Math.sign(ddy) !== dy || Math.abs(ddy) < 1)) continue;
            var d = dx !== 0 ? Math.abs(ddx) + 2 * Math.abs(ddy) : Math.abs(ddy) + 2 * Math.abs(ddx);
            if (d < bestD) { bestD = d; best = i; }
        }
        if (best < 0) return false;
        current = best;
        playNav();
        return true;
    }
    onCurrentChanged: keepVisible()
    function keepVisible() {
        // cells[current], not currentCell: this runs from onCurrentChanged,
        // before that binding has caught up, so it would be one move behind.
        var c = cells[current]; if (!c) return;
        var y = cellY(c), h = cellH(c), top = flick.contentY, vis = flick.height - edge * 2;
        // Show the section header above a card too, when there is one.
        var pad = headerH + gap;
        // On the last card, show whatever sits below it too (a closing note).
        var last = true;
        for (var k = current + 1; k < cells.length; k++) if (interactive(cells[k])) { last = false; break; }
        if (last && current >= 0) { flick.contentY = Math.max(0, contentH - gap - vis); return; }
        if (y - pad < top) flick.contentY = Math.max(0, y - pad);
        else if (y + h > top + vis) flick.contentY = Math.min(Math.max(0, contentH - gap - vis), y + h - vis);
    }

    Keys.onUpPressed:    move(0, -1)
    Keys.onDownPressed:  move(0, 1)
    Keys.onRightPressed: move(1, 0)
    Keys.onLeftPressed:  { if (!move(-1, 0)) { playBack(); leave(); } }
    // Clickable prompts (theme.qml helpClick): A and X as the keys do; B is
    // left to the screen's mouseBack().
    function helpAction(button) {
        var c = cells[current];
        if (button === "accept") { if (c && c.kind === "value") step(c, 1); return true; }
        if (button === "details") { if (c && c.kind === "item") itemAction(c); else if (c) infoRequested(c); return true; }
        return false;
    }

    Keys.onPressed: {
        if (event.isAutoRepeat && api.keys.isAccept(event)) return;
        var c = currentCell;
        if (api.keys.isAccept(event)) {
            event.accepted = true;
            if (c && c.kind === "value") step(c, 1);
            return;
        }
        if (api.keys.isNextPage(event)) { event.accepted = true; step(c, 1);  return; }
        if (api.keys.isPrevPage(event)) { event.accepted = true; step(c, -1); return; }
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (c && c.kind === "item") itemAction(c); else if (c) infoRequested(c);
            return;
        }
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true; playBack(); leave();
        }
    }

    onWidthChanged: layout()

    Flickable {
    id: flick
        // Outset by `edge` so the focus frame, which sits just outside a
        // card, isn't clipped at the grid's sides, top or bottom.
        anchors.fill: parent
        anchors.margins: -grid.edge
        contentHeight: grid.contentH + grid.edge * 2
        interactive: false
        clip: true
        Behavior on contentY { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

        Repeater {
            model: grid.cells.length
            delegate: Item {
            id: card
                // A model swap can leave a delegate briefly past the new end.
                readonly property var c: grid.cells[index] || ({})
                readonly property bool focused: grid.activeFocus && index === grid.current
                readonly property bool dis: { var e = grid.rev; var ee = settingsEpoch; return grid.interactive(c) && c.kind === "value" && grid.isDisabled(c); }
                x: grid.cellX(c) + grid.edge; y: grid.cellY(c) + grid.edge
                width: grid.cellW(c); height: grid.cellH(c)

                // Section header: accent caps, sitting on the bottom of its row.
                Text {
                    visible: c.kind === "header"
                    anchors { left: parent.left; bottom: parent.bottom; bottomMargin: vpx(6) }
                    text: (c.text || "").toUpperCase()
                    color: grid.accent
                    font { family: subtitleFont.name; pixelSize: vpx(13); bold: true; letterSpacing: vpx(1.2) }
                }
                // Column heading (Previews & sound): grey caps.
                Text {
                    visible: c.kind === "colhead"
                    anchors { left: parent.left; leftMargin: vpx(6); bottom: parent.bottom; bottomMargin: vpx(2) }
                    text: (c.text || "").toUpperCase()
                    color: "#8e8e8e"
                    font { family: subtitleFont.name; pixelSize: vpx(12); bold: true; letterSpacing: vpx(1.2) }
                }

                // Card
                Rectangle {
                id: plate
                    visible: c.kind === "label" || c.kind === "value" || c.kind === "item"
                    anchors.fill: parent
                    radius: vpx(4)
                    color: c.dim ? "#1a1a1a" : card.focused ? "#2e2e2e" : "#232323"
                    opacity: card.dis ? 0.38 : 1
                }
                // Focus: the same Xbox frame the tiles use.
                Loader {
                    anchors.fill: parent
                    active: card.focused
                    sourceComponent: Item { FocusFrame { anchors.fill: parent; artRadius: vpx(4); glowStrength: 0.45 } }
                    z: 2
                }

                // Label card (and the name of an item card)
                Column {
                    visible: c.kind === "label" || c.kind === "item"
                    // A dim label is a "not here" filler: grey and centred.
                    anchors.left: c.dim ? undefined : parent.left
                    anchors.leftMargin: vpx(16)
                    anchors.horizontalCenter: c.dim ? parent.horizontalCenter : undefined
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: vpx(2)
                    Text { text: c.text || ""; color: c.dim ? "#5c5c5c" : "white"; font { family: subtitleFont.name; pixelSize: vpx(17) } }
                    Text { visible: !!c.sub; text: c.sub || ""; color: "#9a9a9a"; font { family: subtitleFont.name; pixelSize: vpx(12) } }
                }
                // Item action prompt (e.g. "X  Back to Systems")
                Row {
                    visible: c.kind === "item" && !!c.action
                    anchors { right: parent.right; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                    spacing: vpx(6)
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: vpx(18); height: vpx(18)
                        source: "../assets/images/controller/" + Utils.processButtonArt("details") + ".png"
                        sourceSize { width: 36; height: 36 }
                        asynchronous: true
                    }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: c.action || ""; color: "#cfcfcf"; font { family: subtitleFont.name; pixelSize: vpx(14) } }
                }

                // Value card: optional name left, value right (or centred)
                Text {
                    visible: c.kind === "value" && !!c.label
                    anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                    text: c.label || ""
                    color: "white"; opacity: card.dis ? 0.38 : 1
                    font { family: subtitleFont.name; pixelSize: vpx(17) }
                }
                Row {
                    visible: c.kind === "value"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: c.label ? parent.right : undefined
                    anchors.rightMargin: vpx(14)
                    anchors.horizontalCenter: c.label ? undefined : parent.horizontalCenter
                    spacing: vpx(10)
                    opacity: card.dis ? 0.38 : 1
                    Text { text: "‹"; color: "#8a8a8a"; font { family: subtitleFont.name; pixelSize: vpx(17) } anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: { var e = grid.rev; var ee = settingsEpoch; return c.kind === "value" ? grid.display(c) : ""; }
                        color: "white"
                        font { family: subtitleFont.name; pixelSize: vpx(16); bold: true }
                    }
                    Text { text: "›"; color: "#8a8a8a"; font { family: subtitleFont.name; pixelSize: vpx(17) } anchors.verticalCenter: parent.verticalCenter }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: grid.interactive(c)
                    hoverEnabled: settings.MouseHover == "Yes"
                    onEntered: { if (pointerMoved() && index !== grid.current) { grid.current = index; playNav(); } }
                    onClicked: {
                        grid.forceActiveFocus();
                        if (index !== grid.current) { grid.current = index; playNav(); return; }
                        if (c.kind === "value") grid.step(c, 1);
                        else if (c.kind === "item") grid.itemAction(c);
                    }
                    onWheel: { wheel.accepted = true; grid.move(0, wheel.angleDelta.y > 0 ? -1 : 1); }
                }
            }
        }
    }
}
