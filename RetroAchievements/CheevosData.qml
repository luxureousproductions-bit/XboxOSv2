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

    // Option 2: title of the Pegasus game the user was viewing when they
    // opened the RA tab.  AchievementsView uses this to auto-scroll to the
    // matching entry once the recent-games list finishes loading.
    property string pendingScrollTitle: ""

    // Formatted points summary shown in view headers
    property string pointsText: {
        var total = hardcorePoints + softcorePoints;
        if (total === 0) return "";
        return total + " pts  ·  " + hardcorePoints + " HC";
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
    function raRequest(apiName, args, handler) {
        if (!raUserName || !raApiKey) {
            statusText = "Configure your credentials in Settings → Retro Achievements";
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
                }
            } else if (xhr.status === 0) {
                statusText = "No network connection";
            } else if (xhr.status === 401) {
                statusText = "Invalid credentials — check Settings";
            } else {
                statusText = "Server error " + xhr.status;
            }
        };
        xhr.send();
    }

    // ── API calls ────────────────────────────────────────────────────────

    function loadUserProfile() {
        raRequest("GetUserSummary", "u=" + encodeURIComponent(raUserName), function(resp) {
            softcorePoints = parseInt(resp.SoftcorePoints) || 0;
            hardcorePoints = parseInt(resp.Points)         || 0;
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
}
