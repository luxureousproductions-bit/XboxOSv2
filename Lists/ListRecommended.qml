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
import SortFilterProxyModel 0.2

Item {
id: root
    
    readonly property var games: gamesFiltered
    function currentGame(index) { return api.allGames.get(gamesFiltered.mapToSource(index)) }
    property int max: gamesFiltered.count

    property bool omitApplication: false
    property bool omitEmulator: false

    // Lazy: the proxy does NO work (no full-library rating sort / per-row filter)
    // until armed. GameView sets this true only when the Recommended fallback is
    // actually shown (publisher/developer list empty), so it costs nothing at load.
    property bool active: false

    property var randomIndices: {};

    function refresh() {
        // Pick up to `max` random games, applying the application/emulator omit
        // HERE (at selection time) so the result never depends on filter timing.
        var indices = {};
        var total   = api.allGames.count;
        var picked  = 0;
        var tries   = 0;
        while (picked < max && total > 0 && tries < max * 20) {
            tries++;
            var ri  = Math.floor(Math.random() * total);
            var key = ri.toString();
            if (indices[key]) continue;
            var g = api.allGames.get(ri);
            var skip = false;
            if (g) {
                var genres = g.genreList;
                for (var j = 0; j < genres.length; j++) {
                    var gg = genres[j].toLowerCase();
                    if (omitApplication && gg === "application") { skip = true; break; }
                    if (omitEmulator    && gg === "emulator")    { skip = true; break; }
                }
            }
            if (skip) continue;
            indices[key] = true;
            picked++;
        }
        randomIndices = indices;
    }

    // Eager seed only when armed at construction (the Showcase sets active:true).
    // Instances left inactive (e.g. GameView) do nothing here and arm on demand,
    // so they cost nothing at load.
    Component.onCompleted: if (active) refresh()

    SortFilterProxyModel {
    id: gamesFiltered
        sourceModel: active ? api.allGames : null
        sorters: RoleSorter { roleName: "rating"; sortOrder: Qt.DescendingOrder; }
        filters: ExpressionFilter {
            // Membership test only — omit logic now lives in refresh(), so this
            // depends solely on randomIndices (which the proxy reliably reacts to).
            expression: randomIndices[model.index.toString()] === true
        }
    }

    property var collection: {
        return {
            name:       "Recommended Games",
            shortName:  "recommended",
            games:      gamesFiltered
        }
    }
}
