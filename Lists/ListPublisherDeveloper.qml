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

import QtQuick 2.15

// --- BEGIN: More by Publisher/Developer – Option 5: JS array ---
// Replaces the SortFilterProxyModel + ExpressionFilter approach with a single
// JavaScript pass that fires on demand (via rebuild()). This eliminates the
// per-row QML reactive overhead of ExpressionFilter and runs the entire scan
// as one synchronous JS loop, which is cheaper at navigation time because it
// is explicitly triggered rather than reacting to property changes.
Item {
id: root

    // Plain JS array of game objects – used directly as the ListView model.
    // Reassigned (not mutated) so QML detects the change and updates bindings.
    property var games: []

    // Returns the game object at the given list index.
    function currentGame(index) { return games[index] }

    property int max: 100

    property string publisher: ""
    property string developer: ""
    // Title of the current game – excluded from results
    property string currentTitle: ""

    // Rebuild the games array from api.allGames in a single JS pass.
    // Called explicitly by GameView's debounce timer after navigation settles.
    function rebuild() {
        if (!publisher && !developer) {
            games = [];
            return;
        }

        var pub   = publisher.toLowerCase();
        var dev   = developer.toLowerCase();
        var title = currentTitle;
        var limit = max;
        var result = [];
        var total  = api.allGames.count;

        for (var i = 0; i < total; i++) {
            var g = api.allGames.get(i);
            if (g.title === title) continue;
            var gamePub = (g.publisher || "").toLowerCase();
            var gameDev = (g.developer || "").toLowerCase();
            if ((pub && gamePub.indexOf(pub) !== -1) ||
                (dev && gameDev.indexOf(dev) !== -1)) {
                result.push(g);
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
// --- END: More by Publisher/Developer – Option 5: JS array ---
