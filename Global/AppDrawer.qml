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
// For OpacityMask — used to round the app icons. Bundled with Pegasus, and
// already used elsewhere in this theme.
import QtGraphicalEffects 1.15

FocusScope {
id: root

    // ── Host interface ────────────────────────────────────────────────────
    // The Pegasus collection holding the installed apps. Enable the system
    // apps option in Pegasus settings, then pass that collection in. Left null
    // the drawer still opens and explains that it's empty rather than looking
    // broken.
    property var collection: null
    property string title: "My games & apps"
    property real panelWidth: vpx(400)
    // Gap between the panel and the screen edges on the left, top and bottom.
    property real panelMargin: vpx(20)
    property real panelRadius: vpx(14)
    property real iconSize: vpx(56)
    property real iconRadius: vpx(10)
    // Pegasus renders Android adaptive icons as circles with transparent
    // corners, so a circular source sits inside the square tile still looking
    // round. A circle needs ~1.41x to cover the square it's inscribed in;
    // rounding up slightly hides the antialiased rim. On adaptive icons the
    // ring being cropped is background, so nothing meaningful is lost.
    // Set to 1.0 if any icon crops too hard — it will then sit centred on the
    // plate below instead.
    property real iconZoom: 1.45
    property color iconPlate: "#2E2E2E"
    property real rowHeight: vpx(80)

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

    // The screens take focus through `focus: shown` bindings, which do NOT
    // re-assert themselves once something else steals active focus. So the item
    // that had focus is captured on open and handed it back on close — this
    // works whatever screen is showing, with no per-state bookkeeping.
    //
    // This only holds because the screen Loaders stay loaded while the drawer
    // is open. They used to unload (active was chained to focus via opacity),
    // which destroyed the component the captured item lived in and left the
    // screen black on return.
    property var previousFocusItem: null

    // Emitted when focus couldn't be handed back — the host should re-assert it.
    signal focusRestoreFailed()

    function openDrawer() {
        previousFocusItem = Window.activeFocusItem;
        open = true;
        forceActiveFocus();
    }
    function closeDrawer() {
        open = false;
        // A destroyed QObject reads as null here, so this also covers the case
        // where the screen went away while the drawer was open.
        if (previousFocusItem) {
            previousFocusItem.forceActiveFocus();
        } else {
            focusRestoreFailed();
        }
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
        // Inset from the screen edges so the panel floats as a card rather
        // than butting against them.
        x: -(root.panelWidth + root.panelMargin) * (1 - root.slide) + root.panelMargin
        y: root.panelMargin
        height: parent.height - (root.panelMargin * 2)
        radius: root.panelRadius
        color: "#1C1C1C"

        // Outline rather than a single open-edge hairline: now that the panel
        // is inset on all sides, it needs an edge the whole way round.
        border.width: vpx(1)
        border.color: Qt.rgba(1, 1, 1, 0.12)

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
                height: root.rowHeight

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
                        id: iconBox

                            width: root.iconSize; height: root.iconSize
                            anchors.verticalCenter: parent.verticalCenter

                            // Fixed for the life of the row. The mask layer and
                            // the plate key off THIS rather than the image's
                            // load status: binding the layer to status meant it
                            // was created at the moment the async texture
                            // arrived, and in a recycled delegate that race
                            // sometimes captured an empty layer — the blank
                            // tiles that appeared at random.
                            readonly property bool hasArt: root.artFor(modelData) !== ""

                            // Plate behind the art. Icons arrive with
                            // transparent corners, so without this the tile
                            // shows the row through them instead of reading as
                            // a solid square.
                            Rectangle {
                                anchors.fill: parent
                                visible: iconBox.hasArt
                                radius: root.iconRadius
                                color: root.iconPlate
                            }

                            // Masked so the art is cropped square with rounded
                            // corners like the Xbox tiles. PreserveAspectFit
                            // would letterbox anything non-square, and
                            // clip: true can only cut rectangles.
                            Item {
                            id: iconClip

                                anchors.fill: parent
                                visible: iconBox.hasArt
                                layer.enabled: iconBox.hasArt
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle {
                                        width: iconBox.width
                                        height: iconBox.height
                                        radius: root.iconRadius
                                    }
                                }

                                Image {
                                    id: appIcon
                                    anchors.fill: parent
                                    source: root.artFor(modelData)
                                    // Decoded at the zoomed size so scaling up
                                    // doesn't soften the icon.
                                    sourceSize {
                                        width: Math.round(root.iconSize * root.iconZoom * 2)
                                        height: Math.round(root.iconSize * root.iconZoom * 2)
                                    }
                                    fillMode: Image.PreserveAspectCrop
                                    // Scales about the centre; the surrounding
                                    // layer clips the overflow.
                                    scale: root.iconZoom
                                    // Synchronous on purpose: at this size the
                                    // decode is trivial, and it removes the
                                    // load-timing race entirely.
                                    asynchronous: false
                                    smooth: true
                                }
                            }

                            // Letter tile — also covers art that failed to load,
                            // so a broken path leaves a labelled tile rather
                            // than an empty plate.
                            Rectangle {
                                anchors.fill: parent
                                visible: !iconBox.hasArt || appIcon.status === Image.Error
                                radius: root.iconRadius
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
                            width: parent.width - root.iconSize - vpx(12)
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
