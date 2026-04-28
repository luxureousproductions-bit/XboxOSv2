// gameOS theme
// Copyright (C) 2018-2020 Seth Powell 
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

import QtQuick 2.0

// --- BEGIN: More by Genre – Option B: JS array ---
// Replaces the SortFilterProxyModel + ExpressionFilter approach with a single
// JavaScript pass that fires on demand (via rebuild()). The genre matched is
// controlled by matchMode: "main" (default) matches only the main genre (left
// of "/"), "sub" matches the sub-genre (right of "/", falling back to the full
// entry when no "/" is present), and "full" matches the entire genre string.
// This eliminates per-row QML reactive overhead and runs the entire scan as
// one synchronous JS loop, explicitly triggered by GameView's debounce timer
// after navigation settles.
Item {
id: root

    // Plain JS array of game objects – used directly as the ListView model.
    // Reassigned (not mutated) so QML detects the change and updates bindings.
    property var games: []

    // Returns the game object at the given list index.
    function currentGame(index) { return games[index] }

    property int max: 100

    // Genre string to match against (pre-extracted by the debounce timer).
    // Its meaning depends on matchMode: for "main" it is the main genre, for
    // "sub" it is the sub-genre (or main if none), for "full" the full string.
    property string genre: ""
    // Title of the current game – excluded from results.
    property string currentTitle: ""
    // Controls which part of each game's genre entry is compared to genre.
    // Values: "main" | "sub" | "full"  (default: "main")
    property string matchMode: "main"

    // Rebuild the games array from api.allGames in a single JS pass.
    // Called explicitly by GameView's debounce timer after navigation settles.
    function rebuild() {
        if (!genre) {
            games = [];
            return;
        }

        var target = genre.toLowerCase();
        var mode   = matchMode;
        var title  = currentTitle;
        var limit  = max;
        var result = [];
        var total  = api.allGames.count;

        for (var i = 0; i < total; i++) {
            var g = api.allGames.get(i);
            if (g.title === title) continue;

            var genreList = g.genreList;
            for (var j = 0; j < genreList.length; j++) {
                var entry = genreList[j];
                if (!entry) continue;
                var entryLower = entry.toLowerCase().trim();
                var matched;
                if (mode === "full") {
                    matched = entryLower === target;
                } else if (mode === "sub") {
                    var si = entryLower.indexOf("/");
                    var entrySub = si !== -1 ? entryLower.substring(si + 1).trim() : entryLower;
                    matched = entrySub === target;
                } else {
                    // "main" (default)
                    var slashIdx  = entryLower.indexOf("/");
                    var entryMain = slashIdx !== -1 ? entryLower.substring(0, slashIdx).trim() : entryLower;
                    matched = entryMain === target;
                }
                if (matched) {
                    result.push(g);
                    break;
                }
            }
        }

        // Sort by rating descending (mirrors the previous RoleSorter behaviour)
        result.sort(function(a, b) { return (b.rating || 0) - (a.rating || 0); });

        // Apply the max cap after sorting so we keep the highest-rated games
        if (result.length > limit)
            result = result.slice(0, limit);

        games = result;
    }
}
// --- END: More by Genre – Option B: JS array ---
