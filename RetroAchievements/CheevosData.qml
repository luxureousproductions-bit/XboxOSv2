// XboxOSv2 – RetroAchievements data layer
// Handles all API communication with retroachievements.org and owns the
// ListModels consumed by AchievementsView and GameAchievementsView.

import QtQuick 2.15

Item {
id: root

    // ── Public properties ────────────────────────────────────────────────
    property alias raRecentGames: raRecentGames
    property alias raGameCheevos: raGameCheevos

    property string raUserName:      ""
    property string raApiKey:        ""

    property string avatarUrl:       ""
    property int    softcorePoints:  0
    property int    hardcorePoints:  0
    property int    userRank:        0
    property int    totalTruePoints: 0   // "RetroPoints" (weighted score)
    property string memberSince:     ""
    property string statusText:      ""

    // Details for the game whose achievements are currently loaded
    property var currentGameDetails: ({
        "Title":                    "",
        "ImageIcon":                "",
        "ConsoleName":              "",
        "NumAchievements":          0,
        "NumAwardedToUser":         0,
        "NumAwardedToUserHardcore": 0,
        "PossibleScore":            0,
        "ScoreAchieved":            0
    })

    property int currentGameID: 0

    // ── Filter / sort state (consumed by GameAchievementsView) ───────────
    // filterMode: "all" | "earned" | "locked"
    // sortMode:   "default" | "points" | "rarity" | "date"
    property string filterMode: "all"
    property string sortMode:   "default"

    // ── Game lookup state (used by RAGameEntryView) ──────────────────────
    property int    pendingGameID:    -1
    property bool   lookupInProgress: false
    property string lookupStatusMsg:  ""

    // Guard so loadUserProfile fires only once per session, even when
    // entering RA from GameView before Overview has ever been opened.
    property bool profileLoaded: false

    // ── Pegasus shortName → RA console ID ────────────────────────────────
    readonly property var consoleMappings: ({
        // Nintendo handhelds
        "gb":             4,  "gameboy":        4,
        "gbc":            6,  "gameboycolor":   6,
        "gba":            5,  "gameboyadvance": 5,
        "pokemini":      24,
        "virtualboy":    28,  "vb":            28,  "vboy":          28,
        "nds":           18,  "ds":            18,
        "dsi":           78,  "nintendodsi":   78,
        // Nintendo home consoles / FDS
        "nes":            7,  "famicom":        7,
        "fds":           81,  "famicomdisksystem": 81,
        "snes":           3,  "superfamicom":   3,
        "n64":            2,  "nintendo64":     2,
        "gc":            16,  "gamecube":      16,  "ngc":           16,
        "wii":           19,
        // Sega
        "genesis":        1,  "megadrive":      1,  "md":             1,
        "sms":           11,  "mastersystem":  11,
        "gamegear":      15,  "gg":            15,
        "32x":           10,  "sega32x":       10,
        "segacd":         9,  "megacd":         9,  "scd":            9,
        "saturn":        39,
        "dreamcast":     40,  "dc":            40,
        "sg1000":        33,  "sg-1000":       33,
        "segapico":      68,  "pico":          68,
        // Sony
        "psx":           12,  "ps1":           12,  "playstation":   12,
        "ps2":           21,  "playstation2":  21,
        "psp":           41,
        // NEC
        "pce":            8,  "tg16":           8,  "pcengine":       8,
        "pcecd":         76,  "tgcd":          76,  "pcenginecd":    76,
        "pc88":          47,  "pc8800":        47,
        "pcfx":          49,
        // SNK
        "neogeo":        14,  "ngp":           14,  "ngpc":          14,
        "neogeopocket":  14,
        "neogeocd":      56,  "ngcd":          56,
        // Atari
        "atari2600":     25,  "2600":          25,
        "atari7800":     51,  "7800":          51,
        "lynx":          13,  "atarilynx":     13,
        "jaguar":        17,  "atarijaguar":   17,
        "jaguarcd":      77,
        // Other
        "3do":           43,
        "coleco":        44,  "colecovision":  44,
        "intellivision": 45,  "intv":          45,
        "vectrex":       46,
        "wonderswan":    53,  "ws":            53,  "wsc":           53,
        "megaduck":      69,
        "watara":        63,  "supervision":   63,
        "channelf":      57,  "fairchildchannelf": 57,
        "arcadia2001":   73,  "arcadia":       73,
        "odyssey2":      23,  "o2":            23,
        "vc4000":        74,
        // Home computers
        "c64":           30,  "commodore64":   30,
        "msx":           29,
        "amstradcpc":    37,  "cpc":           37,
        "apple2":        38,  "appleii":       38,
        // Arcade
        "arcade":        27,  "mame":          27
    })

    // ── Formatted strings for UI headers ─────────────────────────────────
    // Adds thousands separators (e.g. 12345 -> "12,345").
    // Manual loop instead of a regex — QML's JS engine mishandles the
    // zero-width global lookahead and can emit a doubled comma.
    function raFmt(n) {
        var s = (Math.round(n) || 0).toString();
        var neg = s.charAt(0) === "-";
        if (neg) s = s.substring(1);
        var out = "";
        for (var i = 0; i < s.length; i++) {
            if (i > 0 && (s.length - i) % 3 === 0) out += ",";
            out += s.charAt(i);
        }
        return (neg ? "-" : "") + out;
    }
    property string pointsText: {
        if (raUserName === "") return "";
        var parts = [ raFmt(hardcorePoints) + " HC" ];
        if (softcorePoints  > 0) parts.push(raFmt(softcorePoints)  + " SC");
        if (totalTruePoints > 0) parts.push(raFmt(totalTruePoints) + " true");
        if (userRank        > 0) parts.push("Rank #" + raFmt(userRank));
        return parts.join("  ·  ");
    }

    property string memberText: {
        if (memberSince === "") return "";
        // memberSince arrives as "YYYY-MM-DD HH:MM:SS" — just show the date part
        return "Member since " + memberSince.substring(0, 10);
    }

    // ── Internal models ──────────────────────────────────────────────────
    ListModel { id: raRecentGames }
    ListModel { id: raGameCheevos }

    // ── Filtered / sorted view of raGameCheevos ───────────────────────────
    // JS array rebuilt whenever the model, filter, or sort changes.
    // GameAchievementsView binds its ListView to this instead of raGameCheevos.
    property var filteredCheevos: []

    function rebuildFilteredCheevos() {
        var list = [];
        for (var i = 0; i < raGameCheevos.count; i++) {
            var a = raGameCheevos.get(i);
            if (filterMode === "earned" && !(a.DateEarned > 0)) continue;
            if (filterMode === "locked" &&  (a.DateEarned > 0)) continue;
            list.push({
                Title:        a.Title,
                Description:  a.Description,
                Points:       a.Points,
                BadgeName:    a.BadgeName,
                DisplayOrder: a.DisplayOrder,
                DateEarned:   a.DateEarned,
                Hardcore:     a.Hardcore,
                Rarity:       a.Rarity,
                TrueRatio:    a.TrueRatio
            });
        }
        // Sort
        if (sortMode === "points") {
            list.sort(function(a, b) { return b.Points - a.Points; });
        } else if (sortMode === "rarity") {
            // Lower rarity % = rarer = show first
            list.sort(function(a, b) { return a.Rarity - b.Rarity; });
        } else if (sortMode === "date") {
            list.sort(function(a, b) {
                // Earned first (most recent), then unearned by DisplayOrder
                if (a.DateEarned > 0 && b.DateEarned === 0) return -1;
                if (a.DateEarned === 0 && b.DateEarned > 0) return 1;
                if (a.DateEarned > 0 && b.DateEarned > 0)  return b.DateEarned - a.DateEarned;
                return a.DisplayOrder - b.DisplayOrder;
            });
        } else {
            // Default: earned (most-recently-earned first), then unearned by DisplayOrder
            list.sort(function(a, b) {
                if (a.DateEarned > 0 && b.DateEarned === 0) return -1;
                if (a.DateEarned === 0 && b.DateEarned > 0) return 1;
                if (a.DateEarned > 0 && b.DateEarned > 0)  return b.DateEarned - a.DateEarned;
                return a.DisplayOrder - b.DisplayOrder;
            });
        }
        filteredCheevos = list;
    }

    onFilterModeChanged: rebuildFilteredCheevos()
    onSortModeChanged:   rebuildFilteredCheevos()

    // Convenience counts for the tab badges
    property int countEarned: {
        var n = 0;
        for (var i = 0; i < raGameCheevos.count; i++)
            if (raGameCheevos.get(i).DateEarned > 0) n++;
        return n;
    }
    property int countLocked: raGameCheevos.count - countEarned

    // ── Credential helpers ───────────────────────────────────────────────
    function reload() {
        raUserName = api.memory.has("RA Username") ? api.memory.get("RA Username") : "";
        raApiKey   = api.memory.has("RA API Key")  ? api.memory.get("RA API Key")  : "";
        var cached = api.memory.has("raAvatarPath") ? api.memory.get("raAvatarPath") : "";
        if (cached !== "")
            avatarUrl = "https://media.retroachievements.org" + cached;
    }

    // Load stored credentials at startup so "signed in" state (and the showcase
    // RA card) is populated immediately — without having to open an RA page first.
    // If signed in, fetch the live profile once (avatar/points/member).
    Component.onCompleted: {
        reload();
        if (raUserName !== "" && raApiKey !== "" && !profileLoaded)
            loadUserProfile();
    }

    // ── Core HTTP helper ─────────────────────────────────────────────────
    function raRequest(apiName, args, handler, errorHandler) {
        if (!raUserName || !raApiKey) {
            statusText = "Configure your credentials in Settings → Retro Achievements";
            if (errorHandler) errorHandler();
            return;
        }
        var url = "https://retroachievements.org/API/API_" + apiName
                  + ".php?z=" + encodeURIComponent(raUserName)
                  + "&y=" + encodeURIComponent(raApiKey)
                  + (args !== "" ? "&" + args : "");
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status === 200) {
                try {
                    handler(JSON.parse(xhr.responseText));
                } catch(e) {
                    statusText = "Error parsing server response";
                    if (errorHandler) errorHandler();
                }
            } else if (xhr.status === 0) {
                statusText = "No network connection";
                if (errorHandler) errorHandler();
            } else if (xhr.status === 401) {
                statusText = "Invalid credentials — check Settings";
                if (errorHandler) errorHandler();
            } else {
                statusText = "Server error " + xhr.status;
                if (errorHandler) errorHandler();
            }
        };
        xhr.send();
    }

    // ── API calls ────────────────────────────────────────────────────────

    function loadUserProfile() {
        profileLoaded = true;
        raRequest(
            "GetUserSummary",
            "u=" + encodeURIComponent(raUserName) + "&g=0&a=0",
            function(resp) {
                softcorePoints  = parseInt(resp.TotalSoftcorePoints || resp.SoftcorePoints) || 0;
                hardcorePoints  = parseInt(resp.TotalPoints         || resp.Points)         || 0;
                totalTruePoints = parseInt(resp.TotalTruePoints)    || 0;
                userRank        = parseInt(resp.Rank)               || 0;
                memberSince     = resp.MemberSince                  || "";
                if (resp.UserPic) {
                    avatarUrl = "https://media.retroachievements.org" + resp.UserPic;
                    api.memory.set("raAvatarPath", resp.UserPic);
                }
            }
        );
        // GetUserSummary often omits the global rank — fetch it from the
        // dedicated endpoint so the card/pages show the real rank, not #0.
        raRequest(
            "GetUserRankAndScore",
            "u=" + encodeURIComponent(raUserName),
            function(resp) {
                var r = parseInt(resp.Rank);
                if (isNaN(r)) r = parseInt(resp.rank);
                if (!isNaN(r) && r > 0) userRank = r;
            }
        );
    }

    function loadRecentGames() {
        statusText = "Loading...";
        raRecentGames.clear();
        raRequest(
            "GetUserRecentlyPlayedGames",
            "u=" + encodeURIComponent(raUserName) + "&c=20&o=0",
            function(resp) {
                for (var i = 0; i < resp.length; i++) {
                    var g = resp[i];
                    var possible = parseInt(g.NumPossibleAchievements) || 0;
                    var achieved = parseInt(g.NumAchieved)             || 0;
                    raRecentGames.append({
                        "GameID":                  parseInt(g.GameID)  || 0,
                        "ConsoleName":             g.ConsoleName       || "",
                        "Title":                   g.Title             || "",
                        "ImageIcon":               g.ImageIcon         || "",
                        "LastPlayed":              g.LastPlayed        || "",
                        "NumPossibleAchievements": possible,
                        "PossibleScore":           parseInt(g.PossibleScore)  || 0,
                        "NumAchieved":             achieved,
                        "ScoreAchieved":           parseInt(g.ScoreAchieved) || 0,
                        // Pre-compute progress ratio (0.0–1.0) for the progress bar
                        "Progress":                possible > 0 ? achieved / possible : 0.0
                    });
                }
                statusText = (raRecentGames.count === 0) ? "No recently played games" : "";
            }
        );
    }

    function loadGameAchievements(gameID) {
        currentGameID = gameID;
        filterMode    = "all";      // reset filters on each new game
        sortMode      = "default";
        statusText    = "Loading...";
        raGameCheevos.clear();
        filteredCheevos = [];
        currentGameDetails = {
            "Title": "", "ImageIcon": "", "ConsoleName": "",
            "NumAchievements": 0, "NumAwardedToUser": 0,
            "NumAwardedToUserHardcore": 0,
            "PossibleScore": 0, "ScoreAchieved": 0
        };

        raRequest(
            "GetGameInfoAndUserProgress",
            "u=" + encodeURIComponent(raUserName) + "&g=" + gameID,
            function(resp) {
                currentGameDetails = {
                    "Title":                    resp.Title       || "",
                    "ImageIcon":                resp.ImageIcon   || "",
                    "ConsoleName":              resp.ConsoleName  || "",
                    "NumAchievements":          parseInt(resp.NumAchievements)          || 0,
                    "NumAwardedToUser":         parseInt(resp.NumAwardedToUser)         || 0,
                    "NumAwardedToUserHardcore": parseInt(resp.NumAwardedToUserHardcore) || 0,
                    "PossibleScore":            parseInt(resp.PossibleScore)            || 0,
                    "ScoreAchieved":            parseInt(resp.ScoreAchieved)            || 0
                };

                var list = [];
                var achievements = resp.Achievements || {};
                var totalPlayers = parseInt(resp.NumDistinctPlayersCasual) || 1;

                for (var key in achievements) {
                    var a = achievements[key];

                    // Earn date — prefer hardcore, fall back to softcore
                    var dateEarned = "";
                    var isHardcore = false;
                    if (a.DateEarnedHardcore && a.DateEarnedHardcore !== "") {
                        dateEarned = a.DateEarnedHardcore;
                        isHardcore = true;
                    } else if (a.DateEarned && a.DateEarned !== "") {
                        dateEarned = a.DateEarned;
                    }
                    var ts = Date.parse(dateEarned);
                    if (isNaN(ts)) ts = 0;

                    // Rarity: % of tracked players who earned it (lower = rarer)
                    var numAwarded  = parseInt(a.NumAwarded) || 0;
                    var rarityPct   = totalPlayers > 0
                                      ? Math.round((numAwarded / totalPlayers) * 1000) / 10
                                      : 100.0;

                    list.push({
                        "Title":        a.Title        || "",
                        "Description":  a.Description  || "",
                        "Points":       parseInt(a.Points)       || 0,
                        "TrueRatio":    parseInt(a.TrueRatio)    || 0,
                        "BadgeName":    a.BadgeName    || "",
                        "DisplayOrder": parseInt(a.DisplayOrder) || 0,
                        "DateEarned":   ts,
                        "Hardcore":     isHardcore,
                        "Rarity":       rarityPct      // 0.0–100.0
                    });
                }

                // Default sort: earned (most recent first), then unearned by DisplayOrder
                list.sort(function(a, b) {
                    if (a.DateEarned > 0 && b.DateEarned === 0) return -1;
                    if (a.DateEarned === 0 && b.DateEarned > 0) return 1;
                    if (a.DateEarned > 0 && b.DateEarned > 0)  return b.DateEarned - a.DateEarned;
                    return a.DisplayOrder - b.DisplayOrder;
                });

                for (var i = 0; i < list.length; i++)
                    raGameCheevos.append(list[i]);

                statusText = (raGameCheevos.count === 0) ? "No achievements for this game" : "";
                rebuildFilteredCheevos();
            }
        );
    }

    function refreshAll() {
        loadUserProfile();
        loadRecentGames();
    }

    // ── Title normalisation ───────────────────────────────────────────────
    function normalizeTitle(t) {
        return (t || "")
            .replace(/^~[^~]+~\s*/i,           "")
            .replace(/^(.*),\s*(the|a|an)\b/i, "$2 $1")
            .toLowerCase()
            .replace(/\s*\([^)]*\)\s*/g,       " ")
            .replace(/[^a-z0-9 ]/g,            " ")
            .replace(/\s+/g,                   " ")
            .trim();
    }

    // ── Game list search (two-pass exact + prefix) ────────────────────────
    function findGameInList(title, data) {
        var norm = normalizeTitle(title);
        var list = Array.isArray(data)
            ? data
            : Object.keys(data).map(function(k){ return data[k]; });

        function isHackEntry(t) { return /^~[^~]+~\s*/i.test(t || ""); }

        // Pass 1: exact match
        var hackFallback1 = 0;
        for (var i = 0; i < list.length; i++) {
            var item = list[i];
            var id   = parseInt(item.ID) || parseInt(item.GameID) || 0;
            if (id <= 0) continue;
            if (normalizeTitle(item.Title || "") !== norm) continue;
            if (!isHackEntry(item.Title)) return id;
            if (!hackFallback1) hackFallback1 = id;
        }
        if (hackFallback1) return hackFallback1;

        // Pass 2: Pegasus title is a left-anchored prefix of RA title
        if (norm.length >= 8) {
            var hackFallback2 = 0;
            for (var j = 0; j < list.length; j++) {
                var item2  = list[j];
                var id2    = parseInt(item2.ID) || parseInt(item2.GameID) || 0;
                if (id2 <= 0) continue;
                var raTitle = normalizeTitle(item2.Title || "");
                if (raTitle.length > norm.length && raTitle.indexOf(norm + " ") === 0) {
                    if (!isHackEntry(item2.Title)) return id2;
                    if (!hackFallback2) hackFallback2 = id2;
                }
            }
            if (hackFallback2) return hackFallback2;
        }
        return 0;
    }

    // ── Game lookup (Pegasus game → RA game ID) ───────────────────────────
    // Uses recently-played cache as fast path, then per-console game list
    // (cached in api.memory for 24 hours to minimise Android network traffic).
    function lookupGame(title, shortName) {
        pendingGameID    = -1;
        lookupInProgress = false;
        lookupStatusMsg  = "";

        reload();

        if (!raUserName || !raApiKey) {
            lookupStatusMsg = "Configure credentials in Settings → Retro Achievements";
            pendingGameID   = 0;
            return;
        }

        // Profile not yet loaded (user entered RA via GameView, bypassing Overview).
        // Fire it now so points/rank/avatar are ready by the time achievements load.
        if (!profileLoaded)
            loadUserProfile();


        var consoleID = consoleMappings[shortName.toLowerCase()] || 0;

        // Fast path: check recently-played model (no network call)
        if (raRecentGames.count > 0) {
            var normTitle = normalizeTitle(title);
            for (var r = 0; r < raRecentGames.count; r++) {
                var entry = raRecentGames.get(r);
                if (normalizeTitle(entry.Title) === normTitle) {
                    pendingGameID   = entry.GameID;
                    lookupStatusMsg = "";
                    return;
                }
            }
        }

        if (!consoleID) {
            lookupStatusMsg = "Console not supported by Retro Achievements";
            pendingGameID   = 0;
            return;
        }

        // Check 24-hour api.memory cache for this console's game list
        var cacheKey  = "raList_" + consoleID;
        var cacheTime = "raListTime_" + consoleID;
        var ttl       = 24 * 60 * 60 * 1000;
        var now       = Date.now();

        if (api.memory.has(cacheKey) && api.memory.has(cacheTime)
                && (now - parseFloat(api.memory.get(cacheTime))) < ttl) {
            try {
                var cached = JSON.parse(api.memory.get(cacheKey));
                var hit    = findGameInList(title, cached);
                pendingGameID   = hit;
                lookupStatusMsg = hit > 0 ? "" : "No Retro Achievements found for this game";
            } catch(e) {
                api.memory.unset(cacheKey);
                api.memory.unset(cacheTime);
            }
            if (pendingGameID !== -1) return;
        }

        // Network fetch: full game list for this console
        lookupInProgress = true;
        var capturedTitle = title;
        var capturedNow   = now;
        raRequest(
            "GetGameList",
            "i=" + consoleID,
            function(resp) {
                lookupInProgress = false;
                api.memory.set(cacheKey, JSON.stringify(resp));
                api.memory.set(cacheTime, capturedNow.toString());
                var found       = findGameInList(capturedTitle, resp);
                pendingGameID   = found;
                lookupStatusMsg = found > 0 ? "" : "No Retro Achievements found for this game";
            },
            function() {
                lookupInProgress = false;
                pendingGameID    = 0;
                lookupStatusMsg  = "Network error — check connection";
            }
        );
    }
}
