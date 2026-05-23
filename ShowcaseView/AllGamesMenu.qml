import QtQuick 2.15
import QtQuick.Layouts 1.11
import "../Global"
import "../Lists"
import SortFilterProxyModel 0.2

FocusScope {
id: root

    property real itemheight: vpx(50)
    property int  skipnum: 10

    // ── Data ──────────────────────────────────────────────────────────────
    ListAllGames {
    id: listAllGames
        max: api.allGames.count
    }

    // ── Filter state ──────────────────────────────────────────────────────
    property string selectedGenre:   "All"
    property string selectedRating:  "All"
    property bool   sortAscending:   true
    property bool   filterOpen:      false
    property int    filterRow:       0
    property var    genreList:       ["All"]
    property var    ratingList:      ["All"]

    // filterRevision increments whenever a filter value changes, forcing
    // ExpressionFilter to re-evaluate even when enabled stays true
    property int filterRevision: 0
    onSelectedGenreChanged:  filterRevision++
    onSelectedRatingChanged: filterRevision++
    onSortAscendingChanged:  filterRevision++

    // ── Display model ─────────────────────────────────────────────────────
    SortFilterProxyModel {
    id: displayModel
        sourceModel: listAllGames.games

        sorters: RoleSorter {
            roleName:  "title"
            sortOrder: sortAscending ? Qt.AscendingOrder : Qt.DescendingOrder
        }

        filters: [
            ExpressionFilter {
                enabled: selectedGenre !== "All"
                expression: {
                    var _force = root.filterRevision;
                    return (model.genre || "").toLowerCase().indexOf(root.selectedGenre.toLowerCase()) >= 0;
                }
            },
            ExpressionFilter {
                enabled: selectedRating !== "All"
                expression: {
                    var _force = root.filterRevision;
                    return Math.round(model.rating) === parseInt(root.selectedRating, 10);
                }
            }
        ]
    }

    function getCurrentGame(idx) {
        return listAllGames.currentGame(displayModel.mapToSource(idx));
    }

    // ── Art: follows settings.BoxArtStyle ────────────────────────────────
    function is3dPath(p) {
        if (!p) return false;
        var l = p.toLowerCase();
        return l.includes("box3d") || l.includes("box_3d") || l.includes("3dbox") ||
               l.includes("3d_box") || l.includes("-3d.") || l.includes("_3d.") ||
               l.includes("/3d/");
    }

    function artSource(data) {
        if (!data) return "";
        var style = settings.BoxArtStyle || "2D";
        var list  = data.assets.boxFrontList;
        var steam = data.assets.steamList;

        if (style === "Miximage") {
            if (data.assets.miximage)  return data.assets.miximage;
            if (data.assets.mix_image) return data.assets.mix_image;
            // steamgrid folder — Skraper stores mix images here
            if (steam && steam.length > 0) return steam[0];
        }
        if (style === "3D" && list) {
            for (var i = 0; i < list.length; i++) if (is3dPath(list[i])) return list[i];
            if (list.length > 1) return list[1];
        }
        if (list) {
            for (var j = 0; j < list.length; j++) if (!is3dPath(list[j])) return list[j];
        }
        return data.assets.boxFront || data.assets.boxBack ||
               data.assets.poster   || data.assets.miximage || "";
    }

    // ── L1/R1 alphabet jump ───────────────────────────────────────────────
    function jumpToNextLetter() {
        if (softwarelist.count === 0) return;
        var cur    = softwarelist.currentIndex;
        var curLtr = cur >= 0 && displayModel.get(cur)
                     ? (displayModel.get(cur).title || "").charAt(0).toUpperCase() : "";
        for (var i = cur + 1; i < softwarelist.count; i++) {
            var entry = displayModel.get(i);
            if (entry && (entry.title || "").charAt(0).toUpperCase() !== curLtr) {
                softwarelist.currentIndex = i; return;
            }
        }
        softwarelist.currentIndex = 0;
    }

    function jumpToPrevLetter() {
        if (softwarelist.count === 0) return;
        var cur = softwarelist.currentIndex;
        if (cur <= 0) { softwarelist.currentIndex = softwarelist.count - 1; return; }
        var prevEntry = displayModel.get(cur - 1);
        var prevLtr   = prevEntry ? (prevEntry.title || "").charAt(0).toUpperCase() : "";
        for (var i = cur - 2; i >= 0; i--) {
            var entry = displayModel.get(i);
            if (entry && (entry.title || "").charAt(0).toUpperCase() !== prevLtr) {
                softwarelist.currentIndex = i + 1; return;
            }
        }
        softwarelist.currentIndex = 0;
    }

    // ── Header ────────────────────────────────────────────────────────────
    Item {
    id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(75)

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
            text: displayModel.count + " games"
            color: theme.text; opacity: 0.7; font.family: subtitleFont.name; font.pixelSize: vpx(14)
        }

        // ── Nav buttons (exact from ShowcaseViewMenu) ──────────────────────
        Rectangle {
        id: ag_homebutton
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -vpx(81) }
            color: focus ? theme.accent : "transparent"; opacity: focus ? 1 : 0.6

            Keys.onDownPressed:  { softwarelist.focus = true; }
            Keys.onRightPressed: { ag_discoverbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; showcaseScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; softwarelist.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: showcaseScreen(); }

            Image {
                anchors { fill: parent; margins: vpx(2) }
                source: "../assets/images/gamesandapps.png"
                fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
            }
        }

        Rectangle {
        id: ag_discoverbutton
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -vpx(27) }
            color: focus ? theme.accent : "transparent"; opacity: focus ? 1 : 0.6

            Keys.onDownPressed:  { softwarelist.focus = true; }
            Keys.onLeftPressed:  { ag_homebutton.focus = true; }
            Keys.onRightPressed: { ag_achievementsbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; discoverScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; softwarelist.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: discoverScreen(); }

            Canvas {
                anchors { fill: parent; margins: vpx(6) }
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset();
                    var cx = width/2, cy = height/2, r = Math.min(cx,cy)-1;
                    ctx.globalAlpha = ag_discoverbutton.focus ? 1.0 : 0.85;
                    ctx.strokeStyle = "white"; ctx.lineWidth = 1.5;
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2); ctx.stroke();
                    ctx.fillStyle = "white";
                    ctx.beginPath(); ctx.moveTo(cx, cy-r*0.65); ctx.lineTo(cx+r*0.30, cy+r*0.10); ctx.lineTo(cx, cy+r*0.20); ctx.lineTo(cx-r*0.30, cy+r*0.10); ctx.closePath(); ctx.fill();
                    ctx.globalAlpha = 0.35;
                    ctx.beginPath(); ctx.moveTo(cx, cy+r*0.65); ctx.lineTo(cx-r*0.30, cy-r*0.10); ctx.lineTo(cx, cy-r*0.20); ctx.lineTo(cx+r*0.30, cy-r*0.10); ctx.closePath(); ctx.fill();
                }
                Connections { target: ag_discoverbutton; onFocusChanged: parent.requestPaint() }
            }
        }

        Rectangle {
        id: ag_achievementsbutton
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: vpx(27) }
            color: focus ? theme.accent : "transparent"; opacity: focus ? 1 : 0.6

            Keys.onDownPressed:  { softwarelist.focus = true; }
            Keys.onLeftPressed:  { ag_discoverbutton.focus = true; }
            Keys.onRightPressed: { ag_settingsbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; achievementsScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; softwarelist.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: achievementsScreen(); }
        }

        Text {
            text: "🏆"
            anchors.centerIn: ag_achievementsbutton
            font.pixelSize: vpx(18)
            opacity: ag_achievementsbutton.focus ? 1 : 0.7
        }

        Rectangle {
        id: ag_settingsbutton
            width: vpx(36); height: vpx(36); radius: height/2
            anchors { top: parent.top; topMargin: vpx(6); horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: vpx(81) }
            color: focus ? theme.accent : "transparent"; opacity: focus ? 1 : 0.6

            Keys.onDownPressed: { softwarelist.focus = true; }
            Keys.onLeftPressed: { ag_achievementsbutton.focus = true; }
            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) { event.accepted = true; settingsScreen(); }
                if (api.keys.isCancel(event) && !event.isAutoRepeat) { event.accepted = true; softwarelist.focus = true; }
            }
            MouseArea { anchors.fill: parent; onClicked: settingsScreen(); }

            Image {
                anchors { fill: parent; margins: vpx(10) }
                source: "../assets/images/settingsicon.svg"
                fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
            }
        }
    }

    // ── Box art ───────────────────────────────────────────────────────────
    Image {
    id: boxArt
        anchors {
            top: header.bottom; topMargin: globalMargin
            left: softwarelist.right; leftMargin: globalMargin
            right: parent.right; rightMargin: globalMargin
            bottom: parent.bottom; bottomMargin: globalMargin + helpMargin
        }
        asynchronous: true
        source: currentGame ? artSource(currentGame) : ""
        fillMode: Image.PreserveAspectFit; smooth: true
    }

    // ── Game list ─────────────────────────────────────────────────────────
    ListView {
    id: softwarelist
        focus: true
        currentIndex: currentGameIndex

        onCurrentIndexChanged: {
            if (currentIndex !== -1) {
                currentGameIndex = currentIndex;
                currentGame = getCurrentGame(currentIndex);
            }
        }

        Keys.onUpPressed: {
            event.accepted = true;
            if (currentIndex > 0) currentIndex--;
            else ag_homebutton.focus = true;
        }

        anchors {
            top: header.bottom; topMargin: globalMargin
            bottom: parent.bottom; bottomMargin: globalMargin
            left: parent.left
        }
        width: vpx(400); clip: true
        spacing: vpx(0); orientation: ListView.Vertical
        preferredHighlightBegin: softwarelist.height / 2 - itemheight
        preferredHighlightEnd:   softwarelist.height / 2
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 100

        model: displayModel

        delegate: Component {
            Item {
                width: ListView.view.width; height: itemheight
                property bool selected: ListView.isCurrentItem

                Rectangle {
                    width: vpx(3)
                    anchors { left: parent.left; leftMargin: vpx(11); top: parent.top; topMargin: vpx(5); bottom: parent.bottom; bottomMargin: vpx(5) }
                    color: theme.text; visible: selected
                }
                Text {
                    text: modelData.title; height: parent.height
                    anchors { left: parent.left; leftMargin: vpx(25); right: parent.right; rightMargin: vpx(10) }
                    color: theme.text; font.family: subtitleFont.name; font.pixelSize: vpx(20)
                    elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
                    opacity: selected ? 1.0 : 0.2
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { if (selected) gameDetails(currentGame); else softwarelist.currentIndex = index; }
                }
            }
        }
    }

    // ── Filter panel ──────────────────────────────────────────────────────
    Rectangle {
    id: filterPanel
        visible: filterOpen; z: 20
        anchors { top: header.bottom; topMargin: vpx(20); right: parent.right; rightMargin: vpx(40) }
        width: vpx(440)
        height: vpx(60) + vpx(52) * 3 + vpx(36)
        radius: vpx(8); color: Qt.rgba(0.08, 0.08, 0.08, 0.97)

        Rectangle {
            anchors.fill: parent; radius: parent.radius
            color: "transparent"; border.color: theme.accent; border.width: 2
        }

        Column {
            anchors { fill: parent; margins: vpx(20) }
            spacing: vpx(6)

            Text {
                text: "Filters"; color: theme.text
                font.family: titleFont.name; font.pixelSize: vpx(20); font.bold: true
                height: vpx(30)
            }

            // Genre row
            Rectangle {
                width: parent.width; height: vpx(48); radius: vpx(6)
                color: filterRow === 0 ? Qt.rgba(1,1,1,0.10) : "transparent"
                Text {
                    anchors { left: parent.left; leftMargin: vpx(14); verticalCenter: parent.verticalCenter }
                    text: "Genre"
                    color: theme.text; opacity: 0.55; font.family: subtitleFont.name; font.pixelSize: vpx(14)
                }
                Text {
                    anchors.centerIn: parent
                    text: selectedGenre
                    color: filterRow === 0 ? theme.accent : theme.text
                    font.family: subtitleFont.name; font.pixelSize: vpx(18); font.bold: true
                }
                Text {
                    anchors { right: parent.right; rightMargin: vpx(14); verticalCenter: parent.verticalCenter }
                    text: "◀ ▶"; color: theme.text; opacity: filterRow === 0 ? 0.85 : 0.2; font.pixelSize: vpx(13)
                }
            }

            // Rating row
            Rectangle {
                width: parent.width; height: vpx(48); radius: vpx(6)
                color: filterRow === 1 ? Qt.rgba(1,1,1,0.10) : "transparent"
                Text {
                    anchors { left: parent.left; leftMargin: vpx(14); verticalCenter: parent.verticalCenter }
                    text: "Rating"
                    color: theme.text; opacity: 0.55; font.family: subtitleFont.name; font.pixelSize: vpx(14)
                }
                Text {
                    anchors.centerIn: parent
                    text: selectedRating === "All" ? "All" : "★ " + selectedRating
                    color: filterRow === 1 ? theme.accent : theme.text
                    font.family: subtitleFont.name; font.pixelSize: vpx(18); font.bold: true
                }
                Text {
                    anchors { right: parent.right; rightMargin: vpx(14); verticalCenter: parent.verticalCenter }
                    text: "◀ ▶"; color: theme.text; opacity: filterRow === 1 ? 0.85 : 0.2; font.pixelSize: vpx(13)
                }
            }

            // Sort row
            Rectangle {
                width: parent.width; height: vpx(48); radius: vpx(6)
                color: filterRow === 2 ? Qt.rgba(1,1,1,0.10) : "transparent"
                Text {
                    anchors { left: parent.left; leftMargin: vpx(14); verticalCenter: parent.verticalCenter }
                    text: "Sort"
                    color: theme.text; opacity: 0.55; font.family: subtitleFont.name; font.pixelSize: vpx(14)
                }
                Text {
                    anchors.centerIn: parent
                    text: sortAscending ? "A → Z" : "Z → A"
                    color: filterRow === 2 ? theme.accent : theme.text
                    font.family: subtitleFont.name; font.pixelSize: vpx(18); font.bold: true
                }
                Text {
                    anchors { right: parent.right; rightMargin: vpx(14); verticalCenter: parent.verticalCenter }
                    text: "◀ ▶"; color: theme.text; opacity: filterRow === 2 ? 0.85 : 0.2; font.pixelSize: vpx(13)
                }
            }

            Text {
                text: "▲▼ navigate    ◀ ▶ change    B close"
                color: theme.text; opacity: 0.35
                font.family: subtitleFont.name; font.pixelSize: vpx(13)
            }
        }

        Keys.onUpPressed:   { if (filterRow > 0) filterRow--; }
        Keys.onDownPressed: { if (filterRow < 2) filterRow++; }
        Keys.onLeftPressed: {
            if (filterRow === 0 && genreList.length > 1) {
                var gi = genreList.indexOf(selectedGenre);
                if (gi < 0) gi = 0;
                selectedGenre = genreList[(gi - 1 + genreList.length) % genreList.length];
                softwarelist.currentIndex = 0;
            } else if (filterRow === 1 && ratingList.length > 1) {
                var ri = ratingList.indexOf(selectedRating);
                if (ri < 0) ri = 0;
                selectedRating = ratingList[(ri - 1 + ratingList.length) % ratingList.length];
                softwarelist.currentIndex = 0;
            } else if (filterRow === 2) {
                sortAscending = !sortAscending;
                softwarelist.currentIndex = 0;
            }
        }
        Keys.onRightPressed: {
            if (filterRow === 0 && genreList.length > 1) {
                var gi = genreList.indexOf(selectedGenre);
                if (gi < 0) gi = 0;
                selectedGenre = genreList[(gi + 1) % genreList.length];
                softwarelist.currentIndex = 0;
            } else if (filterRow === 1 && ratingList.length > 1) {
                var ri = ratingList.indexOf(selectedRating);
                if (ri < 0) ri = 0;
                selectedRating = ratingList[(ri + 1) % ratingList.length];
                softwarelist.currentIndex = 0;
            } else if (filterRow === 2) {
                sortAscending = !sortAscending;
                softwarelist.currentIndex = 0;
            }
        }
        Keys.onPressed: {
            if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                event.accepted = true; filterOpen = false; softwarelist.focus = true;
            }
            if (api.keys.isDetails(event) && !event.isAutoRepeat) {
                event.accepted = true; filterOpen = false; softwarelist.focus = true;
            }
        }
    }

    // ── Global key handling ───────────────────────────────────────────────
    Keys.onDownPressed: {
        if (!filterOpen && softwarelist.focus) {
            if (softwarelist.currentIndex < softwarelist.count - 1) softwarelist.currentIndex++;
            else softwarelist.currentIndex = 0;
        }
    }
    Keys.onLeftPressed: {
        if (!filterOpen && softwarelist.focus)
            softwarelist.currentIndex = Math.max(0, softwarelist.currentIndex - skipnum);
    }
    Keys.onRightPressed: {
        if (!filterOpen && softwarelist.focus)
            softwarelist.currentIndex = Math.min(softwarelist.count - 1, softwarelist.currentIndex + skipnum);
    }

    Keys.onPressed: {
        // A — view details
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && softwarelist.focus) gameDetails(currentGame);
        }
        // B — back
        if (api.keys.isCancel(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && softwarelist.focus) previousScreen();
        }
        // X — filters
        if (api.keys.isDetails(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && softwarelist.focus) {
                filterOpen = true; filterRow = 0; filterPanel.forceActiveFocus();
            }
        }
        // Y — settings
        if (api.keys.isFilters(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen && softwarelist.focus) settingsScreen();
        }
        // L1 — jump to previous letter
        if (api.keys.isPageUp(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen) jumpToPrevLetter();
        }
        // R1 — jump to next letter
        if (api.keys.isPageDown(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (!filterOpen) jumpToNextLetter();
        }
    }

    // ── Helpbar ───────────────────────────────────────────────────────────
    ListModel {
    id: allGamesHelpModel
        ListElement { name: "View details"; button: "accept"  }
        ListElement { name: "Filters";      button: "details" }
        ListElement { name: "Settings";     button: "filters" }
        ListElement { name: "Back";         button: "cancel"  }
    }

    Component.onCompleted: {
        currentHelpbarModel     = allGamesHelpModel;
        currentCustomCollection = listAllGames.collection;
        try {
            var genres = {}, ratings = {};
            for (var i = 0; i < api.allGames.count; i++) {
                var g = api.allGames.get(i);
                if (!g) continue;
                var genreStr = String(g.genre || "");
                if (genreStr) {
                    genreStr.split(",").forEach(function(p) {
                        var t = p.trim(); if (t) genres[t] = true;
                    });
                }
                var r = g.rating;
                if (r !== undefined && r !== null) {
                    var rv = Math.round(r);
                    if (rv > 0) ratings[String(rv)] = true;
                }
            }
            var ga = Object.keys(genres).sort();
            ga.unshift("All"); genreList = ga;
            var ra = Object.keys(ratings).sort(function(a,b){ return Number(a)-Number(b); });
            ra.unshift("All"); ratingList = ra;
        } catch(e) {}
    }

    onFocusChanged: {
        if (focus) {
            currentHelpbarModel     = allGamesHelpModel;
            currentCustomCollection = listAllGames.collection;
        }
    }
}
