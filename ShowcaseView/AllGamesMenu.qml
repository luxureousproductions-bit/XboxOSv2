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

    // ── Right panel: box art + logo + game info ───────────────────────────
    Item {
    id: rightPanel

        anchors {
            top: header.bottom
            left: gamelist.right
            right: parent.right
            bottom: parent.bottom
        }

        // Box art
        Image {
        id: boxArt

            anchors {
                top: parent.top; topMargin: globalMargin
                left: parent.left; leftMargin: globalMargin
                right: parent.right; rightMargin: globalMargin
                bottom: parent.verticalCenter
            }
            asynchronous: true
            source: currentGame ? (currentGame.assets.boxFront || "") : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        // Game logo — overlaid at bottom of box art area
        Image {
        id: gameLogo

            anchors {
                bottom: boxArt.bottom; bottomMargin: vpx(8)
                left: parent.left; leftMargin: globalMargin
                right: parent.right; rightMargin: globalMargin
            }
            height: vpx(60)
            asynchronous: true
            source: currentGame ? (currentGame.assets.logo || "") : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: source !== ""
        }

        // Game info (title, meta, description)
        GameInfo {
        id: info

            anchors {
                top: parent.verticalCenter; topMargin: globalMargin
                left: parent.left; leftMargin: globalMargin
                right: parent.right; rightMargin: globalMargin
                bottom: parent.bottom; bottomMargin: globalMargin + helpMargin
            }
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
                        if (selected) gameDetails(currentGame);
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
        // A — open game details
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            gameDetails(currentGame);
        }
        // B — go back
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            previousScreen();
        }
        // X — filter (favorites toggle)
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            toggleFavs();
        }
    }

    ListModel {
        id: allGamesHelpModel
        ListElement { name: "Back";         button: "cancel" }
        ListElement { name: "Filter";       button: "filters" }
        ListElement { name: "View details"; button: "accept" }
    }

    onFocusChanged: { if (focus) currentHelpbarModel = allGamesHelpModel; }
}
