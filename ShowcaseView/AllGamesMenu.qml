// AllGamesMenu.qml — All games across all collections, platform-page style
import QtQuick 2.15
import QtQuick.Layouts 1.11
import "../Global"
import "../Lists"
import "../utils.js" as Utils

FocusScope {
id: root

    property real itemheight: vpx(50)
    property int  skipnum: 10

    // All-games data source
    ListAllGames {
    id: listAllGames
        max: api.allGames.count
    }

    Component.onCompleted: {
        currentCustomCollection = listAllGames.collection;
        currentHelpbarModel = allGamesHelpModel;
    }

    // ── Box art (right side) — identical logic to GameView ────────────────
    Image {
    id: boxArt
        anchors {
            top: header.bottom; topMargin: globalMargin
            left: softwarelist.right; leftMargin: globalMargin
            right: parent.right; rightMargin: globalMargin
            bottom: parent.bottom; bottomMargin: globalMargin + helpMargin
        }
        asynchronous: true
        source: currentGame ? Utils.boxArt(currentGame, settings.BoxArtStyle) : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    // ── Header (same as platform page) ────────────────────────────────────
    HeaderBar {
    id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(75)
        filteredCount: listAllGames.games.count
    }

    // Library icon overlay — replaces the platform logo on the left
    Item {
        anchors { left: parent.left; top: parent.top }
        width: vpx(310); height: vpx(75)
        z: 10

        Rectangle { anchors.fill: parent; color: theme.main }

        Image {
        id: libIcon
            source: "../assets/images/gamesandapps.png"
            anchors { left: parent.left; leftMargin: globalMargin; verticalCenter: parent.verticalCenter }
            height: vpx(40); width: vpx(40)
            fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
        }
        Text {
            anchors { left: libIcon.right; leftMargin: vpx(10); verticalCenter: parent.verticalCenter }
            text: "My Games & Apps"
            color: theme.text; font.family: titleFont.name; font.pixelSize: vpx(22); font.bold: true
        }
        Text {
            anchors { left: parent.left; leftMargin: globalMargin; bottom: parent.bottom; bottomMargin: vpx(6) }
            text: listAllGames.games.count + " games"
            color: theme.text; opacity: 0.7; font.family: subtitleFont.name; font.pixelSize: vpx(14)
        }
    }

    // ── Game list ─────────────────────────────────────────────────────────
    ListView {
    id: softwarelist

        currentIndex: currentGameIndex
        onCurrentIndexChanged: {
            if (currentIndex !== -1) {
                currentGameIndex = currentIndex;
                currentGame = listAllGames.currentGame(currentIndex);
            }
        }

        focus: true
        Keys.onUpPressed: {
            if (currentIndex !== 0) currentIndex--;
            else header.focusNavButtons();
        }
        Connections {
            target: header
            onNavButtonDown: { softwarelist.focus = true; }
        }

        anchors {
            top: header.bottom; topMargin: globalMargin
            bottom: parent.bottom; bottomMargin: globalMargin
            left: parent.left
        }
        width: vpx(400)
        spacing: vpx(0)
        orientation: ListView.Vertical
        preferredHighlightBegin: softwarelist.height / 2 - itemheight
        preferredHighlightEnd:   softwarelist.height / 2
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 100
        clip: true

        model: currentCustomCollection.games

        delegate: Component {
            Item {
                width: ListView.view.width
                height: itemheight
                property bool selected: ListView.isCurrentItem

                // Solid accent highlight bar for the selected game
                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right; rightMargin: vpx(20)
                        top: parent.top; topMargin: vpx(4)
                        bottom: parent.bottom; bottomMargin: vpx(4)
                    }
                    radius: vpx(6)
                    color: theme.accent
                    visible: selected
                }
                Text {
                    text: modelData.title
                    height: parent.height
                    anchors {
                        left: parent.left; leftMargin: vpx(20)
                        right: parent.right; rightMargin: vpx(30)
                    }
                    color: selected ? "white" : theme.text
                    font.family: subtitleFont.name
                    font.pixelSize: vpx(20)
                    font.bold: selected
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    opacity: selected ? 1 : 0.35
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (selected) gameDetails(currentGame);
                        else softwarelist.currentIndex = index;
                    }
                }
            }
        }
    }

    // ── Input ─────────────────────────────────────────────────────────────
    Keys.onDownPressed: {
        if (softwarelist.currentIndex !== softwarelist.count - 1)
            softwarelist.currentIndex++;
        else
            softwarelist.currentIndex = 0;
    }
    Keys.onLeftPressed: {
        if (softwarelist.currentIndex > skipnum)
            softwarelist.currentIndex -= skipnum;
        else
            softwarelist.currentIndex = 0;
    }
    Keys.onRightPressed: {
        if (softwarelist.currentIndex < softwarelist.count - skipnum)
            softwarelist.currentIndex += skipnum;
        else
            softwarelist.currentIndex = softwarelist.count - 1;
    }

    Keys.onPressed: {
        // A — view details
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (softwarelist.focus) gameDetails(currentGame);
            else { currentGameIndex = 0; softwarelist.focus = true; }
        }
        // B — back
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (softwarelist.focus) previousScreen();
            else { currentGameIndex = 0; softwarelist.focus = true; }
        }
        // X — filters (same function as platform page's filter)
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            toggleFavs();
        }
        // Y — settings
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            settingsScreen();
        }
    }

    // ── Helpbar: A View details, X Filters, Y Settings, B Back ────────────
    ListModel {
        id: allGamesHelpModel
        ListElement { name: "View details"; button: "accept"  }
        ListElement { name: "Filters";      button: "details" }
        ListElement { name: "Settings";     button: "filters" }
        ListElement { name: "Back";         button: "cancel"  }
    }

    onFocusChanged: {
        if (focus) {
            currentCustomCollection = listAllGames.collection;
            currentHelpbarModel = allGamesHelpModel;
        }
    }
}
