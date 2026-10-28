// XboxOSv2 – the app drawer's data, kept apart from its screen.
//
// The index of Android apps, their categories, and what you've favourited,
// hidden or reclassified. theme.qml needs these at startup (the Home and
// library "hide" sets are built from them), while the drawer's screen is only
// needed when it's opened — so the data lives here, always, and the screen
// (AppDrawer.qml) is created on first open and reads from this object.
import QtQuick 2.15

QtObject {
id: lib
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
    // Windows / Linux: the drawer holds PC entries from your "PC Apps"
    // collection, sorted into PC tabs by the genre you give each one.
    // PC game collections (names) the host added to `collections`: their
    // entries always land in Games.
    property var pcGameCollections: []
    property bool pcMode: false
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

    // One pass over the collection, done only when the collection itself
    // changes. packageOf() and artFor() reach into Pegasus's model (files,
    // assets), which is far too costly to call from delegate bindings or from
    // a filter that re-runs on every favourite/hide/tab change — that work is
    // cached here instead.
    //
    // Several sources now (the host passes "Android" plus your android /
    // androidapps / androidgames collections), so:
    //   - one entry per title: an entry of yours replaces a Pegasus import of
    //     the same title (yours has your metadata and art); otherwise first wins
    //   - each entry carries a category hint from its genre / collection,
    //     used by categoryFor() below
    //   - an entry with no file gets its title as its key, so two of them
    //     can't share one favourite/hidden/category slot
    readonly property var appIndex: {
        var out = [];
        var at = {};                         // title -> position in out
        var cols = activeCollections;
        if (!cols) return out;
        for (var ci = 0; ci < cols.length; ci++) {
            var gl = cols[ci].games;
            if (!gl) continue;
            var gamesCol = ((cols[ci].shortName || "").toLowerCase() === "androidgames");
            var pcGamesCol = pcMode && pcGameCollections.indexOf(cols[ci].name) >= 0;
            for (var i = 0; i < gl.count; i++) {
                var g = gl.get(i);
                var t = g.title || "";
                var pkg = packageOf(g);
                var imported = (g.files && g.files.count > 0
                                && (g.files.get(0).path || "").indexOf("android:") === 0);
                var e = {
                    g: g,
                    pkg: pkg !== "" ? pkg : "title:" + t,
                    art: artFor(g),
                    title: t,
                    initial: t.length > 0 ? t.charAt(0).toUpperCase() : "?",
                    imported: imported,
                    hint: pcGamesCol ? "game" : categoryHint(g, gamesCol, imported)
                };
                var prev = (t !== "") ? at[t] : undefined;
                if (prev === undefined) {
                    if (t !== "") at[t] = out.length;
                    out.push(e);
                } else if (out[prev].imported && !imported) {
                    out[prev] = e;           // yours beats the import
                }
            }
        }
        // One A-to-Z order for every tab, upper and lower case alike, whatever
        // collection or source an entry came from (filteredApps keeps it).
        out.sort(function(a, b) {
            var ta = a.title.toLowerCase(), tb = b.title.toLowerCase();
            return ta < tb ? -1 : (ta > tb ? 1 : 0);
        });
        return out;
    }

    // pkg -> category. Rebuilt only when the collection or a saved override
    // changes, so the rule matching runs once per app rather than once per app
    // per filter rebuild.
    readonly property var categoryMap: {
        var m = {};
        var idx = appIndex;
        for (var i = 0; i < idx.length; i++)
            m[idx[i].pkg] = categoryFor(idx[i].pkg, idx[i].title, idx[i].hint);
        return m;
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
    // Two independent kinds of hidden, chosen from the Hide panel:
    //   hiddenPkgs        - hidden in THIS drawer (and its Hidden tab shows it)
    //   libraryHiddenPkgs - hidden from the library: Home, the platform pages
    //                       and All Games (theme.qml builds its rows-to-hide
    //                       lists from this). Still listed in the drawer.
    // Hide panel: App drawer only / Library only / Both / Unhide.
    property var libraryHiddenPkgs: ({})

    readonly property string memFavorites: "appdrawer.favorites"
    readonly property string memHidden: "appdrawer.hidden"
    readonly property string memCategories: "appdrawer.categories"
    readonly property string memLibraryHidden: "appdrawer.libraryhidden"

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
        libraryHiddenPkgs = parseObj(api.memory.get(memLibraryHidden));
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
    function isLibraryHidden(pkg) { return pkg !== "" && libraryHiddenPkgs[pkg] === true; }
    // "none" | "drawer" | "library" | "both" — the Hide panel's current choice.
    function hideMode(pkg) {
        var d = isHidden(pkg), l = isLibraryHidden(pkg);
        return (d && l) ? "both" : d ? "drawer" : l ? "library" : "none";
    }
    function setHideMode(pkg, mode) {
        if (pkg === "") return;
        var d = (mode === "drawer"  || mode === "both");
        var l = (mode === "library" || mode === "both");
        if (d !== isHidden(pkg)) {
            hiddenPkgs = withKey(hiddenPkgs, pkg, d ? true : undefined);
            api.memory.set(memHidden, JSON.stringify(hiddenPkgs));
        }
        if (l !== isLibraryHidden(pkg)) {
            libraryHiddenPkgs = withKey(libraryHiddenPkgs, pkg, l ? true : undefined);
            api.memory.set(memLibraryHidden, JSON.stringify(libraryHiddenPkgs));
        }
    }

    function toggleFavorite(pkg) {
        if (pkg === "") return;
        favoritePkgs = withKey(favoritePkgs, pkg, isFavorite(pkg) ? undefined : true);
        api.memory.set(memFavorites, JSON.stringify(favoritePkgs));
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

    // Section from what your metadata says, for entries you added yourself.
    // Pegasus imports have no genre, so they get no hint and fall through to
    // the keyword rules as before.
    //   genre "Emulator"                          -> emulator
    //   in an androidgames collection, not tagged
    //   "Application"                             -> game
    function categoryHint(g, gamesCol, imported) {
        if (!g) return "";
        // PC: the genre picks the tab. Game, Emulator, Launcher, App, Tool,
        // Power (Sleep / Restart / Shut down — the drawer's Power tile).
        if (pcMode) {
            var pgl = g.genreList;
            for (var p = 0; pgl && p < pgl.length; p++) {
                var pg = (pgl[p] || "").toLowerCase();
                if (pg === "game" || pg === "games") return "game";
                if (pg === "emulator" || pg === "emulators") return "emulator";
                if (pg === "launcher" || pg === "launchers" || pg === "store") return "launcher";
                if (pg === "app" || pg === "apps" || pg === "application") return "app";
                if (pg === "tool" || pg === "tools" || pg === "system" || pg === "utility") return "tool";
                if (pg === "power") return "power";
            }
            return "";
        }
        // Pegasus X tags every Android entry, its own imports included
        // (Game / Emulator / Application); Application falls through to the
        // rules below, which tell system apps from the rest.
        var tl = g.tagList;
        for (var t = 0; tl && t < tl.length; t++) {
            var tt = (tl[t] || "").toLowerCase();
            if (tt === "game") return "game";
            if (tt === "emulator") return "emulator";
        }
        if (imported) return "";
        var gl = g.genreList, isApp = false;
        for (var i = 0; gl && i < gl.length; i++) {
            var gg = (gl[i] || "").toLowerCase();
            if (gg === "emulator") return "emulator";
            if (gg === "application") isApp = true;
        }
        return (gamesCol && !isApp) ? "game" : "";
    }

    function categoryFor(pkg, title, hint) {
        // Saved reclassification beats the shipped seed, which beats your
        // metadata's hint, which beats the rules.
        if (pkg !== "" && savedCategories[pkg] !== undefined)
            return savedCategories[pkg];
        if (pkg !== "" && categoryOverrides[pkg] !== undefined)
            return categoryOverrides[pkg];
        if (hint) return hint;

        var p = pkg.toLowerCase();
        var t = (title || "").toLowerCase();
        var i;
        for (i = 0; i < systemPrefixes.length; i++)
            if (p.indexOf(systemPrefixes[i]) === 0) return "system";
        for (i = 0; i < emulatorKeywords.length; i++)
            if (p.indexOf(emulatorKeywords[i]) >= 0 || t.indexOf(emulatorKeywords[i]) >= 0)
                return "emulator";
        return pcMode ? "app" : "other";
    }

    // Pegasus only has art for some installed apps, so try the asset slots an
    // app icon realistically lands in and let the delegate fall back to a
    // letter tile when they're all empty.
    function artFor(g) {
        if (!g || !g.assets) return "";
        var a = g.assets;
        return a.boxFront || a.tile || a.logo || a.banner || a.poster || "";
    }
}
