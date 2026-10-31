// XboxOSv2 – RALeaderboardPanel.qml
// One leaderboard's top 100, over the Gaming tab's Leaderboards view (A on a
// leaderboard).
// Your row is in the accent; when you're outside the top 100 it's added at
// the end under a gap. Opens on your row when you're listed, else the top.
//
// Keys: Up/Down move, LB/RB jump to the top / to you, B (or a tap outside)
// closes.

import QtQuick 2.15

FocusScope {
id: panel

    anchors.fill: parent
    visible: false
    z: 100

    property var board: null                    // a cheevosData.leaderboards entry
    readonly property bool loading: cheevosData.lbEntriesState === 1
    // The top 100, plus your row when you're further down.
    readonly property var rows: {
        var out = cheevosData.lbEntries.slice(0);
        if (board && board.myRank > 0 && board.myRank > out.length && out.length > 0)
            out.push({ rank: board.myRank, user: cheevosData.raUserName, score: board.myScore, date: "", gap: true });
        return out;
    }
    readonly property int myRow: {
        for (var i = 0; i < rows.length; i++)
            if (rows[i].user.toLowerCase() === cheevosData.raUserName.toLowerCase()) return i;
        return -1;
    }
    onMyRowChanged: if (visible && myRow >= 0 && list.currentIndex === 0) list.currentIndex = myRow

    signal closed()

    readonly property color panelColor: whiteBackground ? "#f4f4f4" : "#2b2b2b"
    readonly property color rowColor:   whiteBackground ? "#ffffff" : "#353535"
    // A color property, so it has real channels (theme.accent is a string).
    readonly property color cAccent: theme.accent
    readonly property color mineColor:  Qt.rgba(cAccent.r, cAccent.g, cAccent.b, whiteBackground ? 0.18 : 0.28)

    function open(b) {
        board = b;
        cheevosData.loadLeaderboardEntries(b.id);
        list.currentIndex = 0;
        visible = true;
        forceActiveFocus();
        playAccept();
    }
    function close() { visible = false; playBack(); closed(); }
    function dateText(d) {
        var ms = Date.parse(d);
        return isNaN(ms) ? "" : Qt.formatDate(new Date(ms), "MMM d, yyyy");
    }

    Rectangle {
        anchors.fill: parent
        color: "black"; opacity: 0.6
        MouseArea { anchors.fill: parent; onClicked: panel.close() }
    }

    Rectangle {
    id: box
        // Centred in the space above the button prompts, clear of the fade.
        anchors.horizontalCenter: parent.horizontalCenter
        width: vpx(760); height: Math.min(parent.height - helpMargin - vpx(40), vpx(580))
        y: (parent.height - helpMargin - height) / 2
        radius: vpx(4)
        color: panel.panelColor
        MouseArea { anchors.fill: parent }

        Column {
        id: head
            x: vpx(28); y: vpx(22)
            width: parent.width - vpx(56)
            spacing: vpx(4)
            Text {
                width: parent.width; elide: Text.ElideRight
                text: panel.board ? panel.board.title : ""
                color: theme.text
                font.family: titleFont.name; font.pixelSize: fpx(21)
            }
            Text {
                width: parent.width; elide: Text.ElideRight
                text: (panel.board ? panel.board.description : "")
                      + (cheevosData.lbEntriesTotal > 0 ? "  ·  " + cheevosData.raFmt(cheevosData.lbEntriesTotal) + " entries" : "")
                      + (panel.board && panel.board.myRank > 0 ? "  ·  your rank #" + cheevosData.raFmt(panel.board.myRank) : "")
                color: theme.text; opacity: 0.7
                font.family: bodyFont.name; font.pixelSize: fpx(14)
            }
        }

        ListView {
        id: list
            anchors { left: head.left; right: head.right; top: head.bottom; topMargin: vpx(12); bottom: parent.bottom; bottomMargin: vpx(16) }
            leftMargin: vpx(8); rightMargin: vpx(8); topMargin: vpx(8); bottomMargin: vpx(8)
            clip: true
            model: panel.rows
            spacing: vpx(5)
            keyNavigationEnabled: false
            highlightMoveDuration: 100
            preferredHighlightBegin: height * 0.3
            preferredHighlightEnd: height * 0.7
            highlightRangeMode: ListView.ApplyRange

            Text {
                anchors.centerIn: parent
                visible: panel.rows.length === 0
                text: panel.loading ? "Loading…" : "No entries yet"
                color: theme.text; opacity: 0.55
                font.family: bodyFont.name; font.pixelSize: fpx(16)
            }

            delegate: Item {
                readonly property bool mine: index === panel.myRow
                readonly property bool hot: ListView.isCurrentItem && panel.activeFocus
                width: list.width - list.leftMargin - list.rightMargin
                height: vpx(48) + (modelData.gap ? vpx(18) : 0)
                Text {
                    visible: modelData.gap === true
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
                    text: "⋯"
                    color: theme.text; opacity: 0.5; font.pixelSize: fpx(14)
                }
                Rectangle {
                id: rowBg
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: vpx(48)
                    radius: vpx(4)
                    color: parent.mine ? panel.mineColor : panel.rowColor
                    RAFocus { on: parent.parent.hot }
                    Rectangle {
                        visible: parent.parent.mine
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: vpx(4); radius: vpx(2); color: theme.accent
                    }
                    Text {
                    id: rankText
                        anchors { left: parent.left; leftMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        width: vpx(64)
                        text: "#" + cheevosData.raFmt(modelData.rank)
                        color: theme.text
                        font.family: titleFont.name; font.pixelSize: fpx(17)
                    }
                    Image {
                    id: av
                        anchors { left: rankText.right; verticalCenter: parent.verticalCenter }
                        width: vpx(32); height: width
                        source: modelData.user ? "https://media.retroachievements.org/UserPic/" + modelData.user + ".png" : ""
                        sourceSize: Qt.size(hrpx(64), hrpx(64))
                        asynchronous: true; smooth: true
                        fillMode: Image.PreserveAspectCrop
                    }
                    Text {
                        anchors { left: av.right; leftMargin: vpx(12); right: scoreText.left; rightMargin: vpx(12); verticalCenter: parent.verticalCenter }
                        elide: Text.ElideRight
                        text: modelData.user + (parent.parent.mine ? " (you)" : "")
                        color: theme.text
                        font.family: bodyFont.name; font.pixelSize: fpx(16)
                    }
                    Text {
                    id: scoreText
                        anchors { right: dateLabel.left; rightMargin: vpx(16); verticalCenter: parent.verticalCenter }
                        text: modelData.score
                        color: theme.text
                        font.family: bodyFont.name; font.pixelSize: fpx(17)
                    }
                    Text {
                    id: dateLabel
                        anchors { right: parent.right; rightMargin: vpx(14); verticalCenter: parent.verticalCenter }
                        width: vpx(110); horizontalAlignment: Text.AlignRight
                        text: panel.dateText(modelData.date)
                        color: theme.text; opacity: 0.55
                        font.family: bodyFont.name; font.pixelSize: fpx(12)
                    }
                }
            }
        }
    }

    Keys.onUpPressed:   { event.accepted = true; if (list.currentIndex > 0) { list.currentIndex--; playNav(); } }
    Keys.onDownPressed: { event.accepted = true; if (list.currentIndex < rows.length - 1) { list.currentIndex++; playNav(); } }
    Keys.onLeftPressed:  event.accepted = true
    Keys.onRightPressed: event.accepted = true
    Keys.onPressed: {
        if (api.keys.isCancel(event) && !event.isAutoRepeat) close();
        else if (api.keys.isPrevPage(event) && !event.isAutoRepeat) { list.currentIndex = 0; playNav(); }
        else if (api.keys.isNextPage(event) && !event.isAutoRepeat) { if (myRow >= 0) { list.currentIndex = myRow; playNav(); } }
        event.accepted = true;
    }
}
