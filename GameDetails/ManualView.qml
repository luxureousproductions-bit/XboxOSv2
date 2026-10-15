// XboxOS-V2
// Fullscreen game manual reader.
//
// Pages come from Pegasus itself: `image://pdf/<page>/<path>` renders one
// page of a PDF and `api.pdfPageCount(path)` counts them. Both exist only in
// Pegasus builds with PDF support (the XOS fork); GameView checks for
// api.pdfPageCount before ever showing this view, so on stock Pegasus the
// Manual button simply never appears.
//
// Controls:
//   A  bookmark / un-bookmark the page (kept per manual in api.memory)
//   X  View: 1 page / 2 pages, paired like the printed booklet
//      (cover alone, then 2-3, 4-5, ...); shown bottom left
//   Y  page overview grid (in the overview: X = bookmarks only)
//   B  back
//   LB / RB  zoom out / in, in steps (Fit, 150%, 200%, 250%, 300%);
//      shown top centre. Zoomed, the D-pad pans and left/right at the
//      page edge turn the page
//   LT/RT  5 pages back / forward (not shown in any prompt)
//   left/right turn pages
// The help bar shows A, X, Y, B in the theme's usual order.
// Manuals scanned as two-page spreads (wide pages) are detected and shown
// edge to edge, with View fixed to 1 page. Always opens on page 1.

import QtQuick 2.15
import "../utils.js" as Utils

