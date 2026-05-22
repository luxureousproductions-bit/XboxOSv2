// AllGamesMenu.qml — All games across all collections in one list
import QtQuick 2.0
import QtQuick.Layouts 1.11
import "../Global"
import "../Lists"

FocusScope {
id: root

    property real itemheight: vpx(50)
    property int skipnum: 10

    // Data source — wraps api.allGames in a SortFilterProxyModel
    ListAllGames {
    id: listAllGames
        max: api.allGames.count
    }

    // Screenshot / game art panel (right side)
    Image {
    id: screenshot

        anchors {
            top: header.bottom
            left: gamelist.right
            right: parent.right
            bottom: parent.bottom
        }
        asynchronous: true
        source: currentGame && currentGame.assets.screenshots[0]
                ? currentGame.assets.screenshots[0] : ""
        fillMode: Image.PreserveAspectCrop
        smooth: true

        GameInfo {
        id: info

            anchors {
                left: parent.left; leftMargin: globalMargin
                right: parent.right; rightMargin: globalMargin
                bottom: parent.bottom; bottomMargin: globalMargin + helpMargin
            }
            height: vpx(230)
        }
    }

    // ── Header bar ────────────────────────────────────────────────────────
    Item {
    id: header

        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(75)

        Rectangle {
            anchors.fill: parent
            color: theme.main
            opacity: 0.92
        }

        Image {
            id: libraryIcon
            source: "../assets/images/gamesandapps.png"
            anchors {
                left: parent.left; leftMargin: globalMargin
                verticalCenter: parent.verticalCenter
            }
            height: vpx(40); width: vpx(40)
            fillMode: Image.PreserveAspectFit
            smooth: true; asynchronous: true
        }

        Text {
            anchors {
                left: libraryIcon.right; leftMargin: vpx(12)
                verticalCenter: parent.verticalCenter
            }
            text: "My Games & Apps"
            color: theme.text
            font.family: titleFont.name
            font.pixelSize: vpx(24)
            font.bold: true
        }

        Text {
            anchors {
                left: parent.left; leftMargin: globalMargin
                bottom: parent.bottom; bottomMargin: vpx(6)
            }
            text: listAllGames.max + " games"
            color: theme.text
            opacity: 0.7
            font.family: subtitleFont.name
            font.pixelSize: vpx(14)
        }
    }

    // ── Game list ─────────────────────────────────────────────────────────
    ListView {
    id: gamelist

        focus: true

        Keys.onUpPressed: {
            if (currentIndex > 0) currentIndex--;
        }

        anchors {
            top: header.bottom; topMargin: globalMargin
            bottom: parent.bottom; bottomMargin: globalMargin
            left: parent.left
        }
        width: vpx(400)

        spacing: vpx(0)
        orientation: ListView.Vertical

        preferredHighlightBegin: gamelist.height / 2 - itemheight
        preferredHighlightEnd: gamelist.height / 2
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 100
        clip: true

        model: listAllGames.games

        onCurrentIndexChanged: {
            if (currentIndex >= 0)
                currentGame = listAllGames.currentGame(currentIndex);
        }

        delegate: Component {
            Item {
            id: delegatecontainer

                width: ListView.view.width
                height: itemheight
                property bool selected: ListView.isCurrentItem

                Rectangle {
                    width: vpx(3)
                    anchors {
                        left: parent.left; leftMargin: vpx(11)
                        top: parent.top; topMargin: vpx(5)
                        bottom: parent.bottom; bottomMargin: vpx(5)
                    }
                    color: theme.text
                    visible: selected
                }

                Text {
                    text: modelData.title
                    height: parent.height
                    anchors {
                        left: parent.left; leftMargin: vpx(25)
                        right: parent.right; rightMargin: vpx(25)
                    }
                    color: theme.text
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(20)
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    opacity: selected ? 1 : 0.2
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (selected) launchGame();
                        else gamelist.currentIndex = index;
                    }
                }
            }
        }
    }

    // ── Input handling ────────────────────────────────────────────────────
    Keys.onDownPressed: {
        if (gamelist.currentIndex < gamelist.count - 1)
            gamelist.currentIndex++;
        else
            gamelist.currentIndex = 0;
    }
    Keys.onLeftPressed: {
        if (gamelist.currentIndex > skipnum)
            gamelist.currentIndex -= skipnum;
        else
            gamelist.currentIndex = 0;
    }
    Keys.onRightPressed: {
        if (gamelist.currentIndex < gamelist.count - skipnum)
            gamelist.currentIndex += skipnum;
        else
            gamelist.currentIndex = gamelist.count - 1;
    }

    Keys.onPressed: {
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            launchGame();
        }
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            previousScreen();
        }
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            toggleSort();
        }
    }

    ListModel {
        id: allGamesHelpModel
        ListElement { name: "Back";         button: "cancel" }
        ListElement { name: "Order";        button: "details" }
        ListElement { name: "View details"; button: "accept" }
    }

    onFocusChanged: { if (focus) currentHelpbarModel = allGamesHelpModel; }
}
