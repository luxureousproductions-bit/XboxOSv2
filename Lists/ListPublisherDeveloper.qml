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
import SortFilterProxyModel 0.2

// --- BEGIN: More by Publisher/Developer merged list ---
// This component replaces the original ListPublisher for the "More" section
// on the Game Details page only. It merges games from both the publisher and
// developer of the current game, automatically deduplicating results (since
// we filter a single source model with an OR condition). The current game is
// excluded via the currentTitle property.
Item {
id: root

    readonly property alias games: gamesFiltered
    // Map from the outer (index-limited) proxy back through to api.allGames.
    // gamesFiltered uses only an IndexFilter (preserving source indices), so
    // pubDevGames.mapToSource(index) correctly resolves to api.allGames.
    function currentGame(index) { return api.allGames.get(pubDevGames.mapToSource(index)) }
    property int max: 100

    property string publisher: ""
    property string developer: ""
    // Title of the current game – used to exclude it from this list
    property string currentTitle: ""

    SortFilterProxyModel {
    id: pubDevGames

        sourceModel: api.allGames
        filters: [
            // Match games whose publisher OR developer matches the current game's
            // publisher or developer. Using a single ExpressionFilter with OR logic
            // ensures deduplication is automatic (no game can appear twice from one
            // source model pass).
            // NOTE: outer properties must use root.* inside ExpressionFilter —
            // bare names resolve to the current row's model roles, not the QML item's properties.
            ExpressionFilter {
                expression: {
                    if (!root.publisher && !root.developer) return false;
                    var gamePub = (model.publisher || "").toLowerCase();
                    var gameDev = (model.developer || "").toLowerCase();
                    var pub = root.publisher.toLowerCase();
                    var dev = root.developer.toLowerCase();
                    // Partial match (same behaviour as the original RegExpFilter)
                    if (root.publisher && gamePub.indexOf(pub) !== -1) return true;
                    if (root.developer && gameDev.indexOf(dev) !== -1) return true;
                    return false;
                }
            },
            // Exclude application-genre entries
            ExpressionFilter {
                expression: {
                    var genres = model.genreList;
                    for (var i = 0; i < genres.length; i++) {
                        if (genres[i].toLowerCase() === "application") return false;
                    }
                    return true;
                }
            },
            // Exclude the current game itself
            ExpressionFilter {
                expression: root.currentTitle === "" || model.title !== root.currentTitle
            }
        ]
        sorters: RoleSorter { roleName: "rating"; sortOrder: Qt.DescendingOrder }
    }

    SortFilterProxyModel {
    id: gamesFiltered

        sourceModel: pubDevGames
        filters: [
            IndexFilter { maximumIndex: max - 1 },
            ExpressionFilter { expression: root.publisher !== "" || root.developer !== "" }
        ]
    }

    property var collection: {
        return {
            name:       "More by Publisher/Developer",
            shortName:  "publisherdeveloper",
            games:      gamesFiltered
        }
    }
}
// --- END: More by Publisher/Developer merged list ---