FocusScope {
id: root

    signal close

    property string pdfPath: ""
    property string gameTitle: ""
    property int pageCount: 0
    property int page: 0
    property int zoomStep: 0                    // index into zoomLevels
    readonly property var zoomLevels: [1, 1.5, 2, 2.5, 3]
    readonly property real zoomFactor: zoomLevels[zoomStep]
    readonly property bool zoomed: zoomStep > 0
    property bool spread: false
    property bool overview: false
    property bool overviewBookmarks: false      // overview shows bookmarks only
    property var bookmarks: []                  // sorted page indices
    property string toastText: ""

    // Layout: header on top, progress bar + the theme's help bar at the bottom
    readonly property real headerH: vpx(72)
    readonly property real footerH: vpx(78)
    readonly property real sideMargin: vpx(40)
    readonly property real availW: width - sideMargin * 2
    readonly property real availH: height - headerH - footerH

    // Spread-scanned manual: page 2 is wider than tall, i.e. each PDF page is
    // already two booklet pages. Probed once per manual at thumbnail size.
    readonly property bool spreadScan: spreadProbe.status === Image.Ready
                                       && spreadProbe.implicitWidth > spreadProbe.implicitHeight * 1.15
    // Pages use the full height (header/footer drawn over them) when zoomed
    // or for wide spread scans, which would otherwise shrink a lot. Not the
    // cover: that one is a normal portrait page even in spread scans.
    readonly property bool wideLayout: spreadScan && page > 0
    readonly property bool fullBleed: zoomed || wideLayout
    readonly property real pageAreaH: wideLayout ? height : availH

    // Booklet pairing: the cover (page 0) stands alone, then 1-2, 3-4, ...
    readonly property bool hasRightPage: spread && page > 0 && page + 1 < pageCount

    function spreadStart(index) {
        if (index <= 0) return 0;
        return (index % 2 === 1) ? index : index - 1;
    }
    function nextIndex() {
        if (!spread) return page + 1;
        return page === 0 ? 1 : page + 2;
    }
    function prevIndex() {
        if (!spread) return page - 1;
        return page <= 1 ? 0 : page - 2;
    }
    // --- Bookmarks ---
    function bookmarkKey() { return "Manual bookmarks - " + pdfPath; }

    function loadBookmarks() {
        var list = [];
        if (api.memory.has(bookmarkKey())) {
            try { list = JSON.parse(api.memory.get(bookmarkKey())); } catch (err) { list = []; }
        }
        bookmarks = Array.isArray(list) ? list.filter(function(i) { return i >= 0 && i < pageCount; }) : [];
    }

    function isBookmarked(index) { return bookmarks.indexOf(index) >= 0; }

    function toggleBookmark() {
        if (pageCount <= 0) return;
        var list = bookmarks.slice();
        var at = list.indexOf(page);
        if (at >= 0) {
            list.splice(at, 1);
            playBack();
            showToast("Bookmark removed");
        } else {
            list.push(page);
            list.sort(function(a, b) { return a - b; });
            playToggle();
            showToast("Bookmarked page " + (page + 1));
        }
        bookmarks = list;
        api.memory.set(bookmarkKey(), JSON.stringify(list));
    }

    // LT/RT: skip a few pages, staying on booklet pairs in two-page mode
    function jump(delta) {
        if (pageCount <= 0) return;
        var target = Math.max(0, Math.min(pageCount - 1, page + delta));
        goTo(spread ? spreadStart(target) : target);
    }

    function showToast(text) {
        toastText = text;
        toastTimer.restart();
    }

    // Pages listed in the overview: all of them, or bookmarks only
    readonly property var overviewPages: {
        if (!overview) return [];
        if (overviewBookmarks) return bookmarks.slice();
        var all = [];
        for (var i = 0; i < pageCount; i++) all.push(i);
        return all;
    }

    function overviewIndexOf(index) {
        var list = overviewPages;
        for (var i = 0; i < list.length; i++) {
            if (list[i] >= index) return i;
        }
        return Math.max(0, list.length - 1);
    }

    function pageUrl(index) {
        if (pdfPath === "" || index < 0 || index >= pageCount)
            return "";
        return "image://pdf/" + index + "/" + encodeURIComponent(pdfPath);
    }

    // Called by GameView before showing the view
    function open(path, title) {
        pdfPath = path;
        gameTitle = title;
        pageCount = api.pdfPageCount(path);
        zoomStep = 0;
        spread = false;
        overview = false;
        overviewBookmarks = false;
        toastText = "";
        page = 0;
        zoomFlick.contentX = 0;
        zoomFlick.contentY = 0;
        loadBookmarks();
        updateHelp();
    }

    onPageChanged: updateHelp()
    onBookmarksChanged: updateHelp()

    // fromEnd: entered by paging back while zoomed, so start at the right
    // edge (where reading of the previous page ended), not the left
    function goTo(index, fromEnd) {
        if (pageCount <= 0) return;
        var target = Math.max(0, Math.min(pageCount - 1, index));
        if (target === page) return;
        playNav();
        page = target;
        zoomFlick.contentY = 0;
        zoomFlick.contentX = fromEnd ? Math.max(0, zoomFlick.contentWidth - zoomFlick.width) : 0;
    }

    // LB/RB: change the zoom step, keeping the point at the centre of the
    // screen where it is (from Fit, zoom in on the middle of the page)
    function setZoom(step) {
        step = Math.max(0, Math.min(zoomLevels.length - 1, step));
        if (step === zoomStep || pageCount <= 0) return;
        var wasZoomed = zoomed;
        var fx = 0.5, fy = 0.5;
        if (wasZoomed && zoomFlick.contentWidth > 0 && zoomFlick.contentHeight > 0) {
            fx = (zoomFlick.contentX + zoomFlick.width / 2) / zoomFlick.contentWidth;
            fy = (zoomFlick.contentY + zoomFlick.height / 2) / zoomFlick.contentHeight;
        }
        playToggle();
        zoomStep = step;
        // content size is bound to zoomFactor, so it is already updated here
        var maxX = Math.max(0, zoomFlick.contentWidth - zoomFlick.width);
        var maxY = Math.max(0, zoomFlick.contentHeight - zoomFlick.height);
        zoomFlick.contentX = Math.max(0, Math.min(maxX, fx * zoomFlick.contentWidth - zoomFlick.width / 2));
        zoomFlick.contentY = Math.max(0, Math.min(maxY, fy * zoomFlick.contentHeight - zoomFlick.height / 2));
        updateHelp();
    }

    // X: View, 1 page / 2 pages
    function toggleSpread() {
        if (spreadScan) return;   // pages are already spreads
        playToggle();
        spread = !spread;
        if (spread) page = spreadStart(page);
        zoomFlick.contentX = 0;
        zoomFlick.contentY = 0;
        updateHelp();
    }

    function openOverview() {
        playToggle();
        overviewBookmarks = false;
        overview = true;
        pageGrid.currentIndex = overviewIndexOf(page);
        pageGrid.positionViewAtIndex(pageGrid.currentIndex, GridView.Center);
        updateHelp();
    }

    function toggleOverviewBookmarks() {
        if (!overviewBookmarks && bookmarks.length === 0) { showToast("No bookmarks yet"); return; }
        playToggle();
        var current = overviewPages[pageGrid.currentIndex];
        overviewBookmarks = !overviewBookmarks;
        pageGrid.currentIndex = overviewIndexOf(current === undefined ? page : current);
        pageGrid.positionViewAtIndex(pageGrid.currentIndex, GridView.Center);
        updateHelp();
    }

    // pick: a page index, or -1 to go back without moving
    function closeOverview(pick) {
        overview = false;
        overviewBookmarks = false;
        if (pick >= 0) goTo(spread ? spreadStart(pick) : pick);
        else playBack();
        updateHelp();
    }

    onSpreadScanChanged: {
        if (spreadScan && spread) {
            spread = false;
        }
        updateHelp();
    }

    function pan(delta) {
        var maxY = Math.max(0, zoomFlick.contentHeight - zoomFlick.height);
        zoomFlick.contentY = Math.max(0, Math.min(maxY, zoomFlick.contentY + delta));
    }

    // Zoomed left/right: pan, or turn the page once already at that edge
    function panOrTurn(forward) {
        var maxX = Math.max(0, zoomFlick.contentWidth - zoomFlick.width);
        if (forward) {
            if (zoomFlick.contentX >= maxX - 1) { goTo(nextIndex(), false); return; }
            zoomFlick.contentX = Math.min(maxX, zoomFlick.contentX + zoomFlick.width * 0.4);
        } else {
            if (zoomFlick.contentX <= 1) { goTo(prevIndex(), true); return; }
            zoomFlick.contentX = Math.max(0, zoomFlick.contentX - zoomFlick.width * 0.4);
        }
    }

    // Backdrop
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.95
    }

    // --- Full page / two pages ---
    Row {
    id: pageRow
        visible: !zoomed
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top; topMargin: wideLayout ? 0 : headerH
        }
        height: pageAreaH
        spacing: vpx(6)

        Image {
        id: leftPage
            source: root.visible ? pageUrl(page) : ""
            sourceSize: Qt.size(spread ? (availW - pageRow.spacing) / 2 : availW, pageAreaH)
            width: status === Image.Ready ? implicitWidth : 0
            height: status === Image.Ready ? implicitHeight : 0
            anchors.verticalCenter: parent.verticalCenter
            asynchronous: true
            smooth: true

            Ribbon {
                anchors { right: parent.right; rightMargin: vpx(18); top: parent.top; topMargin: -vpx(4) }
                visible: leftPage.status === Image.Ready && isBookmarked(page)
            }
        }
        Image {
        id: rightPage
            source: root.visible && hasRightPage ? pageUrl(page + 1) : ""
            sourceSize: Qt.size((availW - pageRow.spacing) / 2, availH)
            visible: hasRightPage
            width: status === Image.Ready ? implicitWidth : 0
            height: status === Image.Ready ? implicitHeight : 0
            anchors.verticalCenter: parent.verticalCenter
            asynchronous: true
            smooth: true

            Ribbon {
                anchors { right: parent.right; rightMargin: vpx(18); top: parent.top; topMargin: -vpx(4) }
                visible: rightPage.status === Image.Ready && isBookmarked(page + 1)
            }
        }
    }

    // --- Zoom: the current view (1 or 2 pages) scaled by zoomFactor ---
    // Sizes come from the fit view, so they are known before the sharper
    // render arrives; the fit render is stretched underneath meanwhile.
    readonly property real zoomPageW: leftPage.width * zoomFactor
    readonly property real zoomPageH: leftPage.height * zoomFactor
    readonly property real zoomRightW: hasRightPage ? rightPage.width * zoomFactor : 0
    readonly property real zoomRowW: zoomPageW + (hasRightPage ? pageRow.spacing * zoomFactor + zoomRightW : 0)
    readonly property real zoomRowH: Math.max(zoomPageH, hasRightPage ? rightPage.height * zoomFactor : 0)

    Flickable {
    id: zoomFlick
        visible: zoomed
        anchors {
            left: parent.left; leftMargin: sideMargin
            right: parent.right; rightMargin: sideMargin
            top: parent.top; topMargin: headerH
            bottom: parent.bottom; bottomMargin: footerH
        }
        clip: true
        contentWidth: Math.max(width, zoomRowW)
        contentHeight: Math.max(height, zoomRowH)
        boundsBehavior: Flickable.StopAtBounds
        interactive: zoomed

        Item {
        id: zoomRow
            // centred while smaller than the screen in that direction
            x: Math.max(0, (zoomFlick.width - zoomRowW) / 2)
            y: Math.max(0, (zoomFlick.height - zoomRowH) / 2)
            width: zoomRowW
            height: zoomRowH

            Image {   // placeholder: the fit render, stretched
                x: 0
                anchors.verticalCenter: parent.verticalCenter
                width: zoomPageW; height: zoomPageH
                visible: zoomLeft.status !== Image.Ready
                source: leftPage.source
                sourceSize: leftPage.sourceSize
                asynchronous: true
            }
            Image {
            id: zoomLeft
                x: 0
                anchors.verticalCenter: parent.verticalCenter
                width: zoomPageW; height: zoomPageH
                source: root.visible && zoomed && leftPage.status === Image.Ready ? pageUrl(page) : ""
                sourceSize: Qt.size(Math.round(zoomPageW), 0)
                asynchronous: true
                smooth: true

                Ribbon {
                    anchors { right: parent.right; rightMargin: vpx(24); top: parent.top; topMargin: -vpx(4) }
                    width: vpx(34)
                    visible: isBookmarked(page)
                }
            }
            Image {   // placeholder for the right-hand page
                x: zoomRowW - zoomRightW
                anchors.verticalCenter: parent.verticalCenter
                width: zoomRightW; height: hasRightPage ? rightPage.height * zoomFactor : 0
                visible: hasRightPage && zoomRight.status !== Image.Ready
                source: rightPage.source
                sourceSize: rightPage.sourceSize
                asynchronous: true
            }
            Image {
            id: zoomRight
                x: zoomRowW - zoomRightW
                anchors.verticalCenter: parent.verticalCenter
                width: zoomRightW; height: hasRightPage ? rightPage.height * zoomFactor : 0
                visible: hasRightPage
                source: root.visible && zoomed && hasRightPage && rightPage.status === Image.Ready ? pageUrl(page + 1) : ""
                sourceSize: Qt.size(Math.max(1, Math.round(zoomRightW)), 0)
                asynchronous: true
                smooth: true

                Ribbon {
                    anchors { right: parent.right; rightMargin: vpx(24); top: parent.top; topMargin: -vpx(4) }
                    width: vpx(34)
                    visible: isBookmarked(page + 1)
                }
            }
        }

        // Touch: a tap (not a drag) goes back to Fit
        MouseArea {
            width: zoomFlick.contentWidth
            height: zoomFlick.contentHeight
            onClicked: setZoom(0)
        }
    }

    // Mini-map while zoomed: the whole view with the visible part outlined
    Rectangle {
    id: miniMap
        visible: zoomed && leftPage.status === Image.Ready && zoomRowW > 0
        anchors {
            right: parent.right; rightMargin: sideMargin + vpx(8)
            top: parent.top; topMargin: headerH + vpx(8)
        }
        width: hasRightPage ? vpx(160) : vpx(110)
        height: zoomRowW > 0 ? width * zoomRowH / zoomRowW : 0
        color: "white"
        border { width: vpx(2); color: theme.accent }

        Row {
            anchors.fill: parent
            anchors.margins: parent.border.width
            Image {
                width: hasRightPage ? parent.width * zoomPageW / zoomRowW : parent.width
                height: parent.height
                source: miniMap.visible ? leftPage.source : ""
                sourceSize: leftPage.sourceSize
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            Image {
                visible: hasRightPage
                width: hasRightPage ? parent.width * zoomRightW / zoomRowW : 0
                height: parent.height
                source: miniMap.visible && hasRightPage ? rightPage.source : ""
                sourceSize: rightPage.sourceSize
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
        }
        Item {
            readonly property real cw: zoomFlick.contentWidth
            readonly property real ch: zoomFlick.contentHeight
            readonly property real ox: (cw - zoomRowW) / 2 > 0 ? (cw - zoomRowW) / 2 : 0
            readonly property real oy: (ch - zoomRowH) / 2 > 0 ? (ch - zoomRowH) / 2 : 0
            x: parent.width * Math.max(0, zoomFlick.contentX - ox) / zoomRowW
            y: parent.height * Math.max(0, zoomFlick.contentY - oy) / zoomRowH
            width: parent.width * Math.min(1, zoomFlick.width / zoomRowW)
            height: parent.height * Math.min(1, zoomFlick.height / zoomRowH)

            // theme.accent is a hex string, so tint with opacity, not rgba()
            Rectangle {
                anchors.fill: parent
                color: theme.accent
                opacity: 0.2
            }
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border { width: vpx(2); color: theme.accent }
            }
        }
    }

    // Preload the neighbours so page turns are instant. Same url + sourceSize
    // as the visible pages, so they land in the same image cache entries.
    Repeater {
        model: {
            if (!root.visible || overview || pageCount <= 0) return [];
            var next = nextIndex();
            var prev = prevIndex();
            // in two-page mode, also the right-hand pages of both neighbours
            return spread ? [prev, prev + 1, next, next + 1] : [prev, next];
        }
        Image {
            visible: false
            asynchronous: true
            source: pageUrl(modelData)
            sourceSize: leftPage.sourceSize
        }
    }

    // Spread-scan detection: page 2 rendered tiny, only its shape matters
    Image {
    id: spreadProbe
        visible: false
        asynchronous: true
        source: root.visible && pageCount > 1 ? pageUrl(1) : ""
        sourceSize: Qt.size(vpx(64), vpx(64))
    }

    // Loading / error message
    Text {
        anchors.centerIn: parent
        visible: text !== ""
        text: {
            if (pageCount <= 0) return "This manual couldn't be opened";
            if (leftPage.status === Image.Error) return "This page couldn't be shown";
            if (leftPage.status === Image.Loading) return "Loading page…";
            return "";
        }
        color: "#ebebeb"
        opacity: 0.8
        font { family: bodyFont.name; pixelSize: vpx(20) }
    }

    // --- Page overview (X): every page as a thumbnail ---
    Item {
    id: overviewLayer
        anchors.fill: parent
        visible: overview

        Rectangle {
            anchors.fill: parent
            color: "black"
        }

        GridView {
        id: pageGrid
            anchors {
                left: parent.left; leftMargin: sideMargin
                right: parent.right; rightMargin: sideMargin
                top: parent.top; topMargin: headerH
                bottom: parent.bottom; bottomMargin: footerH
            }
            clip: true
            readonly property int columns: Math.max(3, Math.floor(width / vpx(200)))
            cellWidth: width / columns
            cellHeight: cellWidth * 1.4
            cacheBuffer: cellHeight * 2
            model: overviewPages
            keyNavigationWraps: false
            highlightMoveDuration: 120

            delegate: Item {
                width: pageGrid.cellWidth
                height: pageGrid.cellHeight
                readonly property bool isCurrent: GridView.isCurrentItem
                readonly property int pageIndex: modelData

                Rectangle {
                id: thumbFrame
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top; topMargin: vpx(8)
                    }
                    width: parent.width - vpx(40)
                    height: parent.height - vpx(52)
                    radius: vpx(4)
                    color: "#202020"
                    border { width: isCurrent ? vpx(3) : 0; color: theme.accent }

                    Image {
                        anchors.fill: parent
                        anchors.margins: vpx(5)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        source: pageUrl(pageIndex)
                        sourceSize: Qt.size(Math.round(width), Math.round(height))
                    }
                    Ribbon {
                        anchors { right: parent.right; rightMargin: vpx(10); top: parent.top; topMargin: -vpx(2) }
                        width: vpx(16)
                        visible: isBookmarked(pageIndex)
                    }
                }
                Text {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: thumbFrame.bottom; topMargin: vpx(8)
                    }
                    text: pageIndex + 1
                    color: isCurrent ? theme.accent : "#bbbbbb"
                    font { family: titleFont.name; pixelSize: vpx(15) }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: closeOverview(pageIndex)
                }
            }
        }
    }

    // Header: title on the left, page counter on the right, and the zoom
    // control (LB  Zoom <level>  RB) top centre
    Row {
    id: zoomPrompt
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.top; verticalCenterOffset: headerH / 2
        }
        z: 1
        spacing: vpx(14)
        visible: !overview && pageCount > 0

        Image {
            anchors.verticalCenter: parent.verticalCenter
            source: "../assets/images/controller/" + Utils.processButtonArt("prevPage") + ".png"
            width: vpx(30); height: vpx(30)
            sourceSize { width: Math.round(vpx(30) * 2); height: Math.round(vpx(30) * 2) }
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: zoomStep > 0 ? 1 : 0.35   // nothing to zoom out of at Fit
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: vpx(8)
            Text {
                text: "Zoom"
                color: "white"
                font { family: subtitleFont.name; pixelSize: fpx(17) }
            }
            Text {
                text: zoomStep === 0 ? "Fit" : Math.round(zoomFactor * 100) + "%"
                color: theme.accent
                font { family: subtitleFont.name; pixelSize: fpx(17) }
            }
        }
        Image {
            anchors.verticalCenter: parent.verticalCenter
            source: "../assets/images/controller/" + Utils.processButtonArt("nextPage") + ".png"
            width: vpx(30); height: vpx(30)
            sourceSize { width: Math.round(vpx(30) * 2); height: Math.round(vpx(30) * 2) }
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: zoomStep < zoomLevels.length - 1 ? 1 : 0.35
        }
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: headerH
        color: "black"
        opacity: fullBleed ? 0.82 : 0
    }
    Column {
        anchors {
            left: parent.left; leftMargin: sideMargin
            verticalCenter: parent.top; verticalCenterOffset: headerH / 2
        }
        // Up to the zoom control
        width: Math.max(vpx(160), root.width / 2 - vpx(150) - sideMargin)
        Text {
            text: overview ? (overviewBookmarks ? "MANUAL · BOOKMARKS" : "MANUAL · PAGES")
                           : (zoomed ? "MANUAL · ZOOM" : "MANUAL")
            color: "#9a9a9a"
            font { family: bodyFont.name; pixelSize: vpx(13); letterSpacing: vpx(1) }
        }
        Text {
            width: parent.width
            text: gameTitle
            elide: Text.ElideRight
            color: "white"
            font { family: titleFont.name; pixelSize: vpx(22) }
        }
    }
    Row {
        anchors {
            right: parent.right; rightMargin: sideMargin
            verticalCenter: parent.top; verticalCenterOffset: headerH / 2
        }
        visible: pageCount > 0
        Text {
            text: overview ? ((overviewPages[pageGrid.currentIndex] !== undefined ? overviewPages[pageGrid.currentIndex] : page) + 1)
                           : (hasRightPage ? (page + 1) + "–" + (page + 2) : (page + 1))
            color: "white"
            font { family: titleFont.name; pixelSize: vpx(20) }
        }
        Text {
            text: " / " + pageCount
            color: "#8a8a8a"
            font { family: titleFont.name; pixelSize: vpx(20) }
        }
    }

    // Footer: progress through the manual, above the theme's help bar
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: footerH
        color: "black"
        opacity: fullBleed ? 0.82 : 0
    }
    Rectangle {
    id: progressTrack
        anchors {
            left: parent.left; leftMargin: sideMargin
            right: parent.right; rightMargin: sideMargin
            bottom: parent.bottom; bottomMargin: vpx(60)
        }
        height: vpx(4)
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.15)
        visible: pageCount > 0

        Rectangle {
            height: parent.height
            radius: parent.radius
            width: pageCount > 0 ? parent.width * Math.min(pageCount, page + (hasRightPage ? 2 : 1)) / pageCount : 0
            color: theme.accent
            Behavior on width { NumberAnimation { duration: 150 } }
        }

        // Where the bookmarks are
        Repeater {
            model: pageCount > 0 ? bookmarks : []
            Rectangle {
                width: vpx(4)
                height: vpx(14)
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                x: progressTrack.width * (modelData + 0.5) / pageCount - width / 2
                color: theme.accent
                border { width: vpx(1); color: "black" }
            }
        }
    }

    // View, bottom left on the help bar's row (the bar sits at the bottom,
    // vpx(50) tall, its prompts laid out from its top)
    Row {
        anchors {
            left: parent.left; leftMargin: globalMargin
            verticalCenter: parent.bottom; verticalCenterOffset: -vpx(35)
        }
        spacing: vpx(6)
        visible: !overview && pageCount > 1 && !spreadScan
        Text {
            text: "View:"
            color: "#9a9a9a"
            font { family: subtitleFont.name; pixelSize: fpx(16) }
        }
        Text {
            text: spread ? "2 Pages" : "1 Page"
            color: "white"
            font { family: subtitleFont.name; pixelSize: fpx(16) }
        }
    }

    // Short confirmation, under the title
    Rectangle {
    id: toast
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top; topMargin: headerH + vpx(10)
        }
        width: toastLabel.implicitWidth + vpx(40)
        height: vpx(42)
        radius: vpx(6)
        color: "#1f1f1f"
        border { width: vpx(1); color: "#333333" }
        opacity: toastTimer.running ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: vpx(4)
            radius: vpx(2)
            color: theme.accent
        }
        Text {
        id: toastLabel
            anchors.centerIn: parent
            text: toastText
            color: "white"
            font { family: bodyFont.name; pixelSize: vpx(16) }
        }
    }
    Timer {
    id: toastTimer
        interval: 1600
    }

    // Touch: tap the left/right third to turn pages, the middle to zoom
    MouseArea {
        anchors.fill: parent
        enabled: !zoomed && !overview
        onClicked: {
            if (mouse.x < width / 3) goTo(prevIndex());
            else if (mouse.x > width * 2 / 3) goTo(nextIndex());
            else setZoom(1);
        }
    }

    // Input handling
    // Mouse back button: same as B
    function mouseBack() { close(); }

    Keys.onPressed: {
        // Modal: nothing reaches GameView while the manual is open
        event.accepted = true;
        if (appDrawerKeys.indexOf(event.key) >= 0) return;   // theme-root list

        if (overview) {
            if (event.isAutoRepeat && !(event.key === Qt.Key_Left || event.key === Qt.Key_Right
                                        || event.key === Qt.Key_Up || event.key === Qt.Key_Down))
                return;
            if (api.keys.isCancel(event) || api.keys.isFilters(event)) { closeOverview(-1); return; }
            if (api.keys.isDetails(event)) { toggleOverviewBookmarks(); return; }
            if (api.keys.isAccept(event)) {
                var picked = overviewPages[pageGrid.currentIndex];
                closeOverview(picked === undefined ? -1 : picked);
                return;
            }
            var before = pageGrid.currentIndex;
            switch (event.key) {
                case Qt.Key_Left:  pageGrid.moveCurrentIndexLeft(); break;
                case Qt.Key_Right: pageGrid.moveCurrentIndexRight(); break;
                case Qt.Key_Up:    pageGrid.moveCurrentIndexUp(); break;
                case Qt.Key_Down:  pageGrid.moveCurrentIndexDown(); break;
            }
            if (pageGrid.currentIndex !== before) playNav();
            return;
        }

        if (api.keys.isCancel(event)) {
            if (!event.isAutoRepeat) close();
            return;
        }
        if (api.keys.isAccept(event)) {
            if (!event.isAutoRepeat) toggleBookmark();
            return;
        }
        if (api.keys.isDetails(event)) {
            if (!event.isAutoRepeat && pageCount > 1) toggleSpread();
            return;
        }
        if (api.keys.isFilters(event)) {
            if (!event.isAutoRepeat && pageCount > 1) openOverview();
            return;
        }
        if (api.keys.isPrevPage(event)) { if (!event.isAutoRepeat) setZoom(zoomStep - 1); return; }
        if (api.keys.isNextPage(event)) { if (!event.isAutoRepeat) setZoom(zoomStep + 1); return; }
        // Triggers: 5 pages at a time, holding repeats
        if (api.keys.isPageUp(event))   { jump(-5); return; }
        if (api.keys.isPageDown(event)) { jump(5); return; }

        switch (event.key) {
            case Qt.Key_Left:  if (zoomed) panOrTurn(false); else goTo(prevIndex()); break;
            case Qt.Key_Right: if (zoomed) panOrTurn(true); else goTo(nextIndex()); break;
            case Qt.Key_Up:    if (zoomed) pan(-zoomFlick.height * 0.4); break;
            case Qt.Key_Down:  if (zoomed) pan(zoomFlick.height * 0.4); break;
        }
    }

    // Helpbar buttons
    // Rebuilt by updateHelp() so the labels follow the current mode
    ListModel {
        id: manualviewHelpModel
    }

    // The help bar lays its model out right to left, so the entries go in
    // as B, Y, X, A to read A, X, Y, B on screen like the rest of the theme.
    // LB/RB (zoom) have their own prompt top centre; LT/RT are never shown.
    function updateHelp() {
        manualviewHelpModel.clear();
        manualviewHelpModel.append({ name: "Back", button: "cancel" });
        if (overview) {
            if (bookmarks.length > 0)
                manualviewHelpModel.append({ name: overviewBookmarks ? "All pages" : "Bookmarks", button: "details" });
            manualviewHelpModel.append({ name: "Go to page", button: "accept" });
            return;
        }
        if (pageCount > 1)
            manualviewHelpModel.append({ name: "Pages", button: "filters" });
        if (pageCount > 1 && !spreadScan)
            manualviewHelpModel.append({ name: "View", button: "details" });
        manualviewHelpModel.append({ name: isBookmarked(page) ? "Remove bookmark" : "Bookmark", button: "accept" });
    }

    onFocusChanged: {
        if (focus) {
            currentHelpbarModel = manualviewHelpModel;
        }
    }
}
