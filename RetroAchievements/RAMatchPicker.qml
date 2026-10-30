// XboxOSv2 – RAMatchPicker.qml
// Pick the right match when title matching got it wrong or found nothing:
// a pop-up list, best guesses first, with a search box (the theme's
// on-screen keyboard). The host gives it the candidates and decides what a
// pick means; GameAchievementsView uses it both ways:
//   "Find in your library"  – which of your games is this RA game
//   "Match to RetroAchievements" – which RA game is this game of yours
//
// Candidates come from cheevosData.pickItem(); ranking is
// cheevosData.rankItems() (shared words, spaces ignored), so the right game
// is usually on top before anything is typed.
//
// Keys: Up/Down move, Up from the first result reaches the search box, A on
// a result picks it, A on the box or Y opens the keyboard, B closes.

import QtQuick 2.15
import "../Global"

FocusScope {
id: picker

    anchors.fill: parent
    visible: false
    z: 100

    property string title: ""
    property string subtitle: ""
    property string query: ""
    property var items: []
    property bool loading: false
    readonly property var results: cheevosData.rankItems(items, query, 80)
    property bool onSearch: false
    property bool kbOpen: false

    signal chosen(var value)
    signal closed()

    readonly property color panelColor: whiteBackground ? "#f4f4f4" : "#2b2b2b"
    readonly property color fieldColor: whiteBackground ? "#ffffff" : "#3a3a3a"

    function open(t, sub, q) {
        title = t; subtitle = sub || ""; query = q || "";
        items = []; loading = true;
        onSearch = false; kbOpen = false;
        list.currentIndex = 0;
        visible = true;
        forceActiveFocus();
        playAccept();
    }
    function setItems(arr) { items = arr; loading = false; list.currentIndex = 0; }
    function close() { kbOpen = false; visible = false; playBack(); closed(); }
    function pick() {
        if (onSearch) { openKeyboard(); return; }
        if (list.currentIndex < 0 || list.currentIndex >= results.length) return;
        playAccept();
        var v = results[list.currentIndex].value;
        kbOpen = false; visible = false;
        chosen(v);
        closed();
    }
    function openKeyboard() { playAccept(); kbOpen = true; }

    Rectangle {
        anchors.fill: parent
        color: "black"; opacity: 0.55
        MouseArea { anchors.fill: parent; onClicked: picker.close() }
    }

    Rectangle {
    id: panel
        anchors.centerIn: parent
        width: vpx(760); height: vpx(540)
        radius: vpx(4)
        color: picker.panelColor
        MouseArea { anchors.fill: parent }

        Column {
        id: head
            x: vpx(28); y: vpx(22)
            width: parent.width - vpx(56)
            spacing: vpx(4)
            Text {
                width: parent.width; elide: Text.ElideRight
                text: picker.title
                color: theme.text
                font.family: titleFont.name; font.pixelSize: fpx(20)
            }
            Text {
                width: parent.width; elide: Text.ElideRight
                text: picker.subtitle
                visible: text !== ""
                color: theme.text; opacity: 0.65
                font.family: bodyFont.name; font.pixelSize: fpx(14)
            }
        }

        // Search box
        Rectangle {
        id: field
            anchors { left: head.left; right: head.right; top: head.bottom; topMargin: vpx(14) }
            height: vpx(42)
            radius: vpx(4)
            color: picker.fieldColor
            RAFocus { on: picker.onSearch && picker.activeFocus && !picker.kbOpen }
            RAIcon {
            id: searchIcon
                anchors { left: parent.left; leftMargin: vpx(12); verticalCenter: parent.verticalCenter }
                source: "../assets/images/fluent/search.svg"
            }
            Text {
                anchors { left: searchIcon.right; leftMargin: vpx(10); right: parent.right; rightMargin: vpx(12); verticalCenter: parent.verticalCenter }
                elide: Text.ElideRight
                text: picker.query !== "" ? picker.query : "Search"
                color: theme.text; opacity: picker.query !== "" ? 1 : 0.5
                font.family: bodyFont.name; font.pixelSize: fpx(16)
            }
            TapHandler { onTapped: { picker.onSearch = true; picker.openKeyboard(); } }
        }

        ListView {
        id: list
            anchors { left: head.left; right: head.right; top: field.bottom; topMargin: vpx(10); bottom: parent.bottom; bottomMargin: vpx(16) }
            leftMargin: vpx(8); rightMargin: vpx(8); topMargin: vpx(8); bottomMargin: vpx(8)
            clip: true
            model: picker.results
            spacing: vpx(4)
            keyNavigationEnabled: false
            highlightMoveDuration: 100
            preferredHighlightBegin: vpx(8)
            preferredHighlightEnd: height - vpx(60)
            highlightRangeMode: ListView.ApplyRange

            Text {
                anchors.centerIn: parent
                visible: picker.results.length === 0
                text: picker.loading ? "Loading…" : (picker.query !== "" ? "Nothing matches “" + picker.query + "”" : "Nothing to pick from")
                color: theme.text; opacity: 0.55
                font.family: bodyFont.name; font.pixelSize: fpx(16)
            }

            delegate: Item {
                readonly property bool hot: ListView.isCurrentItem && !picker.onSearch && picker.activeFocus && !picker.kbOpen
                width: list.width - list.leftMargin - list.rightMargin
                height: vpx(52)
                Rectangle { anchors.fill: parent; radius: vpx(4); color: picker.fieldColor; opacity: 0.6 }
                RAFocus { on: parent.hot }
                Text {
                id: rowTitle
                    anchors { left: parent.left; leftMargin: vpx(14); right: rowSub.left; rightMargin: vpx(14); verticalCenter: parent.verticalCenter }
                    elide: Text.ElideRight
                    text: modelData.title
                    color: theme.text
                    font.family: bodyFont.name; font.pixelSize: fpx(16)
                }
                Text {
                id: rowSub
                    anchors { right: parent.right; rightMargin: vpx(14); verticalCenter: parent.verticalCenter }
                    text: modelData.sub || ""
                    color: theme.text; opacity: 0.6
                    font.family: bodyFont.name; font.pixelSize: fpx(13)
                }
                TapHandler {
                    onTapped: {
                        picker.onSearch = false;
                        if (list.currentIndex === index) picker.pick();
                        else { list.currentIndex = index; playNav(); }
                    }
                }
            }
        }
    }

    // ── On-screen keyboard: typing re-ranks the list as you go ───────────
    Rectangle {
        visible: picker.kbOpen
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        MouseArea { anchors.fill: parent; onClicked: { picker.kbOpen = false; picker.forceActiveFocus(); } }
        Loader {
            anchors.centerIn: parent
            active: picker.kbOpen
            focus: picker.kbOpen
            onLoaded: item.forceActiveFocus()
            sourceComponent: Component {
                VirtualKeyboard {
                    title: "Search"
                    text: picker.query
                    onTextEdited: { picker.query = newText; list.currentIndex = 0; }
                    onAccepted: { picker.kbOpen = false; picker.onSearch = picker.results.length === 0; picker.forceActiveFocus(); }
                    onCancelled: { picker.kbOpen = false; picker.forceActiveFocus(); }
                }
            }
        }
    }

    Keys.onUpPressed: {
        event.accepted = true;
        if (onSearch) return;
        if (list.currentIndex > 0) { list.currentIndex--; playNav(); }
        else { onSearch = true; playNav(); }
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (onSearch) { if (results.length > 0) { onSearch = false; list.currentIndex = 0; playNav(); } return; }
        if (list.currentIndex < results.length - 1) { list.currentIndex++; playNav(); }
    }
    Keys.onLeftPressed: event.accepted = true
    Keys.onRightPressed: event.accepted = true
    Keys.onPressed: {
        if (event.isAutoRepeat) { event.accepted = true; return; }
        if (api.keys.isCancel(event)) close();
        else if (api.keys.isAccept(event)) pick();
        else if (api.keys.isFilters(event)) { onSearch = true; openKeyboard(); }
        event.accepted = true;
    }
}
