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
    // Gap between the panel and the screen edges. The left is deliberately
    // wider than the top/bottom — the Xbox guide sits well in from the left
    // edge while hugging top and bottom, roughly a 3:1 ratio. A uniform inset
    // is what made this read as slightly off against the reference.
    property real panelMargin: vpx(20)          // top and bottom
    property real panelMarginLeft: vpx(36)
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
    property color iconPlate: "#303030"

    // ── Palette ───────────────────────────────────────────────────────────
    // Sampled off the reference screenshot rather than eyeballed. The strip
    // behind the top nav is genuinely darker than the panel body — that
    // contrast is a lot of what makes the guide read the way it does.
    property color colPanel:    "#1F1F1F"   // panel body
    property color colTabBar:   "#191919"   // bar behind the tab strip
    property color colRowSel:   "#343434"   // highlighted row fill
    property color colDivider:  "#2A2A2A"   // rules between sections
    property color colMenu:     "#272727"   // quick menu surface
    property color colMenuSel:  "#3A3A3A"   // highlighted quick menu row

    // ── Zones ─────────────────────────────────────────────────────────────
    // The panel is three stacked navigable regions. Focus moves between them
    // vertically; each keeps its own index so returning to one lands where you
    // left it.
    readonly property int zoneTabs: 0
    readonly property int zoneNav:  1
    readonly property int zoneApps: 2
    readonly property int zoneActions: 3

    property int zone: zoneNav      // opens on Home, like the guide
    property int tabIndex: 0
    property int navIndex: 0
    property int actionIndex: 0

    // Hidden apps are hidden for a reason, so the Hidden tab is off by default
    // — otherwise the section advertises exactly what you asked to tuck away.
    // This toggle is the way back in.
    property bool showHiddenTab: false

    readonly property var actions: [
        { act: "toggleHidden", icon: "../assets/images/icon_hidden.svg",   scale: 0.84,
          on: root.showHiddenTab },
        { act: "discover",     icon: "../assets/images/icon_discover.svg", scale: 0.80 },
        { act: "achievements", icon: "../assets/images/trophy.svg",       scale: 0.92 },
        { act: "settings",     icon: "../assets/images/settingsicon.svg",  scale: 0.92 }
    ]

    // The host owns navigation; the drawer just says which tile was pressed.
    signal navDiscover()
    signal navAchievements()
    signal navSettings()

    function runAction(i) {
        var a = actions[i];
        if (!a) return;
        if (a.act === "toggleHidden") {
            // Stays open: this one changes the panel rather than leaving it.
            showHiddenTab = !showHiddenTab;
            playToggle();
            return;
        }
        closeDrawer();
        if (a.act === "discover")          navDiscover();
        else if (a.act === "achievements") navAchievements();
        else if (a.act === "settings")     navSettings();
    }

    property real navRowHeight: vpx(56)
    property real rowInset: vpx(10)      // row edge -> icon column
    property real iconGap: vpx(12)       // icon column -> label
    property real navIconSize: vpx(28)   // nav glyphs, drawn inside the icon column
    property real tabStripInset: vpx(10)
    // Divides the available width, so the icons spread evenly however many
    // tabs are showing.
    readonly property real tabWidth:
        (panelWidth - tabStripInset * 2) / Math.max(1, tabs.length)

    // Emitted when a nav row is chosen; the host decides where each one goes.
    signal navHome()
    signal navLibrary()

    readonly property var navItems: [
        { label: "Home",             icon: "../assets/images/icon_home.svg",     scale: 1.0 },
        { label: "My games & apps",  icon: "../assets/images/icon_gamesandapps.svg", scale: 1.02 }
    ]

    // Tab strip. The logo is real; the rest are throwaway shapes drawn with
    // plain Rectangles until the strip's actual contents are decided.
    //
    // Rectangles rather than Canvas: Canvas doesn't render in this build (the
    // same reason every keyboard glyph is an SVG). An entry with `icon` draws
    // that image; one with `shape` draws the named placeholder.
    // Six sections normally. Hidden is appended only while something is
    // actually hidden — a permanent seventh tab that reads "(0)" most of the
    // time is clutter, and a setting would mean configuring something almost
    // nobody touches. It can't live in the quick menu either: that menu acts on
    // the highlighted row, and a hidden app isn't in any list to highlight.
    //
    // Appended last on purpose, so its appearing and disappearing never shifts
    // the index of any other tab.
    readonly property var tabs: {
        var base = [
            { icon: "../assets/images/Xbox-logo2-tight.png", filter: "all",      label: "All" },
            { icon: "../assets/images/icon_heart.svg",  filter: "favorite", label: "Favorites", scale: 0.77 },
            { icon: "../assets/images/icon_games.svg",  filter: "game",     label: "Games", scale: 1.03 },
            { icon: "../assets/images/icon_emulator.svg", filter: "emulator", label: "Emulators", scale: 1.34 },
            { icon: "../assets/images/icon_system.svg", filter: "system",   label: "System", scale: 0.96 },
            { icon: "../assets/images/icon_other.svg",  filter: "other",    label: "Other", scale: 1.02 }
        ];
        if (hiddenCount > 0 && showHiddenTab)
            base.push({ icon: "../assets/images/icon_hidden.svg", filter: "hidden", label: "Hidden", scale: 0.84 });
        return base;
    }

    // One pass over the collection, done only when the collection itself
    // changes. packageOf() and artFor() reach into Pegasus's model (files,
    // assets), which is far too costly to call from delegate bindings or from
    // a filter that re-runs on every favourite/hide/tab change — that work is
    // cached here instead.
    readonly property var appIndex: {
        var out = [];
        var cols = activeCollections;
        if (!cols) return out;
        for (var ci = 0; ci < cols.length; ci++) {
            var gl = cols[ci].games;
            if (!gl) continue;
            for (var i = 0; i < gl.count; i++) {
                var g = gl.get(i);
                var t = g.title || "";
                out.push({
                    g: g,
                    pkg: packageOf(g),
                    art: artFor(g),
                    title: t,
                    initial: t.length > 0 ? t.charAt(0).toUpperCase() : "?"
                });
            }
        }
        return out;
    }

    // pkg -> category. Rebuilt only when the collection or a saved override
    // changes, so the rule matching runs once per app rather than once per app
    // per filter rebuild.
    readonly property var categoryMap: {
        var m = {};
        var idx = appIndex;
        for (var i = 0; i < idx.length; i++)
            m[idx[i].pkg] = categoryFor(idx[i].pkg, idx[i].title);
        return m;
    }

    // Counted against the live collection rather than the saved list, so stale
    // entries for uninstalled apps can't keep the tab alive forever.
    readonly property int hiddenCount: {
        var hid = hiddenPkgs;
        var idx = appIndex;
        var n = 0;
        for (var i = 0; i < idx.length; i++)
            if (hid[idx[i].pkg] === true) n++;
        return n;
    }

    // Unhiding the last app removes the tab under the cursor; step back so the
    // index can't dangle past the end.
    onTabsChanged: if (tabIndex >= tabs.length) tabIndex = tabs.length - 1;

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
    // Collections the drawer draws from, supplied by the host. Previously the
    // drawer matched a name itself, with fallbacks — which meant it could land
    // on a different collection than the one theme.qml hid from the system row.
    // The host resolves it now and both read the same answer.
    // Two ways to supply the source, so this works with either host wiring:
    //   collections     - an explicit list, wins when non-empty
    //   collectionMatch - a name to resolve, which is what theme.qml passes
    property var collections: []
    property string collectionMatch: "Android"

    // Resolved by exact name, then exact shortName, then substring. Exact-first
    // matters because a provider collection and a hand-written one can share a
    // shortName, and substring alone would return whichever came first.
    readonly property var resolvedCollection: {
        if (collectionMatch === "") return null;
        var needle = collectionMatch.toLowerCase();
        var i, c;
        for (i = 0; i < api.collections.count; i++) {
            c = api.collections.get(i);
            if ((c.name || "").toLowerCase() === needle) return c;
        }
        for (i = 0; i < api.collections.count; i++) {
            c = api.collections.get(i);
            if ((c.shortName || "").toLowerCase() === needle) return c;
        }
        for (i = 0; i < api.collections.count; i++) {
            c = api.collections.get(i);
            if ((c.name || "").toLowerCase().indexOf(needle) >= 0) return c;
        }
        return null;
    }

    readonly property var activeCollections: {
        if (collections && collections.length > 0) return collections;
        var c = resolvedCollection;
        return c ? [c] : [];
    }

    property bool open: false

    // Emitted with the chosen Game, so launching goes through the theme's own
    // launch path (transitions, saved state) rather than this component
    // deciding for itself.
    signal appChosen(var game)
    signal closed()
    // Emitted when focus couldn't be handed back — the host re-asserts it.
    signal focusRestoreFailed()

    anchors.fill: parent
    // Closed, the drawer must not sit in front of the screen eating input.
    visible: slide > 0.001
    enabled: open

    // The screens take focus through `focus: shown` bindings, which do NOT
    // re-assert themselves once something else steals active focus. So the item
    // that had focus is captured on open and handed back on close — this works
    // whatever screen is showing, with no per-state bookkeeping in theme.qml.
    //
    // Only safe because the screen Loaders stay loaded while the drawer is
    // open; they used to unload, which destroyed the captured item and left
    // the screen black on return.
    property var previousFocusItem: null

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
        var e = filteredApps[list.currentIndex];
        var g = e ? e.g : null;
        if (!g) return;
        // Launching suspends Pegasus; close now so returning doesn't land back
        // in a half-open drawer.
        open = false;
        // Deliberately NOT restoring focus here: the host's launch path moves
        // to the launch screen, whose own binding claims focus.
        previousFocusItem = null;
        appChosen(g);
    }

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

    function packageOf(game) {
        if (!game || !game.files || game.files.count < 1) return "";
        var p = game.files.get(0).path || "";
        // Paths arrive prefixed, e.g. "android:com.dsemu.drastic".
        var colon = p.indexOf(":");
        return colon >= 0 ? p.substring(colon + 1) : p;
    }

    function categoryFor(pkg, title) {
        // Saved reclassification beats the shipped seed, which beats the rules.
        if (pkg !== "" && savedCategories[pkg] !== undefined)
            return savedCategories[pkg];
        if (pkg !== "" && categoryOverrides[pkg] !== undefined)
            return categoryOverrides[pkg];

        var p = pkg.toLowerCase();
        var t = (title || "").toLowerCase();
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
    readonly property int appCount: filteredApps.length

    readonly property var filteredApps: {
        var out = [];
        var idx = appIndex;
        var want = activeFilter;
        var fav = favoritePkgs, hid = hiddenPkgs, cats = categoryMap;
        for (var i = 0; i < idx.length; i++) {
            var e = idx[i];
            // Hidden apps are gone from every tab except Hidden itself,
            // otherwise there'd be no way to get them back.
            if (want !== "hidden" && hid[e.pkg] === true) continue;
            if (want === "all") { out.push(e); continue; }
            if (want === "favorite") { if (fav[e.pkg] === true) out.push(e); continue; }
            if (want === "hidden")   { if (hid[e.pkg] === true) out.push(e); continue; }
            if (cats[e.pkg] === want) out.push(e);
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
        x: -(root.panelWidth + root.panelMarginLeft) * (1 - root.slide) + root.panelMarginLeft
        y: root.panelMargin
        height: parent.height - (root.panelMargin * 2)
        radius: root.panelRadius
        color: root.colPanel

        // No border: the reference has none. An outline here read as a card
        // sitting on the screen rather than part of the shell.

        // Darker bar behind the top nav.
        Item {
        id: tabBar

            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: tabStrip.y + tabStrip.height + vpx(10)

            // Two rectangles because a single one with a radius would round all
            // four corners — the lower squares off the bottom so only the
            // panel's top corners stay curved.
            Rectangle {
                anchors.fill: parent
                radius: root.panelRadius
                color: root.colTabBar
            }
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: root.panelRadius
                color: root.colTabBar
            }

            // The accent IS the bottom edge of the bar, under the active tab —
            // in the reference there's no separate underline and no divider
            // rule; away from the active tab the dark bar just meets the body.
            Rectangle {
                anchors.bottom: parent.bottom
                x: tabStrip.x + root.tabIndex * root.tabWidth
                     + (root.tabWidth - width) / 2
                width: root.tabWidth * 0.62
                height: vpx(5)
                radius: height / 2
                color: theme.accent
                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
        }

        // ── Tab strip ─────────────────────────────────────────────────────
        // Placeholders for now — edit root.tabs to change them. Each entry is
        // just an icon plus an action, so wiring one up later is a one-liner.
        Row {
        id: tabStrip

            anchors {
                top: parent.top; topMargin: vpx(14)
                left: parent.left; leftMargin: root.tabStripInset
                right: parent.right; rightMargin: root.tabStripInset
            }
            height: vpx(46)
            spacing: 0

            Repeater {
                model: root.tabs
                delegate: Item {
                    width: root.tabWidth; height: tabStrip.height
                    // Which section is showing — stays lit wherever the cursor
                    // is, so the strip always says where you are.
                    readonly property bool active: root.tabIndex === index
                    // Whether the cursor is actually on the strip. Drawn as a
                    // backing plate so it reads differently from `active`.
                    readonly property bool focused: active && root.zone === root.zoneTabs

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: vpx(3)
                        visible: parent.focused
                        radius: vpx(6)
                        color: Qt.rgba(1, 1, 1, 0.08)
                    }

                    Image {
                        anchors.centerIn: parent
                        visible: modelData.icon !== undefined
                        // Larger than the drawn placeholders: the logo has its
                        // own internal padding, so matching their box size left
                        // it looking like a dot.
                        // Per-tab scale: these are separate assets with
                        // different amounts of built-in padding.
                        width: vpx(30) * (modelData.scale !== undefined ? modelData.scale : 1)
                        height: width
                        source: modelData.icon !== undefined ? modelData.icon : ""
                        sourceSize { width: Math.round(width * 2); height: Math.round(width * 2) }
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        opacity: parent.active ? 1.0 : 0.5
                    }

                    // Drawn placeholders. Deliberately plain — they're meant to
                    // be replaced, and shapes make that obvious at a glance.
                    Item {
                        anchors.centerIn: parent
                        visible: modelData.shape !== undefined
                        width: vpx(22); height: vpx(22)
                        opacity: parent.active ? 1.0 : 0.5

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
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { root.zone = root.zoneTabs; root.tabIndex = index; }
                    }
                }
            }
        }


        // ── Home / My games & apps ────────────────────────────────────────
        Column {
        id: navSection

            anchors {
                top: tabBar.bottom; topMargin: vpx(12)
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
                        color: parent.current ? root.colRowSel : "transparent"
                        border.width: parent.current ? vpx(2) : 0
                        border.color: theme.accent
                    }

                    Row {
                        anchors {
                            left: parent.left; leftMargin: root.rowInset
                            right: parent.right; rightMargin: vpx(18)
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: root.iconGap

                        // Same width as an app tile: the glyph is centred in
                        // that column so both the icons and the labels below
                        // line up, rather than each row carrying its own inset.
                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.iconSize; height: root.iconSize
                            Image {
                                anchors.centerIn: parent
                                // Per-item scale: these are separate assets with
                                // different amounts of built-in padding.
                                width: root.navIconSize * (modelData.scale !== undefined ? modelData.scale : 1)
                                height: width
                                source: modelData.icon
                                sourceSize { width: Math.round(width * 2); height: Math.round(width * 2) }
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - root.iconSize - root.iconGap
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
            color: root.colDivider
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
            text: (root.activeCollections && root.activeCollections.length > 0)
                  ? (root.activeFilter === "all"
                     ? "No apps in the selected collections."
                     : "Nothing in this category yet.")
                  : "No collections are set to appear here.\nSettings > Systems, "
                    + "then set a collection's App Drawer option to Include."
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
                bottom: actionBar.top; bottomMargin: vpx(8)
            }
            visible: root.appCount > 0
            clip: true
            // Kept resident while closed. Emptying the model on close saved a
            // dozen tiny decoded icons, but meant every open rebuilt all the
            // delegates and re-decoded every icon — they visibly popped in one
            // by one. A dozen 64px images is negligible; the reopen cost isn't.
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
                    color: parent.current ? root.colRowSel : "transparent"
                    border.color: theme.accent
                    border.width: parent.current ? vpx(2) : 0

                    Row {
                        anchors {
                            left: parent.left; leftMargin: root.rowInset
                            right: parent.right; rightMargin: vpx(10)
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: root.iconGap

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
                            readonly property bool hasArt: modelData.art !== ""

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
                                    source: modelData.art
                                    // Decoded at the zoomed size so scaling up
                                    // doesn't soften the icon.
                                    sourceSize {
                                        width: Math.round(root.iconSize * root.iconZoom * 1.4)
                                        height: Math.round(root.iconSize * root.iconZoom * 1.4)
                                    }
                                    fillMode: Image.PreserveAspectCrop
                                    // Scales about the centre; the surrounding
                                    // layer clips the overflow.
                                    scale: root.iconZoom
                                    // Async is safe here: the blank-tile race
                                    // came from layer.enabled tracking load
                                    // status, and that's keyed to hasArt now.
                                    // Sync decode blocked the UI thread once
                                    // per row created.
                                    asynchronous: true
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
                                    text: modelData.initial
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
                            text: modelData.title
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
                            visible: root.favoritePkgs[modelData.pkg] === true
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

        // ── Action bar ────────────────────────────────────────────────────
        // Square tiles along the foot, as the guide has. Left to right:
        // show/hide hidden, Discover, achievements, settings.
        Row {
        id: actionBar

            anchors {
                left: parent.left; leftMargin: root.tabStripInset
                right: parent.right; rightMargin: root.tabStripInset
                bottom: parent.bottom; bottomMargin: vpx(14)
            }
            // Fills the panel edge to edge: the tiles divide whatever width is
            // left after the insets and gaps, and height follows so they stay
            // square. No cap — capping them was what left them clustered in the
            // middle with dead space either side.
            readonly property real tileSize:
                (width - spacing * (root.actions.length - 1)) / root.actions.length
            height: tileSize
            // Wider gaps shrink the tiles; this is the knob for their size now
            // that the row is width-locked.
            spacing: vpx(14)

            Repeater {
                model: root.actions
                delegate: Rectangle {
                    width: actionBar.tileSize
                    height: actionBar.tileSize
                    readonly property bool current: root.zone === root.zoneActions
                                                    && root.actionIndex === index
                    radius: vpx(6)
                    color: current ? root.colRowSel : root.colTabBar
                    border.width: current ? vpx(2) : 0
                    border.color: theme.accent

                    Image {
                        anchors.centerIn: parent
                        width: actionBar.tileSize * 0.5
                               * (modelData.scale !== undefined ? modelData.scale : 1)
                        height: width
                        source: modelData.icon
                        sourceSize { width: Math.round(width * 2); height: Math.round(width * 2) }
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    // Accent pip marks the toggle's on-state; the icon itself
                    // is identical either way.
                    Rectangle {
                        anchors { bottom: parent.bottom; bottomMargin: vpx(5)
                                  horizontalCenter: parent.horizontalCenter }
                        width: vpx(14); height: vpx(3)
                        radius: height / 2
                        color: theme.accent
                        visible: modelData.on === true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.zone = root.zoneActions;
                            root.actionIndex = index;
                            root.runAction(index);
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
                // Follows the active tab. Falls back to the logo for any tab
                // still on a drawn placeholder — none are, currently.
                readonly property var tab: root.tabs[root.tabIndex]
                readonly property real iconScale:
                    (tab && tab.scale !== undefined) ? tab.scale : 1
                width: vpx(26) * iconScale
                height: width
                source: (tab && tab.icon !== undefined)
                        ? tab.icon : "../assets/images/Xbox-logo2-tight.png"
                sourceSize { width: Math.round(width * 2); height: Math.round(width * 2) }
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

    // Human-readable name for a category key, used in the menu header.
    function categoryLabel(cat) {
        if (cat === "game")     return "Games";
        if (cat === "emulator") return "Emulators";
        if (cat === "system")   return "System";
        if (cat === "favorite") return "Favorites";
        return "Other";
    }

    readonly property var quickActions: {
        var pkg = root.quickApp ? root.quickApp.pkg : "";
        return [
            { label: root.isFavorite(pkg) ? "Remove from Favorites" : "Add to Favorites",
              act: "fav",  icon: "../assets/images/icon_heart.svg",     scale: 0.90 },
            { label: root.isHidden(pkg)   ? "Unhide app" : "Hide app",
              act: "hide", icon: "../assets/images/icon_hidden.svg",    scale: 0.95 },
            { label: "Move to Games",      act: "cat", cat: "game",
              icon: "../assets/images/icon_games.svg",    scale: 1.15 },
            { label: "Move to Emulators",  act: "cat", cat: "emulator",
              icon: "../assets/images/icon_emulator.svg", scale: 1.45 },
            { label: "Move to System",     act: "cat", cat: "system",
              icon: "../assets/images/icon_system.svg",   scale: 1.05 },
            { label: "Move to Other",      act: "cat", cat: "other",
              icon: "../assets/images/icon_other.svg",    scale: 1.10 },
            { label: "Reset to automatic", act: "reset",
              icon: "../assets/images/icon_reset.svg",    scale: 1.05 }
        ];
    }

    function openQuickMenu() {
        if (zone !== zoneApps) return;
        if (list.currentIndex < 0 || list.currentIndex >= filteredApps.length) return;
        quickApp = filteredApps[list.currentIndex];   // cached entry, not a raw Game
        quickIndex = 0;
        quickOpen = true;
    }
    function closeQuickMenu() {
        quickOpen = false;
        quickApp = null;
    }
    function runQuickAction() {
        var a = quickActions[quickIndex];
        var pkg = quickApp ? quickApp.pkg : "";
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
        width: vpx(380)
        height: quickCol.height + vpx(30)
        radius: vpx(10)
        color: root.colMenu
        border.width: vpx(1)
        border.color: Qt.rgba(1, 1, 1, 0.10)
        visible: root.quickOpen
        opacity: root.quickOpen ? 1 : 0
        scale: root.quickOpen ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 2 } }

        Column {
        id: quickCol

            anchors { top: parent.top; topMargin: vpx(14); left: parent.left; right: parent.right }
            spacing: vpx(2)

            // Header: which app this menu is acting on, and where it currently
            // sits, so a reclassification can be judged before it's made.
            Item {
                width: quickCol.width
                height: hdrRow.height + vpx(14)

                Row {
                id: hdrRow

                    anchors { left: parent.left; leftMargin: vpx(20)
                              right: parent.right; rightMargin: vpx(20)
                              top: parent.top }
                    spacing: vpx(10)

                    Text {
                        id: hdrTitle
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, hdrRow.width - hdrCat.width - vpx(10))
                        text: root.quickApp ? root.quickApp.title : ""
                        color: "white"
                        font.family: titleFont.name
                        font.pixelSize: fpx(19)
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        id: hdrCat
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.quickApp
                              ? root.categoryLabel(root.categoryMap[root.quickApp.pkg]) : ""
                        color: theme.accent
                        font.family: subtitleFont.name
                        font.pixelSize: fpx(15)
                        font.bold: true
                    }
                }
            }

            Repeater {
                model: root.quickActions
                delegate: Item {
                    width: quickCol.width
                    height: vpx(46)
                    readonly property bool current: root.quickIndex === index

                    Rectangle {
                        anchors {
                            fill: parent
                            leftMargin: vpx(10); rightMargin: vpx(10)
                            topMargin: vpx(1); bottomMargin: vpx(1)
                        }
                        radius: vpx(5)
                        color: parent.current ? root.colMenuSel : "transparent"
                        border.width: parent.current ? vpx(2) : 0
                        border.color: theme.accent
                    }
                    Row {
                        anchors {
                            left: parent.left; leftMargin: vpx(22)
                            right: parent.right; rightMargin: vpx(18)
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: vpx(14)

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: vpx(22); height: vpx(22)
                            Image {
                                anchors.centerIn: parent
                                width: vpx(20) * (modelData.scale !== undefined ? modelData.scale : 1)
                                height: width
                                source: modelData.icon
                                sourceSize { width: Math.round(width * 2); height: Math.round(width * 2) }
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                opacity: 0.9
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - vpx(22) - vpx(14)
                            text: modelData.label
                            color: "white"
                            font.family: subtitleFont.name
                            font.pixelSize: fpx(16)
                            elide: Text.ElideRight
                        }
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
        if (zone === zoneActions) {
            if (appCount > 0) { zone = zoneApps; list.currentIndex = list.count - 1; }
            else { zone = zoneNav; navIndex = navItems.length - 1; }
            playNav();
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
            if (appCount > 0) { zone = zoneApps; list.currentIndex = 0; }
            else zone = zoneActions;
            playNav();
            return;
        }
        if (zone === zoneActions) return;      // bottom of the panel
        // Past the end of the list, drop into the action bar; Up comes back.
        if (list.currentIndex < list.count - 1) { list.currentIndex++; playNav(); return; }
        zone = zoneActions;
        actionIndex = 0;
        playNav();
    }

    // Left/Right page through the app list, wrapping at both ends. They used to
    // move the tab strip; that's on LB/RB now, matching the nav bar elsewhere.
    Keys.onLeftPressed: {
        event.accepted = true;
        if (quickOpen) return;
        if (zone === zoneTabs) { cycleTab(-1); return; }
        if (zone === zoneActions) {
            if (actionIndex > 0) { actionIndex--; playNav(); }
            return;
        }
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
        if (zone === zoneActions) {
            if (actionIndex < actions.length - 1) { actionIndex++; playNav(); }
            return;
        }
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
            else if (zone === zoneActions) runAction(actionIndex);
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
