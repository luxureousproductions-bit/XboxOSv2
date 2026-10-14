// XboxOS-V2
// Fullscreen game manual reader.
//
// Pages come from Pegasus itself: `image://pdf/<page>/<path>` renders one
// page of a PDF and `api.pdfPageCount(path)` counts them. Both exist only in
// Pegasus builds with PDF support (the XOS fork); GameView checks for
// api.pdfPageCount before ever showing this view, so on stock Pegasus the
// Manual button simply never appears.
//
// Modes (see the mockup): full page (default), zoom (A) where the page fills
// the width and up/down pans, and two pages (Y) side by side.
// Left/right turn pages, LB/RB jump 10, B closes. The last page read is
// remembered per manual in api.memory.

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

    // Layout: header on top, progress bar + the theme's help bar at the bottom
    readonly property real headerH: vpx(72)
    readonly property real footerH: vpx(78)
    readonly property real sideMargin: vpx(40)
    readonly property real availW: width - sideMargin * 2
    readonly property real availH: height - headerH - footerH

    // Two pages advance together; one page at a time otherwise
    readonly property int step: spread ? 2 : 1
    readonly property bool hasRightPage: spread && page + 1 < pageCount

    function pageUrl(index) {
        if (pdfPath === "" || index < 0 || index >= pageCount)
            return "";
        return "image://pdf/" + index + "/" + encodeURIComponent(pdfPath);
    }

    function memoryKey() { return "Manual page - " + pdfPath; }

    // Called by GameView before showing the view
    function open(path, title) {
        pdfPath = path;
        gameTitle = title;
        pageCount = api.pdfPageCount(path);
        zoomed = false;
        spread = false;
        var saved = api.memory.has(memoryKey()) ? parseInt(api.memory.get(memoryKey())) : 0;
        page = (saved > 0 && saved < pageCount) ? saved : 0;
    }

    function goTo(index) {
        if (pageCount <= 0) return;
        var target = Math.max(0, Math.min(pageCount - 1, index));
        if (target === page) return;
        playNav();
        page = target;
        zoomFlick.contentY = 0;
        api.memory.set(memoryKey(), String(page));
    }

    function toggleZoom() {
        playToggle();
        spread = false;
        zoomed = !zoomed;
        zoomFlick.contentY = 0;
    }

    function toggleSpread() {
        playToggle();
        zoomed = false;
        spread = !spread;
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
            top: parent.top; topMargin: headerH
        }
        height: availH
        spacing: vpx(6)

        Image {
        id: leftPage
            source: root.visible && !zoomed ? pageUrl(page) : ""
            sourceSize: Qt.size(spread ? (availW - pageRow.spacing) / 2 : availW, availH)
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
        model: root.visible && !zoomed && pageCount > 0 ? [page - step, page + step, page + step + 1] : []
        Image {
            visible: false
            asynchronous: true
            source: (spread || modelData !== page + step + 1) ? pageUrl(modelData) : ""
            sourceSize: leftPage.sourceSize
        }
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

    // Header: title on the left, page counter on the right
    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: headerH
        color: "black"
        opacity: zoomed ? 0.82 : 0
    }
    Column {
        anchors {
            left: parent.left; leftMargin: sideMargin
            verticalCenter: parent.top; verticalCenterOffset: headerH / 2
        }
        width: availW * 0.7
        Text {
            text: zoomed ? "MANUAL · ZOOM" : "MANUAL"
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
            text: hasRightPage ? (page + 1) + "–" + (page + 2) : (page + 1)
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
        opacity: zoomed ? 0.82 : 0
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
        enabled: !zoomed
        onClicked: {
            if (mouse.x < width / 3) goTo(page - step);
            else if (mouse.x > width * 2 / 3) goTo(page + step);
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

        if (api.keys.isCancel(event)) {
            if (!event.isAutoRepeat) close();
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
        if (api.keys.isPrevPage(event)) { goTo(page - 10); return; }
        if (api.keys.isNextPage(event)) { goTo(page + 10); return; }

        switch (event.key) {
            case Qt.Key_Left:  goTo(page - step); break;
            case Qt.Key_Right: goTo(page + step); break;
            case Qt.Key_Up:    if (zoomed) pan(-zoomFlick.height * 0.4); break;
            case Qt.Key_Down:  if (zoomed) pan(zoomFlick.height * 0.4); break;
        }
    }

    // Helpbar buttons
    ListModel {
        id: manualviewHelpModel

        ListElement {
            name: "Back"
            button: "cancel"
        }
        ListElement {
            name: "Two pages"
            button: "filters"
        }
        ListElement {
            name: "Zoom"
            button: "accept"
        }
        ListElement {
            name: "+10 pages"
            button: "nextPage"
        }
    }

    onFocusChanged: {
        if (focus) {
            currentHelpbarModel = manualviewHelpModel;
        }
    }
}
