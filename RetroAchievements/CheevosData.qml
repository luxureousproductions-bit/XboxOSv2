// XboxOSv2 – RetroAchievements data layer
// Handles all API communication with retroachievements.org and owns the
// ListModels consumed by AchievementsView and GameAchievementsView.

import QtQuick 2.0

Item {
id: root

    // ── Public properties ────────────────────────────────────────────────
    property alias raRecentGames:   raRecentGames
    property alias raGameCheevos:   raGameCheevos

    property string raUserName:     ""
    property string raApiKey:       ""

    property string avatarUrl:      ""
    property int    softcorePoints: 0
    property int    hardcorePoints: 0
    property string statusText:     ""

    // Details for the game whose achievements are currently loaded
    property var currentGameDetails: ({
        "Title":                    "",
        "ImageIcon":                "",
        "ConsoleName":              "",
        "NumAchievements":          0,
        "NumAwardedToUser":         0,
        "NumAwardedToUserHardcore": 0
    })

    // ID of the game currently loaded in GameAchievementsView
    property int currentGameID: 0

    // ── Game lookup state (used by RAGameEntryView) ───────────────────────
    // -1 = not started / reset, 0 = not found, >0 = found RA game ID
    property int    pendingGameID:    -1
    property bool   lookupInProgress: false
    property string lookupStatusMsg:  ""

    // Pegasus collection shortName → RetroAchievements console ID
    readonly property var consoleMappings: ({
        "nes":        7,  "fds":        7,
        "snes":       3,
        "gb":         4,  "gbc":        6,  "gba":        5,
        "n64":        2,
        "nds":       18,
        "genesis":    1,  "megadrive":  1,  "md":         1,
        "sms":       11,  "mastersystem": 11,  "sg1000":  11,
        "gamegear":  15,  "gg":        15,
        "32x":       10,
        "pce":        8,  "tg16":       8,  "pcengine":   8,
        "neogeo":    14,
        "atari2600": 25,  "2600":      25,
        "atari7800": 51,
        "lynx":      13,
        "psx":       12,  "ps1":       12,
        "ps2":       21,  "playstation2": 21,
        "saturn":    39,
        "dreamcast": 40,  "dc":        40,
        "msx":       29,
        "coleco":    44,
        "jaguar":    17,
        "3do":       43,
        "vectrex":   46,
        "arcade":    27,  "mame":      27
    })

    // Formatted points summary shown in view headers.
    // Always returns a string once the user is logged in so the Text item
    // stays visible even while the async API call is still in flight.
    property string pointsText: {
        if (raUserName === "") return "";
        var total = softcorePoints + hardcorePoints;
        return total + " Points: " + softcorePoints + " Softcore points, " + hardcorePoints + " Hardcore points";
    }

    // ── Internal models ──────────────────────────────────────────────────
    ListModel { id: raRecentGames }
    ListModel { id: raGameCheevos }

    // ── Credential helpers ───────────────────────────────────────────────

    // Re-read credentials from api.memory (call when opening the view).
    function reload() {
        raUserName = api.memory.has("RA Username") ? api.memory.get("RA Username") : "";
        raApiKey   = api.memory.has("RA API Key")  ? api.memory.get("RA API Key")  : "";
        // Restore cached avatar so the header shows immediately
        var cached = api.memory.has("raAvatarPath") ? api.memory.get("raAvatarPath") : "";
        if (cached !== "")
            avatarUrl = "https://media.retroachievements.org" + cached;
    }

    // ── Core HTTP helper ─────────────────────────────────────────────────
    // NOTE: The retroachievements.org API authenticates via URL query parameters
    // (?z=username&y=apikey).  This is the only authentication method the API
    // supports; header-based auth is not available.  HTTPS is used for all
    // requests, so the credentials are encrypted in transit.
    //
    // handler      – called with the parsed JSON object on HTTP 200.
    // errorHandler – optional; called (with no arguments) on any failure
    //                (missing credentials, network error, HTTP error, or parse
    //                error).  Used by lookupGame() to reset lookup state.
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
        raRequest("GetUserSummary", "u=" + encodeURIComponent(raUserName), function(resp) {
            // The RA API returns TotalSoftcorePoints / TotalPoints on GetUserSummary.
            // Fall back to the legacy field names in case a future API version changes them.
            softcorePoints = parseInt(resp.TotalSoftcorePoints || resp.SoftcorePoints) || 0;
            hardcorePoints = parseInt(resp.TotalPoints         || resp.Points)         || 0;
            if (resp.UserPic) {
                avatarUrl = "https://media.retroachievements.org" + resp.UserPic;
                api.memory.set("raAvatarPath", resp.UserPic);
            }
        });
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
                    raRecentGames.append({
                        "GameID":                  parseInt(g.GameID)                   || 0,
                        "ConsoleName":             g.ConsoleName                        || "",
                        "Title":                   g.Title                              || "",
                        "ImageIcon":               g.ImageIcon                          || "",
                        "LastPlayed":              g.LastPlayed                         || "",
                        "NumPossibleAchievements": parseInt(g.NumPossibleAchievements)  || 0,
                        "PossibleScore":           parseInt(g.PossibleScore)            || 0,
                        "NumAchieved":             parseInt(g.NumAchieved)              || 0,
                        "ScoreAchieved":           parseInt(g.ScoreAchieved)            || 0
                    });
                }
                statusText = (raRecentGames.count === 0) ? "No recently played games" : "";
            }
        );
    }

    function loadGameAchievements(gameID) {
        currentGameID = gameID;
        statusText = "Loading...";
        raGameCheevos.clear();
        currentGameDetails = {
            "Title": "", "ImageIcon": "", "ConsoleName": "",
            "NumAchievements": 0, "NumAwardedToUser": 0, "NumAwardedToUserHardcore": 0
        };
        raRequest(
            "GetGameInfoAndUserProgress",
            "u=" + encodeURIComponent(raUserName) + "&g=" + gameID,
            function(resp) {
                currentGameDetails = {
                    "Title":                    resp.Title      || "",
                    "ImageIcon":                resp.ImageIcon  || "",
                    "ConsoleName":              resp.ConsoleName || "",
                    "NumAchievements":          parseInt(resp.NumAchievements)          || 0,
                    "NumAwardedToUser":         parseInt(resp.NumAwardedToUser)         || 0,
                    "NumAwardedToUserHardcore": parseInt(resp.NumAwardedToUserHardcore) || 0
                };

                // Collect, sort, then append achievements
                var list = [];
                var achievements = resp.Achievements || {};
                for (var key in achievements) {
                    var a = achievements[key];
                    var dateEarned = "";
                    var isHardcore = false;
                    if (a.DateEarnedHardcore !== undefined && a.DateEarnedHardcore !== null
                            && a.DateEarnedHardcore !== "") {
                        dateEarned = a.DateEarnedHardcore;
                        isHardcore = true;
                    } else if (a.DateEarned !== undefined && a.DateEarned !== null
                            && a.DateEarned !== "") {
                        dateEarned = a.DateEarned;
                    }
                    var ts = Date.parse(dateEarned);
                    if (isNaN(ts)) ts = 0;
                    list.push({
                        "Title":        a.Title        || "",
                        "Description":  a.Description  || "",
                        "Points":       parseInt(a.Points)        || 0,
                        "BadgeName":    a.BadgeName    || "",
                        "DisplayOrder": parseInt(a.DisplayOrder)  || 0,
                        "DateEarned":   ts,
                        "Hardcore":     isHardcore
                    });
                }

                // Sort: earned (most-recently-earned first), then unearned by DisplayOrder
                list.sort(function(a, b) {
                    if (a.DateEarned > 0 && b.DateEarned === 0) return -1;
                    if (a.DateEarned === 0 && b.DateEarned > 0) return 1;
                    if (a.DateEarned > 0 && b.DateEarned > 0)  return b.DateEarned - a.DateEarned;
                    return a.DisplayOrder - b.DisplayOrder;
                });

                for (var i = 0; i < list.length; i++)
                    raGameCheevos.append(list[i]);

                statusText = (raGameCheevos.count === 0) ? "No achievements for this game" : "";
            }
        );
    }

    // Convenience: refresh both profile and recent games list
    function refreshAll() {
        loadUserProfile();
        loadRecentGames();
    }

    // ── Game-title lookup helpers ────────────────────────────────────────

    // Normalise a title for fuzzy matching: lowercase, strip regional/version
    // tags in parentheses (e.g. "(USA)", "(Europe)", "(Rev A)"), then replace all
    // remaining punctuation (including colons) with spaces and collapse whitespace.
    // Subtitles are preserved so "Castlevania: Symphony of the Night" normalises
    // to "castlevania symphony of the night" and still matches the RA entry.
    function normalizeTitle(t) {
        return (t || "").toLowerCase()
            .replace(/\s*\([^)]*\)\s*/g, " ") // remove parenthetical tags
            .replace(/[^a-z0-9 ]/g,     " ") // replace punctuation (incl. :) with space
            .replace(/\s+/g,            " ") // collapse whitespace
            .trim();
    }

    // Search a RA game-list response (array or ID-keyed object) for a matching
    // title; returns the RA game ID (>0) or 0 if not found.
    // Two passes are used:
    //   Pass 1 – exact match after normalisation (handles (USA) / punctuation diffs).
    //   Pass 2 – prefix match: Pegasus title is a left-anchored prefix of the RA
    //            title followed by a space (handles RA adding an extra subtitle such
    //            as "Street Fighter II: The World Warrior" when Pegasus just has
    //            "Street Fighter II").  Guarded to titles of 8+ chars to avoid
    //            spurious short-prefix false-positives.
    function findGameInList(title, data) {
        var norm = normalizeTitle(title);
        var list = Array.isArray(data) ? data : Object.keys(data).map(function(k){ return data[k]; });

        // Pass 1: exact match
        for (var i = 0; i < list.length; i++) {
            var item = list[i];
            var id = parseInt(item.ID) || parseInt(item.GameID) || 0;
            if (id > 0 && normalizeTitle(item.Title || "") === norm)
                return id;
        }

        // Pass 2: Pegasus title is a prefix of RA title (word-boundary safe)
        if (norm.length >= 8) {
            for (var i = 0; i < list.length; i++) {
                var item = list[i];
                var id = parseInt(item.ID) || parseInt(item.GameID) || 0;
                if (id <= 0) continue;
                var raTitle = normalizeTitle(item.Title || "");
                if (raTitle.length > norm.length && raTitle.indexOf(norm + " ") === 0)
                    return id;
            }
        }

        return 0;
    }

    // Look up whether a Pegasus game has RA entries.
    // Result is written to pendingGameID (-1 while pending, 0 = not found, >0 = RA game ID).
    // The per-console game list is cached in api.memory for 24 hours to minimise
    // network traffic on Android devices.
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

        var consoleID = consoleMappings[shortName.toLowerCase()] || 0;
        if (!consoleID) {
            lookupStatusMsg = "Console not supported by Retro Achievements";
            pendingGameID   = 0;
            return;
        }

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
                // Corrupt cache — remove and fall through to fresh fetch
                api.memory.unset(cacheKey);
                api.memory.unset(cacheTime);
            }
            if (pendingGameID !== -1) return;
        }

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
