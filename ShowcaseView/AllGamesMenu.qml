// AllGamesMenu.qml — All games across all collections in one list
import QtQuick 2.0
import QtQuick.Layouts 1.11
import "../Global"
import "../Lists"
import SortFilterProxyModel 0.2

FocusScope {
id: root

    property real itemheight: vpx(50)
    property int skipnum: 10

    // Data source — wraps api.allGames in a SortFilterProxyModel
    ListAllGames {
    id: listAllGames
        max: api.allGames.count
    }

    property bool showFavsOnly: false

    // Second proxy layer adds favorites filter on top of listAllGames
    SortFilterProxyModel {
    id: displayModel
        sourceModel: listAllGames.games
        filters: ExpressionFilter {
            id: favFilter
            enabled: showFavsOnly
            expression: model.favorite === true
        }
    }

    // Get the actual game object through both proxy layers
    function getCurrentGame(displayIndex) {
        var sourceIndex = displayModel.mapToSource(displayIndex);
        return listAllGames.currentGame(sourceIndex);
    }

    // ── Art selection: mirrors Game Details tab settings ─────────────────
    function is3dPath(path) {
        if (!path) return false;
        var p = path.toLowerCase();
        return p.includes("box3d") || p.includes("box_3d") || p.includes("3dbox");
    }
    function artSource(data) {
        if (!data) return "";
        var list = data.assets.boxFrontList;

        // Priority matches Game Details tab order: Miximage > 3D Box > 2D Box
        if (settings.CarouselMiximage === "Yes") {
            if (data.assets.miximage)   return data.assets.miximage;
            if (data.assets.mix_image)  return data.assets.mix_image;
        }
        if (settings.Carousel3DBox === "Yes" && list) {
            for (var i = 0; i < list.length; i++)
                if (is3dPath(list[i])) return list[i];
        }
        if (settings.Carousel2DBox === "Yes") {
            if (list) {
                for (var j = 0; j < list.length; j++)
                    if (!is3dPath(list[j])) return list[j];
            }
            if (data.assets.boxFront) return data.assets.boxFront;
        }
        // Fallback: use whatever boxFront exists
        if (data.assets.boxFront)  return data.assets.boxFront;
        if (data.assets.boxBack)   return data.assets.boxBack;
        if (data.assets.poster)    return data.assets.poster;
        if (data.assets.banner)    return data.assets.banner;
        if (data.assets.cartridge) return data.assets.cartridge;
        if (data.assets.miximage)  return data.assets.miximage;
        return "";
    }

    // ── Right panel: box art + game info ─────────────────────────────────
    Item {
    id: rightPanel

        anchors {
            top: header.bottom
            left: gamelist.right
            right: parent.right
            bottom: parent.bottom
        }

        // Box art — fills top half of right panel
        Image {
        id: boxArt

            anchors {
                top: parent.top; topMargin: globalMargin
                left: parent.left; leftMargin: globalMargin
                right: parent.right; rightMargin: globalMargin
                bottom: parent.verticalCenter
            }
            asynchronous: true
            source: currentGame ? artSource(currentGame) : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        // Game info (title, meta, description) — lower half
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
            text: showFavsOnly ? (displayModel.count + " favorites") : (listAllGames.max + " games")
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

        model: displayModel

        onCurrentIndexChanged: {
            if (currentIndex >= 0)
                currentGame = getCurrentGame(currentIndex);
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
        // A — view game details
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            gameDetails(currentGame);
        }
        // B — go back
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            previousScreen();
        }
        // X — toggle favorites filter locally
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            showFavsOnly = !showFavsOnly;
            gamelist.currentIndex = 0;
        }
    }

    ListModel {
        id: allGamesHelpModel
        ListElement { name: "Back";         button: "cancel" }
        ListElement { name: "Filter";       button: "details" }
        ListElement { name: "View details"; button: "accept" }
    }

    onFocusChanged: { if (focus) currentHelpbarModel = allGamesHelpModel; }
}
