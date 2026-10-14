// XboxOS-V2
// Fullscreen game manual reader.
//
// Pages come from Pegasus itself: `image://pdf/<page>/<path>` renders one
// page of a PDF and `api.pdfPageCount(path)` counts them. Both exist only in
// Pegasus builds with PDF support (the XOS fork); GameView checks for
// api.pdfPageCount before ever showing this view, so on stock Pegasus the
// Manual button simply never appears.
//
// Modes (see the mockups): full page (default), zoom (A) where the page fills
// the width and up/down pans, two pages (Y) paired like the printed booklet
// (cover alone, then 2-3, 4-5, ...), and a page overview grid (X).
// Manuals scanned as two-page spreads (wide pages) are detected and shown
// edge to edge, with the two-page mode turned off.
// Left/right turn pages, LB/RB jump 10, B closes. Always opens on page 1.

import QtQuick 2.15

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
    function jump(delta) {
        var target = Math.max(0, Math.min(pageCount - 1, page + delta));
        goTo(spread ? spreadStart(target) : target);
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
        page = 0;
        zoomFlick.contentY = 0;
        updateHelp();
    }

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
        overview = true;
        pageGrid.currentIndex = page;
        pageGrid.positionViewAtIndex(page, GridView.Center);
        updateHelp();
    }

    function closeOverview(pick) {
        overview = false;
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
            model: overview ? pageCount : 0
            keyNavigationWraps: false
            highlightMoveDuration: 120

            delegate: Item {
                width: pageGrid.cellWidth
                height: pageGrid.cellHeight
                readonly property bool isCurrent: GridView.isCurrentItem

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
                        source: pageUrl(index)
                        sourceSize: Qt.size(Math.round(width), Math.round(height))
                    }
                }
                Text {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: thumbFrame.bottom; topMargin: vpx(8)
                    }
                    text: index + 1
                    color: isCurrent ? theme.accent : "#bbbbbb"
                    font { family: titleFont.name; pixelSize: vpx(15) }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: closeOverview(index)
                }
            }
        }
    }

    // Header: title on the left, page counter on the right
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
        width: availW * 0.7
        Text {
            text: overview ? "MANUAL · PAGES" : (zoomed ? "MANUAL · ZOOM" : "MANUAL")
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
            text: overview ? (pageGrid.currentIndex + 1)
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
            if (api.keys.isCancel(event) || api.keys.isDetails(event)) { closeOverview(-1); return; }
            if (api.keys.isAccept(event)) { closeOverview(pageGrid.currentIndex); return; }
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
        if (api.keys.isDetails(event)) {
            if (!event.isAutoRepeat && pageCount > 1) openOverview();
            return;
        }
        if (api.keys.isAccept(event)) {
            if (!event.isAutoRepeat && pageCount > 0) toggleZoom();
            return;
        }
        if (api.keys.isFilters(event)) {
            if (!event.isAutoRepeat && pageCount > 1) toggleSpread();
            return;
        }
        if (api.keys.isPrevPage(event)) { jump(-10); return; }
        if (api.keys.isNextPage(event)) { jump(10); return; }

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

    function updateHelp() {
        manualviewHelpModel.clear();
        manualviewHelpModel.append({ name: "Back", button: "cancel" });
        if (overview) {
            manualviewHelpModel.append({ name: "Go to page", button: "accept" });
            return;
        }
        if (pageCount > 1)
            manualviewHelpModel.append({ name: "Pages", button: "details" });
        if (pageCount > 1 && !spreadScan)
            manualviewHelpModel.append({ name: spread ? "One page" : "Two pages", button: "filters" });
        manualviewHelpModel.append({ name: zoomed ? "Fit page" : "Zoom", button: "accept" });
    }

    onFocusChanged: {
        if (focus) {
            currentHelpbarModel = manualviewHelpModel;
        }
    }
}
