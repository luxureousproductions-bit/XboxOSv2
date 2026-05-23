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

    // ── Data source ───────────────────────────────────────────────────────
    ListAllGames {
    id: listAllGames
        max: api.allGames.count
    }

    // ── Filter / sort state ───────────────────────────────────────────────
    property bool  sortAscending: true
    property bool  showFavsOnly:  false
    property int   genreIndex:    0
    property var   genreList:     []
    property string currentGenre: "All"

    Component.onCompleted: {
        var genres = {};
        for (var i = 0; i < api.allGames.count; i++) {
            var g = api.allGames.get(i).genre;
            if (g) {
                g.split(",").forEach(function(part) {
                    var t = part.trim();
                    if (t) genres[t] = true;
                });
            }
        }
        var arr = Object.keys(genres).sort();
        arr.unshift("All");
        genreList = arr;
    }

    // ── Display model: sort + genre filter + favorites ────────────────────
    SortFilterProxyModel {
    id: displayModel
        sourceModel: listAllGames.games

        sorters: RoleSorter {
            roleName: "title"
            sortOrder: sortAscending ? Qt.AscendingOrder : Qt.DescendingOrder
        }

        filters: [
            ExpressionFilter {
                enabled: showFavsOnly
                expression: model.favorite === true
            },
            ExpressionFilter {
                enabled: currentGenre !== "All" && currentGenre !== ""
                expression: model.genre.toLowerCase().includes(currentGenre.toLowerCase())
            }
        ]
    }

    function getCurrentGame(displayIndex) {
        var sourceIndex = displayModel.mapToSource(displayIndex);
        return listAllGames.currentGame(sourceIndex);
    }

    // ── Art selection: mirrors Game Details carousel settings ─────────────
    function is3dPath(path) {
        if (!path) return false;
        var p = path.toLowerCase();
        // Cover common scraper naming conventions for 3D box art
        return p.includes("box3d") || p.includes("box_3d") || p.includes("3dbox") ||
               p.includes("3d_box") || p.includes("-3d.") || p.includes("_3d.") ||
               p.includes("/3d/") || p.includes("\\3d\\");
    }

    function artSource(data) {
        if (!data) return "";
        var list = data.assets.boxFrontList;

        // Miximage
        if (settings.CarouselMiximage === "Yes") {
            if (data.assets.miximage)  return data.assets.miximage;
            if (data.assets.mix_image) return data.assets.mix_image;
        }

        // 3D box art
        if (settings.Carousel3DBox === "Yes" && list) {
            for (var i = 0; i < list.length; i++)
                if (is3dPath(list[i])) return list[i];
            // No 3D file detected — if 2D is also enabled fall through,
            // otherwise use first entry as best guess
            if (settings.Carousel2DBox !== "Yes" && list.length > 0)
                return list[list.length > 1 ? 1 : 0]; // prefer last entry (often 3D)
        }

        // 2D box art
        if (settings.Carousel2DBox === "Yes") {
            if (list) {
                for (var j = 0; j < list.length; j++)
                    if (!is3dPath(list[j])) return list[j];
            }
            if (data.assets.boxFront) return data.assets.boxFront;
        }

        // Last resort: show something rather than blank
        if (data.assets.boxFront)  return data.assets.boxFront;
        if (data.assets.boxBack)   return data.assets.boxBack;
        if (data.assets.poster)    return data.assets.poster;
        if (data.assets.banner)    return data.assets.banner;
        if (data.assets.cartridge) return data.assets.cartridge;
        if (data.assets.miximage)  return data.assets.miximage;
        return "";
    }

    // ── Letter jump helper ────────────────────────────────────────────────
    function jumpToNextLetter() {
        if (gamelist.count === 0) return;
        var current = gamelist.currentIndex;
        var currentTitle = displayModel.count > current
            ? displayModel.get(current).title || "" : "";
        var currentLetter = currentTitle.charAt(0).toUpperCase();

        // Find first game starting with a letter after the current one
        for (var i = current + 1; i < gamelist.count; i++) {
            var t = displayModel.get(i).title || "";
            if (t.charAt(0).toUpperCase() !== currentLetter) {
                gamelist.currentIndex = i;
                return;
            }
        }
        // Wrap to beginning
        gamelist.currentIndex = 0;
    }

    function jumpToPrevLetter() {
        if (gamelist.count === 0) return;
        var current = gamelist.currentIndex;
        if (current <= 0) { gamelist.currentIndex = gamelist.count - 1; return; }
        var prevTitle = displayModel.count > (current - 1)
            ? displayModel.get(current - 1).title || "" : "";
        var prevLetter = prevTitle.charAt(0).toUpperCase();

        // Find the start of the previous letter group
        for (var i = current - 2; i >= 0; i--) {
            var t = displayModel.get(i).title || "";
            if (t.charAt(0).toUpperCase() !== prevLetter) {
                gamelist.currentIndex = i + 1;
                return;
            }
        }
        gamelist.currentIndex = 0;
    }

    // ── Right panel: box art + game info ──────────────────────────────────
    Item {
    id: rightPanel

        anchors {
            top: header.bottom
            left: gamelist.right
            right: parent.right
            bottom: parent.bottom
        }

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

    // ── Header ────────────────────────────────────────────────────────────
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
            anchors { left: parent.left; leftMargin: globalMargin; verticalCenter: parent.verticalCenter }
            height: vpx(40); width: vpx(40)
            fillMode: Image.PreserveAspectFit
            smooth: true; asynchronous: true
        }

        Text {
            anchors { left: libraryIcon.right; leftMargin: vpx(12); verticalCenter: parent.verticalCenter }
            text: "My Games & Apps"
            color: theme.text
            font.family: titleFont.name
            font.pixelSize: vpx(24)
            font.bold: true
        }

        // Filter status row
        Row {
            anchors { right: parent.right; rightMargin: globalMargin; verticalCenter: parent.verticalCenter }
            spacing: vpx(12)

            Text {
                text: sortAscending ? "↑ A→Z" : "↓ Z→A"
                color: theme.accent
                font.family: subtitleFont.name
                font.pixelSize: vpx(16)
                font.bold: true
            }

            Text {
                visible: currentGenre !== "All"
                text: currentGenre
                color: theme.accent
                font.family: subtitleFont.name
                font.pixelSize: vpx(16)
                font.bold: true
            }

            Text {
                visible: showFavsOnly
                text: "★ Favorites"
                color: theme.accent
                font.family: subtitleFont.name
                font.pixelSize: vpx(16)
                font.bold: true
            }
        }

        Text {
            anchors { left: parent.left; leftMargin: globalMargin; bottom: parent.bottom; bottomMargin: vpx(6) }
            text: displayModel.count + (displayModel.count !== listAllGames.max ? " / " + listAllGames.max : "") + " games"
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
                        else gamelist.currentIndex = index;
                    }
                }
            }
        }
    }

    // ── Input ─────────────────────────────────────────────────────────────
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
        // B — back
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            previousScreen();
        }
        // X — cycle genre filter
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (genreList.length > 0) {
                genreIndex = (genreIndex + 1) % genreList.length;
                currentGenre = genreList[genreIndex];
                showFavsOnly = false;
                gamelist.currentIndex = 0;
            }
        }
        // Y — settings
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            settingsScreen();
        }
        // L1 — toggle sort direction
        if (api.keys.isPageUp(event) && !event.isAutoRepeat) {
            event.accepted = true;
            sortAscending = !sortAscending;
            gamelist.currentIndex = 0;
        }
        // R1 — jump to next letter group
        if (api.keys.isPageDown(event) && !event.isAutoRepeat) {
            event.accepted = true;
            jumpToNextLetter();
        }
    }

    ListModel {
        id: allGamesHelpModel
        ListElement { name: "Back";         button: "cancel"  }
        ListElement { name: "Genre";        button: "details" }
        ListElement { name: "Settings";     button: "filters" }
        ListElement { name: "View details"; button: "accept"  }
    }

    onFocusChanged: { if (focus) currentHelpbarModel = allGamesHelpModel; }
}
