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

// --- BEGIN: More by Genre/Subgenre expanded list ---
// This component replaces the original ListGenre for the "More" section on the
// Game Details page only. It broadens the match to include:
//   1. Games whose genre exactly matches the full "genre / subgenre" string.
//   2. Games that share the same main genre (left of " / "), regardless of subgenre.
//   3. Games that share the same subgenre (right of " / "), regardless of main genre.
// All three groups are merged into a single deduplicated list (no game can appear
// twice since we use a single ExpressionFilter pass over one source model).
// The current game is excluded via the currentTitle property.
Item {
id: root

    readonly property alias games: gamesFiltered
    // Map from the outer (index-limited) proxy back through to api.allGames.
    function currentGame(index) { return api.allGames.get(genreExpandedGames.mapToSource(index)) }
    property int max: 100

    // Full genre string for the current game, e.g. "Action / Platformer" or "RPG"
    property string genre: ""
    // Title of the current game – used to exclude it from this list
    property string currentTitle: ""

    SortFilterProxyModel {
    id: genreExpandedGames

        sourceModel: api.allGames
        filters: [
            // Broad genre match: full genre/subgenre, just main genre, or just subgenre.
            // Using a single ExpressionFilter keeps deduplication automatic.
            // NOTE: outer properties must use root.* inside ExpressionFilter —
            // bare names resolve to the current row's model roles, not the QML item's properties.
            ExpressionFilter {
                expression: {
                    if (!root.genre) return false;

                    // Parse the current game's genre string
                    var fullGenre = root.genre.toLowerCase().trim();
                    var parts = fullGenre.split("/");
                    var mainGenre = parts[0].trim();
                    var subGenre  = parts.length > 1 ? parts[1].trim() : "";

                    // Check every genre entry on the candidate game
                    var gameGenreList = model.genreList;
                    for (var i = 0; i < gameGenreList.length; i++) {
                        var gameFullGenre = gameGenreList[i].toLowerCase().trim();
                        if (!gameFullGenre) continue;

                        // 1. Full match: "Action / Platformer" == "Action / Platformer"
                        if (gameFullGenre === fullGenre) return true;

                        // Split the candidate game's genre string
                        var gameParts     = gameFullGenre.split("/");
                        var gameMainGenre = gameParts[0].trim();
                        var gameSubGenre  = gameParts.length > 1 ? gameParts[1].trim() : "";

                        // 2. Same main genre (e.g. both are "Action / ...")
                        if (mainGenre && gameMainGenre === mainGenre) return true;

                        // 3. Same subgenre (e.g. both are "... / Platformer")
                        if (subGenre && gameSubGenre && gameSubGenre === subGenre) return true;
                    }
                    return false;
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

        sourceModel: genreExpandedGames
        filters: [
            IndexFilter { maximumIndex: max - 1 },
            ExpressionFilter { expression: root.genre !== "" }
        ]
    }

    property var collection: {
        return {
            name:       genre ? "More " + genre + " Games" : "More Games",
            shortName:  genre ? genre + "games" : "games",
            games:      gamesFiltered
        }
    }
}
// --- END: More by Genre/Subgenre expanded list ---
