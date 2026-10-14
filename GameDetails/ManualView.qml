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
//   A  zoom: the page fills the width, up/down pans
//   X  bookmark / un-bookmark the page (kept per manual in api.memory)
//   Y  page overview grid (in the overview: X = bookmarks only)
//   B  back
//   LB one page / two pages, paired like the printed booklet
//      (cover alone, then 2-3, 4-5, ...)
//   RB next bookmark (wraps round to the first)
//   LT/RT  5 pages back / forward (not shown in any prompt)
//   left/right turn pages
// LB and RB have their own prompts in the header, either side of centre;
// the help bar shows A, X, Y, B in the theme's usual order.
// Manuals scanned as two-page spreads (wide pages) are detected and shown
// edge to edge, with the two-page mode turned off. Always opens on page 1.

import QtQuick 2.15
import "../utils.js" as Utils

FocusScope {
id: root

    signal close

    property string pdfPath: ""
    property string gameTitle: ""
    property int pageCount: 0
    property int page: 0
    property bool zoomed: false
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

    // RB: next bookmark after the current view, wrapping round to the first.
    // In two-page mode the right-hand page counts as part of the current view.
    function nextBookmark() {
        if (bookmarks.length === 0) { showToast("No bookmarks yet"); return; }
        var last = hasRightPage ? page + 1 : page;
        var target = bookmarks[0];
        for (var i = 0; i < bookmarks.length; i++) {
            if (bookmarks[i] > last) { target = bookmarks[i]; break; }
        }
        var dest = spread ? spreadStart(target) : target;
        if (dest === page) { showToast("No other bookmarks"); return; }
        goTo(dest);
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
        zoomed = false;
        spread = false;
        overview = false;
        overviewBookmarks = false;
        toastText = "";
        page = 0;
        zoomFlick.contentY = 0;
        loadBookmarks();
        updateHelp();
    }

    onPageChanged: updateHelp()
    onBookmarksChanged: updateHelp()

    function goTo(index) {
        if (pageCount <= 0) return;
        var target = Math.max(0, Math.min(pageCount - 1, index));
        if (target === page) return;
        playNav();
        page = target;
        zoomFlick.contentY = 0;
    }

    function toggleZoom() {
        playToggle();
        spread = false;
        zoomed = !zoomed;
        zoomFlick.contentY = 0;
        updateHelp();
    }

    function toggleSpread() {
        if (spreadScan) return;   // pages are already spreads
        playToggle();
        zoomed = false;
        spread = !spread;
        if (spread) page = spreadStart(page);
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
            source: root.visible && !zoomed ? pageUrl(page) : ""
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
            source: root.visible && hasRightPage && !zoomed ? pageUrl(page + 1) : ""
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

    // --- Zoom: page fills the width, up/down pans ---
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
        contentWidth: width
        contentHeight: zoomPage.height
        boundsBehavior: Flickable.StopAtBounds
        interactive: zoomed

        Image {
        id: zoomPage
            source: root.visible && zoomed ? pageUrl(page) : ""
            sourceSize: Qt.size(zoomFlick.width, 0)
            width: zoomFlick.width
            height: status === Image.Ready ? implicitHeight : zoomFlick.height
            asynchronous: true
            smooth: true

            // Touch: a tap (not a drag) returns to the full page
            MouseArea {
                anchors.fill: parent
                onClicked: toggleZoom()
            }

            Ribbon {
                anchors { right: parent.right; rightMargin: vpx(24); top: parent.top; topMargin: -vpx(4) }
                width: vpx(34)
                visible: zoomPage.status === Image.Ready && isBookmarked(page)
            }
        }
    }

    // Mini-map while zoomed: whole page with the visible part outlined
    Rectangle {
    id: miniMap
        visible: zoomed && zoomPage.status === Image.Ready
        anchors {
            right: parent.right; rightMargin: sideMargin + vpx(8)
            top: parent.top; topMargin: headerH + vpx(8)
        }
        width: vpx(110)
        height: zoomPage.height > 0 ? width * zoomPage.height / zoomPage.width : 0
        color: "white"
        border { width: vpx(2); color: theme.accent }

        Image {
            anchors.fill: parent
            anchors.margins: parent.border.width
            source: miniMap.visible ? pageUrl(page) : ""
            sourceSize: Qt.size(vpx(110), 0)
            asynchronous: true
        }
        Item {
            x: 0
            width: parent.width
            y: zoomFlick.contentHeight > 0 ? parent.height * zoomFlick.contentY / zoomFlick.contentHeight : 0
            height: zoomFlick.contentHeight > 0 ? parent.height * Math.min(1, zoomFlick.height / zoomFlick.contentHeight) : parent.height

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
            if (!root.visible || zoomed || overview || pageCount <= 0) return [];
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
            var img = zoomed ? zoomPage : leftPage;
            if (img.status === Image.Error) return "This page couldn't be shown";
            if (img.status === Image.Loading) return "Loading page…";
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

    // Header: title on the left, page counter on the right, and the LB/RB
    // prompts either side of centre (same icons as the help bar)
    readonly property real shoulderOffset: width * 0.17

    Row {
    id: lbPrompt
        anchors {
            horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: -shoulderOffset
            verticalCenter: parent.top; verticalCenterOffset: headerH / 2
        }
        z: 1
        spacing: vpx(8)
        visible: !overview && pageCount > 1 && !spreadScan

        Image {
            anchors.verticalCenter: parent.verticalCenter
            source: "../assets/images/controller/" + Utils.processButtonArt("prevPage") + ".png"
            width: vpx(30); height: vpx(30)
            sourceSize { width: Math.round(vpx(30) * 2); height: Math.round(vpx(30) * 2) }
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: spread ? "One page" : "Two pages"
            color: "white"
            font { family: subtitleFont.name; pixelSize: fpx(16) }
        }
    }
    Row {
    id: rbPrompt
        anchors {
            horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: shoulderOffset
            verticalCenter: parent.top; verticalCenterOffset: headerH / 2
        }
        z: 1
        spacing: vpx(8)
        visible: !overview && bookmarks.length > 0

        Image {
            anchors.verticalCenter: parent.verticalCenter
            source: "../assets/images/controller/" + Utils.processButtonArt("nextPage") + ".png"
            width: vpx(30); height: vpx(30)
            sourceSize { width: Math.round(vpx(30) * 2); height: Math.round(vpx(30) * 2) }
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Jump to bookmark"
            color: "white"
            font { family: subtitleFont.name; pixelSize: fpx(16) }
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
        // Up to the LB prompt
        width: Math.max(vpx(160), root.width / 2 - shoulderOffset - vpx(120) - sideMargin)
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
            else toggleZoom();
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
            if (!event.isAutoRepeat && pageCount > 0) toggleZoom();
            return;
        }
        if (api.keys.isDetails(event)) {
            if (!event.isAutoRepeat) toggleBookmark();
            return;
        }
        if (api.keys.isFilters(event)) {
            if (!event.isAutoRepeat && pageCount > 1) openOverview();
            return;
        }
        if (api.keys.isPrevPage(event)) {
            if (!event.isAutoRepeat && pageCount > 1) toggleSpread();
            return;
        }
        if (api.keys.isNextPage(event)) { if (!event.isAutoRepeat) nextBookmark(); return; }
        // Triggers: 5 pages at a time, holding repeats
        if (api.keys.isPageUp(event))   { jump(-5); return; }
        if (api.keys.isPageDown(event)) { jump(5); return; }

        switch (event.key) {
            case Qt.Key_Left:  goTo(prevIndex()); break;
            case Qt.Key_Right: goTo(nextIndex()); break;
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
    // LB/RB have their own prompts in the header; LT/RT are never shown.
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
        manualviewHelpModel.append({ name: isBookmarked(page) ? "Remove bookmark" : "Bookmark", button: "details" });
        manualviewHelpModel.append({ name: zoomed ? "Fit page" : "Zoom", button: "accept" });
    }

    onFocusChanged: {
        if (focus) {
            currentHelpbarModel = manualviewHelpModel;
        }
    }
}
