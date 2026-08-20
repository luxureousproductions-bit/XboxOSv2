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
    property real iconSize: vpx(64)
    property real iconRadius: vpx(12)
    // Pegasus renders Android adaptive icons as circles with transparent
    // corners, so a circular source sits inside the square tile still looking
    // round. A circle needs ~1.41x to cover the square it's inscribed in;
    // rounding up slightly hides the antialiased rim. On adaptive icons the
    // ring being cropped is background, so nothing meaningful is lost.
    // Set to 1.0 if any icon crops too hard — it will then sit centred on the
    // plate below instead.
    property real iconZoom: 1.45
    property color iconPlate: "#2E2E2E"

    // ── Zones ─────────────────────────────────────────────────────────────
    // The panel is three stacked navigable regions. Focus moves between them
    // vertically; each keeps its own index so returning to one lands where you
    // left it.
    readonly property int zoneTabs: 0
    readonly property int zoneNav:  1
    readonly property int zoneApps: 2

    property int zone: zoneNav      // opens on Home, like the guide
    property int tabIndex: 0
    property int navIndex: 0

    property real navRowHeight: vpx(52)

    // Emitted when a nav row is chosen; the host decides where each one goes.
    signal navHome()
    signal navLibrary()

    readonly property var navItems: [
        { label: "Home",             icon: "../assets/images/icon_home.svg" },
        { label: "My games & apps",  icon: "../assets/images/gamesandapps.png" }
    ]

    // Tab strip. The logo is real; the rest are throwaway shapes drawn with
    // plain Rectangles until the strip's actual contents are decided.
    //
    // Rectangles rather than Canvas: Canvas doesn't render in this build (the
    // same reason every keyboard glyph is an SVG). An entry with `icon` draws
    // that image; one with `shape` draws the named placeholder.
    readonly property var tabs: [
        { icon: "../assets/images/Xbox-logo2.png", filter: "all",      label: "All" },
        { shape: "diamond",                         filter: "favorite", label: "Favorites" },
        { shape: "circle",                          filter: "game",     label: "Games" },
        { shape: "square",                          filter: "emulator", label: "Emulators" },
        { shape: "grid",                            filter: "system",   label: "System" },
        { shape: "tri",                             filter: "other",    label: "Apps" },
        { shape: "bar",                             filter: "hidden",   label: "Hidden" }
    ]

    // Closes first, so the drawer isn't sitting open over the screen it just
    // navigated to.
    function triggerNav(i) {
        closeDrawer();
        if (i === 0) navHome();
        else         navLibrary();
    }
    property real rowHeight: vpx(90)

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
        // Always opens on Home rather than wherever it was left, so the first
        // press of Down is predictable.
        zone = zoneNav;
        navIndex = 0;
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
        if (list.currentIndex < 0 || list.currentIndex >= filteredApps.length) return;
        var g = filteredApps[list.currentIndex];
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
    readonly property int appCount: filteredApps.length

    // ── Categories ────────────────────────────────────────────────────────
    // Pegasus leaves genre, developer and publisher empty on provider apps, but
    // it does expose the package name via files — "android:com.dsemu.drastic".
    // That's the only usable signal, so categories are derived from it.
    //
    // System and emulator detect reliably. "Game vs ordinary app" has NO signal
    // in the data, so games are listed explicitly below; anything unmatched
    // still shows under the All tab, so nothing is ever hidden.
    property var systemPrefixes: [
        "com.android.", "com.google.android.", "com.qualcomm.", "com.mediatek.",
        "com.samsung.", "com.sec.", "com.odin.", "com.ayn.", "org.lineageos.", "android."
    ]
    property var emulatorKeywords: [
        "citra", "dolphin", "drastic", "duckstation", "aethersx2", "ppsspp", "retroarch",
        "vita3k", "yuzu", "ryujinx", "eden", "sudachi", "redream", "mupen", "melonds",
        "flycast", "pcsx", "epsxe", "mame", "xemu", "winlator", "lime3ds", "azahar",
        "panda3ds", "skyline", "nethersx2", "snes9x", "mgba", "fpse", "dsemu", "mm.jr",
        "emu", "emulator", "gamenative"
    ]
    // Package -> category. Wins over every rule; this is where games go, and
    // where anything the rules get wrong gets corrected.
    property var categoryOverrides: ({
        "com.lojical.AM2R": "game"
    })

    // ── Saved state ───────────────────────────────────────────────────────
    // Favorites, hidden apps and reclassifications are theme-side concepts —
    // Pegasus knows nothing about them — so they live in api.memory, which
    // persists across restarts.
    //
    // Stored keyed by package rather than title: titles can change when an app
    // updates, package names don't.
    property var favoritePkgs: ({})
    property var hiddenPkgs: ({})
    property var savedCategories: ({})

    readonly property string memFavorites: "appdrawer.favorites"
    readonly property string memHidden: "appdrawer.hidden"
    readonly property string memCategories: "appdrawer.categories"

    function parseObj(raw) {
        if (!raw) return ({});
        try {
            var o = JSON.parse(raw);
            return (o && typeof o === "object") ? o : ({});
        } catch (e) {
            return ({});
        }
    }
    function loadState() {
        favoritePkgs    = parseObj(api.memory.get(memFavorites));
        hiddenPkgs      = parseObj(api.memory.get(memHidden));
        savedCategories = parseObj(api.memory.get(memCategories));
    }
    // Reassigns a fresh object rather than mutating in place: QML only
    // re-evaluates bindings on assignment, so an in-place edit would update the
    // data without ever refreshing the list.
    function withKey(obj, key, value) {
        var copy = {};
        for (var k in obj) copy[k] = obj[k];
        if (value === undefined) delete copy[key];
        else copy[key] = value;
        return copy;
    }

    function isFavorite(pkg) { return pkg !== "" && favoritePkgs[pkg] === true; }
    function isHidden(pkg)   { return pkg !== "" && hiddenPkgs[pkg] === true; }

    function toggleFavorite(pkg) {
        if (pkg === "") return;
        favoritePkgs = withKey(favoritePkgs, pkg, isFavorite(pkg) ? undefined : true);
        api.memory.set(memFavorites, JSON.stringify(favoritePkgs));
    }
    function toggleHidden(pkg) {
        if (pkg === "") return;
        hiddenPkgs = withKey(hiddenPkgs, pkg, isHidden(pkg) ? undefined : true);
        api.memory.set(memHidden, JSON.stringify(hiddenPkgs));
    }
    function setCategory(pkg, cat) {
        if (pkg === "") return;
        savedCategories = withKey(savedCategories, pkg, cat);
        api.memory.set(memCategories, JSON.stringify(savedCategories));
    }
    // Drops the saved override so the package falls back to the rules.
    function clearCategory(pkg) {
        if (pkg === "") return;
        savedCategories = withKey(savedCategories, pkg, undefined);
        api.memory.set(memCategories, JSON.stringify(savedCategories));
    }

    Component.onCompleted: loadState()

    function packageOf(game) {
        if (!game || !game.files || game.files.count < 1) return "";
        var p = game.files.get(0).path || "";
        // Paths arrive prefixed, e.g. "android:com.dsemu.drastic".
        var colon = p.indexOf(":");
        return colon >= 0 ? p.substring(colon + 1) : p;
    }

    function categoryOf(game) {
        var pkg = packageOf(game);
        // Saved reclassification beats the shipped seed, which beats the rules.
        if (pkg !== "" && savedCategories[pkg] !== undefined)
            return savedCategories[pkg];
        if (pkg !== "" && categoryOverrides[pkg] !== undefined)
            return categoryOverrides[pkg];

        var p = pkg.toLowerCase();
        var t = (game && game.title ? game.title : "").toLowerCase();
        var i;
        for (i = 0; i < systemPrefixes.length; i++)
            if (p.indexOf(systemPrefixes[i]) === 0) return "system";
        for (i = 0; i < emulatorKeywords.length; i++)
            if (p.indexOf(emulatorKeywords[i]) >= 0 || t.indexOf(emulatorKeywords[i]) >= 0)
                return "emulator";
        return "other";
    }

    // Rebuilt when the collection, the active tab, or any saved state changes.
    // A plain JS array is used as the ListView model because a Pegasus GameList
    // can't be filtered in place.
    readonly property string activeFilter: {
        var t = tabs[tabIndex];
        return (t && t.filter !== undefined) ? t.filter : "all";
    }
    readonly property var filteredApps: {
        var out = [];
        if (!appModel) return out;
        var want = activeFilter;
        // Referenced so the list rebuilds when any of these change.
        var fav = favoritePkgs, hid = hiddenPkgs, cats = savedCategories;
        for (var i = 0; i < appModel.count; i++) {
            var g = appModel.get(i);
            var pkg = packageOf(g);
            // Hidden apps are gone from every tab except Hidden itself,
            // otherwise there'd be no way to get them back.
            if (want !== "hidden" && hid[pkg] === true) continue;
            if (want === "all") { out.push(g); continue; }
            if (want === "favorite") { if (fav[pkg] === true) out.push(g); continue; }
            if (want === "hidden")   { if (hid[pkg] === true) out.push(g); continue; }
            if (categoryOf(g) === want) out.push(g);
        }
        return out;
    }
    // Selecting a different tab restarts the list at the top.
    onActiveFilterChanged: list.currentIndex = 0

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

        // ── Tab strip ─────────────────────────────────────────────────────
        // Placeholders for now — edit root.tabs to change them. Each entry is
        // just an icon plus an action, so wiring one up later is a one-liner.
        Row {
        id: tabStrip

            anchors {
                top: parent.top; topMargin: vpx(14)
                horizontalCenter: parent.horizontalCenter
            }
            height: vpx(46)
            spacing: vpx(4)

            Repeater {
                model: root.tabs
                delegate: Item {
                    width: vpx(46); height: tabStrip.height
                    readonly property bool current: root.zone === root.zoneTabs
                                                    && root.tabIndex === index

                    Image {
                        anchors.centerIn: parent
                        visible: modelData.icon !== undefined
                        // Larger than the drawn placeholders: the logo has its
                        // own internal padding, so matching their box size left
                        // it looking like a dot.
                        width: vpx(38); height: vpx(38)
                        source: modelData.icon !== undefined ? modelData.icon : ""
                        sourceSize { width: Math.round(vpx(38) * 2); height: Math.round(vpx(38) * 2) }
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        opacity: parent.current ? 1.0 : 0.55
                    }

                    // Drawn placeholders. Deliberately plain — they're meant to
                    // be replaced, and shapes make that obvious at a glance.
                    Item {
                        anchors.centerIn: parent
                        visible: modelData.shape !== undefined
                        width: vpx(22); height: vpx(22)
                        opacity: parent.current ? 1.0 : 0.55

                        Rectangle {
                            anchors.fill: parent
                            visible: modelData.shape === "circle"
                            radius: width / 2
                            color: "transparent"
                            border.width: vpx(2)
                            border.color: "white"
                        }
                        Rectangle {
                            anchors.fill: parent
                            visible: modelData.shape === "square"
                            radius: vpx(4)
                            color: "transparent"
                            border.width: vpx(2)
                            border.color: "white"
                        }
                        Grid {
                            anchors.centerIn: parent
                            visible: modelData.shape === "grid"
                            columns: 2
                            spacing: vpx(4)
                            Repeater {
                                model: 4
                                Rectangle {
                                    width: vpx(9); height: vpx(9)
                                    radius: vpx(2)
                                    color: "white"
                                }
                            }
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            visible: modelData.shape === "diamond"
                            width: vpx(15); height: vpx(15)
                            radius: vpx(2)
                            rotation: 45
                            color: "transparent"
                            border.width: vpx(2)
                            border.color: "white"
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            visible: modelData.shape === "bar"
                            width: vpx(20); height: vpx(6)
                            radius: vpx(3)
                            color: "white"
                        }
                        // Triangle stand-in built from a rotated square, since
                        // Rectangle can't do triangles and Canvas doesn't render
                        // in this build.
                        Rectangle {
                            anchors.centerIn: parent
                            visible: modelData.shape === "tri"
                            width: vpx(14); height: vpx(14)
                            radius: vpx(2)
                            rotation: 45
                            color: "white"
                        }
                    }
                    // Underline marks the active tab, as the guide does.
                    Rectangle {
                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                        width: vpx(26); height: vpx(2)
                        radius: height / 2
                        color: theme.accent
                        visible: parent.current
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { root.zone = root.zoneTabs; root.tabIndex = index; }
                    }
                }
            }
        }

        Rectangle {
        id: tabRule

            anchors { top: tabStrip.bottom; topMargin: vpx(10); left: parent.left; right: parent.right }
            height: vpx(1)
            color: Qt.rgba(1, 1, 1, 0.12)
        }

        // ── Home / My games & apps ────────────────────────────────────────
        Column {
        id: navSection

            anchors {
                top: tabRule.bottom; topMargin: vpx(10)
                left: parent.left; right: parent.right
            }
            spacing: vpx(2)

            Repeater {
                model: root.navItems
                delegate: Item {
                    width: navSection.width
                    height: root.navRowHeight
                    readonly property bool current: root.zone === root.zoneNav
                                                    && root.navIndex === index

                    Rectangle {
                        anchors {
                            fill: parent
                            leftMargin: vpx(12); rightMargin: vpx(12)
                            topMargin: vpx(2); bottomMargin: vpx(2)
                        }
                        radius: vpx(6)
                        color: parent.current ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
                        border.width: parent.current ? vpx(2) : 0
                        border.color: theme.accent
                    }

                    Row {
                        anchors {
                            left: parent.left; leftMargin: vpx(26)
                            right: parent.right; rightMargin: vpx(18)
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: vpx(16)

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: vpx(24); height: vpx(24)
                            source: modelData.icon
                            sourceSize { width: Math.round(vpx(24) * 2); height: Math.round(vpx(24) * 2) }
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - vpx(24) - vpx(16)
                            text: modelData.label
                            color: "white"
                            font.family: subtitleFont.name
                            font.pixelSize: fpx(17)
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.zone = root.zoneNav;
                            root.navIndex = index;
                            root.triggerNav(index);
                        }
                    }
                }
            }
        }

        Rectangle {
        id: headerRule

            anchors { top: navSection.bottom; topMargin: vpx(10); left: parent.left; right: parent.right }
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
                  ? (root.activeFilter === "all"
                     ? "No apps in this collection."
                     : "Nothing in this category yet.")
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
            model: root.filteredApps
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

                // Requires the cursor to actually be in the app list — otherwise
                // the top row stayed lit while focus was up on the tabs or nav.
                readonly property bool current: ListView.isCurrentItem
                                                && root.zone === root.zoneApps

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
                            width: parent.width - root.iconSize - vpx(12) - vpx(16)
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData ? modelData.title : ""
                            color: "white"
                            font.family: subtitleFont.name
                            font.pixelSize: fpx(16)
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.WordWrap
                        }

                        // Favourite marker — visible in every tab, so the state
                        // is readable without opening the quick menu.
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.isFavorite(root.packageOf(modelData))
                            width: vpx(8); height: vpx(8)
                            radius: width / 2
                            color: theme.accent
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
    // Vertical movement crosses zones; the app list is skipped entirely when
    // it's empty, so an unconfigured collection can't strand the cursor.
    // ── Hints ─────────────────────────────────────────────────────────────
    // Sits beside the panel, where the guide puts its prompts. The section
    // label lives here rather than inside the panel so the panel is nothing but
    // tabs, nav and list.
    Column {
    id: hints

        anchors {
            left: panel.right; leftMargin: vpx(30)
            top: panel.top; topMargin: vpx(34)
            right: parent.right; rightMargin: vpx(20)
        }
        spacing: vpx(12)
        // Fades in with the panel rather than popping.
        opacity: root.slide

        // Xbox button + the section you're in, with a live count.
        Row {
            spacing: vpx(12)
            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: vpx(26); height: vpx(26)
                source: "../assets/images/Xbox-logo2.png"
                sourceSize { width: Math.round(vpx(26) * 2); height: Math.round(vpx(26) * 2) }
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    var t = root.tabs[root.tabIndex];
                    return (t && t.label ? t.label : "") + "  (" + root.filteredApps.length + ")";
                }
                color: "white"
                font.family: subtitleFont.name
                font.pixelSize: fpx(17)
                elide: Text.ElideRight
            }
        }

        // Only meaningful with an app highlighted — the quick menu acts on the
        // current row, so it's hidden in the tab and nav zones.
        Row {
            spacing: vpx(12)
            visible: root.zone === root.zoneApps && root.filteredApps.length > 0
            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: vpx(24); height: vpx(24)
                source: "../assets/images/kb_badge_start_white.svg"
                sourceSize { width: Math.round(vpx(24) * 2); height: Math.round(vpx(24) * 2) }
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "More options"
                color: Qt.rgba(1, 1, 1, 0.85)
                font.family: subtitleFont.name
                font.pixelSize: fpx(17)
                elide: Text.ElideRight
            }
        }
    }

    // ── Quick menu ────────────────────────────────────────────────────────
    // Opened with Start on the highlighted app. Modal: while it's up the
    // drawer's own key handling defers to it entirely.
    property bool quickOpen: false
    property int quickIndex: 0
    property var quickApp: null
    // Start. api.keys has no binding for it, so the raw code is used — the
    // same one the virtual keyboard uses.
    property int quickMenuKey: 1048587

    readonly property var quickActions: {
        var pkg = root.quickApp ? root.packageOf(root.quickApp) : "";
        return [
            { label: root.isFavorite(pkg) ? "Remove from Favorites" : "Add to Favorites", act: "fav" },
            { label: root.isHidden(pkg)   ? "Unhide app"            : "Hide app",         act: "hide" },
            { label: "Move to Games",     act: "cat", cat: "game" },
            { label: "Move to Emulators", act: "cat", cat: "emulator" },
            { label: "Move to System",    act: "cat", cat: "system" },
            { label: "Move to Apps",      act: "cat", cat: "other" },
            { label: "Reset to automatic", act: "reset" }
        ];
    }

    function openQuickMenu() {
        if (zone !== zoneApps) return;
        if (list.currentIndex < 0 || list.currentIndex >= filteredApps.length) return;
        quickApp = filteredApps[list.currentIndex];
        quickIndex = 0;
        quickOpen = true;
    }
    function closeQuickMenu() {
        quickOpen = false;
        quickApp = null;
    }
    function runQuickAction() {
        var a = quickActions[quickIndex];
        var pkg = quickApp ? packageOf(quickApp) : "";
        if (!a || pkg === "") { closeQuickMenu(); return; }
        if (a.act === "fav")       toggleFavorite(pkg);
        else if (a.act === "hide") toggleHidden(pkg);
        else if (a.act === "cat")  setCategory(pkg, a.cat);
        else if (a.act === "reset") clearCategory(pkg);
        closeQuickMenu();
        // The list may have shrunk under the cursor — hiding an app removes it
        // from the current tab, reclassifying can too.
        if (list.currentIndex >= filteredApps.length)
            list.currentIndex = Math.max(0, filteredApps.length - 1);
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.quickOpen ? 0.5 : 0
        visible: opacity > 0.001
        Behavior on opacity { NumberAnimation { duration: 120 } }
        MouseArea {
            anchors.fill: parent
            enabled: root.quickOpen
            onClicked: root.closeQuickMenu()
        }
    }

    Rectangle {
    id: quickMenu

        anchors.centerIn: parent
        width: vpx(330)
        height: quickCol.height + vpx(28)
        radius: vpx(10)
        color: "#242424"
        border.width: vpx(1)
        border.color: Qt.rgba(1, 1, 1, 0.16)
        visible: root.quickOpen
        opacity: root.quickOpen ? 1 : 0
        scale: root.quickOpen ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 2 } }

        Column {
        id: quickCol

            anchors { top: parent.top; topMargin: vpx(14); left: parent.left; right: parent.right }
            spacing: vpx(2)

            Text {
                anchors { left: parent.left; leftMargin: vpx(18); right: parent.right; rightMargin: vpx(18) }
                text: root.quickApp ? root.quickApp.title : ""
                color: Qt.rgba(1, 1, 1, 0.55)
                font.family: subtitleFont.name
                font.pixelSize: fpx(13)
                font.bold: true
                elide: Text.ElideRight
                bottomPadding: vpx(8)
            }

            Repeater {
                model: root.quickActions
                delegate: Item {
                    width: quickCol.width
                    height: vpx(40)
                    readonly property bool current: root.quickIndex === index

                    Rectangle {
                        anchors {
                            fill: parent
                            leftMargin: vpx(10); rightMargin: vpx(10)
                            topMargin: vpx(1); bottomMargin: vpx(1)
                        }
                        radius: vpx(5)
                        color: parent.current ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        border.width: parent.current ? vpx(2) : 0
                        border.color: theme.accent
                    }
                    Text {
                        anchors {
                            left: parent.left; leftMargin: vpx(22)
                            right: parent.right; rightMargin: vpx(18)
                            verticalCenter: parent.verticalCenter
                        }
                        text: modelData.label
                        color: "white"
                        font.family: subtitleFont.name
                        font.pixelSize: fpx(15)
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { root.quickIndex = index; root.runQuickAction(); }
                    }
                }
            }
        }
    }

    // ── Navigation ────────────────────────────────────────────────────────
    // Vertical moves cross zones. The app list wraps top-to-bottom so a long
    // list can be circled without backing out of it, but Up from the first row
    // still exits to the nav rows — otherwise there'd be no way back up.
    Keys.onUpPressed: {
        event.accepted = true;
        if (quickOpen) {
            if (quickIndex > 0) { quickIndex--; playNav(); }
            return;
        }
        if (zone === zoneApps) {
            if (list.currentIndex > 0) list.currentIndex--;
            else { zone = zoneNav; navIndex = navItems.length - 1; }
            playNav();
            return;
        }
        if (zone === zoneNav) {
            if (navIndex > 0) navIndex--;
            else zone = zoneTabs;
            playNav();
            return;
        }
        // Already at the top.
    }
    Keys.onDownPressed: {
        event.accepted = true;
        if (quickOpen) {
            if (quickIndex < quickActions.length - 1) { quickIndex++; playNav(); }
            return;
        }
        if (zone === zoneTabs) { zone = zoneNav; navIndex = 0; playNav(); return; }
        if (zone === zoneNav) {
            if (navIndex < navItems.length - 1) { navIndex++; playNav(); return; }
            if (appCount > 0) { zone = zoneApps; list.currentIndex = 0; playNav(); }
            return;
        }
        // Wraps back to the first app past the end of the list.
        if (list.currentIndex < list.count - 1) list.currentIndex++;
        else list.currentIndex = 0;
        playNav();
    }

    // Left/Right page through the app list, wrapping at both ends. They used to
    // move the tab strip; that's on LB/RB now, matching the nav bar elsewhere.
    Keys.onLeftPressed: {
        event.accepted = true;
        if (quickOpen) return;
        if (zone === zoneTabs) { cycleTab(-1); return; }
        if (zone !== zoneApps) return;
        if (list.count < 1) return;
        if (list.currentIndex > 0) list.currentIndex = Math.max(0, list.currentIndex - 8);
        else list.currentIndex = list.count - 1;      // wrap to the bottom
        playNav();
    }
    Keys.onRightPressed: {
        event.accepted = true;
        if (quickOpen) return;
        if (zone === zoneTabs) { cycleTab(1); return; }
        if (zone !== zoneApps) return;
        if (list.count < 1) return;
        if (list.currentIndex < list.count - 1)
            list.currentIndex = Math.min(list.count - 1, list.currentIndex + 8);
        else list.currentIndex = 0;                   // wrap to the top
        playNav();
    }

    // Cycles the tab strip from anywhere in the drawer, without having to walk
    // the cursor up to it first.
    function cycleTab(step) {
        var n = tabs.length;
        tabIndex = (tabIndex + step + n) % n;
        playNav();
    }

    Keys.onPressed: {
        if (event.isAutoRepeat) return;

        // Modal: the quick menu takes everything while it's up.
        if (quickOpen) {
            event.accepted = true;
            if (api.keys.isAccept(event))      { playAccept(); runQuickAction(); }
            else if (api.keys.isCancel(event)) { playBack(); closeQuickMenu(); }
            else if (event.key === quickMenuKey) { playBack(); closeQuickMenu(); }
            return;
        }

        // Start opens the quick menu on the highlighted app.
        if (event.key === quickMenuKey) {
            event.accepted = true;
            if (zone === zoneApps) playToggle();
            openQuickMenu();
            return;
        }

        if (api.keys.isAccept(event)) {
            event.accepted = true;
            if (zone === zoneNav) triggerNav(navIndex);
            else if (zone === zoneApps) chooseCurrent();
            // Tabs are placeholders — nothing bound yet.
            return;
        }
        if (api.keys.isCancel(event)) {
            event.accepted = true;
            closeDrawer();
            return;
        }
        // LB/RB cycle the tab strip, mirroring how they move the system row
        // elsewhere in the theme. Works from any zone.
        if (api.keys.isPrevPage(event)) {                 // LB
            event.accepted = true;
            cycleTab(-1);
            return;
        }
        if (api.keys.isNextPage(event)) {                 // RB
            event.accepted = true;
            cycleTab(1);
        }
    }
}
