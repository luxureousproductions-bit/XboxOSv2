// XboxOSv2 — AppDrawer
//
// Left slide-out app list, modelled on the Xbox guide: a square icon with the
// app name to its right, a dark panel over a dimming scrim, and an accent
// outline on the focused row.
//
// Lives in Global/ so any screen can host it. Place ONE instance at the top
// level of theme.qml (not per-screen) so it overlays everything and keeps its
// state as the user moves between views:
//
//   AppDrawer {
//       id: appDrawer
//       anchors.fill: parent
//       z: 9000
//       collection: <the Android apps collection>
//       onAppChosen: launchGame(game)     // or game.launch(), see below
//       onClosed: <give focus back to the current screen>
//   }
//
// Open it from wherever the trigger ends up living:
//   appDrawer.openDrawer()
//
// The collection and the trigger are both supplied by the host, so nothing
// here depends on knowing the Select key code yet.
//
// Controls: up/down move · A launch · B close · LB/RB jump a page.

import QtQuick 2.15
import QtQuick.Window 2.15

FocusScope {
id: root

    // ── Host interface ────────────────────────────────────────────────────
    // The Pegasus collection holding the installed apps. Enable the system
    // apps option in Pegasus settings, then pass that collection in. Left null
    // the drawer still opens and explains that it's empty rather than looking
    // broken.
    property var collection: null
    property string title: "My games & apps"
    property real panelWidth: vpx(330)

    // If `collection` is left null, the apps collection is looked up by name
    // instead. Pegasus doesn't guarantee what it calls that collection, so the
    // match is loose and case-insensitive — set collection explicitly (or
    // change this string) if it ever grabs the wrong one.
    property string collectionMatch: "android"

    property bool open: false

    // Emitted with the chosen Game. Wired to the host so launching can go
    // through the theme's own launch path (transitions, saved state) rather
    // than this component deciding. If you'd rather it be self-contained,
    // call game.launch() in the handler — that's the plain Pegasus API.
    signal appChosen(var game)
    signal closed()

    anchors.fill: parent
    // Closed, the drawer must not sit in front of the screen eating input.
    visible: slide > 0.001
    enabled: open

    // The screens take focus through `focus: (root.state === ...)` bindings,
    // which do NOT re-assert themselves once something else steals active
    // focus. So the item that had focus is captured on open and handed it back
    // on close — this works whatever screen is showing, with no per-state
    // bookkeeping in theme.qml.
    property var previousFocusItem: null

    function openDrawer() {
        previousFocusItem = Window.activeFocusItem;
        open = true;
        forceActiveFocus();
    }
    function closeDrawer() {
        open = false;
        // Guard: the previous item can be gone if its Loader unloaded while
        // the drawer was open.
        if (previousFocusItem)
            previousFocusItem.forceActiveFocus();
        previousFocusItem = null;
        closed();
    }
    function chooseCurrent() {
        if (!appModel || list.currentIndex < 0) return;
        var g = appModel.get(list.currentIndex);
        if (!g) return;
        // Launching suspends Pegasus; close now so returning doesn't land
        // back in a half-open drawer.
        open = false;
        // Deliberately NOT restoring focus here. The host's launch path moves
        // to the launch screen, and that Loader's own `focus` binding claims
        // focus — handing it back to the previous screen would fight that.
        previousFocusItem = null;
        appChosen(g);
    }

    // ── Data ──────────────────────────────────────────────────────────────
    // An explicit collection always wins; the name search is only a fallback.
    readonly property var resolvedCollection: {
        if (collection) return collection;
        if (collectionMatch === "") return null;
        var needle = collectionMatch.toLowerCase();
        var i, c;
        // Exact name wins. The apps provider's collection and the hand-written
        // ROM collections can all share the shortName "android", so a substring
        // match would just return whichever happened to be enumerated first —
        // which is not a stable thing to depend on.
        for (i = 0; i < api.collections.count; i++) {
            c = api.collections.get(i);
            if ((c.name || "").toLowerCase() === needle) return c;
        }
        for (i = 0; i < api.collections.count; i++) {
            c = api.collections.get(i);
            if ((c.shortName || "").toLowerCase() === needle) return c;
        }
        // Substring only as a last resort.
        for (i = 0; i < api.collections.count; i++) {
            c = api.collections.get(i);
            if ((c.name || "").toLowerCase().indexOf(needle) >= 0) return c;
        }
        return null;
    }
    readonly property var appModel: resolvedCollection ? resolvedCollection.games : null
    readonly property int appCount: appModel ? appModel.count : 0

    // Pegasus only has art for some installed apps, so try the asset slots an
    // app icon realistically lands in and let the delegate fall back to a
    // letter tile when they're all empty.
    function artFor(g) {
        if (!g || !g.assets) return "";
        var a = g.assets;
        return a.boxFront || a.tile || a.logo || a.banner || a.poster || "";
    }
    function initialFor(g) {
        if (!g || !g.title || g.title.length === 0) return "?";
        return g.title.charAt(0).toUpperCase();
    }

    // ── Animation ─────────────────────────────────────────────────────────
    // One driver for both the panel offset and the scrim, so they can't drift
    // out of step.
    property real slide: open ? 1 : 0
    Behavior on slide {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // Dimming scrim. A real blur behind the panel is the expensive part of the
    // Xbox look and buys little at this size, so this is a flat fill.
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.55 * root.slide
        MouseArea {
            anchors.fill: parent
            onClicked: root.closeDrawer()
        }
    }

    // ── Panel ─────────────────────────────────────────────────────────────
    Rectangle {
    id: panel

        width: root.panelWidth
        height: parent.height
        x: -root.panelWidth * (1 - root.slide)
        color: "#1C1C1C"

        // Hairline along the open edge, so the panel reads as a layer above
        // the screen rather than a flat block of colour.
        Rectangle {
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: vpx(1)
            color: Qt.rgba(1, 1, 1, 0.12)
        }

        Text {
        id: header

            anchors {
                top: parent.top; topMargin: vpx(22)
                left: parent.left; leftMargin: vpx(20)
                right: parent.right; rightMargin: vpx(20)
            }
            text: root.title
            color: "white"
            font.family: titleFont.name
            font.pixelSize: fpx(20)
            font.bold: true
            elide: Text.ElideRight
        }

        Rectangle {
        id: headerRule

            anchors { top: header.bottom; topMargin: vpx(14); left: parent.left; right: parent.right }
            height: vpx(1)
            color: Qt.rgba(1, 1, 1, 0.12)
        }

        // Empty state — most likely the system apps option isn't enabled yet,
        // which is worth saying rather than showing a blank panel.
        Text {
            anchors {
                top: headerRule.bottom; topMargin: vpx(28)
                left: parent.left; leftMargin: vpx(20)
                right: parent.right; rightMargin: vpx(20)
            }
            visible: root.appCount === 0
            text: root.resolvedCollection
                  ? "No apps in this collection."
                  : "No app collection found.\nEnable system apps in Pegasus settings, "
                    + "or set the collection on this drawer."
            color: Qt.rgba(1, 1, 1, 0.5)
            font.family: subtitleFont.name
            font.pixelSize: fpx(15)
            wrapMode: Text.WordWrap
            lineHeight: 1.3
        }

        ListView {
        id: list

            anchors {
                top: headerRule.bottom; topMargin: vpx(8)
                left: parent.left; right: parent.right
                bottom: parent.bottom; bottomMargin: vpx(12)
            }
            visible: root.appCount > 0
            clip: true
            model: root.appModel
            currentIndex: 0
            // Keeps the focused row off the very edge when scrolling.
            preferredHighlightBegin: height * 0.25
            preferredHighlightEnd: height * 0.75
            highlightRangeMode: ListView.ApplyRange
            highlightMoveDuration: 160
            cacheBuffer: vpx(400)

            delegate: Item {
                width: ListView.view.width
                height: vpx(60)

                readonly property bool current: ListView.isCurrentItem

                Rectangle {
                    anchors {
                        fill: parent
                        leftMargin: vpx(12); rightMargin: vpx(12)
                        topMargin: vpx(3); bottomMargin: vpx(3)
                    }
                    radius: vpx(4)
                    color: parent.current ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                    border.color: theme.accent
                    border.width: parent.current ? vpx(2) : 0

                    Row {
                        anchors {
                            left: parent.left; leftMargin: vpx(10)
                            right: parent.right; rightMargin: vpx(10)
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: vpx(12)

                        // Icon, or a letter tile when the app has no art. The
                        // tile keeps every row the same visual weight so a
                        // partly-scraped list doesn't look broken.
                        Item {
                            width: vpx(40); height: vpx(40)
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: appIcon
                                anchors.fill: parent
                                source: root.artFor(modelData)
                                sourceSize { width: Math.round(vpx(40) * 2); height: Math.round(vpx(40) * 2) }
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                                visible: source != "" && status === Image.Ready
                            }
                            Rectangle {
                                anchors.fill: parent
                                visible: !appIcon.visible
                                radius: vpx(6)
                                color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.22)
                                Text {
                                    anchors.centerIn: parent
                                    text: root.initialFor(modelData)
                                    color: "white"
                                    font.family: titleFont.name
                                    font.pixelSize: fpx(19)
                                    font.bold: true
                                }
                            }
                        }

                        Text {
                            width: parent.width - vpx(40) - vpx(12)
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData ? modelData.title : ""
                            color: "white"
                            font.family: subtitleFont.name
                            font.pixelSize: fpx(16)
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.WordWrap
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            list.currentIndex = index;
                            root.chooseCurrent();
                        }
                    }
                }
            }
        }
    }

    // ── Input ─────────────────────────────────────────────────────────────
    Keys.onUpPressed: {
        event.accepted = true;
        if (list.currentIndex > 0) list.currentIndex--;
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (list.currentIndex < list.count - 1) list.currentIndex++;
    }
    Keys.onPressed: {
        if (event.isAutoRepeat) return;

        if (api.keys.isAccept(event)) {
            event.accepted = true;
            chooseCurrent();
            return;
        }
        if (api.keys.isCancel(event)) {
            event.accepted = true;
            closeDrawer();
            return;
        }
        if (api.keys.isPrevPage(event)) {                 // LB — page up
            event.accepted = true;
            list.currentIndex = Math.max(0, list.currentIndex - 8);
            return;
        }
        if (api.keys.isNextPage(event)) {                 // RB — page down
            event.accepted = true;
            list.currentIndex = Math.min(list.count - 1, list.currentIndex + 8);
        }
    }
}
