// XboxOSv2 – RetroAchievements data layer
// Handles all API communication with retroachievements.org and owns the
// ListModels consumed by AchievementsView and GameAchievementsView.

import QtQuick 2.15

Item {
id: root

    // ── Public properties ────────────────────────────────────────────────
    property alias raRecentGames: raRecentGames
    property alias raGameCheevos: raGameCheevos
    property alias raLibrary:     raLibrary

    // Where the web API lives. One property so the test harness can point
    // it at a local fake server (tools/harness/sync.sh); never changed here.
    readonly property string apiBase: "https://retroachievements.org/API/API_"

    // ── Every game you've played (Gaming tab) and your awards (Awards tab) ─
    // Loaded the first time the RA page opens, not at startup. Totals are
    // worked out once per load, not bound per row.
    property bool   libraryLoaded:    false
    property bool   libraryLoading:   false
    property int    libraryTotal:     0      // games RA says you've played
    property int    totalAwarded:     0      // achievements unlocked, softcore or hardcore
    property int    totalPossible:    0      // achievements in those games
    property bool   awardsLoaded:     false
    property int    awardsTotal:      0
    property int    masteredCount:    0      // 100% in hardcore (Xbox "Mythic")
    property int    completedCount:   0      // 100% in softcore
    property int    beatenCount:      0      // beaten, hardcore + softcore
    property int    eventAwardsCount: 0      // event + site awards
    property var    awardsList:       []     // newest first

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
    // filterMode: "all" | "locked" | "earned" | "rare" | "common"
    //             (rare: under 10% of players have it, as on the Xbox)
    // typeFilter: "all" | "progression" | "win_condition" | "missable"
    //             (RA's achievement types; untyped ones only show under All)
    // sortMode:   "default" | "points" | "rarity" | "date"
    // setFilter:  "all" | "base" | "subsets" | "unofficial"
    //             (All = base set + subsets; unofficial ones only on their own)
    property string filterMode: "all"
    property string typeFilter: "all"
    property string setFilter:  "all"
    property string sortMode:   "default"

    // ── Game lookup state (used by RAGameEntryView) ──────────────────────
    property int    pendingGameID:    -1
    property bool   lookupInProgress: false
    property string lookupStatusMsg:  ""

    // Guard so loadUserProfile fires only once per session, even when
    // entering RA from GameView before Overview has ever been opened.
    property bool profileLoaded: false

    // ── Credential check (Settings → Retro Achievements) ─────────────────
    // verifyState: "idle" | "empty" | "checking" | "ok" | "bad" | "neterr"
    property string verifyState: "idle"
    property string verifyName:  ""
    function verify() {
        var u = api.memory.has("RA Username") ? ("" + api.memory.get("RA Username")) : "";
        var k = api.memory.has("RA API Key")  ? ("" + api.memory.get("RA API Key"))  : "";
        u = u.trim();
        if (u === "" || k === "") { verifyState = "empty"; verifyName = ""; return; }
        verifyState = "checking";
        var url = apiBase + "GetUserProfile.php?z=" + encodeURIComponent(u)
                + "&y=" + encodeURIComponent(k) + "&u=" + encodeURIComponent(u);
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status === 200) {
                try {
                    var resp = JSON.parse(xhr.responseText);
                    if (resp && resp.User && resp.User.length > 0) {
                        verifyState = "ok";
                        verifyName  = resp.User;
                        // Credentials are good — populate the live profile/card too.
                        reload();
                        if (!profileLoaded) loadUserProfile();
                    } else {
                        verifyState = "bad"; verifyName = "";
                    }
                } catch (e) {
                    verifyState = "bad"; verifyName = "";
                }
            } else if (xhr.status === 0) {
                verifyState = "neterr";
            } else {
                verifyState = "bad"; verifyName = "";
            }
        };
        xhr.send();
    }

    // ── Pegasus shortName → RA console ID ────────────────────────────────
    readonly property var consoleMappings: ({
        // Nintendo handhelds
        "gb":             4,  "gameboy":        4,
        "sgb":            4,
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
        "sfc":            3,  "snesna":         3,
        "n64":            2,  "nintendo64":     2,
        "n64dd":          2,
        "gc":            16,  "gamecube":      16,  "ngc":           16,
        "wii":           19,
        // Sega
        "genesis":        1,  "megadrive":      1,  "md":             1,
        "megadrivejp":    1,
        "sms":           11,  "mastersystem":  11,
        "gamegear":      15,  "gg":            15,
        "32x":           10,  "sega32x":       10,
        "segacd":         9,  "megacd":         9,  "scd":            9,
        "saturn":        39,  "saturnjp":      39,
        "dreamcast":     40,  "dc":            40,
        "sg1000":        33,  "sg-1000":       33,
        "segapico":      68,  "pico":          68,
        // Sony
        "psx":           12,  "ps1":           12,  "playstation":   12,
        "ps2":           21,  "playstation2":  21,
        "psp":           41,
        // NEC
        "pce":            8,  "tg16":           8,  "pcengine":       8,
        "supergrafx":     8,
        "pcecd":         76,  "tgcd":          76,  "pcenginecd":    76,
        "pc88":          47,  "pc8800":        47,
        "pcfx":          49,  "pc-fx":         49,
        // SNK
        "neogeo":        14,  "ngp":           14,  "ngpc":          14,
        "neogeopocket":  14,
        "neogeocd":      56,  "ngcd":          56,
        // Atari
        "atari2600":     25,  "2600":          25,
        "atari5200":     50,
        "atari7800":     51,  "7800":          51,
        "lynx":          13,  "atarilynx":     13,
        "jaguar":        17,  "atarijaguar":   17,
        "jaguarcd":      77,  "atarijaguarcd": 77,
        // Other
        "3do":           43,
        "coleco":        44,  "colecovision":  44,
        "intellivision": 45,  "intv":          45,
        "vectrex":       46,
        "wonderswan":    53,  "ws":            53,  "wsc":           53,
        "wonderswancolor": 53,
        "megaduck":      69,
        "watara":        63,  "supervision":   63,
        "channelf":      57,  "fairchildchannelf": 57,
        "arcadia2001":   73,  "arcadia":       73,
        "odyssey2":      23,  "o2":            23,  "videopac":      23,
        "vc4000":        74,
        "arduboy":       71,  "uzebox":        80,  "wasm4":         72,
        // Home computers
        "c64":           30,  "commodore64":   30,
        "msx":           29,  "msx1":          29,  "msx2":          29,
        "amstradcpc":    37,  "cpc":           37,
        "apple2":        38,  "appleii":       38,
        // Arcade
        "arcade":        27,  "mame":          27,
        "cps1":          27,  "cps2":          27,  "cps3":          27,
        "fbneo":         27
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

    // Split form of pointsText for the alternating header line
    // (Global/RAStatLine.qml): points on one face, rank on the other.
    property string scoreText: {
        if (raUserName === "") return "";
        var parts = [ raFmt(hardcorePoints) + " HC" ];
        if (softcorePoints  > 0) parts.push(raFmt(softcorePoints)  + " SC");
        if (totalTruePoints > 0) parts.push(raFmt(totalTruePoints) + " true");
        return parts.join("  ·  ");
    }
    property string rankText: (raUserName !== "" && userRank > 0)
                              ? "Rank #" + raFmt(userRank) : ""

    property string memberText: {
        if (memberSince === "") return "";
        // memberSince arrives as "YYYY-MM-DD HH:MM:SS" — just show the date part
        return "Member since " + memberSince.substring(0, 10);
    }

    // ── Internal models ──────────────────────────────────────────────────
    ListModel { id: raRecentGames }
    ListModel { id: raGameCheevos }
    ListModel { id: raLibrary }

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
            if (filterMode === "rare"   && !(a.Rarity > 0 && a.Rarity < 10)) continue;
            if (filterMode === "common" &&  (a.Rarity > 0 && a.Rarity < 10)) continue;
            if (typeFilter !== "all" && a.Type !== typeFilter) continue;
            var set = a.Set || "";
            if (set === "Unofficial") { if (setFilter !== "unofficial") continue; }
            else if (setFilter === "unofficial" || (setFilter === "base" && set !== "") || (setFilter === "subsets" && set === "")) continue;
            list.push({
                Title:        a.Title,
                Description:  a.Description,
                Points:       a.Points,
                BadgeName:    a.BadgeName,
                DisplayOrder: a.DisplayOrder,
                DateEarned:   a.DateEarned,
                Hardcore:     a.Hardcore,
                Rarity:       a.Rarity,
                TrueRatio:    a.TrueRatio,
                Type:         a.Type,
                Set:          a.Set || ""
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

    // Both filters at once (the Filters pop-up's Apply): one rebuild.
    property bool _settingFilters: false
    function setFilters(status, type, set) {
        _settingFilters = true;
        filterMode = status;
        typeFilter = type;
        setFilter  = set || "all";
        _settingFilters = false;
        if (setFilter === "unofficial") loadUnofficial();
        rebuildFilteredCheevos();
    }
    onFilterModeChanged: if (!_settingFilters) rebuildFilteredCheevos()
    onTypeFilterChanged: if (!_settingFilters) rebuildFilteredCheevos()
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
        var url = apiBase + apiName
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

    // Every game with progress, 500 per request (RA's maximum), newest
    // activity first. A load that's overtaken by a newer one is dropped.
    property int _libGen: 0
    function loadLibrary() {
        if (libraryLoading) return;
        var gen = ++_libGen;
        libraryLoading = true;
        raLibrary.clear();
        var awarded = 0, possible = 0;
        function page(offset) {
            raRequest("GetUserCompletionProgress",
                "u=" + encodeURIComponent(raUserName) + "&c=500&o=" + offset,
                function(resp) {
                    if (gen !== _libGen) return;
                    var rows = resp.Results || resp.results || [];
                    var total = parseInt(resp.Total !== undefined ? resp.Total : resp.total) || 0;
                    var batch = [];     // one append per page: 500 single appends cost a visible hitch
                    for (var i = 0; i < rows.length; i++) {
                        var g = rows[i];
                        var max = parseInt(g.MaxPossible) || 0;
                        var n   = parseInt(g.NumAwarded)  || 0;
                        var hc  = parseInt(g.NumAwardedHardcore) || 0;
                        awarded += n; possible += max;
                        batch.push({
                            "GameID":       parseInt(g.GameID) || 0,
                            "Title":        g.Title       || "",
                            "ImageIcon":    g.ImageIcon   || "",
                            "ConsoleID":    parseInt(g.ConsoleID) || 0,
                            "ConsoleName":  g.ConsoleName || "",
                            "MaxPossible":  max,
                            "NumAwarded":   n,
                            "NumAwardedHardcore": hc,
                            // "mastered" | "completed" | "beaten-hardcore" | "beaten-softcore" | ""
                            "Award":        g.HighestAwardKind || "",
                            "AwardDate":    g.HighestAwardDate || "",
                            "LastUnlock":   g.MostRecentAwardedDate || "",
                            "Progress":     max > 0 ? n / max : 0.0
                        });
                    }
                    raLibrary.append(batch);
                    var next = offset + rows.length;
                    if (rows.length > 0 && next < total) { page(next); return; }
                    libraryTotal  = total > 0 ? total : raLibrary.count;
                    totalAwarded  = awarded;
                    totalPossible = possible;
                    libraryLoaded = true;
                    libraryLoading = false;
                    console.log("[RA] library: " + raLibrary.count + " games, "
                                + awarded + "/" + possible + " achievements");
                },
                function() { if (gen === _libGen) libraryLoading = false; });
        }
        page(0);
    }

    // Award counts and the visible awards, newest first.
    function loadAwards() {
        raRequest("GetUserAwards", "u=" + encodeURIComponent(raUserName),
            function(resp) {
                function n(k) { return parseInt(resp[k]) || 0; }
                awardsTotal      = n("TotalAwardsCount");
                masteredCount    = n("MasteryAwardsCount");
                completedCount   = n("CompletionAwardsCount");
                beatenCount      = n("BeatenHardcoreAwardsCount") + n("BeatenSoftcoreAwardsCount");
                eventAwardsCount = n("EventAwardsCount") + n("SiteAwardsCount");
                var list = (resp.VisibleUserAwards || []).slice(0);
                list.sort(function(a, b) { return String(b.AwardedAt).localeCompare(String(a.AwardedAt)); });
                awardsList = list;
                awardsLoaded = true;
                console.log("[RA] awards: " + awardsTotal + " total, " + masteredCount + " mastered, "
                            + beatenCount + " beaten, " + completedCount + " completed");
            });
    }

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
        typeFilter    = "all";
        setFilter     = "all";
        leaderboardsFor = 0; leaderboardsState = 0; leaderboards = [];
        subsetNames   = [];
        unofficialState = 0;
        unofficialCount = 0;
        sortMode      = "default";
        statusText    = "Loading...";
        raGameCheevos.clear();
        filteredCheevos = [];
        currentGameDetails = {
            "Title": "", "ImageIcon": "", "ConsoleName": "",
            "NumAchievements": 0, "NumAwardedToUser": 0,
            "NumAwardedToUserHardcore": 0,
            "PossibleScore": 0, "ScoreAchieved": 0,
            "ImageIngame": "", "Players": 0, "PlayersHardcore": 0,
            "Award": "", "AwardDate": "", "PointsHardcore": 0, "PointsSoftcore": 0,
            "TrueRatioEarned": 0, "FirstUnlock": 0, "LatestUnlock": 0,
            "RarestPct": 0, "RarestTitle": "", "Loaded": false
        };

        raRequest(
            "GetGameInfoAndUserProgress",
            "u=" + encodeURIComponent(raUserName) + "&g=" + gameID + "&a=1",   // a=1: award kind + date
            function(resp) {
                var det = {
                    "Title":                    resp.Title       || "",
                    "ImageIcon":                resp.ImageIcon   || "",
                    "ConsoleName":              resp.ConsoleName  || "",
                    "ConsoleID":                parseInt(resp.ConsoleID)                || 0,
                    "NumAchievements":          parseInt(resp.NumAchievements)          || 0,
                    "NumAwardedToUser":         parseInt(resp.NumAwardedToUser)         || 0,
                    "NumAwardedToUserHardcore": parseInt(resp.NumAwardedToUserHardcore) || 0,
                    "PossibleScore":            parseInt(resp.PossibleScore)            || 0,
                    "ScoreAchieved":            parseInt(resp.ScoreAchieved)            || 0,
                    "ImageIngame":              resp.ImageIngame || resp.ImageTitle || "",
                    "ImageBoxArt":              resp.ImageBoxArt || "",
                    "Players":                  parseInt(resp.NumDistinctPlayersCasual || resp.NumDistinctPlayers) || 0,
                    "PlayersHardcore":          parseInt(resp.NumDistinctPlayersHardcore) || 0,
                    "Award":                    resp.HighestAwardKind || "",
                    "AwardDate":                resp.HighestAwardDate || "",
                    "Loaded":                   true
                };
                // Worked out once here for the page and its Stats view.
                var ptsHc = 0, ptsSc = 0, trueEarned = 0, first = 0, latest = 0, rarest = 101, rarestTitle = "", possible = 0;

                var list = [];
                var achievements = resp.Achievements || {};
                var totalPlayers = parseInt(resp.NumDistinctPlayersCasual) || 1;

                for (var key in achievements) {
                    var it = _achItem(achievements[key], totalPlayers, "");
                    possible += it.Points;
                    if (it.DateEarned > 0) {
                        if (it.Hardcore) ptsHc += it.Points; else ptsSc += it.Points;
                        trueEarned += it.TrueRatio;
                        if (first === 0 || it.DateEarned < first) first = it.DateEarned;
                        if (it.DateEarned > latest) latest = it.DateEarned;
                        if (it.Rarity < rarest) { rarest = it.Rarity; rarestTitle = it.Title; }
                    }
                    list.push(it);
                }

                // Default sort: earned (most recent first), then unearned by DisplayOrder
                list.sort(function(a, b) {
                    if (a.DateEarned > 0 && b.DateEarned === 0) return -1;
                    if (a.DateEarned === 0 && b.DateEarned > 0) return 1;
                    if (a.DateEarned > 0 && b.DateEarned > 0)  return b.DateEarned - a.DateEarned;
                    return a.DisplayOrder - b.DisplayOrder;
                });

                det.PointsHardcore  = ptsHc;
                det.PointsSoftcore  = ptsSc;
                det.TrueRatioEarned = trueEarned;
                det.FirstUnlock     = first;
                det.LatestUnlock    = latest;
                det.RarestPct       = rarest <= 100 ? rarest : 0;
                det.RarestTitle     = rarestTitle;
                if (!det.PossibleScore) det.PossibleScore = possible;
                if (!det.ScoreAchieved) det.ScoreAchieved = ptsHc + ptsSc;
                currentGameDetails = det;
                raGameCheevos.append(list);

                statusText = (raGameCheevos.count === 0) ? "No achievements for this game" : "";
                rebuildFilteredCheevos();
                loadSubsets(gameID, det.ConsoleID, det.Title);
            }
        );
    }

    // One achievement from RA's game info, in the shape the page uses. set:
    // "" for the base set, the subset's name, or "Unofficial".
    function _achItem(a, totalPlayers, set) {
        var dateEarned = "", hc = false;
        if (a.DateEarnedHardcore) { dateEarned = a.DateEarnedHardcore; hc = true; }
        else if (a.DateEarned) dateEarned = a.DateEarned;
        var ts = Date.parse(dateEarned);
        if (isNaN(ts)) ts = 0;
        var n = parseInt(a.NumAwarded) || 0;
        return {
            "Title":        a.Title        || "",
            "Description":  a.Description  || "",
            "Points":       parseInt(a.Points)       || 0,
            "TrueRatio":    parseInt(a.TrueRatio)    || 0,
            "BadgeName":    a.BadgeName    || "",
            "DisplayOrder": parseInt(a.DisplayOrder) || 0,
            "DateEarned":   ts,
            "Hardcore":     hc,
            // % of the game's players who have it (lower = rarer)
            "Rarity":       totalPlayers > 0 ? Math.round((n / totalPlayers) * 1000) / 10 : 100.0,
            "Type":         a.Type || a.type || "",     // "progression" | "win_condition" | "missable" | ""
            "Set":          set || ""
        };
    }

    // ── Subsets and unofficial achievements ──────────────────────────────
    // RA keeps subsets as games of their own, "<title> [Subset - Bonus]",
    // linked to the base game (multiset). They're found in the console's
    // game list (the same list the Game details RA button uses) and loaded
    // after the base set, with your progress; the page's numbers and the
    // Mythic card stay the base set's, as RA's mastery does.
    property var subsetNames: []        // subsets loaded for the current game
    function loadSubsets(gameID, consoleID, baseTitle) {
        if (!consoleID || !baseTitle) return;
        withList(consoleID, function(list) {
            if (currentGameID !== gameID) return;
            var want = titleKey(baseTitle), found = [];
            for (var i = 0; i < list.length; i++) {
                var m = /^(.*?)\s*\[Subset\s*-\s*([^\]]+)\]\s*$/i.exec(list[i].Title || "");
                if (m && list[i].ID !== gameID && titleKey(m[1]) === want) found.push({ id: list[i].ID, name: m[2].trim() });
            }
            found.forEach(function(sub) {
                raRequest("GetGameInfoAndUserProgress",
                    "u=" + encodeURIComponent(raUserName) + "&g=" + sub.id,
                    function(resp) {
                        if (currentGameID !== gameID) return;
                        var players = parseInt(resp.NumDistinctPlayersCasual) || 1, out = [];
                        var ach = resp.Achievements || {};
                        for (var k in ach) out.push(_achItem(ach[k], players, sub.name));
                        if (out.length === 0) return;
                        raGameCheevos.append(out);
                        subsetNames = subsetNames.concat([sub.name]);
                        rebuildFilteredCheevos();
                    }, function() {});
            });
        });
    }

    // Unofficial (demoted / in-development) achievements: one request, only
    // when the Unofficial filter is picked. They can't be earned, so they
    // always show locked.
    property int unofficialState: 0     // 0 not asked, 1 loading, 2 loaded
    property int unofficialCount: 0
    function loadUnofficial() {
        if (unofficialState !== 0) return;
        var gameID = currentGameID;
        unofficialState = 1;
        raRequest("GetGameExtended", "i=" + gameID + "&f=5",
            function(resp) {
                if (currentGameID !== gameID) return;
                var players = parseInt(resp.NumDistinctPlayers || resp.NumDistinctPlayersCasual) || currentGameDetails.Players || 1;
                var ach = resp.Achievements || {}, out = [];
                for (var k in ach) {
                    var it = _achItem(ach[k], players, "Unofficial");
                    it.DateEarned = 0; it.Hardcore = false;
                    out.push(it);
                }
                if (out.length) raGameCheevos.append(out);
                unofficialCount = out.length;
                unofficialState = 2;
                rebuildFilteredCheevos();
            },
            function() { if (currentGameID === gameID) { unofficialState = 2; rebuildFilteredCheevos(); } });
    }

    // ── Leaderboards (game page) ─────────────────────────────────────────
    // The game's leaderboards with the top entry, merged with yours (two
    // requests, both only when Leaderboards opens). state: 0 not asked,
    // 1 loading, 2 loaded.
    property var leaderboards: []
    property int leaderboardsFor: 0
    property int leaderboardsState: 0
    function loadLeaderboards(gameID) {
        if (leaderboardsFor === gameID && leaderboardsState > 0) return;
        leaderboardsFor = gameID; leaderboardsState = 1; leaderboards = [];
        var all = null, mine = null;
        function done() {
            if (leaderboardsFor !== gameID || all === null || mine === null) return;
            var byId = {};
            for (var m = 0; m < mine.length; m++) byId[mine[m].ID] = mine[m].UserEntry || {};
            var out = [];
            for (var i = 0; i < all.length; i++) {
                var l = all[i], t = l.TopEntry || {}, u = byId[l.ID] || {};
                out.push({ id: parseInt(l.ID) || 0, title: (l.Title || "").trim(), description: (l.Description || "").trim(),
                           topUser: t.User || "", topScore: t.FormattedScore || (t.Score !== undefined ? "" + t.Score : ""),
                           myScore: u.FormattedScore || "", myRank: parseInt(u.Rank) || 0 });
            }
            leaderboards = out;
            leaderboardsState = 2;
        }
        raRequest("GetGameLeaderboards", "i=" + gameID + "&c=500",
            function(r) { all = (r && r.Results) || []; done(); }, function() { all = []; done(); });
        raRequest("GetUserGameLeaderboards", "i=" + gameID + "&u=" + encodeURIComponent(raUserName) + "&c=500",
            function(r) { mine = (r && r.Results) || []; done(); }, function() { mine = []; done(); });
    }
    // One leaderboard's top 100 (the entries pop-up).
    property var lbEntries: []
    property int lbEntriesTotal: 0
    property int lbEntriesFor: 0
    property int lbEntriesState: 0
    function loadLeaderboardEntries(id) {
        lbEntriesFor = id; lbEntriesState = 1; lbEntries = []; lbEntriesTotal = 0;
        raRequest("GetLeaderboardEntries", "i=" + id + "&c=100",
            function(r) {
                if (lbEntriesFor !== id) return;
                var res = (r && r.Results) || [], out = [];
                for (var i = 0; i < res.length; i++)
                    out.push({ rank: parseInt(res[i].Rank) || (i + 1), user: res[i].User || "",
                               score: res[i].FormattedScore || ("" + res[i].Score), date: res[i].DateSubmitted || "" });
                lbEntries = out;
                lbEntriesTotal = parseInt(r && r.Total) || out.length;
                lbEntriesState = 2;
            },
            function() { if (lbEntriesFor === id) lbEntriesState = 2; });
    }

    // Your rank among this game's players (Stats view). One request per
    // game, only when Stats is opened; -1 while unknown, 0 if unranked.
    property int gameRank: -1
    property int gameRankFor: 0
    function loadGameRank(gameID) {
        if (gameRankFor === gameID && gameRank >= 0) return;
        gameRankFor = gameID; gameRank = -1;
        raRequest("GetUserGameRankAndScore",
            "u=" + encodeURIComponent(raUserName) + "&g=" + gameID,
            function(resp) {
                if (gameRankFor !== gameID) return;
                var r = (resp && resp.length > 0) ? parseInt(resp[0].UserRank) : 0;
                gameRank = isNaN(r) ? 0 : r;
            },
            function() { if (gameRankFor === gameID) gameRank = 0; });
    }

    function refreshAll() {
        loadUserProfile();
        loadRecentGames();
        loadLibrary();
        loadAwards();
    }

    // ── Title normalisation ───────────────────────────────────────────────
    // Accented letters fold to plain ones ("Pokémon" = "Pokemon"), and "&"
    // reads as "and", so the same game spelled two ways still matches.
    readonly property var _fold: ({ "à":"a","á":"a","â":"a","ã":"a","ä":"a","å":"a","æ":"ae","ç":"c",
        "è":"e","é":"e","ê":"e","ë":"e","ì":"i","í":"i","î":"i","ï":"i","ñ":"n",
        "ò":"o","ó":"o","ô":"o","õ":"o","ö":"o","ø":"o","ù":"u","ú":"u","û":"u","ü":"u","ý":"y","ÿ":"y","ß":"ss" })
    function normalizeTitle(t) {
        var fold = _fold;
        return (t || "")
            .replace(/^~[^~]+~\s*/i,           "")
            .replace(/^(.*),\s*(the|a|an)\b/i, "$2 $1")
            .toLowerCase()
            .replace(/[\u00df-\u00ff]/g,       function(c) { return fold[c] || c; })
            .replace(/&/g,                     " and ")
            .replace(/\s*\([^)]*\)\s*/g,       " ")
            .replace(/[^a-z0-9 ]/g,            " ")
            .replace(/\s+/g,                   " ")
            .trim();
    }
    // What two titles must share to be the same game: the normalized title
    // without spaces, so "FireRed" = "Fire Red" and "MegaMan" = "Mega Man".
    function titleKey(t) { return normalizeTitle(t).replace(/ /g, ""); }

    // ── Reverse lookup: RA game title → local Pegasus game ────────────────
    // Used by the achievements page to launch what you're viewing. Matches on
    // the same normalized form as the RA lookup, and prefers a game whose
    // collection maps to the expected RA console so same-named titles on
    // different systems don't get crossed.
    // ── Your own matches ─────────────────────────────────────────────────
    // Exact pairs that beat title matching, in both directions, strongest
    // first:
    //   1. a pair picked in the theme (Change match / Find in your library),
    //      kept in the theme's settings as "RA Pairs" { local key: RA ID };
    //   2. "x-ra-id: <RA game ID>" in the game's Pegasus metadata, which
    //      Pegasus X writes from the ROM's hash (x-retroachievements and
    //      x-raid work too). "x-ra-id: 0" means Pegasus X checked the ROM and
    //      it isn't on RA: no RA button, and no guessing by title.
    property var raPairs: ({})
    property bool _pairsLoaded: false
    function _loadPairs() {
        if (_pairsLoaded) return;
        _pairsLoaded = true;
        if (!api.memory.has("RA Pairs")) return;
        var v = api.memory.get("RA Pairs");
        try { raPairs = (typeof v === "string") ? JSON.parse(v) : (v || {}); } catch (e) { raPairs = {}; }
    }
    // A game's own key: its file, else system + title.
    function localKey(g) {
        if (!g) return "";
        var f = (g.files && g.files.count > 0) ? (g.files.get(0).path || "") : "";
        if (f !== "") return f;
        var sn = (g.collections && g.collections.count > 0) ? (g.collections.get(0).shortName || "") : "";
        return sn + "|" + (g.title || "");
    }
    // >0 the RA ID in the metadata, -1 checked and not on RA, 0 not there.
    function metadataId(g) {
        if (!g || !g.extra) return 0;
        var keys = ["ra-id", "retroachievements", "raid"];
        for (var i = 0; i < keys.length; i++) {
            var v = g.extra[keys[i]];
            if (v === undefined || v === null || v === "") continue;
            if (typeof v !== "string" && v.length !== undefined) v = v[0];
            var id = parseInt(v);
            if (id > 0) return id;
            if (id === 0) return -1;
        }
        return 0;
    }
    // >0 the RA game you (or Pegasus X) said this is, -1 not on RA, 0 not
    // known (title matching decides).
    function pairedId(g) {
        if (!g) return 0;
        _loadPairs();
        var p = parseInt(raPairs[localKey(g)]) || 0;
        if (p > 0) return p;
        return metadataId(g);
    }
    function setPair(g, raId) {
        if (!g || !(raId > 0)) return;
        _loadPairs();
        var copy = {};
        for (var k in raPairs) copy[k] = raPairs[k];
        copy[localKey(g)] = raId;
        raPairs = copy;
        api.memory.set("RA Pairs", copy);
        _localIndex = null;
        _hits = ({});
        listsEpoch++;                       // Game details re-asks for its RA button
    }

    // The library, indexed once on first use (one pass instead of one per
    // lookup): normalized title -> indexes, RA ID -> indexes for games you
    // paired, and index -> RA ID so a paired game isn't title-matched to a
    // different RA game.
    property var _localIndex: null
    function localIndex() {
        if (_localIndex && _localIndex.count === api.allGames.count) return _localIndex;
        _loadPairs();
        var map = {}, ids = {}, paired = {};
        var anyPairs = Object.keys(raPairs).length > 0;
        for (var i = 0; i < api.allGames.count; i++) {
            var g = api.allGames.get(i);
            var k = titleKey(g.title);
            if (k !== "") (map[k] = map[k] || []).push(i);
            var pid = anyPairs ? (parseInt(raPairs[localKey(g)]) || 0) : 0;
            if (pid <= 0) pid = metadataId(g);
            if (pid > 0) (ids[pid] = ids[pid] || []).push(i);
            if (pid !== 0) paired[i] = pid;         // -1: not on RA, never title-matched
        }
        _localIndex = { count: api.allGames.count, map: map, ids: ids, paired: paired };
        return _localIndex;
    }

    function findLocalGame(raTitle, consoleName, raId) {
        var idx = localIndex();
        if (raId > 0 && idx.ids[raId]) return api.allGames.get(idx.ids[raId][0]);
        if (!raTitle) return null;
        var want = titleKey(raTitle);
        if (want === "") return null;

        var wantConsole = (consoleName || "").toLowerCase();
        var loose = null;
        var hits = idx.map[want] || [];

        for (var h = 0; h < hits.length; h++) {
            var pid = idx.paired[hits[h]];
            if (pid && pid !== raId) continue;          // you paired it with another RA game
            var g = api.allGames.get(hits[h]);
            if (!loose) loose = g;                     // first title match, any system
            if (wantConsole === "") return g;

            // Prefer the copy whose collection maps to this RA console.
            for (var c = 0; c < g.collections.count; c++) {
                var sn = (g.collections.get(c).shortName || "").toLowerCase();
                var mappedId = consoleMappings[sn] || 0;
                if (mappedId > 0 && mappedId === (consoleMappings[wantConsole] || -1))
                    return g;
            }
        }
        return loose;
    }

    // ── Picker support ───────────────────────────────────────────────────
    // A console's game list, from the cache or downloaded once.
    function withList(consoleID, cb) {
        var l = _listFor(consoleID);
        if (l) { cb(l); return; }
        raRequest("GetGameList", "i=" + consoleID,
            function(resp) {
                api.memory.set("raList_" + consoleID, _storeList(consoleID, resp));
                api.memory.set("raListTime_" + consoleID, Date.now().toString());
                _hits = ({});
                listsEpoch++;
                cb(_lists[consoleID] || []);
            },
            function() { cb([]); });
    }
    // Candidates for the picker: { title, sub, value, key, words } with
    // key/words worked out once, so typing only re-scores.
    function pickItem(title, sub, value) {
        var n = normalizeTitle(title), w = {};
        n.split(" ").forEach(function(x) { if (x !== "") w[x] = true; });
        return { title: title, sub: sub, value: value, key: n.replace(/ /g, ""), words: w };
    }
    // Best matches first: shared words, plus a bonus when one title contains
    // the other with spaces ignored ("FireRed" finds "Fire Red").
    function rankItems(items, query, limit) {
        var qn = normalizeTitle(query), qk = qn.replace(/ /g, "");
        var qw = qn === "" ? [] : qn.split(" ");
        var scored = [];
        for (var i = 0; i < items.length; i++) {
            var it = items[i], sc = 0;
            if (qk !== "") {
                for (var j = 0; j < qw.length; j++) {
                    if (it.words[qw[j]]) sc += 2;
                    else if (qw[j].length >= 3 && it.key.indexOf(qw[j]) >= 0) sc += 1;
                }
                if (it.key === qk) sc += 10;
                else if (it.key.indexOf(qk) >= 0) sc += 6;
                else if (it.key.length >= 4 && qk.indexOf(it.key) >= 0) sc += 4;
                if (sc === 0) continue;
            }
            scored.push({ it: it, sc: sc });
        }
        scored.sort(function(a, b) { return (b.sc - a.sc) || (a.it.title < b.it.title ? -1 : a.it.title > b.it.title ? 1 : 0); });
        var out = [];
        for (var r = 0; r < scored.length && r < (limit || 80); r++) out.push(scored[r].it);
        return out;
    }

    // ── Game list search (two-pass exact + prefix) ────────────────────────
    function findGameInList(title, data) {
        var norm = normalizeTitle(title);
        var key  = norm.replace(/ /g, "");
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
            if (titleKey(item.Title || "") !== key) continue;
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

    // ── Quick check for the Game details RA button ────────────────────────
    // The button only shows when the game really has achievements, the same
    // way the Manual button only shows when a manual exists. No network on
    // this path: it answers from the console lists already saved by the RA
    // lookup, parsed once per session (re-parsing a big console list on
    // every details open would stall the open).
    property var _lists: ({})       // consoleID -> parsed game list
    property var _counts: ({})      // consoleID -> { gameID: achievement count }
    property var _hits: ({})        // consoleID|title -> gameID (0 = none)
    property var _fetching: ({})    // consoleID -> true while a list download runs
    // Bumped when a list arrives, so bindings that asked before re-ask.
    property int listsEpoch: 0

    function hasCredentials() {
        var u = api.memory.has("RA Username") ? ("" + api.memory.get("RA Username")) : "";
        var k = api.memory.has("RA API Key")  ? ("" + api.memory.get("RA API Key"))  : "";
        return u !== "" && k !== "";
    }

    // Keeps only what the lookup uses (ID, title, count) and only games
    // that have achievements. A full RA console list is up to a few MB, and
    // it lives in the theme's settings file, which Pegasus rewrites in full
    // on EVERY setting change, so a big list slowed every save.
    function _storeList(consoleID, list) {
        var arr = Array.isArray(list) ? list
                : Object.keys(list || {}).map(function(k){ return list[k]; });
        var compact = [], counts = {};
        for (var i = 0; i < arr.length; i++) {
            var id = parseInt(arr[i].ID) || parseInt(arr[i].GameID) || 0;
            if (id <= 0) continue;
            var n = (arr[i].NumAchievements === undefined) ? 1 : (parseInt(arr[i].NumAchievements) || 0);
            if (n <= 0) continue;
            compact.push({ ID: id, Title: arr[i].Title || "", NumAchievements: n });
            counts[id] = n;
        }
        _lists[consoleID]  = compact;
        _counts[consoleID] = counts;
        return compact;
    }

    function _listFor(consoleID) {
        if (_lists[consoleID]) return _lists[consoleID];
        var key = "raList_" + consoleID;
        if (!api.memory.has(key)) return null;
        var v = api.memory.get(key);
        try {
            if (typeof v === "string") {
                // Saved by an older build: full list as JSON text. Shrink it
                // once and save it back in the compact form.
                api.memory.set(key, _storeList(consoleID, JSON.parse(v)));
            } else {
                _storeList(consoleID, v);
            }
        } catch (e) { return null; }
        return _lists[consoleID];
    }

    // >0: the RA game ID (game has achievements), 0: none or RA not set up,
    // -1: not known yet (this console's list hasn't been downloaded).
    function quickGameId(title, shortName, game) {
        if (!title || !hasCredentials()) return 0;
        var paired = pairedId(game);
        if (paired > 0) return paired;
        if (paired < 0) return 0;                   // Pegasus X: not on RA

        // Recently played on RA: known without any list
        var normTitle = titleKey(title);
        for (var r = 0; r < raRecentGames.count; r++) {
            var entry = raRecentGames.get(r);
            if (titleKey(entry.Title) === normTitle) return entry.GameID;
        }

        var consoleID = consoleMappings[(shortName || "").toLowerCase()] || 0;
        if (!consoleID) return 0;
        var list = _listFor(consoleID);
        if (!list) return -1;

        var hitKey = consoleID + "|" + normTitle;
        if (_hits[hitKey] === undefined) {
            var id = findGameInList(title, list);
            _hits[hitKey] = (id > 0 && (_counts[consoleID][id] || 0) > 0) ? id : 0;
        }
        return _hits[hitKey];
    }

    // Downloads a console's list in the background when it's missing or
    // older than a day, so the button can appear. One download per console
    // at a time; failures are silent (the button just stays hidden).
    function prefetchList(shortName) {
        if (!hasCredentials()) return;
        var consoleID = consoleMappings[(shortName || "").toLowerCase()] || 0;
        if (!consoleID || _fetching[consoleID]) return;
        var cacheKey  = "raList_" + consoleID;
        var cacheTime = "raListTime_" + consoleID;
        if (api.memory.has(cacheKey) && api.memory.has(cacheTime)
                && (Date.now() - parseFloat(api.memory.get(cacheTime))) < 24 * 60 * 60 * 1000)
            return;
        if (!raUserName || !raApiKey) reload();
        _fetching[consoleID] = true;
        var started = Date.now();
        raRequest("GetGameList", "i=" + consoleID,
            function(resp) {
                _fetching[consoleID] = false;
                api.memory.set(cacheKey, _storeList(consoleID, resp));
                api.memory.set(cacheTime, started.toString());
                _hits = ({});
                listsEpoch++;
            },
            function() { _fetching[consoleID] = false; });
    }

    // ── Game lookup (Pegasus game → RA game ID) ───────────────────────────
    // Uses recently-played cache as fast path, then per-console game list
    // (cached in api.memory for 24 hours to minimise Android network traffic).
    function lookupGame(title, shortName, game) {
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

        // Your own match (metadata ID or a pair you picked) needs no lookup.
        var paired = pairedId(game);
        if (paired > 0) { pendingGameID = paired; return; }
        if (paired < 0) {
            lookupStatusMsg = "Not on RetroAchievements (its ROM was checked by Pegasus X)";
            pendingGameID = 0;
            return;
        }


        var consoleID = consoleMappings[shortName.toLowerCase()] || 0;

        // Fast path: check recently-played model (no network call)
        if (raRecentGames.count > 0) {
            var normTitle = titleKey(title);
            for (var r = 0; r < raRecentGames.count; r++) {
                var entry = raRecentGames.get(r);
                if (titleKey(entry.Title) === normTitle) {
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
                var cached = _listFor(consoleID);    // parsed once per session
                if (!cached) throw "bad list";
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
                api.memory.set(cacheKey, _storeList(consoleID, resp));
                api.memory.set(cacheTime, capturedNow.toString());
                _hits = ({});
                listsEpoch++;
                var found       = findGameInList(capturedTitle, _lists[consoleID]);
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
